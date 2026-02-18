import json
import os
import logging
import argparse
import hashlib

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

# --- Configuration ---
DEFAULT_OUTPUT_BASE_DIR = "res://Resources/levels"
# Mapping of GDScript class names to their file paths
SCRIPT_PATHS = {
    "Level": "res://Resources/Level.gd",
    "Objective": "res://Resources/task/objective.gd",
    "Stage": "res://Resources/task/stage.gd",
    "Task": "res://Resources/task/task.gd",
    "JournalEntry": "res://Gameplay/journal/journal_entry.gd",
    "LevelDialogueEntry": "res://Resources/level_data/level_dialogue_entry.gd",
    "LevelDialogueJournalEntry": "res://Resources/level_data/level_dialogue_journal_entry.gd",
    "LevelTerrainData": "res://Resources/level_data/level_terrain_data.gd",

    "UnitRosterDefinition": "res://Resources/rosters/unit_roster_definition.gd", # Deprecated usage?
    "LevelUnitSpawnEntry": "res://Resources/level_data/level_unit_spawn_entry.gd",
    "LevelLootEntry": "res://Resources/level_data/level_loot_entry.gd",
    "LevelTaskEntry": "res://Resources/level_data/level_task_entry.gd",
    "CompletionCondition": "res://Resources/task/completion_condition.gd",
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
            return f'Vector2i({value["x"]}, {value["y"]})'
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

def build_level_dialogue_entry(builder: TresBuilder, data: dict) -> str:
    props = {}
    # Copy direct properties
    for k in ["initiator_name", "partner_name", "group_id", "dialogue_resource_path",
              "action_label", "action_hint", "repeatable", "requires_adjacent",
              "consume_action", "allow_partner_initiation"]:
        if k in data:
            if k == "group_id":
                 props[k] = f'&"{data[k]}"'
            else:
                 props[k] = data[k]

    if "coord" in data:
        props["coord"] = data["coord"]

    if "partner_faction" in data:
        props["partner_faction"] = ENUM_VALUES["UnitFaction"].get(data["partner_faction"], 0)

    return builder.add_sub_resource("LevelDialogueEntry", props)


def build_level_journal_entry(builder: TresBuilder, data: dict) -> str:
    props = {}
    # Copy direct properties
    for k in ["entry_id", "flag_name", "section_id", "topic_id", "notes", "level_id"]:
        if k in data:
            if k == "entry_id" or k == "flag_name" or k == "level_id":
                 props[k] = f'&"{data[k]}"'
            else:
                 props[k] = data[k]

    return builder.add_sub_resource("LevelJournalEntry", props)


def build_level_dialogue_journal_entry(builder: TresBuilder, data: dict) -> str:
    props = {}
    # Dialogue properties
    for k in ["initiator_name", "partner_name", "group_id", "dialogue_resource_path",
              "action_label", "action_hint", "repeatable", "requires_adjacent",
              "consume_action", "allow_partner_initiation"]:
        if k in data:
            if k == "group_id":
                 props[k] = f'&"{data[k]}"'
            else:
                 props[k] = data[k]

    if "coord" in data:
        props["coord"] = data["coord"]

    if "partner_faction" in data:
        props["partner_faction"] = ENUM_VALUES["UnitFaction"].get(data["partner_faction"], 0)

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

def build_task(builder: TresBuilder, data: dict) -> str:
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
        if "dialogue_id" in oe: props["enter_dialogue_id"] = f'&"{oe["dialogue_id"]}"'
        if "journal_id" in oe: props["enter_journal_id"] = oe["journal_id"]

    if "on_exit" in data:
        ox = data["on_exit"]
        if "dialogue_id" in ox: props["exit_dialogue_id"] = f'&"{ox["dialogue_id"]}"'
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


def generate_stage_tres(data: dict, output_dir: str, level_id: str):
    sid = data["id"]
    tres_path = os.path.join(output_dir, f"stage_{sid}.tres").replace(os.sep, '/')
    uid = generate_deterministic_uid(tres_path)

    builder = TresBuilder()
    builder.add_ext_resource(SCRIPT_PATHS["Stage"], "Script") # Ensure script is referenced

    # Process Tasks
    task_refs = []
    for t_data in data.get("tasks", []):
        trid = build_task(builder, t_data)
        task_refs.append(f'SubResource("{trid}")')

    # Process Spawns
    enemy_refs = []
    # explicit enemy spawns
    for s_data in data.get("enemy_spawns", []):
         srid = build_level_unit_spawn_entry(builder, s_data, 1) # 1 = Enemy
         enemy_refs.append(f'SubResource("{srid}")')

    # Explicit neutral spawns
    neutral_refs = []
    for s_data in data.get("neutral_spawns", []):
         srid = build_level_unit_spawn_entry(builder, s_data, 2) # 2 = Neutral
         neutral_refs.append(f'SubResource("{srid}")')

    # Convert "Legacy" spawns if any (User said legacy is confusing, but we should handle it or ignore it.
    # Let's check 'spawns' list and sort by faction if present, or default to Enemy if not specified.)
    if "spawns" in data and isinstance(data["spawns"], list):
        for s_data in data["spawns"]:
            # Check faction
            fac = s_data.get("faction", "ENEMY")
            if fac == "NEUTRAL":
                 srid = build_level_unit_spawn_entry(builder, s_data, 2)
                 neutral_refs.append(f'SubResource("{srid}")')
            elif fac == "PLAYER":
                 # Player spawns usually in level? Or maybe ally unit in stage.
                 # User said: "level should have player starting coords".
                 # If this is a unit spawn, maybe it's an ally.
                 srid = build_level_unit_spawn_entry(builder, s_data, 0)
                 # We don't have a 'ally_spawns' list in Stage explicitly in previous code,
                 # but maybe we should add it or treat as neutral?
                 # For now, put in neutral or warn?
                 # LevelBuilder processes 'neutral_spawns', 'enemy_spawns'.
                 # If we put it in neutral, it works.
                 neutral_refs.append(f'SubResource("{srid}")')
            else:
                 srid = build_level_unit_spawn_entry(builder, s_data, 1) # Enemy
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
        drid = build_level_dialogue_entry(builder, d_data)
        dialogue_refs.append(f'SubResource("{drid}")')

    journal_refs = []
    for j_data in data.get("journal_entries", []):
        jrid = build_level_journal_entry(builder, j_data)
        journal_refs.append(f'SubResource("{jrid}")')

    dialogue_journal_refs = []
    for dj_data in data.get("dialogue_journal_entries", []):
        djrid = build_level_dialogue_journal_entry(builder, dj_data)
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
        "spawns": [] # Legacy field cleared/unused


    }

    # On Enter/Exit
    if "on_enter" in data:
        oe = data["on_enter"]
        if "dialogue_id" in oe: props["start_dialogue_resource"] = oe["dialogue_id"] # Type mismatch in GDScript? Export is String usually
        if "journal_id" in oe: props["enter_journal_id"] = oe["journal_id"]

    if "on_exit" in data:
        ox = data["on_exit"]
        if "dialogue_id" in ox: props["exit_dialogue_id"] = f'&"{ox["dialogue_id"]}"'
        if "journal_id" in ox: props["exit_journal_id"] = ox["journal_id"]

    # Next Stage Reference handling (External)
    next_id = data.get("default_next_stage_id")
    if next_id:
        # We assume the file pattern
        next_path = f"res://Resources/levels/{level_id}/stages/stage_{next_id}.tres"
        nid = builder.add_ext_resource(next_path, "Resource")
        props["default_next_stage"] = f'ExtResource("{nid}")'

    content = builder.build_tres("Stage", props, uid)
    write_tres_file(tres_path, content)
    _generated_stage_paths[f"{level_id}_{sid}"] = f"res://{tres_path.replace('./', '')}"


