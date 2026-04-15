extends Control

signal back_requested

@onready var _tab_container: TabContainer = $CanvasLayer/Panel/VBox/TabContainer
@onready var _audio_vbox: VBoxContainer = $CanvasLayer/Panel/VBox/TabContainer/Audio/AudioVBox
@onready var _graphics_vbox: VBoxContainer = $CanvasLayer/Panel/VBox/TabContainer/Graphics/GraphicsVBox
@onready var _language_flow_vbox: VBoxContainer = $CanvasLayer/Panel/VBox/TabContainer/LanguageFlow/LanguageFlowVBox
@onready var _accessibility_vbox: VBoxContainer = $CanvasLayer/Panel/VBox/TabContainer/Accessibility/AccessibilityVBox
@onready var _audio_bus_controller = get_node_or_null("/root/AudioBusController")


@onready var _mute_check: CheckButton = $CanvasLayer/Panel/VBox/TabContainer/Audio/AudioVBox/VolumeRow/Mute
@onready var _orientation_option: OptionButton = $CanvasLayer/Panel/VBox/TabContainer/Graphics/GraphicsVBox/OrientationRow/Orientation
@onready var _resolution_option: OptionButton = $CanvasLayer/Panel/VBox/TabContainer/Graphics/GraphicsVBox/ResolutionRow/Resolution
@onready var _animation_speed_option: OptionButton = $CanvasLayer/Panel/VBox/TabContainer/Graphics/GraphicsVBox/AnimationSpeedRow/AnimationSpeed
@onready var _auto_advance_toggle: CheckButton = $CanvasLayer/Panel/VBox/TabContainer/LanguageFlow/LanguageFlowVBox/AutoAdvanceRow/AutoAdvance
@onready var _auto_advance_speed_slider: HSlider = $CanvasLayer/Panel/VBox/TabContainer/LanguageFlow/LanguageFlowVBox/AutoAdvanceSpeedRow/AutoAdvanceSpeed
@onready var _auto_advance_speed_value: Label = $CanvasLayer/Panel/VBox/TabContainer/LanguageFlow/LanguageFlowVBox/AutoAdvanceSpeedRow/AutoAdvanceSpeedValue
@onready var _text_speed_slider: HSlider = $CanvasLayer/Panel/VBox/TabContainer/LanguageFlow/LanguageFlowVBox/TextSpeedRow/TextSpeed
@onready var _text_speed_value: Label = $CanvasLayer/Panel/VBox/TabContainer/LanguageFlow/LanguageFlowVBox/TextSpeedRow/TextSpeedValue

@onready var _layouts_label: RichTextLabel = $CanvasLayer/Panel/VBox/TabContainer/Controls/ControlsVBox/Scroll/Layouts

var _language_option: OptionButton
var _difficulty_option: OptionButton
var _display_settings: DisplaySettingsManager
var _game_config: Node

var _is_refreshing_resolution := false

func _ready() -> void:
	GameLogger.debug(GameLogger.Category.UI, "settings_menu _ready. _audio_bus_controller: ", _audio_bus_controller)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process_unhandled_input(true)
	LocaleService.locale_changed.connect(_on_locale_changed)
	_tab_container.tab_changed.connect(_on_tab_changed)
	visibility_changed.connect(_on_visibility_changed)

	_translate_labels()
	_apply_tooltips()

	_game_config = GameConfig
	if _game_config:
		setup(_game_config)


func _on_locale_changed() -> void:
	if _game_config:
		setup(_game_config)

func setup(game_config: Node) -> void:
	GameLogger.debug(GameLogger.Category.UI, "settings_menu setup. _audio_bus_controller: ", _audio_bus_controller)
	_game_config = game_config
	if game_config == null:
		GameLogger.error(GameLogger.Category.UI, "GameConfig not provided to setup!")
		return


	_translate_labels()
	_setup_audio_settings(game_config)
	_setup_display_settings(game_config)
	_setup_animation_settings(game_config)
	_initialize_dialogue_settings(game_config)
	_setup_language_row(game_config)
	_setup_difficulty_row(game_config)
	_setup_accessibility_tab(game_config)
	_apply_tooltips()
	_refresh_layouts()
	
	# Apply focus styles to all controls in the menu
	_apply_focus_styles_to_tree(self)
	var back_button = get_node_or_null("CanvasLayer/Panel/VBox/Back")
	if back_button:
		GUINavigationHelper.apply_focus_style(back_button)

