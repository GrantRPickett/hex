class_name TriggerDialogueCommand
extends GameCommand

func get_required_context_fields() -> PackedStringArray:
	# DialogueManager is a global (autoload), so no specific context fields needed for it.
	# We might need context if we want to pass extra_game_states or interact with other services.
	return PackedStringArray([])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	# No context validation needed for this simple command.
	# var ctx_result = validate_context(context)
	# if ctx_result.is_failure():
	# 	return ctx_result

	if payload == null or not payload is Dictionary:
		return CommandResult.invalid_payload("Payload must be a Dictionary with 'dialogue_resource_path' (String) and optionally 'start_title' (String).")

	var dialogue_resource_path = payload.get("dialogue_resource_path")
	var start_title = payload.get("start_title", "start")

	if dialogue_resource_path == null or not dialogue_resource_path is String:
		return CommandResult.invalid_payload("Payload missing 'dialogue_resource_path' (String).")

	var dialogue_resource = load(dialogue_resource_path) # Load the resource
	if dialogue_resource == null:
		return CommandResult.failed("Failed to load dialogue resource: " + dialogue_resource_path)

	# Assuming DialogueManager is a globally accessible singleton (autoload)
	if DialogueManager:
		DialogueManager.show_dialogue_balloon(dialogue_resource, start_title)
		return CommandResult.success()
	else:
		return CommandResult.failed("DialogueManager not found or not an autoload.")
