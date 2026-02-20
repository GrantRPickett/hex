class_name TalkToUnitCommand
extends GameCommand

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray(["unit_manager", "dialogue_action_service"])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	print_debug("TalkToUnitCommand: execute() called with payload: %s" % str(payload))
	var ctx_result := validate_context(context)
	if ctx_result.is_failure():
		print_debug("TalkToUnitCommand: Context validation failed: %s" % ctx_result.get_error_message())
		return ctx_result

	var payload_result := CommandValidator.validate_payload_dict_keys(
		payload,
		PackedStringArray(["initiator_index", "target_index", "dialogue_id"])
	)
	if payload_result.is_failure():
		print_debug("TalkToUnitCommand: Payload validation failed: %s" % payload_result.get_error_message())
		return payload_result

	var initiator_index := int(payload.get("initiator_index", -1))
	var target_index := int(payload.get("target_index", -1))
	var dialogue_id_value = payload.get("dialogue_id", "")
	var dialogue_id :StringName = dialogue_id_value if dialogue_id_value is StringName else StringName(dialogue_id_value)

	if initiator_index < 0 or target_index < 0:
		print_debug("TalkToUnitCommand: Invalid indices - initiator: %d, target: %d" % [initiator_index, target_index])
		return CommandResult.invalid_payload("Invalid initiator or target index")

	var service = context.get_field("dialogue_action_service")
	if service == null:
		print_debug("TalkToUnitCommand: Missing dialogue_action_service in context")
		return CommandResult.invalid_context(["dialogue_action_service"])

	print_debug("TalkToUnitCommand: Calling service.start_dialogue with id='%s'" % dialogue_id)
	var result = service.start_dialogue(dialogue_id, initiator_index, target_index)
	print_debug("TalkToUnitCommand: service.start_dialogue returned: %s" % result.get_description())
	return result
