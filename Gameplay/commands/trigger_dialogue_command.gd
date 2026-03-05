class_name TriggerDialogueCommand
extends GameCommand

static func get_command_name() -> String:
	return GameConstants.Commands.TRIGGER_DIALOGUE

static func get_command_description() -> String:
	return "Trigger a custom DialogueManager dialogue at a specific location"

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([])

func execute(context: GameCommandContext, payload = null) -> CommandResult:
	if payload == null or not payload is Dictionary:
		return CommandResult.invalid_payload("Payload must be a Dictionary with 'dialogue_resource_path' (String) and optionally 'start_title' (String).")

	var dialogue_resource_path = payload.get(GameConstants.Payload.DIALOGUE_RESOURCE_PATH)
	var start_title = payload.get(GameConstants.Payload.START_TITLE, "start")

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
