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
	
	_game_config = GameConfig
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

	_translate_labels()
	_setup_audio_settings(game_config)
	_setup_display_settings(game_config)
	_setup_animation_settings(game_config)
	_initialize_dialogue_settings(game_config)
	_setup_language_row(game_config)
	_setup_difficulty_row(game_config)

func _translate_labels() -> void:
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
	if dialogue_header: dialogue_header.text = tr("journal.section.rules")
	
	var auto_advance_label = get_node_or_null("CanvasLayer/Panel/VBox/AutoAdvanceRow/AutoAdvanceLabel")
	if auto_advance_label: auto_advance_label.text = tr("settings.dialogue.auto_advance")
	
	var auto_advance_speed_label = get_node_or_null("CanvasLayer/Panel/VBox/AutoAdvanceSpeedRow/AutoAdvanceSpeedLabel")
	if auto_advance_speed_label: auto_advance_speed_label.text = tr("settings.dialogue.auto_advance")
	
	var text_speed_label = get_node_or_null("CanvasLayer/Panel/VBox/TextSpeedRow/TextSpeedLabel")
	if text_speed_label: text_speed_label.text = tr("settings.dialogue.text_speed")
	
	var back_button = get_node_or_null("CanvasLayer/Panel/VBox/Back")
	if back_button: back_button.text = tr("hud.action_back")

func _setup_audio_settings(game_config: Node) -> void:
	var audio_bus_controller = AudioBusController
	if not audio_bus_controller:
		return
		
	var vbox = $CanvasLayer/Panel/VBox
	var music_row = $CanvasLayer/Panel/VBox/VolumeRow
	
	# Clear the existing static music row connections if any, or just hide it
	# Actually, we'll replace the whole audio section with dynamic rows for consistency
	music_row.hide()
	
	# Add additional audio rows dynamically, starting with Master
	_create_audio_row(vbox, music_row, "Master", "settings.audio.master", GameConfig.Paths.AUDIO_MASTER, GameConfig.Paths.AUDIO_MASTER_MUTED)
	_create_audio_row(vbox, music_row, "Music", "settings.audio.music", GameConfig.Paths.AUDIO_MUSIC, GameConfig.Paths.AUDIO_MUSIC_MUTED)
	_create_audio_row(vbox, music_row, "SFX", "settings.audio.sfx", GameConfig.Paths.AUDIO_SFX, GameConfig.Paths.AUDIO_SFX_MUTED)
	_create_audio_row(vbox, music_row, "UI", "settings.audio.ui", GameConfig.Paths.AUDIO_UI, GameConfig.Paths.AUDIO_UI_MUTED)
	_create_audio_row(vbox, music_row, "Environment", "settings.audio.environment", GameConfig.Paths.AUDIO_ENVIRONMENT, GameConfig.Paths.AUDIO_ENVIRONMENT_MUTED)
	_create_audio_row(vbox, music_row, "Narrative", "settings.audio.narrative", GameConfig.Paths.AUDIO_NARRATIVE, GameConfig.Paths.AUDIO_NARRATIVE_MUTED)

func _create_audio_row(parent: Node, anchor: Node, bus_name: String, label_key: String, config_path: String, mute_path: String) -> void:
	var audio_bus_controller = AudioBusController
	if not audio_bus_controller: return
	
	var row_name = bus_name + "Row"
	var row = parent.get_node_or_null(row_name)
	if not row:
		row = HBoxContainer.new()
		row.name = row_name
		parent.add_child(row)
		parent.move_child(row, anchor.get_index() + 1)
		
		var label := Label.new()
		label.name = "Label"
		label.text = tr(label_key)
		label.custom_minimum_size = Vector2(150, 0) # Fixed width for all labels
		row.add_child(label)
		
		var slider := HSlider.new()
		slider.name = "Volume"
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.min_value = -40.0
		slider.max_value = 0.0
		slider.step = 0.5
		slider.custom_minimum_size = Vector2(200, 0) # Ensure a minimum width for sliders
		row.add_child(slider)
		
		var mute := CheckButton.new()
		mute.name = "Mute"
		mute.text = tr("settings.audio.mute")
		mute.custom_minimum_size = Vector2(100, 0) # Fixed width for mute buttons
		row.add_child(mute)
		
		# Initial Values
		var saved_db = _game_config.get_value(config_path, audio_bus_controller.get_bus_volume_db(bus_name))
		slider.value = float(saved_db)
		audio_bus_controller.set_bus_volume_db(bus_name, float(saved_db))
		
		var saved_muted = _game_config.get_value(mute_path, audio_bus_controller.is_bus_muted(bus_name))
		mute.button_pressed = bool(saved_muted)
		audio_bus_controller.mute_bus(bus_name, bool(saved_muted))
		
		# Connections
		slider.value_changed.connect(func(v):
			audio_bus_controller.set_bus_volume_db(bus_name, v)
			_game_config.set_value(config_path, v)
			_game_config.save_config()
		)
		mute.toggled.connect(func(p):
			audio_bus_controller.mute_bus(bus_name, p)
			_game_config.set_value(mute_path, p)
			_game_config.save_config()
		)
	else:
		# Update translations
		var label = row.get_node_or_null("Label")
		if label: label.text = tr(label_key)
		var mute = row.get_node_or_null("Mute")
		if mute: mute.text = tr("settings.audio.mute")

