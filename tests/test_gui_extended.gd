extends GdUnitTestSuite

# Test suite covering GUI element uncovered functions

func _add_and_free(node: Node) -> Node:
	add_child(node)
	return auto_free(node)

# --- ActionsPanel ---
const ActionsPanelScript = preload("res://GUI/actions_panel.gd")

func test_action_panel_focus_first_button() -> void:
	var p = ActionsPanelScript.new()
	var vbox = VBoxContainer.new()
	vbox.name = "ActionsContainer"
	p.add_child(vbox)
	p.actions_container = vbox
	_add_and_free(p)

	# Empty container
	assert_bool(p.focus_first_button()).is_false()

	# Add label (no focus)
	vbox.add_child(Label.new())
	assert_bool(p.focus_first_button()).is_false()

	# Add button
	var btn = Button.new()
	vbox.add_child(btn)
	assert_bool(p.focus_first_button()).is_true()

func test_action_panel_update_actions_missing_unit() -> void:
	var p = ActionsPanelScript.new()
	var vbox = VBoxContainer.new()
	vbox.name = "ActionsContainer"
	p.add_child(vbox)
	p.actions_container = vbox

	var label = Label.new()
	label.name = "HintLabel"
	p.add_child(label)
	p.hint_label = label
	_add_and_free(p)

	# Needs to be inside tree for ready to actually run, but update calls manually
	var um = UnitManager.new()
	p.update_actions(null, {}, um)

	assert_str(label.text).is_equal("No unit selected")
	um.free()

# --- CombatPreviewPanel ---
const CombatPreviewScript = preload("res://GUI/combat_preview_panel.gd")

func test_combat_preview_panel_show_forecast() -> void:
	var p = CombatPreviewScript.new()
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	p.add_child(vbox)

	var l1 = Label.new()
	l1.name = "AttackerLabel"
	vbox.add_child(l1)
	var l2 = Label.new()
	l2.name = "DefenderLabel"
	vbox.add_child(l2)
	var l3 = Label.new()
	l3.name = "ForecastLabel"
	vbox.add_child(l3)

	p._vbox = vbox
	p._attacker_label = l1
	p._defender_label = l2
	p._forecast_label = l3
	_add_and_free(p)

	var atk = Unit.new()
	atk.unit_name = "Player"
	var def = Location.new()
	def.loc_name = "Base"

	p.show_preview(atk, def)
	assert_str(l1.text).contains("Player")
	assert_str(l2.text).contains("Base")
	assert_str(l3.text).contains("Hover")

	p.show_forecast(atk, def, {"damage_to_target": 10, "counter_damage_to_self": 2})
	assert_str(l3.text).contains("10")
	assert_str(l3.text).contains("2")

	p.hide_preview()
	assert_bool(p.visible).is_false()

	atk.queue_free()
	def.queue_free()

# --- FeedbackDisplay ---
const FeedbackDisplayScript = preload("res://GUI/feedback_display.gd")

func test_feedback_display_show_feedback() -> void:
	var fd = FeedbackDisplayScript.new()
	var hud = Control.new()
	_add_and_free(hud)

	fd.show_feedback("Test Message", hud)

	var label = hud.get_child(0) as Label
	assert_object(label).is_not_null()
	assert_str(label.text).is_equal("Test Message")

# --- JournalUI ---
const JournalUIScript = preload("res://GUI/journal_ui.gd")

func test_journal_ui_find_item() -> void:
	var ui = JournalUIScript.new()
	_add_and_free(ui)
	var list = ItemList.new()
	list.add_item("Test1")
	list.set_item_metadata(0, "val1")
	list.add_item("Test2")
	list.set_item_metadata(1, "val2")

	assert_int(ui.find_item_by_metadata(list, "val2")).is_equal(1)
	assert_int(ui.find_item_by_metadata(list, "missing")).is_equal(-1)
	list.queue_free()

# --- Lists and Items ---
const LocationListScript = preload("res://GUI/locations_list_panel.gd")
const TaskListScript = preload("res://GUI/tasks_list_panel.gd")
const LocationDisplayScript = preload("res://GUI/location_display_item.gd")
const TaskDisplayScript = preload("res://GUI/task_display_item.gd")
const TaskListItemScript = preload("res://GUI/task_list_item.gd")

