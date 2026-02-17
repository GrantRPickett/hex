import json
import os
import logging
import argparse
import hashlib

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

# --- Configuration ---
TEMPLATES_DIR = os.path.join(os.path.dirname(__file__), "templates")
DEFAULT_OUTPUT_BASE_DIR = "res://GeneratedLevels"
# Mapping of GDScript class names to their file paths
SCRIPT_PATHS = {
    "Level": "res://Resources/Level.gd",
    "Objective": "res://Resources/objective.gd",
    "Stage": "res://Resources/task/stage.gd",
    "Task": "res://Resources/task/task.gd",
    "JournalEntry": "res://Gameplay/Journal/journal_entry.gd",
    "LevelDialogueEntry": "res://Resources/level_data/level_dialogue_entry.gd",
    "LevelTerrainData": "res://Resources/level_data/level_terrain_data.gd",
    "UnitRosterDefinition": "res://Resources/rosters/unit_roster_definition.gd",
    "LevelUnitSpawnEntry": "res://Resources/level_data/level_unit_spawn_entry.gd",
    "LootListDefinition": "res://Resources/loot_lists/loot_list_definition.gd",
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
    }
}

# Global map for cross-referencing in Pass 2
_generated_stage_paths = {}

# --- Utilities ---

def fill_template(template_name, context):
    """Loads a template and replaces placeholders."""
    template_path = os.path.join(TEMPLATES_DIR, f"{template_name}.tres.template")
    if not os.path.exists(template_path):
        template_path = os.path.join(TEMPLATES_DIR, "standard.tres.template")

    with open(template_path, "r", encoding="utf-8") as f:
        content = f.read()

    for key, value in context.items():
        placeholder = "{{" + key + "}}"
        content = content.replace(placeholder, str(value))

    import re
    # Cleanup: remove lines with unused placeholders
    content = re.sub(r"^[^\n]*\{\{.*?\}\}[^\n]*\n?", "", content, flags=re.MULTILINE)
    # Cleanup: remove remaining inline placeholders
    content = re.sub(r"\{\{.*?\}\}", "", content)
    # Cleanup: collapse multiple blank lines
    content = re.sub(r"\n{3,}", "\n\n", content)
    return content.strip() + "\n"

def generate_deterministic_uid(seed_string: str) -> str:
    """Generates a stable UID string from a seed string."""
    hash_obj = hashlib.md5(seed_string.encode('utf-8'))
    return f"uid://{hash_obj.hexdigest()[:12]}"

def gd_variant_to_tres(value, is_string_name=False):
    """Converts a Python value to its Godot .tres string representation."""
    if isinstance(value, str):
        if is_string_name:
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
        if isinstance(value[0], dict) and "x" in value[0] and "y" in value[0]:
            inner_type = "Vector2i"
        elif isinstance(value[0], str):
            inner_type = "String"
        elif isinstance(value[0], int):
            inner_type = "int"

        items = [gd_variant_to_tres(item) for item in value]
        return f'Array[{inner_type}]({", ".join(items)})'
    elif isinstance(value, dict):
        if "x" in value and "y" in value and len(value) == 2:
            return f'Vector2i({value["x"]}, {value["y"]})'
        items = [f'{gd_variant_to_tres(k, is_string_name=(k in ["id", "topic_id", "section_id"]))}: {gd_variant_to_tres(v)}' for k, v in value.items()]
        return f'{{{", ".join(items)}}}'
    return 'null' if value is None else str(value)

def write_tres_file(file_path, content):
    """Writes content to a .tres file."""
    abs_path = file_path.replace("res://", "./")
    os.makedirs(os.path.dirname(abs_path), exist_ok=True)
    action = "Updating" if os.path.exists(abs_path) else "Generating"
    with open(abs_path, "w", encoding="utf-8") as f:
        f.write(content)
    logger.info(f"{action}: {file_path}")

# --- Validation ---

def validate_level_data(data: dict):
    """Deep validation of level JSON structure."""
    required_root = ["level_id", "display_name", "objective"]
    for key in required_root:
        if key not in data:
            raise ValueError(f"Missing required root key: '{key}'")

    obj = data["objective"]
    if "id" not in obj or "stages" not in obj:
        raise ValueError("Objective must have 'id' and 'stages'")

    for i, stage in enumerate(obj["stages"]):
        if "id" not in stage:
            raise ValueError(f"Stage at index {i} is missing 'id'")
        for j, task in enumerate(stage.get("tasks", [])):
            if "id" not in task:
                raise ValueError(f"Stage '{stage['id']}' task at index {j} is missing 'id'")

