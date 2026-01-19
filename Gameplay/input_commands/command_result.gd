class_name CommandResult
extends RefCounted

## Result codes for command execution
enum Status {
	SUCCESS,
	FAILED,
	INVALID_CONTEXT,
	INVALID_PAYLOAD,
	PRECONDITION_FAILED,
}

var status: Status
var error_message: String = ""

func _init(p_status: Status = Status.SUCCESS, p_error: String = "") -> void:
	status = p_status
	error_message = p_error

static func success() -> CommandResult:
	return CommandResult.new(Status.SUCCESS)

static func failed(error: String = "Command failed") -> CommandResult:
	return CommandResult.new(Status.FAILED, error)

static func invalid_context(missing: PackedStringArray = []) -> CommandResult:
	var msg = "Invalid context"
	if missing.size() > 0:
		msg += ": missing " + ", ".join(missing)
	return CommandResult.new(Status.INVALID_CONTEXT, msg)

static func invalid_payload(reason: String = "Invalid payload") -> CommandResult:
	return CommandResult.new(Status.INVALID_PAYLOAD, reason)

static func precondition_failed(reason: String = "Precondition failed") -> CommandResult:
	return CommandResult.new(Status.PRECONDITION_FAILED, reason)

func is_success() -> bool:
	return status == Status.SUCCESS

func is_failure() -> bool:
	return status != Status.SUCCESS

func get_description() -> String:
	var status_name = Status.keys()[status] if status < Status.size() else "UNKNOWN"
	if error_message.is_empty():
		return status_name
	return "%s: %s" % [status_name, error_message]
