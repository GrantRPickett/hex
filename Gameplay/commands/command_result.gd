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
var fix_hint: String = ""

func _init(p_status: Status = Status.SUCCESS, p_message: String = "", p_fix_hint: String = "") -> void:
	status = p_status
	message = p_message
	fix_hint = p_fix_hint

static func success(p_message: String = "") -> CommandResult:
	return CommandResult.new(Status.SUCCESS, p_message)

static func failed(error: String = "Command failed", hint: String = "") -> CommandResult:
	return CommandResult.new(Status.FAILED, error, hint)

static func invalid_context(missing: PackedStringArray = [], hint: String = "") -> CommandResult:
	var msg: String = "Invalid context"
	if missing.size() > 0:
		msg += ": missing " + ", ".join(missing)
	return CommandResult.new(Status.INVALID_CONTEXT, msg, hint)

static func invalid_payload(reason: String = "Invalid payload", hint: String = "") -> CommandResult:
	return CommandResult.new(Status.INVALID_PAYLOAD, reason, hint)

static func precondition_failed(reason: String = "Precondition failed", hint: String = "") -> CommandResult:
	return CommandResult.new(Status.PRECONDITION_FAILED, reason, hint)

func is_success() -> bool:
	return status == Status.SUCCESS

func is_failure() -> bool:
	return status != Status.SUCCESS

func get_description() -> String:
	var status_name: String = Status.keys()[status] if status < Status.size() else "UNKNOWN"
	var desc := status_name
	if not message.is_empty():
		desc += ": " + message
	if not fix_hint.is_empty():
		desc += " [Fix: " + fix_hint + "]"
	return desc
func get_error_message() -> String:
	return message
