class_name PlayerTeamSlot extends Control

@onready var player_name_label: Label = $PlayerName

var player_name: String

func _ready() -> void:
	player_name_label.text = player_name
