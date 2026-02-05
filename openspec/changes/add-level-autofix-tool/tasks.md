## 1. Implementation
- [ ] 1.1 Audit current validator + builder glue to map out all failure modes (impassable tiles, overlaps, OOB) and define repair priority order per type.
- [ ] 1.2 Implement a LevelAutoFixService that consumes the validator findings, computes deterministic fallback coordinates (pathfinding or spiral search), and reports the chosen repairs.
- [ ] 1.3 Add builder/validator hooks to invoke the service when the auto-fix flag is enabled, mutate a cloned level payload, and emit logs/JSON reports describing applied fixes.
- [ ] 1.4 Update CLI/editor pathways so QA/dev builds enable auto-fix by default while release builds keep it off. Add configuration plumbing + docs.
- [ ] 1.5 Create tests covering suggestion ordering, application of fixes, and serialization of the repair report.

## 2. Validation
- [ ] 2.1 Run pwsh -File scripts/validate.ps1 -UpdateTodos and ensure everything passes.