def generate_level_tres(data: dict, output_dir: str):
    lid = data["level_id"]
    tres_path = os.path.join(output_dir, f"{lid}.tres").replace(os.sep, '/')
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

    stage_refs = []
    # Create the stages directory
    stages_dir = os.path.join(output_dir, "stages")
    os.makedirs(stages_dir, exist_ok=True)

    for s_data in obj_data.get("stages", []):
         generate_stage_tres(s_data, stages_dir, lid)
         # Now reference it
         s_path = f"res://Resources/levels/{lid}/stages/stage_{s_data['id']}.tres"
         srid = builder.add_ext_resource(s_path, "Resource")
         stage_refs.append(f'ExtResource("{srid}")')

    obj_props = {
        "objective_id": f'&"{obj_data["id"]}"',
        "title": obj_data.get("title", "Objective"),
        "stages": stage_refs
    }
    obj_id = builder.add_sub_resource("Objective", obj_props)

    # Player Starts
    p_starts = []
    # check legacy location or new top-level
    if "player_starts" in data:
         p_starts = data["player_starts"]
    elif "spawns" in data and "player_starts" in data["spawns"]:
         p_starts = data["spawns"]["player_starts"]

    # Main Level Props
    main_props = {
        "display_name": data.get("display_name", "New Level"),
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
    try:
        if not os.path.exists(json_path):
             logger.error(f"Input file not found: {json_path}")
             return

        with open(json_path, "r", encoding="utf-8") as f: data = json.load(f)
        validate_level_data(data)

        lid = data["level_id"]
        # Output struct: <base>/<lid>/
        out_dir = os.path.join(out_base.replace("res://", "./"), lid).replace(os.sep, '/')

        logger.info(f"Converting level: {lid} -> {out_dir}")
        generate_level_tres(data, out_dir)
        logger.info(f"Done: {lid}")

    except Exception as e:
        logger.error(f"Error converting {json_path}: {e}", exc_info=True)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert Level JSON to Godot Resources")
    parser.add_argument("--input", "-i", default="sample_level.json", help="Path to input JSON")
    parser.add_argument("--output", "-o", default=DEFAULT_OUTPUT_BASE_DIR, help="Output base directory")
    parser.add_argument("--verbose", "-v", action="store_true", help="Enable verbose logging")
    args = parser.parse_args()
    if args.verbose: logger.setLevel(logging.DEBUG)
    convert_json_to_tres(args.input, args.output)
