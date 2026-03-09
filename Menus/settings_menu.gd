extends Control

signal back_requested

@onready var _volume_slider: HSlider = $CanvasLayer/Panel/VBox/VolumeRow/Volume
@onready var _mute_check: CheckButton = $CanvasLayer/Panel/VBox/VolumeRow/Mute
@onready var _orientation_option: OptionButton = $CanvasLayer/Panel/VBox/OrientationRow/Orientation
@onready var _resolution_option: OptionButton = $CanvasLayer/Panel/VBox/ResolutionRow/Resolution
@onready var _animation_speed_option: OptionButton = $CanvasLayer/Panel/VBox/AnimationSpeedRow/AnimationSpeed
@onready var _auto_advance_toggle: CheckButton = $CanvasLayer/Panel/VBox/AutoAdvanceRow/AutoAdvance
@onready var _auto_advance_speed_slider: HSlider = $CanvasLayer/Panel/VBox/AutoAdvanceSpeedRow/AutoAdvanceSpeed
@onready var _auto_advance_speed_value: Label = $CanvasLayer/Panel/VBox/AutoAdvanceSpeedRow/AutoAdvanceSpeedValue
@onready var _text_speed_slider: HSlider = $CanvasLayer/Panel/VBox/TextSpeedRow/TextSpeed
@onready var _text_speed_value: Label = $CanvasLayer/Panel/VBox/TextSpeedRow/TextSpeedValue

var _language_option: OptionButton
var _difficulty_option: OptionButton
var _display_settings: DisplaySettingsManager
var _game_config: Node

var _is_refreshing_resolution := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process_unhandled_input(true)
	LocaleService.locale_changed.connect(_on_locale_changed)
	
	_game_config = get_tree().root.get_node_or_null("GameConfig")
	if _game_config:
		setup(_game_config)

func _on_locale_changed() -> void:
	if _game_config:
		setup(_game_config)

