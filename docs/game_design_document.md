# Game Design Document: Puzzle Versus

**Version:** 1.0
**Last Updated:** January 30, 2026
**Document Status:** Initial Draft

---

## Table of Contents

1. [Game Overview & Vision](#1-game-overview--vision)
2. [Core Gameplay Loop](#2-core-gameplay-loop)
3. [Puzzle Types](#3-puzzle-types)
4. [Competition Mechanics](#4-competition-mechanics)
5. [Progression & Rewards](#5-progression--rewards)
6. [Combat System](#6-combat-system)
7. [Multiplayer Design](#7-multiplayer-design)
8. [Roguelike Elements](#8-roguelike-elements)
9. [UI/UX Requirements](#9-uiux-requirements)
10. [Art Style Direction](#10-art-style-direction)
11. [Audio Design](#11-audio-design)
12. [MVP Features vs Future Features](#12-mvp-features-vs-future-features)

---

## 1. Game Overview & Vision

### 1.1 High Concept

**Puzzle Versus** is a competitive multiplayer roguelike where 2-4 players race through procedurally generated puzzle dungeons. Players solve escape room-style puzzles, logic challenges, and environmental obstacles to progress through the dungeon faster than their opponents. Speed matters: faster puzzle-solvers gain critical advantages in information, resources, and positioning before all players converge in a final arena for combat. The winner is determined by a combination of puzzle-solving prowess and strategic combat.

### 1.2 Vision Statement

Create a unique competitive experience that rewards both intellectual agility and strategic thinking. Unlike traditional battle royales or puzzle games, Puzzle Versus merges the satisfaction of puzzle-solving with the tension of real-time competition and combat, creating emergent moments where a brilliant puzzle solution translates directly into combat advantage.

### 1.3 Target Audience

- **Primary:** Competitive gamers who enjoy intellectual challenges (ages 18-35)
- **Secondary:** Escape room enthusiasts looking for digital experiences
- **Tertiary:** Roguelike fans seeking fresh multiplayer experiences

### 1.4 Platform

- PC (Primary)
- Console (Future consideration)

### 1.5 Unique Selling Points

1. **Puzzle-to-Combat Pipeline:** Your puzzle performance directly affects your combat power
2. **Information as Weapon:** First solvers gain intel that others lack
3. **Procedural Puzzle Dungeons:** Every match is different
4. **Asymmetric Advantages:** Multiple ways to gain edges beyond raw speed
5. **Tense Convergence:** Building anticipation as players race toward the final showdown

### 1.6 Core Pillars

1. **Competitive Tension:** Every second counts; every puzzle matters
2. **Fair but Asymmetric:** All players face equivalent challenges, but outcomes create meaningful differences
3. **Skill Expression:** Reward pattern recognition, lateral thinking, and strategic planning
4. **Emergent Drama:** Create memorable moments through mechanical interactions

---

## 2. Core Gameplay Loop

### 2.1 Match Structure Overview

A complete match consists of three distinct phases:

```
PHASE 1: DUNGEON RACE (10-15 minutes)
    |
    v
PHASE 2: PREPARATION (1-2 minutes)
    |
    v
PHASE 3: ARENA COMBAT (3-5 minutes)
```

### 2.2 Phase 1: Dungeon Race

#### 2.2.1 Spawn & Initialization
- All players spawn simultaneously in separate, isolated starting rooms
- Each player's dungeon wing is procedurally generated but balanced for equivalent difficulty
- A countdown timer syncs all players before the race begins
- Players can see opponent progress indicators (room count, not specifics)

#### 2.2.2 Dungeon Navigation
- Players progress through a series of connected rooms
- Each room contains one primary puzzle and optional bonus objectives
- Room types include: Puzzle Rooms, Treasure Rooms, Shop Rooms, and Transit Rooms
- Standard dungeon length: 8-12 rooms before convergence point

#### 2.2.3 Puzzle Solving
- Players must solve the room's primary puzzle to unlock the exit
- Time spent in each room is tracked and affects scoring
- Optional bonus puzzles provide additional rewards
- Hints are available at a cost (coins or time penalty)

#### 2.2.4 Resource Collection
- Coins spawn in rooms and from puzzle completion
- Faster completion = higher coin multiplier (1.5x for sub-par time, 2x for record time)
- Treasure chests contain equipment, consumables, or bonus coins
- Hidden secrets provide major rewards for observant players

### 2.3 Phase 2: Preparation

#### 2.3.1 Pre-Arena Setup
- First player to complete their dungeon enters the Preparation Phase
- They can: scout the arena, place traps, choose spawn position
- Each subsequent finisher gains less preparation time
- Shop access for final purchases with accumulated coins
- Equipment loadout finalization

#### 2.3.2 Advantage Windows
| Finish Position | Prep Time | Trap Slots | Spawn Choice |
|----------------|-----------|------------|--------------|
| 1st            | 90 sec    | 3          | First pick   |
| 2nd            | 60 sec    | 2          | Second pick  |
| 3rd            | 30 sec    | 1          | Third pick   |
| 4th            | 0 sec     | 0          | Remaining    |

### 2.4 Phase 3: Arena Combat

#### 2.4.1 Arena Structure
- Single arena map with multiple elevation levels and cover
- Shrinking safe zone (roguelike circle mechanic)
- Environmental hazards activated by arena events
- Power-up spawns at timed intervals

#### 2.4.2 Combat Resolution
- Last player standing wins the match
- Respawns: None (elimination format)
- Match duration cap: 5 minutes (zone fully closes)

### 2.5 Session Flow

```
LOBBY (Player Matchmaking)
    |
    v
CHARACTER SELECT (30 seconds)
    |
    v
LOADING (Dungeon Generation)
    |
    v
COUNTDOWN (3 seconds)
    |
    v
DUNGEON RACE
    |
    +---> Room Entry
    |         |
    |         v
    |     Puzzle Solve
    |         |
    |         v
    |     Loot Collection
    |         |
    |         v
    |     Exit to Next Room
    |         |
    +----<----+
    |
    v (All rooms cleared)
PREPARATION PHASE
    |
    v
ARENA COMBAT
    |
    v
RESULTS SCREEN
    |
    v
LOBBY (Rematch or Exit)
```

---

## 3. Puzzle Types

### 3.1 Puzzle Philosophy

All puzzles must adhere to these design principles:

1. **Solvable in Isolation:** No external knowledge required
2. **Clear Win State:** Players know when they've solved it
3. **Time Scalable:** Faster solving is possible with skill/insight
4. **Procedurally Variable:** Core logic remains, specifics change
5. **Non-Blocking:** Hints prevent permanent stalls

### 3.2 Escape Room Puzzles

#### 3.2.1 Definition
Physical interaction puzzles that require players to examine the environment, find hidden objects, and combine items to progress.

#### 3.2.2 Examples

**Lock and Key Variant: "The Sigil Door"**
- A door with four symbol slots
- Symbols are hidden around the room (behind paintings, under objects, in drawers)
- Players must find all four symbols and arrange them correctly
- Procedural variation: Symbol locations and correct sequence change

**Combination Puzzle: "The Merchant's Safe"**
- A safe with a 4-digit combination
- Clues scattered in the room (receipt with partial number, calendar with circled date, etc.)
- Players deduce the combination from environmental clues
- Procedural variation: Clue types and number combinations change

**Mechanism Puzzle: "The Clockwork Gate"**
- A gate controlled by a series of gears and levers
- Players must activate mechanisms in the correct sequence
- Visual/audio feedback indicates progress
- Procedural variation: Mechanism count and sequence length vary

**Hidden Object Puzzle: "The Curator's Collection"**
- Find X specific objects in a cluttered room
- Objects are procedurally placed among distractors
- Examining objects reveals which belong to the collection
- Procedural variation: Object types, positions, and count change

#### 3.2.3 Interaction Model
- Point-and-click examination
- Inventory system for collected items
- Item combination interface
- Environmental interaction highlights

### 3.3 Logic Puzzles

#### 3.3.1 Definition
Abstract reasoning challenges that test pattern recognition, deduction, and logical thinking.

#### 3.3.2 Examples

**Deduction Grid: "The Prisoner's Dilemma"**
- Classic logic grid puzzle (4x4 or 5x5)
- Given clues to deduce which prisoner is in which cell with which crime
- Procedural variation: Names, crimes, cell positions, and clues change

**Sequence Puzzle: "The Alchemist's Formula"**
- Complete a sequence of symbols/numbers
- Pattern rules: arithmetic, geometric, symbolic transformation
- Multiple difficulty tiers based on pattern complexity
- Procedural variation: Sequence type and complexity randomized

**Spatial Reasoning: "The Architect's Blueprint"**
- Rotate/flip shapes to fill a container
- Tetris-like piece fitting with rotation constraints
- Procedural variation: Piece shapes and container size vary

**Circuit/Flow Puzzle: "The Conduit"**
- Connect power sources to destinations
- Pipes/wires cannot cross (or can with bridges)
- All connections must be made simultaneously
- Procedural variation: Grid size, connection count, and complexity scale

**Sudoku Variant: "The Runestone Grid"**
- Modified sudoku with fantasy theming
- Additional constraints (diagonal rules, color rules)
- Smaller grids for time efficiency (6x6 or 4x4)
- Procedural variation: Given numbers and constraint types change

**Memory Puzzle: "The Echo Chamber"**
- Simon-says style pattern memorization
- Sequence length increases with room difficulty
- Audio and visual components
- Procedural variation: Pattern length and input types vary

#### 3.3.3 Interface Requirements
- Clean, readable grid/puzzle displays
- Undo functionality for logic mistakes
- Note-taking system for deduction puzzles
- Clear success/failure feedback

### 3.4 Environmental Puzzles

#### 3.4.1 Definition
Physics-based or world-interaction puzzles that require manipulating the game environment.

#### 3.4.2 Examples

**Pressure Plates: "The Weight of Passage"**
- Multiple pressure plates require simultaneous activation
- Players push moveable objects onto plates
- Weight requirements may vary per plate
- Procedural variation: Plate positions, required weights, object availability

**Light/Mirror Puzzle: "The Sunstone Shrine"**
- Redirect light beams using mirrors and prisms
- Light must hit multiple targets simultaneously
- Obstacles block or filter light
- Procedural variation: Mirror positions, target locations, obstacle placement

**Elemental Interaction: "The Crucible"**
- Use fire to melt ice, water to extinguish flames, etc.
- Chain reactions create paths forward
- Environmental hazards add time pressure
- Procedural variation: Element sources, obstacle types, solution paths

**Platforming Integration: "The Shifting Stones"**
- Activate switches in sequence to create platforms
- Timing-based execution after solving the sequence puzzle
- Combines mental solving with execution skill
- Procedural variation: Platform patterns and timing windows

**Perspective Puzzle: "The Architect's Eye"**
- Align objects in 3D space to form a shape from specific viewpoint
- Moving viewpoint reveals hidden patterns
- Unlocks passage when alignment is correct
- Procedural variation: Required shape, object positions, viewpoint location

#### 3.4.3 Physics Considerations
- Deterministic physics (same input = same output across clients)
- Clear object interaction affordances
- Reset mechanism if objects become stuck
- Visual guides for trajectory/projection

### 3.5 Puzzle Difficulty Scaling

#### 3.5.1 Room Progression Difficulty
| Room Number | Difficulty Tier | Puzzle Complexity | Expected Solve Time |
|-------------|-----------------|-------------------|---------------------|
| 1-3         | Easy            | Single-step       | 30-60 seconds       |
| 4-6         | Medium          | Multi-step        | 60-120 seconds      |
| 7-9         | Hard            | Complex chain     | 120-180 seconds     |
| 10-12       | Expert          | Combined types    | 180-240 seconds     |

#### 3.5.2 Procedural Difficulty Variables
- Grid sizes (4x4 vs 6x6 vs 8x8)
- Clue count (more clues = easier)
- Step count (fewer steps = easier)
- Time pressure (optional countdown rooms)
- Red herrings (false clues in harder rooms)

### 3.6 Hint System

#### 3.6.1 Hint Tiers
1. **Nudge (Free, 10-second delay):** Highlights the next interaction point
2. **Clue (50 coins):** Provides partial solution information
3. **Solution (200 coins + 30-second penalty):** Reveals the answer

#### 3.6.2 Hint Philosophy
- Hints should prevent frustration without removing challenge
- Economic cost creates meaningful choice
- Time penalties maintain competitive balance
- Hints should teach, not just solve

---

## 4. Competition Mechanics

### 4.1 Information Asymmetry

#### 4.1.1 Map Revelation System

**First Solver Advantage: Arena Intel**
- First player to complete dungeon sees the full arena map
- Includes: spawn points, trap locations, power-up spawns, hazard zones
- This information is NOT shared with other players
- Creates decision advantage in spawn selection and trap placement

**Dungeon Intel Sharing**
- Optional: First solver can reveal/hide information about dungeon rooms
- False information planting (limited uses): Mark safe rooms as dangerous
- True information has credibility cost (other players may not trust it)

#### 4.1.2 Secret Discovery

**Hidden Room Intel**
- Players who find secret rooms learn about hidden arena features
- Secret passages in arena only visible to discoverers
- Trap locations in other players' dungeon paths (if mechanics allow)

**Trap Visibility**
- Traps placed by earlier finishers are initially invisible
- Detection ability: Purchased items can reveal traps
- First-mover advantage vs. counter-play options

#### 4.1.3 Information Economy
| Information Type | How Acquired | Strategic Value |
|-----------------|--------------|-----------------|
| Arena Layout | First finish | Spawn/trap planning |
| Power-up Spawns | First/Second finish | Early positioning |
| Hazard Timing | Secret rooms | Survival advantage |
| Enemy Loadout | Shop purchase | Combat preparation |
| Trap Locations | Detection items | Avoidance/disarm |

### 4.2 Resource Economy

#### 4.2.1 Coin Generation

**Base Coin Sources**
- Room completion: 50 coins (base)
- Speed bonus: +25 coins (under par time)
- Treasure chests: 25-100 coins (random)
- Secret discovery: 75 coins (fixed)
- Bonus puzzles: 50 coins per puzzle

**Speed Multipliers**
| Completion Time | Multiplier | Applied To |
|-----------------|------------|------------|
| Record time (top 10%) | 2.0x | Room completion coins |
| Fast (under par) | 1.5x | Room completion coins |
| Par time | 1.0x | Room completion coins |
| Over par | 0.75x | Room completion coins |

#### 4.2.2 Coin Expenditure

**Shop Categories**
- **Weapons:** Combat equipment (500-1500 coins)
- **Armor:** Defensive gear (400-1200 coins)
- **Consumables:** Single-use items (100-300 coins)
- **Traps:** Arena placement items (200-600 coins)
- **Intel:** Information purchases (150-400 coins)
- **Hints:** Puzzle assistance (50-200 coins)

**Economic Strategy**
- Save for powerful arena items vs. invest in puzzle hints
- Buy traps (requires early finish) vs. buy counter-measures
- Information purchases vs. equipment purchases

#### 4.2.3 Wealth Disparity Mitigation

**Catch-up Mechanics**
- Later finishers find slightly more treasure in final rooms
- Shop prices discount 10% for each position behind first
- Bonus coins for surviving trap damage (demonstrates opponent investment)

**Disparity Caps**
- Maximum coin lead capped at 2x the median
- Excess coins convert to minor stat boost instead

### 4.3 Time & Positioning Advantages

#### 4.3.1 Preparation Time Benefits

**First Finisher (90 seconds prep)**
- Full arena scout time
- First pick of spawn position (4 options, varying quality)
- Place up to 3 traps anywhere in arena
- Access to premium shop items (first-come-first-served)
- Can observe other players' final dungeon rooms (limited time)

**Second Finisher (60 seconds prep)**
- Partial arena scout (fog of war on edges)
- Second pick of spawn position
- Place up to 2 traps
- Standard shop access

**Third Finisher (30 seconds prep)**
- Minimal arena scout (immediate area only)
- Third pick of spawn position
- Place 1 trap
- Standard shop access

**Fourth Finisher (0 seconds prep)**
- No arena preview
- Assigned remaining spawn position
- No trap placement
- Quick shop access only (10 seconds)

#### 4.3.2 Spawn Position Value

**Position Qualities**
- **High Ground:** Elevation advantage, longer sightlines
- **Cover Rich:** More obstacles for defense
- **Resource Adjacent:** Near early power-up spawns
- **Escape Route:** Multiple exit paths

**Strategic Consideration**
- First picker may take high ground for combat advantage
- Or may take resource position for equipment advantage
- Position synergy with trap placement

#### 4.3.3 Trap Placement Strategy

**Available Traps (Examples)**
- **Proximity Mine:** Damage on approach (visible with detection)
- **Slow Field:** Movement reduction zone
- **Alarm Trap:** Reveals enemy position when triggered
- **Decoy:** False power-up that triggers effect
- **Reversal Pad:** Inverts controls briefly

**Placement Considerations**
- High-traffic areas (power-up spawns, choke points)
- Counter-spawn positions (predict enemy paths)
- Defensive perimeter (around own spawn)
- Denial zones (block access to key resources)

---

## 5. Progression & Rewards

### 5.1 Within-Match Progression

#### 5.1.1 Power Curve
```
START OF MATCH
    |
    v
[Base Stats Only]
    |
    v
ROOM 1-3: Minor pickups, basic weapons
    |
    v
ROOM 4-6: Armor pieces, ability unlocks
    |
    v
ROOM 7-9: Significant upgrades, build definition
    |
    v
ROOM 10-12: Build completion, legendary items
    |
    v
ARENA: Full power, built advantages
```

#### 5.1.2 In-Match Pickups

**Weapon Drops**
- Common: +10% damage
- Uncommon: +20% damage, minor effect
- Rare: +35% damage, moderate effect
- Legendary: +50% damage, major effect

**Armor Drops**
- Shield fragments: +25 shield each (max 100)
- Armor pieces: Damage reduction 5-20%
- Unique armor: Special defensive abilities

**Consumables**
- Health potions: Restore 50/100/150 HP
- Speed boost: +30% movement for 10 seconds
- Reveal scroll: Shows enemy positions for 5 seconds
- Trap detector: Highlights traps in radius

### 5.2 Meta-Progression (Between Matches)

#### 5.2.1 Player Level System

**Experience Gains**
- Match completion: 100 XP
- Match win: +200 XP bonus
- Puzzles solved: 10 XP each
- Speed records: 25 XP each
- Challenges completed: Variable XP

**Level Rewards (Every 5 Levels)**
- New character skin
- New trap type unlock
- Cosmetic customization option
- Title unlock

#### 5.2.2 Mastery Tracks

**Puzzle Mastery**
- Track solve times across puzzle types
- Unlock puzzle-specific cosmetic frames
- Earn titles ("Logic Master," "Escape Artist," etc.)
- Access to puzzle variant modes

**Combat Mastery**
- Track kills, wins, damage dealt
- Unlock weapon skins
- Earn combat titles
- Access to combat variant modes

**Explorer Mastery**
- Track secrets found, hidden rooms discovered
- Unlock map-reveal cosmetics
- Earn explorer titles
- Access to exploration challenges

### 5.3 Unlockable Content

#### 5.3.1 Characters

**Base Roster (4 Characters)**
Each with unique passive ability affecting dungeon phase:

1. **The Scholar**
   - Passive: Logic puzzles show one free hint
   - Arena ability: Reveal trap in radius

2. **The Rogue**
   - Passive: Environmental puzzles have highlighted interaction points
   - Arena ability: Temporary invisibility

3. **The Engineer**
   - Passive: Escape room puzzles have item highlights
   - Arena ability: Deploy temporary cover

4. **The Mystic**
   - Passive: Bonus coins from secret discovery
   - Arena ability: Short-range teleport

**Unlockable Characters (Future)**
- Earned through gameplay milestones
- Each with unique passive/active abilities
- Cosmetic variants available

#### 5.3.2 Cosmetics

**Categories**
- Character skins (recolors, themed outfits)
- Weapon skins (visual only)
- Trap skins (visual only)
- Victory animations
- Emotes
- Titles
- Profile frames
- Dungeon themes (private matches)

**Acquisition Methods**
- Level rewards
- Mastery rewards
- Challenge completion
- Battle pass (seasonal)
- Direct purchase (cosmetic only)

### 5.4 Daily/Weekly Challenges

#### 5.4.1 Challenge Types

**Daily (3 per day)**
- Solve X puzzles of specific type
- Complete a match
- Achieve speed record on any puzzle
- Place X traps
- Collect X total coins

**Weekly (5 per week)**
- Win X matches
- Discover X secrets
- Complete dungeon under Y total time
- Deal X damage with traps
- Solve X puzzles without hints

#### 5.4.2 Rewards
- Daily: 50 XP + 25 premium currency
- Weekly: 200 XP + 100 premium currency
- Complete all daily: Bonus chest
- Complete all weekly: Premium chest

---

## 6. Combat System

### 6.1 Combat Philosophy

Arena combat serves as the culmination of the puzzle race, not the primary skill test. Combat should be:
- **Accessible:** Low mechanical barrier to entry
- **Strategic:** Positioning and resource management matter more than reflexes
- **Decisive:** Fights resolve quickly; advantages are meaningful
- **Readable:** Players understand why they won or lost

### 6.2 Health & Damage

#### 6.2.1 Health Pool
- Base HP: 200
- Maximum HP: 300 (with pickups)
- Shield: 0-100 (from pickups, absorbs damage first)
- Armor: 0-30% damage reduction

#### 6.2.2 Damage Values (Base Weapons)
| Weapon Type | Damage | Fire Rate | Range |
|-------------|--------|-----------|-------|
| Pistol (default) | 15 | Medium | Medium |
| Shotgun | 8x6 pellets | Slow | Short |
| Rifle | 20 | Fast | Long |
| SMG | 10 | Very Fast | Medium |
| Crossbow | 45 | Very Slow | Long |

#### 6.2.3 Time-to-Kill Targets
- Minimum TTK (optimal play): 2 seconds
- Average TTK: 4-6 seconds
- Maximum TTK (poor accuracy): 10+ seconds

### 6.3 Weapon System

#### 6.3.1 Weapon Slots
- Primary weapon (1 slot)
- Secondary weapon (1 slot)
- Quick-swap between slots

#### 6.3.2 Weapon Acquisition
- Start with: Pistol (default)
- Dungeon drops: Random weapon pickups
- Shop purchase: Guaranteed specific weapons
- Arena spawns: Timed weapon drops

#### 6.3.3 Weapon Rarities
Rarity affects base stats:
- Common: Base stats
- Uncommon: +15% damage, minor perk
- Rare: +25% damage, moderate perk
- Legendary: +40% damage, major perk

**Example Perks**
- Vampiric: Heal 10% of damage dealt
- Explosive: AoE on hit
- Piercing: Ignores 50% armor
- Swift: +20% fire rate
- Hunter: Bonus damage to revealed enemies

### 6.4 Movement & Positioning

#### 6.4.1 Movement Stats
- Base movement speed: 5 m/s
- Sprint speed: 7 m/s (limited stamina)
- Crouch speed: 2.5 m/s
- Jump height: 2 meters

#### 6.4.2 Movement Abilities
- Dodge roll: Quick invincibility frames (cooldown: 3 seconds)
- Sprint: Faster movement, cannot shoot (stamina-based)
- Crouch: Reduced profile, reduced speed
- Mantle: Climb low obstacles

#### 6.4.3 Terrain Interactions
- High ground: +10% accuracy bonus
- Cover: Blocks projectiles, can be destroyed
- Water: Slowed movement
- Hazards: Environmental damage zones

### 6.5 Arena Structure

#### 6.5.1 Arena Layout
- Central area with power-up spawns
- Four quadrant spawn zones
- Multiple elevation levels (ground, platforms, high ground)
- Destructible cover elements
- Hazard zones (activate mid-match)

#### 6.5.2 Shrinking Zone
| Time | Zone Size | Damage/sec outside |
|------|-----------|-------------------|
| 0:00-1:00 | 100% | 0 |
| 1:00-2:00 | 75% | 5 |
| 2:00-3:00 | 50% | 15 |
| 3:00-4:00 | 25% | 30 |
| 4:00-5:00 | 10% | 50 |
| 5:00+ | 0% | Instant death |

#### 6.5.3 Arena Events
- 1:30 - First hazard activates (fire geysers, spike traps)
- 2:30 - Power weapon spawns center
- 3:30 - Second hazard activates
- 4:30 - Final power-up spawns

### 6.6 Trap System (Arena Phase)

#### 6.6.1 Trap Types
| Trap | Effect | Duration | Visibility |
|------|--------|----------|------------|
| Proximity Mine | 50 damage | Instant | Hidden |
| Slow Field | -50% movement | 3 seconds | Faint shimmer |
| Flash Trap | Blinds | 2 seconds | Hidden |
| Alarm | Reveals position | 5 seconds | Hidden |
| Decoy | Fake power-up | On interact | Visible (mimics item) |
| Damage Zone | 10 DPS | While in zone | Hidden |

#### 6.6.2 Trap Counters
- Trap Detection item: Reveals traps in radius
- Careful movement: Traps have activation delay
- Triggering for enemies: Lure opponents into traps

### 6.7 Consumables (Arena Phase)

#### 6.7.1 Available Consumables
- **Health Pack:** Restore 100 HP (3-second channel)
- **Shield Cell:** Restore 50 shield (2-second channel)
- **Speed Stim:** +40% movement for 5 seconds
- **Reveal Pulse:** Shows all enemies for 3 seconds
- **Trap Disabler:** Destroys traps in radius

#### 6.7.2 Consumable Limits
- Maximum 3 consumables carried into arena
- Cannot pick up additional consumables during combat
- Use requires brief channel time (interruptible)

---

## 7. Multiplayer Design

### 7.1 Network Architecture

#### 7.1.1 Server Authority
- **Authoritative Server Model:** Server validates all game state
- **Client Prediction:** Local movement prediction for responsiveness
- **Server Reconciliation:** Correct client state on mismatch
- **Rollback:** Support for lag compensation in combat

#### 7.1.2 Session Types
- **Public Matchmaking:** Queue for random opponents
- **Private Lobbies:** Custom games with invite codes
- **Ranked Queue:** Skill-based matchmaking (post-launch)

### 7.2 Matchmaking

#### 7.2.1 Casual Matchmaking
- Player pool segmentation by game count (new vs. experienced)
- Region-based matching for latency
- Flexible party sizes (1-4 players)
- Backfill for disconnected players (pre-game only)

#### 7.2.2 Ranked Matchmaking (Future)
- Skill rating system (Elo-based or Glicko-2)
- Placement matches (10 games)
- Rank tiers: Bronze, Silver, Gold, Platinum, Diamond, Master
- Seasonal resets with rewards

### 7.3 Anti-Cheat Considerations

#### 7.3.1 Puzzle Integrity
- Server-side puzzle solution validation
- Client-server time synchronization
- Suspicious solve time flagging
- Automated and manual review systems

#### 7.3.2 Combat Integrity
- Server-authoritative hit detection
- Movement validation
- Statistical anomaly detection
- Report system with review process

### 7.4 Social Features

#### 7.4.1 Communication
- Pre-game lobby text chat
- Ping system during match (location markers)
- Post-game lobby with all players
- Emote wheel (no voice chat in MVP)

#### 7.4.2 Social Systems
- Friends list
- Recent players list
- Block/mute functionality
- Party system for queuing together

### 7.5 Reconnection

#### 7.5.1 Disconnect Handling
- 30-second grace period for reconnection
- AI takeover during disconnect (basic behavior)
- Full state restoration on reconnect
- Disconnect during combat = vulnerable (not invincible)

#### 7.5.2 Abandonment
- Players who abandon receive penalties (casual: none, ranked: rating loss)
- Remaining players continue match
- Abandoned player's dungeon is sealed
- Coin/reward penalty for abandoner

---

## 8. Roguelike Elements

### 8.1 Procedural Generation

#### 8.1.1 Dungeon Generation Algorithm

**Room Graph Generation**
1. Generate base graph with critical path (8-12 rooms)
2. Add branch rooms (2-4 per dungeon)
3. Place special rooms (shop, treasure, secret)
4. Assign puzzle types based on progression
5. Scale difficulty per room position

**Room Layout Generation**
1. Select room template from pool
2. Procedurally place puzzle elements
3. Add decorative and interactive objects
4. Validate solvability
5. Place loot and coin spawns

#### 8.1.2 Puzzle Procedural Elements

**Logic Puzzles**
- Grid sizes vary
- Clue sets procedurally generated
- Verification: automated solver confirms single solution

**Escape Room Puzzles**
- Object placement from position pools
- Clue content from themed sets
- Combination values randomized
- Verification: all components accessible and logical

**Environmental Puzzles**
- Object counts and positions
- Target locations
- Obstacle placement
- Verification: physics simulation confirms solvability

### 8.2 Run Variance

#### 8.2.1 Item Pools
- **Common Pool:** Always available items (70% of drops)
- **Uncommon Pool:** Periodic rotation (25% of drops)
- **Rare Pool:** Low spawn rate (5% of drops)
- **Legendary Pool:** One per dungeon maximum, guaranteed final room

#### 8.2.2 Shop Variance
- 4 item slots per shop
- Items drawn from daily rotation pool
- Prices vary +/-20% from base
- One "deal of the day" discounted item

#### 8.2.3 Build Diversity
- No permanent unlocks that affect power
- All combat options available from item drops
- Character choice affects playstyle, not power level
- Encourages adaptation to what's offered

### 8.3 Randomness Philosophy

#### 8.3.1 Player-Influenceable Randomness
- More rooms explored = more drops seen
- Faster completion = more shop access time
- Secret discovery = bonus loot tables
- Player skill affects outcome distribution

#### 8.3.2 Randomness Boundaries
- No run should be unwinnable due to RNG
- All players face equivalent randomness within a match
- Skill should overcome reasonable bad luck
- Lucky drops provide advantage, not auto-win

### 8.4 Replayability Features

#### 8.4.1 Daily Modifiers
- **Speed Demon:** Puzzle par times reduced by 25%
- **Treasure Hunt:** Double coin drops, half shop items
- **Trap Master:** Double trap placement for all
- **Fog of War:** No opponent progress indicators
- **Puzzle Rush:** Only logic puzzles appear

#### 8.4.2 Weekly Challenges
- Specific puzzle type focus
- Themed dungeon aesthetics
- Modified arena rules
- Limited weapon pools

#### 8.4.3 Seasonal Events
- Themed puzzle sets
- Special cosmetic rewards
- Limited-time game modes
- Community challenges

---

## 9. UI/UX Requirements

### 9.1 HUD Design

#### 9.1.1 Dungeon Phase HUD

**Always Visible**
- Health bar (top left)
- Coin counter (top left, below health)
- Room timer (top center)
- Opponent progress indicators (top right)
- Minimap (bottom right corner)
- Inventory quick-bar (bottom center)

**Contextual**
- Puzzle interface (center, when engaged)
- Hint button (near puzzle when available)
- Interaction prompts (near interactable objects)
- Item pickup notifications (center, brief)

#### 9.1.2 Arena Phase HUD

**Always Visible**
- Health bar with shield overlay (top left)
- Ammo counter (bottom right)
- Weapon indicator (bottom right)
- Consumable slots (bottom center)
- Kill feed (top right)
- Zone timer and damage warning (top center)
- Minimap with zone indicator (bottom left)

**Contextual**
- Damage indicators (screen edge, directional)
- Trap warnings (with detection items)
- Power-up spawn notifications

### 9.2 Menu Systems

#### 9.2.1 Main Menu
- Play (Quick Match / Ranked / Private)
- Characters (Selection / Customization)
- Collection (Cosmetics / Unlocks)
- Challenges (Daily / Weekly / Mastery)
- Settings
- Exit

#### 9.2.2 Character Select
- Character portrait with ability description
- Loadout customization (cosmetics only)
- Ready check system
- Timer (30 seconds max)

#### 9.2.3 Settings Menu
- Graphics (resolution, quality presets, individual options)
- Audio (master, music, SFX, voice, spatial audio)
- Controls (keybindings, sensitivity, accessibility)
- Gameplay (HUD scale, colorblind modes, hints toggle)
- Network (region preference, matchmaking options)

### 9.3 Puzzle Interfaces

#### 9.3.1 Logic Puzzle UI
- Full-screen puzzle view with escape option
- Clear input methods (click, drag, keyboard shortcuts)
- Undo/redo buttons
- Reset button
- Timer visible but not obstructive
- Hint access button with cost display

#### 9.3.2 Escape Room UI
- Minimal HUD overlay
- Item examination close-up view
- Inventory accessible via hotkey
- Combination input interfaces (keypads, locks)
- Clear back/cancel navigation

#### 9.3.3 Environmental Puzzle UI
- Standard game HUD
- Interaction highlights on hover
- Physics preview indicators where helpful
- Reset mechanism clearly marked

### 9.4 Accessibility

#### 9.4.1 Visual Accessibility
- Colorblind modes (deuteranopia, protanopia, tritanopia)
- High contrast UI option
- Scalable HUD elements (50-150%)
- Screen reader support for menus
- Puzzle element differentiation beyond color

#### 9.4.2 Audio Accessibility
- Visual alternatives for audio cues
- Closed captions for voice/sound effects
- Mono audio option
- Separate volume controls for all audio types

#### 9.4.3 Motor Accessibility
- Fully remappable controls
- Hold vs. toggle options for all held inputs
- Adjustable input timing windows
- Auto-aim assist (toggle, ranked restrictions)
- Single-stick movement option

#### 9.4.4 Cognitive Accessibility
- Puzzle hint system with adjustable delay
- Progress saving within puzzles
- Clear objective markers
- Difficulty options for private matches
- Practice mode for puzzle types

### 9.5 Feedback Systems

#### 9.5.1 Visual Feedback
- Clear hit markers (damage dealt)
- Damage direction indicators
- Puzzle progress animations
- Achievement/unlock celebrations
- Subtle camera effects for impacts

#### 9.5.2 Audio Feedback
- Distinct sounds for all actions
- Spatial audio for positional awareness
- UI confirmation sounds
- Victory/defeat musical stingers

#### 9.5.3 Haptic Feedback (Controller)
- Weapon fire rumble
- Damage taken pulses
- Puzzle completion buzz
- Trap trigger warning

---

## 10. Art Style Direction

### 10.1 Visual Identity

#### 10.1.1 Style Overview
**Stylized Low-Poly Fantasy**
- Geometric, angular aesthetic
- Bold, readable silhouettes
- Vibrant color palette with fantasy undertones
- Balance between whimsy and tension

#### 10.1.2 Reference Touchstones
- Zelda: Link's Awakening (remake) - Charm and readability
- Hades - Character design and color use
- Slay the Spire - UI clarity and iconography
- Escape Academy - Puzzle room aesthetic

### 10.2 Environment Art

#### 10.2.1 Dungeon Themes (Initial Set)

**The Scholar's Library**
- Dusty bookshelves, floating candles, ancient tomes
- Warm browns, golds, deep reds
- Puzzles themed around books, symbols, knowledge

**The Alchemist's Laboratory**
- Bubbling vats, ingredient shelves, arcane equipment
- Greens, purples, sickly yellows
- Puzzles themed around chemistry, combinations, reactions

**The Clockwork Vault**
- Gears, pistons, brass mechanisms
- Copper, bronze, silver metallics
- Puzzles themed around timing, sequences, machinery

**The Crystal Cavern**
- Glowing crystals, underground lakes, natural formations
- Blues, purples, cyan glows
- Puzzles themed around light, reflection, nature

#### 10.2.2 Arena Theme
- Colosseum-style circular arena
- Neutral stone with colored player-zone indicators
- Destructible wooden and stone cover
- Elevated central platform
- Hazard areas visually distinct (lava cracks, spike zones)

### 10.3 Character Art

#### 10.3.1 Design Principles
- Distinct silhouettes for each character
- Readable at all zoom levels
- Clear front/back distinction
- Expressive faces and animations
- Costume variations maintain silhouette

#### 10.3.2 Character Proportions
- Slightly stylized proportions (larger heads, hands)
- 6-head tall ratio (heroic but approachable)
- Exaggerated expressions for readability
- Clear class/archetype visual language

### 10.4 UI Art

#### 10.4.1 Visual Language
- Parchment and wood textures for menus
- Gold and silver accents for headers
- Hand-drawn quality for icons
- Consistent border and frame styles
- Clear hierarchy through size and color

#### 10.4.2 Puzzle UI Art
- Clean, minimal puzzle frames
- High contrast for puzzle elements
- Themed decorative borders matching dungeon
- Clear feedback states (correct, incorrect, selected)

### 10.5 Effects and Animation

#### 10.5.1 Particle Effects
- Stylized, shape-based particles
- Color-coded by type (damage, heal, buff)
- Non-intrusive during gameplay
- Celebration-worthy for victories

#### 10.5.2 Animation Priorities
- Snappy, responsive character movement
- Clear attack anticipation and recovery
- Satisfying puzzle completion flourishes
- Environmental idle animations for atmosphere

---

## 11. Audio Design

### 11.1 Music Design

#### 11.1.1 Adaptive Music System
Music dynamically responds to game state:

**Dungeon Phase Music**
- Base layer: Ambient, mysterious
- Puzzle engagement layer: Adds tension/focus
- Near-solution layer: Building anticipation
- Solution: Triumphant sting, return to base
- Speed pressure: Tempo increase when behind

**Arena Phase Music**
- Pre-combat: Tension building
- Combat engaged: Action intensity
- Final two: Maximum intensity
- Victory/defeat: Appropriate stingers

#### 11.1.2 Theme Variations
Each dungeon theme has unique music arrangements:
- Library: Orchestral, mysterious
- Laboratory: Synthetic, bubbling undertones
- Clockwork: Mechanical rhythms, ticking
- Crystal: Ethereal, choral elements

### 11.2 Sound Effects

#### 11.2.1 Puzzle Audio

**Interaction Sounds**
- Object pickup: Satisfying weight
- Object placement: Confirming thunk
- Mechanism activation: Appropriate mechanical
- Lock opening: Rewarding click-clack

**Feedback Sounds**
- Correct action: Ascending chime
- Incorrect action: Gentle buzz (not punishing)
- Hint activation: Mysterious reveal
- Puzzle complete: Triumphant fanfare

#### 11.2.2 Combat Audio

**Weapon Sounds**
- Each weapon type has distinct audio signature
- Rarity affects audio quality (more reverb, bass)
- Spatial audio for directional awareness
- Ammo low: Subtle warning tone

**Impact Sounds**
- Hit confirms: Satisfying impact
- Headshots/crits: Elevated impact
- Shield vs. health: Different texture
- Death: Dramatic but not gruesome

#### 11.2.3 UI Audio
- Button clicks: Subtle, consistent
- Menu navigation: Soft tones
- Error states: Clear but not annoying
- Celebration: Joyful without being overwhelming

### 11.3 Voice Design

#### 11.3.1 Character Voice
- Each character has distinct voice personality
- Contextual barks: puzzle progress, combat, victory/defeat
- Not excessive: 1-2 lines per major event
- Subtitled for accessibility

#### 11.3.2 Announcer (Optional)
- Match start/end announcements
- Phase transition callouts
- Final player remaining announcement
- Can be toggled off

### 11.4 Spatial Audio

#### 11.4.1 3D Audio Implementation
- Full 3D positioning for combat sounds
- Environmental reverb matching room type
- Occlusion for sounds behind walls
- Distance attenuation for all sound sources

#### 11.4.2 Audio Cues
- Opponent footsteps audible at range
- Puzzle interaction sounds in shared spaces
- Trap trigger audio warnings
- Power-up spawn audio indicators

---

## 12. MVP Features vs Future Features

### 12.1 MVP Scope Definition

The Minimum Viable Product (MVP) represents the smallest feature set that delivers the core game experience and validates the concept.

### 12.2 MVP Features (Launch Required)

#### 12.2.1 Core Gameplay
- [x] 2-4 player matchmaking
- [x] Single dungeon theme (Scholar's Library)
- [x] 6 puzzle types (2 each category)
- [x] 8-room dungeon generation
- [x] Basic loot system (3 weapon types, consumables)
- [x] Single arena map
- [x] Core combat loop (shoot, move, dodge)
- [x] Preparation phase with trap placement
- [x] Information asymmetry for first finisher

#### 12.2.2 Progression
- [x] Basic XP and leveling (50 levels)
- [x] 4 base characters with unique abilities
- [x] Daily challenges (3 per day)
- [x] Basic cosmetic unlocks (10 skins)

#### 12.2.3 Multiplayer
- [x] Public matchmaking
- [x] Private lobby system
- [x] Basic anti-cheat
- [x] Reconnection support
- [x] Text chat (lobby only)

#### 12.2.4 UI/UX
- [x] Full HUD implementation
- [x] All menu systems
- [x] Settings with essential options
- [x] Basic colorblind support
- [x] Remappable controls

#### 12.2.5 Content
- [x] 1 dungeon theme with full art
- [x] 1 arena with full art
- [x] 4 playable characters
- [x] 3 weapon types (Pistol, Shotgun, Rifle)
- [x] 6 puzzle types
- [x] 3 trap types

### 12.3 Post-Launch Priority Features (Phase 1: 1-3 Months)

#### 12.3.1 Content Expansion
- [ ] Second dungeon theme (Alchemist's Laboratory)
- [ ] 4 additional puzzle types
- [ ] 2 new weapon types (SMG, Crossbow)
- [ ] 2 new trap types
- [ ] Second arena map

#### 12.3.2 Feature Expansion
- [ ] Ranked matchmaking with ladder
- [ ] Weekly challenges
- [ ] Battle pass (Season 1)
- [ ] 2 additional characters
- [ ] Voice chat (push-to-talk)

#### 12.3.3 Quality of Life
- [ ] Replay system
- [ ] Improved statistics tracking
- [ ] Tutorial improvements
- [ ] Practice mode expansion

### 12.4 Future Features (Phase 2: 3-6 Months)

#### 12.4.1 Major Content
- [ ] Third dungeon theme (Clockwork Vault)
- [ ] Fourth dungeon theme (Crystal Cavern)
- [ ] Third arena map
- [ ] 4 more characters (12 total)
- [ ] Legendary weapon tier

#### 12.4.2 Game Modes
- [ ] Team mode (2v2)
- [ ] Tournament support
- [ ] Daily challenge mode (solo time attack)
- [ ] Custom game modifiers

#### 12.4.3 Social Features
- [ ] Clan/team system
- [ ] Spectator mode
- [ ] Clip capture and sharing
- [ ] Leaderboards (global and friends)

### 12.5 Long-Term Vision (6+ Months)

#### 12.5.1 Platform Expansion
- [ ] Console ports (PlayStation, Xbox, Switch)
- [ ] Cross-platform play
- [ ] Mobile companion app

#### 12.5.2 Content Expansion
- [ ] Seasonal dungeon themes
- [ ] Community puzzle creation tools
- [ ] Narrative campaign mode
- [ ] Boss battle events

#### 12.5.3 Competitive Features
- [ ] Esports infrastructure
- [ ] Ranked seasons with exclusive rewards
- [ ] Professional tournament tools
- [ ] Coaching/replay analysis tools

### 12.6 Development Milestones

| Milestone | Target Date | Deliverables |
|-----------|-------------|--------------|
| Prototype | T+2 months | Core loop playable (puzzle → arena) |
| Alpha | T+4 months | Full MVP features, placeholder art |
| Closed Beta | T+6 months | Polished MVP, limited player testing |
| Open Beta | T+8 months | Stress testing, balance tuning |
| Launch | T+10 months | Full MVP release |
| Phase 1 | T+13 months | Post-launch content wave 1 |
| Phase 2 | T+16 months | Post-launch content wave 2 |

### 12.7 Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Puzzle generation too slow | Medium | High | Pre-generate puzzle pools, validate offline |
| Network latency affects fairness | High | High | Server-side puzzle timing, generous thresholds |
| Combat feels tacked-on | Medium | High | Focus combat testing early, iterate heavily |
| Puzzle variety insufficient | Medium | Medium | Modular puzzle design, community feedback |
| Player count concerns | Medium | High | Bot support for underfilled matches |

---

## Appendix A: Glossary

- **Par Time:** Expected solve time for a puzzle at medium skill level
- **Prep Time:** Time in preparation phase before arena
- **Information Asymmetry:** Advantage gained through exclusive knowledge
- **Procedural Generation:** Algorithm-driven content creation
- **TTK (Time-to-Kill):** Average time to eliminate an opponent

## Appendix B: Technical Requirements (High-Level)

- **Engine:** Godot 4.x
- **Networking:** Dedicated server model with client prediction
- **Platform:** PC (Windows, Linux, macOS)
- **Minimum Spec:** TBD based on art fidelity
- **Target Frame Rate:** 60 FPS
- **Resolution Support:** 1080p to 4K, ultrawide support

## Appendix C: Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-30 | Product Manager | Initial document creation |

---

*This document is a living artifact and will be updated as development progresses and design decisions are validated through playtesting.*
