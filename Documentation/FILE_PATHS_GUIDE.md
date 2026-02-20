# Centralized File Paths Registry - Documentation

## Overview

The `Resources/file_paths.gd` file serves as a single source of truth for all file paths used throughout the HEX project. This centralization reduces the effort needed to refactor and move files around.

## Usage

```gdscript
# Import the file paths registry
const FilePaths = preload("res://Resources/file_paths.gd")

# Access paths by category
var gameplay_scene = FilePaths.Scenes.GAMEPLAY
var save_path = FilePaths.UserPaths.SAVE_GAME_FILE
var level_one = FilePaths.Resources.LEVEL

# Get all paths for debugging
var all_paths = FilePaths.get_all_paths()
```

## File Organization

The registry is organized into logical categories:

### 1. **Scenes** - Scene files (.tscn)
- Main gameplay and menu scenes
- GUI panel components

### 2. **Autoloads** - Global autoload scripts
- All autoloads registered in `project.godot`
- Accessible globally via singleton pattern

### 3. **Resources** - Resource class definitions
- Core gameplay resources (Level, Goal, Stage, etc.)
- Data structures for level configuration
- Dialogue and achievement system resources

### 4. **Gameplay** - Gameplay logic scripts
- Core gameplay systems (Unit, AI, Controllers)
- Terrain types and components
- Input command system
- Journal and task systems

### 5. **Directories** - Directory paths for scans
- Paths used with `DirAccess.list_dir_absolute()`
- Achievement, journal, and level data directories

### 6. **UserPaths** - Runtime config paths
- Configuration file paths (`user://`)
- Save game paths

### 7. **Addons** - Third-party addon paths
- GdUnit4 testing framework
- Dialogic dialogue manager
- Hexagon tilemaplayer

### 8. **Tests** - Test file paths
- GdUnit4 test suite files

### 9. **DynamicPaths** - Patterns for dynamically-built paths
- **Special handling required** - See warnings below

## ⚠️ WARNINGS - Paths That CANNOT Be Centralized

Some paths are constructed dynamically at runtime and cannot be fully centralized in this file. If you need to refactor directories containing these paths, use search-and-replace and test thoroughly.

### 1. **Dialogue Paths with Dynamic Level Prefixes**
**Pattern:** `res://Resources/level_data/dialogues/{level_id}_{dialogue_id}.dialogue`

**Used in:**
- `Gameplay/narrative/task/task_controller.gd` (lines 381-467)
- `Gameplay/dialogue_action_service.gd`
- `json_to_tres.py` (dialogue file generation)
- Dynamic dialogue loading based on task/stage configuration

**Refactoring Impact:** HIGH
- Dialogue files are created dynamically during level generation
- If you move the `dialogues/` directory, update all three files above
- The `json_to_tres.py` script hardcodes this path pattern

**Mitigation:**
- Use `FilePaths.DynamicPaths.get_dialogue_path(level_id, dialogue_id)`
- Keep the pattern consistent: `{level_id}_{dialogue_id}`

---

### 2. **Achievement Resource Scanning**
**Pattern:** All `.tres` files in `res://Resources/Achievements/`

**Used in:**
- `Autoloads/achievement_manager.gd` (line 32)

**Implementation:**
```gdscript
var all_resources = _collect_resources_recursive("res://Resources/Achievements/")
```

**Refactoring Impact:** MEDIUM
- If you rename/move the `Achievements/` directory, this directory path must be updated
- Otherwise file discovery will fail

**Mitigation:**
- Only hardcoded in `achievement_manager.gd` line 32
- Use `FilePaths.Directories.ACHIEVEMENTS` when referencing

---

### 3. **Journal Entry Resource Scanning**
**Pattern:** All `.tres` files in `res://Resources/level_data/journal_entry_rows/`

**Used in:**
- `Autoloads/journal_manager.gd` (line 82-83)

**Implementation:**
```gdscript
var all_resources = _collect_resources_recursive("res://Resources/level_data/journal_entry_rows/")
```

**Refactoring Impact:** MEDIUM
- Directory scanning is hardcoded
- If renamed, update `journal_manager.gd` only

**Mitigation:**
- Use `FilePaths.Directories.LEVEL_DATA_JOURNAL_ROWS` when referencing

---

### 4. **Level Catalog Entries**
**Pattern:** Individual level resource paths from `LevelCatalog.gd`

**Used in:**
- `Resources/level_data/levels/level_catalog.gd` (each entry)
- `Autoloads/level_manager.gd`
- `Gameplay/level_flow_controller.gd`

**Implementation:**
```gdscript
const LEVELS: Array[Dictionary] = [
	{"id": "level_0", "path": "res://Resources/levels/hometown.tres", ...},
	{"id": "level_1", "path": "res://Resources/levels/level_1.tres", ...},
]
```

**Refactoring Impact:** HIGH
- Each level's path is defined in the catalog
- Cannot be fully centralized (there are many levels)
- If you move the `levels/` directory, update `level_catalog.gd` entries

