# Change: Refactor prints to Logger class

## Why
The project currently uses bare `print()` and `printerr()` statements scattered across the codebase. Refactoring to a centralized `Logger` class (aligned with Godot 4.5 logging paradigms) will allow for structured logging, varying log levels (debug, info, warning, error), and better maintainability. Additionally, it will introduce category-based toggling so developers can easily turn specific logs (e.g., AI, Combat, UI) on or off from a central location, reducing clutter during debugging.

## What Changes
- Add/Configure the `Logger` class to handle application logging with support for sub-system categories.
- Introduce a central configuration (e.g., inside `Logger` or `GameConstants`) to toggle categories on and off.
- Refactor all existing `print()`, `printerr()`, and `push_error()` calls across the GDScript files to use `Logger.info(category, message)`, `Logger.error()`, or equivalent.

## Impact
- Affected specs: `logging` (new capability)
- Affected code: Broad refactor across the entire codebase (`Gameplay/`, `Menus/`, `Autoloads/`, etc.).
