# Function Similarity and Redundancy Report

## Duplicate Function Names (Excluding Private/Underscored)

### create_components
- GUI/HUD/hud_component_factory.gd: tatic func create_components(parent: Node, is_portrait: bool) -> Component
- Gameplay/targets/unit_component_factory.gd: tatic func create_components(unit: Unit) -> voi

### get_command_description
- Gameplay/commands/aid_ally_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/attack_unit_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/cancel_move_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/confirm_move_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/convince_unit_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/explore_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/game_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/joy_move_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/loot_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/move_action_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/move_to_coord_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/primary_action_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/select_index_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/selection_cycle_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/talk_to_unit_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/toggle_enemy_range_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/toggle_free_cam_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/trapped_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/trigger_dialogue_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/undo_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/use_skill_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/visit_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/wait_command.gd: tatic func get_command_description() -> Strin
- Gameplay/commands/zoom_camera_command.gd: tatic func get_command_description() -> Strin

### get_command_name
- Gameplay/commands/aid_ally_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/attack_unit_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/cancel_move_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/confirm_move_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/convince_unit_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/explore_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/game_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/joy_move_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/loot_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/move_action_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/move_to_coord_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/primary_action_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/select_index_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/selection_cycle_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/talk_to_unit_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/toggle_enemy_range_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/toggle_free_cam_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/trapped_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/trigger_dialogue_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/undo_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/use_skill_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/visit_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/wait_command.gd: tatic func get_command_name() -> Strin
- Gameplay/commands/zoom_camera_command.gd: tatic func get_command_name() -> Strin

### get_faction_name
- Autoloads/game_constants.gd: tatic func get_faction_name(faction: int) -> Strin
- Gameplay/targets/unit_presenter.gd: tatic func get_faction_name(unit: Unit) -> Strin

### get_neighbor_offsets
- Gameplay/map/hex_lib.gd: tatic func get_neighbor_offsets(coord: Vector2i, axis: int) -> Array[Vector2i
- Gameplay/map/hex_navigator.gd: tatic func get_neighbor_offsets(coord: Vector2i, offset_axis: int) -> Array[Vector2i

### validate
- level/validation/connectivity_validator.gd: tatic func validate(level: Level, level_id: String, roster_rows: Array, loot_rows: Array, location_rows: Array, start_rows: Array) -> Array[String
- level/validation/task_row_validator.gd: tatic func validate(level: Level, level_id: String, roster_rows: Array, loot_rows: Array, location_rows: Array) -> Array[String

## Similar Function Names (Potential Overlap)

