import logging
import json
import os
from conversion_utils import slugify as _slugify

try:
	import jsonschema
	HAS_JSONSCHEMA = True
except ImportError:
	HAS_JSONSCHEMA = False

logger = logging.getLogger(__name__)

def json_coord_to_godot_coord(json_coord, default_invalid_coord) -> dict:
	"""Converts a 0-based JSON coord (dict or list) to a 0-based Godot coord dict.
	The sentinel value -999 is preserved as-is."""
	if json_coord is None:
		return default_invalid_coord
	if isinstance(json_coord, list) and len(json_coord) >= 2:
		return {"x": int(json_coord[0]), "y": int(json_coord[1])}
	if isinstance(json_coord, dict):
		if "x" in json_coord and "y" in json_coord:
			return {"x": int(json_coord["x"]), "y": int(json_coord["y"])}
		if "coord" in json_coord:
			return json_coord_to_godot_coord(json_coord["coord"], default_invalid_coord)
	return default_invalid_coord

class LevelValidator:
	def __init__(self, default_invalid_coord, file_paths_helper=None):
		self.default_invalid_coord = default_invalid_coord
		self.conversion_warnings = []
		
		# Load impassable codes from config or use default fallback
		self.impassable_codes = {"2", "3", "R", "W", "4"}
		if file_paths_helper:
			codes = file_paths_helper.get_path("resources.level_data.terrain_codes.impassable")
			if codes:
				self.impassable_codes = set(codes)

	def validate_level_data(self, data: dict):
		"""Deep validation of level JSON structure using schema and custom rules."""
		schema_path = os.path.join(os.path.dirname(__file__), "level_schema.json")
		if HAS_JSONSCHEMA and os.path.exists(schema_path):
			try:
				with open(schema_path, "r", encoding="utf-8") as f:
					schema = json.load(f)
				jsonschema.validate(instance=data, schema=schema)
			except Exception as e:
				raise ValueError(f"JSON validation failed: {e}")
		else:
			if not HAS_JSONSCHEMA:
				logger.warning("jsonschema library not found. Falling back to basic validation.")
			else:
				logger.warning("level_schema.json not found, skipping schema validation.")
			required_root = ["level_id", "display_name", "objective"]
			for key in required_root:
				if key not in data:
					raise ValueError(f"Missing required root key: '{key}'")
			
			obj = data["objective"]
			if "stages" not in obj:
				raise ValueError("Objective must have 'stages'")

		obj = data["objective"]
		s_ids = set()
		for i, stage in enumerate(obj["stages"]):
			if "id" not in stage:
				raise ValueError(f"Stage at index {i} is missing 'id'")
			if stage["id"] in s_ids:
				raise ValueError(f"Duplicate stage ID: {stage['id']}")
			s_ids.add(stage["id"])

			# Check coordinates in stage
			for group in ["enemy_spawns", "neutral_spawns", "loot_spawns", "location_spawns", "dialogue_entries"]:
				for entry in stage.get(group, []):
					if "coord" in entry:
						c = json_coord_to_godot_coord(entry["coord"], self.default_invalid_coord)
						if c["x"] < 0 or c["y"] < 0:
							if c["x"] != -999:
								logger.warning(f"Negative coordinate found in {group} of stage {stage['id']}: {c}. [Fix: Use 0-based coordinates (e.g., {{'x': 5, 'y': 2}})]")

		# Check player starts
		for start in (data.get("player_starts") or []):
			if isinstance(start, dict):
				if start.get("x", 0) < 0 or start.get("y", 0) < 0:
					logger.warning(f"Negative coordinate found in player_starts: {start}. [Fix: Use 0-based coordinates (e.g., {{'x': 5, 'y': 2}})]")

	def validate_connectivity(self, data: dict):
		"""
		Verifies that all points of interest (starts, spawns, targets) are reachable
		from the primary player start given the terrain layout.
		"""
		if "terrain" not in data:
			return

		t_data = data["terrain"]
		if isinstance(t_data, list):
			rows = t_data
			width = len(rows[0]) if rows else 0
			height = len(rows)
		else:
			rows = t_data.get("rows", [])
			width = t_data.get("grid_width", 7)
			height = t_data.get("grid_height", 7)

		axis = data.get("hex_offset_axis", 1)  # Default: Vertical/Flat-top

		# Impassable codes (synchronized with TerrainMap.gd and terrain scripts via file_paths)
		impassable_codes = self.impassable_codes

		player_starts = data.get("player_starts", [])
		if not player_starts:
			return

		# Collect all POIs (0-based coordinates from JSON)
		pois = []
		for ps in player_starts:
			if isinstance(ps, dict):
				pois.append(ps.get("coord") or ps)
			else:
				pois.append(ps)

		for stage in data.get("objective", {}).get("stages", []):
			for group in ["enemy_spawns", "neutral_spawns", "loot_spawns", "location_spawns"]:
				for entry in stage.get(group, []):
					if "coord" in entry:
						pois.append(entry["coord"])
			for task in stage.get("tasks", []):
				if "target_coord" in task:
					pois.append(task["target_coord"])

		if not pois:
			return

		# Start BFS from first player start
		start = json_coord_to_godot_coord(pois[0], self.default_invalid_coord)
		sx, sy = start["x"], start["y"]
		if sx == -999:
			return

		if sy >= len(rows) or sx >= len(rows[sy]):
			logger.warning(f"[Connectivity] Primary player start ({sx}, {sy}) is out of bounds.")
			return

		if rows[sy][sx] in impassable_codes:
			msg = f"[Connectivity] Primary player start at ({sx}, {sy}) is on impassable terrain '{rows[sy][sx]}'. [Fix: Move player start to a passable tile (e.g., '.'), or change the tile code in the terrain grid]"
			logger.warning(msg)
			self.conversion_warnings.append(msg)
			return

		reachable = set()
		queue = [(sx, sy)]
		reachable.add((sx, sy))

		while queue:
			cx, cy = queue.pop(0)

			# Hex neighbors
			if axis == 1:  # Vertical / Flat-top / Odd-column stagger
				# In 1-based logic, col 1 is odd. In 0-based, cx=0 is col 1.
				if (cx + 1) % 2 != 0:
					offsets = [(0, -1), (1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0)]
				else:
					offsets = [(0, -1), (1, -1), (1, 0), (0, 1), (-1, 0), (-1, -1)]
			else:  # Horizontal / Pointy-top / Odd-row stagger
				if (cy + 1) % 2 != 0:
					offsets = [(1, 0), (1, -1), (0, -1), (-1, 0), (0, 1), (1, 1)]
				else:
					offsets = [(1, 0), (0, -1), (-1, -1), (-1, 0), (-1, 1), (0, 1)]

			for dx, dy in offsets:
				nx, ny = cx + dx, cy + dy
				if 0 <= ny < len(rows) and 0 <= nx < len(rows[ny]):
					if (nx, ny) not in reachable and rows[ny][nx] not in impassable_codes:
						reachable.add((nx, ny))
						queue.append((nx, ny))

		# Check all POIs
		for p in pois:
			pc = json_coord_to_godot_coord(p, self.default_invalid_coord)
			px, py = pc["x"], pc["y"]
			if px == -999 or py == -999:
				continue
			if (px, py) not in reachable:
				msg = f"[Connectivity] Point of interest at ({px}, {py}) is unreachable from player start"
				logger.warning(msg)
				self.conversion_warnings.append(msg)

		return reachable

	def generate_ascii_preview(self, rows: list, pois: list, player_starts: list, reachable: set = None) -> str:
		"""
		Generates an ASCII grid representation of the terrain with POIs and player starts.
		"""
		if not rows:
			return ""

		height = len(rows)
		width = max(len(r) for r in rows)

		grid = [list(r) for r in rows]

		# Add Markers
		for p in pois:
			pc = json_coord_to_godot_coord(p, self.default_invalid_coord)
			px, py = pc["x"], pc["y"]
			if 0 <= py < height and 0 <= px < len(grid[py]):
				if reachable is not None and (px, py) not in reachable:
					grid[py][px] = "!" # Unreachable POI
				else:
					grid[py][px] = "L" # Location/POI

		for s in player_starts:
			sc = json_coord_to_godot_coord(s, self.default_invalid_coord)
			sx, sy = sc["x"], sc["y"]
			if 0 <= sy < height and 0 <= sx < len(grid[sy]):
				grid[sy][sx] = "P" # Player Start

		lines = []
		header = "   " + "".join([str(i % 10) for i in range(width)])
		lines.append(header)
		for y, row in enumerate(grid):
			line = f"{y:2} {''.join(row)}"
			lines.append(line)

		legend = "\nLegend: P=Start, L=POI, !=Unreachable POI, .=Empty, R=Ruin, W=Water"
		return "\n".join(lines) + legend

	def validate_referential_integrity(self, data: dict):
		"""
		Validates that target_ids and dialogue ids referenced in tasks/stages
		exist within the generated structures.
		"""
		spawns_and_locations = set()
		defined_dialogues = set()
		item_ids_to_check = set()

		obj = data.get("objective", {})
		stages = obj.get("stages", [])

		# 1. Collect Valid Targets & Items
		for stage in stages:
			# Collect Loot Spawns
			for loot in stage.get("loot_spawns", []):
				for it_entry in loot.get("items", []):
					if isinstance(it_entry, dict):
						item_id = it_entry.get("id") or it_entry.get("item_id")
						if item_id: item_ids_to_check.add(str(item_id))
					elif isinstance(it_entry, str):
						item_ids_to_check.add(str(it_entry))

			for group in ["enemy_spawns", "neutral_spawns", "roster_spawns", "loot_spawns"]:
				for entry in stage.get(group, []):
					if "id" in entry: spawns_and_locations.add(str(entry["id"]))
					elif "unit_name" in entry: spawns_and_locations.add(str(entry["unit_name"]))
					
			for loc in stage.get("location_spawns", []):
				if "id" in loc: spawns_and_locations.add(str(loc["id"]))
				elif "location_name" in loc: spawns_and_locations.add(str(loc["location_name"]))

			# Check reward items
			for task in stage.get("tasks", []):
				rr = task.get("reward_resource", {})
				rt = rr.get("reward_type", "ITEM")
				rv = rr.get("reward_value")
				if rt == "ITEM" and rv:
					item_ids_to_check.add(str(rv))

			# Collect Stage-Level Dialogues
			for entry in stage.get("dialogue_entries", []) + stage.get("dialogue_journal_entries", []):
				eid = entry.get("entry_id") or entry.get("id")
				if eid: defined_dialogues.add(str(eid))

		# Global Dialogues
		for entry in data.get("dialogue_entries", []) + data.get("dialogue_journal_entries", []):
			eid = entry.get("entry_id") or entry.get("id")
			if eid: defined_dialogues.add(str(eid))

		# If there are global defined targets or roster, we can add them here
		for r in data.get("roster_spawns", []):
			if "id" in r: spawns_and_locations.add(str(r["id"]))
			elif "unit_name" in r: spawns_and_locations.add(str(r["unit_name"]))

		# Function to validate hooks
		def _check_hooks(source_name, hooks_dict):
			for hook_key in ["on_enter", "on_exit", "on_fail"]:
				hook_data = hooks_dict.get(hook_key)
				if not hook_data: continue
				
				d_ids = []
				if isinstance(hook_data, dict) and "dialogue_id" in hook_data:
					d_ids.append(str(hook_data["dialogue_id"]))
				elif isinstance(hook_data, str):
					d_ids.append(hook_data)
				elif isinstance(hook_data, list):
					d_ids.extend([str(h) for h in hook_data if isinstance(h, str)])

				for did in d_ids:
					if did not in defined_dialogues:
						msg = f"[Reference Integrity] {source_name} references dialogue_id hook '{did}', but it is not defined in any dialogue entries."
						logger.warning(msg)
						self.conversion_warnings.append(msg)

		# 2. Check Tasks & Hooks
		for i, stage in enumerate(stages):
			stage_name = f"Stage '{stage.get('id', i)}'"
			_check_hooks(stage_name, stage)

			for task in stage.get("tasks", []):
				task_name = f"Task '{task.get('id', task.get('title', 'Unknown'))}'"
				target_id = task.get("target_id")
				
				# If task uses a target_id, check it exists
				if target_id and str(target_id) not in spawns_and_locations:
					# It might be an item id, but for units and locations this catches easy typos.
					# Event types like 'convince', 'attack', 'eliminate', 'interact', 'visit' rely on entity IDs.
					evt = task.get("event_type", "")
					if evt in ["convince", "attack", "eliminate", "interact", "visit", "dialogue_started", "dialogue_finished", "unit_defeated"]:
						msg = f"[Reference Integrity] {task_name} targets '{target_id}', but no spawn/location was found with that ID."
						logger.warning(msg)
						self.conversion_warnings.append(msg)

				_check_hooks(f"{stage_name} -> {task_name}", task)

		# 3. Item Validation against file system
		if item_ids_to_check:
			items_dir = os.path.join(os.path.dirname(__file__), "..", "Resources", "items")
			if os.path.exists(items_dir):
				for item_id in item_ids_to_check:
					# Allow if it's already a full path or we can find matching .tres
					if item_id.startswith("res://"):
						continue
					
					expected_file = os.path.join(items_dir, f"{item_id}.tres")
					if not os.path.exists(expected_file):
						msg = f"[Reference Integrity] Item '{item_id}' referenced in loot or rewards, but {expected_file} was not found."
						logger.warning(msg)
						self.conversion_warnings.append(msg)
				
