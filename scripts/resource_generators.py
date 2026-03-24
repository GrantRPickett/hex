import logging
import hashlib
import re
from conversion_config import SCRIPT_PATHS, ENUM_VALUES, GENERIC_UNIT_SCENE, GENERIC_LOCATION_SCENE, GENERIC_LOOT_SCENE
from conversion_utils import copy_props as _copy_props, slugify as _slugify

logger = logging.getLogger(__name__)

def _apply_stat_overrides(builder, props: dict, data: dict, defaults: dict) -> None:
	"""Applies stat overrides from data to props by creating a CombatStats sub-resource."""
	stats = ["grit", "flow", "gusto", "focus", "shine", "shade", "willpower", "movement_points"]

	has_any = any(stat in data for stat in stats)
	if not has_any:
		return

	stat_props = {}
	for stat in stats:
		if stat in data:
			stat_props[stat] = data[stat]

	stat_id = builder.add_sub_resource("CombatStats", stat_props)
	props["stats"] = f'SubResource("{stat_id}")'

def _extract_loot_items(builder, data: dict) -> list:
	"""Extracts items and converts them to InventoryItem sub-resources."""
	item_refs = []

	items_list = data.get("items", []) or []
	if items_list:
		for item_entry in items_list:
			if not item_entry:
				continue

			ref = build_inventory_item(builder, item_entry)
			if ref:
				item_refs.append(ref)

	return item_refs

def build_inventory_item(builder, item_data) -> str:
	"""
	Creates an InventoryItem sub-resource from an item ID, dict, or path.
	Returns the full resource reference string (e.g., 'SubResource("...")' or 'ExtResource("...")').
	"""
	item_id = ""
	is_equipped = False
	template_path = ""

	if isinstance(item_data, str):
		if item_data.startswith("res://"):
			# If it's already a path, check if it's a template or an item instance
			if "/items/" in item_data or "template" in item_data.lower():
				template_path = item_data
			else:
				# Already an InventoryItem instance
				iid = builder.add_ext_resource(item_data, "Resource")
				return f'ExtResource("{iid}")' if iid else None
		else:
			item_id = item_data
	elif isinstance(item_data, dict):
		item_id = item_data.get("id", item_data.get("item_id", ""))
		is_equipped = item_data.get("equipped", item_data.get("is_equipped", False))
		if item_id.startswith("res://"):
			if "/items/" in item_id or "template" in item_id.lower():
				template_path = item_id
			else:
				iid = builder.add_ext_resource(item_id, "Resource")
				return f'ExtResource("{iid}")' if iid else None

	if not item_id and not template_path:
		return None

	# Link to ItemTemplate ExtResource
	if not template_path:
		template_path = f"res://Resources/items/{item_id}.tres"

	tid = builder.add_ext_resource(template_path, "Resource")

	props = {
		"template": f'ExtResource("{tid}")' if tid else None,
		"equipped": is_equipped,
		# Generating a pseudo-unique ID for the SubResource
		"uuid": f"gen-{hashlib.md5((template_path + str(is_equipped) + str(builder.next_sub_id_counter)).encode()).hexdigest()[:8]}"
	}

	rid = builder.add_sub_resource("InventoryItem", props)
	return f'SubResource("{rid}")' if rid else None

def build_level_loot_entry(builder, data: dict, coord_func, default_invalid_coord) -> str:
	props = {}
	_copy_props(props, data, ["id", "stage_id", "is_trapped"])
	props["coord"] = coord_func(data.get("coord", default_invalid_coord), default_invalid_coord)
	props["items"] = _extract_loot_items(builder, data)
	_apply_stat_overrides(builder, props, data, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 1, "movement_points": 0})

	type_hints = {"items": "InventoryItem"}
	return builder.add_sub_resource("LevelLootEntry", props, type_hints=type_hints)