# --- Resource Generators ---

def generate_journal_entry_tres(entry_data, output_dir):
    try:
        e_id = entry_data["id"]
        tres_path = os.path.join(output_dir, f"journal_entry_{e_id}.tres").replace(os.sep, '/')
        uid = generate_deterministic_uid(tres_path)

        props = []
        for k, v in entry_data.items():
            if k in ["id", "topic_id", "section_id", "entry_type", "status", "related_id"]:
                props.append(f'{k} = "{v}"')
            else:
                props.append(f'{k} = {gd_variant_to_tres(v)}')

        content = fill_template("standard", {
            "script_class": "JournalEntry",
            "load_steps": 2,
            "uid": uid,
            "script_path": SCRIPT_PATHS["JournalEntry"],
            "ext_resources": "",
            "properties": "\n".join(props)
        })

        write_tres_file(tres_path, content)
        return f"res://{tres_path.replace('./', '')}", uid
    except Exception as e:
        logger.warning(f"Journal Entry error: {e}")
        return None, None

def generate_completion_condition_tres(condition_data, output_dir, condition_id):
    try:
        tres_path = os.path.join(output_dir, f"condition_{condition_id}.tres").replace(os.sep, '/')
        uid = generate_deterministic_uid(tres_path)

        props = []
        for k, v in condition_data.items():
            if k == "type":
                props.append(f'type = "{v}"')
            elif k == "faction":
                props.append(f'faction = {ENUM_VALUES["UnitFaction"].get(v, 0)}')
            else:
                props.append(f'{k} = {gd_variant_to_tres(v)}')

        content = fill_template("standard", {
            "script_class": "CompletionCondition",
            "load_steps": 2,
            "uid": uid,
            "script_path": SCRIPT_PATHS["CompletionCondition"],
            "ext_resources": "",
            "properties": "\n".join(props)
        })

        write_tres_file(tres_path, content)
        return f"res://{tres_path.replace('./', '')}", uid
    except Exception as e:
        logger.warning(f"Condition error {condition_id}: {e}")
        return None, None

def generate_task_tres(task_data, output_dir, level_id, stage_id, script_id_map):
    try:
        t_id = task_data["id"]
        tres_path = os.path.join(output_dir, f"task_{level_id}_{stage_id}_{t_id}.tres").replace(os.sep, '/')
        uid = generate_deterministic_uid(tres_path)

        ext_decls, load_steps = [], 2

        ctx = {
            "uid": uid,
            "script_path": SCRIPT_PATHS["Task"],
            "id": gd_variant_to_tres(t_id, is_string_name=True),
            "title": gd_variant_to_tres(task_data.get("title", "New Task")),
            "description": gd_variant_to_tres(task_data.get("description", "")),
            "event_type": gd_variant_to_tres(task_data.get("event_type", "interact")),
            "target_coord": gd_variant_to_tres(task_data.get("target_coord", {"x": -999, "y": -999})),
            "target_id": gd_variant_to_tres(task_data.get("target_id", "")),
            "required_attribute": gd_variant_to_tres(task_data.get("required_attribute", "grit")),
            "effort_required": gd_variant_to_tres(task_data.get("effort_required", 10)),
            "is_optional": gd_variant_to_tres(task_data.get("is_optional", False)),
            "journal_entry_id": gd_variant_to_tres(task_data.get("journal_entry_id", "")),
            "reward_id": gd_variant_to_tres(task_data.get("reward_id", "")),
            "enter_dialogue_id": gd_variant_to_tres("", is_string_name=True),
            "exit_dialogue_id": gd_variant_to_tres("", is_string_name=True),
            "enter_journal_id": gd_variant_to_tres(""),
            "exit_journal_id": gd_variant_to_tres(""),
            "custom_properties": ""
        }

        if "completion_condition" in task_data:
            path, _ = generate_completion_condition_tres(task_data["completion_condition"], output_dir, f"{level_id}_{stage_id}_{t_id}_cond")
            ext_decls.append(f'[ext_resource type="Resource" path="{path}" id="2_cond"]')
            ctx["custom_properties"] = 'completion_condition = ExtResource("2_cond")'
            load_steps += 1

        if "on_enter" in task_data:
            oe = task_data["on_enter"]
            if "dialogue_id" in oe: ctx["enter_dialogue_id"] = gd_variant_to_tres(oe["dialogue_id"], is_string_name=True)
            if "journal_id" in oe: ctx["enter_journal_id"] = gd_variant_to_tres(oe["journal_id"])

        if "on_exit" in task_data:
            ox = task_data["on_exit"]
            if "dialogue_id" in ox: ctx["exit_dialogue_id"] = gd_variant_to_tres(ox["dialogue_id"], is_string_name=True)
            if "journal_id" in ox: ctx["exit_journal_id"] = gd_variant_to_tres(ox["journal_id"])

        ctx["load_steps"] = load_steps
        ctx["ext_resources"] = "\n".join(ext_decls)

        content = fill_template("task", ctx)
        write_tres_file(tres_path, content)
        script_id_map[f"Task_{t_id}"] = tres_path
        return f"res://{tres_path.replace('./', '')}", uid
    except Exception as e:
        logger.warning(f"Task error {task_data.get('id')}: {e}")
        return None, None

