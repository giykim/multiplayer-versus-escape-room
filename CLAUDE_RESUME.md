# Claude Code Resume Document

Use this file to quickly resume development on this project.

## Project Summary

**Name**: Multiplayer Versus Escape Room
**Type**: Competitive multiplayer roguelike puzzle game
**Engine**: Godot 4.6
**Language**: GDScript
**View**: 3D First-Person (conversion in progress from 2D)

## How to Resume Development

### Quick Start Command
```
Open this project folder in Claude Code and say:

"Continue developing the multiplayer puzzle game.
Read CLAUDE_RESUME.md for full context.
Current status: Converting from 2D to 3D first-person view."
```

### Alternative: Detailed Resume
```
"Resume the multiplayer versus escape room project.

Context:
- Engine: Godot 4.6
- Architecture: Client-server multiplayer
- Game flow: Menu → Lobby → Dungeon (puzzles) → Arena (combat) → Winner

Current tasks:
1. Complete 3D first-person conversion
2. Add interference/sabotage mechanics
3. Add opponent progress tracking

Use subagents for parallel development. Commit frequently."
```

## Development Process

### Team Simulation with Subagents

This project uses Claude subagents to simulate a dev team. Use these patterns:

#### Launching Parallel Engineers
```
Use Task tool with subagent_type: "general-purpose" and run_in_background: true

Example - launch 3 engineers in parallel:
1. Task: "Engine Engineer: [task]" - Core systems
2. Task: "Gameplay Engineer: [task]" - Player mechanics
3. Task: "UI Engineer: [task]" - Interface
```

#### Role Definitions
| Role | Responsibilities |
|------|-----------------|
| **Orchestrator (main)** | Coordinates, creates tasks, reviews, commits |
| **PM Subagent** | Writes specs, GDD, requirements |
| **Tech Lead Subagent** | Code review, architecture decisions |
| **Engineer Subagents** | Implementation (run in parallel) |
| **QA Subagent** | Testing, bug finding |

#### Workflow Pipeline
```
1. Create tasks with TaskCreate
2. Set dependencies with TaskUpdate (addBlockedBy)
3. Launch subagents in parallel with Task tool
4. Wait for completion with TaskOutput
5. Review results and commit
6. Repeat
```

### Git Commit Strategy

**Commit frequently** - after each:
- Bug fix
- Feature completion
- Phase completion
- Major file changes

Use descriptive commit messages with Co-Authored-By footer.

### Testing Strategy

After each phase:
1. Run Godot (F5)
2. Test single-player flow
3. Test multiplayer with 2 instances
4. Fix bugs before proceeding

## Current State

### Git History
```
dfa184b - Fix missing activate() function in base Room class
94cf555 - Add combat system, weapons, items, and arena room
455fba7 - Fix critical bugs found in code review
6c91872 - Add dungeon generation, room navigation, and pattern puzzle
e7aff07 - Initial project setup with core systems and MVP features
```

### Completed Phases
- [x] Phase 1: Project setup, autoloads, player, sliding puzzle, UI
- [x] Phase 2: Dungeon generation, rooms, pattern puzzle
- [x] Phase 3: Combat, weapons, items, arena

### In Progress
- [ ] 3D first-person conversion
- [ ] Opponent progress tracking UI
- [ ] Interference/sabotage mechanics

### Pending
- [ ] Phase 4: Shop/economy system
- [ ] Phase 5: Polish, more puzzles, balance

## Key Files

### Must Read First
1. `README.md` - Project overview
2. `docs/game_design_document.md` - Full game design
3. `project.godot` - Godot configuration

### Core Architecture
```
src/autoload/
├── GameManager.gd    - Game state, players, match flow
├── NetworkManager.gd - Multiplayer, RPCs
└── AudioManager.gd   - Music, SFX

src/player/           - Player controller
src/dungeon/          - Procedural generation
src/puzzles/          - Puzzle framework
src/combat/           - Weapons, damage
src/items/            - Pickups, loot
src/ui/               - Menus, HUD
```

## Technical Notes

### Multiplayer Architecture
- ENet-based client-server
- Host is authority (player ID 1)
- Use `@rpc` for network sync
- Seed-based generation for determinism

### Physics Layers (2D - will need 3D equivalent)
```
Layer 1: Player
Layer 2: Walls
Layer 3: Puzzles
Layer 4: Items
Layer 5: Projectiles
```

## Troubleshooting

### Common Issues
1. "Nonexistent function" - Check base class has the method
2. Audio warnings - Placeholder files, safe to ignore
3. RPC not working - Check multiplayer authority

### Running Tests
```bash
godot --editor .
# Press F5 to run
# For multiplayer: open 2 Godot instances
```
