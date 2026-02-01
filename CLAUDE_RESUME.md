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

#### Role Definitions
| Role | Subagent Type | Responsibilities |
|------|--------------|-----------------|
| **Orchestrator (main)** | - | Coordinates, creates tasks, reviews, commits |
| **PM** | general-purpose | Writes specs, GDD, requirements |
| **Tech Lead** | Plan | Architecture decisions, code review |
| **SWE/Engineers** | general-purpose | Implementation (run in parallel) |
| **QA** | general-purpose | Testing, bug finding, validation |

#### Launching Parallel Engineers
```gdscript
# Example - launch 3 engineers in parallel using Task tool:
# Send all 3 in the SAME message to run them in parallel

Task 1: "Engine Engineer: Implement dungeon generation system"
Task 2: "Gameplay Engineer: Add player movement and interaction"
Task 3: "UI Engineer: Create main menu and HUD"

# Set subagent_type: "general-purpose" and run_in_background: true
```

#### Workflow Pipeline
```
1. PM writes spec → creates tasks
2. Tech Lead reviews architecture
3. Engineers implement in parallel (background tasks)
4. QA validates and finds bugs
5. Orchestrator reviews and commits
6. Repeat for next phase
```

#### Example: Bug Fix with QA Subagent
```
1. User reports bug
2. Launch QA agent: "Find all null reference errors in src/"
3. QA returns list of issues with file:line
4. Fix each issue
5. Commit with descriptive message
```

#### When to Use Subagents
- **Large features**: Split into parallel engineer tasks
- **Bug hunting**: Use QA agent to audit code
- **Architecture**: Use Plan/Tech Lead agent
- **Research**: Use Explore agent for codebase questions
- **Simple fixes**: Do directly (no subagent needed)

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

### Completed Phases
- [x] Phase 1: Project setup, autoloads, player, sliding puzzle, UI
- [x] Phase 2: Dungeon generation, rooms, pattern puzzle
- [x] Phase 3: Combat, weapons, items, arena
- [x] Phase 4: 3D first-person conversion, interference, tracking
- [x] E2E Testing framework created

### In Progress
- [ ] Full runtime testing and validation
- [ ] Steam multiplayer integration (docs ready)

### Pending
- [ ] Phase 5: Shop/economy system
- [ ] Phase 6: Polish, more puzzles, balance

### Recent Bug Fixes
- Fixed "Cannot call method on null value" errors across all UI components
- Added null checks for GameManager, NetworkManager, AudioManager
- Fixed OpponentTracker path to entries_container
- Created comprehensive runtime tests

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
