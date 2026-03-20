import json
import os
import logging
import argparse
import re
import hashlib
import glob
from file_paths_loader import FilePathsLoader
from tres_builder import TresBuilder
from conversion_utils import fs_path as _fs_path_utils, generate_deterministic_uid, slugify as _slugify, copy_props as _copy_props
from conversion_config import SCRIPT_PATHS, LEVEL_DATA_SUBDIRS, ENUM_VALUES, GENERIC_UNIT_SCENE, GENERIC_LOCATION_SCENE, GENERIC_LOOT_SCENE, paths_helper
from dialogue_generator import DialogueGenerator
from level_validator import LevelValidator, json_coord_to_godot_coord as _json_coord_to_godot_coord
import resource_generators as gen

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

# Global context for conversion run
class ConversionContext:
	def __init__(self, out_base):
		self.out_base = out_base
		self.dialogue_gen = DialogueGenerator(PROJECT_ROOT, out_base, paths_helper, self.fs_path)
		self.validator = LevelValidator(DEFAULT_INVALID_COORD)
		self.warnings = []
		self.generated_stage_paths = {}
		self.journal_map = {} # Shared journal entries across all generators
		self.dialogue_map = {} # Unified dialogue map entry_id -> props
		self.dialogue_res_paths = {} # entry_id -> res_path

	def fs_path(self, res_path: str) -> str:
		return _fs_path_utils(res_path, PROJECT_ROOT)

	def get_builder(self) -> TresBuilder:
		return TresBuilder(SCRIPT_PATHS, GENERIC_UNIT_SCENE, GENERIC_LOCATION_SCENE, GENERIC_LOOT_SCENE, self.fs_path)

DEFAULT_OUTPUT_BASE_DIR = (paths_helper.get_path("directories.level_data") or "res://Resources/level_data").rstrip('/')
DEFAULT_INVALID_COORD = {"x": -999, "y": -999}

def _resolve_hook_ids(hook_data, dialogue_ids=None, journal_keys=None, task_data=None) -> tuple[str, str]:
	if not hook_data: return None, None
	d_id, j_id = None, None
	if isinstance(hook_data, dict):
		d_id, j_id = hook_data.get("dialogue_id"), hook_data.get("journal_id")
	elif isinstance(hook_data, str):
		hook_data = [hook_data]
	if isinstance(hook_data, list):
		for val in hook_data:
			is_d = dialogue_ids is None or val in dialogue_ids
			is_j = journal_keys is None or val in journal_keys
			if is_d and not d_id: d_id = val
			if is_j and not j_id: j_id = val
	return d_id, j_id

def _resolve_output_dirs(out_base: str, level_id: str = "") -> dict:
	normalized = out_base.replace('\\', '/')
	if normalized.startswith('./'): normalized = 'res://' + normalized[2:].lstrip('/')
	elif not normalized.startswith('res://'): normalized = 'res://' + normalized.lstrip('/')
	normalized = normalized.rstrip('/')
	if level_id: normalized = f"{normalized}/{_slugify(level_id)}"
	fs_root = _fs_path_utils(normalized, PROJECT_ROOT)
	os.makedirs(fs_root, exist_ok=True)
	dirs: dict = {"levels_fs": fs_root, "levels_res": normalized}
	for subdir in [s for s in LEVEL_DATA_SUBDIRS if s != 'summaries']:
		fs_dir = os.path.join(fs_root, subdir).replace(os.sep, '/')
		os.makedirs(fs_dir, exist_ok=True)
		dirs[f"{subdir}_fs"], dirs[f"{subdir}_res"] = fs_dir, f"{normalized}/{subdir}"
	return dirs

def _apply_dialogue_props(props: dict, data: dict) -> None:
	_copy_props(props, data, [
		"entry_id", "flag_name", "initiator_name", "partner_name", "group_id",
		"action_label", "action_hint", "repeatable", "requires_near",
		"consume_action", "allow_partner_initiation"
	], {k: "StringName" for k in ["group_id", "entry_id", "flag_name"]})
	if "coord" in data: props["coord"] = _json_coord_to_godot_coord(data["coord"], DEFAULT_INVALID_COORD)
	if "partner_faction" in data:
		props["partner_faction"] = ENUM_VALUES["UnitFaction"].get(str(data["partner_faction"]).upper(), 0)

