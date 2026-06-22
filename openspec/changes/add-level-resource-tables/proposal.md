## Why
Designers now have to open each level .tres and dig into nested arrays to change spawn/loot/goal data. They asked for the ResourceTables addon to cover those assets exactly like the upcoming LevelCatalogEntry table. To do that we need table-friendly Resource types that flatten the level ID, coords, and references per row plus runtime glue code to rebuild the existing roster/loot/goal structures before gameplay starts.

## What Changes
- Define spreadsheet-friendly row resources for rosters, loot drops, and goals (e.g. LevelRosterRow, LevelLootRow, LevelGoalRow) with exported columns for level id, coord, linked scene/resource paths, and optional metadata such as faction or spawn weight.
- Add folder conventions (e.g. 
es://Resources/level_data/roster_rows/) so ResourceTables can display every row as a table and update the .tres on save.
- Implement a loader/service that reads those row resources at runtime and builds UnitRosterDefinition, LootListDefinition, and LevelGoalEntry arrays for the requested level.
- Update Level resources (and loaders/tests) to consume the generated data rather than embedding spawn/loot/goal sub-resources directly.
- Extend automated tests to cover the new pipeline so mis-edited table rows fail fast.

## Impact
- Designers can edit spawn, loot, and goal data for every level entirely inside the ResourceTables addon.
- Gameplay loading changes because roster/loot/goal data is now composed from row resources; we need conversion code and save upgrade path.
- Requires touching every existing level resource plus new tests for the loader and ResourceTables folder conventions.
