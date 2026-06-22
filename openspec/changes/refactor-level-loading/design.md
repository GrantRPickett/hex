# Level Loading Refactor

## Current State & Issues

Currently, `LevelRowLoader` in `level_row_loader.gd` reads a variety of intermediate `Resource` types (like `LevelLootRow`, `LevelStartRow`, `LevelTaskRow`, etc.), runs a validation pass over them (`LevelRowValidator`), and then builds game-specific representations like `UnitRosterDefinition` or arrays of `LevelLootEntry`, `LevelTaskEntry`, `LevelDialogueEntry`, etc.

The user noted: "using openspec review how the resources are eventually converted into nodes and suggest a way to avoid a bunch of unneeded steps".

Indeed, the current process is heavily layered:

1. JSON is parsed by `json_to_tres.py`.
2. `json_to_tres.py` creates `.tres` files storing instances of `Level*Row` resources (which extends `BaseLevelRowWithCoord`).
3. During runtime loading, `LevelRowLoader` grabs all these `.tres` files by directory (`roster_rows/`, `loot_rows/`, etc.).
4. `LevelRowLoader` copies data from `Level*Row` into structurally similar but separate entry classes (`LevelUnitSpawnEntry`, `LevelLootEntry`, `LevelTaskEntry`, etc.) using functions like `_build_roster_definition`, `_build_loot_definition`, `_build_location_entries`, and a brute-force `_copy_stats()` property mapper.
5. These entry resources are then placed onto the `Level` object.
6. A `LevelBuilder` or `TargetSpawner` ultimately takes these entry objects and instantiates the matching `PackedScene`, applying the data.

**Key Issues / "Unneeded Steps":**

- **Redundant Data Structures:** We have `LevelLootRow` (the persisted resource) and `LevelLootEntry` (the runtime resource), which hold almost identical data.
- **Fragile Copying:** `LevelRowLoader._copy_stats` was using literal property checks/assignments. We recently moved to composition via `CombatStats`, but the duplication of the container classes remains.
- **Needless Translation:** The translation from Row -> Entry provides little value since both are `Resource` types that Godot can load directly.

## Proposed Architecture

The core proposal is to **eliminate the distinction between "Row" resources and "Entry" resources**, streamlining the pipeline from disk to nodes.

1. **Unify Resource Types:**
   - Deprecate `LevelRosterRow`, `LevelLootRow`, `LevelTaskRow`, `LevelStartRow`, `LevelDialogueRow`.
   - Update `json_to_tres.py` to directly generate `LevelUnitSpawnEntry`, `LevelLootEntry`, `LevelTaskEntry`, etc. (Many of these already exist and have the required fields via the recent composition refactor).
   - *Wait, `json_to_tres.py` actually DOES generate `LevelUnitSpawnEntry`, `LevelLootEntry`, etc., as SUB-RESOURCES inside the Row files? No, looking closely at `json_to_tres.py`, it generates both. It builds an entry as a sub-resource, and then builds a Row resource that contains properties... wait, no. Let's look at `build_level_loot_entry` vs the row building. The rows ARE the main resource.*

   **Correction on Current State based on latest code:**
   `json_to_tres.py` currently writes out `Level*Row` resources.

   **Simplified Pipeline:**
   - `json_to_tres.py` should just export lists of the final entry types directly attached to a single `Level` resource, OR export individual `LevelUnitSpawnEntry`, `LevelLootEntry`, etc. files.
   - Ideally, `json_to_tres.py` creates a *single* `Level` `.tres` file containing all the entries as sub-resources, or arrays of entries. This eliminates the need for `LevelRowLoader` to crawl directories and stitch things together at runtime.

2. **Phase 1: Merge Rows and Entries**
   - Make `LevelUnitSpawnEntry` the ONLY data type for spawns. Add any missing fields from `LevelRosterRow`/`LevelStartRow` to it (like `faction` or `slot_index`).
   - Do the same for Loot, Tasks, Dialogue, and Journal entries.
   - Delete the `*Row.gd` classes entirely.

3. **Phase 2: Streamline LevelRowLoader**
   - If we must keep individual `.tres` files per entity, `LevelRowLoader` just loads them and appends them to the `Level`'s arrays. No `_build_...` translation functions needed.
   - The `Level` resource directly holds `Array[LevelUnitSpawnEntry]`, `Array[LevelLootEntry]`, etc.

4. **Phase 3: Refactor Node Instantiation (TargetSpawner / LevelBuilder)**
   - The actual `PackedScene` instantiation should consume these Entry resources directly. TargetSpawner already does this for `LevelUnitSpawnEntry`, `LevelLootEntry`, etc.
   - By removing the intermediate "Row" types, the pipeline is simply: `json_to_tres.py` -> `[EntryResource].tres` -> `TargetSpawner` loads `EntryResource` and spawns `PackedScene`.

## Benefits

- **Less Code:** Deletes 5+ duplicated classes (`*Row.gd`) and hundreds of lines of fragile mapping code in `LevelRowLoader` and `json_to_tres.py`.
- **Fewer Bugs:** No more "forgot to copy a property" bugs (like the recent `stats` oversight).
- **Faster Loads:** Less processing per resource at runtime.
