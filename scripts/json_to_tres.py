import json
import os
import logging
import argparse
import re
import csv
import hashlib
from file_paths_loader import FilePathsLoader
from tres_builder import TresBuilder
from conversion_utils import fs_path as _fs_path_utils, generate_deterministic_uid, slugify as _slugify, copy_props as _copy_props
from conversion_config import SCRIPT_PATHS, LEVEL_DATA_SUBDIRS, ENUM_VALUES, GENERIC_UNIT_SCENE, GENERIC_LOCATION_SCENE, GENERIC_LOOT_SCENE, paths_helper

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

def _fs_path(res_path: str) -> str:
	return _fs_path_utils(res_path, PROJECT_ROOT)

def _get_builder() -> TresBuilder:
	"""Helper to create a TresBuilder with standard configuration."""
	return TresBuilder(SCRIPT_PATHS, GENERIC_UNIT_SCENE, GENERIC_LOCATION_SCENE, GENERIC_LOOT_SCENE, _fs_path)

# --- Configuration ---
DEFAULT_OUTPUT_BASE_DIR = (paths_helper.get_path("directories.level_data") or "res://Resources/level_data").rstrip('/')

# Global map for cross-referencing
_generated_stage_paths = {}
_conversion_warnings = []

# Sentinel coordinate used when no valid coord is available (0-based Godot space)
DEFAULT_INVALID_COORD = {"x": -999, "y": -999}
_translation_buffer = {} # Global buffer for translations to avoid redundant disk I/O


def _resolve_hook_ids(hook_data, dialogue_ids=None, journal_keys=None, task_data=None) -> tuple[str, str]:
	"""
	Resolves a hook (list, dict, or string) into a (dialogue_id, journal_id) tuple.
	If a list is provided, the IDs are split based on known dialogue/journal IDs.
	If task_data is provided and has a title, the journal_id is derived from it.
	"""
	if not hook_data:
		return None, None

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
	
	# Rule: Use Task Title as Journal Entry ID if available
	if task_data and "title" in task_data and j_id:
		j_id = _slugify(task_data["title"]).lower()
	
	return d_id, j_id


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

	targets = [s for s in LEVEL_DATA_SUBDIRS if s != 'summaries']
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

def _copy_props(target: dict, data: dict, keys: list, type_map: dict = None) -> None:
	"""
	Utility to copy keys from data to target.
	If type_map is provided, keys in it will be formatted (e.g., StringName with &").
	"""
	if type_map is None:
		type_map = {}
	for k in keys:
		if k in data:
			val = data[k]
			if k in type_map and type_map[k] == "StringName":
				target[k] = f'&"{val}"'
			else:
				target[k] = val


# --- TresBuilder ---

class TresBuilder:
	def __init__(self):
		self.load_steps = 1 # Start at 1 for the main resource
		self.ext_resources = [] # (path, type, id)
		self.sub_resources = [] # (content, type, id)
		self.next_ext_id_counter = 1
		self.next_sub_id_counter = 1

	def gd_variant_to_tres(self, value, is_string_name=False, inner_type_hint=None):
		"""Converts a Python value to its Godot .tres string representation."""
		if isinstance(value, str):
			# Check for pre-formatted Resource references
			if value.startswith("ExtResource(") or value.startswith("SubResource(") or value.startswith("&"):
				return value
			if is_string_name:
				return f'&"{value}"'
			return f'"{value}"'
		elif isinstance(value, bool):
			return str(value).lower()
		elif isinstance(value, (int, float)):
			return str(value)
		elif isinstance(value, list):
			# Type inference if no hint provided
			inner_type = inner_type_hint or "Variant"

			# Resolve script class to ExtResource if necessary
			if inner_type_hint in SCRIPT_PATHS:
				script_path = SCRIPT_PATHS[inner_type_hint]
				rid = self.add_ext_resource(script_path, "Script")
				if rid:
					inner_type = f'ExtResource("{rid}")'

			if not inner_type_hint and len(value) > 0:
				if isinstance(value[0], dict) and "x" in value[0] and "y" in value[0]:
					inner_type = "Vector2i"
				elif str(value[0]).startswith("ExtResource") or str(value[0]).startswith("SubResource"):
					inner_type = "Resource"
				elif isinstance(value[0], str):
					inner_type = "String"
				elif isinstance(value[0], int):
					inner_type = "int"

			items = [self.gd_variant_to_tres(item) for item in value]
			# Clean up already formatted items (like ExtResource("..."))
			clean_items = []
			for item in items:
				if item.startswith('"') and item.endswith('"') and (item[1:-1].startswith("ExtResource") or item[1:-1].startswith("SubResource")):
					clean_items.append(item[1:-1]) # Remove quotes from pre-formatted resources
				else:
					clean_items.append(item)

			if inner_type == "Variant":
				return f"[{', '.join(clean_items)}]"
			return f'Array[{inner_type}]([{ ", ".join(clean_items) }])'
		elif isinstance(value, dict):
			if "x" in value and "y" in value and len(value) == 2:
				x = value["x"]
				y = value["y"]
				return f'Vector2i({x}, {y})'
			items = [f"{self.gd_variant_to_tres(k, is_string_name=(k in ['id', 'topic_id', 'section_id']))}: {self.gd_variant_to_tres(v)}" for k, v in value.items()]
			return f'{{{ ", ".join(items) }}}'
		elif isinstance(value, tuple) and len(value) in [3, 4]: # Assuming Color if tuple of 3-4 floats
			return f'Color({ ", ".join(map(str, value)) })'
		return 'null' if value is None else str(value)

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

	def add_sub_resource(self, script_class: str, properties: dict, type_hints: dict = None) -> str:
		"""Adds a sub-resource and returns its ID (e.g., '1_xyzw')."""
		if type_hints is None:
			type_hints = {}
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
			hint = type_hints.get(k)
			lines.append(f'{k} = {self.gd_variant_to_tres(v, inner_type_hint=hint)}')

		self.sub_resources.append(("\n".join(lines), "Resource", rid))
		self.load_steps += 1
		return rid

	def build_tres(self, main_script_class: str, main_properties: dict, uid: str = "", type_hints: dict = None) -> str:
		"""Generates the full .tres file content."""
		if type_hints is None:
			type_hints = {}

		# Pre-process main properties to discover any needed resources (e.g. from type_hints)
		main_res_lines = []

		# Ensure main script is added
		main_script_path = SCRIPT_PATHS.get(main_script_class)
		if main_script_path:
			self.add_ext_resource(main_script_path, "Script")

		for k, v in main_properties.items():
			hint = type_hints.get(k)
			main_res_lines.append(f'{k} = {self.gd_variant_to_tres(v, inner_type_hint=hint)}')

		lines = []
		lines.append(f'[gd_resource type="Resource" script_class="{main_script_class}" load_steps={self.load_steps} format=3 uid="{uid}"]')
		lines.append("")

		# Scripts and ExtResources
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

		lines.extend(main_res_lines)

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

