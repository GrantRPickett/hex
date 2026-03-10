import json
import random
import math

class HexMapGenerator:
	"""
	Generates procedural hexgrid terrain maps for the HEX project.
	Uses axial coordinate math for hex calculations.
	"""
	WATER_TERRAINS = ["river", "waterfall", "swamp", "quagmire", "river"]
	MOUNTAIN_TERRAINS = ["mountain_peak", "hill_high_ground", "stone", "ruins"]

	def __init__(self, width, height, default_terrain="grass"):
		self.width = width
		self.height = height
		self.default_terrain = default_terrain
		self.grid = {} # Map (q, r) -> terrain_type
		self.units = []
		self.loot = []

	def _axial_to_offset(self, q, r):
		col = q + (r + (r & 1)) // 2
		row = r
		return col, row

	def _offset_to_axial(self, col, row):
		q = col - (row + (row & 1)) // 2
		r = row
		return q, r

	def _dist(self, q1, r1, q2, r2):
		return (abs(q1 - q2) + abs(q1 + r1 - q2 - r2) + abs(r1 - r2)) / 2

	def _get_neighbors(self, q, r):
		return [
			(q+1, r), (q-1, r), (q, r+1), (q, r-1),
			(q+1, r-1), (q-1, r+1)
		]

	def fill_base(self):
		for r in range(self.height):
			for q_offset in range(self.width):
				q, r_val = self._offset_to_axial(q_offset, r)
				self.grid[(q, r_val)] = self.default_terrain

	def add_shore(self, side=None, thickness=None, terrain=None):
		""" Adds a shore along a side with randomized defaults. """
		if not side: side = random.choice(["top", "bottom", "left", "right"])
		if not thickness: thickness = random.randint(1, 3)
		if not terrain: terrain = random.choice(["waterfall", "river", "swamp", "sand"])

		for (q, r) in self.grid.keys():
			col, row = self._axial_to_offset(q, r)
			if side == "left" and col < thickness:
				self.grid[(q, r)] = terrain
			elif side == "right" and col >= self.width - thickness:
				self.grid[(q, r)] = terrain
			elif side == "top" and row < thickness:
				self.grid[(q, r)] = terrain
			elif side == "bottom" and row >= self.height - thickness:
				self.grid[(q, r)] = terrain

	def add_mountain_range(self, start=None, end=None, width=None):
		""" Draws a line of mountains with randomized defaults. """
		if not start: start = [random.randint(0, self.width-1), random.randint(0, self.height-1)]
		if not end: end = [random.randint(0, self.width-1), random.randint(0, self.height-1)]
		if not width: width = random.uniform(1.0, 2.5)

		q1, r1 = self._offset_to_axial(start[0], start[1])
		q2, r2 = self._offset_to_axial(end[0], end[1])
		dist = self._dist(q1, r1, q2, r2)

		if dist == 0: return

		for i in range(int(dist) + 1):
			t = i / dist
			curr_q = round(q1 * (1 - t) + q2 * t)
			curr_r = round(r1 * (1 - t) + r2 * t)

			for (q, r) in self.grid.keys():
				if self._dist(curr_q, curr_r, q, r) <= width:
					chance = random.random()
					if chance > 0.6: self.grid[(q, r)] = "mountain_peak"
					elif chance > 0.3: self.grid[(q, r)] = "hill_high_ground"
					else: self.grid[(q, r)] = "stone"

	def add_river(self, start=None, end=None):
		""" Simple random walk river with randomized defaults. """
		if not start: start = [0, random.randint(0, self.height-1)]
		if not end: end = [self.width-1, random.randint(0, self.height-1)]

		curr_q, curr_r = self._offset_to_axial(start[0], start[1])
		target_q, target_r = self._offset_to_axial(end[0], end[1])

		if (curr_q, curr_r) not in self.grid: return

		max_steps = self.width * self.height
		steps = 0
		while (curr_q, curr_r) != (target_q, target_r) and steps < max_steps:
			self.grid[(curr_q, curr_r)] = "river"
			neighbors = [n for n in self._get_neighbors(curr_q, curr_r) if n in self.grid]
			if not neighbors: break

			if random.random() > 0.15:
				curr_q, curr_r = min(neighbors, key=lambda n: self._dist(n[0], n[1], target_q, target_r))
			else:
				curr_q, curr_r = random.choice(neighbors)
			steps += 1

		if (target_q, target_r) in self.grid: self.grid[(target_q, target_r)] = "river"

	def add_natural_path(self, start=None, end=None):
		""" Enhancement: Connects two points with paths and bridges. """
		if not start: start = [0, 0]
		if not end: end = [self.width - 1, self.height - 1]

		curr_q, curr_r = self._offset_to_axial(start[0], start[1])
		target_q, target_r = self._offset_to_axial(end[0], end[1])

		steps = 0
		while (curr_q, curr_r) != (target_q, target_r) and steps < 500:
			current_t = self.grid.get((curr_q, curr_r), "")
			# If crossing water, use a bridge
			if current_t in self.WATER_TERRAINS:
				self.grid[(curr_q, curr_r)] = "bridge_causeway"
			else:
				self.grid[(curr_q, curr_r)] = "path"

			neighbors = [n for n in self._get_neighbors(curr_q, curr_r) if n in self.grid]
			if not neighbors: break
			curr_q, curr_r = min(neighbors, key=lambda n: self._dist(n[0], n[1], target_q, target_r))
			steps += 1

	def scatter_objects(self, obj_type="unit", count=3, terrain_whitelist=None, data=None):
		""" Enhancement: Procedurally scatters units or loot based on terrain. """
		if not terrain_whitelist: terrain_whitelist = ["grass", "path", "hill_high_ground"]

		valid_coords = [c for c, t in self.grid.items() if t in terrain_whitelist]
		if not valid_coords: return

		count = min(count, len(valid_coords))
		chosen = random.sample(valid_coords, count)

		for (q, r) in chosen:
			col, row = self._axial_to_offset(q, r)
			entry = {"coord": [col, row]}
			if data: entry.update(data)

			if obj_type == "unit": self.units.append(entry)
			else: self.loot.append(entry)

	def export_all(self):
		terrain_data = []
		for (q, r), t_type in self.grid.items():
			col, row = self._axial_to_offset(q, r)
			terrain_data.append({"coord": [col, row], "type": t_type})
		return terrain_data, self.units, self.loot

