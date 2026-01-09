# CI/CD

## GitHub Actions workflow

- Workflow file: `.github/workflows/godot-ci.yml`.
- Triggers: `push`, `pull_request`.

### Optional repository variables (Settings → Actions → Variables)

- `GODOT_RUNNER`: Runner label (default `ubuntu-latest`).
- `GODOT_VERSION`: Godot version (default `4.5`).
- `GODOT_CHANNEL`: Godot channel (default `stable`).
- `GODOT_EXE`: Absolute path to a preinstalled Godot binary. When set, the workflow skips the download/cache steps.

### Script configuration overrides (self-hosted or local)

- `HEX_GODOT_CLI_ROOT`: Overrides the `.godot-cli` directory used by `scripts/godot_cli.ps1`.
- `HEX_EXTENSION_LIST_PATH`: Overrides `.godot/extension_list.cfg` used by `scripts/run_tests.ps1`.

## Local verification

- `pwsh -File scripts/run_tests.ps1`
- `python scripts/check_function_tests.py`