# --- Generation Logic ---

def _generate_start_rows(ctx: ConversionContext, level_id: str, level_slug: str, dirs: dict, starts: list) -> None:
	for idx, raw in enumerate(starts or []):
		faction = 'player'; slot_index = idx; coord = raw; unit_scene_path = None
		if isinstance(raw, dict):
			faction = str(raw.get('faction', 'player'))
			slot_index = raw.get('slot_index', idx)
			coord = raw.get('coord', {k: raw.get(k, 0) for k in ('x', 'y')})
			unit_scene_path = raw.get('unit_scene_path')
		res_path = f"{dirs['start_rows_res']}/{level_slug}_start_{_slugify(faction)}_{slot_index}.tres"
		builder = ctx.get_builder()
		builder.add_ext_resource(SCRIPT_PATHS['LevelUnitSpawnEntry'], 'Script')
		props = {
			'level_id': f'&"{level_id}"',
			'faction': ENUM_VALUES["UnitFaction"].get(str(faction).upper(), 0),
			'slot_index': slot_index,
			'coord': _json_coord_to_godot_coord(coord, DEFAULT_INVALID_COORD),
			'notes': ''
		}
		if unit_scene_path:
			unit_ext = builder.add_ext_resource(unit_scene_path, 'PackedScene')
			if unit_ext: props['unit_scene'] = f'ExtResource("{unit_ext}")'
		gen._apply_stat_overrides(builder, props, raw if isinstance(raw, dict) else {}, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 10})
		content = builder.build_tres('LevelUnitSpawnEntry', props, generate_deterministic_uid(res_path), type_hints={"inventory": "InventoryItem"})
		write_tres_file(res_path, content)

def _generate_roster_rows(ctx: ConversionContext, level_id: str, level_slug: str, dirs: dict, stages: list) -> None:
	for index, stage in enumerate(stages):
		stage_slug = _stage_slug(stage, index); stage_id = stage.get('id', '')
		for faction in ['enemy', 'neutral']:
			for idx, spawn in enumerate(stage.get(f'{faction}_spawns', []) or []):
				res_path = f"{dirs['roster_rows_res']}/{level_slug}_{stage_slug}_{_slugify(faction)}_{idx}.tres"
				builder = ctx.get_builder()
				builder.add_ext_resource(SCRIPT_PATHS['LevelUnitSpawnEntry'], 'Script')
				props = {'level_id': f'&"{level_id}"', 'stage_id': stage_id, 'notes': stage_id or ''}
				faction_int = ENUM_VALUES["UnitFaction"].get(str(faction).upper(), 1)
				props['faction'] = faction_int
				props['coord'] = _json_coord_to_godot_coord(spawn.get('coord', DEFAULT_INVALID_COORD), DEFAULT_INVALID_COORD)
				_copy_props(props, spawn, ["id", "slot_index", "unit_name", "loyalty_type"])
				can_persuade = spawn.get('neutral_can_be_persuaded', False)
				if not can_persuade and faction == 'neutral':
					unit_id = spawn.get('id') or spawn.get('unit_name')
					for t in stage.get('tasks', []) or []:
						if t.get('event_type') == 'convince' and t.get('target_id') == unit_id:
							can_persuade = True; break
				props['neutral_can_be_persuaded'] = can_persuade
				unit_scene_path = spawn.get('unit_scene_path') or GENERIC_UNIT_SCENE
				unit_ext = builder.add_ext_resource(unit_scene_path, 'PackedScene')
				if unit_ext: props['unit_scene'] = f'ExtResource("{unit_ext}")'
				gen._apply_stat_overrides(builder, props, spawn, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 10})
				write_tres_file(res_path, builder.build_tres('LevelUnitSpawnEntry', props, generate_deterministic_uid(res_path), type_hints={"inventory": "InventoryItem"}))

