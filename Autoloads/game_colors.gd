class_name GameColors

## Centralized color constants and palette management.
## This utility provides a single source of truth for all game colors.
## For accessibility overrides, query AccessibilityManager directly.

# --- Core Palette ---
const WHITE := Color(1, 1, 1, 1)
const BLACK := Color(0, 0, 0, 1)
const TRANSPARENT := Color(0, 0, 0, 0)
const WHITE_TRANSPARENT := Color(1, 1, 1, 0)
const WHITE_SEMI_TRANSPARENT := Color(1, 1, 1, 0.6)
const WHITE_MOSTLY_OPAQUE := Color(1, 1, 1, 0.9)

# --- UI Feedback ---
const WARNING := Color(1, 0.2, 0.2)
const HINT_TEXT := Color(1, 1, 0.8)
const SUCCESS := Color(0.2, 1, 0.2)
const INFO := Color(0.2, 0.6, 1)
const UI_WHITE := Color(1, 1, 1)
const UI_GRAY := Color(0.5, 0.5, 0.5)
const UI_CYAN := Color.CYAN

# --- Basic Color Aliases (for backward compatibility) ---
const RED := Color.RED
const GREEN := Color.GREEN
const BLUE := Color.BLUE
const YELLOW := Color.YELLOW

# --- Factions ---
const FACTION_PLAYER := Color.GREEN
const FACTION_ENEMY := Color.RED
const FACTION_NEUTRAL := Color.YELLOW
const FACTION_NEUTRAL_ALT := Color.GOLD

# --- Attributes & Stats ---
const WILLPOWER_LOW := Color.ORANGE_RED
const WILLPOWER_MID := Color.YELLOW
const WILLPOWER_NORMAL := Color.WHITE
const MOVES_DEPLETED := Color.RED
const MOVES_NORMAL := Color.WHITE

# --- Tasks & Journal ---
const TASK_COMPLETED_TEXT := Color(0.5, 0.5, 0.5)
const TASK_FACTION_HEADER := Color(0.8, 0.8, 0.2)
const TASK_LOCATION_TEXT := Color(0.8, 1.0, 0.8)
const TASK_OBJECTIVE_FADE := Color(0, 0, 0, 0)

# --- Inventory ---
const INV_BG := Color(0.2, 0.5, 0.3, 1.0)
const INV_HELP_TEXT := Color(0.8, 0.8, 0.4)
const INV_SLOT_BG := Color(0.3, 0.5, 0.8, 0.4)
const INV_CHAR_PANEL_BG := Color(0.2, 0.4, 0.6, 0.5)
const INV_ITEM_EQUIPPED := Color.GREEN
const INV_ITEM_UNEQUIPPED := Color.WHITE
const INV_CAPACITY_FULL := Color.GOLD
const INV_CAPACITY_NORMAL := Color(0.7, 0.7, 0.7)
const INV_HIGHLIGHT := Color.CYAN
const INV_DEBUG_BG := Color(0.6, 0.2, 0.2, 1.0)

# --- Grid Overview ---
const GRID_HOVER := Color(1.0, 1.0, 1.0, 0.25)
const GRID_PATH_LINE := Color(1.0, 1.0, 1.0, 0.7)
const GRID_THREATENED_PATH := Color(1.0, 0.1, 0.1, 0.8)
const GRID_RANGE_PLAYER := Color(0.2, 0.6, 1.0, 0.3)
const GRID_RANGE_ENEMY := Color(1.0, 0.3, 0.3, 0.3)
const GRID_RANGE_TENTATIVE := Color(1.0, 1.0, 0.0, 0.5)
const GRID_AOO_THREAT := Color(1.0, 0.5, 0.0, 0.5)
const GRID_ENEMY_RANGE_FULL := Color(1.0, 0.0, 0.0, 0.2)
const GRID_DIALOGUE_INDICATOR := Color(1.0, 0.85, 0.0, 0.6)
const GRID_LOCATION_HAZARD := Color(1.0, 0.5, 0.0, 0.5)
const GRID_LOCATION_BOOST := Color(0.2, 0.9, 0.4, 0.45)
const GRID_LOYALTY_PLAYER := Color(0.0, 1.0, 0.5, 0.25)
const GRID_LOYALTY_ENEMY := Color(1.0, 0.1, 0.1, 0.25)
const GRID_LOYALTY_NEUTRAL := Color(1.0, 1.0, 1.0, 0.15)

