## 1. Implementation
- [ ] 1.1 Create LevelCatalogEntry resource script (exported fields, helper for dictionary conversion) and add .tres assets for all existing levels under a dedicated folder.
- [ ] 1.2 Refactor level_catalog.gd to load entries from those resources, keep a deterministic order field, and expose the same API (get_levels, get_level_by_id, ind_level_by_path).
- [ ] 1.3 Add or update unit/integration tests to cover resource loading, ordering, and repeatable/hometown flags so regressions are caught.

## 2. Validation
- [ ] 2.1 Run pwsh -File scripts/validate.ps1 -UpdateTodos and ensure it passes.
