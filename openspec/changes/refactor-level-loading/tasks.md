# Tasks

1. [ ] **Update `LevelLootEntry` and `LevelTaskEntry` composition (Pre-requisite)**
	* Verify `LevelLootEntry` and `LevelTaskEntry` directly inherit from `Resource` without unnecessary intermediate inheritance.
	* Ensure they use `CombatStats` composition for attribute management.

2. [ ] **Update `json_to_tres.py` Export Targets**
	* Modify `build_level_loot_entry` to save directly as `.tres` (no longer wrapped in `LevelLootRow`).
	* Modify `build_level_task_entry` (for locations) to save directly as `.tres` (no longer wrapped in `LevelTaskRow`).
	* Modify `build_level_unit_spawn_entry` to save directly as `.tres` (no longer wrapped in `LevelRosterRow` or `LevelStartRow`). Combine start and roster logic if necessary, using `faction` to differentiate.
	* Modify `build_level_dialogue_entry` to save directly as `.tres` (no longer wrapped in `LevelDialogueRow`).
	* Ensure terrain rows are saved as a single `LevelTerrainData` resource directly instead of individual `LevelTerrainRow` objects.
	* Ensure meta rows are saved as a single `LevelMeta` resource directly.

3. [ ] **Simplify `LevelRowLoader.gd`**
	* Remove `_build_roster_definition`, `_build_loot_definition`, `_build_location_entries`.
	* Update `_load_rows_from_path` to cast directly to `LevelUnitSpawnEntry`, `LevelLootEntry`, etc.
	* Update `_apply_combat_rows` to simply assign the loaded arrays directly to `level.enemy_spawns`, `level.neutral_spawns`, `level.loot`, and `level.locations`.
	* Remove all `_copy_stats` logic from `LevelRowLoader`, as the entries are fully formed by `json_to_tres.py`.
	* Ensure `apply_rows_to_level` correctly handles the new direct assignments.

4. [ ] **Remove Deprecated Row Resources**
	* Delete `level_roster_row.gd`
	* Delete `level_start_row.gd`
	* Delete `level_loot_row.gd`
	* Delete `level_task_row.gd`
	* Delete `level_dialogue_row.gd`
	* Delete `level_terrain_row.gd`
	* Delete `level_meta_row.gd`
	* Delete `base_level_row.gd` and `base_level_row_with_coord.gd` if they are no longer used by any other classes.

5. [ ] **Update Tests and Validation**
	* Run `run_tests.ps1` to catch any broken references.
	* Run `json_to_tres.py` and verify level data is generated cleanly.
	* Run the game and load a level to ensure spawns, loot, and terrain appear correctly.
