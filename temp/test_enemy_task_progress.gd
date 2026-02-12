extends SceneTree
const LocationManager := preload("res://Gameplay/location_manager.gd")
const TargetTask := preload("res://Gameplay/target_task.gd")
const TaskDefinition := preload("res://Resources/task_definition.gd")
const TaskStep := preload("res://Resources/task_step.gd")
const Unit := preload("res://Gameplay/unit.gd")
func _init():
	var gm: LocationManager = LocationManager.new()
	var target_task: TargetTask = TargetTask.new()
	var def := TaskDefinition.new()
	var step := TaskStep.new()
	step.required_amount = 3
	step.required_attribute = "grit"
	def.steps.append(step)
	target_task.definition = def
	gm.setup([Vector2i.ZERO], [target_task], null)
	var enemy: Unit = Unit.new()
	enemy.faction = Unit.Faction.ENEMY
	gm.apply_progress(0, enemy)
	gm.apply_progress(0, enemy)
	var progress := gm.get_progress(0, Unit.Faction.ENEMY)
	print("enemy progress=", progress)
	quit()
