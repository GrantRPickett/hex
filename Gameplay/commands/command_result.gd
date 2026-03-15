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
var message: String = ""

func _init(p_status: Status = Status.SUCCESS, p_message: String = "") -> void:
	status = p_status
	message = p_message

static func success(p_message: String = "") -> CommandResult:
	return CommandResult.new(Status.SUCCESS, p_message)

static func failed(error: String = "Command failed") -> CommandResult:
	return CommandResult.new(Status.FAILED, error)

static func invalid_context(missing: PackedStringArray = []) -> CommandResult:
	var msg: String = "Invalid context"
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
	var status_name: String = Status.keys()[status] if status < Status.size() else "UNKNOWN"
	if message.is_empty():
		return status_name
	return "%s: %s" % [status_name, message]
func get_error_message() -> String:
	return message
