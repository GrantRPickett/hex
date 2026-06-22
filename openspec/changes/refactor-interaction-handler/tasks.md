# Tasks for refactoring interaction handler

- [x] **Define InteractionResult Enum**: Create `class_name InteractionResult` or add an enum to an existing class that defines `SUCCESS`, `INVESTIGATED`, and `FAILED` (or `IGNORED`).
- [x] **Refactor `_try_interaction_detailed`**: Update `UnitInteractionHandler._try_interaction_detailed` and any usages (like `loot`) to return the new enum instead of `Variant` strings.
- [x] **Update `LootCommand.gd`**: Update `LootCommand` to check against the new enum values rather than `"success"` or `"investigated"`.
- [x] **Update `Target.interact` Signature**: Modify `Target.interact(unit: Unit)` to `Target.interact(unit: Unit, context: Dictionary = {})` and update the `interacted` signal similarly.
- [x] **Propagate Context**: Update the callers of `interact()` in `UnitInteractionHandler` (like `work_on_task`) to pass relevant context parameters (like `{"is_task": true, "task_id": ...}`) into the interaction.
- [x] **Update Listeners**: Update any scripts listening to the `interacted` signal (like `TaskManager`) to expect the new context argument.
