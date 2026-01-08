extends GdUnitTestSuite

func test_level_manager_api() -> void:
    if not Engine.has_singleton("LevelManager"):
        return
    LevelManager.set_levels(["res://Resources/levels/level1.tres", "res://Resources/levels/level2.tres"])
    LevelManager.set_current_level_path("res://Resources/levels/level1.tres")
    var path: String = LevelManager.get_current_level_path()
    assert_that(path).is_equal("res://Resources/levels/level1.tres")
