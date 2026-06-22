# Capability: standardized-service-setup

## MODIFIED Requirements

### Requirement: Consistent Setup Interface
All services SHALL use a consistent `setup` method that takes the `GameSession` or `GameState` as its primary dependency.

#### Scenario: Service Configuration
Given a service (e.g., `TurnController`)
When its `setup(session)` method is called
Then it should correctly resolve its dependencies from the session's state.