def _generate_loot_rows(ctx: ConversionContext, level_id: str, level_slug: str, dirs: dict, stages: list) -> None:
	for index, stage in enumerate(stages):
		stage_slug = _stage_slug(stage, index); stage_id = stage.get('id', '')
		for count, loot in enumerate(stage.get('loot_spawns', []) or []):
			res_path = f"{dirs['loot_rows_res']}/{level_slug}_{stage_slug}_loot_{count}.tres"
			builder = ctx.get_builder()
			builder.add_ext_resource(SCRIPT_PATHS['LevelLootEntry'], 'Script')
			props = {'level_id': f'&"{level_id}"', 'notes': stage_id or '', 'stage_id': stage_id}
			_copy_props(props, loot, ["id", "is_trapped"])
			props['coord'] = _json_coord_to_godot_coord(loot.get('coord', DEFAULT_INVALID_COORD), DEFAULT_INVALID_COORD)
			props['items'] = gen._extract_loot_items(builder, loot)
			gen._apply_stat_overrides(builder, props, loot, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 1})
			write_tres_file(res_path, builder.build_tres('LevelLootEntry', props, generate_deterministic_uid(res_path), type_hints={"items": "InventoryItem"}))

def _generate_location_rows(ctx: ConversionContext, level_id: str, level_slug: str, dirs: dict, stages: list) -> None:
	for index, stage in enumerate(stages):
		stage_slug = _stage_slug(stage, index); stage_id = stage.get('id', '')
		for count, loc in enumerate(stage.get('location_spawns', []) or []):
			res_path = f"{dirs['location_rows_res']}/{level_slug}_{stage_slug}_location_{count}.tres"
			builder = ctx.get_builder()
			builder.add_ext_resource(SCRIPT_PATHS['LevelTaskEntry'], 'Script')
			props = {'level_id': f'&"{level_id}"', 'stage_id': stage_id, 'notes': stage_id or ''}
			props['coord'] = _json_coord_to_godot_coord(loc.get('coord', DEFAULT_INVALID_COORD), DEFAULT_INVALID_COORD)
			props['location_name'] = loc.get('location_name') or loc.get('id', '')
			props['id'] = loc.get('id', '')
			scene_path = loc.get('location_scene_path') or GENERIC_LOCATION_SCENE
			scene_ext = builder.add_ext_resource(scene_path, 'PackedScene')
			if scene_ext: props['location_scene'] = f'ExtResource("{scene_ext}")'
			
			icon_path = loc.get('icon_path') or loc.get('location_icon_path')
			if icon_path:
				icon_ext = builder.add_ext_resource(icon_path, 'Texture2D')
				if icon_ext: props['location_icon'] = f'ExtResource("{icon_ext}")'

			gen._apply_stat_overrides(builder, props, loc, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 10})
			write_tres_file(res_path, builder.build_tres('LevelTaskEntry', props, generate_deterministic_uid(res_path)))

