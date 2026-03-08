# HEX Appendix

This appendix captures supporting references that keep the glossary and index trustworthy. Update it whenever validation steps, TODO sources, or spec workflows change.

## Maintenance Checklist
1. **Validation Runs** – Execute `pwsh -File scripts/validate.ps1 -UpdateTodos` before merging to ensure GdUnit4, coverage, and TODO syncing stay current.
2. **Glossary Refresh** – When a system is renamed or replaced, update `Documentation/GLOSSARY.md` alongside the code change.
3. **Index Review** – Any new documentation or major directory should be linked in `Documentation/REFERENCE_INDEX.md`.
4. **Skill Briefs** – Keep `llm_skills/` entries aligned with reality; add TODOs where skill coverage is lacking.

## TODO & Ticket Conventions
- Add actionable TODOs inside code files or in `TODO.md` with owner/system context.
- Use `MoSCoW` tags (Must/Should/Could/Won't) or size markers (S/M/L/XL) when Product skill needs prioritization clarity.
- When multiple skills collaborate, summarize next steps in README/guide footnotes or `openspec/AGENTS.md` references to prevent siloed knowledge.

## Reference Tables
| Asset | Location | Notes |
| --- | --- | --- |
| Godot CLI Wrapper | `scripts/godot_cli.ps1` | Handles editor/runtime downloads and execution.
| Level Validators | `level/validation/` | Grid, spawn, and row validators invoked before committing new levels.
| JSON↔TRES Tools | `scripts/json_to_tres.py`, `scripts/patch_json_to_tres.py` | Keeps JSON samples synced with Godot resources.
| Coverage Docs | `TEST_COVERAGE_ANALYSIS.md` | Explains how the coverage gate maps functions to tests.

## Cross-References
- LLM skills overview: `openspec/AGENTS.md` ("LLM Skills Collaboration" section).
- Glossary: `Documentation/GLOSSARY.md`.
- Index: `Documentation/REFERENCE_INDEX.md`.
- Narrative influences and design heuristics live in `Documentation/LEVEL_DESIGN_GUIDELINES.md` and `llm_skills/ttrpg_narrative_designer.md`.

## Staleness Mitigation
- As part of PR review, confirm if touched systems have glossary/index entries; update them in the same change.
- Encourage architects, QA, or documentation skills to append notes here when new maintenance rituals are introduced (e.g., lint rules, generation scripts).
- If context debt grows, log a TODO referencing this appendix so Product skill can prioritize a doc refresh cycle.
