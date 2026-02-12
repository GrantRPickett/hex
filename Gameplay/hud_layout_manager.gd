class_name HUDLayoutManager
extends Node

@onready var margin_container: MarginContainer = get_parent()

func _ready() -> void:
	if not margin_container:
		margin_container = get_parent()
	margin_container.resized.connect(_on_margin_resized)
	# Defer initial check to let containers settle
	_on_margin_resized.call_deferred()

func _on_margin_resized() -> void:
	var size = margin_container.size
	# If margin size is invalid/zero, fallback to viewport as a hint
	if size.x < 100 or size.y < 100:
		size = get_viewport().get_visible_rect().size

	var is_portrait = size.y > size.x
	# Check for 'narrow' landscape as well (e.g. square-ish screens)
	if not is_portrait and size.x < 800:
		is_portrait = true

	print_debug("HUDLayoutManager: Margin Resized to ", size, " | is_portrait: ", is_portrait)
	_update_layout(is_portrait)

func _update_layout(is_portrait: bool) -> void:
	var tl = margin_container.get_node_or_null("TopLeftContainer")
	var tr = margin_container.get_node_or_null("TopRightContainer")
	var bl = margin_container.get_node_or_null("BottomLeftContainer")
	var br = margin_container.get_node_or_null("BottomRightContainer")
	var cl = margin_container.get_node_or_null("CenterLeftContainer")
	var cr = margin_container.get_node_or_null("CenterRightContainer")

	if not tl or not tr or not bl or not br or not cl or not cr:
		return

	if is_portrait:
		print_debug("HUDLayoutManager: Switching to Portrait...")
		# Migrate nodes to corners to clear center sides
		_migrate_children(cl, tl) # location Details -> Top Left
		_migrate_children(cr, br, true) # Combat/Loot -> Bottom Right

		tl.show(); tr.show(); bl.show(); br.show()
		cl.hide(); cr.hide()
	else:
		print_debug("HUDLayoutManager: Switching to Landscape...")
		# Restore original positions
		for child in tl.get_children():
			if child is LocationDetailsPanel or child.name == "LocationDetailsPanel":
				print_debug("HUDLayoutManager: Moving location Details back to Center Left")
				_reparent(child, cl)

		for child in br.get_children():
			if child is CombatPreviewPanel or child is LootDetailsPanel or child.name == "CombatPreviewPanel" or child.name == "LootDetailsPanel":
				print_debug("HUDLayoutManager: Moving ", child.name, " back to Center Right")
				_reparent(child, cr)

		tl.show(); tr.show(); bl.show(); br.show()
		cl.show(); cr.show()

func _migrate_children(from: Control, to: Control, prepend: bool = false) -> void:
	var children = from.get_children()
	for child in children:
		_reparent(child, to, prepend)

func _reparent(node: Node, new_parent: Node, prepend: bool = false) -> void:
	if node.get_parent() == new_parent:
		return
	node.get_parent().remove_child(node)
	new_parent.add_child(node)
	if prepend:
		new_parent.move_child(node, 0)
