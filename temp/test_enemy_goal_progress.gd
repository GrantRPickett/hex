extends SceneTree
const GoalManager := preload("res://Gameplay/goal_manager.gd")
const Goal := preload("res://Gameplay/goal.gd")
const GoalDefinition := preload("res://Resources/goal_definition.gd")
const GoalStep := preload("res://Resources/goal_step.gd")
const Unit := preload("res://Gameplay/unit.gd")
func _init():
	var gm: GoalManager = GoalManager.new()
	var goal: Goal = Goal.new()
	var def := GoalDefinition.new()
	var step := GoalStep.new()
	step.required_amount = 3
	step.required_attribute = "grit"
	def.steps.append(step)
	goal.definition = def
	gm.setup([Vector2i.ZERO], [goal], null)
	var enemy: Unit = Unit.new()
	enemy.faction = Unit.Faction.ENEMY
	gm.apply_progress(0, enemy)
	gm.apply_progress(0, enemy)
	var progress := gm.get_progress(0, Unit.Faction.ENEMY)
	print("enemy progress=", progress)
	quit()
