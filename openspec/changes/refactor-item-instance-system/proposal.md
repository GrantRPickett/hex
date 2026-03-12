# Change: Refactor Item Instance System

## Why

The current item system uses `InventoryItem` as both a resource template and an in-game instance. This leads to several issues:
1. **Memory Sharing**: Multiple units can inadvertently share the same resource instance if they are assigned the same `.tres` file without explicit duplication.
2. **Serialization Bloat**: Entire item dictionaries are saved for every instance, even when 90% of the data is static (template data).
3. **Ambiguity**: Hard to track which items are "originals" versus "clones" during level transitions and trading.

## What Changes

- **Template/Instance Separation**: Introduce `ItemTemplate` (static, read-only) and `InventoryItem` (dynamic, stateful instance).
- **ItemRegistry**: A central Autoload to manage and create item instances from templates.
- **UUID Persistence**: Ensure all item instances have stable UUIDs for safe movement between units and stash.
- **Save Refactor**: Update `UnitSerializer` and `SaveManager` to store `template_id` instead of full item data where possible.

## Impact

- Affected specs: `item-system` (new)
- Affected code: `inventory_item.gd`, `loot_manager.gd`, `unit_inventory.gd`, `unit_serializer.gd`, `item_registry.gd` (new), `item_template.gd` (new)
