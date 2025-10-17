# VOLPWN's Third Person Shooter Multiplayer Template

This repository is a baseline third person shooter multiplayer template built with opinions.

- Opinion 1: Your multiplayer game should be built in a server-authoritative approach to simplify development and prevent cheating
- Opinion 2: Server authoritative models result in game-feel issues for connected clients, so we will use Netfox for Client Side Prediction and Server Side Reconciliation

See [Netfox Documentation](https://foxssake.github.io/netfox/latest/) for more details

## Known Issues

1. Currently, leaving the lobby screen on the server crashes the server (the client remains in tact).  Will patch this once I figure it out in my private project
2. Disconnection once in the game is likely not going to give you the results you want, will patch a basic implementation once implemented in my private project
