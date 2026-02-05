## 1. Discovery & API Design
- [ ] 1.1 Inventory existing Tween usage across gameplay/HUD scripts and categorize common patterns (unit move, HUD toast, loot pop, generic).
- [ ] 1.2 Draft the Animation Request Service API (request structs, style IDs, signals) and capture it in design notes/specs.

## 2. Animation Service Implementation
- [ ] 2.1 Add an AnimationRequestService that owns Tween instances, queues requests, and exposes typed helpers for common gameplay/HUD motions.
- [ ] 2.2 Create resource-driven style definitions (duration, easing, offsets) and teach the service to load/validate them.

## 3. Engine Integration
- [ ] 3.1 Update GameSessionServiceFactory/GameSessionBuilder/GameState to create, configure, and expose the animation service to consumers.
- [ ] 3.2 Extend LevelBuild/GameSession contexts so controllers (move, HUD, loot, etc.) receive the animation service via constructor or setter injection.

## 4. Migration of Callers
- [ ] 4.1 Migrate unit movement, HUD warning feedback, and loot popups to issue animation requests instead of instantiating Tweens directly.
- [ ] 4.2 Emit semantic presentation events where direct Tween coupling remains so additional callers can be migrated incrementally.

## 5. Testing & Telemetry
- [ ] 5.1 Add GdUnit tests covering the animation service API (queuing, style resolution, fallback behavior) and update existing tests to mock/inspect requests.
- [ ] 5.2 Document debugging hooks/telemetry so QA can trace animation requests during automation.
