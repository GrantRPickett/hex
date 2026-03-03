import os
import re

def get_line_count(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return sum(1 for _ in f)
    except:
        return 0

def get_functions(filepath):
    funcs = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            current_func = None
            func_start = 0
            for i, line in enumerate(lines):
                match = re.match(r'func\s+(\w+)', line.strip())
                if match:
                    if current_func:
                        funcs.append((current_func, i - func_start, func_start + 1, i))
                    current_func = match.group(1)
                    func_start = i
            if current_func:
                funcs.append((current_func, len(lines) - func_start, func_start + 1, len(lines)))
    except:
        pass
    return funcs

all_files = []
for root, dirs, files in os.walk('.'):
    if '.godot' in root or '.git' in root or 'addons' in root:
        continue
    for file in files:
        if file.endswith('.gd'):
            fullpath = os.path.join(root, file)
            line_count = get_line_count(fullpath)
            all_files.append((fullpath, line_count))

all_files.sort(key=lambda x: x[1], reverse=True)

print("TOP 20 LONG FILES:")
for path, count in all_files[:20]:
    print(f"{count:4} : {path}")

all_funcs = []
for path, count in all_files:
    funcs = get_functions(path)
    for name, length, start, end in funcs:
        all_funcs.append((path, name, length, start, end))

all_funcs.sort(key=lambda x: x[2], reverse=True)

print("\nTOP 20 LONG FUNCTIONS:")
for path, name, length, start, end in all_funcs[:20]:
    print(f"{length:4} : {path} -> {name} ({start}-{end})")
