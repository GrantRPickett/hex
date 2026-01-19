# Hexagon Orientation Configuration

## Overview
HEX supports both **flat-top** and **pointy-top** hexagon orientations per level. The visual representation (shape drawn on screen) automatically adapts to match the grid's tile offset axis configuration.

## Tile Offset Axis Settings

| Setting | Enum Value | Hexagon Shape | Offset Pattern |
|---------|-----------|--------------|-----------------|
| `TILE_OFFSET_AXIS_VERTICAL` | `1` | Flat-top (wide) | Rows offset vertically |
| `TILE_OFFSET_AXIS_HORIZONTAL` | `0` | Pointy-top (tall) | Columns offset horizontally |

## How to Set Per Level

Each level resource specifies its orientation via the `hex_offset_axis` export:

```gdscript
# In Resources/Level.gd or custom level files
@export var hex_offset_axis: int = TileSet.TILE_OFFSET_AXIS_VERTICAL
```

### Examples

**Flat-top hexagons (default):**
```gdscript
level.hex_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
```

**Pointy-top hexagons:**
```gdscript
level.hex_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
```

## Consistency Guarantees

When a level is loaded, the following systems automatically synchronize to the level's orientation:

1. **Grid System** (`grid_controller.gd`)
   - Sets `TileSet.tile_offset_axis` from level data

2. **Terrain Map** (`terrain_map.gd`)
   - Configures neighbor offset patterns via `set_offset_axis()`
   - Ensures `get_neighbors()` returns correct adjacent cells

3. **Visual Representation** (`grid_visuals.gd`)
   - Draws hexagons matching the grid's tile offset axis
   - Updates all visual indicators: hover, range, path preview, terrain overlay

4. **Navigation** (`hex_navigator.gd`)
   - Uses direction vectors calculated from grid's actual cell positions

## Implementation Details

### Visual Adaptation

The `_build_hex_points()` method inspects the grid's `tile_set.tile_offset_axis` and renders the appropriate shape:

```gdscript
func _build_hex_points(tile_size: Vector2, grid: Node2D = null) -> PackedVector2Array:
	var use_flat_top := false
	if grid and grid.tile_set:
		use_flat_top = (grid.tile_set.tile_offset_axis == TileSet.TILE_OFFSET_AXIS_VERTICAL)

	if use_flat_top:
		# Render flat-top (8 vertices)
		return PackedVector2Array([...])
	else:
		# Render pointy-top (6 vertices)
		return PackedVector2Array([...])
```

### Load Flow

1. `LevelBuilder.build()` reads level's `hex_offset_axis`
2. Updates grid's tileset: `dup.tile_offset_axis = data.hex_offset_axis`
3. Updates terrain map: `terrain_map.set_offset_axis(data.hex_offset_axis)`
4. Gameplay calls `grid_visuals.setup_hex_shape()` which reads grid's axis
5. All subsequent visual updates respect the configuration

## Testing

When adding new levels or changing orientation:

1. **Verify neighbor calculation:** Use `tests/terrain/test_terrain_map.gd::test_get_neighbors_respects_offset_axis`
2. **Check visual alignment:** Run gameplay and hover over cells - hexagons should align with grid neighbors
3. **Test pathfinding:** Units should move along correct adjacency patterns

## Troubleshooting

**Hexagons look misaligned or wrong shape:**
- Verify level's `hex_offset_axis` matches intended orientation
- Check `gameplay.tscn` default tileset matches most levels
- Run `test_get_neighbors_respects_offset_axis` to confirm neighbor logic

**Units moving to unexpected cells:**
- Likely neighbor calculation mismatch
- Confirm terrain map's `offset_axis` set correctly in `LevelBuilder.build()`
- Verify `TerrainMap.get_neighbors()` uses correct offset pattern

**Range indicator or hover highlight shows wrong shape:**
- Ensure `setup_hex_shape()` was called with grid parameter
- Verify grid passed to `_build_hex_points()` has valid tileset
