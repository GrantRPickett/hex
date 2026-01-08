extends Node

signal scene_change_requested(path)

@export var default_delay := 0.0

func change_scene(path: String, delay := -1.0, execute_change := true) -> void:
	var effective_delay := default_delay if delay < 0.0 else delay
	emit_signal("scene_change_requested", path)
	if execute_change:
		if effective_delay > 0.0:
			await get_tree().create_timer(effective_delay).timeout
		get_tree().change_scene_to_file(path)
	await get_tree().process_frame

func reload_current(execute_change := true) -> void:
	var tree := get_tree()
	var current := tree.current_scene
	if current and current.scene_file_path != "":
		await change_scene(current.scene_file_path, 0.0, execute_change)
