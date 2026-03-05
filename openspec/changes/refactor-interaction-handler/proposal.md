# Refactor Interaction Handler

## Summary
The current `UnitInteractionHandler` uses variant strings (e.g., `"success"`, `"investigated"`) to communicate interaction results back to commands like `LootCommand`. This is prone to typos and lacks type safety. Additionally, we need to ensure that the correct state and context are passed around to support both task and non-task related interaction flows cleanly.

This proposal refactors these string returns into a proper enum (`InteractionResult`) and updates the `interact` signals to pass an optional context dictionary so targets know exactly *why* they are being interacted with.

## Motivation
- **Type Safety**: Using an enum prevents accidental string typos and makes the expected return values explicit.
- **Context Awareness**: Right now, `Target.interact(unit)` only takes the `unit`. However, whether an interaction was triggered freely or as part of a task/objective might matter to the target or downstream systems. Passing a context dictionary fixes this blind spot.
- **Maintainability**: Makes extending interaction results or contexts much simpler in the future.