def generate_stage_spawn_entry_tres(spawn_data, output_dir, spawn_id):
    try:
        tres_path = os.path.join(output_dir, f"unit_spawn_{spawn_id}.tres").replace(os.sep, '/')
        uid = generate_deterministic_uid(tres_path)

        ext_decls, load_steps = [], 2
        props = []

        if spawn_data.get("unit_scene_path"):
            ext_decls.append(f'[ext_resource type="PackedScene" path="{spawn_data["unit_scene_path"]}" id="2_scene"]')
            props.append('unit_scene = ExtResource("2_scene")')
            load_steps += 1

        inv_refs = []
        if spawn_data.get("inventory"):
            for idx, item in enumerate(spawn_data["inventory"]):
                rid = f"{load_steps}_item"
                ext_decls.append(f'[ext_resource type="Resource" path="{item}" id="{rid}"]')
                inv_refs.append(f'ExtResource("{rid}")')
                load_steps += 1
            props.append(f'inventory = Array[ExtResource]({", ".join(inv_refs)})')
        else:
            props.append('inventory = Array[Variant]([])')

        for k, v in spawn_data.items():
            if k == "unit_scene_path": continue
            elif k == "faction": props.append(f'faction = {ENUM_VALUES["UnitFaction"].get(v, 0)}')
            elif k == "inventory": continue
            else: props.append(f'{k} = {gd_variant_to_tres(v)}')

        content = fill_template("standard", {
            "script_class": "LevelUnitSpawnEntry",
            "load_steps": load_steps,
            "uid": uid,
            "script_path": SCRIPT_PATHS["LevelUnitSpawnEntry"],
            "ext_resources": "\n".join(ext_decls),
            "properties": "\n".join(props)
        })

        write_tres_file(tres_path, content)
        return f"res://{tres_path.replace('./', '')}", uid
    except Exception as e:
        logger.warning(f"Spawn entry error {spawn_id}: {e}")
        return None, None

