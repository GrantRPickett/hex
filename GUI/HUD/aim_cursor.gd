class_name AimCursor
extends Node2D

signal cursor_moved(screen_pos: Vector2)

@export var aim_inactivity_threshold := 0.25
@export var aim_cursor_speed := 900.0

var _virtual_cursor_pos: Vector2 = Vector2.ZERO
var _using_virtual_cursor := false
var _aim_inactivity_timer := 0.0
var _input_handler: InputHandler

class Crosshair:
	extends Node2D
	var size := 6.0
	var color := Color(1, 1, 1, 0.9)
	var thickness := 2.0
	func _draw() -> void:
		var s := size
		draw_line(Vector2(-s, 0), Vector2(-2, 0), color, thickness)
		draw_line(Vector2(2, 0), Vector2(s, 0), color, thickness)
		draw_line(Vector2(0, -s), Vector2(0, -2), color, thickness)
		draw_line(Vector2(0, 2), Vector2(0, s), color, thickness)
		draw_circle(Vector2.ZERO, 1.2, color)

var _crosshair := Crosshair.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_crosshair.visible = false
	add_child(_crosshair)

func set_initial_position(pos: Vector2) -> void:
	_virtual_cursor_pos = pos
	_update_crosshair()

func connect_input_handler(handler: InputHandler) -> void:
	_input_handler = handler
	if is_instance_valid(_input_handler):
		_input_handler.joy_aim_held.connect(_on_joy_aim_held)

func get_effective_cursor_position(fallback_mouse_pos: Vector2) -> Vector2:
	return _virtual_cursor_pos if _using_virtual_cursor else fallback_mouse_pos

func is_virtual_active() -> bool:
	return _using_virtual_cursor

func _on_joy_aim_held(axis: Vector2, delta: float) -> void:
	_using_virtual_cursor = axis.length() > 0.0
	_aim_inactivity_timer = 0.0
	var viewport := get_viewport()
	var velocity := axis * aim_cursor_speed * delta
	_virtual_cursor_pos += velocity
	if viewport:
		var rect := Rect2(Vector2.ZERO, viewport.get_visible_rect().size)
		_virtual_cursor_pos.x = clamp(_virtual_cursor_pos.x, rect.position.x, rect.end.x)
		_virtual_cursor_pos.y = clamp(_virtual_cursor_pos.y, rect.position.y, rect.end.y)
	_update_crosshair()

func _process(delta: float) -> void:
	if _using_virtual_cursor:
		_aim_inactivity_timer += delta
		if _aim_inactivity_timer > aim_inactivity_threshold:
			_using_virtual_cursor = false
	_update_crosshair()

func _update_crosshair() -> void:
	_crosshair.visible = _using_virtual_cursor
	if _crosshair.visible:
		_crosshair.position = _virtual_cursor_pos
	cursor_moved.emit(_virtual_cursor_pos)
