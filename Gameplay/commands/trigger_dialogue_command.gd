class_name TriggerDialogueCommand
extends GameCommand

static func _get_command_id() -> GameConstants.ActionType:
	return GameConstants.ActionType.TRIGGER_DIALOGUE

func get_required_context_fields() -> PackedStringArray:
	return PackedStringArray([])

static func create_payload(resource_path: String, start_title: String = "start") -> Dictionary:
	return {
		GameConstants.Payload.DIALOGUE_RESOURCE_PATH: resource_path,
		GameConstants.Payload.START_TITLE: start_title
	}

func execute(context: GameCommandContext, payload: Dictionary = {}) -> CommandResult:
	var dialogue_resource_path = payload.get(GameConstants.Payload.DIALOGUE_RESOURCE_PATH)
	var start_title = payload.get(GameConstants.Payload.START_TITLE, "start")

	if dialogue_resource_path == null or not dialogue_resource_path is String:
		return CommandResult.invalid_payload("Payload missing 'dialogue_resource_path' (String).")

	var dialogue_resource: Resource = load(dialogue_resource_path) # Load the resource
	if dialogue_resource == null:
		return CommandResult.failed("Failed to load dialogue resource: " + dialogue_resource_path)

	# Assuming DialogueManager is a globally accessible singleton (autoload)
	if DialogueManager:
		var log_msg := "Dialogue triggered: %s" % dialogue_resource_path.get_file().get_basename()
		EventBus.interaction_logged.emit(log_msg)
		
		if context and context.auto_battle_active:
			return CommandResult.success()
			
		DialogueManager.show_dialogue_balloon(dialogue_resource, start_title)
		return CommandResult.success()
	else:
		return CommandResult.failed("DialogueManager not found or not an autoload.")