func setup(game_config: Node) -> void:
	_game_config = game_config
	if game_config == null:
		push_error("GameConfig not provided to setup!")
		return

	# Translate static labels
	var volume_label = get_node_or_null("CanvasLayer/Panel/VBox/VolumeRow/Label")
	if volume_label: volume_label.text = tr("settings.audio.music")
	if _mute_check: _mute_check.text = tr("settings.audio.mute")
	
	var orientation_label = get_node_or_null("CanvasLayer/Panel/VBox/OrientationRow/OrientationLabel")
	if orientation_label: orientation_label.text = tr("settings.display.orientation")
	
	var resolution_label = get_node_or_null("CanvasLayer/Panel/VBox/ResolutionRow/ResolutionLabel")
	if resolution_label: resolution_label.text = tr("settings.display.resolution")
	
	var anim_speed_label = get_node_or_null("CanvasLayer/Panel/VBox/AnimationSpeedRow/AnimationSpeedLabel")
	if anim_speed_label: anim_speed_label.text = tr("settings.gameplay.animation_speed")
	
	var dialogue_header = get_node_or_null("CanvasLayer/Panel/VBox/DialogueHeader")
	if dialogue_header: dialogue_header.text = tr("journal.section.rules") # Or a specific Dialogue key if added
	
	var auto_advance_label = get_node_or_null("CanvasLayer/Panel/VBox/AutoAdvanceRow/AutoAdvanceLabel")
	if auto_advance_label: auto_advance_label.text = tr("settings.dialogue.auto_advance")
	
	var auto_advance_speed_label = get_node_or_null("CanvasLayer/Panel/VBox/AutoAdvanceSpeedRow/AutoAdvanceSpeedLabel")
	if auto_advance_speed_label: auto_advance_speed_label.text = tr("settings.dialogue.auto_advance") # Use same as auto advance for now
	
	var text_speed_label = get_node_or_null("CanvasLayer/Panel/VBox/TextSpeedRow/TextSpeedLabel")
	if text_speed_label: text_speed_label.text = tr("settings.dialogue.text_speed")
	
	var back_button = get_node_or_null("CanvasLayer/Panel/VBox/Back")
	if back_button: back_button.text = tr("hud.action_back")

	var audio_bus_controller = get_tree().root.get_node_or_null("AudioBusController")
	if audio_bus_controller:
		if is_instance_valid(_volume_slider):
			_volume_slider.min_value = -40.0
			_volume_slider.max_value = 0.0
			_volume_slider.step = 0.5
			var saved_db = game_config.get_value("audio/music_db", audio_bus_controller.get_bus_volume_db("Music"))
			_volume_slider.value = float(saved_db)
			audio_bus_controller.set_bus_volume_db("Music", float(saved_db))
			if not _volume_slider.value_changed.is_connected(_on_volume_changed):
				_volume_slider.value_changed.connect(_on_volume_changed)
		
		if is_instance_valid(_mute_check):
			var saved_muted = game_config.get_value("audio/music_muted", audio_bus_controller.is_bus_muted("Music"))
			_mute_check.button_pressed = bool(saved_muted)
			audio_bus_controller.mute_bus("Music", bool(saved_muted))
			if not _mute_check.toggled.is_connected(_on_mute_toggled):
				_mute_check.toggled.connect(_on_mute_toggled)

	var ds = get_tree().root.get_node_or_null("DisplaySettings")
	if ds:
		_display_settings = ds
		if is_instance_valid(_orientation_option):
			_orientation_option.clear()
			_orientation_option.add_item(tr("settings.display.landscape"), DisplayOrientation.Orientation.LANDSCAPE)
			_orientation_option.add_item(tr("settings.display.portrait"), DisplayOrientation.Orientation.PORTRAIT)
			var orientation_index := 0
			var current_orientation := _display_settings.get_current_orientation()
			for i in range(_orientation_option.get_item_count()):
				if _orientation_option.get_item_id(i) == current_orientation:
					orientation_index = i
					break
			_orientation_option.select(orientation_index)
			if not _orientation_option.item_selected.is_connected(_on_orientation_selected):
				_orientation_option.item_selected.connect(_on_orientation_selected)
			_orientation_option.get_parent().show()

		if is_instance_valid(_resolution_option):
			_is_refreshing_resolution = true
			_resolution_option.clear()
			var orientation := _display_settings.get_current_orientation()
			var options := _display_settings.get_standard_resolutions(orientation)
			for i in range(options.size()):
				var res: Vector2i = options[i]
				_resolution_option.add_item("%d x %d" % [res.x, res.y], i)
			_resolution_option.select(_display_settings.get_current_resolution_index())
			_is_refreshing_resolution = false
			if not _resolution_option.item_selected.is_connected(_on_resolution_selected):
				_resolution_option.item_selected.connect(_on_resolution_selected)
			_resolution_option.get_parent().show()

	if is_instance_valid(_animation_speed_option):
		_animation_speed_option.clear()
		_animation_speed_option.add_item(tr("settings.speed.normal"), 0)
		_animation_speed_option.add_item(tr("settings.speed.fast"), 1)
		_animation_speed_option.add_item(tr("settings.speed.skip"), 2)

		var current_speed = game_config.get_value("gameplay/animation_speed", "normal")
		var selected_idx = 0
		match current_speed:
			"fast": selected_idx = 1
			"skip": selected_idx = 2
		_animation_speed_option.select(selected_idx)
		if not _animation_speed_option.item_selected.is_connected(_on_animation_speed_selected):
			_animation_speed_option.item_selected.connect(_on_animation_speed_selected)

	_initialize_dialogue_settings(game_config)
	_setup_language_row(game_config)
	_setup_difficulty_row(game_config)

func _setup_language_row(game_config: Node) -> void:
	var vbox = $CanvasLayer/Panel/VBox
	var res_row = $CanvasLayer/Panel/VBox/ResolutionRow
	
	# Check if row already exists
	var lang_row = vbox.get_node_or_null("LanguageRow")
	if not lang_row:
		lang_row = HBoxContainer.new()
		lang_row.name = "LanguageRow"
		
		var label := Label.new()
		label.name = "LanguageLabel"
		label.text = tr("settings.display.language")
		label.custom_minimum_size = Vector2(120, 0)
		lang_row.add_child(label)
		
		_language_option = OptionButton.new()
		_language_option.name = "Language"
		_language_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lang_row.add_child(_language_option)
		
		# Insert after resolution row
		vbox.add_child(lang_row)
		vbox.move_child(lang_row, res_row.get_index() + 1)
	
	# Update labels and items (for translation)
	var label = lang_row.get_node_or_null("LanguageLabel")
	if label: label.text = tr("settings.display.language")
	
	_language_option.clear()
	_language_option.add_item(tr("settings.language.en"), 0)
	_language_option.set_item_metadata(0, "en")
	_language_option.add_item(tr("settings.language.es"), 1)
	_language_option.set_item_metadata(1, "es")
	_language_option.add_item(tr("settings.language.ja"), 2)
	_language_option.set_item_metadata(2, "ja")
	
	var current_lang = game_config.get_value(GameConstants.Settings.LANGUAGE, "en")
	for i in range(_language_option.item_count):
		if _language_option.get_item_metadata(i) == current_lang:
			_language_option.select(i)
			break
			
	if not _language_option.item_selected.is_connected(_on_language_selected):
		_language_option.item_selected.connect(_on_language_selected)

