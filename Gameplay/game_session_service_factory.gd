
class_name GameSessionServiceFactory
extends RefCounted

func create_services() -> GameSessionServices:
	return GameSessionServices.new()
