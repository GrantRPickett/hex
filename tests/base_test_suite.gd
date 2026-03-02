# Base test suite providing common setup/teardown and helper methods.
# Inherit from this class to avoid repeat test setup and modular reusability.

extends GdUnitTestSuite

const Stubs := preload("res://tests/fixtures/test_stubs.gd")
const Factory := preload("res://tests/fixtures/test_factory.gd")

var _managed_autoloads: Array[Node] = []

# --- Common Helper Methods ---

func assert_eq(actual, expected, message: String = ""):
	var processed_actual = actual
	var processed_expected = expected

	if typeof(actual) == TYPE_STRING or typeof(actual) == TYPE_STRING_NAME:
		processed_actual = str(actual).strip_edges()

	if typeof(expected) == TYPE_STRING or typeof(expected) == TYPE_STRING_NAME:
		processed_expected = str(expected).strip_edges()

	if message != "":
		assert_that(processed_actual).override_failure_message(message).is_equal(processed_expected)
	else:
		assert_that(processed_actual).is_equal(processed_expected)

func _simulate_frames(runner: GdUnitSceneRunner, frames: int = 1) -> void:
	await runner.simulate_frames(frames)

func _create_scene_runner(scene_path: String) -> GdUnitSceneRunner:
	return scene_runner(scene_path)

# --- Autoload & Manager Setup ---

const REQUIRED_AUTOLOADS := {
	"DisplaySettings": "res://Autoloads/display_settings.gd",
}

func ensure_manager(
	manager_name: String,
	path: String,
	override_instance: Node = null
) -> Node:
	# Ensures a manager-like singleton exists during tests.
	var tree := get_tree()
	assert(tree != null)

	var root := tree.root
	assert(root != null)

	# Allow explicit override (mocks)
	if override_instance != null:
		override_instance.name = manager_name
		if root.has_node(manager_name):
			root.get_node(manager_name).queue_free()
		root.add_child(override_instance)
		await tree.process_frame
		return override_instance

	# Already exists (normal autoload case)
	if root.has_node(manager_name):
		return root.get_node(manager_name)

	# Create fallback instance (test-safe autoload)
	var res := load(path)
	assert(res != null)

	var node: Node
	if res is PackedScene:
		node = (res as PackedScene).instantiate()
	elif res is Script:
		node = (res as Script).new()
	else:
		push_error("Unsupported resource type for %s" % path)
		return null

	node.name = manager_name
	root.add_child(node)

	# One frame to avoid Nil access from _ready timing
	await tree.process_frame
	return node

func setup_autoloads(autoload_configs: Dictionary) -> Dictionary:
	var merged := REQUIRED_AUTOLOADS.duplicate()
	for key in autoload_configs.keys():
		merged[key] = autoload_configs[key]
	var instances = {}
	var root = get_tree().root

	for aname in merged.keys():
		var path = merged[aname]
		if root.has_node(aname):
			instances[aname] = root.get_node(aname)
		else:
			var instance = await ensure_manager(aname, path)
			instances[aname] = instance
			_managed_autoloads.append(instance)
	return instances

func teardown_autoloads() -> void:
	for instance in _managed_autoloads:
		if is_instance_valid(instance):
			instance.queue_free()
	_managed_autoloads.clear()
	await get_tree().process_frame

func after_test() -> void:
	await teardown_autoloads()

# --- Utility Methods ---

func _clear_save_game() -> void:
	var dir = DirAccess.open("user://")
	if dir.file_exists("save_game.cfg"):
		dir.remove("save_game.cfg")

static func free_tree(node: Node) -> void:
	if node == null:
		return

	# Defensive: detach first to prevent re-entrancy bugs
	if node.get_parent():
		node.get_parent().remove_child(node)

	# Walk children explicitly
	for child in node.get_children():
		free_tree(child)

	# Clear signals and references if needed
	node.free()
