extends GdUnitTestSuite

const TaskProcessor = preload("res://Gameplay/narrative/task/task_processor.gd")

func test_task_progress_floors_at_zero() -> void:
    var unit = auto_free(Unit.new())
    unit.grit = 1
    
    var location = auto_free(Target.new())
    location.grit = 1 # Match unit grit
    
    var task = auto_free(Task.new())
    task.event_type = GameConstants.TaskEvents.EXPLORE
    task.is_opposed = true # Should be irrelevant now as we always subtract
    
    var data = {
        "unit": unit,
        "target": location,
        "attribute": GameConstants.AttributeIndex.GRIT
    }
    
    var progress = TaskProcessor.calculate_event_progress(task, unit, data, GameConstants.TaskEvents.EXPLORE)
    assert_int(progress).is_equal(0)
    
    unit.grit = 2
    progress = TaskProcessor.calculate_event_progress(task, unit, data, GameConstants.TaskEvents.EXPLORE)
    assert_int(progress).is_equal(1)

func test_unopposed_is_no_counter_but_still_difficulty_check() -> void:
    # Per user: "unopposed means no reaction counter attack not guarnteed sucess"
    # This means TaskProcessor should still subtract defense.
    var unit = auto_free(Unit.new())
    unit.grit = 5
    
    var location = auto_free(Target.new())
    location.grit = 10
    
    var task = auto_free(Task.new())
    task.id = "test_task"
    task.is_opposed = false
    
    var data = {
        "unit": unit,
        "target": location,
        "attribute": GameConstants.AttributeIndex.GRIT
    }
    
    var progress = TaskProcessor.calculate_event_progress(task, unit, data, GameConstants.TaskEvents.EXPLORE)
    # 5 - 10 = -5 -> floor 0
    assert_int(progress).is_equal(0)

func test_loot_and_location_difficulty() -> void:
    # Verify that Loot and Location (Targets) also follow the rule
    var unit = auto_free(Unit.new())
    unit.grit = 1
    
    var loot = auto_free(Loot.new())
    loot.grit = 1 # Default from Target.gd is 1
    
    var task = auto_free(Task.new())
    task.event_type = GameConstants.TaskEvents.LOOT
    
    var data = {
        "unit": unit,
        "target": loot,
        "attribute": GameConstants.AttributeIndex.GRIT
    }
    
    var progress = TaskProcessor.calculate_event_progress(task, unit, data, GameConstants.TaskEvents.LOOT)
    assert_int(progress).is_equal(0) # 1 - 1 = 0
    
    unit.grit = 2
    progress = TaskProcessor.calculate_event_progress(task, unit, data, GameConstants.TaskEvents.LOOT)
    assert_int(progress).is_equal(1) # 2 - 1 = 1

