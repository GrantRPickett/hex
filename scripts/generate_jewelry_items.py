import json
import os
import re

def slugify(text):
    return re.sub(r'[^a-zA-Z0-9_]', '_', text.lower()).strip('_')

def generate():
    # Adjusted paths for project root execution
    map_path = 'Resources/item_adjective_map.json'
    output_dir = 'Resources/items/jewelry'
    script_path = 'res://Resources/items/item_template.gd'
    
    if not os.path.exists(map_path):
        print(f"Error: Could not find {map_path}")
        return

    with open(map_path, 'r') as f:
        data = json.load(f)
    
    adjectives = data['item_adjectives']
    # 15 distinct, symbolically-matched jewelry nouns (Recognizable versions)
    terms = [
        "Cameo",      # 1: shine_shade -> Twilight Cameo
        "Brooch",     # 2: shine_grit -> Burnished Brooch
        "Pendant",    # 3: shine_flow -> Scintillating Pendant
        "Diadem",     # 4: shine_gusto -> Resplendent Diadem
        "Gem",        # 5: shine_focus -> Lucid Gem
        "Collar",     # 6: shade_grit -> Grim Collar
        "Choker",     # 7: shade_flow -> Veiled Choker
        "Locket",     # 8: shade_gusto -> Ominous Locket
        "Signet",     # 9: shade_focus -> Subtle Signet
        "Bracelet",   # 10: grit_flow -> Sinuous Bracelet
        "Cuff",       # 11: grit_gusto -> Stalwart Cuff
        "Amulet",     # 12: grit_focus -> Tempered Amulet
        "Talisman",   # 13: flow_gusto -> Buoyant Talisman
        "Vial",       # 14: flow_focus -> Serene Vial
        "Ring"         # 15: gusto_focus -> Fervent Ring
    ]
    
    os.makedirs(output_dir, exist_ok=True)
    
    pair_list = list(adjectives.items())
    
    for i in range(len(pair_list)):
        pair, adj = pair_list[i]
        term = terms[i]
        
        item_name = f"{adj.capitalize()} {term}"
        # We use the pair in the ID to keep it distinct
        item_id = slugify(f"{adj}_{term}")
        
        attr_parts = pair.split('_')
        # Handle cases where multiple underscores might exist (unlikely here but safe)
        attr1 = attr_parts[0]
        attr2 = attr_parts[1]
        
        tres_content = f'''[gd_resource type="Resource" script_class="ItemTemplate" format=3]

[ext_resource type="Script" path="{script_path}" id="1_template_script"]

[resource]
script = ExtResource("1_template_script")
item_id = "{item_id}"
item_name = "{item_name}"
description = "A {item_name.lower()} imbued with the essence of {attr1} and {attr2}."
attribute_modifiers = {{
"{attr1}": 1,
"{attr2}": 1
}}
quest_item = false
value = 50
'''
        file_path = os.path.join(output_dir, f"{item_id}.tres")
        with open(file_path, 'w') as f:
            f.write(tres_content)
        print(f"Generated {file_path}")

if __name__ == "__main__":
    generate()
