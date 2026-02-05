## ADDED Requirements

### Requirement: Animation Request Service
Gameplay systems MUST request visual motion through a dedicated AnimationRequestService instead of instantiating Godot Tweens directly so that presentation logic can be swapped without touching core code.

#### Scenario: Unit move request routed via service
- **GIVEN** a unit needs to slide to a new grid coordinate
- **WHEN** MoveController finalizes the move
- **THEN** it submits a `unit_move` request (unit id + coord + style id) to the AnimationRequestService and does not call `create_tween()` itself

#### Scenario: HUD warning animation dispatched centrally
- **GIVEN** the HUD needs to flash a warning banner
- **WHEN** HUDController emits a `warning_banner` request
- **THEN** the AnimationRequestService applies the configured style to the banner node and reports completion via a signal for tests/telemetry

### Requirement: Declarative Animation Styles
Animation timings/easings MUST be defined in data (e.g., AnimationStyle resources) addressable by ID so designers and future front-ends can change presentation without modifying scripts.

#### Scenario: Style lookup drives motion
- **GIVEN** an animation request references style id `hud-warning`
- **WHEN** the service processes the request
- **THEN** it loads the `hud-warning` style (duration, easing, offsets) from the style catalog and applies those parameters to the tween; if the style is missing it falls back to a default and logs a warning
