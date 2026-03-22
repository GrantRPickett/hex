import os
import re

project_dir = r"c:\Users\grant\Documents\github\hex"

def determine_category(file_path):
    path_lower = file_path.lower()
    
    # UI
    if 'gui' in path_lower or 'menus' in path_lower or 'ui' in os.path.basename(path_lower):
        return 'UI'
    # AI
    if 'ai_controller' in path_lower or 'ai_player' in path_lower or '\\ai\\' in path_lower:
        return 'AI'
    # TASK
    if 'tasks' in path_lower or 'journal' in path_lower or 'dialogue' in path_lower or 'quest' in path_lower:
        return 'TASK'
    # MAP
    if 'map' in path_lower or 'grid' in path_lower or 'location' in path_lower or 'pathfinding' in path_lower or 'level' in path_lower:
        return 'MAP'
    # COMBAT
    if 'combat' in path_lower or 'action' in path_lower or 'skill' in path_lower or 'target' in path_lower or 'unit' in path_lower:
        return 'COMBAT'
        
    return 'SYSTEM'

count = 0
for root, dirs, files in os.walk(project_dir):
    if 'addons' in root or '.git' in root or '.godot' in root:
        continue
    for file in files:
        if file.endswith('.gd') and file != 'game_logger.gd':
            file_path = os.path.join(root, file)
            cat = determine_category(file_path)
            
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Only update if it's currently SYSTEM and should be something else
            # OR if we want to replace ANY GameLogger.Category.* back to the correct one
            # We'll just replace GameLogger.Category.SYSTEM for now
            if cat != 'SYSTEM':
                new_content = re.sub(r'GameLogger\.Category\.SYSTEM', f'GameLogger.Category.{cat}', content)
                
                if new_content != content:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"[{cat}] Updated {os.path.basename(file_path)}")
                    count += 1

print(f"\nCategorization complete! Updated {count} files.")
