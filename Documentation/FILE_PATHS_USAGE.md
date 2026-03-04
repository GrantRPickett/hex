# Centralized File Paths System - Complete Guide

## Overview

The HEX project now has a **centralized file paths system** that reduces refactoring effort when moving files around. File paths are stored in a single JSON file that can be read by both **Godot** and **Python**.

### Files Created

1. **`Resources/file_paths.json`** - Master registry of all file paths (JSON format, readable by both languages)
2. **`Resources/file_paths_loader.gd`** - Godot utility to load and use paths
3. **`scripts/file_paths_loader.py`** - Python utility to load and use paths
4. **`Documentation/FILE_PATHS_USAGE.md`** - This guide

## Quick Start

### In Godot

```gdscript
# Load the paths
var paths = FilePathsLoader.load_paths()

# Get a single path
var gameplay_scene = paths.get_path("scenes.gameplay")  # "res://Gameplay/gameplay.tscn"

# Get all paths in a category
var all_scenes = paths.get_category("scenes")

# Check for errors
if paths.get_errors().size() > 0:
	for error in paths.get_errors():
		push_error(error)

# Print a summary
paths.print_summary()
```

### In Python

```python
from scripts.file_paths_loader import FilePathsLoader

# Load the paths (relative to project root)
paths = FilePathsLoader("Resources/file_paths.json")

# Get a single path
gameplay_scene = paths.get_path("scenes.gameplay")  # "res://Gameplay/gameplay.tscn"

# Get all paths in a category
all_autoloads = paths.get_category("autoloads")

# Build a dialogue path dynamically
dialogue_path = paths.build_dialogue_path("level_1", "intro")
# → "res://Resources/level_data/dialogues/level_1_intro.dialogue"

# Print a summary
paths.print_summary()
```

## File Structure

### `file_paths.json` Organization

The JSON file is organized by category:

- **`scenes`** - `.tscn` scene files (gameplay, menus, GUI panels, character scenes)
- **`autoloads`** - Global autoload scripts from `project.godot`
- **`resources`** - GDScript resource classes (Level, Task, Dialog, etc.)
- **`gameplay`** - Gameplay logic scripts organized by subsystem
- **`directories`** - Directory paths for resource scanning
- **`user_paths`** - Runtime user paths (`user://` paths)
- **`addons`** - Third-party addon paths
- **`tests`** - GdUnit4 test files
- **`dynamic_paths`** - ⚠️ **Patterns that cannot be fully centralized**

### Example Structure

```json
{
  "scenes": {
	"gameplay": "res://Gameplay/gameplay.tscn",
	"title_screen": "res://Menus/title_screen.tscn",
	"gui_panels": {
	 "round_info": "res://GUI/round_info_panel.tscn",
	 "actions": "res://GUI/actions_panel.tscn"
	}
  },
  "autoloads": {
	"save_manager": "res://Autoloads/save_manager.gd",
	"level_manager": "res://Autoloads/level_manager.gd"
  }
}
```

### Accessing Nested Paths

Use dot notation to access nested paths:

```gdscript
# Godot
var panel = paths.get_path("scenes.gui_panels.round_info")  # "res://GUI/round_info_panel.tscn"

# Python
panel = paths.get_path("scenes.gui_panels.round_info")  # "res://GUI/round_info_panel.tscn"
```

## Dynamic Paths - ⚠️ CANNOT Be Fully Centralized

Some paths are constructed at runtime and cannot be fully centralized:

### 1. Dialogue Paths with Level Prefixes
**Pattern:** `res://Resources/level_data/dialogues/{level_id}_{dialogue_id}.dialogue`

**Used in:**
- `Gameplay/narrative/task/task_controller.gd`
- `Gameplay/dialogue_action_service.gd`
- `json_to_tres.py`

**Solution:** Use the pattern helper:

```gdscript
# Godot - get the pattern
var dynamic = paths.get_dynamic_paths()
var pattern = dynamic["dialogue_paths"]["pattern"]  # "{level_id}_{dialogue_id}..."

# Or use Python helper
dialogue_path = paths.build_dialogue_path("level_1", "intro")
```

