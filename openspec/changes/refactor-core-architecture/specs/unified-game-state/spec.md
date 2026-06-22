# Capability: unified-game-state

## MODIFIED Requirements

### Requirement: Unified State Container
The system MUST merge `GameSessionServices` and `GameState` into a single container that provides access to all services.

#### Scenario: Accessing Services
Given a unified `GameState` instance
When a service is requested (e.g., `state.unit_manager`)
Then the correct service instance is returned directly.

### Requirement: Service Consistency
The system MUST ensure all core services are available through this unified container.

#### Scenario: Service Presence
Given a `GameState` initialized by `GameSession`
Then it must contain valid references to `UnitManager`, `TaskManager`, `TurnController`, etc.