func test_location_display_item() -> void:
	var item = LocationDisplayScript.new()
	var l1 = Label.new()
	l1.name = "NameLabel"
	item.add_child(l1)
	var l2 = Label.new()
	l2.name = "DescriptionLabel"
	item.add_child(l2)
	_add_and_free(item)

	item._ready()
	item.set_location_data({"name": "Town", "description": "A place"})
	assert_str(l1.text).is_equal("Town")
	assert_str(l2.text).is_equal("A place")

func test_task_display_item() -> void:
	var item = TaskDisplayScript.new()
	var l1 = Label.new()
	l1.name = "NameLabel"
	item.add_child(l1)
	var l2 = Label.new()
	l2.name = "StatusLabel"
	item.add_child(l2)
	_add_and_free(item)

	item._ready()
	item.set_task_data({"title": "Kill boss", "completed": true})
	assert_str(l1.text).is_equal("Kill boss")
	assert_str(l2.text).contains("Completed")

func test_task_list_item() -> void:
	var item = TaskListItemScript.new()
	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	item.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	margin.add_child(vbox)

	var l1 = Label.new()
	l1.name = "TitleLabel"
	item.title_label = l1
	vbox.add_child(l1)

	var pb = ProgressBar.new()
	pb.name = "ProgressBar"
	item.progress_bar = pb
	vbox.add_child(pb)

	var pl = Label.new()
	pl.name = "ProgressLabel"
	item.progress_label = pl
	pb.add_child(pl)

	_add_and_free(item)

	item.update_task({"title": "Gather wood", "current": 2, "required": 5})
	assert_str(l1.text).is_equal("Gather wood")
	assert_int(pb.value).is_equal(2)
	assert_int(pb.max_value).is_equal(5)

func test_lists_panels_empty() -> void:
	var loc_panel = LocationListScript.new()
	var task_panel = TaskListScript.new()

	var vbox1 = VBoxContainer.new()
	vbox1.name = "locationsVBox"
	loc_panel.add_child(vbox1)
	loc_panel._vbox = vbox1

	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	task_panel.add_child(margin)
	var vbox2 = VBoxContainer.new()
	vbox2.name = "VBoxContainer"
	margin.add_child(vbox2)
	task_panel.tasks_container = vbox2

	_add_and_free(loc_panel)
	_add_and_free(task_panel)

	# Passing empty arrays shouldn't throw error
	loc_panel.update_locations([])
	task_panel.update_tasks([])

# --- MoralePanel ---
const MoralePanelScript = preload("res://GUI/morale_panel.gd")

func test_morale_panel_update_morale_display() -> void:
	var mp = MoralePanelScript.new()
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	mp.add_child(vbox)

	var hbox = HBoxContainer.new()
	hbox.name = "LabelsHBox"
	vbox.add_child(hbox)

	var l1 = Label.new()
	l1.name = "PlayerRatioLabel"
	hbox.add_child(l1)
	var l2 = Label.new()
	l2.name = "EnemyRatioLabel"
	hbox.add_child(l2)
	var l3 = Label.new()
	l3.name = "NeutralRatioLabel"
	hbox.add_child(l3)

	var pb = ProgressBar.new()
	pb.name = "MoraleAdvantageBar"
	vbox.add_child(pb)

	_add_and_free(mp)

	var um = UnitManager.new()
	mp.reset_state(um)

	assert_str(l1.text).is_equal("Player: 0%")
	assert_int(pb.value).is_equal(0)

	mp.update_morale_display()

	# Manually update
	mp._update_labels(0.5, 0.25, 0.75)
	assert_str(l1.text).contains("50%")
	assert_str(l2.text).contains("25%")

	um.free()

func test_morale_panel_faction_label_to_id() -> void:
	var mp = MoralePanelScript.new()
	assert_int(mp.faction_label_to_id("Player")).is_equal(Unit.Faction.PLAYER)
	assert_int(mp.faction_label_to_id("Enemy")).is_equal(Unit.Faction.ENEMY)
	assert_int(mp.faction_label_to_id("Neutral")).is_equal(Unit.Faction.NEUTRAL)
	assert_int(mp.faction_label_to_id("Invalid")).is_equal(-1)
	mp.free()