def generate_from_config(config_path):
	try:
		with open(config_path, 'r', encoding='utf-8') as f:
			config = json.load(f)
	except Exception as e:
		print(f"Error loading config: {e}")
		return

	width, height = config.get('width', 15), config.get('height', 12)
	gen = HexMapGenerator(width, height, config.get('default_terrain', 'grass'))
	gen.fill_base()

	# Existing units/loot from config
	gen.units = config.get('unit_data', [])
	gen.loot = config.get('loot_data', [])

	for feature in config.get('features', []):
		f_type = feature.get('type')
		if f_type == 'shore':
			gen.add_shore(feature.get('side'), feature.get('thickness'), feature.get('terrain'))
		elif f_type == 'mountains':
			gen.add_mountain_range(feature.get('start'), feature.get('end'), feature.get('width'))
		elif f_type == 'river':
			gen.add_river(feature.get('start'), feature.get('end'))
		elif f_type == 'path':
			gen.add_natural_path(feature.get('start'), feature.get('end'))
		elif f_type == 'scatter':
			gen.scatter_objects(
				feature.get('object_type', 'unit'),
				feature.get('count', 3),
				feature.get('terrain_whitelist'),
				feature.get('data')
			)

	output = config.copy()
	t_data, u_data, l_data = gen.export_all()
	output["terrain_data"] = t_data
	output["unit_data"] = u_data
	output["loot_data"] = l_data

	output_name = config_path.replace('.json', '_generated.json')
	with open(output_name, 'w', encoding='utf-8') as f:
		json.dump(output, f, indent=4)
	print(f"Generated level with {len(t_data)} tiles, {len(u_data)} units, {len(l_data)} loot.")
	print(f"Saved to: {output_name}")

if __name__ == "__main__":
	import sys
	if len(sys.argv) > 1:
		generate_from_config(sys.argv[1])
	else:
		# Default run creates a test config showcasing new features
		test_cfg = "generator_test.json"
		with open(test_cfg, "w") as f:
			json.dump({
				"level_name": "Enhanced Procedural Level",
				"width": 18, "height": 14,
				"features": [
					{ "type": "shore", "side": "top" }, # Randomized thickness/terrain
					{ "type": "river" }, # Randomized path
					{ "type": "path", "start": [0,0], "end": [17, 13] }, # Path with bridges
					{ "type": "mountains", "width": 2.2 }, # Random range
					{ "type": "scatter", "object_type": "unit", "count": 5, "data": {"unit_name": "Goblin", "faction": 1} },
					{ "type": "scatter", "object_type": "loot", "count": 3, "data": {"item_id": "Health Potion"} }
				]
			}, f, indent=4)
		generate_from_config(test_cfg)