### 2. Level Catalog Entries
**Source:** `res://Resources/levels/level_catalog.gd`

Each level definition is hardcoded in the catalog. **Update the catalog itself** if moving levels.

### 3. Directory Scans
**Patterns:**
- `res://Resources/Achievements/` (achievement_manager.gd)
- `res://Resources/level_data/journal_entry_rows/` (journal_manager.gd)

**Solution:** Update the paths in the source files if moving directories.

### 4. JSON-Generated Resources
**Script:** `json_to_tres.py`

Generates dialogue, terrain, loot resources. Update script if moving output directories.

## Refactoring Workflow

### Step 1: Identify what you're moving

Check the `dynamic_paths` section in `file_paths.json` to see if your move is documented.

### Step 2: Update `file_paths.json`

Update the relevant path constant:

```json
{
  "scenes": {
	"gameplay": "res://Gameplay/gameplay_new_location.tscn"  // Changed path
  }
}
```

### Step 3: Find all affected files

Search your codebase using this checklist:

```gdscript
# Example: Moving res://GUI/ to res://UserInterface/

1. Update file_paths.json paths
   - scenes.gui_panels.* → new paths
   - directories.gui → new directory

2. Search for hardcoded strings:
   IDE Find → "res://GUI/" → replace with new path

3. Update files that load these paths:
   - game_config.gd (scene paths)
   - hud_component_factory.gd (panel scenes)
   - Any test files referencing paths

4. Run tests:
   pwsh -File scripts/run_tests.ps1

5. Validate:
   python scripts/check_function_tests.py
```

### Step 4: Special Cases

#### Moving Dialogue Files

If moving `res://Resources/level_data/dialogues/`:

1. Update `file_paths.json`: `dynamic_paths.dialogue_paths.pattern`
2. Update `Gameplay/narrative/task/task_controller.gd` (lines 381-467)
3. Update `json_to_tres.py`: change dialogue output directory in `_ensure_dialogue_file_exists()`
4. Test with: `python json_to_tres.py` (verify files created in new location)

#### Moving Level Catalog

If moving `res://Resources/levels/level_catalog.gd`:

1. Update `file_paths.json`: `resources.level_data.level_catalog`
2. Update imports in:
   - `Autoloads/level_manager.gd`
   - `Gameplay/level_manager_gameplay.gd`
   - `Gameplay/level_flow_controller.gd`

#### Moving Test Files

If moving `res://tests/`:

1. Update `file_paths.json`: `directories.tests` and `tests.*`
2. Update test runner scripts
3. Verify GdUnit4 can still find tests

## Usage Examples

### Using paths in your code

```gdscript
# Instead of hardcoding:
var scene = load("res://Gameplay/gameplay.tscn")

# Use the centralized system:
var paths = FilePathsLoader.load_paths()
var gameplay_path = paths.get_path("scenes.gameplay")
var scene = load(gameplay_path)
```

### Building dynamic paths

```gdscript
# Instead of string concatenation:
var dialogue_path = "res://Resources/level_data/dialogues/%s_%s.dialogue" % [level_id, dialogue_id]

# Use the Python helper:
# (In json_to_tres.py or other Python tools)
paths = FilePathsLoader("Resources/file_paths.json")
dialogue_path = paths.build_dialogue_path(level_id, dialogue_id)
```

### Validating paths

```gdscript
# Godot - validate all static paths
var paths = FilePathsLoader.load_paths()
var validation = paths.validate_paths()

print("Valid paths: %d" % validation["valid"].size())
if validation["missing"].size() > 0:
	print("Missing paths:")
	for missing in validation["missing"]:
		push_error(missing)
```

```python
# Python - validate paths
paths = FilePathsLoader("Resources/file_paths.json")
validation = paths.validate_paths()

print(f"Total paths: {validation['total_checked']}")
print(f"Godot paths (res://): {len(validation['godot_paths'])}")
```

## Warnings Summary

### Critical ⚠️

