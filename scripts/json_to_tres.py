import json
import os
import logging
import argparse
import hashlib
import re
import csv
from file_paths_loader import FilePathsLoader

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

# Initialize FilePaths helper
paths_helper = FilePathsLoader("Resources/file_paths.json")

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

def _fs_path(res_path: str) -> str:
	"""Safely converts a res:// path to an absolute OS filesystem path."""
	if res_path.startswith("res://"):
		return os.path.join(PROJECT_ROOT, res_path[6:]).replace(os.sep, '/')
	elif res_path.startswith("./"):
		return os.path.join(PROJECT_ROOT, res_path[2:]).replace(os.sep, '/')
	return os.path.abspath(res_path).replace(os.sep, '/')

# --- Configuration ---
DEFAULT_OUTPUT_BASE_DIR = (paths_helper.get_path("directories.level_data") or "res://Resources/level_data").rstrip('/')

# Mapping of GDScript class names to their file paths
# We attempt to pull these from file_paths.json via the helper
SCRIPT_PATHS = {
	"Level": paths_helper.get_path("resources.core.level") or "res://level/Level.gd",
	"Objective": paths_helper.get_path("resources.task_system.objective") or "res://Gameplay/narrative/task/objective.gd",
	"Stage": paths_helper.get_path("resources.task_system.stage") or "res://Gameplay/narrative/task/stage.gd",
	"Task": paths_helper.get_path("resources.task_system.task") or "res://Gameplay/narrative/task/task.gd",
	"LevelDialogueEntry": paths_helper.get_path("resources.level_data.level_dialogue_entry") or "res://level/level_dialogue_entry.gd",

	"LevelJournalEntry": paths_helper.get_path("resources.level_data.level_journal_entry") or "res://level/level_journal_entry.gd",
	"LevelDialogueJournalEntry": paths_helper.get_path("resources.level_data.level_dialogue_journal_entry") or "res://level/level_dialogue_journal_entry.gd",
	"LevelTerrainData": paths_helper.get_path("resources.level_data.level_terrain_data") or "res://level/level_terrain_data.gd",
	"UnitRosterDefinition": paths_helper.get_path("resources.rosters.unit_roster_definition") or "res://Gameplay/roster/unit_roster_definition.gd",
	"LevelUnitSpawnEntry": paths_helper.get_path("resources.level_data.level_unit_spawn_entry") or "res://level/level_unit_spawn_entry.gd",
	"LevelLootEntry": paths_helper.get_path("resources.level_data.level_loot_entry") or "res://level/level_loot_entry.gd",
	"LevelTaskEntry": paths_helper.get_path("resources.level_data.level_task_entry") or "res://level/level_task_entry.gd",

	"CompletionCondition": paths_helper.get_path("resources.task_system.completion_condition") or "res://Gameplay/narrative/task/completion_condition.gd",
	"TaskReward": "res://Gameplay/narrative/task/task_reward.gd",
	"CombatStats": "res://level/combat_stats.gd",
}

# Mapping of enum strings to integer values
ENUM_VALUES = {
	"CompletionMode": {
		"ALL_REQUIRED": 0,
		"ANY_REQUIRED": 1,
		"ANY_WITH_BRANCHING": 2,
	},
	"TaskStatus": {
		"PENDING": 0,
		"ACTIVE": 1,
		"COMPLETED": 2,
		"FAILED": 3,
		"CANCELLED": 4,
	},
	"UnitFaction": {
		"PLAYER": 0,
		"ENEMY": 1,
		"NEUTRAL": 2,
	},
	"TaskType": { # Event Type aligned with manager/controller
		"interact": "interact",
		"move": "move",
		"pickup": "pickup",
		"ability_used": "ability_used",
		"dialogue_started": "dialogue_started",
		"explore_zone": "explore_zone",
		"eliminate": "eliminate",
		"countdown": "countdown",
	},
	"TaskRewardType": {
		"ITEM": 0,
		"HINT": 1,
		"UNIT_ADDITION": 2
	}
}

# Global map for cross-referencing
_generated_stage_paths = {}
_conversion_warnings = []

# Sentinel coordinate used when no valid coord is available (1-based Godot space)
DEFAULT_INVALID_COORD = {"x": -999, "y": -999}

# Fallback scenes for missing or invalid paths - pulled from file_paths.json
GENERIC_UNIT_SCENE = paths_helper.get_path("scenes.templates.unit") or "res://Gameplay/scene_templates/generic_unit.tscn"
GENERIC_LOCATION_SCENE = paths_helper.get_path("scenes.templates.location") or "res://Gameplay/scene_templates/location.tscn"
GENERIC_LOOT_SCENE = paths_helper.get_path("scenes.templates.loot") or "res://Gameplay/scene_templates/loot.tscn"


def _resolve_output_dirs(out_base: str, level_id: str = "") -> dict:
	"""Builds filesystem/res paths for level_data outputs, optionally nested by level_id."""
	normalized = out_base.replace('\\', '/')
	if normalized.startswith('./'):
		normalized = 'res://' + normalized[2:].lstrip('/')
	elif not normalized.startswith('res://'):
		normalized = 'res://' + normalized.lstrip('/')
	normalized = normalized.rstrip('/')

	# If level_id is provided, nest everything inside a folder for that level
	if level_id:
		normalized = f"{normalized}/{_slugify(level_id)}"

	fs_root = _fs_path(normalized)

	os.makedirs(fs_root, exist_ok=True)

	def _build(subdir: str):
		fs_dir = os.path.join(fs_root, subdir).replace(os.sep, '/')
		os.makedirs(fs_dir, exist_ok=True)
		res_dir = f"{normalized}/{subdir}"
		return fs_dir, res_dir

	targets = ['stages', 'terrain_rows', 'start_rows', 'roster_rows', 'loot_rows', 'location_rows', 'meta_rows', 'dialogue_rows', 'journal_entry_rows']
	dirs: dict = {
		"levels_fs": fs_root,
		"levels_res": normalized
	}
	for subdir in targets:
		fs_dir, res_dir = _build(subdir)
		dirs[f"{subdir}_fs"] = fs_dir
		dirs[f"{subdir}_res"] = res_dir
	return dirs

# --- Utilities ---

def generate_deterministic_uid(seed_string: str) -> str:
	"""Generates a stable UID string from a seed string."""
	hash_obj = hashlib.md5(seed_string.encode('utf-8'))
	return f"uid://{hash_obj.hexdigest()[:12]}"

def gd_variant_to_tres(value, is_string_name=False):
	"""Converts a Python value to its Godot .tres string representation."""
	if isinstance(value, str):
		# Check if this is already a formatted Godot expression
		if value.startswith(('SubResource(', 'ExtResource(', '&"')):
			return value
		if is_string_name:
			return f'&"{value}"'
		return f'"{value}"'
	elif isinstance(value, bool):
		return str(value).lower()
	elif isinstance(value, (int, float)):
		return str(value)
	elif isinstance(value, list):
		if not value: return "Array[Variant]([])"
		# Type inference
		inner_type = "Variant"
		if len(value) > 0:
			if isinstance(value[0], dict) and "x" in value[0] and "y" in value[0]:
				inner_type = "Vector2i"
			elif str(value[0]).startswith("ExtResource") or str(value[0]).startswith("SubResource"):
				inner_type = "Resource"
			elif isinstance(value[0], str):
				inner_type = "String"
			elif isinstance(value[0], int):
				inner_type = "int"

		items = [gd_variant_to_tres(item) for item in value]
		# Clean up already formatted items (like ExtResource("..."))
		clean_items = []
		for item in items:
			if item.startswith('"') and item.endswith('"') and (item[1:-1].startswith("ExtResource") or item[1:-1].startswith("SubResource")):
				clean_items.append(item[1:-1]) # Remove quotes from pre-formatted resources
			else:
				clean_items.append(item)

		return f'Array[{inner_type}]([{", ".join(clean_items)}])'
	elif isinstance(value, dict):
		if "x" in value and "y" in value and len(value) == 2:
			x = value["x"]
			y = value["y"]
			return f'Vector2i({x}, {y})'
		items = [f'{gd_variant_to_tres(k, is_string_name=(k in ["id", "topic_id", "section_id"]))}: {gd_variant_to_tres(v)}' for k, v in value.items()]
		return f'{{{", ".join(items)}}}'
	elif isinstance(value, tuple) and len(value) in [3, 4]: # Assuming Color if tuple of 3-4 floats
		return f'Color({", ".join(map(str, value))})'
	return 'null' if value is None else str(value)


# --- TresBuilder ---

