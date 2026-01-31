# Multiplayer Versus Escape Room

A competitive multiplayer roguelike puzzle game built with Godot 4 and GDScript.

## Game Concept

2-4 players race through procedurally generated puzzle dungeons. Faster puzzle-solvers gain advantages:
- **Information asymmetry**: Learn map layout and secrets
- **Resource economy**: Earn more coins for upgrades
- **Positioning**: Better spawn positions in the final arena

## Quick Start

### Requirements
- Godot 4.2+ (download from https://godotengine.org/)

### Running the Game
```bash
cd "C:\Users\juyou\Documents\Programming Projects\multiplayer-versus-escape-room"
godot --editor .
# Then press F5 to run
```

### Testing Multiplayer Locally
1. Run two instances of Godot
2. Instance 1: Host Game (creates lobby on port 7777)
3. Instance 2: Join Game (connect to 127.0.0.1:7777)

## Project Structure

```
src/
├── autoload/           # Singletons (GameManager, NetworkManager, AudioManager)
├── player/             # Player movement, input, character
├── puzzles/            # Puzzle system
│   ├── base/           # BasePuzzle, PuzzleTile
│   └── logic/          # SlidingTile, PatternSequence puzzles
├── dungeon/            # Procedural generation
│   ├── DungeonGenerator.gd
│   ├── Dungeon.gd
│   ├── Room.gd
│   └── RoomTypes/      # PuzzleRoom, TreasureRoom, ArenaRoom
├── combat/             # Combat system
│   ├── CombatSystem.gd
│   ├── Weapon.gd
│   └── Weapons/        # Sword, Bow
├── items/              # Pickups and loot
│   ├── Item.gd
│   ├── CoinPickup.gd
│   ├── WeaponPickup.gd
│   └── HealthPickup.gd
├── ui/                 # Menus and HUD
│   ├── MainMenu
│   ├── Lobby
│   └── HUD
└── Game.gd             # Main game scene
```

## Current Features

### Core Systems
- [x] Multiplayer networking (host/join lobby)
- [x] Procedural dungeon generation (seed-based)
- [x] Player movement with interaction system
- [x] Puzzle framework with multiple types
- [x] Combat system with weapons
- [x] Item/loot system
- [x] Arena final showdown

### Puzzle Types
- [x] Sliding Tile Puzzle
- [x] Pattern Sequence (Simon Says)

### Weapons
- [x] Sword (melee, high damage)
- [x] Bow (ranged, charge mechanic)

### Items
- [x] Coins (small/medium/large)
- [x] Health pickups
- [x] Weapon pickups

## Development Status

| Phase | Status | Description |
|-------|--------|-------------|
| 1 | ✅ Complete | Project setup, core systems, MVP |
| 2 | ✅ Complete | Dungeon generation, rooms, navigation |
| 3 | ✅ Complete | Combat, weapons, items, arena |
| 4 | 🔲 Pending | Shop system, economy |
| 5 | 🔲 Pending | Polish, more puzzles, balance |

## Resuming Development

To continue development with Claude Code:
```
Open this project folder and say:
"Continue developing the multiplayer puzzle game. Read the README.md and docs/game_design_document.md for context. Current status: Phase 3 complete, ready for Phase 4 (Shop/Economy)."
```

## Controls

| Action | Key |
|--------|-----|
| Move | WASD / Arrow Keys |
| Interact | E |
| Attack | Left Click |
| Charge (Bow) | Hold Left Click |

## Technical Notes

- **Engine**: Godot 4.2+
- **Language**: GDScript
- **Networking**: ENet (client-server model)
- **Resolution**: 1280x720 (scalable)

## License

Private project - All rights reserved