func _apply_focus_styles_to_tree(node: Node) -> void:
	if node is Control and node.focus_mode != Control.FOCUS_NONE:
		if not node is Container and not node is Label and not node is ScrollContainer:
			GUINavigationHelper.apply_focus_style(node)
	
	for child in node.get_children():
		_apply_focus_styles_to_tree(child)

func _translate_labels() -> void:
	if _tab_container:
		_tab_container.set_tab_title(0, tr("settings.tab.audio"))
		_tab_container.set_tab_title(1, tr("settings.tab.graphics"))
		_tab_container.set_tab_title(2, tr("settings.tab.language_flow"))
		_tab_container.set_tab_title(3, tr("settings.tab.accessibility"))
		_tab_container.set_tab_title(4, tr("settings.tab.controls"))

	var volume_label = get_node_or_null("CanvasLayer/Panel/VBox/TabContainer/Audio/AudioVBox/VolumeRow/Label")
	if volume_label: volume_label.text = tr("settings.audio.music")
	if _mute_check: _mute_check.text = tr("settings.audio.mute")

	var orientation_label = get_node_or_null("CanvasLayer/Panel/VBox/TabContainer/Graphics/GraphicsVBox/OrientationRow/OrientationLabel")
	if orientation_label: orientation_label.text = tr("settings.display.orientation")

	var resolution_label = get_node_or_null("CanvasLayer/Panel/VBox/TabContainer/Graphics/GraphicsVBox/ResolutionRow/ResolutionLabel")
	if resolution_label: resolution_label.text = tr("settings.display.resolution")

	var anim_speed_label = get_node_or_null("CanvasLayer/Panel/VBox/TabContainer/Graphics/GraphicsVBox/AnimationSpeedRow/AnimationSpeedLabel")
	if anim_speed_label: anim_speed_label.text = tr("settings.gameplay.animation_speed")

	var dialogue_header = get_node_or_null("CanvasLayer/Panel/VBox/TabContainer/LanguageFlow/LanguageFlowVBox/DialogueHeader")
	if dialogue_header: dialogue_header.text = tr("journal.section.rules")

	var auto_advance_label = get_node_or_null("CanvasLayer/Panel/VBox/TabContainer/LanguageFlow/LanguageFlowVBox/AutoAdvanceRow/AutoAdvanceLabel")
	if auto_advance_label: auto_advance_label.text = tr("settings.dialogue.auto_advance")

	var auto_advance_speed_label = get_node_or_null("CanvasLayer/Panel/VBox/TabContainer/LanguageFlow/LanguageFlowVBox/AutoAdvanceSpeedRow/AutoAdvanceSpeedLabel")
	if auto_advance_speed_label: auto_advance_speed_label.text = tr("settings.dialogue.auto_advance_speed")

	var text_speed_label = get_node_or_null("CanvasLayer/Panel/VBox/TabContainer/LanguageFlow/LanguageFlowVBox/TextSpeedRow/TextSpeedLabel")
	if text_speed_label: text_speed_label.text = tr("settings.dialogue.text_speed")

	var back_button = get_node_or_null("CanvasLayer/Panel/VBox/Back")
	if back_button: back_button.text = tr("hud.action_back")

	var reset_button = get_node_or_null("CanvasLayer/Panel/VBox/TabContainer/Controls/ControlsVBox/Reset")
	if reset_button: reset_button.text = tr("menu.controls.reset")