def _generate_dialogue_rows(ctx: ConversionContext, level_id: str, level_slug: str, dirs: dict, stages: list, data: dict) -> None:
	# 1. Collect all dialogue/journal definitions from the root to use as metadata templates
	global_metadata = {}
	for entry in (data.get('dialogue_entries', []) or []) + (data.get('dialogue_journal_entries', []) or []):
		eid = entry.get('entry_id') or entry.get('id')
		if eid: global_metadata[str(eid)] = entry

	# 2. Map every dialogue ID to its stage (based on hook usage or stage-local definitions)
	dialogue_to_stage = {}
	for index, stage in enumerate(stages):
		stage_id = stage.get('id') or f"stage_{index+1}"
		# Stage-local definitions
		for entry in (stage.get('dialogue_entries', []) or []) + (stage.get('dialogue_journal_entries', []) or []):
			eid = entry.get('entry_id') or entry.get('id')
			if eid: dialogue_to_stage[str(eid)] = stage_id
		# Hooks
		for hook in ["on_enter", "on_exit", "on_fail"]:
			d_id, _ = _resolve_hook_ids(stage.get(hook))
			if d_id: dialogue_to_stage[str(d_id)] = stage_id
		# Task hooks
		for task in stage.get("tasks", []) or []:
			for hook in ["on_enter", "on_exit"]:
				d_id, _ = _resolve_hook_ids(task.get(hook))
				if d_id: dialogue_to_stage[str(d_id)] = stage_id

	# 3. Collect all unique dialogue entries to generate
	unified_entries = {} # entry_id -> props
	
	# Process stages for their specific entries and hooks
	for index, stage in enumerate(stages):
		stage_slug = _stage_slug(stage, index); stage_id = stage.get('id', '')
		combined: list[tuple[dict, bool]] = []
		for e in (stage.get('dialogue_entries', []) or []): combined.append((e, False))
		for e in (stage.get('dialogue_journal_entries', []) or []): combined.append((e, False))
		
		# Task hooks
		for task in stage.get("tasks", []):
			task_id = task.get("id", "task")
			for hook_key in ["on_enter", "on_exit"]:
				d_id, j_id = _resolve_hook_ids(task.get(hook_key), task_data=task)
				if d_id:
					new_entry = task.get(hook_key, {}).copy() if isinstance(task.get(hook_key), dict) else {}
					new_entry.update({"entry_id": d_id, "notes": f"Task {task_id} {hook_key}"})
					# Merge root metadata if it exists
					if d_id in global_metadata:
						meta_copy = global_metadata[d_id].copy()
						meta_copy.update(new_entry)
						new_entry = meta_copy
					
					meta = {"task_id": task_id, "stage_id": stage_id, "journal_id": j_id, "title": task.get("title"), "description": task.get("description")}
					new_entry["metadata"] = meta
					combined.append((new_entry, True))

		for count, (entry, is_auto) in enumerate(combined):
			eid = str(entry.get('entry_id') or entry.get('journal_entry_id'))
			if not eid: continue
			
			res_path = f"{dirs['dialogue_rows_res']}/{level_slug}_{stage_slug}_dialogue_{count}.tres"
			builder = ctx.get_builder(); builder.add_ext_resource(SCRIPT_PATHS['LevelDialogueEntry'], 'Script')
			props = {'level_id': f'&"{level_id}"', 'stage_id': stage_id}
			_apply_dialogue_props(props, entry)
			props['requires_near'] = bool(entry.get('requires_near', ("coord" in entry) and (not is_auto)))
			props['consume_action'] = bool(entry.get('consume_action', not is_auto))
			props['allow_partner_initiation'] = bool(entry.get('allow_partner_initiation', is_auto))
			props['notes'] = entry.get('notes', stage_id or '')
			if not props.get('dialogue_resource_path'):
				meta = entry.get("metadata", {}); t = meta.get("title") or entry.get("title", ""); d = meta.get("description") or entry.get("notes", "")
				props['dialogue_resource_path'] = ctx.dialogue_gen.ensure_dialogue_file_exists(level_id, eid, title=t, description=d, metadata=meta)
			
			write_tres_file(res_path, builder.build_tres('LevelDialogueEntry', props, generate_deterministic_uid(res_path)))
			ctx.dialogue_res_paths[eid] = res_path

	# 4. Process root-level globals that haven't been claimed by stages
	all_globals = list(enumerate(data.get("dialogue_entries", []) or [])) + list(enumerate(data.get("dialogue_journal_entries", []) or []))
	for count, entry in all_globals:
		eid = str(entry.get('entry_id') or entry.get('id'))
		if not eid or eid in ctx.dialogue_res_paths: continue
		
		# Assign correct stage_id if this global is used as a hook somewhere
		assigned_stage = dialogue_to_stage.get(eid, "")
		stage_prefix = _slugify(assigned_stage) if assigned_stage else "global"
		
		res_path = f"{dirs['dialogue_rows_res']}/{level_slug}_{stage_prefix}_narrative_{count}.tres"
		builder = ctx.get_builder(); builder.add_ext_resource(SCRIPT_PATHS['LevelDialogueEntry'], 'Script')
		props = {'level_id': f'&"{level_id}"', 'stage_id': assigned_stage}
		_apply_dialogue_props(props, entry)
		if not props.get('dialogue_resource_path'):
			props['dialogue_resource_path'] = ctx.dialogue_gen.ensure_dialogue_file_exists(level_id, eid, title=entry.get('title', ''), description=entry.get('notes', ''))
		
		write_tres_file(res_path, builder.build_tres('LevelDialogueEntry', props, generate_deterministic_uid(res_path)))
		ctx.dialogue_res_paths[eid] = res_path

