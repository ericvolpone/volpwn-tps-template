class_name Player extends CharacterBody3D

@export var look_at: LookAtModifier3D;

@export var speed = 5.0
@export var jump_strength = 5.0

@onready var input: PlayerInput = $PlayerInput
@onready var tick_interpolator: TickInterpolator = $TickInterpolator
@onready var spring_arm_look_at: SpringArm3D = $SpringArmLookAt
@onready var spring_arm_camera: SpringArm3D = $SpringArmCamera
@onready var camera: Camera3D = $SpringArmCamera/Camera3D
@onready var animation_tree: AnimationTree = $AnimationTree

static var _logger := _NetfoxLogger.new("game", "Player")

var gravity = ProjectSettings.get_setting(&"physics/3d/default_gravity")
var health: int = 100
var death_tick: int = -1
var respawn_position: Vector3
var did_respawn: bool = false
var deaths: int = 0

# Track deaths and *acknowledged* deaths
# Acknowledge the number of deaths on tick loop start
# If the value changes by the end of the loop, that means the player has
# respawned, and needs to `teleport()`
var _ackd_deaths: int = 0

var _was_hit: bool = false

func _ready():
	NetworkTime.before_tick_loop.connect(_before_tick_loop)
	NetworkTime.after_tick_loop.connect(_after_tick_loop)

	# Wait for deps to setup
	await get_tree().process_frame
	if input.is_multiplayer_authority():
		camera.current = true

func _process(delta: float) -> void:
	var movement: Vector3 = input.movement
	var movement_forward: float = 1 if movement.z == -1 else 0
	var movement_backward: float = 1 if movement.z == 1 else 0
	var animated_movement_forward: float = animation_tree.get("parameters/Run Forward/blend_amount")
	var animated_movement_backward: float = animation_tree.get("parameters/Run Backward/blend_amount")

	animation_tree.set("parameters/Run Forward/blend_amount", move_toward(animated_movement_forward, movement_forward, delta * 3))
	animation_tree.set("parameters/Run Backward/blend_amount", move_toward(animated_movement_backward, movement_backward, delta * 3))

func _before_tick_loop():
	_ackd_deaths = deaths

func _after_tick_loop():
	if _ackd_deaths != deaths:
		tick_interpolator.teleport()
		_ackd_deaths = deaths

	if _was_hit:
		_was_hit = false

func _rollback_tick(delta: float, tick: int, is_fresh: bool) -> void:
	# Handle respawn
	if tick == death_tick:
		global_position = respawn_position
		did_respawn = true
	else:
		did_respawn = false

	# Gravity
	_force_update_is_on_floor()
	if is_on_floor():
		if input.jump:
			velocity.y = jump_strength
	else:
		velocity.y -= gravity * delta

	# Handle look left and right
	rotate_object_local(Vector3(0, 1, 0), input.look_angle.x)

	# Handle Camera up and down
	spring_arm_camera.rotate_object_local(Vector3(1, 0, 0), input.look_angle.y)
	spring_arm_camera.rotation.x = clamp(spring_arm_camera.rotation.x, -1.57, 1.57)
	spring_arm_camera.rotation.z = 0
	spring_arm_camera.rotation.y = 0
	
	# Handle Look At up and down
	spring_arm_look_at.rotate_object_local(Vector3(1, 0, 0), input.look_angle.y)
	spring_arm_look_at.rotation.x = clamp(spring_arm_look_at.rotation.x, -1.57, 1.57)
	spring_arm_look_at.rotation.z = 0
	spring_arm_look_at.rotation.y = 0
	

	# Apply movement
	var input_dir = input.movement
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.z)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# move_and_slide assumes physics delta
	# multiplying velocity by NetworkTime.physics_factor compensates for it
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor

	# Handle death
	if health <= 0:
		deaths += 1
		global_position = get_parent().get_next_spawn_point(get_player_id(), deaths)
		health = 100

func _force_update_is_on_floor():
	var old_velocity = velocity
	velocity = Vector3.ZERO
	move_and_slide()
	velocity = old_velocity

func damage(amount: int, is_new_hit: bool = false):
	# Queue hit sound
	if is_new_hit:
		_was_hit = true

	health -= amount
	_logger.info("%s HP now at %s", [name, health])

func get_player_id() -> int:
	return input.get_multiplayer_authority()
