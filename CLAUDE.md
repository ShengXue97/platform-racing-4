# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

Platform Racing 4 is a multiplayer platform racing game with three main components:

### Client (`/client`)
- **Godot Engine 4.4** game client with GDScript
- **Main scenes**: `pages/` directory contains different game screens (lobby, editor, game, etc.)
- **Networking**: Uses netfox addons for multiplayer (netfox, netfox.extras, netfox.internals, netfox.noray)
- **Game engine**: Core systems in `engine/` (level management, player management, camera, etc.)
- **Singletons**: Auto-loaded scripts in `singletons/` provide global functionality
- **Testing**: Uses vest addon for unit testing - run specific test scenes with `--run-tests` command line arg

### API Server (`/api`)
- **Go backend** for authentication, user management, and level storage
- **Database**: SQLite with GORM
- **Authentication**: JWT tokens with refresh mechanism
- **Level import**: Can import Platform Racing 2 levels via `/internal/pr2_level_import/`
- **File storage**: Uses AWS S3 for level data storage

### Game Server (`/game-server`) 
- **Go WebSocket server** for real-time multiplayer game sessions
- **Room management**: Handles game rooms and level editor collaboration
- **Client communication**: WebSocket-based protocol for game state synchronization

## Commands

### Client Development
- **Run game**: Open `client/project.godot` in Godot Engine and press F5
- **Build for web**: `godot --headless --verbose --export-release "Web" $PWD/build/web/index.html` (from client directory)
- **Run tests**: `godot --headless --run-tests all` or `godot --headless --run-tests game,editor,tester,items`
- **Test individual scenes**: Open `*_test.tscn` files in Godot and press F5

### API Server
- **Run development**: `go run .` (from api directory)
- **Run tests**: `go test ./...` (from api directory)
- **Build**: `go build -o api .` (from api directory)

### Game Server
- **Run development**: `go run .` (from game-server directory)  
- **Run tests**: `go test ./...` (from game-server directory)
- **Build**: `go build -o pr4-game-server .` (from game-server directory)

## Key Architecture Patterns

### Godot Client Structure
- **Autoloads**: Global singletons defined in `project.godot` provide cross-scene functionality
- **Scene composition**: Main game logic split into reusable scenes and scripts
- **Networking**: Netfox handles client-server synchronization and rollback
- **State management**: Game state managed through scene transitions in `main/main.gd`

### Data Flow
1. **Authentication**: Client → API Server (JWT tokens)
2. **Level data**: API Server → Client (JSON level format) 
3. **Real-time gameplay**: Client ↔ Game Server (WebSocket)
4. **Level editing**: Multiple clients ↔ Game Server (collaborative editing)

### Level System
- **Storage**: Levels stored as JSON in S3, metadata in SQLite
- **Import**: PR2 levels can be converted to PR4 format
- **Editing**: Real-time collaborative editing through WebSocket rooms
- **Rendering**: Godot TileMap system with custom tile behaviors

## Development Workflow

1. **Client changes**: Test with F5 in Godot, run automated tests for core functionality
2. **API changes**: Use `go test` to verify endpoints, check database migrations
3. **Game server**: Test multiplayer features with multiple client instances
4. **Integration**: Run full stack locally - API server, game server, and client(s)

## Networking Architecture

- **Netfox**: Handles client-side prediction, server reconciliation, and rollback
- **WebSockets**: Game server uses gorilla/websocket for real-time communication  
- **HTTP API**: RESTful API for authentication, user data, and level management
- **Room system**: Game server manages isolated rooms for matches and level editing