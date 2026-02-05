extends SceneTree
const Unit := preload("res://Gameplay/unit.gd")
const Goal := preload("res://Gameplay/goal.gd")
const GoalManager := preload("res://Gameplay/goal_manager.gd")
const GoalDefinition := preload("res://Resources/goal_definition.gd")
const GoalStep := preload("res://Resources/goal_step.gd")
const ActionPointsComponent := preload("res://Gameplay/components/action_points_component.gd")
func _init():
	var grid := TileMapLayer.new()
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(16,16)
	grid.tile_set = tileset
	var goal_coord := Vector2i(0,0)
	var goal := Goal.new()
	goal.coord = goal_coord
	var def := GoalDefinition.new()
	var step := GoalStep.new()
	step.required_amount = 2
	step.required_attribute = "grit"
	def.steps.append(step)
	goal.definition = def
	var gm := GoalManager.new()
	gm.setup([goal_coord], [goal], grid)
	var unit := Unit.new()
	unit.grid_map = grid
	unit.position = grid.map_to_local(goal_coord)
	unit.set_goal_manager(gm)
	unit._action_points = ActionPointsComponent.new()
	unit._action_points.set_actions(1)
	unit.faction = Unit.Faction.ENEMY
	var worked := unit.work_on_goal(goal)
	print("worked=", worked)
	print("enemy=", gm.get_progress(0, Unit.Faction.ENEMY))
	print("player=", gm.get_progress(0, Unit.Faction.PLAYER))
	quit()
