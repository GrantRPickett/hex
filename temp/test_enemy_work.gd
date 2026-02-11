extends SceneTree
const Unit := preload("res://Gameplay/unit.gd")
const location := preload("res://Gameplay/location.gd")
const locationManager := preload("res://Gameplay/location_manager.gd")
const locationDefinition := preload("res://Resources/location_definition.gd")
const locationStep := preload("res://Resources/location_step.gd")
const ActionPointsComponent := preload("res://Gameplay/components/action_points_component.gd")
func _init():
	var grid := TileMapLayer.new()
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(16,16)
	grid.tile_set = tileset
	var location_coord := Vector2i(0,0)
	var location := location.new()
	location.coord = location_coord
	var def := locationDefinition.new()
	var step := locationStep.new()
	step.required_amount = 2
	step.required_attribute = "grit"
	def.steps.append(step)
	location.definition = def
	var gm := locationManager.new()
	gm.setup([location_coord], [location], grid)
	var unit := Unit.new()
	unit.grid_map = grid
	unit.position = grid.map_to_local(location_coord)
	unit.set_location_manager(gm)
	unit._action_points = ActionPointsComponent.new()
	unit._action_points.set_actions(1)
	unit.faction = Unit.Faction.ENEMY
	var worked := unit.work_on_location(location)
	print("worked=", worked)
	print("enemy=", gm.get_progress(0, Unit.Faction.ENEMY))
	print("player=", gm.get_progress(0, Unit.Faction.PLAYER))
	quit()
