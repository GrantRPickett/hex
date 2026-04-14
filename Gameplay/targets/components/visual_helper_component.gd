class_name VisualHelperComponent
extends RefCounted

## Handles squash-and-stretch (S&S) and wiggle animations for Units.
## Uses tweens to ensure smooth transitions and robust reset logic.

var _unit: Unit
var _sprite: Sprite2D
var _ss_tween: Tween
var _wiggle_tween: Tween

const SS_DURATION := 0.8
const SS_SCALE_X := 1.05
const SS_SCALE_Y := 0.95
const WIGGLE_DURATION := 0.4
const WIGGLE_ROTATION := 0.1 # Radians
const WIGGLE_SCALE := 1.1

func _init(p_unit: Unit) -> void:
	_unit = p_unit
	if _unit.is_node_ready():
		_setup_sprite()
	else:
		_unit.ready.connect(_setup_sprite)

func _setup_sprite() -> void:
	_sprite = _unit.get_node_or_null("Sprite2D")
	if not _sprite:
		# Fallback to finding first Sprite2D child
		for child in _unit.get_children():
			if child is Sprite2D:
				_sprite = child
				break

func start_squash_stretch() -> void:
	if not is_instance_valid(_sprite):
		return
	
	stop_squash_stretch()
	
	_ss_tween = _unit.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_ss_tween.tween_property(_sprite, "scale", Vector2(SS_SCALE_X, SS_SCALE_Y) * 2.0, SS_DURATION)
	_ss_tween.tween_property(_sprite, "scale", Vector2(SS_SCALE_Y, SS_SCALE_X) * 2.0, SS_DURATION)
	# Note: Sprite scale is 2.0 by default in Unit.gd, adjust if necessary

func stop_squash_stretch() -> void:
	if _ss_tween and _ss_tween.is_valid():
		_ss_tween.kill()
	_ss_tween = null
	_reset_transforms()

func trigger_wiggle() -> void:
	if not is_instance_valid(_sprite):
		return
	
	if _wiggle_tween and _wiggle_tween.is_valid():
		return # Already wiggling
	
	_wiggle_tween = _unit.create_tween().set_loops(3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	# Wiggle rotation
	_wiggle_tween.tween_property(_sprite, "rotation", WIGGLE_ROTATION, WIGGLE_DURATION * 0.25)
	_wiggle_tween.tween_property(_sprite, "rotation", -WIGGLE_ROTATION, WIGGLE_DURATION * 0.5)
	_wiggle_tween.tween_property(_sprite, "rotation", 0.0, WIGGLE_DURATION * 0.25)
	
	_wiggle_tween.finished.connect(func(): _wiggle_tween = null)

func stop_wiggle() -> void:
	if _wiggle_tween and _wiggle_tween.is_valid():
		_wiggle_tween.kill()
	_wiggle_tween = null
	_reset_transforms()

func _reset_transforms() -> void:
	if is_instance_valid(_sprite):
		# Default scale in Unit.gd is Vector2(2, 2)
		_sprite.scale = Vector2(2, 2)
		_sprite.rotation = 0.0