func _setup_display_settings(_game_config_node: Node) -> void:
	var ds = DisplaySettings
	if not ds:
		return
		
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

func _setup_animation_settings(game_config: Node) -> void:
	if not is_instance_valid(_animation_speed_option):
		return
		
	_animation_speed_option.clear()
	_animation_speed_option.add_item(tr("settings.speed.normal"), 0)
	_animation_speed_option.add_item(tr("settings.speed.fast"), 1)
	_animation_speed_option.add_item(tr("settings.speed.skip"), 2)

	var current_speed = game_config.get_value(GameConfig.Paths.GAMEPLAY_ANIMATION_SPEED, GameConstants.Settings.ANIMATION_SPEED_NORMAL)
	var selected_idx = 0
	match current_speed:
		GameConstants.Settings.ANIMATION_SPEED_FAST: selected_idx = 1
		GameConstants.Settings.ANIMATION_SPEED_SKIP: selected_idx = 2
	_animation_speed_option.select(selected_idx)
	if not _animation_speed_option.item_selected.is_connected(_on_animation_speed_selected):
		_animation_speed_option.item_selected.connect(_on_animation_speed_selected)

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
	var audio_bus_controller = AudioBusController
	if audio_bus_controller != null:
		audio_bus_controller.set_bus_volume_db("Music", value)
	var game_config = GameConfig
	if game_config != null:
		game_config.set_value("audio/music_db", value)
		game_config.save_config()

func _on_mute_toggled(pressed: bool) -> void:
	var audio_bus_controller = AudioBusController
	if audio_bus_controller != null:
		audio_bus_controller.mute_bus("Music", pressed)
	var game_config = GameConfig
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
	var game_config = GameConfig
	if game_config != null:
		var orientation_name := DisplayOrientation.to_name(orientation_id)
		game_config.set_value("display/orientation", orientation_name)
		game_config.set_value("display/resolution", _display_settings.get_current_resolution())
		game_config.save_config()

func _on_resolution_selected(index: int) -> void:
	if _display_settings == null or _is_refreshing_resolution:
		return
	_display_settings.set_resolution_index(index)
	var game_config = GameConfig
	if game_config != null:
		var orientation_name := DisplayOrientation.to_name(_display_settings.get_current_orientation())
		game_config.set_value("display/orientation", orientation_name)
		game_config.set_value("display/resolution", _display_settings.get_current_resolution())
		game_config.save_config()

func _on_animation_speed_selected(index: int) -> void:
	var speed = GameConstants.Settings.ANIMATION_SPEED_NORMAL
	match index:
		1: speed = GameConstants.Settings.ANIMATION_SPEED_FAST
		2: speed = GameConstants.Settings.ANIMATION_SPEED_SKIP

	if _game_config:
		_game_config.set_value(GameConfig.Paths.GAMEPLAY_ANIMATION_SPEED, speed)
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
	
	if is_instance_valid(EventBus):
		EventBus.show_feedback_message.emit("Difficulty set to: " + diff_value.capitalize())

func _save_dialogue_value(path: String, value) -> void:
	if _game_config == null:
		return
	_game_config.set_value(path, value)
	_game_config.save_config()
