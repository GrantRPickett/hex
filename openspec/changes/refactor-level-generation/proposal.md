# Change: Refactor Level Generation

## Why
The current `json_to_tres.py` script is prone to crashing on malformed input, produces a nested directory structure that is difficult to manage for the Godot level builder, and lacks robust idempotency for rerunning on updated JSON.

## What Changes
- **Graceful Error Handling**: Wrap resource generation in try/except blocks and log warnings instead of crashing.
- **Flattened Output Structure**: All `.tres` files for a level will be generated directly into the level's root folder (e.g., `res://level_data/<level_id>/`) without subdirectories.
- **Idempotency/Update Support**: Ensure the script can be safely rerun to update existing `.tres` files or fill in missing ones based on the latest JSON.
- **Logging**: Implement standardized logging for better visibility of the conversion process.

## Impact
- Affected specs: `level-generation` (new)
- Affected code: `json_to_tres.py`
