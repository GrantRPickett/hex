
import os
import re

unit_gd_path = r"c:\Users\grant\Documents\github\hex\Gameplay\unit.gd"
search_dir = r"c:\Users\grant\Documents\github\hex\Gameplay"

with open(unit_gd_path, 'r') as f:
	content = f.read()

# Find all function definitions in Unit.gd
funcs = re.findall(r'func\s+([a-zA-Z0-9_]+)\(', content)

# Remove internal/built-in funcs
internal_funcs = ['_ready', '_init', '_process', '_physics_process', '_input', '_unhandled_input', '_exit_tree', '_on_action_points_willpower_changed', '_collect_targets_in_range', '_die']
public_funcs = [f for f in funcs if f not in internal_funcs]

print(f"Checking {len(public_funcs)} functions for calls...")

for func in public_funcs:
	found_call = False
	call_pattern = re.compile(rf'\b{func}\s*\(')

	for root, dirs, files in os.walk(search_dir):
		for file in files:
			file_path = os.path.join(root, file)
			if file.endswith('.gd') and file_path != unit_gd_path:
				with open(file_path, 'r') as f:
					file_content = f.read()
					if call_pattern.search(file_content):
						found_call = True
						break
		if found_call:
			break

	if not found_call:
		# Check if used in Unit.gd itself (beyond definition)
		matches = list(call_pattern.finditer(content))
		# One match is the definition 'func NAME('
		if len(matches) <= 1:
			print(f"UNUSED_FUNC: {func}")
