import json
import os

def merge_data(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    unit_data = data.get('unit_data', [])
    loot_data = data.get('loot_data', [])
    
    if not data.get('objective') or not data['objective'].get('stages'):
        print("No stages found to merge into.")
        return

    first_stage = data['objective']['stages'][0]
    
    if 'neutral_spawns' not in first_stage:
        first_stage['neutral_spawns'] = []
    if 'loot_spawns' not in first_stage:
        first_stage['loot_spawns'] = []
        
    for unit in unit_data:
        if unit.get('faction') == 'NEUTRAL':
            # Convert [q, r] to x, y if needed, but generator already uses col, row for unit_data
            first_stage['neutral_spawns'].append(unit)
        else:
            if 'enemy_spawns' not in first_stage:
                first_stage['enemy_spawns'] = []
            first_stage['enemy_spawns'].append(unit)
            
    for loot in loot_data:
        first_stage['loot_spawns'].append(loot)
        
    # Clear root data to avoid confusion
    data['unit_data'] = []
    data['loot_data'] = []
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4)
    print(f"Merged {len(unit_data)} units and {len(loot_data)} loot into first stage.")

if __name__ == "__main__":
    merge_data('Resources/level_data/moba_level_generated.json')
