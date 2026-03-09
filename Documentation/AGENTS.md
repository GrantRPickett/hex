<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

## Related Documentation
- **[README.md](../README.md)**: Main project entry point and component overview.
- **[@/openspec/AGENTS.md](../openspec/AGENTS.md)**: Authoritative guide for change proposals and architectural specs.
- **[ARCHITECTURE.md](ARCHITECTURE.md)**: Technical overview of GameSession, GameState, and the unit component system.
- **[UTILITY_SCRIPTS.md](UTILITY_SCRIPTS.md)**: Catalog of generation, testing, and maintenance scripts.
- **[COMMAND_PATTERN_GUIDE.md](COMMAND_PATTERN_GUIDE.md)**: Architecture for input and action execution.
- **[LEVEL_CREATION_GUIDE.md](LEVEL_CREATION_GUIDE.md)**: How levels are built and registered.
- **[LEVEL_DESIGN_GUIDELINES.md](LEVEL_DESIGN_GUIDELINES.md)**: Recommended narrative and gameplay pacing patterns.
- **[FILE_PATHS_GUIDE.md](FILE_PATHS_GUIDE.md)**: Standards for resource path management.

## System Environment
- **OS**: **Windows 10/11**
- **Shell**: **PowerShell (pwsh)**
- **Constraint**: **Do NOT use Linux commands** (ls, grep, rm, etc.) unless via `pwsh -Command`. Prefer standard PowerShell cmdlets (Get-ChildItem, Select-String, Remove-Item).

## Core Operating Rules
1. **Scope Discipline**: Respond only to the current task. No preambles or summaries.
2. **Translation Freeze**: Do NOT attempt to translate dialogue, UI labels, or documentation into non-English languages. The project is in a rapid revision phase. Existing translations are for infrastructure testing only.
3. **Context Compression**: When threads get long, produce a ≤150-token state summary and continue from there.
3. **Change Management**: 
   - Prefer targeted `replace` calls or diffs. 
   - Reference systems by name (e.g., "Six-Stat Model").
   - **Architectural Shifts**: Use the OpenSpec workflow for new capabilities or breaking changes (see `@/openspec/AGENTS.md`).
4. **Efficiency & Permissions**: 
   - **Minimize Confirmation Prompts**: Prefer internal tools (`grep_search`, `glob`, `read_file`) over `run_shell_command` for discovery to avoid unnecessary user permission loops.
   - **Selective Scripting**: Do not run maintenance scripts (e.g., `audit_localization.py`, `find_long_funcs.py`) unless specifically tasked.
5. **Verification**: Flag uncertainty briefly ("Assumption:"). Prefer being correct and revisable over exhaustive.
6. **No Chitchat**: Professional, direct tone. Use tools for actions, text for concise intent.

## Testing & Validation Mandates
1. **Fast-Fail Check**: Before running full test suites, skim your changed code for obvious parse errors (missing commas, unclosed brackets, typed GDScript mismatches). Do not waste time running tests on code that will not compile.
2. **Mandatory Tests**: Every new function added outside of `tests/` or `addons/` **must** have a paired GdUnit4 test.
3. **Test References**: The test must reference the function by name to pass the coverage checker.
4. **Final Validation**: Once code is verified clean, run:
   - `pwsh -File scripts/validate.ps1 -UpdateTodos`

## Helpful Commands (Windows PowerShell)
- **Run Validation**: `pwsh -File scripts/validate.ps1 -UpdateTodos -ShowAll`
  - (Default): Runs tests and function reference coverage check.
  - `-Short`: Runs **only** GdUnit4 tests (fastest).
  - `-Full`: Runs tests, coverage check, localization audit, and UID collision check (comprehensive).
  - `-UpdateTodos`: Automatically updates `TODO.md` with any detected issues or missing tests.
  - `-ShowAll`: Disables quiet mode to show full test output and diagnostics.
- **Run Tests Only**: `pwsh -File scripts/run_tests.ps1 -Verbose`
  - `-Verbose`: Shows individual test results and Godot output.
  - `-Test <path>`: Run a specific test file (e.g., `-Test res://tests/test_unit.gd`).
- **Launch Editor**: `pwsh -File scripts/godot_cli.ps1 -Run -- -e`
- **Prune Reports**: `pwsh -File scripts/prune_reports.ps1 -Keep 10`
