import os
import re

def migrate_tscn(file_path):
	with open(file_path, 'r', encoding='utf-8') as f:
		content = f.read()

	# Identify the UnitAttributes script resource ID
	script_match = re.search(r'\[ext_resource type="Script" [^\]]*path="res://Gameplay/targets/unit_attributes\.gd" id="([^"]+)"\]', content)

	if script_match:
		script_id = script_match.group(1)
		# Remove the ext_resource line
		content = re.sub(rf'\[ext_resource type="Script" [^\]]*path="res://Gameplay/targets/unit_attributes\.gd" id="{script_id}"\]\n', '', content)

		# Remove the UnitAttributes node that uses this script
		# [node name="UnitAttributes" type="Node" parent="." unique_id=...]
		# script = ExtResource("script_id")
		node_pattern = rf'\[node name="UnitAttributes" type="Node" parent="\." unique_id=\d+\]\nscript = ExtResource\("{script_id}"\)\n'
		content = re.sub(node_pattern, '', content)

		# Also handle cases where it might have base_values or other properties
		node_pattern_props = rf'\[node name="UnitAttributes" type="Node" parent="\." unique_id=\d+\]\nscript = ExtResource\("{script_id}"\)\n(?:[a-z_]+ = [^\n]+\n)*'
		content = re.sub(node_pattern_props, '', content)

	# Final cleanup of any lingering mentions (like in Resources/characters/core/monk.tscn example)
	content = re.sub(r'\[node name="UnitAttributes"[^\]]*\]\nscript = ExtResource\("2_unit_attributes_script"\)\n', '', content)
	content = re.sub(r'\[ext_resource type="Script" [^\]]*path="res://Gameplay/targets/unit_attributes\.gd" id="2_unit_attributes_script"\]\n', '', content)

	with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
		f.write(content)
	print(f"Cleaned up {file_path}")

core_chars_dir = "Resources/characters/core"
for f in os.listdir(core_chars_dir):
	if f.endswith(".tscn"):
		migrate_tscn(os.path.join(core_chars_dir, f))
