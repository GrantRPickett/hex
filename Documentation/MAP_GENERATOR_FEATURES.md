# Hex Map Generator: Feature List & Documentation

The `hex_map_generator.py` script is a procedural generation tool designed to create complex, feature-rich terrain maps for the HEX project. It utilizes axial coordinate math to handle hexagonal grid logic and outputs JSON data compatible with the `json_to_tres.py` pipeline.

## Related Documentation

- **[Level Creation Guide](LEVEL_CREATION_GUIDE.md)**: Technical instructions for building levels in Godot.
- **[Level Design Guidelines](LEVEL_DESIGN_GUIDELINES.md)**: Creative best practices for narrative and gameplay pacing.
- **[Utility Scripts Catalog](UTILITY_SCRIPTS.md)**: Overview of other scripts in the pipeline.

## 1. Core Generation Features

### 🗺️ Base Grid Initialization
- **Fill Base**: Automatically populates the entire defined grid width and height with a `default_terrain` (e.g., `grass`).
- **Coordinate System**: Internally calculates logic using **Axial Coordinates (q, r)** for accurate distance and neighbor checks, while exporting to **Offset Coordinates [col, row]** for Godot compatibility.

### 🌊 Shorelines
- **Description**: Adds a "border" of specific terrain along the edges of the map.
- **Parameters**: 
  - `side`: "top", "bottom", "left", or "right".
  - `thickness`: Number of tiles deep the shore extends.
  - `terrain`: The terrain type to apply (e.g., `waterfall`, `sand`, `ice`).

### 🏔️ Mountain Ranges
- **Description**: Draws a natural-looking line of elevated terrain between two points.
- **Noise Logic**: Instead of a flat line, it uses probability to distribute `mountain_peak`, `hill_high_ground`, and `stone` tiles.
- **Parameters**:
  - `start` / `end`: Offset coordinates `[col, row]`.
  - `width`: The thickness of the range (supports decimals for soft edges).

### 💧 River Systems
- **Description**: Generates a winding path of `river` tiles between two points.
- **Pathfinding**: Uses a "weighted random walk" that generally trends toward the destination but meanders naturally.
- **Parameters**:
  - `start` / `end`: Offset coordinates `[col, row]`.

### 🌲 Feature Clusters
- **Description**: Scatters circular "blobs" of terrain across the map to create biomes or points of interest.
- **Parameters**: 
  - `terrain`: The terrain type (e.g., `enchanted_forest`, `swamp`).
  - `count`: Number of clusters to generate.
  - `radius`: How large each cluster should be.

---

## 2. Configuration Workflow

The generator is "Data-Driven," meaning you define the map features in a simple JSON configuration file.

### Example Configuration Snippet
```json
{
    "level_name": "Mystic Valley",
    "width": 20,
    "height": 15,
    "default_terrain": "grass",
    "features": [
        { "type": "shore", "side": "left", "thickness": 3, "terrain": "waterfall" },
        { "type": "mountains", "start": [5, 2], "end": [5, 12], "width": 1.5 },
        { "type": "cluster", "terrain": "enchanted_forest", "count": 4, "radius": 2.0 }
    ]
}
```

---

## 3. Integration Path

1. **Input**: User creates a `<level>.json` containing basic info and a `features` list.
2. **Execution**: Run `python scripts/hex_map_generator.py <level>.json`.
3. **Output**: The script produces `<level>_generated.json` which now contains the full `terrain_data` array.
4. **Conversion**: Run `python scripts/json_to_tres.py <level>_generated.json` to create the final Godot `.tres` resources.

---

## 4. Planned & Suggested Enhancements

- [ ] **Heightmap Support**: Integration of Perlin/Simplex noise for organic terrain distribution.
- [ ] **Pathing Logic**: Automatically generate `path` or `bridge_causeway` tiles between player starts and objectives.
- [ ] **Biome Compatibility**: Rules to prevent "illegal" neighbors (e.g., `lava_flow` next to `ice`).
- [ ] **Symmetry Modes**: For competitive maps (Vertical, Horizontal, or Radial symmetry).
- [ ] **Object Scattering**: Procedurally placing `unit_data` (enemies) or `loot_data` based on terrain type.
