class_name TaskDetailsPanel
extends CustomResizablePanel

const LocalizationStrings := preload(FilePaths.Resources.LOCALIZATION_STRINGS)


@onready var _task_name_label: Label = %TaskNameLabel
@onready var _task_description_label: Label = %TaskDescriptionLabel
@onready var _task_status_label: Label = %TaskStatusLabel

var _back_button: Button
var _pending_update: Variant = null
var _last_task_data: Variant = null

func _ready() -> void:
	super._ready()
	hide()
	_setup_back_button()
	LocaleService.locale_changed.connect(_on_locale_changed)
	if _pending_update:
		update_details(_pending_update)
		_pending_update = null

func _setup_back_button() -> void:
	_back_button = Button.new()
	_back_button.text = tr("hud.action_back_to_list")
	_back_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_back_button.pressed.connect(_on_back_pressed)

	# Match the structure from the .tscn: VBoxContainer is a direct child
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		# Fallback: check inside MarginContainer if it existed
		for child in get_children():
			if child is MarginContainer:
				vbox = child.get_child(0)
				if vbox is VBoxContainer:
					break

	if vbox:
		vbox.add_child(_back_button)
		vbox.move_child(_back_button, 0)

func _on_back_pressed() -> void:
	hide()
	# Fallback: find HUDController
	var hud = get_viewport().get_node_or_null("HUD")
	if hud and hud.has_method("_on_portrait_tab_pressed"):
		hud._on_portrait_tab_pressed(GameConstants.UI.TAB_TASKS)

func setup(_state: GameState, _config: GameSessionBuilder.Config) -> void:
	pass # No specific setup for now

func _on_locale_changed() -> void:
	if visible and _last_task_data:
		update_details(_last_task_data)

func update_details(task_data) -> void:
	if not is_node_ready():
		_pending_update = task_data
		return
	if task_data == null or (task_data is Dictionary and task_data.is_empty()):
		hide()
		_last_task_data = null
		return

	_last_task_data = task_data
	show()
	var title = task_data.get("title", LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_UNKNOWN))
	_task_name_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_NAME_LABEL).format({"title": title})
	var description_text = task_data.get("description", LocalizationStrings.get_text(LocalizationStrings.HUD_TARGET_NA))
	if String(description_text).is_empty():
		description_text = LocalizationStrings.get_text(LocalizationStrings.HUD_TARGET_NA)
	_task_description_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_DESCRIPTION_LABEL).format({"description": description_text})


	var is_completed: bool = bool(task_data.get("completed", false))
	var current: int = int(task_data.get("current", 0))
	var max_val: int = int(task_data.get("required", 0))

	var progress_text: String = ""
	if max_val > 0:
		var unit_name = "rounds" if task_data.get("duration_turns", 0) > 0 or task_data.get("event_type", "") == "countdown" else "effort"
		progress_text = " (%d/%d %s)" % [current, max_val, unit_name]

	var status_word = LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_COMPLETED) if is_completed else LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_IN_PROGRESS)
	_task_status_label.text = LocalizationStrings.get_text(LocalizationStrings.HUD_TASK_STATUS_LABEL).format({"status": status_word}) + progress_text
	force_fit_content()
