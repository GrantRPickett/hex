import json
import os
import logging
import argparse
import hashlib
import re
from file_paths_loader import FilePathsLoader

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

# Initialize FilePaths helper
paths_helper = FilePathsLoader("Resources/file_paths.json")

# --- Configuration ---
DEFAULT_OUTPUT_BASE_DIR = (paths_helper.get_path("directories.level_data") or "res://Resources/level_data").rstrip('/')

# Mapping of GDScript class names to their file paths
# We attempt to pull these from file_paths.json via the helper
SCRIPT_PATHS = {
    "Level": paths_helper.get_path("resources.core.level") or "res://level/Level.gd",
    "Objective": paths_helper.get_path("resources.task_system.objective") or "res://Gameplay/narrative/task/objective.gd",
    "Stage": paths_helper.get_path("resources.task_system.stage") or "res://Gameplay/narrative/task/stage.gd",
    "Task": paths_helper.get_path("resources.task_system.task") or "res://Gameplay/narrative/task/task.gd",
    "JournalEntry": paths_helper.get_path("resources.level_data.level_journal_entry") or "res://level/level_journal_entry.gd",
    "LevelDialogueEntry": paths_helper.get_path("resources.level_data.level_dialogue_entry") or "res://level/level_dialogue_entry.gd",
    "LevelDialogueRow": paths_helper.get_path("resources.level_data.level_dialogue_row") or "res://level/level_dialogue_row.gd",
    "LevelJournalEntry": paths_helper.get_path("resources.level_data.level_journal_entry") or "res://level/level_journal_entry.gd",
    "LevelDialogueJournalEntry": paths_helper.get_path("resources.level_data.level_dialogue_journal_entry") or "res://level/level_dialogue_journal_entry.gd",
    "LevelTerrainData": paths_helper.get_path("resources.level_data.level_terrain_data") or "res://level/level_terrain_data.gd",

    "UnitRosterDefinition": paths_helper.get_path("resources.rosters.unit_roster_definition") or "res://Gameplay/roster/unit_roster_definition.gd",
    "LevelUnitSpawnEntry": paths_helper.get_path("resources.level_data.level_unit_spawn_entry") or "res://level/level_unit_spawn_entry.gd",
    "LevelLootEntry": paths_helper.get_path("resources.level_data.level_loot_entry") or "res://level/level_loot_entry.gd",
    "LevelTaskEntry": paths_helper.get_path("resources.level_data.level_task_entry") or "res://level/level_task_entry.gd",
    "LevelTerrainRow": paths_helper.get_path("resources.level_data.level_terrain_row") or "res://level/level_terrain_row.gd",
    "LevelStartRow": paths_helper.get_path("resources.level_data.level_start_row") or "res://level/level_start_row.gd",
    "LevelRosterRow": paths_helper.get_path("resources.level_data.level_roster_row") or "res://level/level_roster_row.gd",
    "LevelLootRow": paths_helper.get_path("resources.level_data.level_loot_row") or "res://level/level_loot_row.gd",
    "LevelTaskRow": paths_helper.get_path("resources.level_data.level_task_row") or "res://level/level_task_row.gd",
    "LevelMetaRow": paths_helper.get_path("resources.level_data.level_meta_row") or "res://level/level_meta_row.gd",
    "CompletionCondition": paths_helper.get_path("resources.task_system.completion_condition") or "res://Gameplay/narrative/task/completion_condition.gd",
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
    "TaskType": { # Event Type
        "interact": "interact",
        "move": "move",
        "elimination": "elimination",
    }
}

