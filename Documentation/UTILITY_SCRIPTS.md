# Utility Scripts Catalog

This document describes the various helper scripts located in the `scripts/` directory and how to use them.

## 1. World & Level Generation

### `hex_map_generator.py`
- **Purpose**: Generates procedural hexgrid terrain data based on a feature configuration (shores, rivers, mountains, etc.).
- **Usage**: `python scripts/hex_map_generator.py <config.json>`
- **Documentation**: See [Map Generator Features](../MAP_GENERATOR_FEATURES.md).

### `json_to_tres.py`
- **Purpose**: The primary pipeline script. Converts `.json` level definitions (including generated terrain data) into Godot `.tres` resource files.
- **Usage**: `python scripts/json_to_tres.py <level.json>`

### `convert_all_levels.py`
- **Purpose**: Batch processes all JSON files in `Resources/level_data/` through the `json_to_tres.py` pipeline.
- **Usage**: `python scripts/convert_all_levels.py`

## 2. Testing & Validation

### `run_tests.ps1` (and `.cmd`)
- **Purpose**: Runs the full GdUnit4 test suite headlessly. Auto-downloads the Godot CLI if missing.
- **Usage**: `pwsh -File scripts/run_tests.ps1`

### `validate.ps1`
- **Purpose**: A comprehensive project health check. Runs tests, audits localization coverage, and identifies untested functions.
- **Usage**: `pwsh -File scripts/validate.ps1 -UpdateTodos`

### `check_function_tests.py`
- **Purpose**: Scans the project for functions and verifies each one is mentioned in a test file. Used for the project's "100% function coverage" mandate.
- **Usage**: `python scripts/check_function_tests.py`

## 3. Maintenance & Auditing

### `audit_localization.py`
- **Purpose**: Compares `translations.csv` against hardcoded strings and identifies missing or unused keys.
- **Usage**: `python scripts/audit_localization.py`

### `check_uids.py`
- **Purpose**: Scans for broken or duplicate Resource UIDs in `.gd` and `.tscn` files.
- **Usage**: `python scripts/check_uids.py`

### `prune_reports.ps1`
- **Purpose**: Keeps the `reports/` folder tidy by deleting old test artifacts.
- **Usage**: `pwsh -File scripts/prune_reports.ps1 -Keep 10`

### `find_long_funcs.py`
- **Purpose**: Identifies overly complex methods that might need refactoring based on line count.
- **Usage**: `python scripts/find_long_funcs.py`

## 4. Environment

### `godot_cli.ps1`
- **Purpose**: Manages the Godot executable for the CLI. Handles downloading, caching, and running the engine.
- **Usage**: `pwsh -File scripts/godot_cli.ps1 -Run -- -e` (to open the editor)
