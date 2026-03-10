import os
import re

def migrate_tscn(file_path):
	with open(file_path, 'r', encoding='utf-8') as f:
		content = f.read()

	# Find UnitAttributes base_values (robust regex)
	# We look for the node and then its base_values property
	base_values_match = re.search(r'\[node name="UnitAttributes"[^\]]*\].*?base_values = ({[^}]+})', content, re.DOTALL)
	if not base_values_match:
		# Check if they already have root attributes but still have the old stats resource from my previous attempt
		content = re.sub(r'\nstats = SubResource\("[^"]+"\)', '', content)
		# Remove any SubResource that uses CombatStats
		content = re.sub(r'\n\[sub_resource type="Resource" id="[^"]+"\]\nscript = ExtResource\("[^"]+"\)\n(?:grit|flow|gusto|focus|shine|shade|willpower) = [^\n]+\n(?:grit|flow|gusto|focus|shine|shade|willpower) = [^\n]+\n(?:grit|flow|gusto|focus|shine|shade|willpower) = [^\n]+\n(?:grit|flow|gusto|focus|shine|shade|willpower) = [^\n]+\n(?:grit|flow|gusto|focus|shine|shade|willpower) = [^\n]+\n(?:grit|flow|gusto|focus|shine|shade|willpower) = [^\n]+\n(?:willpower = [^\n]+\n)?', '', content)

		with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
			f.write(content)
		print(f"Cleaned up {file_path}")
		return

	base_values_str = base_values_match.group(1)
	# Parse dict: "flow": 5, "focus": 7, ...
	base_values = {}
	for pair in re.findall(r'"([^"]+)": ([\d.]+)', base_values_str):
		base_values[pair[0]] = pair[1]

	# Add attributes to root node
	# Find the root node (first node)
	root_node_match = re.search(r'(\[node name="[^"]+" type="Node2D" unique_id=[^\]]+\]\nscript = [^\n]+)', content)
	if root_node_match:
		attr_lines = ""
		for k, v in base_values.items():
			attr_lines += f'\n{k} = {v}'
		if "willpower" not in base_values:
			attr_lines += "\nbase_willpower = 10"

		content = content.replace(root_node_match.group(1), root_node_match.group(1) + attr_lines)

	# Remove base_values from UnitAttributes node
	content = content.replace(f'base_values = {base_values_str}\n', '')
	content = content.replace(f'base_values = {base_values_str}', '')

	# Also clean up stats resource if it exists from previous run
	content = re.sub(r'\nstats = SubResource\("[^"]+"\)', '', content)

	with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
		f.write(content)
	print(f"Migrated {file_path}")

core_chars_dir = "Resources/characters/core"
for f in os.listdir(core_chars_dir):
	if f.endswith(".tscn"):
		migrate_tscn(os.path.join(core_chars_dir, f))