1. **Dialogue paths** - Dynamic level prefix pattern (HIGH impact if moving)
2. **Level catalog** - Master list in `level_catalog.gd` (HIGH impact if moving)
3. **json_to_tres.py** - Python script generates files (HIGH impact if moving)

### Medium Risk ⚠️

1. **Directory scans** - Achievement and journal directories
2. **Default roster paths** - Level row loader defaults
3. **Hometown dialogues** - Special naming pattern

### Low Risk ✓

Most other paths can be safely refactored using this system.

## Testing After Changes

Always run these after refactoring:

```bash
# Run all tests
pwsh -File scripts/run_tests.ps1

# Check function test coverage
python scripts/check_function_tests.py

# Validate paths (optional - for debugging)
# In Godot editor:
# Create a test script that calls FilePathsLoader.load_paths().validate_paths()

# In Python:
python -c "from scripts.file_paths_loader import FilePathsLoader; FilePathsLoader('Resources/file_paths.json').print_summary()"
```

## Common Tasks

### Find all references to a file path

```bash
# PowerShell
Select-String -Path "*.gd" -Pattern "res://Menus/title_screen.tscn" -Recurse

# After refactoring, use file_paths.json as the source of truth
```

### Check if a path exists

```gdscript
# Godot
if ResourceLoader.exists(path):
	print("Path exists!")
else:
	print("Path does not exist!")
```

### List all paths in a category

```gdscript
# Godot
var all_scenes = paths.get_category("scenes")
for path_name in all_scenes:
	print("%s: %s" % [path_name, all_scenes[path_name]])
```

```python
# Python
all_scenes = paths.get_category("scenes")
for path_name, path_value in all_scenes.items():
	print(f"{path_name}: {path_value}")
```

## Troubleshooting

### "Path not found" error

1. Check spelling of path key (case-sensitive)
2. Verify path exists in `file_paths.json`
3. Use dot notation: `"scenes.gameplay"` not `"scene.gamePlay"`

### JSON parsing errors

1. Verify `file_paths.json` is valid JSON (use online validator)
2. Check file is not corrupted
3. Ensure file is in correct location: `res://Resources/file_paths.json`

### Paths not updating after edits

1. Save `file_paths.json`
2. Reload the FilePathsLoader:
   ```gdscript
   var paths = FilePathsLoader.load_paths()  # Creates fresh instance
   ```

### Dynamic paths not working

1. Check source file still has hardcoded pattern
2. Look in `dynamic_paths` section of JSON for the pattern
3. Use pattern helper function:
   ```python
   paths.build_dialogue_path("level_1", "intro")
   ```

## Integration with json_to_tres.py

The Python loader can be integrated into `json_to_tres.py`:

```python
from scripts.file_paths_loader import FilePathsLoader

# Load centralized paths
paths = FilePathsLoader("Resources/file_paths.json")

# Build output directory paths dynamically
dialogue_dir = paths.get_path("directories.dialogues")
roster_dir = paths.get_path("directories.roster_rows")

# Or use the dialogue helper
dialogue_path = paths.build_dialogue_path(level_id, dialogue_id)
```

## Future Improvements

1. Add `check_file_paths.py` script to validate all paths in JSON
2. Add IDE integration to check paths in real-time
3. Generate TypeScript types from JSON for web tools
4. Support `@deprecated` markers for deprecated paths
5. Add migration helpers for refactored paths

## Summary

| Aspect | Centralized | Notes |
|--------|-------------|-------|
| Scene paths | ✅ 100% | Update JSON and file references |
| Autoload paths | ✅ 100% | Update JSON + autoload registration |
| Resource paths | ✅ 100% | Update JSON + imports |
| Gameplay scripts | ✅ 95% | Most can be centralized |
| Dialogue paths | ⚠️ 50% | Dynamic patterns, see documentation |
| Level catalog | ⚠️ 30% | Master list in catalog.gd |
| Directory scans | ⚠️ 20% | Source files hardcode paths |
| Python scripts | ⚠️ 10% | json_to_tres.py generates files |

## Questions?

See `FILE_PATHS_GUIDE.md` for the technical reference, or check the example usage in this document.
