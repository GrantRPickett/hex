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
	var interaction_log: InteractionLogPanel
	var auto_battle_button: Button
	var pause_button: Button
	var debug_clear_journal_button: Button
	var debug_player_stats_button: Button
	var debug_enemy_stats_button: Button
	var debug_neutral_stats_button: Button

	# Container references for layout updates
	var margin_container: MarginContainer
	var column_container: BoxContainer
	var column_spacer: Control
	var left_column: VBoxContainer
	var right_column: VBoxContainer
	var top_center: HBoxContainer
	var bottom_center: HBoxContainer

	func setup(state: GameState, config: GameSessionBuilder.Config) -> void:
		var panels = [
			round_info,
			locations_list,
			unit_details,
			combat_preview,
			location_details,
			terrain_details,
			weather_panel,
			morale_panel,
			interaction_log
		]

		for panel in panels:
			if panel == null or not panel.has_method("setup"):
				continue
			# Individual panels' setup methods now expect state and config
			panel.callv("setup", [state, config])

	func update_layout(_is_portrait: bool) -> void:
		if not margin_container: return

		# In this new architecture, the scene itself handles the basic layout.
		# If we needed to swap scenes here, we'd notify the controller.
		# For now, we'll assume the factory created the correct scene for the initial orientation.
		pass


	func _get_setup_method_info(panel) -> Dictionary:
		for method_dict in panel.get_method_list():
			if method_dict.get("name") == "setup":
				return method_dict
		return {}
static func create_components(parent: Node, is_portrait: bool) -> Components:
	var components: Components = Components.new()

	var scene_path := "res://GUI/HUD/portrait_hud.tscn" if is_portrait else "res://GUI/HUD/landscape_hud.tscn"
	var hud_scene: PackedScene = load(scene_path)
	if not hud_scene:
		GameLogger.error(GameLogger.Category.UI, "HUDComponentFactory: Could not load HUD scene: " + scene_path)
		return components

	var root: Node = hud_scene.instantiate()
	parent.add_child(root)
	components.margin_container = root

	_populate_from_scene(components, root, is_portrait)
	return components

static func _populate_from_scene(components: Components, root: Node, is_portrait: bool) -> void:
	if is_portrait:
		_populate_portrait(components, root)
	else:
		_populate_landscape(components, root)

static func _populate_landscape(components: Components, root: Node) -> void:
	var left_column = root.get_node("%LeftColumn")
	var right_column = root.get_node("%RightColumn")
	var top_center = root.get_node("%TopCenterContainer")
	var bottom_center = root.get_node("%BottomCenterContainer")

	components.locations_list = _instantiate_panel(FilePaths.Scenes.LOCATIONS_LIST_PANEL, left_column, "LocationsListPanel", Control.SIZE_SHRINK_BEGIN)
	components.tasks_list = _instantiate_panel(FilePaths.Scenes.TASKS_LIST_PANEL, left_column, "TasksListPanel", Control.SIZE_SHRINK_BEGIN)

	# Spacer
	var spacer_l := Control.new()
	spacer_l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_column.add_child(spacer_l)

	components.location_details = _instantiate_panel(FilePaths.Scenes.LOCATION_DETAILS_PANEL, left_column, "LocationDetailsPanel", Control.SIZE_SHRINK_BEGIN)
	components.task_details = _instantiate_panel(FilePaths.Scenes.TASK_DETAILS_PANEL, left_column, "TaskDetailsPanel", Control.SIZE_SHRINK_BEGIN)
	components.unit_details = _instantiate_panel(FilePaths.Scenes.UNIT_DETAILS_PANEL, left_column, "UnitDetailsPanel", Control.SIZE_SHRINK_BEGIN)

	_populate_right_column(components, right_column)

	components.actions_panel = _instantiate_panel(FilePaths.Scenes.ACTIONS_PANEL, top_center, "ActionsPanel", Control.SIZE_SHRINK_CENTER)
	components.morale_panel = _instantiate_panel(FilePaths.Scenes.MORALE_PANEL, bottom_center, "MoralePanel", Control.SIZE_EXPAND_FILL)

