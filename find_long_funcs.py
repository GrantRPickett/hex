
import re
import os

def find_long_functions(file_path, threshold=50):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    functions = []
    current_func = None

    for i, line in enumerate(lines):
        match = re.match(r'^func\s+([a-zA-Z0-9_]+)', line)
        if match:
            if current_func:
                current_func['end'] = i
                functions.append(current_func)
            current_func = {'name': match.group(1), 'start': i + 1}
        elif current_func and (line.strip() == "" or line.startswith("\t") or line.startswith(" ")):
            # Still inside a function (roughly)
            pass
        elif current_func and not line.strip().startswith("#"):
            # New block started that isn't a function but might be at root level
            # GDScript use indentation, so if it's not indented and not a function, it's outside.
            if not line.startswith("\t") and not line.startswith("    ") and line.strip() != "":
                 current_func['end'] = i
                 functions.append(current_func)
                 current_func = None

    if current_func:
        current_func['end'] = len(lines)
        functions.append(current_func)

    long_funcs = []
    for f in functions:
        length = f['end'] - f['start']
        if length > threshold:
            long_funcs.append((f['name'], length, f['start']))

    return long_funcs

target_files = [
    r"c:\Users\grant\Documents\github\hex\Gameplay\ai_controller.gd",
    r"c:\Users\grant\Documents\github\hex\Gameplay\gameplay.gd",
    r"c:\Users\grant\Documents\github\hex\Gameplay\goal_manager.gd",
    r"c:\Users\grant\Documents\github\hex\Gameplay\hud_controller.gd",
    r"c:\Users\grant\Documents\github\hex\Gameplay\level_builder.gd",
    r"c:\Users\grant\Documents\github\hex\Gameplay\level_manager_gameplay.gd",
    r"c:\Users\grant\Documents\github\hex\Gameplay\turn_controller.gd",
    r"c:\Users\grant\Documents\github\hex\Gameplay\unit.gd"
]

for file_path in target_files:
    if os.path.exists(file_path):
        print(f"File: {file_path}")
        longs = find_long_functions(file_path)
        for name, length, start in longs:
            print(f"  {name}: {length} lines (starting at line {start})")
