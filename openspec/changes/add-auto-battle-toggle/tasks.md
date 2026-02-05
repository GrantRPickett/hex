## 1. Auto Battle Toggle
- [ ] 1.1 Add UX notes (icon, tooltip, disabled state) to HUD component definitions.
- [ ] 1.2 Update Hud/HUDController/InputController to display an Auto Battle button, emit toggles, and reflect active state.

## 2. Delegate Player Turns To AI
- [ ] 2.1 Teach TurnController/GameState to keep an "auto battle active" flag and skip manual turn_ready emissions while active.
- [ ] 2.2 Reuse AIController for player units, ensuring cancelation drops back to manual control after any in-flight AI action completes.

## 3. Unsupported Action Reporting
- [ ] 3.1 Enumerate player commands not implemented by AIController (skills, interactions, etc.) and emit a HUD warning/log line when attempted under auto battle.
- [ ] 3.2 Store the unsupported list in telemetry/debug output for QA reference.

## 4. Testing
- [ ] 4.1 Add GdUnit tests for HUD toggle visibility/state and AI delegation handshake.
- [ ] 4.2 Add tests covering unsupported-action reporting path.