func _on_language_selected(index: int) -> void:
	var lang_code = _language_option.get_item_metadata(index)
	TranslationServer.set_locale(lang_code)
	_save_dialogue_value(GameConstants.Settings.LANGUAGE, lang_code)

func _unhandled_input(event: InputEvent) -> void:
	if $CanvasLayer.visible and event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _on_back_pressed() -> void:
	back_requested.emit()

func _on_volume_changed(value: float) -> void:
	var audio_bus_controller = get_tree().root.get_node_or_null("AudioBusController")
	if audio_bus_controller != null:
		audio_bus_controller.set_bus_volume_db("Music", value)
	var game_config = get_tree().root.get_node_or_null("GameConfig")
	if game_config != null:
		game_config.set_value("audio/music_db", value)
		game_config.save_config()

func _on_mute_toggled(pressed: bool) -> void:
	var audio_bus_controller = get_tree().root.get_node_or_null("AudioBusController")
	if audio_bus_controller != null:
		audio_bus_controller.mute_bus("Music", pressed)
	var game_config = get_tree().root.get_node_or_null("GameConfig")
	if game_config != null:
		game_config.set_value("audio/music_muted", pressed)
		game_config.save_config()

func _on_orientation_selected(index: int) -> void:
	if _display_settings == null or not is_instance_valid(_orientation_option):
		return
	var orientation_id := _orientation_option.get_item_id(index)
	_display_settings.set_orientation(orientation_id)
	if is_instance_valid(_resolution_option):
		_is_refreshing_resolution = true
		_resolution_option.clear()
		var options := _display_settings.get_standard_resolutions(orientation_id)
		for i in range(options.size()):
			var res: Vector2i = options[i]
			_resolution_option.add_item("%d x %d" % [res.x, res.y], i)
		_resolution_option.select(_display_settings.get_current_resolution_index())
		_is_refreshing_resolution = false
	var game_config = get_tree().root.get_node_or_null("GameConfig")
	if game_config != null:
		var orientation_name := DisplayOrientation.to_name(orientation_id)
		game_config.set_value("display/orientation", orientation_name)
		game_config.set_value("display/resolution", _display_settings.get_current_resolution())
		game_config.save_config()

func _on_resolution_selected(index: int) -> void:
	if _display_settings == null or _is_refreshing_resolution:
		return
	_display_settings.set_resolution_index(index)
	var game_config = get_tree().root.get_node_or_null("GameConfig")
	if game_config != null:
		var orientation_name := DisplayOrientation.to_name(_display_settings.get_current_orientation())
		game_config.set_value("display/orientation", orientation_name)
		game_config.set_value("display/resolution", _display_settings.get_current_resolution())
		game_config.save_config()

func _on_animation_speed_selected(index: int) -> void:
	var speed = "normal"
	match index:
		1: speed = "fast"
		2: speed = "skip"

	if _game_config:
		_game_config.set_value("gameplay/animation_speed", speed)
		_game_config.save_config()

func _initialize_dialogue_settings(game_config: Node) -> void:
	if not is_instance_valid(_auto_advance_toggle):
		return
	var auto_setting := false
	if game_config != null:
		auto_setting = bool(game_config.get_value(GameConstants.Settings.DIALOGUE_AUTO_ADVANCE, false))
	_auto_advance_toggle.button_pressed = auto_setting
	# _apply_auto_advance(auto_setting) # Removed, as it was Dialogic specific
	if not _auto_advance_toggle.toggled.is_connected(_on_auto_advance_toggled):
		_auto_advance_toggle.toggled.connect(_on_auto_advance_toggled)

	if is_instance_valid(_auto_advance_speed_slider):
		_auto_advance_speed_slider.min_value = 0.5
		_auto_advance_speed_slider.max_value = 2.0
		_auto_advance_speed_slider.step = 0.05
		var stored_speed := 1.0
		if game_config != null:
			stored_speed = float(game_config.get_value(GameConstants.Settings.DIALOGUE_AUTO_SPEED, 1.0))
		_auto_advance_speed_slider.value = clamp(stored_speed, _auto_advance_speed_slider.min_value, _auto_advance_speed_slider.max_value)
		_update_auto_advance_speed_label(_auto_advance_speed_slider.value)
		# _apply_auto_advance_speed(_auto_advance_speed_slider.value) # Removed, as it was Dialogic specific
		if not _auto_advance_speed_slider.value_changed.is_connected(_on_auto_advance_speed_changed):
			_auto_advance_speed_slider.value_changed.connect(_on_auto_advance_speed_changed)

	if is_instance_valid(_text_speed_slider):
		_text_speed_slider.min_value = 0.5
		_text_speed_slider.max_value = 2.0
		_text_speed_slider.step = 0.05
		var stored_text_speed := 1.0
		if game_config != null:
			stored_text_speed = float(game_config.get_value(GameConstants.Settings.DIALOGUE_TEXT_SPEED, 1.0))
		_text_speed_slider.value = clamp(stored_text_speed, _text_speed_slider.min_value, _text_speed_slider.max_value)
		_update_text_speed_label(_text_speed_slider.value)
		# _apply_text_speed(_text_speed_slider.value) # Removed, as it was Dialogic specific
		if not _text_speed_slider.value_changed.is_connected(_on_text_speed_changed):
			_text_speed_slider.value_changed.connect(_on_text_speed_changed)

