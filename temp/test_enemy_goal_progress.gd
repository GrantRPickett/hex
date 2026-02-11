extends SceneTree
const locationManager := preload("res://Gameplay/location_manager.gd")
const location := preload("res://Gameplay/location.gd")
const locationDefinition := preload("res://Resources/location_definition.gd")
const locationStep := preload("res://Resources/location_step.gd")
const Unit := preload("res://Gameplay/unit.gd")
func _init():
	var gm: locationManager = locationManager.new()
	var location: location = location.new()
	var def := locationDefinition.new()
	var step := locationStep.new()
	step.required_amount = 3
	step.required_attribute = "grit"
	def.steps.append(step)
	location.definition = def
	gm.setup([Vector2i.ZERO], [location], null)
	var enemy: Unit = Unit.new()
	enemy.faction = Unit.Faction.ENEMY
	gm.apply_progress(0, enemy)
	gm.apply_progress(0, enemy)
	var progress := gm.get_progress(0, Unit.Faction.ENEMY)
	print("enemy progress=", progress)
	quit()
