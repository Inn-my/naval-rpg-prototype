# naval-rpg-prototype

2D top-down mobile naval trading/combat RPG. Full design spec: `docs/design-blueprint.md`.

## Phase 1: touch steering prototype

Open this folder as a Godot **4.3+** project and run it (`scenes/Main.tscn` is the main scene).

- Drag from the left half of the screen: a fixed anchor ring (bottom-left) sets a target heading + throttle via Relative Vector Guidance — not a floating joystick.
- The ship turns to face that heading using a PID controller (`scripts/ship.gd`) whose damping term is auto-tuned per hull from its mass, so heavy hulls turn slowly but never overshoot.
- Buttons top-right swap between three hull presets (`resources/ship_presets/`) for feel comparison: Sloop (small/fast), Corvette (medium), Galleon (heavy/slow).
- No targeting, combat, or trade yet — steering only, per the Phase 1 roadmap.

In the editor, mouse drag emulates touch (`input_devices/pointing/emulate_touch_from_mouse` is enabled), so no device is required to try it.