func _on_auto_advance_toggled(pressed: bool) -> void:
	_save_dialogue_value(GameConstants.Settings.DIALOGUE_AUTO_ADVANCE, pressed)

func _on_auto_advance_speed_changed(value: float) -> void:
	if not is_instance_valid(_auto_advance_speed_slider):
		return
	var clamped: float = clamp(value, _auto_advance_speed_slider.min_value, _auto_advance_speed_slider.max_value)
	_update_auto_advance_speed_label(clamped)
	_save_dialogue_value(GameConstants.Settings.DIALOGUE_AUTO_SPEED, clamped)

func _on_text_speed_changed(value: float) -> void:
	if not is_instance_valid(_text_speed_slider):
		return
	var clamped: float = clamp(value, _text_speed_slider.min_value, _text_speed_slider.max_value)
	_update_text_speed_label(clamped)
	_save_dialogue_value(GameConstants.Settings.DIALOGUE_TEXT_SPEED, clamped)

func _update_auto_advance_speed_label(value: float) -> void:
	if is_instance_valid(_auto_advance_speed_value):
		_auto_advance_speed_value.text = "%.1fx" % value

func _update_text_speed_label(value: float) -> void:
	if is_instance_valid(_text_speed_value):
		_text_speed_value.text = "%.1fx" % value

func _setup_difficulty_row(game_config: Node) -> void:
	var vbox = $CanvasLayer/Panel/VBox
	var anim_row = $CanvasLayer/Panel/VBox/AnimationSpeedRow
	
	var diff_row = vbox.get_node_or_null("DifficultyRow")
	if not diff_row:
		diff_row = HBoxContainer.new()
		diff_row.name = "DifficultyRow"
		
		var label := Label.new()
		label.name = "DifficultyLabel"
		label.text = tr("settings.gameplay.difficulty")
		label.custom_minimum_size = Vector2(120, 0)
		diff_row.add_child(label)
		
		_difficulty_option = OptionButton.new()
		_difficulty_option.name = "Difficulty"
		_difficulty_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		diff_row.add_child(_difficulty_option)
		
		# Insert after animation speed row
		vbox.add_child(diff_row)
		vbox.move_child(diff_row, anim_row.get_index() + 1)
	
	var label = diff_row.get_node_or_null("DifficultyLabel")
	if label: label.text = tr("settings.gameplay.difficulty")
	
	_difficulty_option.clear()
	_difficulty_option.add_item(tr("settings.difficulty.easy"), 0)
	_difficulty_option.set_item_metadata(0, GameConstants.Settings.DIFFICULTY_EASY)
	_difficulty_option.add_item(tr("settings.difficulty.normal"), 1)
	_difficulty_option.set_item_metadata(1, GameConstants.Settings.DIFFICULTY_NORMAL)
	_difficulty_option.add_item(tr("settings.difficulty.hard"), 2)
	_difficulty_option.set_item_metadata(2, GameConstants.Settings.DIFFICULTY_HARD)
	
	var current_diff = game_config.get_value(GameConfig.Paths.GAMEPLAY_DIFFICULTY, GameConstants.Settings.DIFFICULTY_NORMAL)
	for i in range(_difficulty_option.item_count):
		if _difficulty_option.get_item_metadata(i) == current_diff:
			_difficulty_option.select(i)
			break
			
	if not _difficulty_option.item_selected.is_connected(_on_difficulty_selected):
		_difficulty_option.item_selected.connect(_on_difficulty_selected)

func _on_difficulty_selected(index: int) -> void:
	var diff_value = _difficulty_option.get_item_metadata(index)
	_save_dialogue_value(GameConfig.Paths.GAMEPLAY_DIFFICULTY, diff_value)
	
	if get_node_or_null("/root/EventBus"):
		EventBus.emit_event("show_feedback_message", "Difficulty set to: " + diff_value.capitalize())

func _save_dialogue_value(path: String, value) -> void:
	if _game_config == null:
		return
	_game_config.set_value(path, value)
	_game_config.save_config()