# Global map for cross-referencing
_generated_stage_paths = {}


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
        
    fs_root = normalized.replace('res://', './', 1)

    def _build(subdir: str):
        fs_dir = os.path.join(fs_root, subdir).replace(os.sep, '/')
        os.makedirs(fs_dir, exist_ok=True)
        res_dir = f"{normalized}/{subdir}"
        return fs_dir, res_dir

    targets = ['levels', 'stages', 'terrain_rows', 'start_rows', 'roster_rows', 'loot_rows', 'location_rows', 'meta_rows', 'dialogue_rows', 'journal_entry_rows']
    dirs: dict = {}
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
            return value  # Already formatted, don't add quotes
        elif is_string_name:
            return f'&"{value}"'
        elif value.startswith("res://") or value.startswith("user://") or value.endswith(".tscn"):
            return f'"{value}"'
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
            # Convert 0-based JSON coordinates to 1-based Godot coordinates
            if x != -999: x += 1
            if y != -999: y += 1
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
        """Adds an external resource and returns its ID (e.g., '1_abcd')."""
        # check if already exists
        for p, t, i in self.ext_resources:
            if p == path:
                return i

        local_path = path.replace("res://", "./")
        if not os.path.exists(local_path) and not path.startswith("user://"):
             logger.warning(f"ExtResource missing at {local_path} (referenced as {path})")

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
             lines.append(f'script = ExtResource("{script_id}")')

        for k, v in properties.items():
            lines.append(f'{k} = {gd_variant_to_tres(v)}')

        self.sub_resources.append(("\n".join(lines), "Resource", rid))
        self.load_steps += 1
        return rid

    def build_tres(self, main_script_class: str, main_properties: dict, uid: str = "") -> str:
        """Generates the full .tres file content."""
        lines = []
        if uid:
            pass # Godot 4 header style varies

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
            # Check if we already added it?
            # get the ID
            found = False
            for p, _, rid in self.ext_resources:
                if p == main_script_path:
                    lines.append(f'script = ExtResource("{rid}")')
                    found = True
                    break
            if not found:
                 # Should have been added by caller or implicit?
                 # Let's simple add it now if missing (but it alters load_steps)
                 # Better: Initialize TresBuilder with main script
                 pass

        for k, v in main_properties.items():
            lines.append(f'{k} = {gd_variant_to_tres(v)}')

        return "\n".join(lines)


# --- Resource Object Generators ---

def build_level_unit_spawn_entry(builder: TresBuilder, data: dict, default_faction: int = 1) -> str:
    props = {}
    props["coord"] = data.get("coord", {"x": -999, "y": -999})

    scene_path = data.get("unit_scene_path", "")
    if scene_path:
        # scene is a PackedScene, so ExtResource
        sid = builder.add_ext_resource(scene_path, "PackedScene")
        props["unit_scene"] = f'ExtResource("{sid}")'

    # Check if faction is explicit, otherwise use default
    faction_str = data.get("faction", "")
    if faction_str:
        props["faction"] = ENUM_VALUES["UnitFaction"].get(faction_str, default_faction)
    else:
        props["faction"] = default_faction

    # Validation constraint: We do not support inventory strings yet in this simple pass unless we map them to resources
    # Assuming inventory are paths
    inv_list = []
    for item_path in data.get("inventory", []):
         iid = builder.add_ext_resource(item_path, "Resource")
         inv_list.append(f'ExtResource("{iid}")')

    props["inventory"] = inv_list

    return builder.add_sub_resource("LevelUnitSpawnEntry", props)

def build_level_loot_entry(builder: TresBuilder, data: dict) -> str:
    props = {}
    props["coord"] = data.get("coord", {"x": -999, "y": -999})

    items = []
    path = data.get("item_resource_path")
    if path:
        iid = builder.add_ext_resource(path, "Resource")
        items.append(f'ExtResource("{iid}")')

    props["items"] = items
    return builder.add_sub_resource("LevelLootEntry", props)

def _ensure_dialogue_file_exists(level_id: str, dialogue_entry_id: str) -> str:
    # Construct the new path based on requirements - now inside level-specific folder
    level_slug = _slugify(level_id)
    entry_slug = _slugify(dialogue_entry_id)

    dialogues_base_dir_res = f"{DEFAULT_OUTPUT_BASE_DIR}/{level_slug}/dialogues"
    dialogues_base_dir_fs = dialogues_base_dir_res.replace("res://", "./")

    # Add level prefix to dialogue filename for global uniqueness/consistency
    new_filename = f"{level_slug}_{entry_slug}.dialogue"
    new_resource_path = f"{dialogues_base_dir_res}/{new_filename}"
    new_local_path = f"{dialogues_base_dir_fs}/{new_filename}"

    if not os.path.exists(new_local_path):
        os.makedirs(os.path.dirname(new_local_path), exist_ok=True)
        # Proper dialogue format matching dialogue_manager expectations
        content = f"""~ start
Hero: Hello there! This is a placeholder dialogue for '{dialogue_entry_id}'.
Villager: Indeed it is.
"""
        try:
            with open(new_local_path, "w", encoding="utf-8") as f:
                f.write(content)
            logger.info(f"Created placeholder dialogue file: {new_resource_path}")
        except IOError as e:
            logger.error(f"Failed to create placeholder dialogue file {new_resource_path}: {e}")

    return new_resource_path