class TresBuilder:
	def __init__(self):
		self.load_steps = 1 # Start at 1 for the main resource
		self.ext_resources = [] # (path, type, id)
		self.sub_resources = [] # (content, type, id)
		self.next_ext_id_counter = 1
		self.next_sub_id_counter = 1

	def add_ext_resource(self, path: str, type_name: str) -> str:
		"""Adds an external resource and returns its ID (e.g., '1_abcd').
		Returns None if the resource is missing and no fallback is available.
		"""
		# check if already exists
		for p, t, i in self.ext_resources:
			if p == path:
				return i

		original_path = path
		local_path = _fs_path(path)

		# For stage references, they might not exist yet during the conversion loop.
		# We check if the path is inside the stages directory to allow it.
		is_stage_ref = "stages/" in path and path.endswith(".tres")

		if not os.path.exists(local_path) and not path.startswith("user://") and not is_stage_ref:
			if type_name == "PackedScene":
				# Try to determine fallback based on path hints or default to location
				if "unit" in path.lower() or "enemy" in path.lower() or "npc" in path.lower():
					path = GENERIC_UNIT_SCENE
				elif "loot" in path.lower() or "chest" in path.lower():
					path = GENERIC_LOOT_SCENE
				else:
					path = GENERIC_LOCATION_SCENE

				msg = f"Missing PackedScene: {original_path}. Using fallback: {path}"
				logger.warning(msg)
				if msg not in _conversion_warnings:
					_conversion_warnings.append(msg)
			else:
				msg = f"ExtResource missing at {local_path} (referenced as {path}). Skipping."
				logger.warning(msg)
				if msg not in _conversion_warnings:
					_conversion_warnings.append(msg)
				return None

		rid = f"{self.next_ext_id_counter}_{hashlib.md5(path.encode()).hexdigest()[:4]}"
		self.next_ext_id_counter += 1
		self.ext_resources.append((path, type_name, rid))
		self.load_steps += 1
		return rid

	def add_sub_resource(self, script_class: str, properties: dict) -> str:
		"""Adds a sub-resource and returns its ID (e.g., '1_xyzw')."""
		rid = f"{self.next_sub_id_counter}_{hashlib.md5(str(properties).encode()).hexdigest()[:4]}"
		self.next_sub_id_counter += 1

		# Build content for sub resource
		lines = []
		lines.append(f'[sub_resource type="Resource" id="{rid}"]')

		script_path = SCRIPT_PATHS.get(script_class)
		if script_path:
			script_id = self.add_ext_resource(script_path, "Script")
			if script_id:
				lines.append(f'script = ExtResource("{script_id}")')

		for k, v in properties.items():
			lines.append(f'{k} = {gd_variant_to_tres(v)}')

		self.sub_resources.append(("\n".join(lines), "Resource", rid))
		self.load_steps += 1
		return rid

	def build_tres(self, main_script_class: str, main_properties: dict, uid: str = "") -> str:
		"""Generates the full .tres file content."""
		lines = []
		lines.append(f'[gd_resource type="Resource" script_class="{main_script_class}" load_steps={self.load_steps} format=3 uid="{uid}"]')
		lines.append("")

		# Scripts and ExtResources
		# Ensure main script is added
		main_script_path = SCRIPT_PATHS.get(main_script_class)
		if main_script_path:
			# We assume main script is implicitly loaded by class_name in Godot,
			# BUT for .tres it's often explicit. Let's add it if not already.
			# Actually, usually the main resource type="Resource" and script=ExtResource(...)
			pass

		# Sort ext resources by ID for stability? Or insertion order.
		for path, type_name, rid in self.ext_resources:
			lines.append(f'[ext_resource type="{type_name}" path="{path}" id="{rid}"]')

		lines.append("")

		# Sub Resources
		for content, _, _ in self.sub_resources:
			lines.append(content)
			lines.append("")

		# Main Resource
		lines.append('[resource]')
		# Add script ref
		if main_script_path:
			found = False
			for p, _, rid in self.ext_resources:
				if p == main_script_path:
					lines.append(f'script = ExtResource("{rid}")')
					found = True
					break
			if not found:
				# Script wasn't pre-registered; add it now.
				# Note: this happens after load_steps was finalised, so load_steps
				# will be off by one. Callers should register the main script via
				# add_ext_resource() before calling build_tres() to avoid this.
				rid = self.add_ext_resource(main_script_path, "Script")
				lines.insert(2, f'[ext_resource type="Script" path="{main_script_path}" id="{rid}"]')
				lines.append(f'script = ExtResource("{rid}")')

		for k, v in main_properties.items():
			lines.append(f'{k} = {gd_variant_to_tres(v)}')

		return "\n".join(lines)


# --- Resource Object Generators ---

def _apply_stat_overrides(builder: TresBuilder, props: dict, data: dict, defaults: dict) -> None:
	"""Applies stat overrides from data to props by creating a CombatStats sub-resource."""
	stats = ["grit", "flow", "gusto", "focus", "shine", "shade", "willpower"]

	has_any = any(stat in data for stat in stats)
	has_defaults = any(stat in defaults for stat in stats)
	if not has_any and not has_defaults:
		return

	stat_props = {}
	for stat in stats:
		if stat in data:
			stat_props[stat] = data[stat]
		elif stat in defaults:
			stat_props[stat] = defaults[stat]

	stat_id = builder.add_sub_resource("CombatStats", stat_props)
	props["stats"] = f'SubResource("{stat_id}")'

# build_level_unit_spawn_entry removed here (using the one at 497)

def _extract_loot_items(builder: TresBuilder, data: dict) -> list:
	"""Extracts item resource paths from either 'items' (new format) or 'item_resource_path' (legacy)."""
	item_refs = []

	# Try new format first (array of items)
	items_list = data.get("items", []) or []
	if items_list:
		for item_path in items_list:
			if not item_path:
				continue
			iid = builder.add_ext_resource(item_path, "Resource")
			if iid:
				item_refs.append(f'ExtResource("{iid}")')

	# Fallback to legacy single item path
	legacy_path = data.get("item_resource_path")
	if legacy_path:
		logger.warning("Found 'item_resource_path' in loot spawn. This format is deprecated; please use 'items' (array) instead.")
		iid = builder.add_ext_resource(legacy_path, "Resource")
		if iid and f'ExtResource("{iid}")' not in item_refs:
			item_refs.append(f'ExtResource("{iid}")')

	return item_refs

def build_level_loot_entry(builder: TresBuilder, data: dict) -> str:
	props = {}
	props["coord"] = _json_coord_to_godot_coord(data.get("coord", DEFAULT_INVALID_COORD))
	props["items"] = _extract_loot_items(builder, data)
	props["is_trapped"] = bool(data.get("is_trapped", False))
	_apply_stat_overrides(builder, props, data, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 1})

	return builder.add_sub_resource("LevelLootEntry", props)

def _generate_dialogue_line_id(level_id: str, entry_id: str, line_index: int) -> str:
	"""Generates a stable, unique ID for a dialogue line."""
	seed = f"{level_id}_{entry_id}_{line_index}"
	return hashlib.md5(seed.encode()).hexdigest()[:8]

def _register_translation(key: str, text: str):
	"""Registers or updates a translation key in translations.csv. Preserves existing translations."""
	if not key or not text:
		return
		
	csv_path = _fs_path("res://Resources/Localization/translations.csv")
	if not os.path.exists(csv_path):
		return
		
	rows = []
	header = []
	updated = False
	found = False
	
	try:
		with open(csv_path, 'r', encoding='utf-8') as f:
			reader = csv.reader(f)
			header = next(reader)
			for row in reader:
				if row and row[0] == key:
					found = True
					# Update source text if it changed
					if len(row) > 1 and row[1] != text:
						row[1] = text
						updated = True
				rows.append(row)
	except Exception as e:
		logger.error(f"Failed to read translations.csv: {e}")
		return
		
	if not found:
		new_row = [key, text] + ([""] * (len(header) - 2))
		rows.append(new_row)
		updated = True
		
	if updated:
		try:
			with open(csv_path, 'w', encoding='utf-8', newline='') as f:
				writer = csv.writer(f)
				writer.writerow(header)
				writer.writerows(rows)
		except Exception as e:
			logger.error(f"Failed to write translations.csv: {e}")

def _register_line_for_translation(line_id: str, text: str):
	"""Legacy wrapper for dialogue lines."""
	_register_translation(line_id, text)

def _ensure_dialogue_file_exists(level_id: str, dialogue_entry_id: str, title: str = "", description: str = "", template_type: str = "DEFAULT", next_info: str = "") -> str:
	# Construct the new path based on requirements - now inside level-specific folder
	level_slug = _slugify(level_id)
	entry_slug = _slugify(dialogue_entry_id)

	dialogues_base_dir_res = f"{DEFAULT_OUTPUT_BASE_DIR}/{level_slug}/dialogues"
	dialogues_base_dir_fs = _fs_path(dialogues_base_dir_res)

	# Add level prefix to dialogue filename for global uniqueness/consistency
	new_filename = f"{level_slug}_{entry_slug}.dialogue"
	new_resource_path = f"{dialogues_base_dir_res}/{new_filename}"
	new_local_path = f"{dialogues_base_dir_fs}/{new_filename}"

	if not os.path.exists(new_local_path):
		os.makedirs(os.path.dirname(new_local_path), exist_ok=True)
		
		# Helper to generate ID and register for translation
		def _line(speaker: str, text: str, index: int) -> str:
			line_id = f"L{_generate_dialogue_line_id(level_id, dialogue_entry_id, index)}"
			_register_line_for_translation(line_id, text)
			return f"{speaker}: {text} [ID:{line_id}]"

		# Select template content based on context
		if template_type == "STAGE_EXIT_TERMINAL":
			lines = [
				"if is_victory",
				f"\t{_line('Hero', 'The mission was a success! The objective is secure.', 0)}",
				f"\t{_line('Villager', 'You have done a great service today.', 1)}",
				"else",
				f"\t{_line('Hero', 'We have failed. The objective was lost.', 2)}",
				f"\t{_line('Villager', 'Retreat and regroup! We will find another way.', 3)}",
				"=> END"
			]
			content = "~ start\n" + "\n".join(lines) + "\n"
		elif template_type == "STAGE_EXIT_TRANSITION":
			line0 = _line('Hero', 'We have finished our work here for now.', 0)
			next_text = next_info if next_info else "the next area"
			line1 = _line('Hero', f'We must move on to our next objective: {next_text}.', 1)
			lines = [line0, line1, "=> END"]
			content = "~ start\n" + "\n".join(lines) + "\n"
		else:
			# Standard placeholder
			line0 = _line('Hero', f'[Title: {title if title else dialogue_entry_id}]', 0)
			line1 = _line('Hero', f'[Objective: {description if description else "Auto-generated placeholder"}]', 1)
			line2 = _line('Hero', f"This is a placeholder for '{dialogue_entry_id}'.", 2)
			line3 = _line('Villager', 'Indeed it is.', 3)
			lines = [line0, line1, line2, line3]
			content = "~ start\n" + "\n".join(lines) + "\n"
			
		try:
			with open(new_local_path, "w", encoding="utf-8") as f:
				f.write(content)
			logger.info(f"Created placeholder dialogue file ({template_type}): {new_resource_path}")
		except IOError as e:
			logger.error(f"Failed to create placeholder dialogue file {new_resource_path}: {e}")

	return new_resource_path


