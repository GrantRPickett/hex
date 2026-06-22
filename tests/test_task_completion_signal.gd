# test_task_completion_signal.gd
extends GdUnitTestSuite

func test_task_completed_signal_handling() -> void:
	var task := Task.new()
	task.id = &"test_task"
	
	var objective := Objective.new()
	
	var journal_manager = load("res://Autoloads/journal_manager.gd").new()
	var stage = Stage.new()
	
	# Connect signals like they are in the real code
	task.completed.connect(journal_manager._on_task_completed_signal.bind(task, objective))
	task.completed.connect(stage._on_task_completed.bind(task))
	
	# This should NOT crash now
	task.completed.emit(GameConstants.Faction.PLAYER, null, task.id)
	
	# Cleanup
	task.free()
	objective.free()
	journal_manager.free()
	stage.free()
