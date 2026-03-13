# HEX Reference Index

Use this index to locate systems, guides, and scripts quickly. Entries are grouped by domain to keep searches predictable for both humans and LLM agents.

## Architecture & Systems
- `Documentation/ARCHITECTURE.md` – overview of GameSession/GameState, unit components, and system boundaries.
- `COMMAND_PATTERN_GUIDE.md` – canonical reference for command lifecycle, handler structure, and validation rules.
- `Documentation/COMMAND_PATTERN_QUICK_REFERENCE.md` – cheat sheet version of the pattern for pair programming sessions.
- `Documentation/FILE_PATHS_GUIDE.md` – conventions for resource IDs, autoload lookups, and serialization paths.

## Gameplay Runtime
- `Gameplay/game_session.gd` – entry point for turn resolution and component dispatch.
- `Gameplay/targets/components/` – per-unit logic (AP, movement, loyalty, statuses, inventory, death handling, query services).
- `Gameplay/turn/ai/` – AI evaluators (`task_evaluator.gd`, `loot_evaluator.gd`, diagnostics helpers).
- `Gameplay/narrative/task/` – definitions, controllers, validators for narrative tasks and stage spawns.

## Level Editing & Validation
- `LEVEL_CREATION_GUIDE.md` – full workflow for building and registering levels.
- `Documentation/LEVEL_DESIGN_GUIDELINES.md` – pacing, narrative, and accessibility standards.
- `Documentation/LEVEL_IDEAS.md` – tutorial concepts and advanced level mechanical expansions.
- `level/` scripts – builder, validators, logging, auto-fixers, row loaders.
- `Resources/level_data/` – source of level `.tres` assets and JSON inputs.

## Tooling & Automation
- `scripts/` – PowerShell + Python helpers (`godot_cli.ps1`, `run_tests.ps1`, `validate.ps1`, `json_to_tres.py`, etc.).
- `Documentation/UTILITY_SCRIPTS.md` – descriptions and usage examples for each script.
- `tests/` – GdUnit4 suites; cross-reference `TEST_COVERAGE_ANALYSIS.md` and `test_status_tracker.md` for coverage expectations.

## LLM-Specific References
- `openspec/AGENTS.md` – operational rules, planning requirements, and testing mandates.
- `llm_skills/` – role-specific briefs (Godot dev, QA, Python tooling, narrative design, product, docs, customer voice, architecture, art/audio).
- `Documentation/GLOSSARY.md` – terminology definitions.
- `Documentation/APPENDIX.md` – maintenance guidance, TODO taxonomies, and validation hooks.

## Data & Resources
- `Resources/file_paths.json` – map of resource identifiers.
- `Resources/` – reusable resources (hex utils, level base classes, UI data).
- `zoo.json`, `quest_competition.json`, `sample_level.json` – data examples for AI or generation scripts.

## Maintenance Hooks
- `TODO.md` – global backlog; auto-updated by `scripts/validate.ps1 -UpdateTodos`.
- `reports/` – test outputs trimmed by validation scripts; check `test_status_tracker.md` for current failures.

Keep this index synced when directories move or new domains emerge. If you create a new guide or major subsystem, add it to the appropriate section so assistants can locate it without scanning the entire tree.
