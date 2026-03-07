## Context

The goal is to support "Capture the Flag" style quests where a specific item must be recovered from a unit and potentially defended for a number of turns.

## Goals

- Allow items to stay in unit inventories if they have the `quest` flag.
- Ensure `quest` items always drop on death (bypass difficulty).
- Support mid-stage rewards (Quest Items) given to the `actor` unit.
- Fix survival/countdown task attribution for the `owning_faction`.

## Decisions

### 1. Quest Item Flag

- We will keep the `quest` boolean in `InventoryItem.gd`.
- We will update the logic that "routes to stash" to only occur at the *end* of the level, instead of being a forced property that prevents unit possession.

### 2. Death Handler Logic

- `UnitDeathHandler._drop_loot` will be modified:

  ```gdscript
  var inv_items = _unit.inv.get_inventory().get_items()
  var quest_items = inv_items.filter(func(i): return i.quest)
  if not quest_items.is_empty():
      _loot_manager.spawn_loot(_unit.get_grid_location(), quest_items)
      # Remove them so they don't get routed to pool
      for qi in quest_items:
          _unit.inv.remove_item(qi)
  ```

### 3. Task Controller Completion

- `TaskController` will connect to `Task.completed(faction)`.
- It will use the `actor` reference (if available) to grant the `reward_id` (Item) to that unit.
- If no `actor` is available (e.g. passive completion), it will go to the faction leader or stash.

### 4. Duration/Survival Attribution

- `Task._process_round_changed` will be updated to:

  ```gdscript
  if duration_turns > 0:
      var holds := _duration_condition_holds(data)
      if holds:
          elapsed_turns += 1
          # ...
          if elapsed_turns >= duration_turns:
              _complete_task(owning_faction) # Use owning_faction as default winner
  ```

## Risks

- **Inventory Full**: If a unit receives a reward but has a full inventory. (Mitigation: Add to a "missed rewards" pool or spawn on the ground).
- **Multiple Quest Items**: Handling multiple items on one unit. (Mitigation: Standard inventory list handling).
