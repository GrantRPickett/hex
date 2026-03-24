class_name ToggleEnemyRangeCommand
extends GameCommand

static func _get_command_id() -> GameConstants.Commands.CommandID:
	return GameConstants.Commands.CommandID.TOGGLE_ENEMY_RANGE

static func create_payload() -> Dictionary:
	return {}

func execute(context: GameCommandContext, _payload: Dictionary = {}) -> CommandResult:
	var ctx_result := validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	var grid_visuals = context.grid_visuals
	var grid = context.grid

	if not grid_visuals or not grid_visuals.has_method("toggle_enemy_range_view"):
		return CommandResult.failed("Missing grid_visuals or toggle method")

	grid_visuals.toggle_enemy_range_view()

	if grid_visuals.is_enemy_range_visible() and context.map_controller and grid:
		grid_visuals.update_enemy_range_overlay(grid, context.map_controller.get_threat_map())

	return CommandResult.success()

func get_required_context_fields() -> PackedStringArray:
	return [
		GameConstants.ContextKeys.GRID_VISUALS, 
		GameConstants.ContextKeys.UNIT_MANAGER, 
		GameConstants.ContextKeys.TERRAIN_MAP, 
		GameConstants.ContextKeys.GRID
	]
