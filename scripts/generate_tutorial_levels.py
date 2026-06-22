import json
import os

# Configuration for the 6 tutorial levels
TUTORIAL_LEVELS = [
    {
        "id": "tutorial_01",
        "name": "The Gatekeeper",
        "stat": "shine",
        "character": "healer",
        "terrain_char": "6",  # Monastery
        "weather": "shine",
        "treasure": "res://Resources/items/bronze_shine.tres",
        "task_type": "convince",
        "task_desc": "The sacred monastery is blocked by a firm guard. Use your presence to convince them to let you pass.",
        "target_kind": "unit",
        "opposed": False,
        "lore": "Sacred ground offers solace, but the gatekeeper is firm. I spoke my way through the first blockade.",
        "target_name": "Gate Guard"
    },
    {
        "id": "tutorial_02",
        "name": "The Briar Path",
        "stat": "flow",
        "character": "scout",
        "terrain_char": "V",  # Vines
        "weather": "flow",
        "treasure": "res://Resources/items/bronze_flow.tres",
        "task_type": "visit",
        "task_desc": "The path is choked with thick vines. Reach the Ancient Well at the far end of the forest.",
        "target_kind": "location",
        "opposed": False,
        "lore": "These woods are thick, but I am swifter than the briars. Speed was my only hope.",
        "target_name": "Ancient Well"
    },
    {
        "id": "tutorial_03",
        "name": "The Sinking Cache",
        "stat": "gusto",
        "character": "monk",
        "terrain_char": "M",  # Mud
        "weather": "gusto",
        "treasure": "res://Resources/items/bronze_gusto.tres",
        "task_type": "gather",
        "task_desc": "The swamp is deep and clinging. Push through the mud to recover the hidden supplies.",
        "target_kind": "loot",
        "opposed": False,
        "lore": "The swamp clings to the weak, but my resolve is iron. I find strength in the struggle.",
        "target_name": "Hidden Cache"
    },
    {
        "id": "tutorial_04",
        "name": "The Shadowed Ruins",
        "stat": "shade",
        "character": "assassin",
        "terrain_char": "N",  # Ruins
        "weather": "shade",
        "treasure": "res://Resources/items/bronze_shade.tres",
        "task_type": "explore",
        "task_desc": "Spirits haunt these cold ruins. Move through the shadows to investigate the haunted pit.",
        "target_kind": "location",
        "opposed": True,
        "lore": "A shadow in the ruins is never truly alone. Old spirits guarded the stone, but I moved unseen.",
        "target_name": "Haunted Pit"
    },
    {
        "id": "tutorial_05",
        "name": "The Outpost",
        "stat": "grit",
        "character": "berserker",
        "terrain_char": "F",  # Fort
        "weather": "grit",
        "treasure": "res://Resources/items/bronze_grit.tres",
        "task_type": "eliminate",
        "task_desc": "A bandit has taken over this fort. Break through their defenses and deliver your message.",
        "target_kind": "unit",
        "opposed": True,
        "lore": "Stone walls will not stop my rage. Some messages are only delivered with steel.",
        "target_name": "Bandit Leader"
    },
    {
        "id": "tutorial_06",
        "name": "The Frozen Vault",
        "stat": "focus",
        "character": "duelist",
        "terrain_char": "I",  # Ice
        "weather": "focus",
        "treasure": "res://Resources/items/bronze_focus.tres",
        "task_type": "eliminate",
        "task_desc": "The iron vault is locked by ancient machinery. Use your focus to find the critical weakness and break it open.",
        "target_kind": "location",
        "opposed": True,
        "lore": "In the cold calculation of battle, I am the edge. The vault yielded its secrets to my focus.",
        "target_name": "Iron Vault"
    }
]

OUTPUT_DIR = "Resources/level_data/tutorial"