# Keys shared by dialogue entry types; StringName keys are formatted with & prefix
_DIALOGUE_PRE_FORMAT_KEYS = {"group_id", "entry_id", "flag_name"}
_DIALOGUE_COPY_KEYS = [
	"entry_id", "flag_name", "initiator_name", "partner_name", "group_id",
	"action_label", "action_hint", "repeatable", "requires_adjacent",
	"consume_action", "allow_partner_initiation"
]

def _apply_dialogue_props(props: dict, data: dict) -> None:
	"""Populates props with shared dialogue fields from data."""
	for k in _DIALOGUE_COPY_KEYS:
		if k in data:
			props[k] = f'&"{data[k]}"' if k in _DIALOGUE_PRE_FORMAT_KEYS else data[k]
	if "coord" in data:
		props["coord"] = _json_coord_to_godot_coord(data["coord"])
	if "partner_faction" in data:
		props["partner_faction"] = ENUM_VALUES["UnitFaction"].get(str(data["partner_faction"]).upper(), 0)


def build_level_dialogue_entry(builder: TresBuilder, data: dict, level_id: str) -> str:
	props = {}
	_apply_dialogue_props(props, data)
	dialogue_entry_id = data.get("entry_id") or data.get("group_id") or f"dialogue_{len(builder.sub_resources)}"
	title = data.get("action_label", dialogue_entry_id)
	props["dialogue_resource_path"] = _ensure_dialogue_file_exists(level_id, dialogue_entry_id, title=title)
	return builder.add_sub_resource("LevelDialogueEntry", props)


def build_level_journal_entry(builder: TresBuilder, data: dict) -> str:
	props = {}
	entry_id = data.get("entry_id", data.get("id", ""))
	if entry_id:
		props["id"] = entry_id
	for k in ["title", "unlocked", "entry_type", "status", "related_id", "topic_id", "section_id"]:
		if k in data:
			props[k] = data[k]
	if "content" in data:
		props["content"] = data["content"]
	elif "notes" in data:
		props["content"] = data["notes"]
	if "flag_name" in data:
		props["flag_name"] = f'&"{data["flag_name"]}"'
	if "level_id" in data:
		props["level_id"] = f'&"{data["level_id"]}"'
	return builder.add_sub_resource("LevelJournalEntry", props)


def build_level_dialogue_journal_entry(builder: TresBuilder, data: dict, level_id: str) -> str:
	props = {}
	_apply_dialogue_props(props, data)
	dialogue_entry_id = data.get("entry_id") or data.get("group_id") or f"dialogue_journal_{len(builder.sub_resources)}"
	props["dialogue_resource_path"] = _ensure_dialogue_file_exists(level_id, dialogue_entry_id)

	# Journal props use journal_* prefixed property names on the resource.
	# The JSON uses bare keys (entry_id, flag_name, etc.) which are shared with
	# the dialogue side — journal_entry_id on the resource maps from data["entry_id"].
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

def build_level_unit_spawn_entry(builder: TresBuilder, data: dict, faction: str = 'enemy') -> str:
	props = {}
	faction_int = ENUM_VALUES["UnitFaction"].get(str(faction).upper(), 1)
	props['faction'] = faction_int
	props['coord'] = _json_coord_to_godot_coord(data.get('coord', DEFAULT_INVALID_COORD))

	unit_scene_path = data.get('unit_scene_path')
	is_player = (faction_int == 0) # PLAYER

	if not unit_scene_path and not is_player:
		unit_scene_path = GENERIC_UNIT_SCENE
		logger.warning(f"Unit spawn missing 'unit_scene_path' in JSON. Using fallback: {unit_scene_path}")

	if unit_scene_path:
		unit_ext = builder.add_ext_resource(unit_scene_path, 'PackedScene')
		if unit_ext:
			props['unit_scene'] = f'ExtResource("{unit_ext}")'

	if "slot_index" in data:
		props["slot_index"] = data["slot_index"]

	if "unit_name" in data:
		props["unit_name"] = data["unit_name"]

	if "inventory" in data:
		props["inventory"] = [] # Simplified for now, inventory items are usually paths

	_apply_stat_overrides(builder, props, data, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 10})

	return builder.add_sub_resource("LevelUnitSpawnEntry", props)

def build_level_task_entry(builder: TresBuilder, data: dict, level_id: str = "") -> str:
	props = {}
	props["coord"] = _json_coord_to_godot_coord(data.get("coord", DEFAULT_INVALID_COORD))

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
		_register_translation(name_key, location_name)
		_register_translation(desc_key, location_desc)
		props["location_name"] = name_key
		props["description"] = desc_key
	else:
		props["location_name"] = location_name
		props["description"] = location_desc

	_apply_stat_overrides(builder, props, data, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 10})

	return builder.add_sub_resource("LevelTaskEntry", props)

def build_task_reward(builder: TresBuilder, data: dict) -> str:
	props = {
		"reward_type": data.get("reward_type", "ITEM"),
		"reward_value": data.get("reward_value", "")
	}
	# Convert Enum string to int
	props["reward_type"] = ENUM_VALUES["TaskRewardType"].get(props["reward_type"].upper(), 0)
	return builder.add_sub_resource("TaskReward", props)

def build_task(builder: TresBuilder, data: dict, level_id: str = "") -> str:
	props = {}
	task_id = data.get('id', 'task')
	props['id'] = f'&"{task_id}"'
	
	copy_keys = [
		"event_type", "target_id", "target_kind",
		"effort_required", "is_optional", "is_opposed",
		"opposition_value", "journal_entry_id", "reward_id", "dialogue_id", "enter_journal_id",
		"exit_journal_id", "duration_turns", "duration_mode"
	]

	for k in copy_keys:
		if k in data:
			props[k] = data[k]

	# Localize Title and Description
	title_text = data.get('title', 'New Task')
	desc_text = data.get('description', '')
	
	if level_id:
		title_key = f"level.{level_id}.task.{task_id}.title"
		desc_key = f"level.{level_id}.task.{task_id}.desc"
		_register_translation(title_key, title_text)
		_register_translation(desc_key, desc_text)
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

	# Handle StringNames explicitly
	for k in ["id", "dialogue_id", "enter_dialogue_id", "exit_dialogue_id", "duration_mode"]:
		if k in props:
			val = props[k]
			props[k] = f'&"{val}"' # Force StringName format

	if "reward_resource" in data:
		reward_id = build_task_reward(builder, data["reward_resource"])
		props["reward_resource"] = f'SubResource("{reward_id}")'

	if "target_coord" in data:
		props["target_coord"] = _json_coord_to_godot_coord(data["target_coord"])
	else:
		props["target_coord"] = {"x": -999, "y": -999}

	if "zone_coords" in data:
		props["zone_coords"] = [_json_coord_to_godot_coord(c) for c in data["zone_coords"]]
	else:
		props["zone_coords"] = []

	if "on_enter" in data:
		oe = data["on_enter"]
		if "dialogue_id" in oe:
			dialogue_id = oe["dialogue_id"]
			if level_id:
				title = data.get("title", dialogue_id)
				desc = data.get("description", "Stage/Task Enter Dialogue")
				dialogue_path = _ensure_dialogue_file_exists(level_id, dialogue_id, title=title, description=desc)
				props["start_dialogue_resource"] = dialogue_path
			props["enter_dialogue_id"] = f'&"{dialogue_id}"'
		if "journal_id" in oe: props["enter_journal_id"] = oe["journal_id"]

	if "on_exit" in data:
		ox = data["on_exit"]
		if "dialogue_id" in ox:
			dialogue_id = ox["dialogue_id"]
			if level_id:
				title = data.get("title", dialogue_id)
				desc = data.get("description", "Stage/Task Exit Dialogue")
				dialogue_path = _ensure_dialogue_file_exists(level_id, dialogue_id, title=title, description=desc)
				props["exit_dialogue_resource"] = dialogue_path
			props["exit_dialogue_id"] = f'&"{dialogue_id}"'
		if "journal_id" in ox: props["exit_journal_id"] = ox["journal_id"]

	if "on_fail" in data:
		of = data["on_fail"]
		if "dialogue_id" in of:
			dialogue_id = of["dialogue_id"]
			if level_id:
				title = data.get("title", dialogue_id)
				desc = data.get("description", "Stage/Task Failure Dialogue")
				dialogue_path = _ensure_dialogue_file_exists(level_id, dialogue_id, title=title, description=desc)
				props["failure_dialogue_resource"] = dialogue_path
			props["failure_dialogue_id"] = f'&"{dialogue_id}"'
		if "journal_id" in of: props["failure_journal_id"] = of["journal_id"]

	if "completion_condition" in data:
		cc = data["completion_condition"]
		cc_props = {
			"type": cc.get("type", "DEFEAT_ALL_UNITS_OF_FACTION"),
			"faction": ENUM_VALUES["UnitFaction"].get(cc.get("faction", "ENEMY"), 1)
		}
		cc_id = builder.add_sub_resource("CompletionCondition", cc_props)
		props["completion_condition"] = f'SubResource("{cc_id}")'

	return builder.add_sub_resource("Task", props)


