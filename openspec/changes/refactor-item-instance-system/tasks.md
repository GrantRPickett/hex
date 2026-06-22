# Tasks

## 1. Setup & Core Resources

- [ ] 1.1 Create `ItemTemplate` resource class
- [ ] 1.2 Create `ItemRegistry` Autoload and register in `project.godot`
- [ ] 1.3 Update existing `.tres` items to use `ItemTemplate` or migrate them

## 2. Item Instance Refactor

- [ ] 2.1 Refactor `InventoryItem` to reference `ItemTemplate`
- [ ] 2.2 Update `InventoryItem` to handle instance-specific state (equipped, UUID)
- [ ] 2.3 Implement `ItemRegistry.create_instance(item_id)`

## 3. Manager & UI Integration

- [ ] 3.1 Update `LootManager` to use `ItemRegistry`
 for spawning
- [ ] 3.2 Update `InventoryService` for safe item transfers
- [ ] 3.3 Update `UnitSerializer` to persist `template_id` + UUID + equipped status

## 4. Verification

- [x] 4.1 Implement `GdUnit4` test for `ItemRegistry`
.gd`
- [ ] 4.2 Write `test_item_serialization.gd`
- [ ] 4.3 Verify in-game loot and inventory persistence
