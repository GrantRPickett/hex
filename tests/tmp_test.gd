@tool
extends SceneTree

func _init():
	var test: Resource = load("res://tests/test_ai_attack_evaluator.gd").new()
	test.test_evaluate_returns_attack_for_near_enemy()
	print("Success")
	quit()