# --- Terrain Colors ---
const TERRAIN_ASH := Color(0.86, 0.86, 0.86) # #DCDCDC
const TERRAIN_BRIDGE_CAUSEWAY := Color.SADDLE_BROWN
const TERRAIN_CAVE_ENTRANCE := Color.DARK_SLATE_GRAY
const TERRAIN_COURTYARD := Color.LIGHT_GRAY
const TERRAIN_CROSSROADS := Color.TAN
const TERRAIN_CRYSTAL := Color.AQUA
const TERRAIN_DESERT_OASIS := Color.AQUA
const TERRAIN_ENCHANTED_FOREST := Color.FOREST_GREEN
const TERRAIN_FLOATING_ISLAND := Color.LIME_GREEN
const TERRAIN_FORT := Color.FIREBRICK
const TERRAIN_GRASS := Color.LAWN_GREEN
const TERRAIN_GRAVEYARD := Color(0.86, 0.86, 0.86) # #DCDCDC
const TERRAIN_HILL_HIGH_GROUND := Color.YELLOW_GREEN
const TERRAIN_ICE := Color.ALICE_BLUE
const TERRAIN_JUNGLE := Color.DARK_GREEN
const TERRAIN_KEEP := Color.DARK_GRAY
const TERRAIN_LAVA_FLOW := Color.DARK_RED
const TERRAIN_LEAF_PLATFORM := Color.PALE_GREEN
const TERRAIN_MONASTERY := Color.GRAY
const TERRAIN_MOUNTAIN_PEAK := Color.SLATE_GRAY
const TERRAIN_MUD := Color.SADDLE_BROWN
const TERRAIN_OASIS := Color.TEAL
const TERRAIN_PATH := Color.PERU
const TERRAIN_PLAZA := Color.SILVER
const TERRAIN_QUAGMIRE := Color.SIENNA
const TERRAIN_RIVER := Color.CORNFLOWER_BLUE
const TERRAIN_ROCK_DUNE := Color.WHEAT
const TERRAIN_RUINS := Color.SLATE_GRAY
const TERRAIN_SAND := Color.SANDY_BROWN
const TERRAIN_STONE := Color.SLATE_GRAY
const TERRAIN_SWAMP := Color.OLIVE_DRAB
const TERRAIN_TREE_VILLAGE := Color.DARK_OLIVE_GREEN
const TERRAIN_VINES := Color.DARK_OLIVE_GREEN
const TERRAIN_WALL := Color.BURLYWOOD
const TERRAIN_WATERFALL := Color.LIGHT_BLUE

# --- Attribute Colors (Accessible) ---
const ATTR_SHINE := Color(0.835, 0.369, 0.0) # Vermillion (#D55E00)
const ATTR_SHADE := Color(0.337, 0.706, 0.914) # Sky Blue (#56B4E9)
const ATTR_FOCUS := Color(0.8, 0.475, 0.655) # Reddish Purple (#CC79A7)
const ATTR_GRIT := Color(0.902, 0.624, 0.0) # Orange (#E69F00)
const ATTR_FLOW := Color(0.0, 0.447, 0.698) # Blue (#0072B2)
const ATTR_GUSTO := Color(0.0, 0.62, 0.451) # Bluish Green (#009E73)

static func get_attribute_color(idx: int) -> Color:
	match idx:
		0: return ATTR_GRIT # GRIT
		1: return ATTR_FLOW # FLOW
		2: return ATTR_GUSTO # GUSTO
		3: return ATTR_FOCUS # FOCUS
		4: return ATTR_SHINE # SHINE
		5: return ATTR_SHADE # SHADE
	return Color.WHITE

static func get_faction_color(faction: int) -> Color:
	match faction:
		0: return FACTION_PLAYER # PLAYER
		1: return FACTION_ENEMY # ENEMY
		2: return FACTION_NEUTRAL # NEUTRAL
	return WHITE

static func colorize_attributes(text: String) -> String:
	var result: String = text
	# Mapping indices to names for replacement
	var attr_data = {
		0: "grit",
		1: "flow",
		2: "gusto",
		3: "focus",
		4: "shine",
		5: "shade"
	}
	
	for idx in attr_data.keys():
		var color: Color = get_attribute_color(idx)
		var hex: String = color.to_html(false)
		var internal_name: String = attr_data[idx]
		
		var translated_name: String = TranslationServer.translate("attr." + internal_name)
		var capitalized_name: String = translated_name.capitalize()
		var braced_name: String = "{" + internal_name + "}"

		result = result.replace(braced_name, "[color=#%s]%s[/color]" % [hex, translated_name])
		result = result.replace(capitalized_name, "[color=#%s]%s[/color]" % [hex, capitalized_name])
		result = result.replace(translated_name, "[color=#%s]%s[/color]" % [hex, translated_name])
	return result

# --- High Contrast Helpers ---
# For now, we mainly use these as constants. 
# If a specific component needs accessible variations, it should query AccessibilityManager.

static func get_warning_color(high_contrast: bool = false) -> Color:
	return Color(1, 0.5, 0.5) if high_contrast else WARNING