func _setup_audio_settings(_config_node: Node) -> void:
	var audio_bus_controller = AudioBusController
	if not audio_bus_controller:
		return

	var vbox = _audio_vbox
	var music_row = vbox.get_node_or_null("VolumeRow")

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
	if not _audio_bus_controller:
		return

	var row_name = bus_name + "Row"
	var row = parent.get_node_or_null(row_name)
	if not row:
		var initial_db = float(_game_config.get_value(config_path, _audio_bus_controller.get_bus_volume_db(bus_name)))
		var initial_muted = bool(_game_config.get_value(mute_path, _audio_bus_controller.is_bus_muted(bus_name)))

		# Sync backend initial state
		_audio_bus_controller.set_bus_volume_db(bus_name, initial_db)
		_audio_bus_controller.mute_bus(bus_name, initial_muted)

		row = SettingsUIFactory.create_audio_row(
			row_name,
			tr(label_key),
			initial_db,
			initial_muted,
			_on_audio_volume_changed.bind(bus_name, config_path),
			_on_audio_mute_toggled.bind(bus_name, mute_path)
		)
		parent.add_child(row)
		parent.move_child(row, anchor.get_index() + 1)
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
	var selected_idx: int = 0
	match current_speed:
		GameConstants.Settings.ANIMATION_SPEED_FAST: selected_idx = 1
		GameConstants.Settings.ANIMATION_SPEED_SKIP: selected_idx = 2
	_animation_speed_option.select(selected_idx)
	if not _animation_speed_option.item_selected.is_connected(_on_animation_speed_selected):
		_animation_speed_option.item_selected.connect(_on_animation_speed_selected)

	_setup_batch_animations_row(game_config)

func _setup_batch_animations_row(game_config: Node) -> void:
	var vbox = _graphics_vbox
	var anim_row = _graphics_vbox.get_node_or_null("AnimationSpeedRow")

	var batch_row = vbox.get_node_or_null("BatchAnimationsRow")
	if not batch_row:
		var initial_val = bool(game_config.get_value(GameConfig.Paths.GAMEPLAY_BATCH_ANIMATIONS_ENABLED, false))
		batch_row = SettingsUIFactory.create_toggle_row(
			"BatchAnimationsRow",
			tr("settings.gameplay.batch_animations"),
			initial_val,
			func(pressed: bool): game_config.set_value(GameConfig.Paths.GAMEPLAY_BATCH_ANIMATIONS_ENABLED, pressed)
		)
		vbox.add_child(batch_row)
		vbox.move_child(batch_row, anim_row.get_index() + 1)
	else:
		var label = batch_row.get_node_or_null("Label")
		if label: label.text = tr("settings.gameplay.batch_animations")

func _setup_language_row(game_config: Node) -> void:
	var vbox = _language_flow_vbox
	var lang_row = vbox.get_node_or_null("LanguageRow")

	var languages = ["en", "es", "ja"]
	var lang_items = []
	var selected_idx = 0
	var current_lang = game_config.get_value(GameConfig.Paths.DISPLAY_LANGUAGE, "en")

	for i in range(languages.size()):
		var code = languages[i]
		var lang_name = tr("settings.language." + code)
		lang_items.append({"text": lang_name, "metadata": code})
		if code == current_lang: selected_idx = i

	if not lang_row:
		lang_row = SettingsUIFactory.create_option_row(
			"LanguageRow",
			tr("settings.display.language"),
			lang_items,
			selected_idx,
			_on_language_selected,
			120.0
		)
		vbox.add_child(lang_row)
		vbox.move_child(lang_row, 0)
		_language_option = lang_row.get_node("Option")
	else:
		_language_option = lang_row.get_node("Option")
		var label = lang_row.get_node("Label")
		if label: label.text = tr("settings.display.language")
		
		# Update dropdown text
		for i in range(_language_option.get_item_count()):
			var code = _language_option.get_item_metadata(i)
			_language_option.set_item_text(i, tr("settings.language." + code))

func _on_language_selected(index: int) -> void:
	var lang_code = _language_option.get_item_metadata(index)
	# Save first so that setup() called by locale_changed reads the new value
	_save_dialogue_value(GameConfig.Paths.DISPLAY_LANGUAGE, lang_code)
	TranslationServer.set_locale(lang_code)

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(InputActions.SELECTION_CYCLE_NEXT):
		_tab_container.current_tab = (_tab_container.current_tab + 1) % _tab_container.get_tab_count()
		_grab_initial_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(InputActions.SELECTION_CYCLE_PREV):
		_tab_container.current_tab = (_tab_container.current_tab - 1 + _tab_container.get_tab_count()) % _tab_container.get_tab_count()
		_grab_initial_focus()
		get_viewport().set_input_as_handled()

func _on_back_pressed() -> void:
	back_requested.emit()