def _add_to_journal_map(ctx: ConversionContext, entries, section_id, topic_id, is_handcrafted=True):
	for entry in entries or []:
		jid = entry.get('journal_entry_id') or entry.get('entry_id') or entry.get('id')
		if not jid: continue
		if 'section_id' not in entry: entry['section_id'] = section_id
		if 'topic_id' not in entry: entry['topic_id'] = topic_id
		if jid not in ctx.journal_map or is_handcrafted:
			ctx.journal_map[jid] = entry

def _generate_journal_rows(ctx: ConversionContext, level_id: str, level_slug: str, dirs: dict, stages: list, data: dict, default_topic: str = "") -> None:
	_add_to_journal_map(ctx, data.get('journal_entries'), level_id, "global", True)
	_add_to_journal_map(ctx, data.get('dialogue_journal_entries'), level_id, "global", True)
	for stage in stages:
		sid = stage.get('id', '')
		_add_to_journal_map(ctx, stage.get('journal_entries'), level_id, sid, True)
		_add_to_journal_map(ctx, stage.get('dialogue_journal_entries'), level_id, sid, True)

	for count, (j_id, entry) in enumerate(ctx.journal_map.items()):
		res_path = f"{dirs['journal_entry_rows_res']}/{level_slug}_journal_{count}.tres"
		builder = ctx.get_builder(); builder.add_ext_resource(SCRIPT_PATHS['JournalEntry'], 'Script')
		jid = entry.get('journal_entry_id') or entry.get('id') or entry.get('entry_id') or f"journal_{count}"
		props = {
			'level_id': f'&"{level_id}"', 'flag_name': f'&"{entry.get("flag_name", "")}"', 'id': jid,
			'title': entry.get('journal_title') or entry.get('title') or entry.get('action_label') or jid,
			'content': entry.get('journal_content') or entry.get('content') or entry.get('journal_notes') or entry.get('notes', ''),
			'unlocked': bool(entry.get('unlocked', False)), 'section_id': entry.get('section_id', level_id),
			'topic_id': entry.get('topic_id', ''), 'entry_type': entry.get('entry_type', 'generic'),
			'status': entry.get('status', 'available'), 'related_id': entry.get('related_id') or entry.get('entry_id') or jid
		}
		write_tres_file(res_path, builder.build_tres('JournalEntry', props, generate_deterministic_uid(res_path)))