def build_inventory_item(builder: TresBuilder, item_data) -> str:
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

def build_level_loot_entry(builder: TresBuilder, data: dict) -> str:
	props = {}
	_copy_props(props, data, ["is_trapped"])
	props["coord"] = _json_coord_to_godot_coord(data.get("coord", DEFAULT_INVALID_COORD))
	props["items"] = _extract_loot_items(builder, data)
	_apply_stat_overrides(builder, props, data, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 1})

	type_hints = {"items": "InventoryItem"}
	return builder.add_sub_resource("LevelLootEntry", props, type_hints=type_hints)

def _generate_dialogue_line_id(level_id: str, entry_id: str, line_index: int) -> str:
	"""Generates a stable, unique ID for a dialogue line."""
	seed = f"{level_id}_{entry_id}_{line_index}"
	return hashlib.md5(seed.encode()).hexdigest()[:8]

def _register_translation(key: str, text: str):
	"""Registers or updates a translation key in the global buffer."""
	if not key or not text:
		return
	_translation_buffer[key] = text


def _flush_translations():
	"""Writes all buffered translations to translations.csv in one pass."""
	if not _translation_buffer:
		return

	csv_res_path = paths_helper.get_path("directories.localization") + "translations.csv" if paths_helper.get_path("directories.localization") else "res://Resources/Localization/translations.csv"
	csv_path = _fs_path(csv_res_path)
	if not os.path.exists(csv_path):
		logger.warning(f"translations.csv not found at {csv_path}. Skipping flush.")
		return

	rows = []
	header = []
	found_keys = set()
	updated_count = 0

	try:
		with open(csv_path, 'r', encoding='utf-8') as f:
			reader = csv.reader(f)
			header = next(reader)
			for row in reader:
				if row:
					key = row[0]
					if key in _translation_buffer:
						new_text = _translation_buffer[key]
						if len(row) > 1 and row[1] != new_text:
							row[1] = new_text
							updated_count += 1
						found_keys.add(key)
					rows.append(row)
	except Exception as e:
		logger.error(f"Failed to read translations.csv during flush: {e}")
		return

	# Add new keys
	for key, text in _translation_buffer.items():
		if key not in found_keys:
			new_row = [key, text] + ([""] * (len(header) - 2))
			rows.append(new_row)
			updated_count += 1

	if updated_count > 0:
		try:
			with open(csv_path, 'w', encoding='utf-8', newline='') as f:
				writer = csv.writer(f)
				writer.writerow(header)
				writer.writerows(rows)
			logger.info(f"Flushed translations: {updated_count} updates/new entries.")
		except Exception as e:
			logger.error(f"Failed to write translations.csv during flush: {e}")


def _register_line_for_translation(line_id: str, text: str):
	"""Legacy wrapper for dialogue lines."""
	_register_translation(line_id, text)