def _slugify(value: str) -> str:
	sanitized = re.sub(r'[^A-Za-z0-9_]+', '_', str(value))
	sanitized = sanitized.strip('_')
	return sanitized or 'level'


def _stage_slug(stage: dict, index: int) -> str:
	sid = stage.get("id")
	if sid and isinstance(sid, str):
		# Only use if it looks like a safe filename
		if re.match(r'^[A-Za-z0-9_]+$', sid):
			return sid
	# IMPORTANT: We use 1-based indexing for stage fallbacks (stage_1, stage_2...)
	# to align with designer expectations and other level data conventions.
	return f"stage_{index + 1}"


def _stage_file_name(level_slug: str, stage_slug: str) -> str:
	return f"{level_slug}_{stage_slug}.tres"



def _to_faction(value) -> int:
	if isinstance(value, int):
		return value
	mapping = {'player': 0, 'ally': 0, 'enemy': 1, 'foe': 1, 'neutral': 2, 'npc': 2}
	key = str(value).strip().lower()
	return mapping.get(key, 0)


def _clear_existing_rows(level_slug: str, dirs: dict) -> None:
	for key in ('stages_fs', 'terrain_rows_fs', 'start_rows_fs', 'roster_rows_fs', 'loot_rows_fs', 'location_rows_fs', 'meta_rows_fs', 'dialogue_rows_fs', 'journal_entry_rows_fs'):
		_remove_prefixed_files(dirs.get(key), level_slug)


def _remove_prefixed_files(fs_dir: str, prefix: str) -> None:
	if not fs_dir:
		return
	os.makedirs(fs_dir, exist_ok=True)
	for name in os.listdir(fs_dir):
		if not name.endswith('.tres'):
			continue
		if name.startswith(f"{prefix}_"):
			try:
				os.remove(os.path.join(fs_dir, name))
			except OSError as err:
				logger.warning(f"Failed to remove old row file {name}: {err}")


def _generate_level_rows(data: dict, dirs: dict) -> None:
	level_id = data.get('level_id', 'level')
	level_slug = _slugify(level_id)
	_clear_existing_rows(level_slug, dirs)
	player_starts = data.get('player_starts') or []
	_generate_start_rows(level_id, level_slug, dirs, player_starts)
	stages = data.get('objective', {}).get('stages', []) or []
	# Global generation is disabled for these because stage-specific content
	# is now embedded directly in the Stage .tres files to avoid doubling
	# and to support deferred spawning during stage transitions.
	# _generate_roster_rows(level_id, level_slug, dirs, stages)
	# _generate_loot_rows(level_id, level_slug, dirs, stages)
	# _generate_location_rows(level_id, level_slug, dirs, stages)
	_generate_dialogue_rows(level_id, level_slug, dirs, stages)
	_generate_journal_rows(level_id, level_slug, dirs, stages)






def _generate_start_rows(level_id: str, level_slug: str, dirs: dict, starts: list) -> None:
	if not starts:
		return
	for idx, raw in enumerate(starts):
		faction = 'player'
		slot_index = idx
		coord = raw
		unit_scene_path = None
		if isinstance(raw, dict):
			faction = str(raw.get('faction', 'player'))
			slot_index = raw.get('slot_index', idx)
			coord = raw.get('coord', {k: raw.get(k, 0) for k in ('x', 'y')})
			unit_scene_path = raw.get('unit_scene_path')
		res_path = f"{dirs['start_rows_res']}/{level_slug}_start_{_slugify(faction)}_{slot_index}.tres"
		builder = TresBuilder()
		builder.add_ext_resource(SCRIPT_PATHS['LevelUnitSpawnEntry'], 'Script')
		props = {
			'level_id': f'&"{level_id}"',
			'faction': ENUM_VALUES["UnitFaction"].get(str(faction).upper(), 0),
			'slot_index': slot_index,
			'coord': _json_coord_to_godot_coord(coord),
			'notes': ''
		}
		if unit_scene_path:
			unit_ext = builder.add_ext_resource(unit_scene_path, 'PackedScene')
			if unit_ext:
				props['unit_scene'] = f'ExtResource("{unit_ext}")'

		# Ensure player starts have valid stats (willpower > 0) so they aren't skipped in turn order
		_apply_stat_overrides(builder, props, raw if isinstance(raw, dict) else {}, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 10})

		content = builder.build_tres('LevelUnitSpawnEntry', props, generate_deterministic_uid(res_path))
		write_tres_file(res_path, content)


def _generate_roster_rows(level_id: str, level_slug: str, dirs: dict, stages: list) -> None:
	counters: dict = {}
	for index, stage in enumerate(stages):
		stage_slug = _stage_slug(stage, index)
		stage_id = stage.get('id', '')
		for spawn in stage.get('enemy_spawns', []) or []:
			_write_roster_row(level_id, level_slug, stage_slug, dirs, spawn, 'enemy', counters, stage_id)
		for spawn in stage.get('neutral_spawns', []) or []:
			_write_roster_row(level_id, level_slug, stage_slug, dirs, spawn, 'neutral', counters, stage_id)

def _write_roster_row(level_id: str, level_slug: str, stage_slug: str, dirs: dict, spawn: dict, faction: str, counters: dict, stage_id: str) -> None:
	unit_scene_path = spawn.get('unit_scene_path')
	if not unit_scene_path:
		return
	key = (stage_slug, faction)
	count = counters.get(key, 0)
	counters[key] = count + 1
	filename = f"{level_slug}_{stage_slug}_{_slugify(faction)}_{count}.tres"
	res_path = f"{dirs['roster_rows_res']}/{filename}"
	builder = TresBuilder()
	builder.add_ext_resource(SCRIPT_PATHS['LevelUnitSpawnEntry'], 'Script')
	unit_ext = builder.add_ext_resource(unit_scene_path, 'PackedScene')
	props = {
		'level_id': f'&"{level_id}"',
		'faction': ENUM_VALUES["UnitFaction"].get(str(faction).upper(), 1),
		'coord': _json_coord_to_godot_coord(spawn.get('coord', DEFAULT_INVALID_COORD)),
		'notes': stage_id or ''
	}
	if unit_ext:
		props['unit_scene'] = f'ExtResource("{unit_ext}")'
	_apply_stat_overrides(builder, props, spawn, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 10})

	content = builder.build_tres('LevelUnitSpawnEntry', props, generate_deterministic_uid(res_path))
	write_tres_file(res_path, content)


def _generate_loot_rows(level_id: str, level_slug: str, dirs: dict, stages: list) -> None:
	counters: dict = {}
	for index, stage in enumerate(stages):
		stage_slug = _stage_slug(stage, index)
		stage_id = stage.get('id', '')
		count = counters.get(stage_slug, 0)
		for loot in stage.get('loot_spawns', []) or []:
			res_path = f"{dirs['loot_rows_res']}/{level_slug}_{stage_slug}_loot_{count}.tres"
			builder = TresBuilder()
			builder.add_ext_resource(SCRIPT_PATHS['LevelLootEntry'], 'Script')

			props = {
				'level_id': f'&"{level_id}"',
				'coord': _json_coord_to_godot_coord(loot.get('coord', DEFAULT_INVALID_COORD)),
				'items': _extract_loot_items(builder, loot),
				'notes': stage_id or ''
			}
			props["is_trapped"] = bool(loot.get("is_trapped", False))
			_apply_stat_overrides(builder, props, loot, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 1})

			content = builder.build_tres('LevelLootEntry', props, generate_deterministic_uid(res_path))
			write_tres_file(res_path, content)
			count += 1
		counters[stage_slug] = count


def _generate_location_rows(level_id: str, level_slug: str, dirs: dict, stages: list) -> None:
	counters: dict = {}
	for index, stage in enumerate(stages):
		stage_slug = _stage_slug(stage, index)
		stage_id = stage.get('id', '')
		count = counters.get(stage_slug, 0)
		for loc in stage.get('location_spawns', []) or []:
			scene_path = loc.get('location_scene_path')
			if not scene_path:
				continue
			res_path = f"{dirs['location_rows_res']}/{level_slug}_{stage_slug}_location_{count}.tres"
			builder = TresBuilder()
			builder.add_ext_resource(SCRIPT_PATHS['LevelTaskEntry'], 'Script')
			scene_ext = builder.add_ext_resource(scene_path, 'PackedScene')
			props = {
				'level_id': f'&"{level_id}"',
				'coord': _json_coord_to_godot_coord(loc.get('coord', DEFAULT_INVALID_COORD)),
				'location_name': loc.get('location_name') or loc.get('id', ''),
				'notes': stage_id or ''
			}
			if scene_ext:
				props['location_scene'] = f'ExtResource("{scene_ext}")'
			_apply_stat_overrides(builder, props, loc, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 10})

			content = builder.build_tres('LevelTaskEntry', props, generate_deterministic_uid(res_path))
			write_tres_file(res_path, content)
			count += 1
		counters[stage_slug] = count



