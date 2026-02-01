## 1. Implementation
- [ ] 1.1 Scaffold row Resource scripts (TerrainRow, PlayerStartRow, DialogueRow, LevelMetaRow) plus templates/folder conventions for ResourceTables.
- [ ] 1.2 Extend the row loader (or companion service) to ingest the new rows and mutate LevelTerrainData, player_starts, and dialogue entries before build.
- [ ] 1.3 Implement a LevelRowValidator that checks bounds, overlapping coords, timeline references, and hex-grid coverage after rows are applied.
- [ ] 1.4 Migrate existing terrain/start/dialogue data into row .tres files and wire the validator into gameplay initialization.
- [ ] 1.5 Add/extend tests covering the loader+validator + ResourceTables templates.

## 2. Validation
- [ ] 2.1 Run pwsh -File scripts/validate.ps1 -UpdateTodos and ensure it passes.
