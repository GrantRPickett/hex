class_name HUDComponentFactory
extends RefCounted

const RoundInfoPanelScene := preload("res://GUI/round_info_panel.tscn")
const GoalsListPanelScene := preload("res://GUI/goals_list_panel.tscn")
const UnitDetailsPanelScene := preload("res://GUI/unit_details_panel.tscn")
const CombatPreviewPanelScene := preload("res://GUI/combat_preview_panel.tscn")
const GoalDetailsPanelScene := preload("res://GUI/goal_details_panel.tscn")
const TerrainDetailsPanelScene := preload("res://GUI/terrain_details_panel.tscn")
const ActionsPanelScene := preload("res://GUI/actions_panel.tscn")
const LootDetailsPanelScene := preload("res://GUI/loot_details_panel.tscn")
const WeatherPanelScene := preload("res://GUI/weather_panel.tscn")
const MoralePanelScene := preload("res://GUI/morale_panel.tscn")

class Components:
	var round_info: RoundInfoPanel
	var goals_list: GoalsListPanel
	var unit_details: UnitDetailsPanel
	var combat_preview: CombatPreviewPanel
	var goal_details: GoalDetailsPanel
	var terrain_details: TerrainDetailsPanel
	var actions_panel: ActionsPanel
	var loot_details: LootDetailsPanel
	var weather_panel: WeatherPanel
	var morale_panel: MoralePanel
	var auto_battle_button: Button

	func setup(unit_manager, turn_controller, input_controller, goal_manager) -> void:
		var panels = [
			round_info,
			goals_list,
			unit_details,
			combat_preview,
			goal_details,
			terrain_details,
			weather_panel,
			morale_panel
		]

		for panel in panels:
			if panel == null or not panel.has_method("setup"):
				continue
			var method_info := _get_setup_method_info(panel)
			var arg_count := 0
			if method_info.has("args"):
				arg_count = method_info["args"].size()
			var call_args: Array = []
			if arg_count >= 1:
				call_args.append(unit_manager)
			if arg_count >= 2:
				call_args.append(turn_controller)
			if arg_count >= 3:
				call_args.append(input_controller)
			if arg_count >= 4:
				call_args.append(goal_manager)
			panel.callv("setup", call_args)


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
	var layout_manager = Node.new()
	layout_manager.name = "LayoutManager"
	layout_manager.set_script(load("res://Gameplay/hud_layout_manager.gd"))
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
	var add_panel := func(scene: PackedScene, container: Control, name := "", h_flag := Control.SIZE_SHRINK_CENTER, v_flag := Control.SIZE_SHRINK_CENTER) -> Control:
		var panel: Control = scene.instantiate()
		panel.size_flags_horizontal = h_flag
		panel.size_flags_vertical = v_flag
		if not String(name).is_empty():
			panel.name = name
		container.add_child(panel)
		return panel
	var top_left: VBoxContainer = containers["top_left"]
	components.goals_list = add_panel.call(GoalsListPanelScene, top_left, "", Control.SIZE_SHRINK_BEGIN)
	var top_right: VBoxContainer = containers["top_right"]
	components.round_info = add_panel.call(RoundInfoPanelScene, top_right, "RoundInfoPanel", Control.SIZE_SHRINK_END)
	components.weather_panel = add_panel.call(WeatherPanelScene, top_right, "WeatherPanel", Control.SIZE_SHRINK_BEGIN)
	var top_center: HBoxContainer = containers["top_center"]
	var create_auto_battle_button := func(container: HBoxContainer) -> Button:
		var button := Button.new()
		button.name = "AutoBattleButton"
		button.text = "Auto Act"
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(140, 30)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.tooltip_text = "Let the team handle actions until cancelled."
		container.add_child(button)
		return button
	components.auto_battle_button = create_auto_battle_button.call(top_center)
	print_debug("HUDComponentFactory - Creating ActionsPanel")
	components.actions_panel = add_panel.call(ActionsPanelScene, top_center, "ActionsPanel", Control.SIZE_SHRINK_CENTER)
	print_debug("HUDComponentFactory - ActionsPanel created: ", components.actions_panel, " parent will be top_center")
	print_debug("HUDComponentFactory - ActionsPanel added to scene tree, visible: ", components.actions_panel.visible, " position: ", components.actions_panel.position)
	var bottom_left: VBoxContainer = containers["bottom_left"]
	components.unit_details = add_panel.call(UnitDetailsPanelScene, bottom_left, "UnitDetailsPanel", Control.SIZE_SHRINK_BEGIN)
	var bottom_right: VBoxContainer = containers["bottom_right"]
	components.terrain_details = add_panel.call(TerrainDetailsPanelScene, bottom_right, "TerrainDetailsPanel", Control.SIZE_SHRINK_END)
	var center_left: VBoxContainer = containers["center_left"]
	components.goal_details = add_panel.call(GoalDetailsPanelScene, center_left, "GoalDetailsPanel", Control.SIZE_SHRINK_BEGIN)
	var center_right: VBoxContainer = containers["center_right"]
	components.loot_details = add_panel.call(LootDetailsPanelScene, center_right, "LootDetailsPanel", Control.SIZE_SHRINK_END, Control.SIZE_SHRINK_BEGIN)
	components.combat_preview = add_panel.call(CombatPreviewPanelScene, center_right, "CombatPreviewPanel", Control.SIZE_SHRINK_END, Control.SIZE_SHRINK_BEGIN)
	var bottom_center: HBoxContainer = containers["bottom_center"]
	components.morale_panel = add_panel.call(MoralePanelScene, bottom_center, "MoralePanel", Control.SIZE_EXPAND_FILL)