def _generate_dialogue_rows(level_id: str, level_slug: str, dirs: dict, stages: list) -> None:
	counters: dict = {}
	for index, stage in enumerate(stages):
		stage_slug = _stage_slug(stage, index)
		stage_id = stage.get('id', '')
		count = counters.get(stage_slug, 0)

		# Standard entries (do NOT include stage on_enter/on_exit - those are handled via start_dialogue_resource/exit_dialogue_resource)
		combined: list[tuple[dict, bool]] = []
		for e in (stage.get('dialogue_entries', []) or []):
			combined.append((e, False))
		for e in (stage.get('dialogue_journal_entries', []) or []):
			combined.append((e, False))

		# Tasks on_enter/on_exit
		for task in stage.get("tasks", []):
			task_id = task.get("id", "task")
			if "on_enter" in task and "dialogue_id" in task["on_enter"]:
				toe = task["on_enter"]
				if isinstance(toe.get("dialogue_id"), str):
					new_entry = toe.copy()
					new_entry["entry_id"] = toe["dialogue_id"]
					new_entry["notes"] = f"Task {task_id} on_enter"
					combined.append((new_entry, True))
			if "on_exit" in task and "dialogue_id" in task["on_exit"]:
				tox = task["on_exit"]
				if isinstance(tox.get("dialogue_id"), str):
					new_entry = tox.copy()
					new_entry["entry_id"] = tox["dialogue_id"]
					new_entry["notes"] = f"Task {task_id} on_exit"
					combined.append((new_entry, True))

		for entry, is_auto_trigger in combined:
			res_path = f"{dirs['dialogue_rows_res']}/{level_slug}_{stage_slug}_dialogue_{count}.tres"
			builder = TresBuilder()
			builder.add_ext_resource(SCRIPT_PATHS['LevelDialogueEntry'], 'Script')
			entry_id = entry.get('entry_id') or entry.get('journal_entry_id') or f"{stage_slug}_dialogue_{count}"
			initiator = entry.get('initiator_name', '')
			partner = entry.get('partner_name', '')
			flag_name = entry.get('flag_name', '')
			group_id = entry.get('group_id', stage_id or '')

			# For on_enter/on_exit dialogues, we set specific flags
			# If no coordinate is provided, we assume it's a logical trigger and doesn't require adjacency.
			default_requires = ("coord" in entry) and (not is_auto_trigger)
			requires_adjacent = entry.get('requires_adjacent', default_requires)
			consume_action = entry.get('consume_action', not is_auto_trigger)
			allow_partner = entry.get('allow_partner_initiation', is_auto_trigger)

			props = {
				'level_id': f'&"{level_id}"',
				'entry_id': f'&"{entry_id}"',
				'initiator_name': f'&"{initiator}"',
				'partner_name': f'&"{partner}"',
				'partner_faction': _to_faction(entry.get('partner_faction', 'neutral')),
				'coord': _json_coord_to_godot_coord(entry.get('coord', DEFAULT_INVALID_COORD)),
				'dialogue_resource_path': _ensure_dialogue_file_exists(level_id, entry_id),
				'flag_name': f'&"{flag_name}"',
				'action_label': entry.get('action_label', ''),
				'action_hint': entry.get('action_hint', ''),
				'repeatable': bool(entry.get('repeatable', False)),
				'requires_adjacent': bool(requires_adjacent),
				'consume_action': bool(consume_action),
				'group_id': f'&"{group_id}"',
				'allow_partner_initiation': bool(allow_partner),
				'notes': entry.get('notes', stage_id or '')
			}
			content = builder.build_tres('LevelDialogueEntry', props, generate_deterministic_uid(res_path))
			write_tres_file(res_path, content)
			count += 1
		counters[stage_slug] = count



def _generate_journal_rows(level_id: str, level_slug: str, dirs: dict, stages: list) -> None:
	counters: dict = {}
	for index, stage in enumerate(stages):
		stage_slug = _stage_slug(stage, index)
		stage_id = stage.get('id', '')
		count = counters.get(stage_slug, 0)
		# Use a dict to deduplicate by ID. Detailed entries take precedence.
		journal_map: dict[str, dict] = {}

		def _add_to_combined(entries):
			if not entries: return
			for entry in entries:
				jid = entry.get('id') or entry.get('entry_id') or entry.get('journal_entry_id')
				if not jid: continue
				# If we have an existing entry with content/title, keep it
				existing = journal_map.get(jid)
				if existing and (existing.get('content') or existing.get('title')):
					# Only overwrite if current also has content (unlikely to need merge)
					if entry.get('content') or entry.get('title'):
						journal_map[jid] = entry
				else:
					journal_map[jid] = entry

		_add_to_combined(stage.get('journal_entries', []))
		_add_to_combined(stage.get('dialogue_journal_entries', []))

		# Add stage on_enter/on_exit journal entries
		if "on_enter" in stage and "journal_id" in stage["on_enter"]:
			jid = stage["on_enter"].get("journal_id")
			if jid and jid not in journal_map:
				journal_map[jid] = {
					"id": jid,
					"title": f"Stage {stage_id} Started",
					"notes": f"Stage {stage_id} on_enter",
					"section_id": "progress",
					"entry_type": "trigger"
				}

		if "on_exit" in stage and "journal_id" in stage["on_exit"]:
			jid = stage["on_exit"].get("journal_id")
			if jid and jid not in journal_map:
				journal_map[jid] = {
					"id": jid,
					"title": f"Stage {stage_id} Completed",
					"notes": f"Stage {stage_id} on_exit",
					"section_id": "progress",
					"entry_type": "trigger"
				}

		# Add task on_enter/on_exit journal entries
		for task in (stage.get("tasks", []) or []):
			task_id = task.get("id", "task")
			for hook in ["on_enter", "on_exit"]:
				h_data = task.get(hook, {})
				jid = h_data.get("journal_id")
				if jid and jid not in journal_map:
					journal_map[jid] = {
						"id": jid,
						"title": f"Task {task_id} {hook.replace('on_', '').capitalize()}",
						"notes": f"Task {task_id} {hook}",
						"section_id": "progress",
						"entry_type": "trigger"
					}

		for j_id, entry in journal_map.items():
			res_path = f"{dirs['journal_entry_rows_res']}/{level_slug}_{stage_slug}_journal_{count}.tres"
			builder = TresBuilder()
			builder.add_ext_resource(SCRIPT_PATHS['LevelJournalEntry'], 'Script')
			journal_id = entry.get('journal_entry_id') or entry.get('id') or entry.get('entry_id') or f"{stage_slug}_journal_{count}"
			title = entry.get('journal_title') or entry.get('title') or entry.get('action_label') or journal_id
			content_text = entry.get('journal_content') or entry.get('content') or entry.get('journal_notes') or entry.get('notes', '')
			flag_name = entry.get('flag_name', '')
			topic_id = entry.get('journal_topic_id', entry.get('topic_id', level_id))
			section_id = entry.get('journal_section_id', entry.get('section_id', ''))
			related_id = entry.get('related_id') or entry.get('entry_id') or journal_id
			props = {
				'level_id': f'&"{level_id}"',
				'flag_name': f'&"{flag_name}"',
				'id': journal_id,
				'title': title,
				'content': content_text,
				'unlocked': bool(entry.get('unlocked', False)),
				'topic_id': topic_id,
				'section_id': section_id,
				'entry_type': entry.get('entry_type', 'generic'),
				'status': entry.get('status', 'available'),
				'related_id': related_id
			}
			content = builder.build_tres('LevelJournalEntry', props, generate_deterministic_uid(res_path))
			write_tres_file(res_path, content)
			count += 1
		counters[stage_slug] = count