def generate_stage_tres_pass1(stage_data, output_dir, level_id, script_id_map):
    try:
        s_id = stage_data["id"]
        tres_path = os.path.join(output_dir, f"stage_{level_id}_{s_id}.tres").replace(os.sep, '/')
        uid = generate_deterministic_uid(tres_path)

        ext_decls, load_steps = [], 2

        task_refs = []
        for t_def in stage_data.get("tasks", []):
            path, _ = generate_task_tres(t_def, output_dir, level_id, s_id, script_id_map)
            rid = f"task_{t_def['id']}"
            ext_decls.append(f'[ext_resource type="Resource" path="{path}" id="{rid}"]')
            task_refs.append(f'ExtResource("{rid}")')
            load_steps += 1

        def process_spawns(data_list, prefix):
            refs = []
            nonlocal load_steps
            for i, sd in enumerate(data_list):
                sid = f"{s_id}_{prefix}_{i}"
                if prefix == "loot":
                    path, _ = generate_level_loot_entry_tres(sd, output_dir, sid)
                elif prefix == "loc":
                    path, _ = generate_level_task_entry_tres(sd, output_dir, sid)
                else:
                    path, _ = generate_stage_spawn_entry_tres(sd, output_dir, sid)
                rid = f"spawn_{prefix}_{i}"
                ext_decls.append(f'[ext_resource type="Resource" path="{path}" id="{rid}"]')
                refs.append(f'ExtResource("{rid}")')
                load_steps += 1
            return refs

        enemy_refs = process_spawns(stage_data.get("enemy_spawns", []), "enemy")
        neutral_refs = process_spawns(stage_data.get("neutral_spawns", []), "neutral")
        loot_refs = process_spawns(stage_data.get("loot_spawns", []), "loot")
        loc_refs = process_spawns(stage_data.get("location_spawns", []), "loc")
        legacy_refs = process_spawns(stage_data.get("spawns", []), "legacy")

        ctx = {
            "script_path": SCRIPT_PATHS["Stage"],
            "uid": uid,
            "load_steps": load_steps,
            "ext_resources": "\n".join(ext_decls),
            "id": gd_variant_to_tres(s_id, is_string_name=True),
            "task_array": f'Array[ExtResource]({", ".join(task_refs)})',
            "completion_mode": ENUM_VALUES["CompletionMode"].get(stage_data.get("completion_mode", "ALL_REQUIRED"), 0),
            "auto_advance": gd_variant_to_tres(stage_data.get("auto_advance", True)),
            "enter_dialogue_id": gd_variant_to_tres(stage_data.get("start_dialogue_resource", "")),
            "exit_dialogue_id": gd_variant_to_tres("", is_string_name=True),
            "enter_journal_id": gd_variant_to_tres(""),
            "exit_journal_id": gd_variant_to_tres(""),
            "enemy_spawns": f'enemy_spawns = Array[ExtResource]({", ".join(enemy_refs)})',
            "neutral_spawns": f'neutral_spawns = Array[ExtResource]({", ".join(neutral_refs)})',
            "loot_spawns": f'loot_spawns = Array[ExtResource]({", ".join(loot_refs)})',
            "location_spawns": f'location_spawns = Array[ExtResource]({", ".join(loc_refs)})',
            "legacy_spawns": f'spawns = Array[ExtResource]({", ".join(legacy_refs)})',
            "default_next_stage": f"null # REF_STAGE_ID: {stage_data.get('default_next_stage_id')}",
            "branching_transitions": f"{{}} # REF_BRANCHING: {json.dumps(stage_data.get('branching_transitions', {}))}"
        }

        if "on_enter" in stage_data:
            oe = stage_data["on_enter"]
            if "dialogue_id" in oe: ctx["enter_dialogue_id"] = gd_variant_to_tres(oe["dialogue_id"])
            if "journal_id" in oe: ctx["enter_journal_id"] = gd_variant_to_tres(oe["journal_id"])

        if "on_exit" in stage_data:
            ox = stage_data["on_exit"]
            if "dialogue_id" in ox: ctx["exit_dialogue_id"] = gd_variant_to_tres(ox["dialogue_id"], is_string_name=True)
            if "journal_id" in ox: ctx["exit_journal_id"] = gd_variant_to_tres(ox["journal_id"])

        custom_props = []
        for k, v in stage_data.items():
            if k in ["id", "tasks", "completion_mode", "enemy_spawns", "neutral_spawns",
                    "loot_spawns", "location_spawns", "spawns", "default_next_stage_id", "branching_transitions",
                    "on_enter", "on_exit"]:
                continue
            custom_props.append(f'{k} = {gd_variant_to_tres(v)}')
        ctx["custom_properties"] = "\n".join(custom_props)

        content = fill_template("stage", ctx)
        write_tres_file(tres_path, content)
        res_path = f"res://{tres_path.replace('./', '')}"
        _generated_stage_paths[f"{level_id}_{s_id}"] = res_path
        return res_path, uid
    except Exception as e:
        logger.warning(f"Stage error {stage_data.get('id')}: {e}")
        return None, None

