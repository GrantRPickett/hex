# HEX Glossary

Use this glossary when an unfamiliar term appears in tasks, specs, or TODOs. Each entry links to an authoritative file or directory so LLM agents can jump to source material and avoid stale assumptions.

## Core Systems
- **GameSession** (`Gameplay/game_session.gd`): Orchestrates command execution, turn state transitions, and component updates for the active level.
- **GameState** (`Gameplay/game_state.gd`): Data model representing current units, objectives, and timeline metadata; serialized between turns and referenced by AI.
- **Command Pattern** (`COMMAND_PATTERN_GUIDE.md`): Input → Command → Handler architecture for unit actions, menu flows, and tool scripts.
- **Autoload** (`Autoloads/`): Godot singletons providing global services (LevelManager, SaveManager, InputMapper) shared across menus and gameplay.
- **Component** (`Gameplay/targets/components/`): Modular behavior blocks attached to units, e.g., `action_points_component.gd`, `inventory_component.gd`.

## Narrative & Tasking
- **Task** (`Gameplay/narrative/task/`): Story or gameplay objective definitions that bundle triggers, stages, and rewards.
- **Stage Spawn Entry** (`Gameplay/narrative/task/stage_spawn_entry.gd`): Data structure describing units spawned per stage, including faction and loadouts.
- **Task Validator** (`Gameplay/narrative/task/task_validator.gd`): Validation logic ensuring narrative tasks can execute given the current GameState.
- **Task Controller** (`Gameplay/narrative/task/task_controller.gd`): Runtime coordinator that advances stages, fires interactions, and tracks completion signals.

## Level Building
- **Level Resource** (`level/Level.gd`, `Resources/level_data/`): Resource defining grid geometry, objectives, spawn lists, and meta tags.
- **Level Builder** (`level/level_builder.gd`): Tool/service assembling grid tiles, props, and interactive objects from a Level resource.
- **Level Validator Suite** (`level/validation/`): Scripts (e.g., `grid_utils.gd`, `level_data_validator.gd`) that ensure level rows, spawns, and logs meet standards before playtests.
- **Spawn Utils** (`level/validation/spawn_utils.gd`): Helpers for enforcing spawn spacing, faction counts, and accessible entry points.

## AI & Turn Flow
- **Task Evaluator** (`Gameplay/turn/ai/task_evaluator.gd`): AI scoring for available tasks per unit or faction during auto-battle simulations.
- **Loot Evaluator** (`Gameplay/turn/ai/loot_evaluator.gd`): Determines post-combat rewards and drop chances.
- **Movement Range Cache** (`Gameplay/targets/components/movement_range_cache.gd`): Performance helper caching reachable tiles per action point budget.

## Resources & Data
- **File Paths Registry** (`Resources/file_paths.json`, `Documentation/FILE_PATHS_GUIDE.md`): Central place to map logical asset names to disk paths.
- **JSON ↔ TRES Converters** (`scripts/json_to_tres.py`, `scripts/patch_json_to_tres.py`): Scripts that synchronize JSON definitions with Godot `.tres` assets.
- **Save Manager** (`Autoloads/save_manager.gd`): Handles serialization of player roster, progress, and custom configs.

## Testing & Tooling
- **GdUnit4 Suite** (`tests/`): Automated tests referenced in `TEST_COVERAGE_ANALYSIS.md` and enforced by `scripts/validate.ps1`.
- **Validation Script** (`scripts/validate.ps1`): Runs Godot tests, function coverage, and TODO updates before merges.
- **Auto Battle Diagnostics** (`Gameplay/turn/auto_battle_diagnostics.gd`): Debug support for AI turns, logging probabilities and actions.

## Collaboration Notes
- Keep glossary entries short and point to living files. When major refactors happen, update both the glossary and the underlying doc to prevent drift.
- If a new term becomes commonplace, add it here with a link to the owning script or spec.
