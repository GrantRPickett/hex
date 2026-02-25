# Change: Refactor Core Architecture

## Why
The current architecture for game session initialization and service management is highly coupled and redundant.
- `GameState` and `GameSessionServices` overlap significantly.
- Initialization is scattered across `Gameplay.gd`, `GameSessionBuilder`, and various `setup` methods.
- Signal wiring is manual and hard to maintain.

## What Changes
- **Unified Game State**: Merge `GameSessionServices` and `GameState` into a single container.
- **Game Session Node**: Create a dedicated `GameSession` node to manage service lifecycles.
- **Standardized Setup**: Refactor services to use a consistent `setup(session)` interface.
- **Refactored Gameplay.gd**: Thin out the main gameplay entry point.

## Impact
- Affected specs: `unified-game-state`, `game-session-node`, `standardized-service-setup`
- Affected code: `Gameplay.gd`, `GameSessionBuilder.gd`, `GameState.gd`, `GameSessionServices.gd`, and most core services.