def build_level_unit_spawn_entry(builder, data: dict, faction: str = 'enemy', stage: dict = None, stage_id: str = "", coord_func=None, default_invalid_coord=None) -> str:
	props = {}
	faction_int = ENUM_VALUES["UnitFaction"].get(str(faction).upper(), 1)
	props['faction'] = faction_int
	if coord_func:
		props['coord'] = coord_func(data.get('coord', default_invalid_coord), default_invalid_coord)
	props['stage_id'] = stage_id

	_copy_props(props, data, ["id", "slot_index", "unit_name", "loyalty_type"])

	# Automatically detect if this unit should be persuadable based on tasks
	can_persuade = data.get('neutral_can_be_persuaded', False)
	if not can_persuade and faction == 'neutral' and stage:
		unit_id = data.get('id') or data.get('unit_name')
		tasks = stage.get('tasks', []) or []
		for t in tasks:
			if t.get('event_type') == 'convince' and t.get('target_id') == unit_id:
				can_persuade = True
				break
	props['neutral_can_be_persuaded'] = can_persuade

	unit_scene_path = data.get('unit_scene_path')
	is_player = (faction_int == 0) # PLAYER

	if not unit_scene_path and not is_player:
		unit_scene_path = GENERIC_UNIT_SCENE
		logger.warning(f"Unit spawn missing 'unit_scene_path' in JSON. Using fallback: {unit_scene_path}")

	if unit_scene_path:
		unit_ext = builder.add_ext_resource(unit_scene_path, 'PackedScene')
		if unit_ext:
			props['unit_scene'] = f'ExtResource("{unit_ext}")'

	if "inventory" in data:
		inv_data = data["inventory"]
		if isinstance(inv_data, list):
			props["inventory"] = []
			for item_entry in inv_data:
				ref = build_inventory_item(builder, item_entry)
				if ref:
					props["inventory"].append(ref)

	_apply_stat_overrides(builder, props, data, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 10, "movement_points": 6})

	type_hints = {"inventory": "InventoryItem"}
	return builder.add_sub_resource("LevelUnitSpawnEntry", props, type_hints=type_hints)

def build_level_task_entry(builder, data: dict, level_id: str, stage_id: str, coord_func, default_invalid_coord, dialogue_gen) -> str:
	props = {}
	props["id"] = data.get("id", "")
	props["stage_id"] = stage_id
	props["coord"] = coord_func(data.get("coord", default_invalid_coord), default_invalid_coord)

	scene_path = data.get("location_scene_path", "")
	if not scene_path:
		scene_path = GENERIC_LOCATION_SCENE
		logger.warning(f"Location spawn missing 'location_scene_path' in JSON. Using fallback: {scene_path}")

	if scene_path:
		sid = builder.add_ext_resource(scene_path, "PackedScene")
		if sid:
			props["location_scene"] = f'ExtResource("{sid}")'

	location_name = data.get("location_name") or data.get("id", "")
	location_desc = data.get("description", "")

	if level_id and location_name:
		name_key = f"level.{level_id}.location.{_slugify(location_name)}.name"
		desc_key = f"level.{level_id}.location.{_slugify(location_name)}.desc"
		dialogue_gen.register_translation(name_key, location_name)
		dialogue_gen.register_translation(desc_key, location_desc)
		props["location_name"] = name_key
		props["description"] = desc_key
	else:
		props["location_name"] = location_name
		props["description"] = location_desc

	_apply_stat_overrides(builder, props, data, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 10})

	return builder.add_sub_resource("LevelTaskEntry", props)

def build_task_reward(builder, data: dict) -> str:
	props = {
		"reward_type": data.get("reward_type", "ITEM"),
		"reward_value": data.get("reward_value", "")
	}
	props["reward_type"] = ENUM_VALUES["TaskRewardType"].get(props["reward_type"].upper(), 0)

	if props["reward_type"] == 0 and props["reward_value"]: # ITEM
		item_id = props["reward_value"]
		ref = build_inventory_item(builder, item_id)
		if ref:
			props["reward_item"] = ref

	return builder.add_sub_resource("TaskReward", props)

def _extract_target_filters(data: dict, coord_func, default_invalid_coord) -> list:
	raw_entries = []
	if isinstance(data.get("target_filters"), list):
		raw_entries = data.get("target_filters") or []
	elif isinstance(data.get("event_type"), list):
		raw_entries = data.get("event_type") or []
	elif isinstance(data.get("targets"), list):
		raw_entries = data.get("targets") or []

	filters: list = []
	for entry in raw_entries:
		if isinstance(entry, dict):
			filter_data: dict = {}
			if "event_type" in entry:
				filter_data["event_type"] = entry.get("event_type")
			elif "type" in entry:
				filter_data["event_type"] = entry.get("type")
			if "target_id" in entry:
				filter_data["target_id"] = entry.get("target_id")
			if "target_kind" in entry:
				filter_data["target_kind"] = entry.get("target_kind")
			if "target_coord" in entry:
				filter_data["target_coord"] = coord_func(entry.get("target_coord"), default_invalid_coord)
			if "target_faction" in entry:
				val = entry.get("target_faction")
				if isinstance(val, str):
					filter_data["target_faction"] = ENUM_VALUES["UnitFaction"].get(val.upper(), 0)
				else:
					filter_data["target_faction"] = val
			filters.append(filter_data)
		elif isinstance(entry, str):
			filters.append({"event_type": entry})

	return filters

