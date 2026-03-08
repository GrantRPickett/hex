class_name HUDComponentFactory
extends RefCounted

# Scenes are loaded dynamically in _populate_components to avoid circular dependencies and parsing issues
const LocalizationStrings := preload("res://Resources/Localization/localization_strings.gd")


class Components:
	var round_info: RoundInfoPanel
	var locations_list: LocationsListPanel
	var unit_details: UnitDetailsPanel
	var combat_preview: CombatPreviewPanel
	var location_details: LocationDetailsPanel
	var terrain_details: TerrainDetailsPanel
	var tasks_list: Control
	var task_details: Control
	var actions_panel: ActionsPanel
	var loot_details: LootDetailsPanel
	var weather_panel: WeatherPanel
	var morale_panel: MoralePanel
	var auto_battle_button: Button
	var pause_button: Button
	var debug_clear_journal_button: Button

	func setup(state: GameState, config: GameSessionBuilder.Config) -> void:
		var panels = [
			round_info,
			locations_list,
			unit_details,
			combat_preview,
			location_details,
			terrain_details,
			weather_panel,
			morale_panel
		]

		for panel in panels:
			if panel == null or not panel.has_method("setup"):
				continue
			# Individual panels' setup methods now expect state and config
			panel.callv("setup", [state, config])


	func _get_setup_method_info(panel) -> Dictionary:
		for method_dict in panel.get_method_list():
			if method_dict.get("name") == "setup":
				return method_dict
		return {}
static func create_components(parent: Node) -> Components:
	var components = Components.new()
	var margin_container := _create_margin_container(parent)
	var containers := _create_layout_containers(margin_container)
	_populate_components(components, containers)
	return components

static func _create_margin_container(parent: Node) -> MarginContainer:
	var margin_container := MarginContainer.new()
	margin_container.name = "HUDMarginContainer"
	margin_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin_container.add_theme_constant_override("margin_left", 20)
	margin_container.add_theme_constant_override("margin_top", 20)
	margin_container.add_theme_constant_override("margin_right", 20)
	margin_container.add_theme_constant_override("margin_bottom", 20)
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layout_manager = HUDLayoutManager.new()
	layout_manager.name = "LayoutManager"
	margin_container.add_child(layout_manager)
	parent.add_child(margin_container)
	return margin_container

static func _create_layout_containers(root: MarginContainer) -> Dictionary:
	var containers: Dictionary = {}
	var vbox_specs = [
		{"key": "top_left", "name": "TopLeftContainer", "preset": Control.PRESET_TOP_LEFT, "h_flag": Control.SIZE_SHRINK_BEGIN, "v_flag": Control.SIZE_SHRINK_BEGIN, "alignment": BoxContainer.ALIGNMENT_BEGIN},
		{"key": "top_right", "name": "TopRightContainer", "preset": Control.PRESET_TOP_RIGHT, "h_flag": Control.SIZE_SHRINK_END, "v_flag": Control.SIZE_SHRINK_BEGIN, "alignment": BoxContainer.ALIGNMENT_BEGIN},
		{"key": "bottom_left", "name": "BottomLeftContainer", "preset": Control.PRESET_BOTTOM_LEFT, "h_flag": Control.SIZE_SHRINK_BEGIN, "v_flag": Control.SIZE_SHRINK_END, "alignment": BoxContainer.ALIGNMENT_END},
		{"key": "bottom_right", "name": "BottomRightContainer", "preset": Control.PRESET_BOTTOM_RIGHT, "h_flag": Control.SIZE_SHRINK_END, "v_flag": Control.SIZE_SHRINK_END, "alignment": BoxContainer.ALIGNMENT_END},
		{"key": "center_left", "name": "CenterLeftContainer", "preset": Control.PRESET_CENTER_LEFT, "h_flag": Control.SIZE_SHRINK_BEGIN, "v_flag": Control.SIZE_SHRINK_CENTER, "alignment": BoxContainer.ALIGNMENT_CENTER, "separator": true},
		{"key": "center_right", "name": "CenterRightContainer", "preset": Control.PRESET_CENTER_RIGHT, "h_flag": Control.SIZE_SHRINK_END, "v_flag": Control.SIZE_SHRINK_CENTER, "alignment": BoxContainer.ALIGNMENT_CENTER, "separator": true}
	]
	for spec in vbox_specs:
		var box := VBoxContainer.new()
		_config_box_container(box, spec)
		root.add_child(box)
		containers[spec["key"]] = box

	var hbox_specs = [
		{"key": "top_center", "name": "TopCenterContainer", "preset": Control.PRESET_CENTER_TOP, "h_flag": Control.SIZE_SHRINK_CENTER, "v_flag": Control.SIZE_SHRINK_BEGIN, "alignment": BoxContainer.ALIGNMENT_CENTER, "separator": true},
		{"key": "bottom_center", "name": "BottomCenterContainer", "preset": Control.PRESET_CENTER_BOTTOM, "h_flag": Control.SIZE_SHRINK_CENTER, "v_flag": Control.SIZE_SHRINK_END, "alignment": BoxContainer.ALIGNMENT_CENTER, "separator": true}
	]
	for spec in hbox_specs:
		var box := HBoxContainer.new()
		_config_box_container(box, spec)
		root.add_child(box)
		containers[spec["key"]] = box
	return containers

static func _config_box_container(box: BoxContainer, spec: Dictionary) -> void:
	box.name = spec["name"]
	box.set_anchors_and_offsets_preset(spec["preset"])
	box.size_flags_horizontal = spec["h_flag"]
	box.size_flags_vertical = spec["v_flag"]
	box.alignment = spec["alignment"]
	if spec.get("separator", false):
		box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE

