## Why
- Every gameplay/HUD script currently instantiates Tweens directly, so UI or engine refactors require auditing dozens of files.
- Designers cannot change animation timing/styles without touching GDScript because there is no central definition.
- QA needs deterministic hooks to stub/inspect player-facing motion for automated tests.

## What Changes
- Introduce an Animation Request Service that exposes typed APIs (unit movement, HUD feedback, generic node animation) and owns all Tween creation.
- Load animation style definitions from resources/config so designers adjust motion without editing scripts.
- Route gameplay systems (unit movement, HUD warnings, loot popups, etc.) through the service and emit semantic events instead of manipulating Tweens directly.

## Impact
- GameSessionBuilder/Services/GameState gain a new dependency for the animation service and must pass it to controllers that need animations.
- Scripts using `create_tween()` will be migrated to request animations through the service, reducing direct Godot coupling.
- New automated tests will target the service API so future UI rebuilds only reimplement the service/presentation shell.
