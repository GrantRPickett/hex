# Refactor & Cleanup Ideas

Based on the `FUNCTION_OUTLINE.md`, here are several areas where code reuse can be improved and architecture can be tightened.

## 1. Centralize Resource Collection logic
**Problem**: `_collect_resources_recursive(path: String)` is duplicated in `achievement_manager.gd` and `journal_manager.gd`.
**Solution**: Move this logic to a utility class (e.g., `ResourceUtils.gd`) or a shared service. This reduces duplication and provides a single place to optimize file system scanning.

## 2. Standardize Component Lifecycle
**Problem**: Components in `Gameplay\targets\components\` use inconsistent initialization patterns. Some use `_init(unit)`, some use `setup(owner, ...)`, and others use `_ready()`.
**Solution**: Adopt a project-wide `BaseComponent` or a consistent `setup()` signature. This makes it easier to swap or add components dynamically and ensures all dependencies are injected predictably.

## 3. Consolidate Spatial Queries (Grid & Units)
**Problem**: `UnitManager`, `UnitQueryService`, `MapController`, and `TerrainMap` all have overlapping functions for checking occupancy, getting units at coordinates, and finding neighbors.
**Solution**: Create a unified `GridQueryService`. This service would act as a facade, combining data from the `UnitManager` (dynamic entities) and `TerrainMap` (static terrain) to answer questions like `is_cell_blocked(coord)` or `get_all_interactables_in_range(coord, range)`.

## 4. Refactor Movement Logic Service Chain
**Problem**: Movement logic is highly fragmented across `MoveController`, `MoveExecutionService`, `MoveRequestValidator`, and `UnitMovementBehavior`. `UnitMovementBehavior` often acts as a pass-through for `ActionPointsComponent`.
**Solution**: 
- Keep `UnitMovementBehavior` focused strictly on the unit's movement state and animation.
- Move "business logic" (AP costs, validation rules) entirely into the `MoveRequestValidator` and `MoveExecutionService`.
- Use the `ActionPointsComponent` directly where possible instead of creating proxy methods in the behavior.

## 5. Formalize Memento Pattern for Save/Load
**Problem**: `create_memento()` and `restore_from_memento()` are used in `SaveManager`, `WeatherManager`, `UnitManager`, and `GameState`, but each implementation is slightly different.
**Solution**: Define a standard `Savable` interface or base class. This ensures that every system that needs to participate in the "Undo/Redo" or "Save/Load" flow follows a predictable structure, making the `SaveManager` more robust.

## 6. Streamline Input-to-Command Flow
**Problem**: The path from a key press to an executed command goes through `InputHandler`, `InputMapper`, `InputController`, and finally a `GameCommand`.
**Solution**: Clarify the responsibilities:
- `InputHandler`: Pure event capture and debouncing.
- `InputMapper`: Translation of events to abstract `ActionNames`.
- `InputController`: Mapping `ActionNames` to specific `GameCommands` based on the current game context (e.g., selection vs. targeting).

## 7. Autoload Lifecycle Management
**Problem**: Many Autoloads have identical `_ready()` logic for loading configuration or initializing state.
**Solution**: If many services share a lifecycle (Load Config -> Setup -> Signal Ready), create a `BaseService` class for Autoloads to reduce boilerplate and ensure initialization order is handled consistently.

## 8. Redundant Math/Hex Logic
**Problem**: Hex-specific math (distance, neighbors, direction mapping) appears in `HexNavigator`, `MovementRangeCalculator`, and `GridVisuals`.
**Solution**: Ensure all low-level hex math is consolidated in `HexNavigator` or a dedicated `HexMath` static library.
