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
	var add_vbox := func(name: String, preset: int, h_flag: int, v_flag: int, alignment: int, add_separator := false) -> VBoxContainer:
		var box := VBoxContainer.new()
		box.name = name
		box.set_anchors_and_offsets_preset(preset)
		box.size_flags_horizontal = h_flag
		box.size_flags_vertical = v_flag
		box.alignment = alignment
		if add_separator:
			box.add_theme_constant_override("separation", 10)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(box)
		return box
	var containers: Dictionary = {}
	containers["top_left"] = add_vbox.call("TopLeftContainer", Control.PRESET_TOP_LEFT, Control.SIZE_SHRINK_BEGIN, Control.SIZE_SHRINK_BEGIN, BoxContainer.ALIGNMENT_BEGIN)
	containers["top_right"] = add_vbox.call("TopRightContainer", Control.PRESET_TOP_RIGHT, Control.SIZE_SHRINK_END, Control.SIZE_SHRINK_BEGIN, BoxContainer.ALIGNMENT_BEGIN)
	containers["bottom_left"] = add_vbox.call("BottomLeftContainer", Control.PRESET_BOTTOM_LEFT, Control.SIZE_SHRINK_BEGIN, Control.SIZE_SHRINK_END, BoxContainer.ALIGNMENT_END)
	containers["bottom_right"] = add_vbox.call("BottomRightContainer", Control.PRESET_BOTTOM_RIGHT, Control.SIZE_SHRINK_END, Control.SIZE_SHRINK_END, BoxContainer.ALIGNMENT_END)
	containers["center_left"] = add_vbox.call("CenterLeftContainer", Control.PRESET_CENTER_LEFT, Control.SIZE_SHRINK_BEGIN, Control.SIZE_SHRINK_CENTER, BoxContainer.ALIGNMENT_CENTER, true)
	containers["center_right"] = add_vbox.call("CenterRightContainer", Control.PRESET_CENTER_RIGHT, Control.SIZE_SHRINK_END, Control.SIZE_SHRINK_CENTER, BoxContainer.ALIGNMENT_CENTER, true)
	var add_hbox := func(name: String, preset: int, h_flag: int, v_flag: int, alignment: int, add_separator := false) -> HBoxContainer:
		var box := HBoxContainer.new()
		box.name = name
		box.set_anchors_and_offsets_preset(preset)
		box.size_flags_horizontal = h_flag
		box.size_flags_vertical = v_flag
		box.alignment = alignment
		if add_separator:
			box.add_theme_constant_override("separation", 10)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(box)
		return box
	containers["top_center"] = add_hbox.call("TopCenterContainer", Control.PRESET_CENTER_TOP, Control.SIZE_SHRINK_CENTER, Control.SIZE_SHRINK_BEGIN, BoxContainer.ALIGNMENT_CENTER, true)
	containers["bottom_center"] = add_hbox.call("BottomCenterContainer", Control.PRESET_CENTER_BOTTOM, Control.SIZE_SHRINK_CENTER, Control.SIZE_SHRINK_END, BoxContainer.ALIGNMENT_CENTER, true)
	return containers

