class_name CommandValidator
extends RefCounted

## Validates command execution prerequisites

static func validate_context(context: GameCommandContext, required_fields: PackedStringArray) -> CommandResult:
	if context == null:
		return CommandResult.invalid_context(["context"])

	var missing: PackedStringArray = []
	for field in required_fields:
		var value = context.get_field(field)
		if value == null:
			missing.append(field)

	if missing.is_empty():
		return CommandResult.success()

	return CommandResult.invalid_context(missing)

static func validate_payload_exists(payload) -> CommandResult:
	if payload == null:
		return CommandResult.invalid_payload("Payload is required")
	return CommandResult.success()

static func validate_payload_type(payload, expected_type: String) -> CommandResult:
	if payload == null:
		return CommandResult.invalid_payload("Payload is required")

	var actual_type = payload.get_class() if payload is Object else type_string(typeof(payload))
	if actual_type != expected_type:
		return CommandResult.invalid_payload("Expected %s, got %s" % [expected_type, actual_type])

	return CommandResult.success()

static func validate_payload_dict_keys(payload: Dictionary, required_keys: PackedStringArray) -> CommandResult:
	if payload == null or not payload is Dictionary:
		return CommandResult.invalid_payload("Payload must be a Dictionary")

	var missing: PackedStringArray = []
	for key in required_keys:
		if not payload.has(key):
			missing.append(key)

	if missing.is_empty():
		return CommandResult.success()

	return CommandResult.invalid_payload("Missing keys: %s" % [", ".join(missing)])

static func validate_int(value: int, min_val: int = -2147483648, max_val: int = 2147483647, name: String = "value") -> CommandResult:
	if value < min_val or value > max_val:
		return CommandResult.invalid_payload("%s out of range [%d, %d]: %d" % [name, min_val, max_val, value])
	return CommandResult.success()

static func validate_vector2i_in_bounds(coord: Vector2i, width: int, height: int) -> CommandResult:
	if coord.x < 0 or coord.y < 0 or coord.x >= width or coord.y >= height:
		return CommandResult.invalid_payload("Coordinate out of bounds: %v (grid: %dx%d)" % [coord, width, height])
	return CommandResult.success()

static func type_string(t: int) -> String:
	match t:
		TYPE_NIL: return "Null"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		TYPE_VECTOR2: return "Vector2"
		TYPE_VECTOR2I: return "Vector2i"
		TYPE_DICTIONARY: return "Dictionary"
		TYPE_ARRAY: return "Array"
		_: return "Unknown"
