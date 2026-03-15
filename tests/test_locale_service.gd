extends GdUnitTestSuite

const LocaleServiceScript = preload("res://Autoloads/locale_service.gd")

func _make_service() -> Node:
	var service: LocaleServiceScript = LocaleServiceScript.new()
	add_child(service)
	return service

func after_test() -> void:
	for child in get_children():
		child.queue_free()

func test_apply_locale_settings() -> void:
	var service = _make_service()
	var monitor = monitor_signals(service)

	service.apply_locale_settings()

	assert_signal(monitor).is_emitted("locale_changed")
