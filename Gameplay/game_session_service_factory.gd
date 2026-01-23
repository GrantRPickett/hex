
class_name GameSessionServiceFactory
extends RefCounted
const GameSessionServices := preload("res://Gameplay/game_session_services.gd")

func create_services() -> GameSessionServices:
	return GameSessionServices.new()
