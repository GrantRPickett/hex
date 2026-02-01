## Why
Level unlock order, prerequisites, and other metadata live inside level_catalog.gd as hard-coded dictionaries. Designers need to tweak this data frequently and already use the ResourceTables addon to edit other resource folders, but the level catalog is not editable there because it isn't stored as resources. They requested that the level metadata live inside dedicated resources so they can open the folder in the addon and edit rows like a spreadsheet.

## What Changes
- Define a LevelCatalogEntry Resource with exported columns (id, level path, display name, flags, prerequisites, ordering index) tailored for ResourceTables.
- Convert the existing catalog entries into .tres assets under a dedicated folder so the addon can display and edit them.
- Update LevelCatalog to load entries from those resources and keep its existing dictionary-based API for the rest of the game.
- Add tests covering the resource-driven catalog loading and ordering rules.

## Impact
- Designers can edit all level metadata in ResourceTables without touching scripts.
- The catalog loading path changes, so missing resource files would now be reported at runtime, which needs CI/unit test coverage to avoid regressions.
- Requires regenerating the catalog entries for every existing level (level_0 (Hometown) plus level 1-7).

