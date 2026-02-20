class_name ActionLabelFormatter
extends RefCounted

static func format(base: String, adjacent_count: int, reachable_count: int) -> String:
	var detail: Array[String] = []
	if adjacent_count > 0:
		detail.append("%d adjacent" % adjacent_count)
	if reachable_count > 0:
		detail.append("%d reachable" % reachable_count)
	if detail.is_empty():
		return base
	return "%s (%s)" % [base, ", ".join(detail)]
