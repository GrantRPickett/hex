# Base test suite providing common setup/teardown and helper methods.
# Inherit from this class to avoid repeat test setup and modular reusability.

class_name HexTestUtils extends RefCounted

const Stubs := preload("res://tests/fixtures/test_stubs.gd")
const Factory := preload("res://tests/fixtures/test_factory.gd")

static var _managed_autoloads: Array[Node] = []

# --- Common Helper Methods ---

static func assert_eq(test_suite: Node, actual, expected, message: String = ""):
	var processed_actual = actual
	var processed_expected = expected

	if typeof(actual) == TYPE_STRING or typeof(actual) == TYPE_STRING_NAME:
		processed_actual = str(actual).strip_edges()

	if typeof(expected) == TYPE_STRING or typeof(expected) == TYPE_STRING_NAME:
		processed_expected = str(expected).strip_edges()

	if message != "":
		test_suite.assert_that(processed_actual).override_failure_message(message).is_equal(processed_expected)
	else:
		test_suite.assert_that(processed_actual).is_equal(processed_expected)

static func _simulate_frames(runner: GdUnitSceneRunner, frames: int = 1) -> void:
	await runner.simulate_frames(frames)

static func _create_scene_runner(test_suite: Node, scene_path: String) -> GdUnitSceneRunner:
	return test_suite.scene_runner(scene_path)

# --- Autoload & Manager Setup ---

const REQUIRED_AUTOLOADS := {
	"DisplaySettings": "res://Autoloads/display_settings.gd",
}

static func ensure_manager(
	tree: SceneTree,
	manager_name: String,
	path: String,
	override_instance: Node = null
) -> Node:
	# Ensures a manager-like singleton exists during tests.
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

static func setup_autoloads(tree: SceneTree, autoload_configs: Dictionary) -> Dictionary:
	var merged := REQUIRED_AUTOLOADS.duplicate()
	for key in autoload_configs.keys():
		merged[key] = autoload_configs[key]
	var instances = {}
	var root = tree.root

	for aname in merged.keys():
		var path = merged[aname]
		if root.has_node(aname):
			instances[aname] = root.get_node(aname)
		else:
			var instance = await ensure_manager(tree, aname, path)
			instances[aname] = instance
			if not _managed_autoloads.has(instance):
				_managed_autoloads.append(instance)
	return instances

static func teardown_autoloads(tree: SceneTree) -> void:
	for instance in _managed_autoloads:
		if is_instance_valid(instance):
			instance.queue_free()
	_managed_autoloads.clear()
	await tree.process_frame

# --- Utility Methods ---

static func _clear_save_game() -> void:
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

static func _mock_unit(test_suite: Node, unit_name: String = "Mock Unit", faction: int = 0) -> Unit:
	var unit = Factory.create_unit(unit_name, faction)
	test_suite.add_child(unit)
	return unit