def _resolve_stage_references(stage_data, output_dir, level_id):
    """Pass 2: Update stage files with cross-references."""
    try:
        tres_path = os.path.join(output_dir, f"stage_{level_id}_{stage_data['id']}.tres").replace(os.sep, '/')
        abs_p = tres_path.replace("res://", "./")
        if not os.path.exists(abs_p): return

        with open(abs_p, "r", encoding="utf-8") as f: content = f.read()

        def inject_ext(text, path, rid):
            if f'id="{rid}"' in text: return text
            lines = text.splitlines()
            idx = next((i for i, line in enumerate(lines) if line.startswith('[ext_resource')), -1)
            if idx != -1:
                while idx < len(lines) and lines[idx].startswith('[ext_resource'): idx += 1
                lines.insert(idx, f'[ext_resource type="Resource" path="{path}" id="{rid}"]')
            return "\n".join(lines)

        nxt = stage_data.get("default_next_stage_id")
        if nxt and f"{level_id}_{nxt}" in _generated_stage_paths:
            p = _generated_stage_paths[f"{level_id}_{nxt}"]
            rid = f"NEXT_{nxt}"
            content = inject_ext(content, p, rid)
            content = content.replace(f'null # REF_STAGE_ID: {nxt}', f'ExtResource("{rid}")')

        import re
        m = re.search(r'# REF_BRANCHING: (\{.*\})', content)
        if m:
            orig = json.loads(m.group(1))
            res = {}
            for tid, sid in orig.items():
                if f"{level_id}_{sid}" in _generated_stage_paths:
                    p, rid = _generated_stage_paths[f"{level_id}_{sid}"], f"BRANCH_{tid}_{sid}"
                    content = inject_ext(content, p, rid)
                    res[f'&"{tid}"'] = f'ExtResource("{rid}")'
            if res:
                r_str = "{" + ", ".join([f"{k}: {v}" for k, v in res.items()]) + "}"
                content = re.sub(r'branching_transitions = \{\} # REF_BRANCHING: .*', f'branching_transitions = {r_str}', content)

        count = content.count('[ext_resource')
        content = re.sub(r'load_steps=\d+', f'load_steps={count + 1}', content, 1)
        write_tres_file(tres_path, content)
    except Exception as e:
        logger.warning(f"Ref resolution error: {e}")

def _generate_terrain(data, out, lid, smap):
    if "terrain" not in data: return None
    t = data["terrain"]
    tres_path = os.path.join(out, f"terrain_{lid}.tres").replace(os.sep, '/')
    uid = generate_deterministic_uid(tres_path)

    props = [
        f'grid_width = {t["grid_width"]}',
        f'grid_height = {t["grid_height"]}',
        f'terrain_rows = {gd_variant_to_tres(t["rows"])}'
    ]

    content = fill_template("standard", {
        "script_class": "LevelTerrainData",
        "load_steps": 2,
        "uid": uid,
        "script_path": SCRIPT_PATHS["LevelTerrainData"],
        "ext_resources": "",
        "properties": "\n".join(props)
    })

    write_tres_file(tres_path, content)
    smap["terrain_ref"] = f"res://{tres_path.replace('./', '')}"
    return smap["terrain_ref"]

def _generate_rosters(data, out, lid, smap):
    sp = data.get("spawns", {})
    for rtype in ["enemy_units", "neutral_units"]:
        if sp.get(rtype):
            tid = "enemy" if "enemy" in rtype else "neutral"
            tres_path = os.path.join(out, f"roster_{lid}_{tid}.tres").replace(os.sep, '/')
            uid = generate_deterministic_uid(tres_path)

            srefs, sdecls = [], []
            for i, sd in enumerate(sp[rtype]):
                p, _ = generate_stage_spawn_entry_tres(sd, out, f"{lid}_{tid}_{i}")
                rid = f"spawn_{i}"
                sdecls.append(f'[ext_resource type="Resource" path="{p}" id="{rid}"]')
                srefs.append(f'ExtResource("{rid}")')

            content = fill_template("standard", {
                "script_class": "UnitRosterDefinition",
                "load_steps": 2 + len(sdecls),
                "uid": uid,
                "script_path": SCRIPT_PATHS["UnitRosterDefinition"],
                "ext_resources": "\n".join(sdecls),
                "properties": f'spawn_entries = Array[ExtResource]({", ".join(srefs)})'
            })

            write_tres_file(tres_path, content)
            smap[f"{tid}_roster_ref"] = f"res://{tres_path.replace('./', '')}"

