# Interaction Result Spec

## Context

Interacting with targets (like Loot, Locations, Units) should return typed states and supply context to the target, rather than relying on magical variant strings and contextless signals.

## MODIFIED Requirements

### Requirement: Interaction Handlers MUST Return Enums

Instead of returning `"success"` or `"investigated"`, handlers like `Loot` MUST return an explicit `InteractionResult.Type` enum `SUCCESS`, `INVESTIGATED`, or `FAILED`.

#### Scenario: Looting a trapped item

When a unit loots a trapped item, `UnitInteractionHandler.loot` returns `InteractionResult.Type.INVESTIGATED`, which `LootCommand` correctly maps to a success message "Trap investigated".

### Requirement: Interaction Signals MUST Provide Context

The `Target.interacted` signal and `Target.interact()` methods MUST supply an optional `context: Dictionary = {}` to provide the downstream listeners (like `TaskManager`) the context under which the interaction happened.

#### Scenario: Interacting via a Task

When `UnitInteractionHandler.work_on_task` calls `node_to_interact.interact(_unit)`, it passes a context dictionary e.g., `{"is_task": true, "task_id": "explore_ruins"}` so that the `TaskManager` accurately attributes the interaction.