def generate_stage_tres(
	data: dict,
	stage_fs_dir: str,
	stage_res_dir: str,
	level_id: str,
	level_slug: str,
	stage_slug: str,
	stage_slug_map: dict,
):
	filename = _stage_file_name(level_slug, stage_slug)
	tres_path = os.path.join(stage_fs_dir, filename).replace(os.sep, '/')
	stage_res_path = f"{stage_res_dir}/{filename}"
	uid = generate_deterministic_uid(tres_path)

	builder = TresBuilder()
	builder.add_ext_resource(SCRIPT_PATHS["Stage"], "Script")  # Ensure script is referenced

	# Process Tasks
	task_refs = []
	stage_tasks = data.get("tasks", []) or []
	stage_locations = data.get("location_spawns", []) or []
	stage_loot = data.get("loot_spawns", []) or []

	for i, t_data in enumerate(stage_tasks):
		logger.info(f"DEBUG: Processing task {i} in stage {stage_slug}")
		# Sync effort_required and target_coord with target willpower for locations/traps
		target_id = t_data.get("target_id")
		target_coord = t_data.get("target_coord")
		target_willpower = None
		linked_coord = None

		if target_id and target_id != "loot":
			for loc in stage_locations:
				lid = loc.get("id") or loc.get("location_name")
				if lid == target_id:
					target_willpower = loc.get("willpower")
					linked_coord = loc.get("coord")
					break

		if target_willpower is None and target_coord:
			for loc in stage_locations:
				if loc.get("coord") == target_coord:
					target_willpower = loc.get("willpower")
					linked_coord = loc.get("coord")
					break
			if target_willpower is None:
				for loot in stage_loot:
					if loot.get("coord") == target_coord:
						target_willpower = loot.get("willpower")
						linked_coord = loot.get("coord")
						break

		# If we have no target_coord but we found a linked_coord by ID, use it
		if not target_coord and linked_coord:
			logger.info(f"Task '{t_data.get('id')}' missing target_coord. Syncing to linked target '{target_id}' at {linked_coord}.")
			t_data["target_coord"] = linked_coord
			target_coord = linked_coord

		if target_willpower is not None:
			if "effort_required" not in t_data:
				t_data["effort_required"] = target_willpower
			elif t_data["effort_required"] != target_willpower:
				logger.info(f"Task '{t_data.get('id')}' effort_required ({t_data['effort_required']}) misaligned with target willpower ({target_willpower}). Syncing to willpower.")
				t_data["effort_required"] = target_willpower

		trid = build_task(builder, t_data, level_id)
		task_refs.append(f'SubResource("{trid}")')

	# Validation: Ensure at least one mandatory task if mode is ALL_REQUIRED
	if data.get("completion_mode", "ALL_REQUIRED") == "ALL_REQUIRED":
		has_mandatory = any(not t.get("is_optional", False) for t in stage_tasks)
		if not has_mandatory and stage_tasks:
			msg = f"[Validation] Stage '{stage_slug}' has no mandatory tasks but is in ALL_REQUIRED mode. It will never advance automatically."
			logger.warning(msg)
			if msg not in _conversion_warnings: _conversion_warnings.append(msg)

	# Process Spawns
	# Embedded in the Stage .tres for stage-specific activation.
	enemy_spawn_refs = []
	for s_data in data.get("enemy_spawns", []):
		srid = build_level_unit_spawn_entry(builder, s_data, 'enemy')
		enemy_spawn_refs.append(f'SubResource("{srid}")')

	neutral_spawn_refs = []
	for s_data in data.get("neutral_spawns", []):
		srid = build_level_unit_spawn_entry(builder, s_data, 'neutral')
		neutral_spawn_refs.append(f'SubResource("{srid}")')

	loot_refs = []
	for l_data in data.get("loot_spawns", []):
		lrid = build_level_loot_entry(builder, l_data)
		loot_refs.append(f'SubResource("{lrid}")')

	location_refs = []
	for l_data in data.get("location_spawns", []):
		lrid = build_level_task_entry(builder, l_data)
		location_refs.append(f'SubResource("{lrid}")')

	dialogue_refs = []
	for d_data in data.get("dialogue_entries", []):
		drid = build_level_dialogue_entry(builder, d_data, level_id)
		dialogue_refs.append(f'SubResource("{drid}")')

	journal_refs = []
	for j_data in data.get("journal_entries", []):
		jrid = build_level_journal_entry(builder, j_data)
		journal_refs.append(f'SubResource("{jrid}")')

	dialogue_journal_refs = []
	for dj_data in data.get("dialogue_journal_entries", []):
		djrid = build_level_dialogue_journal_entry(builder, dj_data, level_id)
		dialogue_journal_refs.append(f'SubResource("{djrid}")')

	# Main Stage Props
	props = {
		"id": f'&"{stage_slug}"',
		"tasks": task_refs,
		"completion_mode": ENUM_VALUES["CompletionMode"].get(data.get("completion_mode", "ALL_REQUIRED"), 0),
		"auto_advance": data.get("auto_advance", True),
		"enemy_spawns": enemy_spawn_refs,
		"neutral_spawns": neutral_spawn_refs,
		"loot_spawns": loot_refs,
		"location_spawns": location_refs,
		"dialogue_entries": dialogue_refs,
		"journal_entries": journal_refs,
		"dialogue_journal_entries": dialogue_journal_refs,
		"spawns": [],
	}

	# Detect stage flow for dialogue templates
	next_id = data.get("default_next_stage_id")
	branching = data.get("branching_transitions", {})
	is_terminal = not next_id and not branching

	# On Enter/Exit
	if "on_enter" in data:
		oe = data["on_enter"]
		if "dialogue_id" in oe:
			dialogue_id = oe["dialogue_id"]
			dialogue_path = _ensure_dialogue_file_exists(level_id, dialogue_id)
			props["start_dialogue_resource"] = dialogue_path
			props["enter_dialogue_id"] = f'&"{dialogue_id}"'
		if "journal_id" in oe:
			props["enter_journal_id"] = oe["journal_id"]

	if "on_exit" in data:
		ox = data["on_exit"]
		if "dialogue_id" in ox:
			dialogue_id = ox["dialogue_id"]
			# Use context-aware template for stage exits
			ttype = "STAGE_EXIT_TERMINAL" if is_terminal else "STAGE_EXIT_TRANSITION"
			next_info = next_id if next_id else ("multiple paths" if branching else "")
			dialogue_path = _ensure_dialogue_file_exists(level_id, dialogue_id, template_type=ttype, next_info=next_info)
			props["exit_dialogue_resource"] = dialogue_path
			props["exit_dialogue_id"] = f'&"{dialogue_id}"'
		if "journal_id" in ox:
			props["exit_journal_id"] = ox["journal_id"]

	if "on_fail" in data:
		of = data["on_fail"]
		if "dialogue_id" in of:
			dialogue_id = of["dialogue_id"]
			dialogue_path = _ensure_dialogue_file_exists(level_id, dialogue_id)
			props["failure_dialogue_resource"] = dialogue_path
			props["failure_dialogue_id"] = f'&"{dialogue_id}"'
		if "journal_id" in of:
			props["failure_journal_id"] = of["journal_id"]

	# Next Stage Reference handling (External)
	next_id = data.get("default_next_stage_id")
	if next_id:
		next_slug = stage_slug_map.get(next_id, _slugify(next_id))
		next_path = f"{stage_res_dir}/{_stage_file_name(level_slug, next_slug)}"
		nid = builder.add_ext_resource(next_path, "Resource")
		if nid:
			props["default_next_stage"] = f'ExtResource("{nid}")'

	# Branching Transitions
	branching_data = data.get("branching_transitions", {})
	if branching_data:
		branching_props = {}
		for task_id, target_stage_id in branching_data.items():
			target_slug = stage_slug_map.get(target_stage_id, _slugify(target_stage_id))
			target_path = f"{stage_res_dir}/{_stage_file_name(level_slug, target_slug)}"
			tid = builder.add_ext_resource(target_path, "Resource")
			if tid:
				branching_props[f'&"{task_id}"'] = f'ExtResource("{tid}")'
		props["branching_transitions"] = branching_props

	content = builder.build_tres("Stage", props, uid)
	write_tres_file(tres_path, content)
	_generated_stage_paths[f"{level_id}_{stage_slug}"] = stage_res_path
	return stage_res_path



def generate_level_tres(data: dict, level_dir_fs: str, stage_dir_fs: str, stage_dir_res: str):
	lid = data["level_id"]
	level_slug = _slugify(lid)
	tres_path = os.path.join(level_dir_fs, f"{lid}.tres").replace(os.sep, '/')
	uid = generate_deterministic_uid(tres_path)

	builder = TresBuilder()
	builder.add_ext_resource(SCRIPT_PATHS["Level"], "Script")

	# Terrain
	if "terrain" in data:
		t_data = data["terrain"]
		if isinstance(t_data, list):
			# Array of strings format
			rows = t_data
			grid_width = len(rows[0]) if rows else 0
			grid_height = len(rows)
		else:
			# Object format
			rows = t_data.get("rows", [])
			grid_width = t_data.get("grid_width", 7)
			grid_height = t_data.get("grid_height", 7)

		t_props = {
			"grid_width": grid_width,
			"grid_height": grid_height,
			"terrain_rows": rows
		}
		tid = builder.add_sub_resource("LevelTerrainData", t_props)
		terrain_ref = f'SubResource("{tid}")'
	else:
		terrain_ref = "null"

	# Objective
	obj_data = data["objective"]
	stage_defs = obj_data.get("stages", []) or []
	stage_slug_map: dict = {}
	for index, s_data in enumerate(stage_defs):
		stage_id = s_data.get("id") or f"stage_{index + 1}"
		stage_slug_map[stage_id] = _stage_slug(s_data, index)

	stage_refs = []
	for index, s_data in enumerate(stage_defs):
		stage_id = s_data.get("id") or f"stage_{index + 1}"
		stage_slug = stage_slug_map.get(stage_id, _stage_slug(s_data, index))
		stage_res_path = generate_stage_tres(
			s_data,
			stage_dir_fs,
			stage_dir_res,
			lid,
			level_slug,
			stage_slug,
			stage_slug_map,
		)
		srid = builder.add_ext_resource(stage_res_path, "Resource")
		if srid:
			stage_refs.append(f'ExtResource("{srid}")')

	obj_props = {
		"objective_id": f'&"{obj_data["id"]}"',
		"title": obj_data.get("title", "Objective"),
		"stages": stage_refs
	}
	obj_id = builder.add_sub_resource("Objective", obj_props)

	# Player Starts
	raw_p_starts = []
	if "player_starts" in data:
		raw_p_starts = data["player_starts"]
	elif "spawns" in data and "player_starts" in data["spawns"]:
		raw_p_starts = data["spawns"]["player_starts"]

	p_starts = []
	for ps in raw_p_starts:
		p_starts.append(_json_coord_to_godot_coord(ps))

	# Main Level Props
	display_name_text = data.get("display_name", "New Level")
	display_name_key = f"level.{lid}.name"
	_register_translation(display_name_key, display_name_text)

	main_props = {
		"display_name": display_name_key,
		"level_id": lid,
		"terrain_data": terrain_ref,
		"objective": f'SubResource("{obj_id}")',
		"player_starts": p_starts,
		"initial_rotation": data.get("initial_rotation", 0.0),
		"hex_offset_axis": data.get("hex_offset_axis", 1)
	}

	content = builder.build_tres("Level", main_props, uid)
	write_tres_file(tres_path, content)


def write_tres_file(file_path, content):
	"""Writes content to a .tres file."""
	abs_path = _fs_path(file_path)
	os.makedirs(os.path.dirname(abs_path), exist_ok=True)
	with open(abs_path, "w", encoding="utf-8") as f:
		f.write(content)
	logger.info(f"Generated: {file_path}")