**Mitigation:**
- Use `FilePaths.DynamicPaths.get_level_path(level_id)` for simple level paths
- Update `LevelCatalog.gd` for actual level resources
- Keep the pattern: `res://Resources/level_data/levels/{level_id}.tres`

---

### 5. **Hometown Progression Dialogues**
**Pattern:** `res://Resources/level_data/dialogues/hometown_level_{number}_return.dialogue`

**Used in:**
- `Gameplay/hometown_progression_service.gd` (lines 70-73)

**Implementation:**
```gdscript
"level_1": "res://Resources/level_data/dialogues/hometown_level_1_return.dialogue",
```

**Refactoring Impact:** MEDIUM
- Only in one file
- Follows specific naming pattern for hometown returns

**Mitigation:**
- Use `FilePaths.DynamicPaths.HOMETOWN_DIALOGUE_PATTERN` if refactoring

---

### 6. **JSON-Generated Dialogue Resources**
**Pattern:** Generated by `json_to_tres.py` script

**Used in:**
- Converting JSON level definitions to `.tres` resources
- Creates dialogue, terrain, loot, and goal resources

**Refactoring Impact:** HIGH
- The Python script hardcodes multiple directory paths:
  - `res://Resources/level_data/dialogues/`
  - `res://Resources/level_data/stages/`
  - `res://Resources/level_data/{loot,terrain,goal}_rows/`
  - `res://Resources/level_data/levels/`

**Mitigation:**
- Update `json_to_tres.py` search-and-replace carefully
- Check the `SCRIPT_PATHS` and `_resolve_output_dirs()` sections
- Test with a sample JSON conversion after refactoring

---

## Refactoring Checklist

If you need to move a directory, follow this checklist:

### For `Scenes/` directory:
- [ ] Update `FilePaths.Scenes.*` constants
- [ ] Check if scenes are hardcoded in game logic (gameplay.gd, etc.)

### For `Autoloads/` directory:
- [ ] Update `project.godot` autoload entries
- [ ] Update `FilePaths.Autoloads.*` constants
- [ ] Verify all references in tests

### For `Gameplay/` scripts:
- [ ] Update `FilePaths.Gameplay.*` constants
- [ ] Update all `.preload()` statements in other files
- [ ] Search for any hardcoded paths

### For `Resources/` directory:
- [ ] Update individual constant paths in `FilePaths.Resources.*`
- [ ] Update `json_to_tres.py` SCRIPT_PATHS dict
- [ ] Check `Directories` class constants

### For Dialogue paths:
- [ ] Update `task_controller.gd` (lines 381-467)
- [ ] Update `json_to_tres.py` dialogue output directory
- [ ] Update `FilePaths.DynamicPaths.DIALOGUE_PATH_PATTERN`
- [ ] Test dialogue loading in gameplay

## Testing File Path Changes

After making refactoring changes:

```gdscript
# Test that all paths exist
var all_paths = FilePaths.get_all_paths()
for path_name in all_paths:
	var path = all_paths[path_name]
	if not FilePaths.path_exists(path):
		push_error("Path does not exist: %s = %s" % [path_name, path])

# Run tests
# pwsh -File scripts/run_tests.ps1
```

## Invalid Syntax Paths

The following types of strings are NOT file paths and were correctly excluded:

- Localization keys: `"menus.title.heading"`
- Documentation paths: markdown files in `docs/`
- Python scripts: `.py` files that run during development
- JSON source files: `.json` files for level design
- Configuration patterns: strings that describe paths (comments, examples)

These are intentionally not included because:
1. They're not loaded by Godot at runtime
2. They're development-only or documentation-only
3. Refactoring them doesn't affect gameplay

## Summary

| Category | Total Paths | Can Be Centralized | Refactoring Ease |
|----------|-------------|-------------------|-----------------|
| Scenes | 18 | ✅ 100% | Easy |
| Autoloads | 12 | ✅ 100% | Easy |
| Resources | 17 | ✅ 100% | Easy |
| Gameplay | 60+ | ✅ 100% | Moderate |
| Directories | 8 | ✅ 100% | Easy |
| UserPaths | 3 | ✅ 100% | Easy |
| Addons | 3 | ✅ 100% | Easy |
| Tests | 4 | ✅ 100% | Easy |
| **DynamicPaths** | **6** | ⚠️ **50%** | **Hard** |
| **TOTAL** | **~130** | **~124 (95%)** | **Hard for 6** |

### Key Takeaway

95% of file paths can be immediately centralized and refactored safely using `FilePaths.gd`. The remaining 5% require careful attention to dynamically-constructed paths, particularly:
- Dialogue paths with level prefixes (task_controller.gd)
- Resource catalog entries (level_catalog.gd)
- Python generation scripts (json_to_tres.py)

For these 5%, use the provided helper functions and patterns to ensure consistency.