def _ensure_dialogue_file_exists(level_id: str, dialogue_entry_id: str, title: str = "", description: str = "", template_type: str = "DEFAULT", next_info: str = "", metadata: dict = None) -> str:
	level_slug = _slugify(level_id)
	entry_slug = _slugify(dialogue_entry_id)

	dialogues_base_dir_res = f"{DEFAULT_OUTPUT_BASE_DIR}/{level_slug}/dialogues"
	dialogues_base_dir_fs = _fs_path(dialogues_base_dir_res)

	new_filename = f"{level_slug}_{entry_slug}.dialogue"
	new_resource_path = f"{dialogues_base_dir_res}/{new_filename}"
	new_local_path = f"{dialogues_base_dir_fs}/{new_filename}"

	if not os.path.exists(new_local_path):
		os.makedirs(os.path.dirname(new_local_path), exist_ok=True)

		def _line(speaker: str, text: str, index: int) -> str:
			line_id = f"L{_generate_dialogue_line_id(level_id, dialogue_entry_id, index)}"
			_register_line_for_translation(line_id, f"{speaker}: {text}")
			return f"{speaker}: {text} [ID:{line_id}]"

		# Determine speakers
		primary_speaker = "{{initiator_name}}"
		secondary_speaker = "{{partner_name}}"
		is_single_speaker = False
		
		if metadata:
			if metadata.get("is_loot"):
				is_single_speaker = True
			elif metadata.get("is_location"):
				if metadata.get("inhabited"):
					loc_name = metadata.get("location_name") or "the area"
					secondary_speaker = f"Person of {loc_name}"
				else:
					is_single_speaker = True
			# Target-specific unit (stretch)
			elif metadata.get("target_id") and metadata.get("target_kind") == "unit":
				secondary_speaker = metadata.get("target_id")
			# Stage-specific partner fallback
			elif metadata.get("partner_name"):
				secondary_speaker = metadata.get("partner_name")

		# Templates mapping
		default_next = next_info if next_info else "the next area"
		default_title = title if title else dialogue_entry_id
		default_desc = description if description else f"Pending narrative description for {dialogue_entry_id}..."

		header_lines = [
			f"{_line(primary_speaker, '[Title: ' + default_title + ']', 0)}",
			f"{_line(primary_speaker, '[Narrative Goal: ' + default_desc + ']', 1)}",
		]
		
		meta_lines = []
		if metadata:
			for k in ["task_id", "stage_id", "journal_id"]:
				if metadata.get(k):
					label = k.split("_")[0].capitalize()
					val = metadata[k]
					content = f"[{label}: {val}]"
					meta_lines.append(_line(primary_speaker, content, len(header_lines) + len(meta_lines)))

		body_lines = []
		if template_type == "STAGE_EXIT_TERMINAL":
			body_lines = [
				"if is_victory",
				f"\t{_line(primary_speaker, 'The mission was a success! The objective is secure.', len(header_lines) + len(meta_lines) + 0)}",
				f"\t{_line(secondary_speaker, 'You have done a great service today.', len(header_lines) + len(meta_lines) + 1)}",
				"else",
				f"\t{_line(primary_speaker, 'We have failed. The objective was lost.', len(header_lines) + len(meta_lines) + 2)}",
				f"\t{_line(secondary_speaker, 'Retreat and regroup! We will find another way.', len(header_lines) + len(meta_lines) + 3)}",
				"=> END"
			]
		elif template_type == "STAGE_EXIT_TRANSITION":
			body_lines = [
				f"{_line(primary_speaker, 'We have finished our work here for now.', len(header_lines) + len(meta_lines) + 0)}",
				f"{_line(primary_speaker, 'We must move on to our next objective: ' + default_next + '.', len(header_lines) + len(meta_lines) + 1)}",
				"=> END"
			]
		else: # DEFAULT
			body_lines = [
				f"{_line(primary_speaker, 'This is a placeholder for ' + dialogue_entry_id + '.', len(header_lines) + len(meta_lines) + 0)}"
			]
			if not is_single_speaker:
				body_lines.append(f"{_line(secondary_speaker, 'Indeed it is.', len(header_lines) + len(meta_lines) + 1)}")
			
			body_lines.append("=> END")

		all_lines = header_lines + meta_lines + body_lines
		content = "~ start\n" + "\n".join(all_lines) + "\n"

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
	"action_label", "action_hint", "repeatable", "requires_near",
	"consume_action", "allow_partner_initiation"
]

def _apply_dialogue_props(props: dict, data: dict) -> None:
	"""Populates props with shared dialogue fields from data."""
	_copy_props(props, data, _DIALOGUE_COPY_KEYS, {k: "StringName" for k in _DIALOGUE_PRE_FORMAT_KEYS})
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

def build_level_unit_spawn_entry(builder: TresBuilder, data: dict, faction: str = 'enemy', stage: dict = None) -> str:
	props = {}
	faction_int = ENUM_VALUES["UnitFaction"].get(str(faction).upper(), 1)
	props['faction'] = faction_int
	props['coord'] = _json_coord_to_godot_coord(data.get('coord', DEFAULT_INVALID_COORD))

	_copy_props(props, data, ["slot_index", "unit_name", "loyalty_type"])
	
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
		logger.warning(f"Unit spawn missing 'unit_scene_path' in JSON. Using fallback: {unit_scene_path}. [Fix: Add 'unit_scene_path': 'res://path/to/unit.tscn' to the unit entry in JSON]")

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

	_apply_stat_overrides(builder, props, data, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 10})

	type_hints = {"inventory": "InventoryItem"}
	return builder.add_sub_resource("LevelUnitSpawnEntry", props, type_hints=type_hints)

def build_level_task_entry(builder: TresBuilder, data: dict, level_id: str = "") -> str:
	props = {}
	props["coord"] = _json_coord_to_godot_coord(data.get("coord", DEFAULT_INVALID_COORD))

	scene_path = data.get("location_scene_path", "")
	if not scene_path:
		scene_path = GENERIC_LOCATION_SCENE
		logger.warning(f"Location spawn missing 'location_scene_path' in JSON. Using fallback: {scene_path}. [Fix: Add 'location_scene_path': 'res://path/to/location.tscn' to the location entry in JSON]")

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

	if props["reward_type"] == 0 and props["reward_value"]: # ITEM
		item_id = props["reward_value"]
		ref = build_inventory_item(builder, item_id)
		if ref:
			# For rewards, we might want to store the actual resource reference
			# depending on how task_reward.gd is implemented.
			# If it expects an InventoryItem, we provide a SubResource or ExtResource.
			props["reward_item"] = ref

	return builder.add_sub_resource("TaskReward", props)

def _extract_target_filters(data: dict) -> list:
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
				filter_data["target_coord"] = _json_coord_to_godot_coord(entry.get("target_coord"))
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

