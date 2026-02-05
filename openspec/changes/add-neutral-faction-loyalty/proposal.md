## Why
Player/enemy turn sequencing and morale now recognize neutral units, but scenarios that mix or omit factions are undefined and neutrals cannot change allegiance over time. We need explicit design so levels can: (1) run with only player units, (2) run with no neutrals, (3) run with no enemies, and (4) let neutral units shift loyalty mid-level without changing direct control. Designers also asked that neutral loyalty resets every time a level loads.

## What Changes
- Define level-behavior requirements for the three faction-presence edge cases.
- Specify a neutral loyalty system where units track temporary leanings toward player or enemy, react to aggression, and can sway other neutrals.
- Require that neutral loyalty state resets whenever a level starts/restarts, preventing carry-over between missions.

## Impact
- Requires updates to level-building flow, AI controller, morale/goal systems, and save/checkpoint logic to respect faction permutations and loyalty resets.
- Additional UI/telemetry hooks likely needed to surface neutral leanings, though this proposal only scopes behavioral requirements.
