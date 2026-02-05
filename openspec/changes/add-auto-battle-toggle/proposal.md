## Why
- Players want a low-friction way to watch battles without issuing every command manually.
- QA needs a deterministic method to let the AI resolve player turns for soak and regression runs.
- Current UI offers no toggle to delegate player control, so canceling mid-battle requires ad-hoc hacks.

## What Changes
- Add an Auto Battle toggle button to the HUD that reflects active/inactive state and pauses hint text while engaged.
- When Auto Battle is on, route player-controlled units through the existing AIController turn executor until the player cancels.
- Surface diagnostics when AI-controlled player units encounter unsupported commands so gaps can be tracked.

## Impact
- HUD, HUDController, and InputController gain new signals/state to expose the toggle and allow cancelation.
- TurnController and AIController must accept "player side uses AI" mode and allow seamless re-entry to manual control.
- New tests must cover toggle state transitions, AI delegation, and unsupported-action reporting paths.