static func _populate_portrait(components: Components, root: Node) -> void:
	var round_anchor = root.get_node("%RoundInfoAnchor")
	var weather_anchor = root.get_node("%WeatherAnchor")
	var locations_tab = root.get_node("%LocationsTab")
	var tasks_tab = root.get_node("%TasksTab")
	var unit_tab = root.get_node("%UnitTab")
	var actions_anchor = root.get_node("%ActionsAnchor")
	var morale_anchor = root.get_node("%MoraleAnchor")
	var top_buttons = root.get_node("%TopButtons")

	components.round_info = _instantiate_panel(FilePaths.Scenes.ROUND_INFO_PANEL, round_anchor, "RoundInfoPanel", Control.SIZE_EXPAND_FILL)
	components.weather_panel = _instantiate_panel(FilePaths.Scenes.WEATHER_PANEL, weather_anchor, "WeatherPanel", Control.SIZE_EXPAND_FILL)
	if components.weather_panel.has_method("set"):
		components.weather_panel.is_compact = true

	# Reuse the button creation logic for the top buttons anchor
	_create_right_column_buttons(components, top_buttons)

	components.locations_list = _instantiate_panel(FilePaths.Scenes.LOCATIONS_LIST_PANEL, locations_tab, "LocationsListPanel", Control.SIZE_EXPAND_FILL, Control.SIZE_EXPAND_FILL)
	components.location_details = _instantiate_panel(FilePaths.Scenes.LOCATION_DETAILS_PANEL, locations_tab, "LocationDetailsPanel", Control.SIZE_EXPAND_FILL, Control.SIZE_EXPAND_FILL)
	components.location_details.visible = false

	components.tasks_list = _instantiate_panel(FilePaths.Scenes.TASKS_LIST_PANEL, tasks_tab, "TasksListPanel", Control.SIZE_EXPAND_FILL, Control.SIZE_EXPAND_FILL)
	components.task_details = _instantiate_panel(FilePaths.Scenes.TASK_DETAILS_PANEL, tasks_tab, "TaskDetailsPanel", Control.SIZE_EXPAND_FILL, Control.SIZE_EXPAND_FILL)
	components.task_details.visible = false

	components.unit_details = _instantiate_panel(FilePaths.Scenes.UNIT_DETAILS_PANEL, unit_tab, "UnitDetailsPanel", Control.SIZE_EXPAND_FILL, Control.SIZE_EXPAND_FILL)
	components.loot_details = _instantiate_panel(FilePaths.Scenes.LOOT_DETAILS_PANEL, unit_tab, "LootDetailsPanel", Control.SIZE_EXPAND_FILL, Control.SIZE_EXPAND_FILL)
	components.combat_preview = _instantiate_panel(FilePaths.Scenes.COMBAT_PREVIEW_PANEL, unit_tab, "CombatPreviewPanel", Control.SIZE_EXPAND_FILL, Control.SIZE_EXPAND_FILL)
	components.terrain_details = _instantiate_panel(FilePaths.Scenes.TERRAIN_DETAILS_PANEL, unit_tab, "TerrainDetailsPanel", Control.SIZE_EXPAND_FILL, Control.SIZE_EXPAND_FILL)

	components.actions_panel = _instantiate_panel(FilePaths.Scenes.ACTIONS_PANEL, actions_anchor, "ActionsPanel", Control.SIZE_EXPAND_FILL)
	components.morale_panel = _instantiate_panel(FilePaths.Scenes.MORALE_PANEL, morale_anchor, "MoralePanel", Control.SIZE_EXPAND_FILL)

	# Pause button in top right buttons? Portrait might need it too.
	# For now, let's just make sure we don't crash.

static func _create_layout_containers(root: MarginContainer) -> Dictionary:
	var containers: Dictionary = {}

	# Column Container to manage Left/Right sidebar orientation
	var column_container := BoxContainer.new()
	column_container.name = "ColumnContainer"
	column_container.vertical = false # Default to horizontal (landscape)
	column_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(column_container)
	containers["column_container"] = column_container

	# Primary Left Column
	var left_column := VBoxContainer.new()
	left_column.name = "LeftColumn"
	left_column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_theme_constant_override("separation", 10)
	left_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column_container.add_child(left_column)
	containers["left_column"] = left_column

	# Spacer between columns for landscape
	var column_spacer := Control.new()
	column_spacer.name = "ColumnSpacer"
	column_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column_container.add_child(column_spacer)
	containers["column_spacer"] = column_spacer

	# Primary Right Column
	var right_column := VBoxContainer.new()
	right_column.name = "RightColumn"
	right_column.size_flags_horizontal = Control.SIZE_SHRINK_END
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.add_theme_constant_override("separation", 10)
	right_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column_container.add_child(right_column)
	containers["right_column"] = right_column

	# Center Top (Actions)
	var top_center := HBoxContainer.new()
	top_center.name = "TopCenterContainer"
	top_center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	top_center.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top_center)
	containers["top_center"] = top_center

	# Center Bottom (Morale)
	var bottom_center := HBoxContainer.new()
	bottom_center.name = "BottomCenterContainer"
	bottom_center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bottom_center.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom_center)
	containers["bottom_center"] = bottom_center

	return containers

static func _populate_components(_components: Components, _containers: Dictionary) -> void:
	# Keep for compatibility or remove later
	pass

