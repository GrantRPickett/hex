class_name LootCommand
extends GameCommand

static func get_command_name() -> String:
	return "loot"

static func get_command_description() -> String:
	return "Pick up loot at current position"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["unit_manager", "turn_controller"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# Validate context
	var ctx_result = validate_context(context)
	if ctx_result.is_failure():
		return ctx_result

	# Validate payload
	var payload_result = CommandValidator.validate_payload_dict_keys(
		payload,
		PackedStringArray(["looter_index", "loot_coord"])
	)
	if payload_result.is_failure():
		return payload_result

	var looter_idx: int = payload.get("looter_index", -1)
	var loot_coord: Vector2i = payload.get("loot_coord", Vector2i(-1, -1))

	if looter_idx < 0:
		return CommandResult.invalid_payload("Invalid unit index")

	if loot_coord == Vector2i(-1, -1):
		return CommandResult.invalid_payload("Invalid loot coordinate")

	# Get unit
	var looter = context.unit_manager.get_unit(looter_idx)
	if looter == null:
		return CommandResult.invalid_payload("Unit not found at index %d" % looter_idx)

	# Check preconditions
	if not context.turn_controller.can_act_on_index(looter_idx):
		return CommandResult.precondition_failed("Unit cannot act this turn")

	if not looter.res.has_action_available():
		return CommandResult.precondition_failed("Unit has no actions available")

	# Check unit is at loot location
	if looter.get_grid_location() != loot_coord:
		return CommandResult.precondition_failed("Unit must be at loot location to pick it up")

	# Execute loot
	looter.interaction.loot(loot_coord)
	return CommandResult.success()
