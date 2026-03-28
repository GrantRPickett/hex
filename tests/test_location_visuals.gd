extends GdUnitTestSuite

func test_location_visual_state_persistence() -> void:
    var location = auto_free(Location.new())
    location.is_explored = false
    # Mocking task manager since Location calls it in update_visuals
    var task_manager = auto_free(TaskManager.new())
    location.set_task_manager(task_manager)
    
    # CASE 1: Not explored
    location.mark_explored()
    assert_that(location.is_explored).is_true()
    
    # Even if there's no task, it should show as open (Rect2(96, 512, 32, 32))
    assert_that(location.sprite.region_rect).is_equal(Rect2(96, 512, 32, 32))

func test_location_visual_with_and_without_task() -> void:
    var location = auto_free(Location.new())
    # New logic: open if (is_explored or has_task)
    
    location.is_explored = false
    # If no task manager, has_task is false
    location.update_visuals()
    assert_that(location.sprite.region_rect).is_equal(Rect2(64, 512, 32, 32)) # Shut
    
    location.is_explored = true
    # Should open now
    assert_that(location.sprite.region_rect).is_equal(Rect2(96, 512, 32, 32))
