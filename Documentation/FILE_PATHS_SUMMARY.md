# Centralized File Paths System - Summary

## What Was Created

You now have a **complete centralized file paths system** that works with both **Godot and Python**.

### Files Created/Updated

| File | Purpose | Language | Readable By |
|------|---------|----------|-------------|
| `Resources/file_paths.json` | Master registry of all file paths | JSON | Godot + Python |
| `Resources/file_paths_loader.gd` | Godot utility to load & access paths | GDScript | Godot |
| `scripts/file_paths_loader.py` | Python utility to load & access paths | Python | Python |
| `Documentation/FILE_PATHS_USAGE.md` | Complete usage guide with examples | Markdown | Everyone |

## Key Features

✅ **Single JSON source of truth** - All paths in one place
✅ **Both Godot and Python support** - Use the same paths everywhere
✅ **Organized by category** - Scenes, Autoloads, Resources, Gameplay, Tests, etc.
✅ **Nested access** - Use dot notation: `"scenes.gui_panels.round_info"`
✅ **Dynamic path helpers** - Build dialogue paths from patterns
✅ **Validation tools** - Check which paths exist
✅ **Comprehensive warnings** - Know which paths can't be fully centralized

## Quick Examples

### Godot

```gdscript
var paths = FilePathsLoader.load_paths()
var gameplay_scene = paths.get_path("scenes.gameplay")
var panel_path = paths.get_path("scenes.gui_panels.round_info")
paths.print_summary()
```

### Python

```python
from scripts.file_paths_loader import FilePathsLoader

paths = FilePathsLoader("Resources/file_paths.json")
gameplay = paths.get_path("scenes.gameplay")
dialogue = paths.build_dialogue_path("level_1", "intro")
```

## Paths Centralized

### **~130+ file paths** centrally managed:

- **18** Scene paths (.tscn files)
- **12** Autoload paths
- **17** Resource class definitions
- **60+** Gameplay logic scripts
- **8** Directory paths
- **3** User config paths
- **3** Addon paths
- **4+** Test paths
- **6** Dynamic path patterns (with documentation)

## ⚠️ Strings That CANNOT Be Extracted (Warned)

### 1. **Dialogue Paths with Dynamic Level Prefixes** (HIGH impact)
- Pattern: `res://Resources/level_data/dialogues/{level_id}_{dialogue_id}.dialogue`
- Used in: `task_controller.gd`, `dialogue_action_service.gd`, `json_to_tres.py`
- Status: **⚠️ WARNED** in JSON file with mitigation strategies

### 2. **Level Catalog Entries** (HIGH impact)
- Source: `res://Resources/levels/level_catalog.gd`
- Each level path hardcoded in the LEVELS array
- Status: **⚠️ WARNED** with instructions to update catalog.gd when moving

### 3. **Directory Scans** (MEDIUM impact)
- Achievement directory: `res://Resources/Achievements/`
- Journal directory: `res://Resources/level_data/journal_entry_rows/`
- Status: **⚠️ WARNED** - must update source files if moving

### 4. **JSON-Generated Resources** (HIGH impact)
- File: `json_to_tres.py`
- Outputs: Dialogue, terrain, loot resources
- Status: **⚠️ WARNED** - must update Python script if moving output directories

### 5. **Hometown Progression Dialogues** (MEDIUM impact)
- Pattern: `hometown_level_{number}_return.dialogue`
- Used in: `hometown_progression_service.gd`
- Status: **⚠️ WARNED**

### 6. **Hardcoded Game Logic** (LOW impact)
- `game_config.gd`: Scene transition paths
- `level_manager.gd`: Catalog loading
- Status: **✓ DOCUMENTED** in JSON file

## How to Use This System

### For Moving Files

**Before:** Search codebase, update 20+ files, hope you didn't miss anything

**After:**
1. Update `file_paths.json` with new path
2. Run IDE search-and-replace for hardcoded strings
3. Check `dynamic_paths` section for exceptions
4. Run tests

### In Your Code

**Before:**
```gdscript
var scene = load("res://Gameplay/gameplay.tscn")  # Hardcoded
```

**After:**
```gdscript
var paths = FilePathsLoader.load_paths()
var scene = load(paths.get_path("scenes.gameplay"))  # Centralized
```

### For Python Scripts

```python
from scripts.file_paths_loader import FilePathsLoader

paths = FilePathsLoader("Resources/file_paths.json")

# Get a path
dialogue = paths.get_path("resources.dialogue.achievement")

# Build dynamic dialogue path
dialogue_path = paths.build_dialogue_path("level_1", "intro_scene")
```

## Testing & Validation

### Validate paths exist:
```gdscript
var paths = FilePathsLoader.load_paths()
var results = paths.validate_paths()
print("Valid: %d, Missing: %d" % [results["valid"].size(), results["missing"].size()])
```

### Run full test suite:
```bash
pwsh -File scripts/run_tests.ps1
```

## Files You Should Know About

1. **`Resources/file_paths.json`** ← Main config file, update this when moving paths
2. **`Resources/file_paths_loader.gd`** ← Godot utility, handles JSON parsing
3. **`scripts/file_paths_loader.py`** ← Python utility, handles JSON parsing
4. **`Documentation/FILE_PATHS_USAGE.md`** ← Full usage guide with examples

## Next Steps

1. **Review** `FILE_PATHS_USAGE.md` for complete documentation
2. **Check** `file_paths.json` structure to understand organization
3. **Test** the loaders in your project:
   - In Godot: Create a test scene/script that calls `FilePathsLoader.load_paths()`
   - In Python: Run `python scripts/file_paths_loader.py` to see summary
4. **Refactor** your code to use centralized paths where appropriate
5. **Update** your `json_to_tres.py` calls to use the Python loader

## Benefits

| Scenario | Before | After |
|----------|--------|-------|
| **Moving a directory** | Update 20+ files manually | Update JSON + 1-2 script files |
| **Finding all references** | Search entire codebase | Look in JSON file |
| **Using paths in Python** | Hardcoded strings | Use FilePathsLoader |
| **Using paths in Godot** | Hardcoded strings | Load from JSON |
| **Documenting path changes** | Update multiple places | Update JSON once |
| **Onboarding new developers** | "Where is file X?" | "Check file_paths.json" |

## Statistics

- **Total paths documented**: 130+
- **Categories**: 9
- **Paths that can be centralized**: ~124 (95%)
- **Paths that need special handling**: 6 (5%)
- **Files that read the paths**: 2+ (Godot loader, Python loader)

## Warnings Summary

| Type | Count | Examples | Impact |
|------|-------|----------|--------|
| **HIGH** | 3 | Dialogue paths, Level catalog, json_to_tres.py | Move carefully |
| **MEDIUM** | 3 | Directory scans, Hometown dialogues, Roster paths | Update source files |
| **LOW** | 0 | Most other paths | Safe to refactor |

---

**All warnings are documented in `file_paths.json` under `dynamic_paths` section.**

See `FILE_PATHS_USAGE.md` for the complete guide!
