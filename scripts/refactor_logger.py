import os
import re

directories = ['Autoloads', 'Gameplay', 'Menus', 'GUI', 'tests', 'Resources', 'level']
project_dir = r"c:\Users\grant\Documents\github\hex"

replacements = [
    (re.compile(r'\bprint\('), r'GameLogger.info(GameLogger.Category.SYSTEM, '),
    (re.compile(r'\bprint_debug\('), r'GameLogger.debug(GameLogger.Category.SYSTEM, '),
    (re.compile(r'\bprinterr\('), r'GameLogger.error(GameLogger.Category.SYSTEM, '),
    (re.compile(r'\bpush_error\('), r'GameLogger.error(GameLogger.Category.SYSTEM, '),
    (re.compile(r'\bpush_warning\('), r'GameLogger.warning(GameLogger.Category.SYSTEM, ')
]

# Exclude the logger itself
exclude_files = ['game_logger.gd']

for dir_name in directories:
    dir_path = os.path.join(project_dir, dir_name)
    if not os.path.exists(dir_path):
        continue
    for root, dirs, files in os.walk(dir_path):
        for file in files:
            if not file.endswith('.gd'):
                continue
            if file in exclude_files:
                continue
                
            file_path = os.path.join(root, file)
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = content
            for regex, repl in replacements:
                new_content = regex.sub(repl, new_content)
                
            if new_content != content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Refactored {file_path}")

print("Refactoring complete.")
