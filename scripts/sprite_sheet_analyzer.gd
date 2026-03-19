extends SceneTree

## SpriteSheetAnalyzer.gd
## A tool script to scan art directories and suggest sprite sheet cutting parameters.
## Usage: godot -s scripts/sprite_sheet_analyzer.gd

const SEARCH_DIR = "res://Resources/art/placeholder"
const POSSIBLE_GRID_SIZES = [16, 32, 64, 128]

func _init() -> void:
	print("--- Sprite Sheet Analyzer ---")
	var images = scan_for_images(SEARCH_DIR)
	if images.is_empty():
		print("No images found in ", SEARCH_DIR)
		quit()
		return

	for img_path in images:
		analyze_image(img_path)
	
	quit()

func scan_for_images(path: String) -> Array[String]:
	var result: Array[String] = []
	var dir = DirAccess.open(path)
	if not dir:
		print("Error: Could not open directory ", path)
		return result

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var full_path = path.path_join(file_name)
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				result.append_array(scan_for_images(full_path))
		elif file_name.ends_with(".png"):
			result.append(full_path)
		file_name = dir.get_next()
	
	return result

func analyze_image(path: String) -> void:
	print("\nAnalyzing: ", path)
	var img = Image.load_from_file(path)
	if not img:
		print("  Failed to load image.")
		return

	var size = img.get_size()
	print("  Resolution: ", size.x, "x", size.y)

	# Suggest Grid Size
	var suggested_grid = suggest_grid(img)
	if suggested_grid > 0:
		print("  Suggested Grid Size: ", suggested_grid, "x", suggested_grid)
	else:
		print("  Uniform grid not detected. Suggesting bounding box analysis...")
		var boxes = find_bounding_boxes(img)
		print("  Found ", boxes.size(), " potential sprites.")
		if boxes.size() > 0:
			print("  Sample Box: ", boxes[0])

func suggest_grid(img: Image) -> int:
	var size = img.get_size()
	
	for grid in POSSIBLE_GRID_SIZES:
		if int(size.x) % grid == 0 and int(size.y) % grid == 0:
			# Check if boundaries between grids are mostly empty/background
			# This is a heuristic: check center of grid edges
			var is_likely = true
			# We only check a few samples for performance
			for x in range(grid, int(size.x), grid):
				for y in range(0, int(size.y), grid/2):
					if img.get_pixel(x, y).a > 0.1: # If boundary has pixel data
						# Not necessarily a dealbreaker, but less likely a clean grid
						pass 
			
			# If resolution matches multiple, we take the smallest that fits the "feel"
			# but for now, 32 is very common in this project
			if grid == 32:
				return 32
			
			# Fallback to the first one that fits the resolution perfectly
			return grid
			
	return 0

func find_bounding_boxes(img: Image) -> Array[Rect2i]:
	var boxes: Array[Rect2i] = []
	var visited = BitMap.new()
	visited.create(img.get_size())
	
	var size = img.get_size()
	
	for y in range(size.y):
		for x in range(size.x):
			if img.get_pixel(x, y).a > 0.1 and not visited.get_bitv(Vector2i(x, y)):
				var box = flood_fill_bounds(img, x, y, visited)
				if box.size.x > 2 and box.size.y > 2: # Ignore tiny noise
					boxes.append(box)
	
	return boxes

func flood_fill_bounds(img: Image, start_x: int, start_y: int, visited: BitMap) -> Rect2i:
	var min_x = start_x
	var max_x = start_x
	var min_y = start_y
	var max_y = start_y
	
	var stack = [Vector2i(start_x, start_y)]
	visited.set_bitv(Vector2i(start_x, start_y), true)
	
	var img_size = img.get_size()
	
	while not stack.is_empty():
		var curr = stack.pop_back()
		min_x = min(min_x, curr.x)
		max_x = max(max_x, curr.x)
		min_y = min(min_y, curr.y)
		max_y = max(max_y, curr.y)
		
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0: continue
				var next = curr + Vector2i(dx, dy)
				if next.x >= 0 and next.x < img_size.x and next.y >= 0 and next.y < img_size.y:
					if not visited.get_bitv(next) and img.get_pixelv(next).a > 0.1:
						visited.set_bitv(next, true)
						stack.push_back(next)
						
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