def _generate_custom_spawns(data, out, lid, smap):
    sp = data.get("spawns", {})
    if sp.get("loot"):
        tres_path = os.path.join(out, f"loot_def_{lid}.tres").replace(os.sep, '/')
        uid = generate_deterministic_uid(tres_path)
        lrefs, ldecls = [], []
        for i, ld in enumerate(sp["loot"]):
            p, _ = generate_level_loot_entry_tres(ld, out, f"{lid}_loot_{i}")
            rid = f"loot_{i}"
            ldecls.append(f'[ext_resource type="Resource" path="{p}" id="{rid}"]')
            lrefs.append(f'ExtResource("{rid}")')

        content = fill_template("standard", {
            "script_class": "LootListDefinition",
            "load_steps": 2 + len(ldecls),
            "uid": uid,
            "script_path": SCRIPT_PATHS["LootListDefinition"],
            "ext_resources": "\n".join(ldecls),
            "properties": f'loot_entries = Array[ExtResource]({", ".join(lrefs)})'
        })
        write_tres_file(tres_path, content)
        smap["loot_ref"] = f"res://{tres_path.replace('./', '')}"

    if sp.get("locations"):
        refs = []
        for i, ld in enumerate(sp["locations"]):
            p, u = generate_level_task_entry_tres(ld, out, f"{lid}_loc_{i}")
            smap[f"loc_{i}_p"] = p
            refs.append(p)
        smap["location_paths"] = refs

def generate_level_loot_entry_tres(data, out, lid):
    p = os.path.join(out, f"loot_entry_{lid}.tres").replace(os.sep, '/')
    uid = generate_deterministic_uid(p)
    ext = f'[ext_resource type="Resource" path="{data["item_resource_path"]}" id="2_item"]'
    props = [
        f'coord = {gd_variant_to_tres(data["coord"])}',
        'items = Array[ExtResource]([ExtResource("2_item")])'
    ]
    content = fill_template("standard", {
        "script_class": "LevelLootEntry",
        "load_steps": 3,
        "uid": uid,
        "script_path": SCRIPT_PATHS["LevelLootEntry"],
        "ext_resources": ext,
        "properties": "\n".join(props)
    })
    write_tres_file(p, content)
    return f"res://{p.replace('./', '')}", uid

def generate_level_task_entry_tres(data, out, lid):
    p = os.path.join(out, f"location_{lid}.tres").replace(os.sep, '/')
    uid = generate_deterministic_uid(p)
    ext = f'[ext_resource type="PackedScene" path="{data["location_scene_path"]}" id="2_scene"]'
    props = [
        f'coord = {gd_variant_to_tres(data["coord"])}',
        'location_scene = ExtResource("2_scene")'
    ]
    content = fill_template("standard", {
        "script_class": "LevelTaskEntry",
        "load_steps": 3,
        "uid": uid,
        "script_path": SCRIPT_PATHS["LevelTaskEntry"],
        "ext_resources": ext,
        "properties": "\n".join(props)
    })
    write_tres_file(p, content)
    return f"res://{p.replace('./', '')}", uid

def generate_level_dialogue_entry_tres(data, out, lid):
    p = os.path.join(out, f"diag_{lid}.tres").replace(os.sep, '/')
    uid = generate_deterministic_uid(p)
    props = []
    for k, v in data.items():
        if k in ["id", "initiator_name", "partner_name", "group_id"]: props.append(f'{k} = &"{v}"')
        elif k == "partner_faction": props.append(f'{k} = {ENUM_VALUES["UnitFaction"].get(v, 0)}')
        else: props.append(f'{k} = {gd_variant_to_tres(v)}')

    content = fill_template("standard", {
        "script_class": "LevelDialogueEntry",
        "load_steps": 2,
        "uid": uid,
        "script_path": SCRIPT_PATHS["LevelDialogueEntry"],
        "ext_resources": "",
        "properties": "\n".join(props)
    })
    write_tres_file(p, content)
    return f"res://{p.replace('./', '')}", uid

def generate_objective_tres(data, out, lid, smap):
    p = os.path.join(out, f"objective_{lid}.tres").replace(os.sep, '/')
    uid = generate_deterministic_uid(p)
    sdecls, srefs = [], []
    for s_def in data.get("stages", []):
        path, _ = generate_stage_tres_pass1(s_def, out, lid, smap)
        rid = f"stage_{s_def['id']}"
        sdecls.append(f'[ext_resource type="Resource" path="{path}" id="{rid}"]')
        srefs.append(f'ExtResource("{rid}")')

    props = []
    for k, v in data.items():
        if k == "id": props.append(f'id = &"{v}"')
        elif k == "stages": props.append(f'stages = Array[ExtResource]({", ".join(srefs)})')
        else: props.append(f'{k} = {gd_variant_to_tres(v)}')

    content = fill_template("standard", {
        "script_class": "Objective",
        "load_steps": 2 + len(sdecls),
        "uid": uid,
        "script_path": SCRIPT_PATHS["Objective"],
        "ext_resources": "\n".join(sdecls),
        "properties": "\n".join(props)
    })

    write_tres_file(p, content)
    smap["objective_p"] = f"res://{p.replace('./', '')}"
    return smap["objective_p"], uid

