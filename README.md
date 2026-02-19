# HEX

HEX is a small Godot 4 tactical RPG prototype that plays out on a hexagonal grid. Players control a party of units to complete level objectives, fighting enemies and managing resources. The project lives entirely in this repository and ships with editor tooling plus a GdUnit4 suite so every gameplay or menu change stays verifiable.

## Gameplay and Structure

- **Menus** (`Menus/`) contain the title screen, level select, credits, pause, and controls overlays. `title_screen.tscn` boots the project, hands off to `LevelManager`, and exposes shortcuts via `ControlSettings`.
- **Gameplay** (`Gameplay/gameplay.tscn` + `Gameplay/gameplay.gd`) renders the grid, handles movement/selection input, and manages the turn-based flow of the game. It emits `level_complete()` or `quit_to_title` when the run ends.
- **Combat** is handled by the `CombatSystem` (`Gameplay/combat_system.gd`), which manages attacks, counters, and damage calculation based on unit stats.
- **Units** (`Gameplay/unit.gd`) are the primary actors in the game, with attributes, skills, inventories, and action points. They can belong to different factions (Player, Enemy, Neutral).
- **Resources** host scripts and data that scenes share. `Resources/hex_utils.gd` contains helpers for addressing the axial grid, and `Resources/Level.gd` defines a `Level` resource with all of the gameplay tuning knobs.
- **Autoloads** wire global managers together:
  - `control_settings.gd` remembers custom key/button bindings and allows "press anything to start" behavior.
  - `input_mapper.gd` turns the configuration dictionaries into project actions so gameplay can stay declarative.
  - `game_config.gd` reads/writes `user://hex_config.cfg` and emits change notifications for UI or future options.
  - `level_manager.gd` stores the ordered list of level resources, remembers the active one, and listens for gameplay signals to advance, roll credits, or return to the title.
  - `scene_transition.gd` centralizes scene changes so the UI can fade or schedule a delayed swap.
  - `audio_bus_controller.gd` and `event_bus.gd` are light wrappers around the engine buses/signals.
- **Tests** (`tests/`) are written with GdUnit4. They load real scenes with `scene_runner`, simulate inputs, and assert on both UI and gameplay state.

## Units

Units are the core of the gameplay. They are highly customizable and have a number of key properties:

- **Faction:** Each unit belongs to a faction, such as `PLAYER`, `ENEMY`, or `NEUTRAL`.
- **Attributes:** A unit's combat prowess is determined by its attributes, which are organized into pairs: `grit`/`flow`, `gusto`/`clarity`, and `shine`/`temper`.
- **Willpower and Morale:** `willpower` serves as a unit's health, while `morale` can also be affected during combat.
- **Action Points:** Units have a limited number of action points per turn, which can be spent on movement, attacks, or other abilities.
- **Skills:** Units can learn and use a variety of skills.
- **Inventory:** Each unit has its own inventory and can equip items to boost its stats or grant new abilities.
- **Status Effects:** Units can be affected by various status effects during gameplay.

## Combat

The `CombatSystem` manages the turn-based combat encounters. When one unit attacks another, the following happens:

1.  The attacker's relevant stat is compared against the defender's defense value.
2.  Damage is calculated and applied to the defender's `willpower`.
3.  The defender performs a counter-attack.
4.  The `attack_occurred` signal is emitted, allowing other game systems to react to the combat event.
5.  If a unit's `willpower` drops to zero, the `unit_defeated` signal is emitted.

## Level Resources and LevelManager

Level files live under `Resources/level_data/` and all extend `Resources/Level.gd`. Common exports include:

- `display_name`: shown in the level select screen.
- `grid_width`/`grid_height`: overrides the default 7x7 board.
- `player1_start`/`player2_start` and `goal_coord`/`goal2_coord`: spawn/goals per unit.
- `initial_camera_rotation`, `hex_offset_axis`: cosmetic alignment, axial offset (flat-top vs point-top tiles).

`LevelManager` owns the list/ordering of these resources through its exported `levels` array. You can edit the singleton in Godot's **Project > Project Settings > Autoload** inspector to drag in `.tres` files or call `LevelManager.set_levels([...])` in a tool script. The manager listens for the SceneTree's `scene_changed` signal, connects to `Gameplay`'s `level_complete`/`quit_to_title`, and reacts by:

1.  Changing scenes to `Gameplay` (reloading with the new level), `Menus/credits.tscn`, or `Menus/title_screen.tscn` when appropriate.
3.  Serving the currently selected path to `Gameplay` through `get_current_level_path()` so `_apply_level_if_available()` can load the resource and rebuild the grid.

The level select menu prefers `LevelManager.levels` for ordering/metadata but will fall back to scanning `Resources/level_data/` if the manager list is empty, which keeps iteration easy.

## Running the Game or Editor

Use the helpers under `scripts/` to keep tooling consistent:

- `pwsh -File scripts/godot_cli.ps1 -- --version` downloads/caches a matching Godot CLI (set `HEX_GODOT_EXE`/`GODOT_EXE` to reuse a local build).
- `pwsh -File scripts/godot_cli.ps1 -Run -- -e` launches the editor with the cached binary.
- `pwsh -File scripts/run_tests.ps1` runs the full GdUnit4 suite headlessly (`scripts\run_tests.cmd` exists for classic CMD).
- `pwsh -File scripts/validate.ps1 -UpdateTodos` executes the tests, runs the `scripts/check_function_tests.py` coverage guard, and keeps `reports/` trimmed to the most recent artifacts.

## Test Expectations

The suite under `tests/` exercises autoloads, gameplay, levels, menu flows, and pause/control workflows. Follow these conventions when contributing:

- Load scenes with `scene_runner("res://path")`, `await runner.simulate_frames(1)`, then drive inputs via `scene._unhandled_input` or helper methods.
- Prefer signal waits (for instance `await runner.simulate_until_object_signal(tree, "scene_changed")`) when a scene transition, fade, or completion determines the next assertion.
- New functions in gameplay/menus/resources must be paired with a test that references the function by name so the coverage checker passes.
- After local edits, run either `pwsh -File scripts/run_tests.ps1` and `python scripts/check_function_tests.py` or the single `scripts/validate.ps1 -UpdateTodos` entry point before opening a PR.

With these pieces in place you can add new levels by duplicating one of the `.tres` files, tweaking the exports, wiring it into `LevelManager.levels`, and letting the existing menus/tests confirm that the campaign flows correctly.
