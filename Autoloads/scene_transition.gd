#class_name SceneTransition
extends Node

signal scene_change_requested(path)
signal scene_change_completed(path)

@export var default_delay := 0.0

enum State { IDLE, CHANGING, FAILED }

var state: State = State.IDLE
var _current_target: String = ""

func change_scene(path: String, delay := -1.0, emit_signal_only := false) -> bool:
	var effective_delay := default_delay
	if delay >= 0.0:
		effective_delay = delay
	var target := String(path).strip_edges()

	# Emit signal for listeners
	##print_debug("DBG SceneTransition.request path=", target, " emit_only=", emit_signal_only)
	emit_signal("scene_change_requested", target)

	# If only emitting signal, complete here
	if emit_signal_only:
		await get_tree().process_frame
		return true

	# Check if already changing
	if state != State.IDLE:
		##print_debug("DBG SceneTransition.change_scene ignored: already changing (state=%d, target=%s)" % [state, _current_target])
		await get_tree().process_frame
		return false

	state = State.CHANGING
	_current_target = target

	# Apply delay if specified
	if effective_delay > 0.0:
		await get_tree().create_timer(effective_delay).timeout

	# Perform actual scene change
	##print_debug("DBG SceneTransition.execute_change to=", target)
	get_tree().change_scene_to_file(target)

	# Wait for confirmation (max 10 frames)
	var confirmed := false
	for i in range(10):
		await get_tree().process_frame
		var cur := get_tree().current_scene
		if cur and cur.scene_file_path == target:
			##print_debug("DBG SceneTransition.change_scene confirmed target=", target)
			confirmed = true
			break

	if not confirmed:
		var _cur_path := "<none>"
		var cur2 := get_tree().current_scene
		if cur2:
			_cur_path = cur2.scene_file_path
		##print_debug("DBG SceneTransition.change_scene did not confirm target after frames, current=", _cur_path)
		state = State.FAILED
		return false

	state = State.IDLE
	emit_signal("scene_change_completed", target)
	return true

func reload_current(emit_signal_only := false) -> bool:
	var tree := get_tree()
	var current := tree.current_scene
	if current and current.scene_file_path != "":
		return await change_scene(current.scene_file_path, 0.0, emit_signal_only)
	return false

func is_changing() -> bool:
	return state == State.CHANGING
