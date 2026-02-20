# Centralized File Paths - Quick Start Guide

## 🎯 What You Need to Know

Your project now has a **centralized file paths system** - a single JSON file that stores ALL hardcoded paths. This makes it **much easier to move files around** because you only update one place instead of searching the entire codebase.

## 📁 The Files

1. **`Resources/file_paths.json`** ← Main file (156 paths organized by category)
2. **`Resources/file_paths_loader.gd`** ← Godot utility
3. **`scripts/file_paths_loader.py`** ← Python utility

## 🚀 Using in Your Code

### Godot Example

```gdscript
# Load the paths once (cache it, don't reload every time)
var paths = FilePathsLoader.load_paths()

# Get a single path
var gameplay_scene = paths.get_path("scenes.gameplay")

# Use it
var scene = load(gameplay_scene)
get_tree().change_scene_to_file(gameplay_scene)

# Get a whole category
var all_scenes = paths.get_category("scenes")

# Check for problems
if paths.get_errors().size() > 0:
    print("Problems loading paths:", paths.get_errors())
```

### Python Example

```python
from scripts.file_paths_loader import FilePathsLoader

# Load paths
paths = FilePathsLoader("Resources/file_paths.json")

# Get a single path
gameplay = paths.get_path("scenes.gameplay")
print(f"Gameplay scene: {gameplay}")

# Build dynamic paths (like dialogue)
dialogue_path = paths.build_dialogue_path("level_1", "intro_scene")
print(f"Dialogue: {dialogue_path}")
```

## 📊 What's Centralized

- **23** Scenes (gameplay, menus, GUI panels)
- **12** Autoloads (global managers)
- **33** Resources (Level, Task, etc.)
- **66** Gameplay scripts
- **16** Directories
- **6** Test scripts
- **Total: 156+ file paths**

## ⚠️ Paths That CANNOT Be Fully Centralized

Some paths are built dynamically and can't be stored statically. These are **documented** in `file_paths.json` with warnings:

1. **Dialogue paths** - Built as `{level_id}_{dialogue_id}` at runtime
2. **Level catalog** - Master list in `level_catalog.gd`
3. **Directory scans** - Achievements, journals
4. **JSON generation** - `json_to_tres.py` script output

**→ See `FILE_PATHS_USAGE.md` for handling these**

## 🔧 Moving Files? Here's What to Do

### Step 1: Update `file_paths.json`

Find the path entry and update it:

```json
{
  "scenes": {
    "gameplay": "res://Gameplay/new_location/gameplay.tscn"  // ← Change this
  }
}
```

### Step 2: Search for Hardcoded References

Some paths might be hardcoded outside the loader. Search your code:

```bash
# PowerShell
Select-String -Path "*.gd" -Pattern "res://Gameplay/gameplay.tscn" -Recurse
```

### Step 3: Update Any Found References

Replace with loader calls:

```gdscript
# Before
var scene = load("res://Gameplay/gameplay.tscn")

# After
var paths = FilePathsLoader.load_paths()
var scene = load(paths.get_path("scenes.gameplay"))
```

### Step 4: Handle Special Cases

Check `FILE_PATHS_USAGE.md` for:
- Moving dialogue directories
- Moving levels
- Moving test files
- Updating `json_to_tres.py`

### Step 5: Test

```bash
pwsh -File scripts/run_tests.ps1
```

## 📖 Documentation

| Document | Purpose |
| --- | --- |
| **FILE_PATHS_SUMMARY.md** | This overview |
| **FILE_PATHS_USAGE.md** | Complete guide with examples |
| **file_paths.json** (comments section) | In-file documentation |

## ✅ Validation

**Python:**
```bash
python scripts/file_paths_loader.py
```

Output shows:
- ✓ Warnings about dynamic paths
- ✓ All categories loaded
- ✓ Total paths: 157
- ✓ Example path access works

**Godot:**
```gdscript
var paths = FilePathsLoader.load_paths()
paths.print_summary()
```

## 🎓 Learning Examples

### Get All Scene Paths
```gdscript
var scenes = paths.get_category("scenes")
for scene_name in scenes:
    print(f"{scene_name}: {scenes[scene_name]}")
```

### Build Dialogue Path
```python
# Python
dialogue = paths.build_dialogue_path("level_1", "intro")
# Result: "res://Resources/level_data/dialogues/level_1_intro.dialogue"
```

### Access Nested Paths
```gdscript
# Use dot notation for nested dictionaries
var panel_path = paths.get_path("scenes.gui_panels.round_info")
# Result: "res://GUI/round_info_panel.tscn"
```

## ❓ Common Questions

**Q: Do I have to use this?**
A: No, it's optional. But it makes refactoring much easier when you do.

**Q: Can I edit file_paths.json?**
A: Yes! Update paths there when you move files. Keep JSON valid (use a JSON validator).

**Q: What if I move files without updating?**
A: The old hardcoded paths still work, but you lose the benefit. Use search-and-replace to update them.

**Q: Does this slow down my game?**
A: No. The JSON loads once into memory. Subsequent lookups are dictionary reads.

**Q: Can I add new paths?**
A: Yes! Edit `file_paths.json` and add entries following the existing structure.

## 🔗 Next Steps

1. **Read** `FILE_PATHS_USAGE.md` for the complete guide
2. **Explore** `file_paths.json` to see all available paths
3. **Try** calling `FilePathsLoader.load_paths()` in a test script
4. **Refactor** your code to use centralized paths where it makes sense
5. **Test** with `pwsh -File scripts/run_tests.ps1`

---

**Questions? See `FILE_PATHS_USAGE.md` or check the examples above.**