def generate_stage_tres(ctx: ConversionContext, data: dict, stage_fs_dir: str, stage_res_dir: str, level_id: str, level_slug: str, stage_slug: str, stage_slug_map: dict):
	filename = _stage_file_name(level_slug, stage_slug); res_path = f"{stage_res_dir}/{filename}"; fs_path = os.path.join(stage_fs_dir, filename).replace(os.sep, '/')
	builder = ctx.get_builder(); builder.add_ext_resource(SCRIPT_PATHS["Stage"], "Script")
	loot_refs = [f'SubResource("{gen.build_level_loot_entry(builder, l, _json_coord_to_godot_coord, DEFAULT_INVALID_COORD)}")' for l in data.get("loot_spawns", [])]
	location_refs = [f'SubResource("{gen.build_level_task_entry(builder, l, level_id, stage_slug, _json_coord_to_godot_coord, DEFAULT_INVALID_COORD, ctx.dialogue_gen)}")' for l in data.get("location_spawns", [])]
	
	enemy_refs = [f'SubResource("{gen.build_level_unit_spawn_entry(builder, s, "enemy", data, stage_slug, _json_coord_to_godot_coord, DEFAULT_INVALID_COORD)}")' for s in data.get("enemy_spawns", [])]
	neutral_refs = [f'SubResource("{gen.build_level_unit_spawn_entry(builder, s, "neutral", data, stage_slug, _json_coord_to_godot_coord, DEFAULT_INVALID_COORD)}")' for s in data.get("neutral_spawns", [])]
	for s in data.get("roster_spawns", []):
		f = str(s.get("faction", "enemy")).lower(); target_list = {"enemy": enemy_refs, "foe": enemy_refs, "neutral": neutral_refs, "npc": neutral_refs}.get(f, enemy_refs)
		target_list.append(f'SubResource("{gen.build_level_unit_spawn_entry(builder, s, f, data, stage_slug, _json_coord_to_godot_coord, DEFAULT_INVALID_COORD)}")')

	task_refs = []
	for i, t_data in enumerate(data.get("tasks", []) or []):
		task_refs.append(f'SubResource("{gen.build_task(builder, t_data, level_id, _json_coord_to_godot_coord, DEFAULT_INVALID_COORD, ctx.dialogue_gen, _resolve_hook_ids, location_refs, enemy_refs + neutral_refs, loot_refs)}")')
	
	props = {"id": f'&"{stage_slug}"', "tasks": task_refs, "completion_mode": ENUM_VALUES["CompletionMode"].get(data.get("completion_mode", "ALL_REQUIRED"), 0), "auto_advance": data.get("auto_advance", True), "enemy_spawns": enemy_refs, "neutral_spawns": neutral_refs, "loot_spawns": loot_refs, "location_spawns": location_refs, "dialogue_entries": [], "journal_entries": [], "dialogue_journal_entries": [], "spawns": []}
	hooks = {"on_enter": ("start_dialogue_resource", "enter_dialogue_id", "enter_journal_id"), "on_exit": ("exit_dialogue_resource", "exit_dialogue_id", "exit_journal_id"), "on_fail": ("failure_dialogue_resource", "failure_dialogue_id", "failure_journal_id")}
	is_term = not data.get("default_next_stage_id") and not data.get("branching_transitions")
	for h_key, (res_p, d_p, j_p) in hooks.items():
		if h_key in data:
			d_id, j_id = _resolve_hook_ids(data[h_key])
			if d_id:
				tt = "STAGE_DIALOGUE"; ninfo = ""
				if h_key == "on_exit": tt = "STAGE_EXIT_TERMINAL" if is_term else "STAGE_EXIT_TRANSITION"; ninfo = data.get("default_next_stage_id", "multiple paths" if data.get("branching_transitions") else "")
				props[res_p] = ctx.dialogue_gen.ensure_dialogue_file_exists(level_id, d_id, title=f"Stage: {stage_slug}", description=f"{h_key[3:].capitalize()} for {stage_slug}", template_type=tt, next_info=ninfo, metadata={"stage_id": stage_slug, "journal_id": j_id})
				props[d_p] = f'&"{d_id}"'
			if j_id: props[j_p] = j_id
	nid = data.get("default_next_stage_id")
	if nid:
		npath = f"{stage_res_dir}/{_stage_file_name(level_slug, stage_slug_map.get(nid, _slugify(nid)))}"
		nrid = builder.add_ext_resource(npath, "Resource")
		if nrid: props["default_next_stage"] = f'ExtResource("{nrid}")'
	branching = data.get("branching_transitions", {})
	if branching:
		bprops = {}
		for tid, tsid in branching.items():
			tpath = f"{stage_res_dir}/{_stage_file_name(level_slug, stage_slug_map.get(tsid, _slugify(tsid)))}"
			trid = builder.add_ext_resource(tpath, "Resource")
			if trid: bprops[f'&"{tid}"'] = f'ExtResource("{trid}")'
		props["branching_transitions"] = bprops
	write_tres_file(fs_path, builder.build_tres("Stage", props, generate_deterministic_uid(fs_path), type_hints={"tasks": "Task", "enemy_spawns": "LevelUnitSpawnEntry", "neutral_spawns": "LevelUnitSpawnEntry", "loot_spawns": "LevelLootEntry", "location_spawns": "LevelTaskEntry", "dialogue_entries": "LevelDialogueEntry", "journal_entries": "JournalEntry", "dialogue_journal_entries": "LevelDialogueJournalEntry"}))
	ctx.generated_stage_paths[f"{level_id}_{stage_slug}"] = res_path
	return res_path

