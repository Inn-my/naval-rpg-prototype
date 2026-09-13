# Hybrid Mobile RPG Design Blueprint
## Comprehensive Architecture and Design Specification for an Open-World Mobile Trading and Naval Combat RPG

## 1. Reference Titles

Two reference titles inform this hybrid design:

- **Space RPG 4 (Esaptonor)** — real-time, top-down Newtonian ship piloting, modular subsystem outfitting, continuous combat, multi-vessel fleet orchestration across 250 star systems.
- **Pirates & Traders: Gold! (MicaBytes)** — turn-based, historical Caribbean setting, tabletop-style attribute matrices, supply-demand trade arbitrage, discrete event-driven encounters.

### Known flaws to resolve

**Space RPG 4:**
- Floating virtual joystick + unmodified rotational inertia causes over-steering and drift on entry-level hulls.
- Target cycling often locks onto irrelevant distant ships instead of immediate threats; manual retargeting forces players to lift thumbs off flight controls mid-combat.
- Mission difficulty shown only as vague narrative text — "standard" missions can spawn capital ships that wipe the player's fleet with no warning.
- Escort ships can spawn far from the flagship on hyper-jump arrival, isolating it inside hostile battlegroups.
- Poorly telegraphed environmental hazards can annihilate fleets instantly on arrival.

**Pirates & Traders: Gold!:**
- Boarding/combat resolution uses opaque dice rolls; a 250-strong attacking force can rout against 30 defenders due to a single bad morale roll, defying tactical plausibility.
- Player is restricted to a single ship for the entire campaign — no fleet, no escorts, no convoy logistics.
- No cargo purchase-price tracking — players must manually record buy prices to calculate margins.

## 2. Unified Hybrid Architecture

| Dimension | Space RPG 4 | Pirates & Traders: Gold! | Unified Hybrid |
|---|---|---|---|
| Execution | Real-time, decoupled sim/render threads | Turn-based, discrete state transitions | Real-time pausable kinetic combat + tick-based macro navigation |
| Vessel Control | Floating joystick, angular inertia | Abstract menu actions | Dual-mode tactile control: direct vector touch + PID angular dampening |
| Fleet Structure | Multi-vessel, aggregated cargo, basic AI stances | Single-ship only | Hierarchical squadron command, tactical stances, cargo pooling, officer roles |
| Progression | Currency + subsystem tiers | Aptitude-gated skills, annual point gates | Aptitude/skill progression tied to gameplay actions, no time gates |
| Economy | Variable pricing, individual haggling | Dynamic supply-demand across ports | Macro supply-demand model with tariffs, merchant disposition |
| Combat | Real-time projectile physics, subsystem targeting | Probabilistic skill checks, broadside rolls | Deterministic gunnery + transparent Lanchester attrition boarding |

## 3. Kinetic Control Architecture (Phase 1 focus)

- **Relative Vector Guidance** replaces the floating analog stick: touching/dragging within the left screen quadrant sets a directional vector.
- **PID angular dampening** eliminates over-steer and drift:

  τ = Kp·θe + Ki·∫θe dt + Kd·θė

  where θe is the signed angular error between current heading and target vector angle. Kp and Kd are tuned per vessel mass for precise, dead-stop alignment even on heavy hulls.

- **Forward arc-cone auto-targeting**: scans a 60° forward arc from the prow, scoring candidates:

  S = wd·(1 − d/dmax) + wθ·cos(θoffset) + wv·Vthreat

  A single tap cycles candidates within this arc, prioritizing threats actively engaging the flagship. An explicit clear-target button disengages lock instantly.

## 4. Threat Modeling (Phase 4)

- **Effective Combat Power (ECP)** combines hull/armor/maneuver stats, weapon DPS, and tactics skill into one score per fleet.
- **Threat Ratio (TR)** = ECP(hostile) / ECP(player fleet), shown via a 5-tier color scale (Green/Blue/Amber/Crimson/Skull) before accepting contracts or jumping sectors.
- **Hyper-jump arrival**: escorts exit warp in a fixed wedge formation with defined offsets from the flagship; hostiles are barred from spawning within a 150m radius.

## 5. Deterministic Combat (Phase 4)

- Boarding uses **Lanchester's Square Law** for troop attrition (function of Gear ratio and Physical/Vigor skills), not random rolls.
- **Continuous morale decay** (not a single dice check) based on casualty rate and Leadership skill; a force only routs below a fixed critical threshold (Mcrit = 15).

## 6. Fleet Management (Phase 3)

- Subordinate vessels pool cargo/fuel into a shared fleet inventory.
- Tactical stances: **Defensive Escort**, **Aggressive Interception**, **Evasive Screen** — toggled live via HUD.
- Officers (Gunner, Carpenter, Pilot, Cook) can be assigned to individual ships for stat boosts and repair-over-time.

## 7. RPG & Economy (Phase 4)

- Three aptitudes — **Physical (Vigor)**, **Intellectual (Cunning)**, **Social (Charisma)** — gating 15 skills across combat, navigation, and commerce.
- XP awarded by activity type (boarding → Physical, navigation/fleet maneuvers → Intellectual, trade/diplomacy → Social); no annual point gates.
- Commodity pricing model:

  P(c,m) = Bc × (1 + γc · [(Dc,m − Sc,m)/(Dc,m + Sc,m + ε)]) × (1 + δevent) × (1 − Bargaining/200) · μrep

- Cargo ledger auto-tracks average buy price and margin per commodity (removes manual note-taking).

## 8. Vessel Hierarchy

12 classes from Pinnace/Courier (scout, cheap, low cargo) up to Manila Galleon (max firepower/capacity), each with defined hull integrity, maneuver rating, hardpoints, crew, and cargo hold — see full table in original spec for exact stat blocks.

## 9. Technical Architecture

- **Engine: Godot 4.3+** — dedicated 2D pipeline, <35MB export footprint, decoupled physics (`_physics_process` @ 60Hz) from rendering (`_process`), zero licensing cost.
- **SimulationCore**: headless data layer for ships/projectiles/cargo, updated on physics ticks; view layer only interpolates positions between ticks.
- **Persistence: SQLite 3 via GDExtension**, WAL journal mode, for atomic saves and non-blocking concurrent reads (tables: CampaignState, CharacterSheet, FleetVessels, VesselOutfitting, ConsolidatedCargo, PortMarketState, MissionLog).
- **Cloud sync**: Google Play Games Cloud Save / Apple iCloud, `PRAGMA wal_checkpoint(TRUNCATE)` before upload, vector-clock conflict detection with era-day tiebreaker and manual arbitration screen for irreconcilable conflicts.

## 10. Production Roadmap

| Phase | Timeline | Focus | Deliverable |
|---|---|---|---|
| 1 | Months 1–3 | Kinetic flight & steering | Playable prototype: drift-free touch steering across small/medium/heavy hulls |
| 2 | Months 4–6 | Relational DB & trade | Full economic loop: buy/sell/sail/hard-quit with DB integrity |
| 3 | Months 7–9 | Squadron AI & logistics | Multi-ship tactical slice: flagship + 2 autonomous escorts |
| 4 | Months 10–13 | Combat systems & RPG matrix | Feature-complete beta: full leveling, deterministic boarding, FTI UI |
| 5 | Months 14–16 | Cloud sync & optimization | Production-ready release candidate |

---
*Condensed from the original design specification for use as an in-repo reference document.*
