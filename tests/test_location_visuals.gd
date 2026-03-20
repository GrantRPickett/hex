extends GdUnitTestSuite

const LocationScript := preload("res://Gameplay/targets/location.gd")
const TaskManagerScript := preload("res://Gameplay/narrative/task/task_manager.gd")
const TaskScript := preload("res://Gameplay/narrative/task/task.gd")

var _location: Location
var _task_manager: TaskManager

func before_test() -> void:
	_location = LocationScript.new()
	_location.name = "TestLocation"
	_location.location_icon = load("res://Resources/art/placeholder/32rogues/tiles.png")
	get_tree().root.add_child(_location)
	
	_task_manager = TaskManagerScript.new()
	auto_free(_task_manager)

func after_test() -> void:
	if is_instance_valid(_location):
		_location.queue_free()

func test_initial_state_is_closed() -> void:
	_location.set_task_manager(_task_manager)
	assert_bool(_location.sprite.region_enabled).is_true()
	assert_bool(_location.sprite.region_rect == Rect2(64, 512, 32, 32)).is_true()

func test_texture_opens_when_task_present() -> void:
	# Mock TaskManager returning a task
	# We can use a subclass or just set the state if TaskManager was more flexible.
	# Since TaskManager is complex, let's just mock the method we care about.
	
	var mock_tm = mock(TaskManagerScript)
	var fake_task = TaskScript.new()
	auto_free(fake_task)
	do_return([fake_task]).on(mock_tm).get_active_tasks_for_target(_location)
	
	_location.set_task_manager(mock_tm)
	assert_bool(_location.sprite.region_rect == Rect2(96, 512, 32, 32)).is_true()

func test_texture_closes_when_task_removed() -> void:
	var mock_tm = mock(TaskManagerScript)
	var fake_task = TaskScript.new()
	auto_free(fake_task)
	
	# Initially has task
	do_return([fake_task]).on(mock_tm).get_active_tasks_for_target(_location)
	_location.set_task_manager(mock_tm)
	assert_bool(_location.sprite.region_rect == Rect2(96, 512, 32, 32)).is_true()
	
	# Now no task
	do_return([]).on(mock_tm).get_active_tasks_for_target(_location)
	_location.update_visuals()
	assert_bool(_location.sprite.region_rect == Rect2(64, 512, 32, 32)).is_true()
