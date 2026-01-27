class_name HUDComponentFactory
extends RefCounted

const RoundInfoPanel := preload("res://GUI/round_info_panel.tscn")
const GoalsListPanel := preload("res://GUI/goals_list_panel.tscn")
const UnitDetailsPanel := preload("res://GUI/unit_details_panel.tscn")
const CombatPreviewPanel := preload("res://GUI/combat_preview_panel.tscn")
const GoalDetailsPanel := preload("res://GUI/goal_details_panel.tscn")
const TerrainDetailsPanel := preload("res://GUI/terrain_details_panel.tscn")
const ActionsPanel := preload("res://GUI/actions_panel.tscn")
const LootDetailsPanel := preload("res://GUI/loot_details_panel.tscn")

class Components:
	var round_info: RoundInfoPanel
	var goals_list: GoalsListPanel
	var unit_details: UnitDetailsPanel
	var combat_preview: CombatPreviewPanel
	var goal_details: GoalDetailsPanel
	var terrain_details: TerrainDetailsPanel
	var actions_panel: ActionsPanel
	var loot_details: LootDetailsPanel

	func setup(unit_manager, turn_controller, input_controller, goal_manager) -> void:
		var panels = [
			round_info,
			goals_list,
			unit_details,
			combat_preview,
			goal_details,
			terrain_details
		]

		for panel in panels:
			if panel.has_method("setup"):
				panel.setup(unit_manager, turn_controller, input_controller, goal_manager)

static func create_components(parent: Node) -> Components:
	var components = Components.new()

	components.round_info = RoundInfoPanel.instantiate()
	components.round_info.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	parent.add_child(components.round_info)

	components.goals_list = GoalsListPanel.instantiate()
	components.goals_list.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	components.goals_list.position += Vector2(220, 0)
	parent.add_child(components.goals_list)

	components.unit_details = UnitDetailsPanel.instantiate()
	components.unit_details.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	parent.add_child(components.unit_details)

	components.combat_preview = CombatPreviewPanel.instantiate()
	components.combat_preview.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	parent.add_child(components.combat_preview)

	components.goal_details = GoalDetailsPanel.instantiate()
	components.goal_details.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	parent.add_child(components.goal_details)

	components.terrain_details = TerrainDetailsPanel.instantiate()
	components.terrain_details.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	parent.add_child(components.terrain_details)

	components.actions_panel = ActionsPanel.instantiate()
	components.actions_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	parent.add_child(components.actions_panel)

	components.loot_details = LootDetailsPanel.instantiate()
	components.loot_details.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	parent.add_child(components.loot_details)


	components.loot_details = LootDetailsPanel.instantiate() # Added
	components.loot_details.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT) # Adjust preset as needed
	parent.add_child(components.loot_details)

	return components
