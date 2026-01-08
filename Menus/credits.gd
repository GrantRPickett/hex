extends Control

const TITLE_SCENE_PATH := "res://Menus/title_screen.tscn"

var return_delay := 10.0
var _timer_token := 0 # avoids holding timers alive while ignoring stale callbacks

func _ready() -> void:
	_start_timer()

func set_return_delay(delay: float) -> void:
	return_delay = delay
	_start_timer()

func _start_timer() -> void:
	_timer_token += 1
	var token := _timer_token
	var timer := get_tree().create_timer(return_delay)
	timer.timeout.connect(Callable(self, "_on_return_timeout").bind(token))

func _on_return_timeout(token: int) -> void:
	if token != _timer_token:
		return
	get_tree().change_scene_to_file(TITLE_SCENE_PATH)
