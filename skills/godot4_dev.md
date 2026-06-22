# Godot 4 Development Skill

## Mission
Deliver maintainable gameplay, UI, and tooling features in idiomatic Godot 4 GDScript.

## Workflow
1. **Context Check**: Read existing component specs and `Documentation/ARCHITECTURE.md` before coding.
2. **Idiomatic Style**: Use `snake_case` for methods/vars and `PascalCase` for classes.
3. **Strict Typing**: Use explicit types (e.g., `var x: int = 0`) and `@export` / `@onready` annotations.
4. **Composition First**: Favor node composition and resource-driven data over inheritance when extending systems.
5. **Command Flow**: All gameplay actions must be implemented as `GameCommand` objects to the `InputCommandRouter`.

## Best Practices
- **Service Access**: Reference services via the central `GameState` (inside `GameSession`) instead of global singletons where possible.
- **Signal-Driven**: Keep component APIs small and signal-driven to ensure decoupling.
- **Editor Safety**: Use `_get_configuration_warnings` to provide helpful hints to designers in the editor.
- **Ternaries**: Use Godot-style ternaries (`x if condition else y`).
- **Path Handling**: Reference resources via `res://` paths; avoid hardcoded local paths.

## Collaboration
- **QA & Architect**: Pair during design reviews to validate testing hooks and pattern alignment.
- **Product & Documentation**: When scope expands, create TODO breadcrumbs in `TODO.md` or near the affected code.
- **Narrative Designer**: Provide context on balance knobs and tunable constants in resources.
