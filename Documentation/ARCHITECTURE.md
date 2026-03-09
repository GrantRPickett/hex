# HEX Architecture Overview

This document provides a high-level overview of the HEX project's technical architecture, core systems, and design patterns.

## Core Concepts

HEX uses a **Service-Oriented Architecture** managed by a central **GameState** object. The game minimizes reliance on global singletons, preferring dependency injection through a `GameSession` lifecycle.

### The GameSession Lifecycle

1.  **Creation**: `GameSessionBuilder` takes a `Config` (containing the level resource and grid reference) and constructs a `GameState`.
2.  **Initialization**: `GameSession` initializes technical systems (hex navigation, visual overlays) and attaches service nodes to the scene tree.
3.  **Active Play**: The `TurnController` manages the flow between factions (Player, Enemy, Neutral).
4.  **Teardown**: When a level ends or the player quits, `GameSession` emits `session_ended` and cleans up all associated services.

## Core Systems

### 1. GameState & Dependency Injection
The `GameState` object is a single "source of truth" container that holds references to every active service (e.g., `UnitManager`, `CombatSystem`, `MoveController`). Services are initialized with a reference to the `GameState` (or specific dependencies) to avoid reaching into the global `/root`.

### 2. Unit Component System
Units in HEX are not monolithic. They use a composition-based approach where behavior is delegated to specific components:

| Component | Responsibility |
| :--- | :--- |
| `UnitCombatBehavior` (`combat`) | Handles attack execution and aid (Encourage) logic. |
| `UnitMovementBehavior` (`movement`) | Manages pathfinding and movement point consumption. |
| `InventoryComponent` (`inv`) | Manages items and calculated attributes. |
| `ActionPointsComponent` (`res`) | Tracks willpower (HP) and action/movement points. |
| `UnitQueryService` (`query`) | Provides hex-aware spatial queries (neighbors, range checks). |
| `UnitDeathHandler` (`death`) | Orchestrates the cleanup and animation when a unit is defeated. |

### 3. Command Pattern
User and AI inputs are abstracted into **Commands**. 
- **Decoupling**: The UI/AI doesn't directly modify unit stats. Instead, it creates a `GameCommand` (like `MoveToCoordCommand`) and sends it to the `InputCommandRouter`.
- **Validation**: Every command is validated against the current `GameState` and `CommandResult` is returned to the caller.
- See: `COMMAND_PATTERN_GUIDE.md` for implementation details.

### 4. Hexgrid & Navigation
The project uses a standard Godot `TileMapLayer` but abstracts the logic into:
- **Axial Coordinates**: Used for math, distances, and range calculations.
- **Offset Coordinates**: Used for visual placement and Godot's native tile addressing.
- **HexNavigator**: A service that handles the conversion and grid-aware pathfinding.

## Event Flow & Signals

HEX uses a tiered signal approach:
1.  **Local Signals**: Emitted by units/components (e.g., `willpower_changed`).
2.  **Service Signals**: Emitted by managers (e.g., `UnitManager.unit_selected`).
3.  **Global Bus**: The `EventBus` autoload is used for cross-cutting concerns that don't have a clear owner, though direct service-to-service communication is preferred where possible.
4.  **Locale Signal**: `LocaleService.locale_changed` triggers UI refreshes when the language is swapped.

## Technical Standards

- **GDScript 2.0**: All code is strictly typed.
- **Determinism**: Game logic (combat math, AI scoring) is kept separate from visual "glue" to ensure it can be unit-tested headlessly.
- **Testing**: GdUnit4 is the primary testing framework. Most gameplay logic is verified in `tests/`.

## State Persistence & Save Data

HEX distinguishes between **Session State** (current level progress) and **Global Persistence** (unlocked content).

### 1. The SaveManager (Global Persistence)
The `SaveManager` autoload handles long-term persistence across game sessions. It uses a `user://save_game.cfg` file to store:
- Completed levels and high scores.
- Unlocked achievements.
- Player roster state (surviving units and their equipment).

### 2. Journal vs. Task State
While related, narrative and mechanical progress are tracked differently:
- **TaskManager (Mechanical)**: Tracks the active `Objective`, `Stage`, and `Task` resources. It is responsible for level completion logic. Its state is captured in "Game Mementos" for undo/redo support within a session.
- **JournalManager (Narrative)**: Listens to the `TaskManager` and `EventBus` to unlock lore entries. It maintains a separate `JournalData` structure that persists globally, ensuring that a player's "discovery" of lore is remembered even if they fail a level or restart.

### 3. Undo/Redo System
The `SaveManager` also provides a memento-based undo system. Every time a major action completes, a snapshot of the current `GameState` (including unit positions, health, and task progress) is pushed to a history stack, allowing the player to revert mistakes.
