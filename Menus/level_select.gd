extends Control

signal back_requested

@onready var _list: VBoxContainer = $Panel/VBox/List

func _ready() -> void:
	set_process_unhandled_input(true)
	_populate_levels()

func _populate_levels() -> void:
	var paths: Array[String] = []
	if Engine.has_singleton("LevelManager") and LevelManager.levels.size() > 0:
		paths = LevelManager.levels.duplicate()
	else:
		paths = _scan_level_paths()
	var entries: Array[Dictionary] = []
	for p: String in paths:
		var name: String = p.get_file()
		var res: Resource = load(p)
		if res and res.has_method("get"):
			var dn = res.get("display_name")
			if typeof(dn) == TYPE_STRING and dn != "":
				name = dn
		entries.append({"path": p, "name": name})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("name", "")).nocasecmp_to(String(b.get("name", ""))) < 0)
	for e: Dictionary in entries:
		var b := Button.new()
		b.text = String(e["name"]) 
		b.pressed.connect(_on_level_pressed.bind(String(e["path"])))
		_list.add_child(b)

func _scan_level_paths() -> Array[String]:
	var list: Array[String] = []
	var dir := DirAccess.open("res://Resources/levels")
	if dir:
		for f in dir.get_files():
			if f.ends_with(".tres"):
				list.append("res://Resources/levels/" + f)
	return list

func _on_back_pressed() -> void:
	back_requested.emit()
	get_tree().change_scene_to_file("res://Menus/title_screen.tscn")

func _on_level_pressed(path: String) -> void:
	if Engine.has_singleton("LevelManager") and LevelManager.has_method("set_current_level_path"):
		LevelManager.set_current_level_path(path)
	get_tree().change_scene_to_file("res://Gameplay/gameplay.tscn")
