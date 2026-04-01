import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    # Replace MOVE_ACTION with MOVE first to avoid ActionType.MOVE_ACTION which doesn't exist
    content = content.replace("GameConstants.Commands.CommandID.MOVE_ACTION", "GameConstants.ActionType.MOVE")
    # Replace all other specific CommandID values
    content = re.sub(r"GameConstants\.Commands\.CommandID\.([A-Z_]+)", r"GameConstants.ActionType.\1", content)
    # Replace the type hints
    content = content.replace("GameConstants.Commands.CommandID", "GameConstants.ActionType")

    if original != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

def main():
    repo_dir = r"c:\Users\grant\Documents\github\hex"
    for root, dirs, files in os.walk(repo_dir):
        # skip .git or .godot
        if '.git' in root or '.godot' in root or 'tmp' in root:
            continue
        for file in files:
            if file.endswith('.gd'):
                process_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
