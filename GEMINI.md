# Godot Project Engineering Standards

## Testing Mandates (GDUnit4)

- **Setup/Teardown:** Always use `before_test()` for per-test setup and `after_test()` for teardown. Do NOT use `before()`.
- **Memory Management:** Use `auto_free(instance)` for all `RefCounted` or `Node` instances created within tests to prevent orphan nodes and memory leaks.
- **Scene Tree:** If a Node or Service uses `get_tree()`, it MUST be added to the scene tree during the test using `add_child(node)` or `get_tree().root.add_child(node)`.
- **Pathing:** Favor `res://` paths over `uid://` (UIDs) in `project.godot` and test files to ensure reliability in headless/CLI environments.
- **Robustness:** Always use `is_instance_valid(object)` before accessing properties or methods on objects that might have been freed (e.g., in `UnitManager` or signal callbacks).

