# Multiplayer Versus Escape Room

A competitive multiplayer roguelike puzzle game built with Godot 4.6 and GDScript.
Features both 2D (top-down) and 3D (first-person) modes.

## Game Concept

2-4 players race through procedurally generated puzzle dungeons. Faster puzzle-solvers gain advantages:
- **Information asymmetry**: Learn map layout and secrets
- **Resource economy**: Earn more coins for upgrades
- **Positioning**: Better spawn positions in the final arena
- **Interference**: Place traps to slow down opponents

## Quick Start

### Requirements
- Godot 4.6+ (download from https://godotengine.org/)

### Running the Game
```bash
cd "C:\Users\juyou\Documents\Programming Projects\multiplayer-versus-escape-room"
godot --editor .
# Then press F5 to run
```

### Running Tests
```bash
# Run E2E tests (headless)
run_tests.bat

# Or manually:
godot --headless --script tests/TestRunner.gd
```

### Testing Multiplayer Locally
1. Run two instances of Godot
2. Instance 1: Host Game (creates lobby on port 7777)
3. Instance 2: Join Game (connect to 127.0.0.1:7777)

## Project Structure

```
src/
├── autoload/           # Singletons (GameManager, NetworkManager, AudioManager)
├── player/             # 2D Player movement, input, character
├── player3d/           # 3D First-person controller
├── puzzles/            # 2D Puzzle system
│   ├── base/           # BasePuzzle, PuzzleTile
│   └── logic/          # SlidingTile, PatternSequence puzzles
├── puzzles3d/          # 3D Puzzle system with raycast interaction
├── dungeon/            # 2D Procedural generation
│   └── RoomTypes/      # PuzzleRoom, TreasureRoom, ArenaRoom
├── dungeon3d/          # 3D Dungeon generation
├── combat/             # Combat system
│   ├── CombatSystem.gd
│   ├── Weapon.gd
│   └── Weapons/        # Sword, Bow
├── items/              # Pickups and loot
├── interference/       # Traps and sabotage system
├── ui/                 # Menus, HUD, OpponentTracker
├── Game.gd             # 2D Main game scene
└── Game3D.gd           # 3D Main game scene
tests/
├── TestRunner.gd       # E2E test framework
├── BaseTest.gd         # Test utilities
├── unit/               # Unit tests
└── integration/        # Integration tests
docs/
├── game_design_document.md
├── STEAM_MULTIPLAYER.md  # Steam integration guide
└── CLAUDE_RESUME.md      # Resume development guide
```

## Current Features

### Core Systems
- [x] Multiplayer networking (host/join lobby)
- [x] Procedural dungeon generation (seed-based)
- [x] 2D top-down player controller
- [x] 3D first-person player controller
- [x] Puzzle framework with multiple types
- [x] Combat system with weapons
- [x] Item/loot system
- [x] Arena final showdown
- [x] Opponent tracking UI
- [x] Interference/trap system

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

### Traps (Interference)
- [x] Slow trap
- [x] Stun trap
- [x] Blind trap
- [x] Reverse controls trap
- [x] Damage trap

## Development Status

| Phase | Status | Description |
|-------|--------|-------------|
| 1 | Complete | Project setup, core systems, MVP |
| 2 | Complete | Dungeon generation, rooms, navigation |
| 3 | Complete | Combat, weapons, items, arena |
| 4 | Complete | 3D conversion, interference, tracking |
| 5 | Pending | Shop system, economy |
| 6 | Pending | Steam multiplayer, polish |

## Controls

### 3D First-Person (Default)
| Action | Key |
|--------|-----|
| Move | WASD |
| Look | Mouse |
| Interact | E / Left Click |
| Sprint | Shift |

### 2D Top-Down
| Action | Key |
|--------|-----|
| Move | WASD / Arrow Keys |
| Interact | E |
| Attack | Left Click |
| Charge (Bow) | Hold Left Click |

## Resuming Development

See `docs/CLAUDE_RESUME.md` for detailed instructions on resuming with Claude Code.

Quick start:
```
Open this project folder and say:
"Continue developing the multiplayer puzzle game. Read CLAUDE_RESUME.md for context."
```

## Steam Multiplayer

See `docs/STEAM_MULTIPLAYER.md` for Steam networking integration guide.

## Technical Notes

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Networking**: ENet (client-server), Steam ready
- **3D Mode**: First-person with CSG prototyping
- **2D Mode**: Top-down with tile-based rooms

## Testing

The project includes an E2E testing framework:

```bash
# Run all tests
run_tests.bat

# Tests validate:
# - Player systems (2D and 3D)
# - Combat mechanics
# - Puzzle logic
# - Dungeon generation
# - Item pickups
# - Game flow integration
```

## License

Private project - All rights reserved
