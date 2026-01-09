extends Node

@export var levels: Array = []
var current_index: int = -1
var _current_level_path: String = ""
const GAMEPLAY_SCENE := "res://Gameplay/gameplay.tscn"
const TITLE_SCENE := "res://Menus/title_screen.tscn"
const CREDITS_SCENE := "res://Menus/credits.tscn"

func set_levels(list: Array) -> void:
    levels = list.duplicate()
    current_index = -1

func set_current_level_path(path: String) -> void:
    _current_level_path = path
    current_index = levels.find(path)

func get_current_level_path() -> String:
    return _current_level_path

func _ready() -> void:
    get_tree().scene_changed.connect(_on_scene_changed)
    # Ensure we attach to the currently running scene if present
    _on_scene_changed()

func _on_scene_changed() -> void:
    var scene := get_tree().current_scene
    if scene == null:
        return
    if scene.has_signal("level_complete"):
        scene.disconnect("level_complete", Callable(self, "_on_level_complete"))
        scene.level_complete.connect(_on_level_complete)
    if scene.has_signal("quit_to_title"):
        scene.disconnect("quit_to_title", Callable(self, "_on_quit_to_title"))
        scene.quit_to_title.connect(_on_quit_to_title)

func _on_quit_to_title() -> void:
    print_debug("DBG level_manager _on_quit_to_title called")
    if Engine.has_singleton("SceneTransition"):
        if SceneTransition.is_changing():
            print_debug("DBG level_manager _on_quit_to_title ignored: already changing")
            return
        await SceneTransition.change_scene(TITLE_SCENE)
    else:
        get_tree().change_scene_to_file(TITLE_SCENE)

func _on_level_complete(next_level_path: String) -> void:
    if Engine.has_singleton("SceneTransition") and SceneTransition.is_changing():
        return

    var chosen_path := ""
    if next_level_path and next_level_path != "":
        chosen_path = String(next_level_path).strip_edges()
    elif current_index >= 0 and current_index + 1 < levels.size():
        chosen_path = String(levels[current_index + 1])

    if chosen_path != "":
        set_current_level_path(chosen_path)
        if Engine.has_singleton("SceneTransition"):
            await SceneTransition.change_scene(GAMEPLAY_SCENE)
        else:
            get_tree().change_scene_to_file(GAMEPLAY_SCENE)
        return

    if Engine.has_singleton("SceneTransition"):
        await SceneTransition.change_scene(CREDITS_SCENE)
    else:
        get_tree().change_scene_to_file(CREDITS_SCENE)