def build_task(builder, data: dict, level_id: str, coord_func, default_invalid_coord, dialogue_gen, hook_resolve_func, location_refs=None, unit_refs=None, loot_refs=None) -> str:
	props = {}
	task_id = data.get('id', 'task')
	props['id'] = f'&"{task_id}"'

	copy_keys = [
		"target_id", "target_kind",
		"effort_required", "is_optional", "is_opposed",
		"opposition_value", "journal_entry_id", "reward_id", "duration_turns",
		"carryover_to_next_stage"
	]
	_copy_props(props, data, copy_keys)

	target_filters = _extract_target_filters(data, coord_func, default_invalid_coord)
	if isinstance(data.get("event_type"), str):
		props["event_type"] = data.get("event_type")

	if target_filters:
		props["target_filters"] = target_filters
		if "event_type" not in props and target_filters[0].get("event_type"):
			props["event_type"] = target_filters[0].get("event_type")
		if "target_id" not in props:
			for f in target_filters:
				if "target_id" in f:
					props["target_id"] = f.get("target_id")
					break
		if "target_kind" not in props:
			for f in target_filters:
				if "target_kind" in f:
					props["target_kind"] = f.get("target_kind")
					break

	# Auto-detect target_kind if missing
	if "target_kind" not in props or not props["target_kind"] or props["target_kind"] == "&\"\"":
		e_type = props.get("event_type", "")
		if e_type in ["visit", "explore", "interact"]:
			props["target_kind"] = f"&\"location\""
		elif e_type in ["convince", "attack", "talk", "unit_defeated"]:
			props["target_kind"] = f"&\"unit\""
		elif e_type in ["loot", "collect"]:
			props["target_kind"] = f"&\"item\""

	# Link to target_spawn if possible
	target_kind_raw = str(props.get("target_kind", "")).strip('&"')
	target_id = props.get("target_id")
	target_spawn_coord = None
	
	if target_id and (location_refs or unit_refs or loot_refs):
		potential_refs = []
		if target_kind_raw == 'location' and location_refs: potential_refs = location_refs
		elif target_kind_raw == 'unit' and unit_refs: potential_refs = unit_refs
		elif target_kind_raw == 'item' and loot_refs: potential_refs = loot_refs
		
		for ref in potential_refs:
			match = re.search(r'(SubResource|ExtResource)\("([^"]+)"\)', ref)
			if match:
				sub_id = match.group(2)
				res_data = builder.sub_resource_props.get(sub_id, {})
				res_props = res_data.get("properties", {})
				
				# Match by ID or Name (for Units/Locations)
				is_match = False
				if res_props.get("id") == target_id:
					is_match = True
				elif target_kind_raw == 'unit' and res_props.get("unit_name") == target_id:
					is_match = True
				elif target_kind_raw == 'location' and (res_props.get("location_name") == target_id or res_props.get("id") == target_id):
					is_match = True
				
				if is_match:
					props["target_spawn"] = ref
					builder.update_sub_resource_prop(sub_id, "is_narrative", True)
					if "coord" in res_props:
						target_spawn_coord = res_props["coord"]
					break

	string_name_keys = ["dialogue_id", "enter_journal_id", "exit_journal_id", "duration_mode", "enter_dialogue_id", "exit_dialogue_id", "failure_dialogue_id", "failure_journal_id"]
	_copy_props(props, data, string_name_keys, {k: "StringName" for k in string_name_keys})

	title_text = data.get('title', 'New Task')
	desc_text = data.get('description', '')

	if level_id:
		title_key = f"level.{level_id}.task.{task_id}.title"
		desc_key = f"level.{level_id}.task.{task_id}.desc"
		dialogue_gen.register_translation(title_key, title_text)
		dialogue_gen.register_translation(desc_key, desc_text)
		props['title'] = title_key
		props['description'] = desc_key
	else:
		props['title'] = title_text
		props['description'] = desc_text

	if "faction" in data:
		props["owning_faction"] = ENUM_VALUES["UnitFaction"].get(str(data["faction"]).upper(), 0) if isinstance(data["faction"], str) else data["faction"]
	elif "owning_faction" in data:
		props["owning_faction"] = ENUM_VALUES["UnitFaction"].get(str(data["owning_faction"]).upper(), 0) if isinstance(data["owning_faction"], str) else data["owning_faction"]

	if "target_faction" in data:
		props["target_faction"] = ENUM_VALUES["UnitFaction"].get(str(data["target_faction"]).upper(), 0)

	if "reward_resource" in data:
		reward_id = build_task_reward(builder, data["reward_resource"])
		props["reward_resource"] = f'SubResource("{reward_id}")'

	if target_filters:
		coord_set = False
		for f in target_filters:
			if "target_coord" in f:
				props["target_coord"] = f.get("target_coord")
				coord_set = True
				break
		if not coord_set:
			if target_spawn_coord is not None and "target_coord" not in data:
				props["target_coord"] = target_spawn_coord
			else:
				props["target_coord"] = coord_func(data.get("target_coord", default_invalid_coord), default_invalid_coord)
	else:
		if target_spawn_coord is not None and "target_coord" not in data:
			props["target_coord"] = target_spawn_coord
		else:
			props["target_coord"] = coord_func(data.get("target_coord", default_invalid_coord), default_invalid_coord)

	if "zone_coords" in data:
		props["zone_coords"] = [coord_func(c, default_invalid_coord) for c in data["zone_coords"]]
	else:
		props["zone_coords"] = []

	hooks = {
		"on_enter": ("start_dialogue_resource", "enter_dialogue_id", "enter_journal_id"),
		"on_exit": ("exit_dialogue_resource", "exit_dialogue_id", "exit_journal_id"),
		"on_fail": ("failure_dialogue_resource", "failure_dialogue_id", "failure_journal_id")
	}

	for hook_key, (res_prop, d_id_prop, j_id_prop) in hooks.items():
		if hook_key in data:
			d_id, j_id = hook_resolve_func(data[hook_key], task_data=data)
			if d_id:
				if level_id:
					t = data.get("title", d_id)
					d = data.get("description", f"Task {hook_key.replace('on_', '').capitalize()} Dialogue")
					meta = {"task_id": data.get("id"), "journal_id": j_id}
					props[res_prop] = dialogue_gen.ensure_dialogue_file_exists(level_id, d_id, title=t, description=d, metadata=meta)
				props[d_id_prop] = f'&"{d_id}"'
			if j_id:
				props[j_id_prop] = j_id

	if "completion_condition" in data:
		cc = data["completion_condition"]
		owning_faction = data.get("owning_faction", "PLAYER")
		default_target_faction = "ENEMY" if owning_faction == "PLAYER" else "PLAYER"
		cc_props = {
			"type": cc.get("type", "DEFEAT_ALL_UNITS_OF_FACTION"),
			"faction": ENUM_VALUES["UnitFaction"].get(cc.get("faction", default_target_faction), 1 if default_target_faction == "ENEMY" else 0)
		}
		cc_id = builder.add_sub_resource("CompletionCondition", cc_props)
		props["completion_condition"] = f'SubResource("{cc_id}")'

	type_hints = {
		"zone_coords": "Vector2i",
		"target_filters": "Dictionary"
	}
	return builder.add_sub_resource("Task", props, type_hints=type_hints)

