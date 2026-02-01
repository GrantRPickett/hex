## 1. Implementation
- [ ] 1.1 Add row Resource scripts (LevelRosterRow, LevelLootRow, LevelGoalRow) plus folders that ResourceTables can open.
- [ ] 1.2 Build loader/service that groups the rows by level_id and emits the runtime structures (UnitRosterDefinition, LootListDefinition, LevelGoalEntry arrays) used today.
- [ ] 1.3 Migrate existing level data into row resources and refactor Level loading to consume the generated structures.
- [ ] 1.4 Update or add tests to cover row editing, grouping, and backwards compatibility when rows are missing/invalid.

## 2. Validation
- [ ] 2.1 Run pwsh -File scripts/validate.ps1 -UpdateTodos and ensure it passes.
