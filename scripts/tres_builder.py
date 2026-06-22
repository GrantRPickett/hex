import hashlib
import os

class TresBuilder:
	def __init__(self, script_paths, generic_unit_scene, generic_location_scene, generic_loot_scene, fs_path_func):
		self.load_steps = 1 # Start at 1 for the main resource
		self.ext_resources = [] # (path, type, id)
		self.sub_resources = [] # (content, type, id)
		self.sub_resource_props = {} # id -> properties
		self.next_ext_id_counter = 1
		self.next_sub_id_counter = 1
		self.script_paths = script_paths
		self.generic_unit_scene = generic_unit_scene
		self.generic_location_scene = generic_location_scene
		self.generic_loot_scene = generic_loot_scene
		self.fs_path_func = fs_path_func
		self.conversion_warnings = []

	def gd_variant_to_tres(self, value, is_string_name=False, inner_type_hint=None):
		"""Converts a Python value to its Godot .tres string representation."""
		if isinstance(value, str):
			# Check for pre-formatted Resource references
			if value.startswith("ExtResource(") or value.startswith("SubResource(") or value.startswith("&"):
				return value
			if is_string_name:
				return f'&"{value}"'
			return f'"{value}"'
		elif isinstance(value, bool):
			return str(value).lower()
		elif isinstance(value, (int, float)):
			return str(value)
		elif isinstance(value, list):
			# Type inference if no hint provided
			inner_type = inner_type_hint or "Variant"

			# Resolve script class to ExtResource if necessary
			if inner_type_hint in self.script_paths:
				script_path = self.script_paths[inner_type_hint]
				rid = self.add_ext_resource(script_path, "Script")
				if rid:
					inner_type = f'ExtResource("{rid}")'

			if not inner_type_hint and len(value) > 0:
				if isinstance(value[0], dict) and "x" in value[0] and "y" in value[0]:
					inner_type = "Vector2i"
				elif str(value[0]).startswith("ExtResource") or str(value[0]).startswith("SubResource"):
					inner_type = "Resource"
				elif isinstance(value[0], str):
					inner_type = "String"
				elif isinstance(value[0], int):
					inner_type = "int"

			items = [self.gd_variant_to_tres(item) for item in value]
			# Clean up already formatted items (like ExtResource("..."))
			clean_items = []
			for item in items:
				if item.startswith('"') and item.endswith('"') and (item[1:-1].startswith("ExtResource") or item[1:-1].startswith("SubResource")):
					clean_items.append(item[1:-1]) # Remove quotes from pre-formatted resources
				else:
					clean_items.append(item)

			if inner_type == "Variant":
				return f"[{', '.join(clean_items)}]"
			return f'Array[{inner_type}]([{ ", ".join(clean_items) }])'
		elif isinstance(value, dict):
			if "x" in value and "y" in value and len(value) == 2:
				x = value["x"]
				y = value["y"]
				return f'Vector2i({x}, {y})'
			items = [f"{self.gd_variant_to_tres(k, is_string_name=(k in ['id', 'topic_id', 'section_id']))}: {self.gd_variant_to_tres(v)}" for k, v in value.items()]
			return f'{{{ ", ".join(items) }}}'
		elif isinstance(value, tuple) and len(value) in [3, 4]: # Assuming Color if tuple of 3-4 floats
			return f'Color({ ", ".join(map(str, value)) })'
		return 'null' if value is None else str(value)

	def add_ext_resource(self, path: str, type_name: str) -> str:
		"""Adds an external resource and returns its ID (e.g., '1_abcd').
		Returns None if the resource is missing and no fallback is available.
		"""
		# check if already exists
		for p, t, i in self.ext_resources:
			if p == path:
				return i

		original_path = path
		local_path = self.fs_path_func(path)

		# For stage references, they might not exist yet during the conversion loop.
		# We check if the path is inside the stages directory to allow it.
		is_stage_ref = "stages/" in path and path.endswith(".tres")

		if not os.path.exists(local_path) and not path.startswith("user://") and not is_stage_ref:
			if type_name == "PackedScene":
				# Try to determine fallback based on path hints or default to location
				if "unit" in path.lower() or "enemy" in path.lower() or "npc" in path.lower():
					path = self.generic_unit_scene
				elif "loot" in path.lower() or "chest" in path.lower():
					path = self.generic_loot_scene
				else:
					path = self.generic_location_scene

				msg = f"Missing PackedScene: {original_path}. Using fallback: {path}"
				self.conversion_warnings.append(msg)
			else:
				msg = f"ExtResource missing at {local_path} (referenced as {path}). Skipping."
				self.conversion_warnings.append(msg)
				return None

		rid = f"{self.next_ext_id_counter}_{hashlib.md5(path.encode()).hexdigest()[:4]}"
		self.next_ext_id_counter += 1
		self.ext_resources.append((path, type_name, rid))
		self.load_steps += 1
		return rid

	def add_sub_resource(self, script_class: str, properties: dict, type_hints: dict = None) -> str:
		"""Adds a sub-resource and returns its ID (e.g., '1_xyzw')."""
		if type_hints is None:
			type_hints = {}
		rid = f"{self.next_sub_id_counter}_{hashlib.md5(str(properties).encode()).hexdigest()[:4]}"
		self.next_sub_id_counter += 1

		self.sub_resource_props[rid] = {
			"script_class": script_class,
			"properties": properties,
			"type_hints": type_hints
		}
		
		content = self._generate_sub_resource_content(rid)
		self.sub_resources.append([content, "Resource", rid]) # Changed to list to allow mutation
		self.load_steps += 1
		return rid

	def _generate_sub_resource_content(self, rid: str) -> str:
		data = self.sub_resource_props[rid]
		script_class = data["script_class"]
		properties = data["properties"]
		type_hints = data["type_hints"]
		
		lines = []
		lines.append(f'[sub_resource type="Resource" id="{rid}"]')

		script_path = self.script_paths.get(script_class)
		if script_path:
			script_id = self.add_ext_resource(script_path, "Script")
			if script_id:
				lines.append(f'script = ExtResource("{script_id}")')

		for k, v in properties.items():
			if isinstance(v, (list, dict)) and not v:
				continue
			hint = type_hints.get(k)
			lines.append(f'{k} = {self.gd_variant_to_tres(v, inner_type_hint=hint)}')

		return "\n".join(lines)

	def update_sub_resource_prop(self, rid: str, key: str, value) -> None:
		"""Updates a property in a sub-resource and refreshes its baked content."""
		if rid not in self.sub_resource_props:
			return
		
		self.sub_resource_props[rid]["properties"][key] = value
		new_content = self._generate_sub_resource_content(rid)
		
		# Find and update in self.sub_resources
		for i, (content, rtype, srid) in enumerate(self.sub_resources):
			if srid == rid:
				self.sub_resources[i][0] = new_content
				break

	def build_tres(self, main_script_class: str, main_properties: dict, uid: str = "", type_hints: dict = None) -> str:
		"""Generates the full .tres file content."""
		if type_hints is None:
			type_hints = {}

		# Pre-process main properties to discover any needed resources (e.g. from type_hints)
		main_res_lines = []

		# Ensure main script is added
		main_script_path = self.script_paths.get(main_script_class)
		if main_script_path:
			self.add_ext_resource(main_script_path, "Script")

		for k, v in main_properties.items():
			if isinstance(v, (list, dict)) and not v:
				continue
			hint = type_hints.get(k)
			main_res_lines.append(f'{k} = {self.gd_variant_to_tres(v, inner_type_hint=hint)}')

		lines = []
		lines.append(f'[gd_resource type="Resource" script_class="{main_script_class}" load_steps={self.load_steps} format=3 uid="{uid}"]')
		lines.append("")

		# Scripts and ExtResources
		for path, type_name, rid in self.ext_resources:
			lines.append(f'[ext_resource type="{type_name}" path="{path}" id="{rid}"]')

		lines.append("")

		# Sub Resources
		for content, _, _ in self.sub_resources:
			lines.append(content)
			lines.append("")

		# Main Resource
		lines.append('[resource]')
		# Add script ref
		if main_script_path:
			found = False
			for p, _, rid in self.ext_resources:
				if p == main_script_path:
					lines.append(f'script = ExtResource("{rid}")')
					found = True
					break

		for line in main_res_lines:
			lines.append(line)

		return "\n".join(lines)