def _json_coord_to_godot_coord(json_coord) -> dict:
	"""Converts a 0-based JSON coord (dict or list) to a 0-based Godot coord dict.
	The sentinel value -999 is preserved as-is."""
	if json_coord is None:
		return {"x": -999, "y": -999}
	if isinstance(json_coord, list) and len(json_coord) >= 2:
		return {"x": int(json_coord[0]), "y": int(json_coord[1])}
	if isinstance(json_coord, dict):
		if "x" in json_coord and "y" in json_coord:
			return {"x": int(json_coord["x"]), "y": int(json_coord["y"])}
		if "coord" in json_coord:
			return _json_coord_to_godot_coord(json_coord["coord"])
	return {"x": -999, "y": -999}

def _is_godot_coord_in_bounds(coord: dict, width: int, height: int) -> bool:
	"""Returns True if a Godot coord dict is within the grid bounds."""
	x = coord.get("x", -999)
	y = coord.get("y", -999)
	return 0 <= x < width and 0 <= y < height


def validate_level_data(data: dict):
	"""Deep validation of level JSON structure."""
	required_root = ["level_id", "display_name", "objective"]
	for key in required_root:
		if key not in data:
			raise ValueError(f"Missing required root key: '{key}'")

	obj = data["objective"]
	if "stages" not in obj:
		raise ValueError("Objective must have 'stages'")

	s_ids = set()
	for i, stage in enumerate(obj["stages"]):
		if "id" not in stage:
			raise ValueError(f"Stage at index {i} is missing 'id'")
		if stage["id"] in s_ids:
			raise ValueError(f"Duplicate stage ID: {stage['id']}")
		s_ids.add(stage["id"])

		# Check coordinates in stage
		for group in ["enemy_spawns", "neutral_spawns", "loot_spawns", "location_spawns", "dialogue_entries"]:
			for entry in stage.get(group, []):
				if "coord" in entry:
					c = _json_coord_to_godot_coord(entry["coord"])
					if c["x"] < 0 or c["y"] < 0:
						if c["x"] != -999:
							logger.warning(f"Negative coordinate found in {group} of stage {stage['id']}: {c}")

	# Check player starts
	for start in (data.get("player_starts") or []):
		if isinstance(start, dict):
			if start.get("x", 0) < 0 or start.get("y", 0) < 0:
				logger.warning(f"Negative coordinate found in player_starts: {start}")

	# Cross-validate dialogue/journal links by shared key
	_validate_dialogue_journal_links_json(data)

	# Validate terrain connectivity
	reachable = _validate_connectivity_json(data)


def _validate_connectivity_json(data: dict):
	"""
	Verifies that all points of interest (starts, spawns, targets) are reachable
	from the primary player start given the terrain layout.
	"""
	if "terrain" not in data:
		return

	t_data = data["terrain"]
	if isinstance(t_data, list):
		rows = t_data
		width = len(rows[0]) if rows else 0
		height = len(rows)
	else:
		rows = t_data.get("rows", [])
		width = t_data.get("grid_width", 7)
		height = t_data.get("grid_height", 7)

	axis = data.get("hex_offset_axis", 1)  # Default: Vertical/Flat-top

	# Impassable codes (synchronized with TerrainMap.gd and terrain scripts)
	# 2: Waterfall, 3: Lava, R: River, W: Wall, 4: Mountain Peak
	impassable_codes = {"2", "3", "R", "W", "4"}

	player_starts = data.get("player_starts", [])
	if not player_starts:
		return

	# Collect all POIs (0-based coordinates from JSON)
	pois = []
	for ps in player_starts:
		if isinstance(ps, dict):
			pois.append(ps.get("coord") or ps)
		else:
			pois.append(ps)

	for stage in data.get("objective", {}).get("stages", []):
		for group in ["enemy_spawns", "neutral_spawns", "loot_spawns", "location_spawns"]:
			for entry in stage.get(group, []):
				if "coord" in entry:
					pois.append(entry["coord"])
		for task in stage.get("tasks", []):
			if "target_coord" in task:
				pois.append(task["target_coord"])

	if not pois:
		return

	# Start BFS from first player start
	start = _json_coord_to_godot_coord(pois[0])
	sx, sy = start["x"], start["y"]
	if sx == -999:
		return

	if sy >= len(rows) or sx >= len(rows[sy]):
		logger.warning(f"[Connectivity] Primary player start ({sx}, {sy}) is out of bounds.")
		return

	if rows[sy][sx] in impassable_codes:
		msg = f"[Connectivity] Primary player start at ({sx}, {sy}) is on impassable terrain '{rows[sy][sx]}'"
		logger.warning(msg)
		_conversion_warnings.append(msg)
		return

	reachable = set()
	queue = [(sx, sy)]
	reachable.add((sx, sy))

	while queue:
		cx, cy = queue.pop(0)

		# Hex neighbors
		if axis == 1:  # Vertical / Flat-top / Odd-column stagger
			# In 1-based logic, col 1 is odd. In 0-based, cx=0 is col 1.
			if (cx + 1) % 2 != 0:
				offsets = [(0, -1), (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0)]
			else:
				offsets = [(0, -1), (1, -1), (1, 0), (0, 1), (-1, 0), (-1, -1)]
		else:  # Horizontal / Pointy-top / Odd-row stagger
			if (cy + 1) % 2 != 0:
				offsets = [(1, 0), (1, -1), (0, -1), (-1, 0), (0, 1), (1, 1)]
			else:
				offsets = [(1, 0), (0, -1), (-1, -1), (-1, 0), (-1, 1), (0, 1)]

		for dx, dy in offsets:
			nx, ny = cx + dx, cy + dy
			if 0 <= ny < len(rows) and 0 <= nx < len(rows[ny]):
				if (nx, ny) not in reachable and rows[ny][nx] not in impassable_codes:
					reachable.add((nx, ny))
					queue.append((nx, ny))

	# Check all POIs
	for p in pois:
		pc = _json_coord_to_godot_coord(p)
		px, py = pc["x"], pc["y"]
		if px == -999 or py == -999:
			continue
		if (px, py) not in reachable:
			msg = f"[Connectivity] Point of interest at ({px}, {py}) is unreachable from player start"
			logger.warning(msg)
			_conversion_warnings.append(msg)

	return reachable


def _generate_ascii_preview(rows: list, pois: list, player_starts: list, reachable: set = None) -> str:
	"""
	Generates an ASCII grid representation of the terrain with POIs and player starts.
	"""
	if not rows:
		return ""

	height = len(rows)
	width = max(len(r) for r in rows)

	grid = [list(r) for r in rows]

	# Add Markers
	for p in pois:
		pc = _json_coord_to_godot_coord(p)
		px, py = pc["x"], pc["y"]
		if 0 <= py < height and 0 <= px < len(grid[py]):
			if reachable is not None and (px, py) not in reachable:
				grid[py][px] = "!" # Unreachable POI
			else:
				grid[py][px] = "L" # Location/POI

	for s in player_starts:
		sc = _json_coord_to_godot_coord(s)
		sx, sy = sc["x"], sc["y"]
		if 0 <= sy < height and 0 <= sx < len(grid[sy]):
			grid[sy][sx] = "P" # Player Start

	lines = []
	header = "   " + "".join([str(i % 10) for i in range(width)])
	lines.append(header)
	for y, row in enumerate(grid):
		line = f"{y:2} {''.join(row)}"
		lines.append(line)

	legend = "\nLegend: P=Start, L=POI, !=Unreachable POI, .=Empty, R=Ruin, W=Water"
	return "\n".join(lines) + legend


def _validate_dialogue_journal_links_json(data: dict) -> None:
	"""
	Verifies that dialogue entries have matching journal entries and vice versa using a shared key.
	Keying rules:
	- Dialogue key: entry.entry_id (for dialogue_entries/dialogue_journal_entries) or on_enter/on_exit dialogue_id in tasks.
	- Journal key: entry.related_id if present; else entry.entry_id if present; else None (ignored).
	Emits warnings for mismatches but does not raise to avoid hard-stopping authoring.
	"""
	obj = data.get("objective", {})
	stages = obj.get("stages", [])
	for index, stage in enumerate(stages):
		# Use 1-based indexing for stage fallbacks to match _stage_slug convention
		stage_id = stage.get("id", f"stage_{index + 1}")

		# Collect dialogue keys and explicit links
		dialogue_ids = set()
		journal_keys = set()
		explicit_links = set() # Set of (dialogue_id, journal_id)

		def _account_link(d_id, j_id):
			if d_id: dialogue_ids.add(d_id)
			if j_id: journal_keys.add(j_id)
			if d_id and j_id: explicit_links.add((d_id, j_id))

		# Stage level on_enter/on_exit
		oe = stage.get("on_enter", {})
		_account_link(oe.get("dialogue_id"), oe.get("journal_id"))
		ox = stage.get("on_exit", {})
		_account_link(ox.get("dialogue_id"), ox.get("journal_id"))

		for entry in (stage.get("dialogue_entries", []) or []):
			key = entry.get("entry_id") or entry.get("journal_entry_id")
			if isinstance(key, str) and key:
				dialogue_ids.add(key)

		for entry in (stage.get("dialogue_journal_entries", []) or []):
			key = entry.get("entry_id") or entry.get("journal_entry_id")
			if isinstance(key, str) and key:
				dialogue_ids.add(key)
			rel = entry.get("related_id")
			if rel: journal_keys.add(rel)

		# Tasks with on_enter/on_exit
		for task in (stage.get("tasks", []) or []):
			toe = task.get("on_enter", {})
			_account_link(toe.get("dialogue_id"), toe.get("journal_id"))
			tox = task.get("on_exit", {})
			_account_link(tox.get("dialogue_id"), tox.get("journal_id"))

		# Standard Journal Entries
		for entry in (stage.get("journal_entries", []) or []):
			key = entry.get("related_id") or entry.get("entry_id") or entry.get("id") or entry.get("journal_entry_id")
			if isinstance(key, str) and key:
				journal_keys.add(key)

		# Compute diffs and warn
		missing_journal = sorted([k for k in dialogue_ids if k not in journal_keys])
		if missing_journal:
			msg = f"[Dialogue/Journal] Stage '{stage_id}' dialogue IDs with no matching journal related_id: {missing_journal}"
			logger.warning(msg)
			if msg not in _conversion_warnings: _conversion_warnings.append(msg)

		missing_dialogue = sorted([k for k in journal_keys if k not in dialogue_ids])
		if missing_dialogue:
			msg = f"[Dialogue/Journal] Stage '{stage_id}' journal related_ids with no matching dialogue entry_id: {missing_dialogue}"
			logger.warning(msg)
			if msg not in _conversion_warnings: _conversion_warnings.append(msg)


