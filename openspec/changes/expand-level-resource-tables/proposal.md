## Why
The new roster/loot/goal tables let designers edit combat content in ResourceTables, but the rest of each level still requires hand-editing .tres assets: terrain grids, player start locations, neutral spawns, and dialogue triggers. Designers want to iterate entirely inside the spreadsheet view, and QA needs an automated validator that ensures no edited rows push coordinates out of bounds or overlap player spawns/terrain. Without that, level updates still involve scripting expertise and manual audits.

## What Changes
- Introduce ResourceTables-friendly row scripts for terrain tiles, player/neutral starts, and dialogue triggers. Store them under dedicated folders with templates so designers can duplicate rows just like the roster/loot data.
- Extend the loader to merge these new row types back into Level resources (terrain data, player_starts, dialogue entries) before gameplay builds a map.
- Add a level validator service that runs after rows are applied to ensure: coords sit within the terrain grid, player starts don’t overlap each other or enemy spawns, dialogue triggers reference valid timelines, and terrain rows cover the declared grid dimensions. Failures must surface as warnings/errors tied to the offending row file.
- Update specs/tests/workflows so editing any level attribute can happen through ResourceTables.

## Impact
- Designers gain spreadsheet editing for every major level attribute, reducing friction and mistakes when tweaking maps or dialogue placements.
- Gameplay loading depends on the expanded loader/validator, so errors in row data will now be caught deterministically; CI coverage must enforce this.
- Requires new row scripts, templates, loader extensions, validator service, and migration of existing level data into the new rows.
