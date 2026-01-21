class_name DisplayOrientation
extends RefCounted

enum Orientation {
    LANDSCAPE,
    PORTRAIT,
}

static func from_string(name: String) -> DisplayOrientation.Orientation:
    return DisplayOrientation.Orientation.PORTRAIT if name.to_lower() == "portrait" else DisplayOrientation.Orientation.LANDSCAPE

static func to_name(orientation: DisplayOrientation.Orientation) -> String:
    return "portrait" if orientation == DisplayOrientation.Orientation.PORTRAIT else "landscape"