def build_task(builder: TresBuilder, data: dict, level_id: str = "") -> str:
	props = {}
	task_id = data.get('id', 'task')
	props['id'] = f'&"{task_id}"'

	copy_keys = [
		"target_id", "target_kind",
		"effort_required", "is_optional", "is_opposed",
		"opposition_value", "journal_entry_id", "reward_id", "duration_turns"
	]
	_copy_props(props, data, copy_keys)

	target_filters = _extract_target_filters(data)
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

	# Handle StringNames explicitly
	string_name_keys = ["dialogue_id", "enter_journal_id", "exit_journal_id", "duration_mode", "enter_dialogue_id", "exit_dialogue_id", "failure_dialogue_id", "failure_journal_id"]
	_copy_props(props, data, string_name_keys, {k: "StringName" for k in string_name_keys})

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
			props["target_coord"] = _json_coord_to_godot_coord(data.get("target_coord", DEFAULT_INVALID_COORD))
	else:
		props["target_coord"] = _json_coord_to_godot_coord(data.get("target_coord", DEFAULT_INVALID_COORD))

	if "zone_coords" in data:
		props["zone_coords"] = [_json_coord_to_godot_coord(c) for c in data["zone_coords"]]
	else:
		props["zone_coords"] = []

	# Hook helpers
	hooks = {
		"on_enter": ("start_dialogue_resource", "enter_dialogue_id", "enter_journal_id"),
		"on_exit": ("exit_dialogue_resource", "exit_dialogue_id", "exit_journal_id"),
		"on_fail": ("failure_dialogue_resource", "failure_dialogue_id", "failure_journal_id")
	}

	for hook_key, (res_prop, d_id_prop, j_id_prop) in hooks.items():
		if hook_key in data:
			d_id, j_id = _resolve_hook_ids(data[hook_key], task_data=data)
			if d_id:
				if level_id:
					t = data.get("title", d_id)
					d = data.get("description", f"Task {hook_key.replace('on_', '').capitalize()} Dialogue")
					meta = {"task_id": data.get("id"), "journal_id": j_id}
					props[res_prop] = _ensure_dialogue_file_exists(level_id, d_id, title=t, description=d, metadata=meta)
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
	targets = [f"{s}_fs" for s in LEVEL_DATA_SUBDIRS if f"{s}_fs" in dirs]
	for key in targets:
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
	level_display_name = data.get('display_name') or data.get('objective', {}).get('title') or level_id
	
	_generate_dialogue_rows(level_id, level_slug, dirs, stages)
	_generate_journal_rows(level_id, level_slug, dirs, stages, level_display_name)
	_generate_roster_rows(level_id, level_slug, dirs, stages)
	_generate_loot_rows(level_id, level_slug, dirs, stages)
	_generate_location_rows(level_id, level_slug, dirs, stages)
	_generate_global_narrative_rows(level_id, level_slug, dirs, data, level_display_name)

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

		type_hints = {"inventory": "InventoryItem"}
		content = builder.build_tres('LevelUnitSpawnEntry', props, generate_deterministic_uid(res_path), type_hints=type_hints)
		write_tres_file(res_path, content)


def _generate_roster_rows(level_id: str, level_slug: str, dirs: dict, stages: list) -> None:
	for index, stage in enumerate(stages):
		stage_slug = _stage_slug(stage, index)
		stage_id = stage.get('id', '')
		for faction in ['enemy', 'neutral']:
			spawns = stage.get(f'{faction}_spawns', []) or []
			for idx, spawn in enumerate(spawns):
				filename = f"{level_slug}_{stage_slug}_{_slugify(faction)}_{idx}.tres"
				res_path = f"{dirs['roster_rows_res']}/{filename}"
				builder = TresBuilder()
				builder.add_ext_resource(SCRIPT_PATHS['LevelUnitSpawnEntry'], 'Script')
				props = {
					'level_id': f'&"{level_id}"',
					'notes': stage_id or ''
				}

				faction_int = ENUM_VALUES["UnitFaction"].get(str(faction).upper(), 1)
				props['faction'] = faction_int
				props['coord'] = _json_coord_to_godot_coord(spawn.get('coord', DEFAULT_INVALID_COORD))
				_copy_props(props, spawn, ["slot_index", "unit_name", "loyalty_type"])
				
				# Automatically detect if this unit should be persuadable based on tasks
				can_persuade = spawn.get('neutral_can_be_persuaded', False)
				if not can_persuade and faction == 'neutral':
					unit_id = spawn.get('id') or spawn.get('unit_name')
					tasks = stage.get('tasks', []) or []
					for t in tasks:
						if t.get('event_type') == 'convince' and t.get('target_id') == unit_id:
							can_persuade = True
							break
				props['neutral_can_be_persuaded'] = can_persuade

				unit_scene_path = spawn.get('unit_scene_path')
				if not unit_scene_path:
					unit_scene_path = GENERIC_UNIT_SCENE

				unit_ext = builder.add_ext_resource(unit_scene_path, 'PackedScene')
				if unit_ext:
					props['unit_scene'] = f'ExtResource("{unit_ext}")'

				_apply_stat_overrides(builder, props, spawn, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 10})

				type_hints = {"inventory": "InventoryItem"}
				content = builder.build_tres('LevelUnitSpawnEntry', props, generate_deterministic_uid(res_path), type_hints=type_hints)
				write_tres_file(res_path, content)


def _generate_loot_rows(level_id: str, level_slug: str, dirs: dict, stages: list) -> None:
	for index, stage in enumerate(stages):
		stage_slug = _stage_slug(stage, index)
		stage_id = stage.get('id', '')
		for count, loot in enumerate(stage.get('loot_spawns', []) or []):
			res_path = f"{dirs['loot_rows_res']}/{level_slug}_{stage_slug}_loot_{count}.tres"
			builder = TresBuilder()
			builder.add_ext_resource(SCRIPT_PATHS['LevelLootEntry'], 'Script')

			props = {
				'level_id': f'&"{level_id}"',
				'notes': stage_id or ''
			}
			_copy_props(props, loot, ["id", "is_trapped"])
			props['coord'] = _json_coord_to_godot_coord(loot.get('coord', DEFAULT_INVALID_COORD))
			props['items'] = _extract_loot_items(builder, loot)
			_apply_stat_overrides(builder, props, loot, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 1})

			type_hints = {"items": "InventoryItem"}
			content = builder.build_tres('LevelLootEntry', props, generate_deterministic_uid(res_path), type_hints=type_hints)
			write_tres_file(res_path, content)