def generate():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    for data in TUTORIAL_LEVELS:
        level_id = data["id"]
        
        # Terrain Layout: 7x5
        # GGGXGGG
        # GGGXGGG
        # GGGGGGG (Gap at y=2)
        # GGGXGGG
        # GGGXGGG
        terrain_char = data["terrain_char"]
        rows = [
            f"GGG{terrain_char}GGG",
            f"GGG{terrain_char}GGG",
            "GGGGGGG",
            f"GGG{terrain_char}GGG",
            f"GGG{terrain_char}GGG"
        ]

        level = {
            "level_id": level_id,
            "display_name": data["name"],
            "starting_weather": data["weather"],
            "terrain": {
                "grid_width": 7,
                "grid_height": 5,
                "rows": rows
            },
            "player_starts": [
                {
                    "x": 0,
                    "y": 2,
                    "unit_scene_path": f"res://Resources/characters/core/{data['character']}.tscn",
                    "faction": "PLAYER"
                }
            ],
            "objective": {
                "id": f"obj_{level_id}",
                "title": data["name"],
                "stages": [
                    {
                        "id": "stage_1",
                        "tasks": [],
                        "enemy_spawns": [],
                        "neutral_spawns": [],
                        "location_spawns": [],
                        "loot_spawns": [],
                        "dialogue_journal_entries": []
                    }
                ]
            }
        }
        
        stage = level["objective"]["stages"][0]
        
        # Primary Task
        task = {
            "id": f"task_{level_id}",
            "title": f"{data['task_type'].capitalize()} {data['target_name']}",
            "description": data["task_desc"],
            "event_type": data["task_type"],
            "target_kind": data["target_kind"],
            "target_id": data["target_name"].replace(" ", ""),
        }
        stage["tasks"].append(task)
        
        # Target Spawn
        target_coord = {"x": 6, "y": 2}
        if data["target_kind"] == "unit":
            spawn = {
                "id": task["target_id"],
                "unit_name": data["target_name"],
                "faction": "ENEMY" if data["opposed"] else "NEUTRAL",
                "coord": target_coord,
                "willpower": 5 if data["opposed"] else 1
            }
            if data["opposed"]:
                stage["enemy_spawns"].append(spawn)
            else:
                stage["neutral_spawns"].append(spawn)
        elif data["target_kind"] == "location":
            spawn = {
                "id": task["target_id"],
                "location_name": data["target_name"],
                "coord": target_coord,
                "hazard": data["opposed"],
                "willpower": 5 if data["opposed"] else 1
            }
            stage["location_spawns"].append(spawn)
        elif data["target_kind"] == "loot" or data["target_kind"] == "item":
            spawn = {
                "id": task["target_id"],
                "coord": target_coord,
                "items": [data["treasure"]]
            }
            stage["loot_spawns"].append(spawn)

        # Mandatory Secondary Treasure (if not already the primary task)
        if data["target_kind"] != "loot" and data["target_kind"] != "item":
            treasure_id = f"Treasure_{level_id}"
            stage["loot_spawns"].append({
                "id": treasure_id,
                "coord": {"x": 6, "y": 4},
                "items": [data["treasure"]],
                "willpower": 1
            })
            # Also add an optional task to collect it so it shows in HUD
            stage["tasks"].append({
                "id": f"task_loot_{level_id}",
                "title": f"Collect {data['stat'].capitalize()} Treasure",
                "description": f"Gather the rewards of your {data['stat']} focus.",
                "event_type": "gather",
                "target_kind": "loot",
                "target_id": treasure_id,
                "is_optional": True
            })

        # Lore
        level["dialogue_journal_entries"] = [
            {
                "entry_id": f"lore_{level_id}",
                "title": data["name"],
                "notes": data["lore"],
                "section_id": level_id,
                "topic_id": "stage_1"
            }
        ]
        # Link lore to stage on_enter
        stage["on_enter"] = [f"lore_{level_id}"]

        output_path = os.path.join(OUTPUT_DIR, f"{level_id}.json")
        with open(output_path, "w") as f:
            json.dump(level, f, indent=2)
        print(f"Generated {output_path}")

if __name__ == "__main__":
    generate()