def build_level_dialogue_entry(builder: TresBuilder, data: dict, level_id: str) -> str:
    props = {}
    # Copy direct properties
    for k in ["entry_id", "flag_name", "initiator_name", "partner_name", "group_id", "action_label", "action_hint", "repeatable", "requires_adjacent",
              "consume_action", "allow_partner_initiation"]:
        if k in data:
            if k in ["group_id", "entry_id", "flag_name"]:
                 props[k] = f'&"{data[k]}"'
            else:
                 props[k] = data[k]

    if "coord" in data:
        props["coord"] = data["coord"]

    if "partner_faction" in data:
        props["partner_faction"] = ENUM_VALUES["UnitFaction"].get(data["partner_faction"], 0)

    # Use the provided dialogue_resource_path or generate one
    dialogue_entry_id = data.get("entry_id") or data.get("group_id") or f"dialogue_{len(builder.sub_resources)}"
    props["dialogue_resource_path"] = _ensure_dialogue_file_exists(level_id, dialogue_entry_id)

    return builder.add_sub_resource("LevelDialogueEntry", props)


def build_level_journal_entry(builder: TresBuilder, data: dict) -> str:
    props = {}
    entry_id = data.get("entry_id", data.get("id", ""))
    if entry_id:
        props["id"] = entry_id
    if "title" in data:
        props["title"] = data["title"]
    if "content" in data:
        props["content"] = data["content"]
    elif "notes" in data:
        props["content"] = data["notes"]
    if "unlocked" in data:
        props["unlocked"] = data["unlocked"]
    if "entry_type" in data:
        props["entry_type"] = data["entry_type"]
    if "status" in data:
        props["status"] = data["status"]
    if "related_id" in data:
        props["related_id"] = data["related_id"]
    if "topic_id" in data:
        props["topic_id"] = data["topic_id"]
    if "section_id" in data:
        props["section_id"] = data["section_id"]
    if "flag_name" in data:
        props["flag_name"] = f'&"{data["flag_name"]}"'
    if "level_id" in data:
        props["level_id"] = f'&"{data["level_id"]}"'

    return builder.add_sub_resource("LevelJournalEntry", props)


def build_level_dialogue_journal_entry(builder: TresBuilder, data: dict, level_id: str) -> str:
    props = {}
    # Dialogue properties
    for k in ["entry_id", "flag_name", "initiator_name", "partner_name", "group_id", "action_label", "action_hint", "repeatable", "requires_adjacent",
              "consume_action", "allow_partner_initiation"]:
        if k in data:
            if k in ["group_id", "entry_id", "flag_name"]:
                 props[k] = f'&"{data[k]}"'
            else:
                 props[k] = data[k]

    if "coord" in data:
        props["coord"] = data["coord"]

    if "partner_faction" in data:
        props["partner_faction"] = ENUM_VALUES["UnitFaction"].get(data["partner_faction"], 0)

    # Use the provided dialogue_resource_path or generate one
    dialogue_entry_id = data.get("entry_id") or data.get("group_id") or f"dialogue_journal_{len(builder.sub_resources)}"
    props["dialogue_resource_path"] = _ensure_dialogue_file_exists(level_id, dialogue_entry_id)

    # Journal properties (with journal_ prefix in JSON)
    journal_mapping = {
        "journal_entry_id": "entry_id",
        "journal_flag_name": "flag_name",
        "journal_section_id": "section_id",
        "journal_topic_id": "topic_id",
        "journal_notes": "notes"
    }

    for prop_name, json_key in journal_mapping.items():
        if json_key in data:
            if prop_name in ["journal_entry_id", "journal_flag_name"]:
                props[prop_name] = f'&"{data[json_key]}"'
            else:
                props[prop_name] = data[json_key]

    return builder.add_sub_resource("LevelDialogueJournalEntry", props)