def generate_level_tres(ctx: ConversionContext, data: dict, level_dir_fs: str, stage_dir_fs: str, stage_dir_res: str):
	lid = data["level_id"]; level_slug = _slugify(lid); tres_path = os.path.join(level_dir_fs, f"{lid}.tres").replace(os.sep, '/'); uid = generate_deterministic_uid(tres_path)
	builder = ctx.get_builder(); builder.add_ext_resource(SCRIPT_PATHS["Level"], "Script")
	if "terrain" in data:
		td = data["terrain"]; r = td if isinstance(td, list) else td.get("rows", []); w = len(r[0]) if isinstance(td, list) and r else td.get("grid_width", 7); h = len(r) if isinstance(td, list) else td.get("grid_height", 7)
		tid = builder.add_sub_resource("LevelTerrainData", {"grid_width": w, "grid_height": h, "terrain_rows": r})
		terrain_ref = f'SubResource("{tid}")'
	else: terrain_ref = "null"
	obj_data = data["objective"]; stage_defs = obj_data.get("stages", []) or []; stage_slug_map = {s.get("id") or f"stage_{i+1}": _stage_slug(s, i) for i, s in enumerate(stage_defs)}
	stage_refs = [f'ExtResource("{builder.add_ext_resource(generate_stage_tres(ctx, s, stage_dir_fs, stage_dir_res, lid, level_slug, stage_slug_map[s.get("id") or f"stage_{i+1}"], stage_slug_map), "Resource")}")' for i, s in enumerate(stage_defs)]
	obj_props = {"objective_id": f'&"{obj_data["id"]}"', "title": obj_data.get("title", "Objective"), "stages": stage_refs}
	if "journal_entry_id" in obj_data:
		obj_props["journal_entry_id"] = obj_data["journal_entry_id"]
	obj_id = builder.add_sub_resource("Objective", obj_props)
	raw_ps = data.get("player_starts") or data.get("spawns", {}).get("player_starts", []); p_starts = [_json_coord_to_godot_coord(ps, DEFAULT_INVALID_COORD) for ps in raw_ps]
	dname = data.get("display_name", "New Level"); dkey = f"level.{lid}.name"; ctx.dialogue_gen.register_translation(dkey, dname)
	
	raw_weather = data.get("starting_weather", [])
	if isinstance(raw_weather, str): final_weather = [raw_weather]
	elif isinstance(raw_weather, list): final_weather = raw_weather
	else: final_weather = []

	main_props = {
		"display_name": dkey, "level_id": lid, 
		"player_faction_name": data.get("player_faction_name", "Player"), 
		"enemy_faction_name": data.get("enemy_faction_name", "Enemy"), 
		"neutral_faction_name": data.get("neutral_faction_name", "Neutral"), 
		"terrain_data": terrain_ref, "objective": f'SubResource("{obj_id}")', 
		"player_starts": p_starts, "initial_rotation": data.get("initial_rotation", 0.0), 
		"hex_offset_axis": data.get("hex_offset_axis", 1),
		"starting_pressures": final_weather
	}
	write_tres_file(tres_path, builder.build_tres("Level", main_props, uid))

def write_tres_file(file_path, content):
	abs_path = _fs_path_utils(file_path, PROJECT_ROOT); os.makedirs(os.path.dirname(abs_path), exist_ok=True)
	with open(abs_path, "w", encoding="utf-8") as f: f.write(content)
	logger.info(f"Generated: {file_path}")

def _stage_slug(stage: dict, index: int) -> str:
	sid = stage.get("id")
	if sid and isinstance(sid, str) and re.match(r'^[A-Za-z0-9_]+$', sid): return sid
	return f"stage_{index + 1}"

def _stage_file_name(level_slug: str, stage_slug: str) -> str: return f"{level_slug}_{stage_slug}.tres"

