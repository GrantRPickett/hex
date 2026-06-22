class_name DisplayOrientation
extends RefCounted

enum Orientation {
	LANDSCAPE,
	PORTRAIT,
}

static func from_string(name: String) -> DisplayOrientation.Orientation:
	return DisplayOrientation.Orientation.PORTRAIT if name.to_lower() == GameConstants.Settings.ORIENTATION_PORTRAIT else DisplayOrientation.Orientation.LANDSCAPE

static func to_name(orientation: DisplayOrientation.Orientation) -> String:
	return GameConstants.Settings.ORIENTATION_PORTRAIT if orientation == DisplayOrientation.Orientation.PORTRAIT else GameConstants.Settings.ORIENTATION_LANDSCAPE