func _on_volume_changed(value: float) -> void:
	var audio_bus_controller = AudioBusController
	if audio_bus_controller != null:
		audio_bus_controller.set_bus_volume_db("Music", value)
	var game_config = GameConfig
	if game_config != null:
		game_config.set_value(GameConfig.Paths.AUDIO_MUSIC, value)
		game_config.save_config()

func _on_mute_toggled(pressed: bool) -> void:
	var audio_bus_controller = AudioBusController
	if audio_bus_controller != null:
		audio_bus_controller.mute_bus("Music", pressed)
	var game_config = GameConfig
	if game_config != null:
		game_config.set_value(GameConfig.Paths.AUDIO_MUSIC_MUTED, pressed)
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
		game_config.set_value(GameConfig.Paths.DISPLAY_ORIENTATION, orientation_name)
		game_config.set_value(GameConfig.Paths.DISPLAY_RESOLUTION, _display_settings.get_current_resolution())
		game_config.save_config()

func _on_resolution_selected(index: int) -> void:
	if _display_settings == null or _is_refreshing_resolution:
		return
	_display_settings.set_resolution_index(index)
	var game_config = GameConfig
	if game_config != null:
		var orientation_name := DisplayOrientation.to_name(_display_settings.get_current_orientation())
		game_config.set_value(GameConfig.Paths.DISPLAY_ORIENTATION, orientation_name)
		game_config.set_value(GameConfig.Paths.DISPLAY_RESOLUTION, _display_settings.get_current_resolution())
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
	var vbox = _language_flow_vbox
	var lang_row = vbox.get_node_or_null("LanguageRow")
	var diff_row = vbox.get_node_or_null("DifficultyRow")

	var diff_items = [
		{"text": tr("settings.difficulty.easy"), "metadata": GameConstants.Settings.DIFFICULTY_EASY},
		{"text": tr("settings.difficulty.normal"), "metadata": GameConstants.Settings.DIFFICULTY_NORMAL},
		{"text": tr("settings.difficulty.hard"), "metadata": GameConstants.Settings.DIFFICULTY_HARD}
	]

	var current_diff = game_config.get_value(GameConfig.Paths.GAMEPLAY_DIFFICULTY, GameConstants.Settings.DIFFICULTY_NORMAL)
	var selected_idx = 1
	for i in range(diff_items.size()):
		if diff_items[i].metadata == current_diff: selected_idx = i

	if not diff_row:
		diff_row = SettingsUIFactory.create_option_row(
			"DifficultyRow",
			tr("settings.gameplay.difficulty"),
			diff_items,
			selected_idx,
			_on_difficulty_selected,
			120.0
		)
		vbox.add_child(diff_row)
		var insert_idx = lang_row.get_index() + 1 if lang_row else 0
		vbox.move_child(diff_row, insert_idx)
		_difficulty_option = diff_row.get_node("Option")
	else:
		_difficulty_option = diff_row.get_node("Option")
		var label = diff_row.get_node("Label")
		if label: label.text = tr("settings.gameplay.difficulty")
		
		# Update dropdown text
		for i in range(_difficulty_option.get_item_count()):
			var meta_val = _difficulty_option.get_item_metadata(i)
			_difficulty_option.set_item_text(i, tr("settings.difficulty." + meta_val.replace("settings.difficulty.", "")))

func _on_difficulty_selected(index: int) -> void:
	var diff_value = _difficulty_option.get_item_metadata(index)
	_save_dialogue_value(GameConfig.Paths.GAMEPLAY_DIFFICULTY, diff_value)

	if is_instance_valid(EventBus):
		EventBus.show_feedback_message.emit(tr("settings.difficulty.feedback").format({"difficulty": tr("settings.difficulty." + diff_value)}))

func _on_audio_volume_changed(value: float, bus_name: String, config_path: String) -> void:
	print_rich("[DEBUG] _on_audio_volume_changed: ", value, " bus: ", bus_name)
	if _audio_bus_controller:
		_audio_bus_controller.set_bus_volume_db(bus_name, value)
	if _game_config:
		_game_config.set_value(config_path, value)

func _on_audio_mute_toggled(pressed: bool, bus_name: String, mute_path: String) -> void:
	if _audio_bus_controller:
		_audio_bus_controller.mute_bus(bus_name, pressed)
	if _game_config:
		_game_config.set_value(mute_path, pressed)

