class_name Task
extends Resource

signal progress_changed(current: int, required: int, faction_id: int)
signal completed(faction_id: int)
signal failed

enum Status {PENDING, ACTIVE, COMPLETED, FAILED, CANCELLED}

@export_group("Identity")
@export var id: StringName
@export var title: String = "New Task"
@export_multiline var description: String = "A new task."
@export var icon: Texture2D

@export_group("Criteria")
@export var event_type: String = "interact"
@export var target_coord: Vector2i = Vector2i(-999, -999)
@export var target_id: String = ""

@export_group("Requirements")
@export var required_attribute: String = "grit"
@export var effort_required: int = 10
@export var is_optional: bool = false

@export_group("Opposition")
@export var is_opposed: bool = false
@export var opposing_attribute: String = "defense"
@export var opposition_value: int = 0 ## Static difficulty if no target unit is present

@export_group("Rewards")
@export var journal_entry_id: String = ""
@export var reward_id: String = ""

# Runtime State
var status: Status = Status.PENDING
var current_effort: int = 0
var winning_faction: int = -1
var _target_unit: Unit = null # The unit/object being acted upon, if any

func initialize(target: Unit = null) -> void:
	status = Status.ACTIVE
	current_effort = 0
	winning_faction = -1
	_target_unit = target

func handle_event(type: String, data: Dictionary) -> void:
	if status != Status.ACTIVE:
		return

	var actor = data.get("unit") as Unit
	var progress = 1
	var event_processed = false

	match type:
		"interact":
			if event_type != "interact":
				return

			if target_coord != Vector2i(-999, -999):
				var coord = data.get("coord", Vector2i(-999, -999))
				if coord != target_coord:
					return

			if not target_id.is_empty():
				var id_val = data.get("id", "")
				if id_val != target_id:
					return
			event_processed = true

		"move": # New event type for movement-based tasks
			if event_type != "explore_zone":
				return

			var unit_coord = data.get("coord", Vector2i.ZERO)
			var unit_index = data.get("unit_index", -1) # Need unit index for dialogue

			if zone_coords.is_empty():
				push_warning("Task '%s': explore_zone task has no zone_coords defined." % id)
				return

			if unit_coord in zone_coords:
				# Check if dialogue should be triggered
				if not dialogue_id.is_empty() and Engine.has_singleton("DialogueActionService"):
					var ds = Engine.get_singleton("DialogueActionService")
					if ds.has_method("start_dialogue"):
						# Assuming actor is the initiator and its own target for zone exploration dialogue
						if unit_index != -1:
							# Use dummy target_index if not relevant, or actual unit_index
							ds.start_dialogue(dialogue_id, unit_index, unit_index)
						else:
							push_warning("Task '%s': explore_zone dialogue could not start, unit_index missing." % id)
				event_processed = true

		_:
			# Other event types not handled by this task
			return

	if not event_processed:
		return

	if actor and not required_attribute.is_empty():
		var attrs = actor.get_attributes()
		if attrs:
			var val = attrs.get_attribute(required_attribute)
			progress = max(1, val)

	# Apply progress
	current_effort += progress
	progress_changed.emit(current_effort, effort_required, actor.faction if actor else 0)

	if current_effort >= effort_required:
		_complete_task(actor.faction if actor else 0)

func _complete_task(faction: int) -> void:
	status = Status.COMPLETED
	winning_faction = faction
	completed.emit(faction)

func cancel() -> void:
	if status == Status.ACTIVE:
		status = Status.CANCELLED
		# We do not emit failed here to avoid triggering failure logic during clean transitions

func get_progress_ratio() -> float:
	if effort_required <= 0: return 1.0
	return float(current_effort) / float(effort_required)

@export_group("Dialogue & Zones")
@export var dialogue_id: StringName = &""
@export var enter_dialogue_id: StringName = &""
@export var exit_dialogue_id: StringName = &""
@export var enter_journal_id: String = ""
@export var exit_journal_id: String = ""
@export var zone_coords: Array[Vector2i] = [] # For "explore_zone" type tasks