def _generate_location_rows(level_id: str, level_slug: str, dirs: dict, stages: list) -> None:
	for index, stage in enumerate(stages):
		stage_slug = _stage_slug(stage, index)
		stage_id = stage.get('id', '')
		for count, loc in enumerate(stage.get('location_spawns', []) or []):
			res_path = f"{dirs['location_rows_res']}/{level_slug}_{stage_slug}_location_{count}.tres"
			builder = TresBuilder()
			builder.add_ext_resource(SCRIPT_PATHS['LevelTaskEntry'], 'Script')

			props = {
				'level_id': f'&"{level_id}"',
				'notes': stage_id or ''
			}
			props['coord'] = _json_coord_to_godot_coord(loc.get('coord', DEFAULT_INVALID_COORD))
			props['location_name'] = loc.get('location_name') or loc.get('id', '')

			scene_path = loc.get('location_scene_path') or GENERIC_LOCATION_SCENE
			scene_ext = builder.add_ext_resource(scene_path, 'PackedScene')
			if scene_ext:
				props['location_scene'] = f'ExtResource("{scene_ext}")'

			_apply_stat_overrides(builder, props, loc, {"grit": 6, "flow": 6, "gusto": 6, "focus": 6, "shine": 6, "shade": 6, "willpower": 10})

			content = builder.build_tres('LevelTaskEntry', props, generate_deterministic_uid(res_path))
			write_tres_file(res_path, content)



def _generate_dialogue_rows(level_id: str, level_slug: str, dirs: dict, stages: list) -> None:
	for index, stage in enumerate(stages):
		stage_slug = _stage_slug(stage, index)
		stage_id = stage.get('id', '')

		# Standard entries
		combined: list[tuple[dict, bool]] = []
		for e in (stage.get('dialogue_entries', []) or []):
			combined.append((e, False))
		for e in (stage.get('dialogue_journal_entries', []) or []):
			combined.append((e, False))

		# Tasks on_enter/on_exit
		for task in stage.get("tasks", []):
			task_id = task.get("id", "task")
			for hook_key in ["on_enter", "on_exit"]:
				h_data = task.get(hook_key, {})
				d_id, j_id = _resolve_hook_ids(h_data)
				if d_id:
					new_entry = {}
					if isinstance(h_data, dict): new_entry = h_data.copy()
					new_entry["entry_id"] = d_id
					new_entry["notes"] = f"Task {task_id} {hook_key}"
					# Detect task specialized types
					is_loot = task.get("target_id") == "loot" or task.get("event_type") == "collect"
					is_location = task.get("event_type") in ["visit", "explore"]
					inhabited = task.get("inhabited", False)
					location_name = ""
					
					if is_location:
						target_id = task.get("target_id")
						stage_locations = stage.get("location_spawns", []) or []
						for loc in stage_locations:
							lid = loc.get("id") or loc.get("location_name")
							if lid == target_id:
								inhabited = loc.get("inhabited", inhabited)
								location_name = loc.get("location_name") or target_id
								break

					new_entry["metadata"] = {
						"task_id": task_id, 
						"stage_id": stage_id, 
						"journal_id": j_id,
						"title": task.get("title"),
						"description": task.get("description"),
						"target_id": task.get("target_id"),
						"target_kind": task.get("target_kind"),
						"is_loot": is_loot,
						"is_location": is_location,
						"inhabited": inhabited,
						"location_name": location_name
					}
					combined.append((new_entry, True))

		for count, (entry, is_auto) in enumerate(combined):
			res_path = f"{dirs['dialogue_rows_res']}/{level_slug}_{stage_slug}_dialogue_{count}.tres"
			builder = TresBuilder()
			builder.add_ext_resource(SCRIPT_PATHS['LevelDialogueEntry'], 'Script')

			props = {'level_id': f'&"{level_id}"'}
			_apply_dialogue_props(props, entry)

			# Overrides for row-specific context
			if 'entry_id' not in props or not props['entry_id']:
				props['entry_id'] = f'&"{entry.get("journal_entry_id") or f"{stage_slug}_dialogue_{count}"}"'

			# Row-specific logic for triggers
			default_requires = ("coord" in entry) and (not is_auto)
			props['requires_near'] = bool(entry.get('requires_near', default_requires))
			props['consume_action'] = bool(entry.get('consume_action', not is_auto))
			props['allow_partner_initiation'] = bool(entry.get('allow_partner_initiation', is_auto))
			props['notes'] = entry.get('notes', stage_id or '')

			if 'dialogue_resource_path' not in props or not props['dialogue_resource_path']:
				meta = entry.get("metadata", {})
				title = meta.get("title") or entry.get("title", "")
				desc = meta.get("description") or entry.get("notes", "")
				props['dialogue_resource_path'] = _ensure_dialogue_file_exists(level_id, entry.get('entry_id', ''), title=title, description=desc, metadata=meta)

			content = builder.build_tres('LevelDialogueEntry', props, generate_deterministic_uid(res_path))
			write_tres_file(res_path, content)