func _save_dialogue_value(path: String, value) -> void:
	if _game_config == null:
		return
	_game_config.set_value(path, value)
	_game_config.save_config()

func _refresh_layouts() -> void:
	var control_settings = ControlSettings
	if control_settings == null:
		GameLogger.error(GameLogger.Category.UI, "ControlSettings autoload not found!")
		return

	var lines := []

	var groups = [
		{"name": tr("menu.controls.movement"), "data": InputActions.MOVEMENT_DEFAULTS},
		{"name": tr("menu.controls.interaction"), "data": InputActions.INTERACTION_DEFAULTS},
		{"name": tr("menu.controls.camera"), "data": InputActions.CAMERA_DEFAULTS},
		{"name": tr("menu.controls.selection"), "data": InputActions.SELECTION_DEFAULTS},
		{"name": tr("menu.controls.pause"), "data": InputActions.PAUSE_DEFAULTS},
	]

	for group in groups:
		lines.append("[b]%s[/b]" % group.name)
		for entry in group.data:
			var action: String = entry["action"]
			var events = InputMap.action_get_events(action)
			var keys := []
			for event in events:
				keys.append(_get_event_label(event))

			if keys.is_empty():
				keys.append(tr("menu.controls.unbound"))

			var action_label := tr("settings.controls.action." + action)
			if action_label == "settings.controls.action." + action:
				action_label = action.replace("_", " ").capitalize()
			lines.append("  %s: %s" % [action_label, ", ".join(keys)])
		lines.append("")

	if _layouts_label:
		_layouts_label.text = "\n".join(lines)
		# Add tab switch hint for controller
		var hint = tr("menu.settings.tab_switch_hint")
		if hint != "menu.settings.tab_switch_hint":
			_layouts_label.text += "\n\n[center][color=gray]" + hint + "[/color][/center]"

func reset_and_apply_defaults() -> void:
	var control_settings = ControlSettings
	if control_settings == null:
		GameLogger.error(GameLogger.Category.UI, "ControlSettings autoload not found!")
		return
	var input_mapper = InputMapper
	if input_mapper == null:
		GameLogger.error(GameLogger.Category.UI, "InputMapper autoload not found!")
		return
	control_settings.reset_inputs_to_defaults()
	# Reapply input maps so changes take effect
	input_mapper.apply_configs(control_settings.move_actions)
	input_mapper.apply_configs(control_settings.camera_actions)
	input_mapper.apply_configs(control_settings.selection_actions)
	input_mapper.apply_configs(control_settings.pause_actions)
	_refresh_layouts()

func _on_reset_pressed() -> void:
	reset_and_apply_defaults()

func _get_event_label(event: InputEvent) -> String:
	if event is InputEventKey:
		var keycode = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
		return OS.get_keycode_string(keycode)
	elif event is InputEventMouseButton:
		var btn_name: String = "Mouse " + str(event.button_index)
		if event.button_index == MOUSE_BUTTON_LEFT: btn_name = "Left Click"
		elif event.button_index == MOUSE_BUTTON_RIGHT: btn_name = "Right Click"
		elif event.button_index == MOUSE_BUTTON_MIDDLE: btn_name = "Middle Click"
		return btn_name
	elif event is InputEventJoypadButton:
		return "JoyBtn " + str(event.button_index)
	elif event is InputEventJoypadMotion:
		var sign_str: String = "+" if event.axis_value > 0 else "-"
		return "JoyAxis " + str(event.axis) + sign_str
	return "Unknown Input"


func _on_tab_changed(_tab_idx: int) -> void:
	_grab_initial_focus()

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		_grab_initial_focus()

func _grab_initial_focus() -> void:
	if not _tab_container:
		return
	var current_tab = _tab_container.get_current_tab_control()
	if not current_tab:
		return

	# Find the first focusable child in the current tab's hierarchy
	var first_focusable = GUINavigationHelper.find_first_focusable(current_tab)
	if first_focusable:
		first_focusable.grab_focus()

