class_name GameCommandContext
extends RefCounted

var unit_manager
var hex_navigator
var camera_controller
var move_controller
var turn_controller
var goal_controller
var grid

func _init(
	unit_manager,
	hex_navigator,
	camera_controller,
	move_controller,
	turn_controller,
	goal_controller,
	grid
) -> void:
	self.unit_manager = unit_manager
	self.hex_navigator = hex_navigator
	self.camera_controller = camera_controller
	self.move_controller = move_controller
	self.turn_controller = turn_controller
	self.goal_controller = goal_controller
	self.grid = grid



