# Project Context: HEX

## Purpose
HEX is a tactical, turn-based RPG built in Godot 4. It features hex-grid movement, squad-based combat with character intimacy, and a cozy-yet-tense narrative atmosphere.

## Tech Stack
- **Engine**: Godot 4.6+ (GDScript 2.0, strictly typed)
- **Tooling**: Python 3 (JSON ↔ TRES conversion, procedural generation)
- **Scripting**: PowerShell (Project validation, test runners)
- **Testing**: GdUnit4 (Headless gameplay logic verification)
- **Dialogue**: Dialogue Manager (Godot addon)

## Project Conventions

### Code Style
- **GDScript**: 
  - `snake_case` for methods, variables, and signals.
  - `PascalCase` for classes and types.
  - `UPPER_SNAKE_CASE` for constants.
  - Use `@export`, `@onready`, and explicit types (e.g., `var x: int = 0`).
  - Use Godot-style ternaries: `x if condition else y`.
- **Python**: PEP 8, `pathlib` for Windows-friendly paths, type annotations.

### Architecture Patterns
- **Command Pattern**: UI and AI emit `GameCommand` objects to the `InputCommandRouter`. Decouples logic from input.
- **Service-Oriented Architecture**: Managed by a central `GameState` inside a `GameSession` lifecycle.
- **Composition over Inheritance**: Units use components (`UnitCombatBehavior`, `InventoryComponent`, etc.) for logic.
- **Resource-Driven**: Levels, units, and items are defined in JSON and converted to `.tres` resources.

### Testing Strategy
- **100% Function Coverage**: Every function outside `tests/` or `addons/` must be referenced in a GdUnit4 test.
- **Headless First**: Gameplay logic (combat, movement, AI) must be testable without a running scene tree.
- **Validation Pipeline**: `pwsh -File scripts/validate.ps1 -UpdateTodos` is the source of truth for project health.

### Git Workflow
- Verb-led commit messages (e.g., `Add unit movement component`, `Fix combat math overflow`).
- OpenSpec workflow for all non-trivial changes (Proposals → Implementation → Archive).

## Domain Context

- **Hexgrid**: Uses Axial coordinates for math/distance and Offset for TileMapLayer rendering.
- **Willpower**: The primary resource (HP/Mana hybrid) for units.
- **Round**: A complete cycle where all available units from all factions (Player, Enemy, Neutral) have taken their individual turns. Each unit gets up to 1 full move, 1 action, and 1 reaction per round.
- **Command Pattern**: All gameplay actions must flow through the Command system.

## Important Constraints

- **Windows Environment**: All scripts must be PowerShell/Python compatible. Avoid Linux-only commands.
- **AI-Friendly**: Abstractions should remain simple and well-documented for AI agent collaboration.