def build_level_task_entry(builder: TresBuilder, data: dict) -> str:
    props = {}
    props["coord"] = data.get("coord", {"x": -999, "y": -999})

    scene_path = data.get("location_scene_path", "")
    if scene_path:
        # scene is a PackedScene, so ExtResource
        sid = builder.add_ext_resource(scene_path, "PackedScene")
        props["location_scene"] = f'ExtResource("{sid}")'

    return builder.add_sub_resource("LevelTaskEntry", props)

def build_task(builder: TresBuilder, data: dict, level_id: str = "") -> str:
    props = {}
    copy_keys = [
        "id", "title", "description", "event_type", "target_id",
        "required_attribute", "effort_required", "is_optional", "is_opposed", "opposing_attribute",
        "opposition_value", "journal_entry_id", "reward_id", "dialogue_id", "enter_journal_id",
        "exit_journal_id", "zone_coords"
    ]

    for k in copy_keys:
        if k in data:
            props[k] = data[k]

    # Handle StringNames explicitly
    for k in ["id", "dialogue_id", "enter_dialogue_id", "exit_dialogue_id"]:
        if k in props:
             val = props[k]
             props[k] = f'&"{val}"' # Force StringName format

    if "target_coord" in data:
        props["target_coord"] = data["target_coord"]
    else:
        props["target_coord"] = {"x": -999, "y": -999}

    if "on_enter" in data:
        oe = data["on_enter"]
        if "dialogue_id" in oe:
            dialogue_id = oe["dialogue_id"]
            if level_id:
                dialogue_path = _ensure_dialogue_file_exists(level_id, dialogue_id)
                props["start_dialogue_resource"] = dialogue_path
            props["enter_dialogue_id"] = f'&"{dialogue_id}"'
        if "journal_id" in oe: props["enter_journal_id"] = oe["journal_id"]

    if "on_exit" in data:
        ox = data["on_exit"]
        if "dialogue_id" in ox:
            dialogue_id = ox["dialogue_id"]
            if level_id:
                dialogue_path = _ensure_dialogue_file_exists(level_id, dialogue_id)
                props["exit_dialogue_resource"] = dialogue_path
            props["exit_dialogue_id"] = f'&"{dialogue_id}"'
        if "journal_id" in ox: props["exit_journal_id"] = ox["journal_id"]

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
    stage_id = stage.get('id') or f'stage_{index}'
    return _slugify(stage_id)


def _stage_file_name(level_slug: str, stage_slug: str) -> str:
    return f"{level_slug}_{stage_slug}.tres"



def _to_faction(value) -> int:
    if isinstance(value, int):
        return value
    mapping = {'player': 0, 'ally': 0, 'enemy': 1, 'foe': 1, 'neutral': 2, 'npc': 2}
    key = str(value).strip().lower()
    return mapping.get(key, 0)


def _clear_existing_rows(level_slug: str, dirs: dict) -> None:
    for key in ('terrain_rows_fs', 'start_rows_fs', 'roster_rows_fs', 'loot_rows_fs', 'location_rows_fs', 'meta_rows_fs', 'dialogue_rows_fs', 'journal_entry_rows_fs'):
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
    _generate_meta_row(level_id, level_slug, dirs, data)
    _generate_terrain_rows(level_id, level_slug, dirs, data.get('terrain', {}))
    player_starts = data.get('player_starts') or data.get('spawns', {}).get('player_starts', []) or []
    _generate_start_rows(level_id, level_slug, dirs, player_starts)
    stages = data.get('objective', {}).get('stages', []) or []
    _generate_roster_rows(level_id, level_slug, dirs, stages)
    _generate_loot_rows(level_id, level_slug, dirs, stages)
    _generate_location_rows(level_id, level_slug, dirs, stages)
    _generate_dialogue_rows(level_id, level_slug, dirs, stages)
    _generate_journal_rows(level_id, level_slug, dirs, stages)



