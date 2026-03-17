import logging
from conversion_utils import slugify as _slugify

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
	def __init__(self, default_invalid_coord):
		self.default_invalid_coord = default_invalid_coord
		self.conversion_warnings = []

	def validate_level_data(self, data: dict):
		"""Deep validation of level JSON structure."""
		required_root = ["level_id", "display_name", "objective"]
		for key in required_root:
			if key not in data:
				raise ValueError(f"Missing required root key: '{key}'")

		obj = data["objective"]
		if "stages" not in obj:
			raise ValueError("Objective must have 'stages'")

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

		# Impassable codes (synchronized with TerrainMap.gd and terrain scripts)
		# 2: Waterfall, 3: Lava, R: River, W: Wall, 4: Mountain Peak
		impassable_codes = {"2", "3", "R", "W", "4"}

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
