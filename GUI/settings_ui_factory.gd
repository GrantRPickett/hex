class_name SettingsUIFactory
extends RefCounted

## Factory for creating standardized settings rows to reduce boilerplate in settings_menu.gd

static func create_row(name: String, label_text: String, label_width: float = 160.0, tooltip: String = "") -> HBoxContainer:
	var row = HBoxContainer.new()
	row.name = name
	
	var label = Label.new()
	label.name = "Label"
	label.text = label_text
	label.custom_minimum_size = Vector2(label_width, 0)
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	if not tooltip.is_empty():
		label.tooltip_text = tooltip
		row.tooltip_text = tooltip
	row.add_child(label)
	
	return row

static func create_toggle_row(name: String, label_text: String, initial_value: bool, on_toggled: Callable, tooltip: String = "", label_width: float = 160.0) -> HBoxContainer:
	var row = create_row(name, label_text, label_width, tooltip)
	
	var toggle = CheckButton.new()
	toggle.name = "Toggle"
	toggle.button_pressed = initial_value
	toggle.toggled.connect(on_toggled)
	toggle.focus_mode = Control.FOCUS_ALL
	if not tooltip.is_empty():
		toggle.tooltip_text = tooltip
	row.add_child(toggle)
	
	return row

static func create_slider_row(name: String, label_text: String, min_val: float, max_val: float, step_val: float, initial_value: float, on_changed: Callable, tooltip: String = "", label_width: float = 160.0) -> HBoxContainer:
	var row = create_row(name, label_text, label_width, tooltip)
	
	var slider = HSlider.new()
	slider.name = "Slider"
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step_val
	slider.value = initial_value
	slider.value_changed.connect(on_changed)
	slider.focus_mode = Control.FOCUS_ALL
	slider.custom_minimum_size = Vector2(200, 0)
	if not tooltip.is_empty():
		slider.tooltip_text = tooltip
	row.add_child(slider)
	
	var val_label = Label.new()
	val_label.name = "ValueLabel"
	val_label.text = "%.1fx" % initial_value if step_val < 0.2 else "%.1f" % initial_value
	slider.value_changed.connect(func(v): 
		val_label.text = "%.1fx" % v if step_val < 0.2 else "%.1f" % v
	)
	row.add_child(val_label)
	
	return row

static func create_audio_row(name: String, label_text: String, initial_db: float, initial_muted: bool, on_volume_changed: Callable, on_mute_toggled: Callable, label_width: float = 150.0) -> HBoxContainer:
	var row = create_row(name, label_text, label_width)
	
	var slider = HSlider.new()
	slider.name = "Volume"
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = -40.0
	slider.max_value = 0.0
	slider.step = 0.5
	slider.value = initial_db
	slider.value_changed.connect(on_volume_changed)
	slider.focus_mode = Control.FOCUS_ALL
	slider.custom_minimum_size = Vector2(200, 0)
	row.add_child(slider)
	
	var mute = CheckButton.new()
	mute.name = "Mute"
	mute.text = TranslationServer.translate("settings.audio.mute")
	mute.button_pressed = initial_muted
	mute.toggled.connect(on_mute_toggled)
	mute.focus_mode = Control.FOCUS_ALL
	mute.custom_minimum_size = Vector2(100, 0)
	row.add_child(mute)
	
	return row

static func create_option_row(name: String, label_text: String, items: Array, initial_index: int, on_selected: Callable, label_width: float = 160.0) -> HBoxContainer:
	var row = create_row(name, label_text, label_width)
	
	var option = OptionButton.new()
	option.name = "Option"
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	for i in range(items.size()):
		var item = items[i]
		if item is Dictionary:
			option.add_item(item.get("text", "Unknown"), i)
			if item.has("id"): option.set_item_id(i, item.id)
			if item.has("metadata"): option.set_item_metadata(i, item.metadata)
		else:
			option.add_item(str(item), i)
			
	option.select(initial_index)
	option.item_selected.connect(on_selected)
	option.focus_mode = Control.FOCUS_ALL
	row.add_child(option)
	
	return row