func _apply_tooltips() -> void:
	# Audio settings
	if is_instance_valid(_audio_vbox):
		for row in _audio_vbox.get_children():
			if not row is HBoxContainer: continue
			var slider = row.get_node_or_null("Volume")
			var mute_btn = row.get_node_or_null("Mute")
			var bus_name = row.name.replace("Row", "")
			if slider:
				slider.tooltip_text = tr("settings.audio." + bus_name.to_lower() + ".tooltip")
			if mute_btn:
				mute_btn.tooltip_text = tr("settings.audio.mute.tooltip")

	# Graphics settings
	if is_instance_valid(_orientation_option):
		_orientation_option.tooltip_text = tr("settings.display.orientation.tooltip")
	if is_instance_valid(_resolution_option):
		_resolution_option.tooltip_text = tr("settings.display.resolution.tooltip")
	if is_instance_valid(_animation_speed_option):
		_animation_speed_option.tooltip_text = tr("settings.gameplay.animation_speed.tooltip")

	# Language & Flow
	if is_instance_valid(_auto_advance_toggle):
		_auto_advance_toggle.tooltip_text = tr("settings.dialogue.auto_advance.tooltip")
	if is_instance_valid(_auto_advance_speed_slider):
		_auto_advance_speed_slider.tooltip_text = tr("settings.dialogue.auto_advance_speed.tooltip")
	if is_instance_valid(_text_speed_slider):
		_text_speed_slider.tooltip_text = tr("settings.dialogue.text_speed.tooltip")

	# Difficulty settings
	if is_instance_valid(_difficulty_option):
		_difficulty_option.tooltip_text = tr("settings.gameplay.difficulty.tooltip")

	# Controls
	var reset_button = get_node_or_null("CanvasLayer/Panel/VBox/TabContainer/Controls/ControlsVBox/Reset")
	if is_instance_valid(reset_button):
		reset_button.tooltip_text = tr("menu.controls.reset.tooltip")

	# Back button
	var back_button = get_node_or_null("CanvasLayer/Panel/VBox/Back")
	if is_instance_valid(back_button):
		back_button.tooltip_text = tr("menu.back.tooltip")

func _setup_accessibility_tab(game_config: Node) -> void:
	var vbox = _accessibility_vbox
	if not vbox: return

	# Clear existing dynamic rows if any
	for child in vbox.get_children():
		child.queue_free()

	# High Contrast Toggle
	var on_high_contrast = func(pressed: bool):
		game_config.set_value(GameConfig.Paths.ACCESSIBILITY_HIGH_CONTRAST, pressed)
		game_config.save_config()
		var manager = get_node_or_null("/root/AccessibilityManager")
		if manager:
			manager.high_contrast_changed.emit(pressed)

	vbox.add_child(SettingsUIFactory.create_toggle_row(
		"HighContrastRow",
		tr("settings.accessibility.high_contrast"),
		bool(game_config.get_value(GameConfig.Paths.ACCESSIBILITY_HIGH_CONTRAST, false)),
		on_high_contrast,
		tr("settings.accessibility.high_contrast.tooltip")
	))

	# Reduced Motion Toggle
	var on_reduced_motion = func(pressed: bool):
		game_config.set_value(GameConfig.Paths.ACCESSIBILITY_REDUCED_MOTION, pressed)
		game_config.save_config()
		var manager = get_node_or_null("/root/AccessibilityManager")
		if manager:
			manager.reduced_motion_changed.emit(pressed)

	vbox.add_child(SettingsUIFactory.create_toggle_row(
		"ReducedMotionRow",
		tr("settings.accessibility.reduced_motion"),
		bool(game_config.get_value(GameConfig.Paths.ACCESSIBILITY_REDUCED_MOTION, false)),
		on_reduced_motion,
		tr("settings.accessibility.reduced_motion.tooltip")
	))

	# UI Scale Slider
	var initial_scale = float(game_config.get_value(GameConfig.Paths.ACCESSIBILITY_UI_SCALE, 1.0))
	var on_ui_scale = func(val: float):
		game_config.set_value(GameConfig.Paths.ACCESSIBILITY_UI_SCALE, val)
		game_config.save_config()
		var manager = get_node_or_null("/root/AccessibilityManager")
		if manager:
			manager.ui_scale_changed.emit(val)

	var scale_row = SettingsUIFactory.create_slider_row(
		"UIScaleRow",
		tr("settings.accessibility.ui_scale"),
		0.5, 2.0, 0.1,
		initial_scale,
		on_ui_scale,
		tr("settings.accessibility.ui_scale.tooltip")
	)
	vbox.add_child(scale_row)