def build_level_dialogue_entry(builder, data: dict, level_id: str, stage_id: str, dialogue_gen, apply_props_func) -> str:
	props = {}
	apply_props_func(props, data)
	props["stage_id"] = stage_id
	dialogue_entry_id = data.get("entry_id") or data.get("group_id") or f"dialogue_{len(builder.sub_resources)}"
	title = data.get("action_label", dialogue_entry_id)
	props["dialogue_resource_path"] = dialogue_gen.ensure_dialogue_file_exists(level_id, dialogue_entry_id, title=title)
	return builder.add_sub_resource("LevelDialogueEntry", props)

def build_level_journal_entry(builder, data: dict) -> str:
	props = {}
	_copy_props(props, data, ["title", "unlocked", "entry_type", "status", "related_id", "topic_id", "section_id"])
	entry_id = data.get("entry_id", data.get("id", ""))
	if entry_id:
		props["id"] = entry_id
	if "content" in data:
		props["content"] = data["content"]
	elif "notes" in data:
		props["content"] = data["notes"]
	_copy_props(props, data, ["flag_name", "level_id"], {"flag_name": "StringName", "level_id": "StringName"})
	return builder.add_sub_resource("JournalEntry", props)

def build_level_dialogue_journal_entry(builder, data: dict, level_id: str, dialogue_gen, apply_props_func) -> str:
	props = {}
	apply_props_func(props, data)
	dialogue_entry_id = data.get("entry_id") or data.get("group_id") or f"dialogue_journal_{len(builder.sub_resources)}"
	props["dialogue_resource_path"] = dialogue_gen.ensure_dialogue_file_exists(level_id, dialogue_entry_id)

	journal_mapping = {
		"journal_entry_id": "entry_id",
		"journal_flag_name": "flag_name",
		"journal_section_id": "section_id",
		"journal_topic_id": "topic_id",
		"journal_notes": "notes"
	}
	for prop_name, json_key in journal_mapping.items():
		if json_key in data:
			if prop_name in ("journal_entry_id", "journal_flag_name"):
				props[prop_name] = f'&"{data[json_key]}"'
			else:
				props[prop_name] = data[json_key]

	return builder.add_sub_resource("LevelDialogueJournalEntry", props)