def _generate_journal_rows(level_id: str, level_slug: str, dirs: dict, stages: list, default_topic: str = "") -> None:
	topic_id = default_topic # Rule: topic id should be the (objective or level) name
	# Use a dict to deduplicate by ID. Detailed entries take precedence.
	journal_map: dict[str, dict] = {}

	def _add_to_combined(entries, section_id=""):
		if not entries: return
		for entry in entries:
			jid = entry.get('id') or entry.get('entry_id') or entry.get('journal_entry_id')
			if not jid: continue
			
			# Ensure topic/section are set if not present
			if 'topic_id' not in entry: entry['topic_id'] = topic_id
			if 'section_id' not in entry: entry['section_id'] = section_id

			# If we have an existing entry with content/title, keep it
			existing = journal_map.get(jid)
			if existing and (existing.get('content') or existing.get('title')):
				# Only overwrite if current also has content (unlikely to need merge)
				if entry.get('content') or entry.get('title'):
					journal_map[jid] = entry
			else:
				journal_map[jid] = entry

	for index, stage in enumerate(stages):
		stage_id = stage.get('id', '')
		_add_to_combined(stage.get('journal_entries', []), stage_id)
		_add_to_combined(stage.get('dialogue_journal_entries', []), stage_id)

		# Add stage on_enter/on_exit journal entries
		for hook_key in ["on_enter", "on_exit"]:
			if hook_key in stage:
				_, j_id = _resolve_hook_ids(stage[hook_key])
				if j_id and j_id not in journal_map:
					journal_map[j_id] = {
						"id": j_id,
						"title": f"Stage {stage_id} {'Started' if hook_key == 'on_enter' else 'Completed'}",
						"notes": f"Stage {stage_id} {hook_key}",
						"topic_id": topic_id,
						"section_id": stage_id,
						"entry_type": "trigger"
					}

		# Add task on_enter/on_exit journal entries
		for task in (stage.get("tasks", []) or []):
			task_id = task.get("id", "task")
			for hook_key in ["on_enter", "on_exit"]:
				h_data = task.get(hook_key, {})
				_, j_id = _resolve_hook_ids(h_data, task_data=task)
				if j_id and j_id not in journal_map:
					journal_map[j_id] = {
						"id": j_id,
						"title": f"Task {task_id} {hook_key.replace('on_', '').capitalize()}",
						"notes": f"Task {task_id} {hook_key}",
						"topic_id": topic_id,
						"section_id": stage_id,
						"entry_type": "trigger"
					}

	for count, (j_id, entry) in enumerate(journal_map.items()):
		res_path = f"{dirs['journal_entry_rows_res']}/{level_slug}_journal_{count}.tres"
		builder = TresBuilder()
		builder.add_ext_resource(SCRIPT_PATHS['JournalEntry'], 'Script')
		journal_id = entry.get('journal_entry_id') or entry.get('id') or entry.get('entry_id') or f"journal_{count}"
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
		content = builder.build_tres('JournalEntry', props, generate_deterministic_uid(res_path))
		write_tres_file(res_path, content)


