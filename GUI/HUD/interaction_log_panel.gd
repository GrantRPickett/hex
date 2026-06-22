extends Control
class_name InteractionLogPanel

@onready var _scroll_container: ScrollContainer = %ScrollContainer
@onready var _log_container: VBoxContainer = %LogContainer

const MAX_LOGS := 50 # Total history limit
const VISIBLE_LOGS := 3 # Logs visible by default without scrolling

# Preload a simple label for log entries
var _log_label_scene := preload("res://GUI/HUD/components/log_entry_label.tscn")

func _ready() -> void:
	EventBus.interaction_logged.connect(_on_interaction_logged)
	_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	
	# Enable scrolling on hover
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(_state: GameState, _config: GameSessionBuilder.Config) -> void:
	# Any specific setup logic if needed
	pass

func _on_interaction_logged(message: String) -> void:
	# Create new log entry
	var label := _log_label_scene.instantiate() as Label
	label.text = message
	
	_log_container.add_child(label)
	
	# Limit number of logs in history
	if _log_container.get_child_count() > MAX_LOGS:
		var oldest := _log_container.get_child(0)
		_log_container.remove_child(oldest)
		oldest.queue_free()
	
	# Scroll to bottom if not hovering
	await get_tree().process_frame
	if _scroll_container.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_NEVER:
		_scroll_container.scroll_vertical = int(_scroll_container.get_v_scroll_bar().max_value)

func _on_mouse_entered() -> void:
	_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS

func _on_mouse_exited() -> void:
	_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	# Snap back to bottom
	_scroll_container.scroll_vertical = int(_scroll_container.get_v_scroll_bar().max_value)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# Scroll wheel will work naturally with ScrollContainer when visible
			pass
