# Change: Add Hard-Save System

## Why
Currently, the game relies on mementos (soft-saves) during levels, but lacks a robust "world state" save point between levels. This can lead to issues like item duplication or lost inventory management progress if a player quits or loses a level. A hard-save system triggered before level start ensures a reliable recovery point and preserves meta-progression (inventory) made in menus.

## What Changes
- **NEW**: Hard-save capability in `SaveManager`.
- **MODIFIED**: `LevelSelect` to trigger hard-save on level selection.
- **NEW**: Support for at least 3 rotation-buffered hard-saves with timestamps.
- **NEW**: Recovery logic to restore world state from hard-save if a level session is aborted.
- Integrate this menu into the "Options" menu or as a "Recovery" button on the Title Screen.

#### [NEW] [recovery_menu.tscn](file:///c:/Users/grant/Documents/github/hex/Menus/recovery_menu.tscn)
- Control node root.
- CenterContainer -> VBoxContainer.
- VBoxContainer should have `%SaveList` unique name for script access.
- Back Button with `%BackButton` unique name.

### Localization

#### [MODIFY] [translations.csv](file:///c:/Users/grant/Documents/github/hex/Resources/Localization/translations.csv)
- Add `menu.title.recovery` key.
- Ensure `menu.title.continue` is consistent (check if `menus.title.continue` should be renamed or aliased).

#### [MODIFY] [localization_strings.gd](file:///c:/Users/grant/Documents/github/hex/Resources/Localization/localization_strings.gd)
- Add `MENU_TITLE_CONTINUE` and `MENU_TITLE_RECOVERY` constants.
- Add `MENU_TITLE_HEADING` for consistency.
- **NEW**: "Continue" capability on the Title Screen to resume from the latest soft-save (memento).
- **NEW**: Crash detection/session flag to prompt for continue if an in-level soft-save exists after a non-graceful exit.

## Impact
- Affected specs: `save-system` (NEW)
- Affected code:
    - [save_manager.gd](file:///c:/Users/grant/Documents/github/hex/Autoloads/save_manager.gd)
    - [level_select.gd](file:///c:/Users/grant/Documents/github/hex/Menus/level_select.gd)
    - [level_manager.gd](file:///c:/Users/grant/Documents/github/hex/Autoloads/level_manager.gd)
    - [title_screen.gd](file:///c:/Users/grant/Documents/github/hex/Menus/title_screen.gd) (for Continue button)