def _generate_meta_row(level_id: str, level_slug: str, dirs: dict, data: dict) -> None:
    res_path = f"{dirs['meta_rows_res']}/{level_slug}_meta.tres"
    builder = TresBuilder()
    builder.add_ext_resource(SCRIPT_PATHS['LevelMetaRow'], 'Script')
    props = {
        'level_id': f'&"{level_id}"',
        'initial_rotation': data.get('initial_rotation', 0.0),
        'hex_offset_axis': data.get('hex_offset_axis', 1),
        'notes': data.get('meta_notes', '')
    }
    content = builder.build_tres('LevelMetaRow', props, generate_deterministic_uid(res_path))
    write_tres_file(res_path, content)


def _generate_terrain_rows(level_id: str, level_slug: str, dirs: dict, terrain: dict) -> None:
    rows = terrain.get('rows', []) or []
    for index, row_data in enumerate(rows):
        res_path = f"{dirs['terrain_rows_res']}/{level_slug}_terrain_row_{index}.tres"
        builder = TresBuilder()
        builder.add_ext_resource(SCRIPT_PATHS['LevelTerrainRow'], 'Script')
        props = {
            'level_id': f'&"{level_id}"',
            'row_index': index,
            'row_data': str(row_data),
            'notes': ''
        }
        content = builder.build_tres('LevelTerrainRow', props, generate_deterministic_uid(res_path))
        write_tres_file(res_path, content)


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
        builder.add_ext_resource(SCRIPT_PATHS['LevelStartRow'], 'Script')
        props = {
            'level_id': f'&"{level_id}"',
            'faction': f'&"{faction}"',
            'slot_index': slot_index,
            'coord': coord,
            'notes': ''
        }
        if unit_scene_path:
            unit_ext = builder.add_ext_resource(unit_scene_path, 'PackedScene')
            props['unit_scene'] = f'ExtResource("{unit_ext}")'
        content = builder.build_tres('LevelStartRow', props, generate_deterministic_uid(res_path))
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
        for spawn in stage.get('spawns', []) or []:
            faction = str(spawn.get('faction', 'enemy')).lower()
            if faction == 'player':
                continue
            if faction not in ('enemy', 'neutral'):
                faction = 'enemy'
            _write_roster_row(level_id, level_slug, stage_slug, dirs, spawn, faction, counters, stage_id)



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
    builder.add_ext_resource(SCRIPT_PATHS['LevelRosterRow'], 'Script')
    unit_ext = builder.add_ext_resource(unit_scene_path, 'PackedScene')
    props = {
        'level_id': f'&"{level_id}"',
        'faction': f'&"{faction}"',
        'coord': spawn.get('coord', {"x": -999, "y": -999}),
        'unit_scene': f'ExtResource("{unit_ext}")',
        'notes': stage_id or ''
    }
    content = builder.build_tres('LevelRosterRow', props, generate_deterministic_uid(res_path))
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
            builder.add_ext_resource(SCRIPT_PATHS['LevelLootRow'], 'Script')
            item_refs = []
            for item_path in loot.get('items', []) or []:
                if not item_path:
                    continue
                item_ext = builder.add_ext_resource(item_path, 'Resource')
                item_refs.append(f'ExtResource("{item_ext}")')
            props = {
                'level_id': f'&"{level_id}"',
                'coord': loot.get('coord', {"x": -999, "y": -999}),
                'items': item_refs,
                'notes': stage_id or ''
            }
            content = builder.build_tres('LevelLootRow', props, generate_deterministic_uid(res_path))
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
            builder.add_ext_resource(SCRIPT_PATHS['LevelTaskRow'], 'Script')
            scene_ext = builder.add_ext_resource(scene_path, 'PackedScene')
            props = {
                'level_id': f'&"{level_id}"',
                'coord': loc.get('coord', {"x": -999, "y": -999}),
                'location_scene': f'ExtResource("{scene_ext}")',
                'notes': stage_id or ''
            }
            content = builder.build_tres('LevelTaskRow', props, generate_deterministic_uid(res_path))
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
                    combined.append(({
                        "entry_id": toe["dialogue_id"],
                        "notes": f"Task {task_id} on_enter"
                    }, True))
            if "on_exit" in task and "dialogue_id" in task["on_exit"]:
                tox = task["on_exit"]
                if isinstance(tox.get("dialogue_id"), str):
                    combined.append(({
                        "entry_id": tox["dialogue_id"],
                        "notes": f"Task {task_id} on_exit"
                    }, True))

        for entry, is_auto_trigger in combined:
            res_path = f"{dirs['dialogue_rows_res']}/{level_slug}_{stage_slug}_dialogue_{count}.tres"
            builder = TresBuilder()
            builder.add_ext_resource(SCRIPT_PATHS['LevelDialogueRow'], 'Script')
            entry_id = entry.get('entry_id') or entry.get('journal_entry_id') or f"{stage_slug}_dialogue_{count}"
            initiator = entry.get('initiator_name', '')
            partner = entry.get('partner_name', '')
            flag_name = entry.get('flag_name', '')
            group_id = entry.get('group_id', stage_id or '')

            # For on_enter/on_exit dialogues, we set specific flags
            requires_adjacent = entry.get('requires_adjacent', not is_auto_trigger)
            consume_action = entry.get('consume_action', not is_auto_trigger)
            allow_partner = entry.get('allow_partner_initiation', is_auto_trigger)

            props = {
                'level_id': f'&"{level_id}"',
                'entry_id': f'&"{entry_id}"',
                'initiator_name': f'&"{initiator}"',
                'partner_name': f'&"{partner}"',
                'partner_faction': _to_faction(entry.get('partner_faction', 'neutral')),
                'coord': entry.get('coord', {"x": -999, "y": -999}),
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
            content = builder.build_tres('LevelDialogueRow', props, generate_deterministic_uid(res_path))
            write_tres_file(res_path, content)
            count += 1
        counters[stage_slug] = count



def _generate_journal_rows(level_id: str, level_slug: str, dirs: dict, stages: list) -> None:
    counters: dict = {}
    for index, stage in enumerate(stages):
        stage_slug = _stage_slug(stage, index)
        stage_id = stage.get('id', '')
        count = counters.get(stage_slug, 0)
        combined: list[dict] = []
        combined += stage.get('journal_entries', []) or []
        combined += stage.get('dialogue_journal_entries', []) or []

        # Add stage on_enter/on_exit journal entries
        if "on_enter" in stage and "journal_id" in stage["on_enter"]:
            journal_id = stage["on_enter"].get("journal_id")
            if isinstance(journal_id, str):
                combined.append({
                    "id": journal_id,
                    "title": f"Stage {stage_id} Started",
                    "notes": f"Stage {stage_id} on_enter",
                    "section_id": "progress",
                    "entry_type": "trigger"
                })

        if "on_exit" in stage and "journal_id" in stage["on_exit"]:
            journal_id = stage["on_exit"].get("journal_id")
            if isinstance(journal_id, str):
                combined.append({
                    "id": journal_id,
                    "title": f"Stage {stage_id} Completed",
                    "notes": f"Stage {stage_id} on_exit",
                    "section_id": "progress",
                    "entry_type": "trigger"
                })

        # Add task on_enter/on_exit journal entries
        for task in stage.get("tasks", []):
            task_id = task.get("id", "task")
            if "on_enter" in task and "journal_id" in task["on_enter"]:
                journal_id = task["on_enter"].get("journal_id")
                if isinstance(journal_id, str):
                    combined.append({
                        "id": journal_id,
                        "title": f"Task {task_id} Started",
                        "notes": f"Task {task_id} on_enter",
                        "section_id": "progress",
                        "entry_type": "trigger"
                    })

            if "on_exit" in task and "journal_id" in task["on_exit"]:
                journal_id = task["on_exit"].get("journal_id")
                if isinstance(journal_id, str):
                    combined.append({
                        "id": journal_id,
                        "title": f"Task {task_id} Completed",
                        "notes": f"Task {task_id} on_exit",
                        "section_id": "progress",
                        "entry_type": "trigger"
                    })

        for entry in combined:
            res_path = f"{dirs['journal_entry_rows_res']}/{level_slug}_{stage_slug}_journal_{count}.tres"
            builder = TresBuilder()
            builder.add_ext_resource(SCRIPT_PATHS['LevelJournalEntry'], 'Script')
            journal_id = entry.get('journal_entry_id') or entry.get('id') or entry.get('entry_id') or f"{stage_slug}_journal_{count}"
            title = entry.get('journal_title') or entry.get('title') or entry.get('action_label') or journal_id
            content_text = entry.get('journal_content') or entry.get('content') or entry.get('journal_notes') or entry.get('notes', '')
            flag_name = entry.get('flag_name', '')
            topic_id = entry.get('journal_topic_id', entry.get('topic_id', ''))
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
    sid = data.get("id", stage_slug)
    filename = _stage_file_name(level_slug, stage_slug)
    tres_path = os.path.join(stage_fs_dir, filename).replace(os.sep, '/')
    stage_res_path = f"{stage_res_dir}/{filename}"
    uid = generate_deterministic_uid(tres_path)

    builder = TresBuilder()
    builder.add_ext_resource(SCRIPT_PATHS["Stage"], "Script")  # Ensure script is referenced

    # Process Tasks
    task_refs = []
    for t_data in data.get("tasks", []):
        trid = build_task(builder, t_data, level_id)
        task_refs.append(f'SubResource("{trid}")')

    # Process Spawns
    enemy_refs = []
    # explicit enemy spawns
    for s_data in data.get("enemy_spawns", []):
        srid = build_level_unit_spawn_entry(builder, s_data, 1)  # 1 = Enemy
        enemy_refs.append(f'SubResource("{srid}")')

    # Explicit neutral spawns
    neutral_refs = []
    for s_data in data.get("neutral_spawns", []):
        srid = build_level_unit_spawn_entry(builder, s_data, 2)  # 2 = Neutral
        neutral_refs.append(f'SubResource("{srid}")')

    # Convert legacy spawns if any
    if "spawns" in data and isinstance(data["spawns"], list):
        for s_data in data["spawns"]:
            fac = s_data.get("faction", "ENEMY")
            if fac == "NEUTRAL":
                srid = build_level_unit_spawn_entry(builder, s_data, 2)
                neutral_refs.append(f'SubResource("{srid}")')
            elif fac == "PLAYER":
                srid = build_level_unit_spawn_entry(builder, s_data, 0)
                neutral_refs.append(f'SubResource("{srid}")')
            else:
                srid = build_level_unit_spawn_entry(builder, s_data, 1)
                enemy_refs.append(f'SubResource("{srid}")')

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
        "id": f'&"{sid}"',
        "tasks": task_refs,
        "completion_mode": ENUM_VALUES["CompletionMode"].get(data.get("completion_mode", "ALL_REQUIRED"), 0),
        "auto_advance": data.get("auto_advance", True),
        "enemy_spawns": enemy_refs,
        "neutral_spawns": neutral_refs,
        "loot_spawns": loot_refs,
        "location_spawns": location_refs,
        "dialogue_entries": dialogue_refs,
        "journal_entries": journal_refs,
        "dialogue_journal_entries": dialogue_journal_refs,
        "spawns": [],
    }

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
            dialogue_path = _ensure_dialogue_file_exists(level_id, dialogue_id)
            props["exit_dialogue_resource"] = dialogue_path
            props["exit_dialogue_id"] = f'&"{dialogue_id}"'
        if "journal_id" in ox:
            props["exit_journal_id"] = ox["journal_id"]

    # Next Stage Reference handling (External)
    next_id = data.get("default_next_stage_id")
    if next_id:
        next_slug = stage_slug_map.get(next_id, _slugify(next_id))
        next_path = f"{stage_res_dir}/{_stage_file_name(level_slug, next_slug)}"
        nid = builder.add_ext_resource(next_path, "Resource")
        props["default_next_stage"] = f'ExtResource("{nid}")'

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
        t_props = {
            "grid_width": t_data.get("grid_width", 7),
            "grid_height": t_data.get("grid_height", 7),
            "terrain_rows": t_data.get("rows", [])
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
        stage_id = s_data.get("id") or f"stage_{index}"
        stage_slug_map[stage_id] = _stage_slug(s_data, index)

    stage_refs = []
    for index, s_data in enumerate(stage_defs):
        stage_id = s_data.get("id") or f"stage_{index}"
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
        stage_refs.append(f'ExtResource("{srid}")')

    obj_props = {
        "objective_id": f'&"{obj_data["id"]}"',
        "title": obj_data.get("title", "Objective"),
        "stages": stage_refs
    }
    obj_id = builder.add_sub_resource("Objective", obj_props)

    # Player Starts
    p_starts = []
    if "player_starts" in data:
        p_starts = data["player_starts"]
    elif "spawns" in data and "player_starts" in data["spawns"]:
        p_starts = data["spawns"]["player_starts"]

    # Main Level Props
    main_props = {
        "display_name": data.get("display_name", "New Level"),
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
    abs_path = file_path.replace("res://", "./")
    os.makedirs(os.path.dirname(abs_path), exist_ok=True)
    with open(abs_path, "w", encoding="utf-8") as f:
        f.write(content)
    logger.info(f"Generated: {file_path}")


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
                    c = entry["coord"]
                    if c.get("x", 0) < 0 or c.get("y", 0) < 0:
                        logger.warning(f"Negative coordinate found in {group} of stage {stage['id']}: {c}")

    # Check player starts
    starts = data.get("player_starts") or data.get("spawns", {}).get("player_starts", [])
    for start in starts:
        if isinstance(start, dict):
            if start.get("x", 0) < 0 or start.get("y", 0) < 0:
                 logger.warning(f"Negative coordinate found in player_starts: {start}")


def validate_and_ensure_scripts():
    """Checks if all scripts in SCRIPT_PATHS exist and creates minimalist ones if missing."""
    for class_name, res_path in SCRIPT_PATHS.items():
        local_path = res_path.replace("res://", "./")
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
    global _generated_stage_paths
    _generated_stage_paths = {}
    validate_and_ensure_scripts()
    errors_encountered = []
    try:
        if not os.path.exists(json_path):
             logger.error(f"Input file not found: {json_path}")
             errors_encountered.append(f"Input file not found: {json_path}")
             return

        with open(json_path, "r", encoding="utf-8") as f: data = json.load(f)
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
        _write_level_list_document(lid if 'lid' in locals() else "unknown_level", dirs["levels_fs"] if 'dirs' in locals() else os.path.join(out_base.replace('res://', './'), 'levels'), errors=errors_encountered)

def _write_level_list_document(level_id: str, levels_fs_dir: str, errors: list = None) -> None:
    """Writes a document listing the generated level files for a given level, including any errors."""
    if errors is None:
        errors = []

    # Define the new output directory for summaries
    summaries_base_dir_fs = os.path.join(os.path.dirname(levels_fs_dir), "summaries")

    # Construct the new file path with level_id as filename
    output_file_name = f"{_slugify(level_id)}.txt"
    output_file_path = os.path.join(summaries_base_dir_fs, output_file_name)

    level_slug = _slugify(level_id)
    all_generated_files = []

    # Define all relevant output directories relative to the base output directory
    output_base_dir_fs = os.path.dirname(levels_fs_dir) # Go up from 'levels' to 'level_data'
    relevant_subdirs = [
        "levels", "stages", "terrain_rows", "start_rows",
        "roster_rows", "loot_rows", "location_rows",
        "meta_rows", "dialogue_rows", "journal_entry_rows"
    ]

    for subdir in relevant_subdirs:
        full_subdir_path = os.path.join(output_base_dir_fs, subdir)
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
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert Level JSON to Godot Resources")
    parser.add_argument("--input", "-i", default="sample_level.json", help="Path to input JSON")
    parser.add_argument("--output", "-o", default=DEFAULT_OUTPUT_BASE_DIR, help="Output base directory")
    parser.add_argument("--verbose", "-v", action="store_true", help="Enable verbose logging")
    args = parser.parse_args()
    if args.verbose: logger.setLevel(logging.DEBUG)
    convert_json_to_tres(args.input, args.output)





