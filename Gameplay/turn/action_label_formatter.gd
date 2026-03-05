class_name ActionLabelFormatter
extends RefCounted

static func format(base: String, adjacent_count: int, reachable_count: int, imm_label: String = "adjacent") -> String:
	var detail: Array[String] = []
	if adjacent_count > 0:
		detail.append("%d %s" % [adjacent_count, imm_label])
	if reachable_count > 0:
		detail.append("%d reachable" % reachable_count)
	if detail.is_empty():
		return base
	return "%s (%s)" % [base, ", ".join(detail)]
