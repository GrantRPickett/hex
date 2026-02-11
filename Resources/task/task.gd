class_name Task
extends Resource

signal progress_changed(current: int, required: int, faction_id: int)
signal completed(faction_id: int)
signal failed

enum Status { PENDING, ACTIVE, COMPLETED, FAILED, CANCELLED }

@export_group("Identity")
@export var id: StringName
@export var title: String = "New Task"
@export_multiline var description: String = "A new task."
@export var icon: Texture2D

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

func interact(actor: Unit) -> void:
	if status != Status.ACTIVE:
		return

	var power = actor.get_attributes().get_attribute(required_attribute)
	var resistance = opposition_value

	if is_opposed and _target_unit:
		resistance = _target_unit.get_attributes().get_attribute(opposing_attribute)

	# Calculate net progress (High Watermark logic: we only add positive progress)
	var progress = max(1, power - resistance)

	# Apply progress
	current_effort += progress
	progress_changed.emit(current_effort, effort_required, actor.faction)

	if current_effort >= effort_required:
		_complete_task(actor.faction)

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