def _generate_global_narrative_rows(level_id: str, level_slug: str, dirs: dict, data: dict, default_topic: str = "") -> None:
	"""Generates rows for dialogue and journal entries defined at the JSON root."""
	topic_id = default_topic or level_id
	section_id = "global"
	# Dialogue entries at root
	dialogue_entries = data.get("dialogue_entries", []) or []
	for count, entry in enumerate(dialogue_entries):
		res_path = f"{dirs['dialogue_rows_res']}/{level_slug}_global_dialogue_{count}.tres"
		builder = TresBuilder()
		builder.add_ext_resource(SCRIPT_PATHS['LevelDialogueEntry'], 'Script')
		props = {'level_id': f'&"{level_id}"'}
		_apply_dialogue_props(props, entry)
		if 'entry_id' not in props or not props['entry_id']:
			props['entry_id'] = f'&"{entry.get("journal_entry_id") or f"global_dialogue_{count}"}"'
		if 'dialogue_resource_path' not in props or not props['dialogue_resource_path']:
			props['dialogue_resource_path'] = _ensure_dialogue_file_exists(level_id, entry.get('entry_id', ''))
		content = builder.build_tres('LevelDialogueEntry', props, generate_deterministic_uid(res_path))
		write_tres_file(res_path, content)

	# Journal entries at root
	journal_entries = data.get("journal_entries", []) or []
	for count, entry in enumerate(journal_entries):
		res_path = f"{dirs['journal_entry_rows_res']}/{level_slug}_global_journal_{count}.tres"
		builder = TresBuilder()
		builder.add_ext_resource(SCRIPT_PATHS['JournalEntry'], 'Script')
		props = {"topic_id": topic_id, "section_id": section_id}
		_copy_props(props, entry, ["title", "unlocked", "entry_type", "status", "related_id"])
		_copy_props(props, entry, ["topic_id", "section_id"]) # Allow overrides
		entry_id = entry.get("entry_id", entry.get("id", f"global_journal_{count}"))
		props["id"] = entry_id
		props["level_id"] = f'&"{level_id}"'
		if "content" in entry: props["content"] = entry["content"]
		elif "notes" in entry: props["content"] = entry["notes"]
		content = builder.build_tres('JournalEntry', props, generate_deterministic_uid(res_path))
		write_tres_file(res_path, content)

	# Dialogue + Journal entries at root
	dj_entries = data.get("dialogue_journal_entries", []) or []
	for count, entry in enumerate(dj_entries):
		# DJ entries generate both a Dialogue resource AND a Journal resource
		# OR a specialized LevelDialogueJournalEntry if supported.
		# For simplicity and compatibility with LevelRowLoader, 
		# we generate two separate resources that share the same ID.

		# 1. The Dialogue Side
		d_res_path = f"{dirs['dialogue_rows_res']}/{level_slug}_global_dj_d_{count}.tres"
		d_builder = TresBuilder()
		d_builder.add_ext_resource(SCRIPT_PATHS['LevelDialogueEntry'], 'Script')
		d_props = {'level_id': f'&"{level_id}"'}
		_apply_dialogue_props(d_props, entry)
		d_id = entry.get('entry_id') or entry.get('group_id') or f"global_dj_{count}"
		d_props['entry_id'] = f'&"{d_id}"'
		if 'dialogue_resource_path' not in d_props or not d_props['dialogue_resource_path']:
			d_props['dialogue_resource_path'] = _ensure_dialogue_file_exists(level_id, str(d_id))
		d_content = d_builder.build_tres('LevelDialogueEntry', d_props, generate_deterministic_uid(d_res_path))
		write_tres_file(d_res_path, d_content)

		# 2. The Journal Side
		j_res_path = f"{dirs['journal_entry_rows_res']}/{level_slug}_global_dj_j_{count}.tres"
		j_builder = TresBuilder()
		j_builder.add_ext_resource(SCRIPT_PATHS['JournalEntry'], 'Script')
		j_id = entry.get('journal_entry_id') or entry.get('entry_id') or f"global_dj_{count}"
		j_props = {
			'level_id': f'&"{level_id}"',
			'id': j_id,
			'title': entry.get('title') or entry.get('journal_title') or j_id,
			'content': entry.get('notes') or entry.get('content') or '',
			'topic_id': entry.get('topic_id', topic_id),
			'section_id': entry.get('section_id', section_id),
			'related_id': entry.get('related_id') or d_id
		}
		j_content = j_builder.build_tres('JournalEntry', j_props, generate_deterministic_uid(j_res_path))
		write_tres_file(j_res_path, j_content)



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
			msg = f"[Validation] Stage '{stage_slug}' has no mandatory tasks but is in ALL_REQUIRED mode. It will never advance automatically. [Fix: Set 'is_optional': false on at least one task or change 'completion_mode' to 'SOME_REQUIRED']"
			logger.warning(msg)
			if msg not in _conversion_warnings: _conversion_warnings.append(msg)
	enemy_spawn_refs = []
	neutral_spawn_refs = []
	
	# Process specific spawn lists
	for s_data in data.get("enemy_spawns", []):
		srid = build_level_unit_spawn_entry(builder, s_data, 'enemy', data)
		enemy_spawn_refs.append(f'SubResource("{srid}")')

	for s_data in data.get("neutral_spawns", []):
		srid = build_level_unit_spawn_entry(builder, s_data, 'neutral', data)
		neutral_spawn_refs.append(f'SubResource("{srid}")')

	# Process general roster_spawns with auto-sorting
	for s_data in data.get("roster_spawns", []):
		raw_faction = str(s_data.get("faction", "enemy")).upper()
		faction_map = {
			"ENEMY": "enemy", "FOE": "enemy",
			"NEUTRAL": "neutral", "NPC": "neutral"
		}
		target_list = faction_map.get(raw_faction, "enemy")
		srid = build_level_unit_spawn_entry(builder, s_data, target_list, data)
		if target_list == "enemy":
			enemy_spawn_refs.append(f'SubResource("{srid}")')
		else:
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
	stage_hooks = {
		"on_enter": ("start_dialogue_resource", "enter_dialogue_id", "enter_journal_id"),
		"on_exit": ("exit_dialogue_resource", "exit_dialogue_id", "exit_journal_id"),
		"on_fail": ("failure_dialogue_resource", "failure_dialogue_id", "failure_journal_id")
	}

	for hook_key, (res_prop, d_id_prop, j_id_prop) in stage_hooks.items():
		if hook_key in data:
			d_id, j_id = _resolve_hook_ids(data[hook_key]) # Note: stage hooks don't use the title rule for j_id
			if d_id:
				ttype = "STAGE_DIALOGUE"
				next_info = ""
				if hook_key == "on_exit":
					ttype = "STAGE_EXIT_TERMINAL" if is_terminal else "STAGE_EXIT_TRANSITION"
					next_info = next_id if next_id else ("multiple paths" if branching else "")
				
				meta = {"stage_id": stage_slug, "journal_id": j_id}
				title = f"Stage: {stage_slug}"
				desc = f"{'Entry' if hook_key == 'on_enter' else 'Exit'} for {stage_slug}"
				dialogue_path = _ensure_dialogue_file_exists(level_id, d_id, title=title, description=desc, template_type=ttype, next_info=next_info, metadata=meta)
				props[res_prop] = dialogue_path
				props[d_id_prop] = f'&"{d_id}"'
			if j_id:
				props[j_id_prop] = j_id

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

	type_hints = {
		"tasks": "Task",
		"enemy_spawns": "LevelUnitSpawnEntry",
		"neutral_spawns": "LevelUnitSpawnEntry",
		"loot_spawns": "LevelLootEntry",
		"location_spawns": "LevelTaskEntry",
		"dialogue_entries": "LevelDialogueEntry",
		"journal_entries": "JournalEntry",
		"dialogue_journal_entries": "LevelDialogueJournalEntry"
	}
	content = builder.build_tres("Stage", props, uid, type_hints=type_hints)
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
		"player_faction_name": data.get("player_faction_name", "Player"),
		"enemy_faction_name": data.get("enemy_faction_name", "Enemy"),
		"neutral_faction_name": data.get("neutral_faction_name", "Neutral"),
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
							logger.warning(f"Negative coordinate found in {group} of stage {stage['id']}: {c}. [Fix: Use 0-based coordinates (e.g., {{'x': 5, 'y': 2}})]")

	# Check player starts
	for start in (data.get("player_starts") or []):
		if isinstance(start, dict):
			if start.get("x", 0) < 0 or start.get("y", 0) < 0:
				logger.warning(f"Negative coordinate found in player_starts: {start}. [Fix: Use 0-based coordinates (e.g., {{'x': 5, 'y': 2}})]")

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
		msg = f"[Connectivity] Primary player start at ({sx}, {sy}) is on impassable terrain '{rows[sy][sx]}'. [Fix: Move player start to a passable tile (e.g., '.'), or change the tile code in the terrain grid]"
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
	Emits warnings for mismatches but does not raise to avoid hard-stopping authoring.
	"""
	# 1. Collect global definitions
	global_dialogue_ids = set()
	global_journal_keys = set()
	
	for entry in (data.get("dialogue_entries", []) or []):
		k = entry.get("entry_id") or entry.get("group_id")
		if k: global_dialogue_ids.add(k)
	for entry in (data.get("journal_entries", []) or []):
		k = entry.get("related_id") or entry.get("entry_id") or entry.get("id")
		if k: global_journal_keys.add(k)
	for entry in (data.get("dialogue_journal_entries", []) or []):
		d_id = entry.get("entry_id") or entry.get("group_id")
		j_id = entry.get("journal_entry_id") or entry.get("entry_id")
		if d_id: global_dialogue_ids.add(d_id)
		if j_id: global_journal_keys.add(j_id)

	obj = data.get("objective", {})
	stages = obj.get("stages", [])
	for index, stage in enumerate(stages):
		stage_id = stage.get("id", f"stage_{index + 1}")

		# Collect dialogue keys and explicit links
		dialogue_ids = global_dialogue_ids.copy()
		journal_keys = global_journal_keys.copy()
		
		# Set of (dialogue_id, journal_id) explicitly paired in this stage
		explicit_links = set() 

		def _account_link(d_id, j_id):
			if d_id: dialogue_ids.add(d_id)
			if j_id: journal_keys.add(j_id)
			if d_id and j_id: explicit_links.add((d_id, j_id))

		# Stage level on_enter/on_exit
		for hook_key in ["on_enter", "on_exit"]:
			d_id, j_id = _resolve_hook_ids(stage.get(hook_key), dialogue_ids, journal_keys)
			_account_link(d_id, j_id)

		for entry in (stage.get("dialogue_entries", []) or []):
			key = entry.get("entry_id") or entry.get("journal_entry_id")
			_account_link(key, key)

		for entry in (stage.get("dialogue_journal_entries", []) or []):
			key = entry.get("entry_id") or entry.get("journal_entry_id")
			_account_link(key, key)

		# Tasks with on_enter/on_exit
		for task in (stage.get("tasks", []) or []):
			for hook_key in ["on_enter", "on_exit"]:
				d_id, j_id = _resolve_hook_ids(task.get(hook_key), dialogue_ids, journal_keys, task_data=task)
				_account_link(d_id, j_id)

		# Standard Journal Entries in stage
		for entry in (stage.get("journal_entries", []) or []):
			key = entry.get("related_id") or entry.get("entry_id") or entry.get("id") or entry.get("journal_entry_id")
			if isinstance(key, str) and key:
				journal_keys.add(key)

		# Validation logic:
		# A dialogue ID is missing a matching journal IF:
		# 1. It's not in the journal_keys set (by same ID)
		# 2. AND it's not the left-side of an explicit link where the right-side IS in journal_keys.
		
		missing_journal = []
		for d in dialogue_ids:
			if d in journal_keys: continue
			
			# Check if it's explicitly paired with something that exists
			paired = False
			for d_link, j_link in explicit_links:
				if d == d_link and j_link in journal_keys:
					paired = True
					break
			if not paired:
				missing_journal.append(d)

		if missing_journal:
			# Sort and filter out empty strings
			missing_journal = sorted([m for m in missing_journal if m])
			if missing_journal:
				msg = f"[Dialogue/Journal] Stage '{stage_id}' dialogue IDs with no matching journal related_id: {missing_journal}. [Fix: Add matching journal entries or update 'related_id' in JSON]"
				logger.warning(msg)
				if msg not in _conversion_warnings: _conversion_warnings.append(msg)

		missing_dialogue = []
		for j in journal_keys:
			if j in dialogue_ids: continue
			
			paired = False
			for d_link, j_link in explicit_links:
				if j == j_link and d_link in dialogue_ids:
					paired = True
					break
			if not paired:
				missing_dialogue.append(j)

		if missing_dialogue:
			missing_dialogue = sorted([m for m in missing_dialogue if m])
			if missing_dialogue:
				msg = f"[Dialogue/Journal] Stage '{stage_id}' journal related_ids with no matching dialogue entry_id: {missing_dialogue}. [Fix: Add matching dialogue entries or update 'entry_id' in JSON]"
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
	global _generated_stage_paths, _conversion_warnings, _translation_buffer
	_generated_stage_paths = {}
	_conversion_warnings = []
	_translation_buffer = {} # Clear buffer for new run
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
		_flush_translations() # Commit all buffered translations
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
	relevant_subdirs = [""] + [s for s in LEVEL_DATA_SUBDIRS if s != 'summaries']

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
	catalog_res_path = paths_helper.get_path("resources.level_data.level_catalog") or "res://level/level_catalog.gd"
	catalog_path = _fs_path(catalog_res_path)
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
		"player_faction_name": "Player",
		"enemy_faction_name": "Enemy",
		"neutral_faction_name": "Neutral",
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
	parser.add_argument("--input", "-i", default="", help="Path to input JSON or directory containing JSONs")
	parser.add_argument("--template", "-t", default="", help="Generate a new level template JSON")
	parser.add_argument("--output", "-o", default=DEFAULT_OUTPUT_BASE_DIR, help="Output base directory")
	parser.add_argument("--verbose", "-v", action="store_true", help="Enable verbose logging")
	args = parser.parse_args()

	if args.verbose: logger.setLevel(logging.DEBUG)

	if args.template:
		generate_template(args.template)
	else:
		input_path = args.input
		if not input_path:
			# Default to Resources/level_data if no input provided
			input_path = os.path.join(PROJECT_ROOT, "Resources", "level_data")
			logger.info(f"No input specified. Searching in default directory: {input_path}")

		if os.path.isdir(input_path):
			import glob
			json_pattern = os.path.join(input_path, "**", "*.json")
			json_files = glob.glob(json_pattern, recursive=True)
			if not json_files:
				logger.info(f"No JSON files found in {input_path}")
			else:
				for json_file in json_files:
					if "template" in json_file.lower():
						continue
					convert_json_to_tres(json_file, args.output)
		elif os.path.isfile(input_path):
			convert_json_to_tres(input_path, args.output)
		else:
			if args.input:
				logger.error(f"Input path not found: {input_path}")
			else:
				parser.print_help()
