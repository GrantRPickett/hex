import os
import re

def patch_file():
    path = r'c:\Users\grant\Documents\github\hex\json_to_tres.py'
    if not os.path.exists(path):
        print(f"Error: {path} does not exist.")
        return

    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    new_lines = []
    in_spawn_func = False
    in_stage_func = False

    for line in lines:
        # Flatten paths on the fly
        line = line.replace('os.path.join(output_dir, "stages", tres_file_name)', 'os.path.join(output_dir, tres_file_name)')
        line = line.replace('os.path.join(output_dir, "objectives", tres_file_name)', 'os.path.join(output_dir, tres_file_name)')
        line = line.replace('os.path.join(output_dir, "levels", f"{level_id}.tres")', 'os.path.join(output_dir, f"{level_id}.tres")')
        line = line.replace('os.path.join(output_dir, "stages", f"stage_{level_id}_{stage_id}.tres")', 'os.path.join(output_dir, f"stage_{level_id}_{stage_id}.tres")')
        line = line.replace('os.path.join(output_dir, "objectives", f"objective_{level_id}_{objective_id}.tres")', 'os.path.join(output_dir, f"objective_{level_id}_{objective_id}.tres")')

        # Remove relative_path_prefix
        line = re.sub(r', relative_path_prefix="[^"]+"', '', line)

        # Remove subdir creation
        if 'os.makedirs(os.path.join(output_dir, "' in line:
            continue

        # Fix generate_stage_spawn_entry_tres indentation
        if 'def generate_stage_spawn_entry_tres' in line:
            in_spawn_func = True
            new_lines.append(line)
            continue

        if in_spawn_func:
            if line.startswith('def ') or line.startswith('# ---'):
                # Function ended, add except block
                new_lines.append('    except Exception as e:\n')
                new_lines.append('        logger.warning(f"Failed to generate spawn entry: {e}")\n')
                new_lines.append('        return None, None\n\n')
                in_spawn_func = False
                new_lines.append(line)
                continue

            # Indent lines that aren't already indented within try
            if line.strip() and not line.startswith('    try:') and not line.startswith('        '):
                 new_lines.append('    ' + line)
            else:
                 new_lines.append(line)
            continue

        new_lines.append(line)

    with open(path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print("Patch applied.")

if __name__ == "__main__":
    patch_file()