static func _populate_components(components: Components, containers: Dictionary) -> void:
	_populate_left_columns(components, containers)
	_populate_right_columns(components, containers)
	_populate_center_sections(components, containers)

static func _instantiate_panel(scene_path: String, container: Control, name := "", h_flag := Control.SIZE_SHRINK_CENTER, v_flag := Control.SIZE_SHRINK_CENTER) -> Control:
	var scene: PackedScene = load(scene_path)
	if not scene:
		push_error("HUDComponentFactory: Failed to load scene: " + scene_path)
		return null
	var panel: Control = scene.instantiate()
	panel.size_flags_horizontal = h_flag
	panel.size_flags_vertical = v_flag
	if not String(name).is_empty():
		panel.name = name
	container.add_child(panel)
	return panel

static func _populate_left_columns(components: Components, containers: Dictionary) -> void:
	var top_left: VBoxContainer = containers["top_left"]
	components.locations_list = _instantiate_panel(FilePaths.Scenes.LOCATIONS_LIST_PANEL, top_left, "", Control.SIZE_SHRINK_BEGIN)
	components.tasks_list = _instantiate_panel(FilePaths.Scenes.TASKS_LIST_PANEL, top_left, "TasksListPanel", Control.SIZE_SHRINK_BEGIN)
	var bottom_left: VBoxContainer = containers["bottom_left"]
	components.unit_details = _instantiate_panel(FilePaths.Scenes.UNIT_DETAILS_PANEL, bottom_left, "UnitDetailsPanel", Control.SIZE_SHRINK_BEGIN)

static func _populate_right_columns(components: Components, containers: Dictionary) -> void:
	var top_right: VBoxContainer = containers["top_right"]
	var button_row := HBoxContainer.new()
	button_row.name = "TopRightButtons"
	button_row.alignment = BoxContainer.ALIGNMENT_END
	top_right.add_child(button_row)
	components.debug_clear_journal_button = _create_button(button_row, {
		"name": "DebugClearJournalButton",
		"text": "DBG: Clear Journal",
		"tooltip": "DEBUG: Clear all journal entries",
		"size": Vector2(120, 30),
		"debug_only": true
	})
	components.auto_battle_button = _create_button(button_row, {
		"name": "AutoBattleButton",
		"text": LocalizationStrings.get_text(LocalizationStrings.HUD_AUTO_BATTLE),
		"tooltip": LocalizationStrings.get_text(LocalizationStrings.HUD_AUTO_BATTLE_TOOLTIP),
		"size": Vector2(100, 30),
		"toggle": true
	})
	components.pause_button = _create_button(button_row, {
		"name": "PauseButton",
		"text": LocalizationStrings.get_text(LocalizationStrings.HUD_PAUSE),
		"tooltip": LocalizationStrings.get_text(LocalizationStrings.HUD_PAUSE_TOOLTIP),
		"size": Vector2(80, 30)
	})
	components.round_info = _instantiate_panel(FilePaths.Scenes.ROUND_INFO_PANEL, top_right, "RoundInfoPanel", Control.SIZE_SHRINK_END)
	components.weather_panel = _instantiate_panel(FilePaths.Scenes.WEATHER_PANEL, top_right, "WeatherPanel", Control.SIZE_SHRINK_BEGIN)
	var bottom_right: VBoxContainer = containers["bottom_right"]
	components.terrain_details = _instantiate_panel(FilePaths.Scenes.TERRAIN_DETAILS_PANEL, bottom_right, "TerrainDetailsPanel", Control.SIZE_SHRINK_END)

static func _populate_center_sections(components: Components, containers: Dictionary) -> void:
	var top_center: HBoxContainer = containers["top_center"]
	print_debug("HUDComponentFactory - Creating ActionsPanel")
	components.actions_panel = _instantiate_panel(FilePaths.Scenes.ACTIONS_PANEL, top_center, "ActionsPanel", Control.SIZE_SHRINK_CENTER)
	print_debug("HUDComponentFactory - ActionsPanel created, type: ", components.actions_panel.get_class() if components.actions_panel else "NULL")
	var center_left: VBoxContainer = containers["center_left"]
	components.location_details = _instantiate_panel(FilePaths.Scenes.LOCATION_DETAILS_PANEL, center_left, "LocationDetailsPanel", Control.SIZE_SHRINK_BEGIN)
	components.task_details = _instantiate_panel(FilePaths.Scenes.TASK_DETAILS_PANEL, center_left, "TaskDetailsPanel", Control.SIZE_SHRINK_BEGIN)
	var center_right: VBoxContainer = containers["center_right"]
	components.loot_details = _instantiate_panel(FilePaths.Scenes.LOOT_DETAILS_PANEL, center_right, "LootDetailsPanel", Control.SIZE_SHRINK_END, Control.SIZE_SHRINK_BEGIN)
	components.combat_preview = _instantiate_panel(FilePaths.Scenes.COMBAT_PREVIEW_PANEL, center_right, "CombatPreviewPanel", Control.SIZE_SHRINK_END, Control.SIZE_SHRINK_BEGIN)
	var bottom_center: HBoxContainer = containers["bottom_center"]
	components.morale_panel = _instantiate_panel(FilePaths.Scenes.MORALE_PANEL, bottom_center, "MoralePanel", Control.SIZE_EXPAND_FILL)

static func _create_button(container: Control, spec: Dictionary) -> Button:
	var button := Button.new()
	button.name = spec.get("name", "")
	button.text = spec.get("text", "")
	button.custom_minimum_size = spec.get("size", Vector2(80, 30))
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	if spec.get("toggle", false):
		button.toggle_mode = true
	if spec.has("tooltip"):
		button.tooltip_text = spec.get("tooltip", "")
	if spec.get("debug_only", false) and not OS.is_debug_build():
		button.visible = false
	container.add_child(button)
	return button