def _generate_level_rows(ctx: ConversionContext, data: dict, dirs: dict) -> None:
	lid = data.get('level_id', 'level'); slug = _slugify(lid); targets = [f"{s}_fs" for s in LEVEL_DATA_SUBDIRS if f"{s}_fs" in dirs]
	for k in targets:
		d = dirs.get(k)
		if d:
			for n in os.listdir(d):
				if n.endswith('.tres') and n.startswith(f"{slug}_"):
					try: os.remove(os.path.join(d, n))
					except: pass
	_generate_start_rows(ctx, lid, slug, dirs, data.get('player_starts'))
	stages = data.get('objective', {}).get('stages', []) or []; dname = data.get('display_name') or data.get('objective', {}).get('title') or lid
	_generate_dialogue_rows(ctx, lid, slug, dirs, stages, data); _generate_journal_rows(ctx, lid, slug, dirs, stages, data, dname)
	_generate_roster_rows(ctx, lid, slug, dirs, stages); _generate_loot_rows(ctx, lid, slug, dirs, stages); _generate_location_rows(ctx, lid, slug, dirs, stages)

def convert_json_to_tres(json_path, out_base=DEFAULT_OUTPUT_BASE_DIR):
	ctx = ConversionContext(out_base)
	try:
		with open(json_path, "r", encoding="utf-8") as f: data = json.load(f)
		ctx.validator.validate_level_data(data); lid = data["level_id"]; dirs = _resolve_output_dirs(out_base, lid)
		logger.info(f"Converting level: {lid}"); _generate_level_rows(ctx, data, dirs); generate_level_tres(ctx, data, dirs["levels_fs"], dirs["stages_fs"], dirs["stages_res"])
		ctx.dialogue_gen.flush_translations(); logger.info(f"Done: {lid}")
		preview = ctx.validator.generate_ascii_preview(data.get("terrain", {}).get("rows", []) if isinstance(data.get("terrain"), dict) else data.get("terrain", []), [], data.get("player_starts", []), ctx.validator.validate_connectivity(data))
		_write_level_list_document(lid, dirs["levels_fs"], warnings=ctx.warnings + ctx.validator.conversion_warnings, preview=preview)
		_register_in_catalog(lid, data.get("display_name", lid), f"res://Resources/level_data/{_slugify(lid)}/{_slugify(lid)}.tres")
	except Exception as e: logger.error(f"Error converting {json_path}: {e}", exc_info=True)

def _write_level_list_document(lid, fs_dir, errors=None, warnings=None, preview="") -> None:
	out = os.path.join(fs_dir, "summaries", f"{_slugify(lid)}.txt"); os.makedirs(os.path.dirname(out), exist_ok=True)
	content = f"Generated files for level '{lid}':\n\n"
	if warnings: content += "\n--- WARNINGS ---\n" + "\n".join([f"- {m}" for m in warnings]) + "\n"
	if preview: content += "\n--- TERRAIN PREVIEW ---\n" + preview + "\n"
	if errors: content += "\n--- ERRORS ---\n" + "\n".join([f"- {m}" for m in errors]) + "\n"
	with open(out, "w", encoding="utf-8") as f: f.write(content)

def _register_in_catalog(lid, dname, res_path) -> None:
	path = _fs_path_utils("res://level/level_catalog.gd", PROJECT_ROOT)
	if not os.path.exists(path): return
	with open(path, "r", encoding="utf-8") as f: lines = f.readlines()
	if any(f'"id": "{lid}"' in l for l in lines): return
	idx = -1; in_levels = False
	for i, l in enumerate(lines):
		if "const LEVELS" in l: in_levels = True
		if in_levels and l.strip() == "]": idx = i; break
	if idx != -1:
		lines.insert(idx, f'\t{{"id": "{lid}", "path": "{res_path}", "display_name": "{dname}", "prerequisites": []}},\n')
		with open(path, "w", encoding="utf-8") as f: f.writelines(lines)

if __name__ == "__main__":
	parser = argparse.ArgumentParser(); parser.add_argument("--input", "-i", default=""); parser.add_argument("--output", "-o", default=DEFAULT_OUTPUT_BASE_DIR); args = parser.parse_args()
	path = args.input or os.path.join(PROJECT_ROOT, "Resources", "level_data")
	if os.path.isdir(path):
		for f in glob.glob(os.path.join(path, "**", "*.json"), recursive=True):
			if "template" not in f.lower(): convert_json_to_tres(f, args.output)
	else: convert_json_to_tres(path, args.output)
