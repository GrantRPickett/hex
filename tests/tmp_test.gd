@tool
extends SceneTree

func _init():
	var test = load("res://tests/test_ai_attack_evaluator.gd").new()
	test.test_evaluate_returns_attack_for_adjacent_enemy()
	print("Success")
	quit()