static func _populate_components(components: Components, containers: Dictionary) -> void:
	var add_panel := func(scene_path: String, container: Control, name := "", h_flag := Control.SIZE_SHRINK_CENTER, v_flag := Control.SIZE_SHRINK_CENTER) -> Control:
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
	var top_left: VBoxContainer = containers["top_left"]
	components.locations_list = add_panel.call(FilePaths.Scenes.LOCATIONS_LIST_PANEL, top_left, "", Control.SIZE_SHRINK_BEGIN)
	components.tasks_list = add_panel.call(FilePaths.Scenes.TASKS_LIST_PANEL, top_left, "TasksListPanel", Control.SIZE_SHRINK_BEGIN)
	var top_right: VBoxContainer = containers["top_right"]
	var button_hbox := HBoxContainer.new()
	button_hbox.name = "TopRightButtons"
	button_hbox.alignment = BoxContainer.ALIGNMENT_END
	top_right.add_child(button_hbox)

	var create_pause_button := func(container: Control) -> Button:
		var button := Button.new()
		button.name = "PauseButton"
		button.text = LocalizationStrings.get_text(LocalizationStrings.HUD_PAUSE)
		button.custom_minimum_size = Vector2(80, 30)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.tooltip_text = LocalizationStrings.get_text(LocalizationStrings.HUD_PAUSE_TOOLTIP)

		container.add_child(button)
		return button

	var create_auto_battle_button := func(container: Control) -> Button:
		var button := Button.new()
		button.name = "AutoBattleButton"
		button.text = LocalizationStrings.get_text(LocalizationStrings.HUD_AUTO_BATTLE)
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(100, 30)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.tooltip_text = LocalizationStrings.get_text(LocalizationStrings.HUD_AUTO_BATTLE_TOOLTIP)

		container.add_child(button)
		return button

	var create_debug_clear_journal_button := func(container: Control) -> Button:
		var button := Button.new()
		button.name = "DebugClearJournalButton"
		button.text = "DBG: Clear Journal"
		button.custom_minimum_size = Vector2(120, 30)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.tooltip_text = "DEBUG: Clear all journal entries"
		# Hide in release builds
		if not OS.is_debug_build():
			button.visible = false

		container.add_child(button)
		return button

	components.debug_clear_journal_button = create_debug_clear_journal_button.call(button_hbox)
	components.auto_battle_button = create_auto_battle_button.call(button_hbox)
	components.pause_button = create_pause_button.call(button_hbox)
	components.round_info = add_panel.call(FilePaths.Scenes.ROUND_INFO_PANEL, top_right, "RoundInfoPanel", Control.SIZE_SHRINK_END)
	components.weather_panel = add_panel.call(FilePaths.Scenes.WEATHER_PANEL, top_right, "WeatherPanel", Control.SIZE_SHRINK_BEGIN)
	var top_center: HBoxContainer = containers["top_center"]
	print_debug("HUDComponentFactory - Creating ActionsPanel")
	components.actions_panel = add_panel.call(FilePaths.Scenes.ACTIONS_PANEL, top_center, "ActionsPanel", Control.SIZE_SHRINK_CENTER)
	print_debug("HUDComponentFactory - ActionsPanel created, type: ", components.actions_panel.get_class() if components.actions_panel else "NULL")
	var bottom_left: VBoxContainer = containers["bottom_left"]
	components.unit_details = add_panel.call(FilePaths.Scenes.UNIT_DETAILS_PANEL, bottom_left, "UnitDetailsPanel", Control.SIZE_SHRINK_BEGIN)
	var bottom_right: VBoxContainer = containers["bottom_right"]
	components.terrain_details = add_panel.call(FilePaths.Scenes.TERRAIN_DETAILS_PANEL, bottom_right, "TerrainDetailsPanel", Control.SIZE_SHRINK_END)
	var center_left: VBoxContainer = containers["center_left"]
	components.location_details = add_panel.call(FilePaths.Scenes.LOCATION_DETAILS_PANEL, center_left, "LocationDetailsPanel", Control.SIZE_SHRINK_BEGIN)
	components.task_details = add_panel.call(FilePaths.Scenes.TASK_DETAILS_PANEL, center_left, "TaskDetailsPanel", Control.SIZE_SHRINK_BEGIN)
	var center_right: VBoxContainer = containers["center_right"]
	components.loot_details = add_panel.call(FilePaths.Scenes.LOOT_DETAILS_PANEL, center_right, "LootDetailsPanel", Control.SIZE_SHRINK_END, Control.SIZE_SHRINK_BEGIN)
	components.combat_preview = add_panel.call(FilePaths.Scenes.COMBAT_PREVIEW_PANEL, center_right, "CombatPreviewPanel", Control.SIZE_SHRINK_END, Control.SIZE_SHRINK_BEGIN)
	var bottom_center: HBoxContainer = containers["bottom_center"]
	components.morale_panel = add_panel.call(FilePaths.Scenes.MORALE_PANEL, bottom_center, "MoralePanel", Control.SIZE_EXPAND_FILL)