def validate_and_ensure_scripts():
	"""Checks if all scripts in SCRIPT_PATHS exist and creates minimalist ones if missing."""
	for class_name, res_path in SCRIPT_PATHS.items():
		local_path = _fs_path(res_path)
		if not os.path.exists(local_path):
			logger.warning(f"Script for {class_name} missing at {local_path}. Creating minimal resource script.")
			os.makedirs(os.path.dirname(local_path), exist_ok=True)
			with open(local_path, "w", encoding="utf-8") as f:
				# Add default properties for known classes to avoid errors
				f.write(f"class_name {class_name}\n")
				if class_name == "CompletionCondition":
					f.write("extends Resource\n\n")
					f.write("@export var type: String = \"DEFEAT_ALL_UNITS_OF_FACTION\"\n")
					f.write("@export var faction: int = 1 # ENEMY\n")
				else:
					f.write("extends Resource\n")

def convert_json_to_tres(json_path, out_base=DEFAULT_OUTPUT_BASE_DIR):
	global _generated_stage_paths, _conversion_warnings
	_generated_stage_paths = {}
	_conversion_warnings = []
	validate_and_ensure_scripts()
	errors_encountered = []
	lid = "unknown_level"
	dirs: dict = {}
	try:
		if not os.path.exists(json_path):
			logger.error(f"Input file not found: {json_path}")
			errors_encountered.append(f"Input file not found: {json_path}")
			return

		with open(json_path, "r", encoding="utf-8") as f:
			data = json.load(f)
		validate_level_data(data)

		lid = data["level_id"]
		dirs = _resolve_output_dirs(out_base, lid)

		level_target = os.path.join(dirs["levels_fs"], f"{lid}.tres").replace(os.sep, '/')
		logger.info(f"Converting level: {lid} -> {level_target}")
		_generate_level_rows(data, dirs)
		generate_level_tres(data, dirs["levels_fs"], dirs["stages_fs"], dirs["stages_res"])
		logger.info(f"Done: {lid}")

	except Exception as e:
		logger.error(f"Error converting {json_path}: {e}", exc_info=True)
		errors_encountered.append(f"Error converting {json_path}: {e}")
	finally:
		levels_dir = dirs.get("levels_fs") or _fs_path(os.path.join(out_base, lid))

		# Collect preview data
		preview = ""
		try:
			with open(json_path, "r", encoding="utf-8") as f:
				data = json.load(f)
			reachable = _validate_connectivity_json(data)
			terrain = data.get("terrain", [])
			if isinstance(terrain, dict): terrain = terrain.get("rows", [])

			# Collect all POIs from all stages and tasks
			pois = []
			for stage in data.get("objective", {}).get("stages", []):
				pois.extend(stage.get("location_spawns", []))
				for task in stage.get("tasks", []):
					if "target_coord" in task:
						pois.append(task["target_coord"])

			starts = data.get("player_starts", [])
			preview = _generate_ascii_preview(terrain, pois, starts, reachable)
		except Exception as e:
			logger.debug(f"Preview generation failed: {e}")

		_write_level_list_document(lid, levels_dir, errors=errors_encountered, warnings=_conversion_warnings, preview=preview)

		# Auto-register if no errors
		if not errors_encountered:
			try:
				_register_in_catalog(lid, data.get("display_name", lid), f"res://Resources/level_data/{_slugify(lid)}/{_slugify(lid)}.tres")
			except Exception as e:
				logger.warning(f"Failed to auto-register in LevelCatalog: {e}")


def _write_level_list_document(level_id: str, levels_fs_dir: str, errors: list = None, warnings: list = None, preview: str = "") -> None:
	"""Writes a document listing the generated level files for a given level, including any errors."""
	if errors is None:
		errors = []
	if warnings is None:
		warnings = []

	# Define the new output directory for summaries
	summaries_base_dir_fs = os.path.join(levels_fs_dir, "summaries")

	# Construct the new file path with level_id as filename
	output_file_name = f"{_slugify(level_id)}.txt"
	output_file_path = os.path.join(summaries_base_dir_fs, output_file_name)

	level_slug = _slugify(level_id)
	all_generated_files = []

	# Define all relevant output directories relative to the base output directory
	output_base_dir_fs = levels_fs_dir # Base is the level directory directly
	relevant_subdirs = [
		"", "stages", "start_rows",
		"roster_rows", "loot_rows", "location_rows",
		"dialogue_rows", "journal_entry_rows"
	]

	for subdir in relevant_subdirs:
		full_subdir_path = os.path.join(output_base_dir_fs, subdir) if subdir else output_base_dir_fs
		if os.path.exists(full_subdir_path):
			for f_name in os.listdir(full_subdir_path):
				if f_name.endswith(".tres") and f_name.startswith(level_slug):
					relative_path = os.path.join(subdir, f_name).replace(os.sep, '/')
					all_generated_files.append(relative_path)

	all_generated_files.sort() # Sort for consistent output

	content = f"Generated files for level '{level_id}':\n\n"
	if not all_generated_files:
		content += "No associated TRES files found for this level.\n"
	else:
		for f_name in all_generated_files:
			content += f"- {f_name}\n"

	if warnings:
		content += "\n--- WARNINGS / FALLBACKS ---\n"
		for warn_msg in warnings:
			content += f"- {warn_msg}\n"

	if preview:
		content += "\n--- TERRAIN PREVIEW ---\n"
		content += preview + "\n"

	if errors:
		content += "\n--- ERRORS ENCOUNTERED ---\n"
		for error_msg in errors:
			content += f"- {error_msg}\n"

	try:
		os.makedirs(os.path.dirname(output_file_path), exist_ok=True)
		with open(output_file_path, "w", encoding="utf-8") as f:
			f.write(content)
		logger.info(f"Generated level list document: {output_file_path}")
	except IOError as e:
		logger.error(f"Failed to write level list document {output_file_path}: {e}")
def _register_in_catalog(level_id: str, display_name: str, res_path: str) -> None:
	catalog_path = _fs_path("res://level/level_catalog.gd")
	if not os.path.exists(catalog_path):
		return

	with open(catalog_path, "r", encoding="utf-8") as f:
		lines = f.readlines()

	# Check if already registered
	for line in lines:
		if f'"id": "{level_id}"' in line:
			return

	# Find the closing bracket of the LEVELS array
	# It's usually a line containing only ']' before any function definitions
	insert_idx = -1
	in_levels = False
	for i, line in enumerate(lines):
		if "const LEVELS" in line:
			in_levels = True
		if in_levels and line.strip() == "]":
			insert_idx = i
			break

	if insert_idx != -1:
		entry = f'\t{{"id": "{level_id}", "path": "{res_path}", "display_name": "{display_name}", "prerequisites": []}},\n'
		lines.insert(insert_idx, entry)
		with open(catalog_path, "w", encoding="utf-8") as f:
			f.writelines(lines)
		logger.info(f"Auto-registered level '{level_id}' in LevelCatalog.gd")

def generate_template(filename: str) -> None:
	template = {
		"id": "new_level",
		"level_id": "new_level",
		"display_name": "New Level Template",
		"terrain": [
			"..........",
			"..........",
			"....R.....",
			"..........",
			"P........E"
		],
		"objective": {
			"id": "obj_main",
			"title": "Main Objective",
			"stages": [
				{
					"id": "stage_1",
					"on_enter": {"dialogue_id": "welcome", "journal_id": "start"},
					"location_spawns": [
						{
							"location_name": "Ancient Ruin",
							"coord": [4, 2],
							"willpower": 1
						}
					],
					"tasks": [
						{
							"id": "task_1",
							"title": "Explore Ruin",
							"description": "Investigate the status of the ancient ruins.",
							"event_type": "explore_zone",
							"target_coord": [4, 2],
							"target_kind": "location"
						}
					]
				}
			]
		},
		"player_starts": [[0, 4]]
	}
	with open(filename, "w", encoding="utf-8") as f:
		json.dump(template, f, indent=4)
	print(f"Generated level template: {filename}")

if __name__ == "__main__":
	parser = argparse.ArgumentParser(description="Convert Level JSON to Godot Resources")
	parser.add_argument("--input", "-i", default="", help="Path to input JSON")
	parser.add_argument("--template", "-t", default="", help="Generate a new level template JSON")
	parser.add_argument("--output", "-o", default=DEFAULT_OUTPUT_BASE_DIR, help="Output base directory")
	parser.add_argument("--verbose", "-v", action="store_true", help="Enable verbose logging")
	args = parser.parse_args()

	if args.verbose: logger.setLevel(logging.DEBUG)

	if args.template:
		generate_template(args.template)
	elif args.input:
		convert_json_to_tres(args.input, args.output)
	else:
		parser.print_help()
