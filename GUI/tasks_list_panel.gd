class_name TasksListPanel
extends PanelContainer

const TaskListItemScene := preload(FilePaths.Scenes.TASK_LIST_ITEM)

signal task_hovered(task_data: Dictionary)
signal task_unhovered()
signal task_completion_requested(task_id: String)
signal task_selected(task_data: Dictionary)

@onready var tasks_container: VBoxContainer = %TasksContainer
@onready var header_button: Button = %HeaderButton
@onready var content_margin: MarginContainer = %Content
@onready var title_label: Label = %TitleLabel
@onready var expand_icon: Label = %ExpandIcon

var _pending_tasks_data = null
var _last_tasks_data = null

func _ready() -> void:
	hide()
	LocaleService.locale_changed.connect(_on_locale_changed)
	if _pending_tasks_data != null:
		update_tasks(_pending_tasks_data)
		_pending_tasks_data = null
		
	if header_button:
		header_button.toggled.connect(_on_header_toggled)
		# Initialize state
		_on_header_toggled(header_button.button_pressed)
		
	if title_label:
		title_label.text = tr("hud.label.tasks")

	if DisplaySettings:
		DisplaySettings.display_settings_changed.connect(_on_display_settings_changed)
	
	_update_layout()

func _on_header_toggled(is_expanded: bool) -> void:
	if content_margin:
		content_margin.visible = is_expanded
	if expand_icon:
		expand_icon.text = "▼" if is_expanded else "▶"
	
	# Force container resize
	custom_minimum_size.y = 0
	size.y = 0

func _on_locale_changed() -> void:
	if title_label:
		title_label.text = tr("hud.label.tasks")
	if _last_tasks_data:
		update_tasks(_last_tasks_data)

func update_tasks(grouped_tasks: Array) -> void:
	if not grouped_tasks.is_empty():
		print_debug("[TasksListPanel] update_tasks called with ", grouped_tasks.size(), " factions")
	
	_last_tasks_data = grouped_tasks
	if not is_node_ready():
		_pending_tasks_data = grouped_tasks
		return

	if not is_instance_valid(tasks_container):
		return
	for child in tasks_container.get_children():
		child.queue_free()

	if grouped_tasks.is_empty():
		hide()
		return

	show()
	for faction_group in grouped_tasks:
		var faction_name = faction_group.get("faction_name", "UNKNOWN")
		var tasks = faction_group.get("tasks", [])
		
		if tasks.is_empty():
			continue
			
		# Add faction header
		var header: Label = Label.new()
		header.text = faction_name
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Add some styling to the header
		header.add_theme_color_override("font_color", GameConstants.Colors.TASK_FACTION_HEADER) # Yellowish for faction headers
		tasks_container.add_child(header)
		
		for task_data in tasks:
			var task_item: Node = TaskListItemScene.instantiate()
			tasks_container.add_child(task_item)
			if task_item.has_method("update_task"):
				task_item.update_task(task_data)
				task_item.hovered.connect(func(data): task_hovered.emit(data))
				task_item.unhovered.connect(func(): task_unhovered.emit())
				task_item.selected.connect(func(data): task_selected.emit(data))
				if task_item.has_signal("completion_requested"):
					task_item.completion_requested.connect(func(id): task_completion_requested.emit(id))

func _on_display_settings_changed(_orientation: int, _resolution: Vector2i) -> void:
	_update_layout()

func _update_layout() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var is_portrait = viewport_size.y > viewport_size.x
	
	var font_size = 14 if is_portrait and viewport_size.x < 500 else 18
	
	if title_label:
		title_label.add_theme_font_size_override("font_size", font_size)
	if expand_icon:
		expand_icon.add_theme_font_size_override("font_size", font_size)
		
	if tasks_container:
		tasks_container.add_theme_constant_override("separation", 5 if is_portrait else 10)
		for child in tasks_container.get_children():
			if child is Label:
				child.add_theme_font_size_override("font_size", font_size)