static func _populate_left_column(components: Components, column: VBoxContainer) -> void:
	components.locations_list = _instantiate_panel(FilePaths.Scenes.LOCATIONS_LIST_PANEL, column, "LocationsListPanel", Control.SIZE_SHRINK_BEGIN)
	components.tasks_list = _instantiate_panel(FilePaths.Scenes.TASKS_LIST_PANEL, column, "TasksListPanel", Control.SIZE_SHRINK_BEGIN)

	# Spacer to push unit details to bottom
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(spacer)

	components.location_details = _instantiate_panel(FilePaths.Scenes.LOCATION_DETAILS_PANEL, column, "LocationDetailsPanel", Control.SIZE_SHRINK_BEGIN)
	components.task_details = _instantiate_panel(FilePaths.Scenes.TASK_DETAILS_PANEL, column, "TaskDetailsPanel", Control.SIZE_SHRINK_BEGIN)
	components.unit_details = _instantiate_panel(FilePaths.Scenes.UNIT_DETAILS_PANEL, column, "UnitDetailsPanel", Control.SIZE_SHRINK_BEGIN)

static func _populate_right_column(components: Components, container: Control) -> void:
	_create_right_column_buttons(components, container)
	_create_right_column_panels(components, container)

static func _create_right_column_buttons(components: Components, container: Control) -> void:
	# Buttons at the very top
	var button_row := HBoxContainer.new()
	button_row.name = "TopRightButtons"
	button_row.alignment = BoxContainer.ALIGNMENT_END
	button_row.size_flags_horizontal = Control.SIZE_SHRINK_END
	button_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(button_row)

	var debug_row := HBoxContainer.new()
	debug_row.name = "DebugFactionButtons"
	debug_row.alignment = BoxContainer.ALIGNMENT_END
	debug_row.size_flags_horizontal = Control.SIZE_SHRINK_END
	debug_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(debug_row)

	components.debug_player_stats_button = _create_button(debug_row, {
		"name": "DebugPlayerStatsButton",
		"text": "DBG: +100 Player",
		"tooltip": "DEBUG: Toggle +100 to all stats for Player faction",
		"size": Vector2(120, 30),
		"debug_only": true,
		"toggle": true
	})
	components.debug_enemy_stats_button = _create_button(debug_row, {
		"name": "DebugEnemyStatsButton",
		"text": "DBG: +100 Enemy",
		"tooltip": "DEBUG: Toggle +100 to all stats for Enemy faction",
		"size": Vector2(120, 30),
		"debug_only": true,
		"toggle": true
	})
	components.debug_neutral_stats_button = _create_button(debug_row, {
		"name": "DebugNeutralStatsButton",
		"text": "DBG: +100 Neutral",
		"tooltip": "DEBUG: Toggle +100 to all stats for Neutral faction",
		"size": Vector2(120, 30),
		"debug_only": true,
		"toggle": true
	})

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

static func _create_right_column_panels(components: Components, container: Control) -> void:
	components.round_info = _instantiate_panel(FilePaths.Scenes.ROUND_INFO_PANEL, container, "RoundInfoPanel", Control.SIZE_SHRINK_END)
	components.weather_panel = _instantiate_panel(FilePaths.Scenes.WEATHER_PANEL, container, "WeatherPanel", Control.SIZE_SHRINK_END)

	# Spacer to push combat preview and terrain details to bottom
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(spacer)

	components.loot_details = _instantiate_panel(FilePaths.Scenes.LOOT_DETAILS_PANEL, container, "LootDetailsPanel", Control.SIZE_SHRINK_END)
	components.interaction_log = _instantiate_panel(FilePaths.Scenes.INTERACTION_LOG_PANEL, container, "InteractionLogPanel", Control.SIZE_SHRINK_END)
	components.combat_preview = _instantiate_panel(FilePaths.Scenes.COMBAT_PREVIEW_PANEL, container, "CombatPreviewPanel", Control.SIZE_SHRINK_END)
	components.terrain_details = _instantiate_panel(FilePaths.Scenes.TERRAIN_DETAILS_PANEL, container, "TerrainDetailsPanel", Control.SIZE_SHRINK_END)

static func _populate_center_sections(components: Components, containers: Dictionary) -> void:
	var top_center: HBoxContainer = containers["top_center"]
	components.actions_panel = _instantiate_panel(FilePaths.Scenes.ACTIONS_PANEL, top_center, "ActionsPanel", Control.SIZE_SHRINK_CENTER)

	var bottom_center: HBoxContainer = containers["bottom_center"]
	components.morale_panel = _instantiate_panel(FilePaths.Scenes.MORALE_PANEL, bottom_center, "MoralePanel", Control.SIZE_EXPAND_FILL)

static func _instantiate_panel(scene_path: String, container: Control, name := "", h_flag := Control.SIZE_SHRINK_CENTER, v_flag := Control.SIZE_SHRINK_CENTER) -> Control:
	var scene: PackedScene = load(scene_path)
	if not scene:
		GameLogger.error(GameLogger.Category.UI, "HUDComponentFactory: Failed to load scene: " + scene_path)
		return null
	var panel: Control = scene.instantiate()
	panel.size_flags_horizontal = h_flag
	panel.size_flags_vertical = v_flag
	if not String(name).is_empty():
		panel.name = name
	container.add_child(panel)
	return panel

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