def generate_level_tres(data, out):
    lid = data["level_id"]
    p = os.path.join(out, f"{lid}.tres").replace(os.sep, '/')
    uid = generate_deterministic_uid(p)
    smap = {}

    obj_p, _ = generate_objective_tres(data["objective"], out, lid, smap)
    _generate_terrain(data, out, lid, smap)
    _generate_rosters(data, out, lid, smap)
    _generate_custom_spawns(data, out, lid, smap)

    # Independent resources
    for entry in data.get("journal_entries", []): generate_journal_entry_tres(entry, out)

    diags = []
    for i, d in enumerate(data.get("dialogue_triggers", [])):
        dp, _ = generate_level_dialogue_entry_tres(d, out, f"{lid}_{i}")
        diags.append(dp)

    for sd in data["objective"].get("stages", []): _resolve_stage_references(sd, out, lid)

    exts = [f'[ext_resource type="Resource" path="{obj_p}" id="obj"]']
    ctx = {
        "uid": uid,
        "script_path": SCRIPT_PATHS["Level"],
        "display_name": gd_variant_to_tres(data["display_name"]),
        "objective_ref": 'ExtResource("obj")',
        "player_starts": gd_variant_to_tres(data.get("spawns", {}).get("player_starts", [])),
        "initial_rotation": gd_variant_to_tres(data.get("initial_rotation", 0.0)),
        "hex_offset_axis": gd_variant_to_tres(data.get("hex_offset_axis", 1))
    }

    if smap.get("terrain_ref"):
        exts.append(f'[ext_resource type="Resource" path="{smap["terrain_ref"]}" id="terrain"]')
        ctx["terrain_data_ref"] = 'terrain_data = ExtResource("terrain")'
    if smap.get("enemy_roster_ref"):
        exts.append(f'[ext_resource type="Resource" path="{smap["enemy_roster_ref"]}" id="erost"]')
        ctx["enemy_roster_ref"] = 'enemy_roster_definition = ExtResource("erost")'
    if smap.get("neutral_roster_ref"):
        exts.append(f'[ext_resource type="Resource" path="{smap["neutral_roster_ref"]}" id="nrost"]')
        ctx["neutral_roster_ref"] = 'neutral_roster_definition = ExtResource("nrost")'
    if smap.get("loot_ref"):
        exts.append(f'[ext_resource type="Resource" path="{smap["loot_ref"]}" id="loot"]')
        ctx["loot_list_ref"] = 'loot_list_definition = ExtResource("loot")'

    loc_refs = []
    for i, lp in enumerate(smap.get("location_paths", [])):
        rid = f"loc_{i}"
        exts.append(f'[ext_resource type="Resource" path="{lp}" id="{rid}"]')
        loc_refs.append(f'ExtResource("{rid}")')
    if loc_refs: ctx["locations"] = f'locations = Array[ExtResource]({", ".join(loc_refs)})'

    diag_refs = []
    for i, dp in enumerate(diags):
        rid = f"diag_{i}"
        exts.append(f'[ext_resource type="Resource" path="{dp}" id="{rid}"]')
        diag_refs.append(f'ExtResource("{rid}")')
    if diag_refs: ctx["dialogues"] = f'dialogue_entries = Array[ExtResource]({", ".join(diag_refs)})'

    ctx["load_steps"] = 1 + len(exts) + 1
    ctx["ext_resources"] = "\n".join(exts)

    content = fill_template("level", ctx)
    write_tres_file(p, content)
    return p

def convert_json_to_tres(json_path, out_base=DEFAULT_OUTPUT_BASE_DIR):
    global _generated_stage_paths
    _generated_stage_paths = {}
    try:
        with open(json_path, "r", encoding="utf-8") as f: data = json.load(f)
        validate_level_data(data)
        lid = data["level_id"]
        out_dir = os.path.join(out_base.replace("res://", "./"), lid).replace(os.sep, '/')
        os.makedirs(out_dir, exist_ok=True)
        logger.info(f"Converting level: {lid}")
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
