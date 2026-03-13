class_name ToggleEnemyRangeCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.TOGGLE_ENEMY_RANGE

func execute(context: GameCommandContext, _payload = null) -> CommandResult:
	var validation = validate_context(context)
	if validation.is_failure():
		return validation

	var grid_visuals = context.grid_visuals
	var unit_manager = context.unit_manager
	var terrain_map = context.terrain_map
	var grid = context.grid

	if not grid_visuals or not grid_visuals.has_method("toggle_enemy_range_view"):
		return CommandResult.failed("Missing grid_visuals or toggle method")

	grid_visuals.toggle_enemy_range_view()

	if grid_visuals.is_enemy_range_visible() and unit_manager and terrain_map and grid:
		grid_visuals.update_enemy_range_overlay(unit_manager, terrain_map, grid)

	return CommandResult.success()

func get_required_context_fields() -> PackedStringArray:
	return [
		GameConstants.Context.GRID_VISUALS, 
		GameConstants.Context.UNIT_MANAGER, 
		GameConstants.Context.TERRAIN_MAP, 
		GameConstants.Context.GRID
	]
