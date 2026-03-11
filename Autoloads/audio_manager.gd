#class_name AudioManager
extends Node

## Centralized audio manager that triggers SFX based on EventBus signals.
## Decouples gameplay logic from audio implementation.

const DEFAULT_BUS := "SFX"
const MAX_SFX_PLAYERS := 12

# Map of sound IDs to their target audio buses
const BUS_MAP := {
	# Combat (SFX)
	"unit_attack": "SFX",
	"unit_damage": "SFX",
	"unit_death": "SFX",
	"unit_move": "SFX",
	"loot_collect": "SFX",
	"morale_critical_unit": "SFX",
	"morale_critical_faction": "SFX",
	
	# UI & Progression (UI)
	"turn_change": "UI",
	"round_change": "UI",
	"objective_start": "UI",
	"objective_complete": "UI",
	"objective_fail": "UI",
	"task_complete": "UI",
	"task_fail": "UI",
	"stage_complete": "UI",
	"level_start": "UI",
	"level_complete": "UI",
	"level_fail": "UI",
	"item_equip": "UI",
	"item_unequip": "UI",
	"checkpoint": "UI",
	"undo": "UI",
	"redo": "UI",
	"ui_click": "UI",
	"ui_hover": "UI",
	"journal_unlock": "UI",
	
	# Weather (Environment)
	"weather_change": "Environment",
	"weather_effect": "Environment",
	
	# Dialogue (Narrative)
	"dialogue_start": "Narrative",
	"dialogue_end": "Narrative"
}

var _sfx_players: Array[AudioStreamPlayer] = []
var _current_player_index := 0

func _ready() -> void:
	_setup_sfx_pool()
	_connect_to_event_bus()
	print_debug("[AudioManager] Ready and listening to EventBus.")

func _setup_sfx_pool() -> void:
	for i in range(MAX_SFX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.bus = DEFAULT_BUS
		add_child(player)
		_sfx_players.append(player)

func _connect_to_event_bus() -> void:
	if not EventBus:
		push_warning("[AudioManager] EventBus not found.")
		return

	# Combat
	EventBus.unit_attacked.connect(func(_a, _t): play_sfx("unit_attack"))
	EventBus.unit_damaged.connect(func(_t, _am, _s): play_sfx("unit_damage"))
	EventBus.unit_died.connect(func(_u): play_sfx("unit_death"))
	EventBus.unit_moved.connect(func(_u, _c): play_sfx("unit_move"))
	
	# Turn / Round
	EventBus.turn_changed.connect(func(_n, _s): play_sfx("turn_change"))
	EventBus.round_changed.connect(func(_n): play_sfx("round_change"))
	
	# Progression
	EventBus.objective_started.connect(func(_id): play_sfx("objective_start"))
	EventBus.objective_completed.connect(func(_id): play_sfx("objective_complete"))
	EventBus.objective_failed.connect(func(_id): play_sfx("objective_fail"))
	EventBus.task_completed.connect(func(_id): play_sfx("task_complete"))
	EventBus.task_failed.connect(func(_id): play_sfx("task_fail"))
	EventBus.stage_completed.connect(func(_id): play_sfx("stage_complete"))
	
	# Narrative
	EventBus.dialogue_started.connect(func(_id): play_sfx("dialogue_start"))
	EventBus.dialogue_finished.connect(func(_id): play_sfx("dialogue_end"))
	
	# Gameplay Systems
	EventBus.level_started.connect(func(_id): play_sfx("level_start"))
	EventBus.level_completed.connect(func(_id): play_sfx("level_complete"))
	EventBus.level_failed.connect(func(_id): play_sfx("level_fail"))
	EventBus.loot_collected.connect(func(_n): play_sfx("loot_collect"))
	EventBus.item_equipped.connect(func(_u, _i): play_sfx("item_equip"))
	EventBus.item_unequipped.connect(func(_u, _i): play_sfx("item_unequip"))
	EventBus.checkpoint_created.connect(func(): play_sfx("checkpoint"))
	EventBus.undo_performed.connect(func(): play_sfx("undo"))
	EventBus.redo_performed.connect(func(): play_sfx("redo"))
	
	# UI
	EventBus.ui_button_pressed.connect(func(): play_sfx("ui_click"))
	EventBus.ui_hover_triggered.connect(func(): play_sfx("ui_hover"))
	
	# Manual Triggers
	EventBus.audio_trigger_requested.connect(play_sfx)
	
	# Weather
	EventBus.weather_changed.connect(func(_attr): play_sfx("weather_change"))
	EventBus.weather_effect_applied.connect(func(_info): play_sfx("weather_effect"))
	
	# Morale
	EventBus.unit_willpower_critical.connect(func(_u): play_sfx("morale_critical_unit"))
	EventBus.faction_willpower_critical.connect(func(_f): play_sfx("morale_critical_faction"))

## Plays a sound effect by ID. Currently using placeholders.
func play_sfx(sound_id: String) -> void:
	var target_bus = BUS_MAP.get(sound_id, DEFAULT_BUS)
	
	# Placeholder logic: Log the trigger
	# print_debug("[AudioManager] Triggering SFX: ", sound_id, " on bus: ", target_bus)
	
	# In the future, this would map sound_id to an AudioStream resource
	# var stream = _sound_map.get(sound_id)
	# if stream:
	#	 var player = _get_next_player()
	#	 player.bus = target_bus
	#	 player.stream = stream
	#	 player.play()
	pass

func _get_next_player() -> AudioStreamPlayer:
	var player = _sfx_players[_current_player_index]
	_current_player_index = (_current_player_index + 1) % MAX_SFX_PLAYERS
	return player
