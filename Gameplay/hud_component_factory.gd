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
const WeatherPanelScene := preload("res://gui/weather_panel.tscn")

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

	func setup(unit_manager, turn_controller, input_controller, goal_manager) -> void:
		var panels = [
			round_info,
			goals_list,
			unit_details,
			combat_preview,
			goal_details,
			terrain_details,
			weather_panel
		]

		for panel in panels:
			if panel.has_method("setup"):
				panel.setup(unit_manager, turn_controller, input_controller, goal_manager)

static func create_components(parent: Node) -> Components:
	var components = Components.new()

	# Create a main layout container
	var margin_container = MarginContainer.new()
	margin_container.name = "HUDMarginContainer"
	margin_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin_container.add_theme_constant_override("margin_left", 20)
	margin_container.add_theme_constant_override("margin_top", 20)
	margin_container.add_theme_constant_override("margin_right", 20)
	margin_container.add_theme_constant_override("margin_bottom", 20)
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Add layout manager for orientation support
	var layout_manager = Node.new()
	layout_manager.name = "LayoutManager"
	layout_manager.set_script(load("res://Gameplay/hud_layout_manager.gd"))
	margin_container.add_child(layout_manager)

	parent.add_child(margin_container)

	# Corner Containers
	var top_left = VBoxContainer.new()
	top_left.name = "TopLeftContainer"
	top_left.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	top_left.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	top_left.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_left.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.add_child(top_left)

	var top_right = VBoxContainer.new()
	top_right.name = "TopRightContainer"
	top_right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	top_right.size_flags_horizontal = Control.SIZE_SHRINK_END
	top_right.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top_right.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.add_child(top_right)

	var bottom_left = VBoxContainer.new()
	bottom_left.name = "BottomLeftContainer"
	bottom_left.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bottom_left.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bottom_left.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom_left.alignment = BoxContainer.ALIGNMENT_END
	bottom_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.add_child(bottom_left)

	var bottom_right = VBoxContainer.new()
	bottom_right.name = "BottomRightContainer"
	bottom_right.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	bottom_right.size_flags_horizontal = Control.SIZE_SHRINK_END
	bottom_right.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom_right.alignment = BoxContainer.ALIGNMENT_END
	bottom_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.add_child(bottom_right)

	# Side Center Containers
	var center_left = VBoxContainer.new()
	center_left.name = "CenterLeftContainer"
	center_left.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	center_left.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	center_left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_left.alignment = BoxContainer.ALIGNMENT_CENTER
	center_left.add_theme_constant_override("separation", 10)
	center_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.add_child(center_left)

	var center_right = VBoxContainer.new()
	center_right.name = "CenterRightContainer"
	center_right.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	center_right.size_flags_horizontal = Control.SIZE_SHRINK_END
	center_right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_right.alignment = BoxContainer.ALIGNMENT_CENTER
	center_right.add_theme_constant_override("separation", 10)
	center_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.add_child(center_right)

	# Instantiate and distribute components to containers

	# Top Left: Goals and Weather
	components.goals_list = GoalsListPanelScene.instantiate()
	components.goals_list.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	top_left.add_child(components.goals_list)

	components.weather_panel = WeatherPanelScene.instantiate()
	components.weather_panel.name = "WeatherPanel"
	components.weather_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	top_left.add_child(components.weather_panel)

	# Top Right: Round Info
	components.round_info = RoundInfoPanelScene.instantiate()
	components.round_info.name = "RoundInfoPanel"
	components.round_info.size_flags_horizontal = Control.SIZE_SHRINK_END
	top_right.add_child(components.round_info)

	# Bottom Left: Actions then Unit Details (Actions above Unit Details)
	components.actions_panel = ActionsPanelScene.instantiate()
	components.actions_panel.name = "ActionsPanel"
	components.actions_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bottom_left.add_child(components.actions_panel)

	components.unit_details = UnitDetailsPanelScene.instantiate()
	components.unit_details.name = "UnitDetailsPanel"
	components.unit_details.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bottom_left.add_child(components.unit_details)

	# Bottom Right: Terrain
	components.terrain_details = TerrainDetailsPanelScene.instantiate()
	components.terrain_details.name = "TerrainDetailsPanel"
	components.terrain_details.size_flags_horizontal = Control.SIZE_SHRINK_END
	bottom_right.add_child(components.terrain_details)

	# Center Left: Goal Details
	components.goal_details = GoalDetailsPanelScene.instantiate()
	components.goal_details.name = "GoalDetailsPanel"
	components.goal_details.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	center_left.add_child(components.goal_details)

	# Center Right: Combat Preview and Loot Details
	components.combat_preview = CombatPreviewPanelScene.instantiate()
	components.combat_preview.name = "CombatPreviewPanel"
	components.combat_preview.size_flags_horizontal = Control.SIZE_SHRINK_END
	center_right.add_child(components.combat_preview)

	components.loot_details = LootDetailsPanelScene.instantiate()
	components.loot_details.name = "LootDetailsPanel"
	components.loot_details.size_flags_horizontal = Control.SIZE_SHRINK_END
	center_right.add_child(components.loot_details)

	return components
