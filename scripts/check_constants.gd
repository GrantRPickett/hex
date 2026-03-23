extends SceneTree

func _init():
	print("--- ScrollContainer.ScrollMode Constants ---")
	print("SCROLL_MODE_DISABLED: ", ScrollContainer.SCROLL_MODE_DISABLED)
	print("SCROLL_MODE_AUTO: ", ScrollContainer.SCROLL_MODE_AUTO)
	print("SCROLL_MODE_SHOW_ALWAYS: ", ScrollContainer.SCROLL_MODE_SHOW_ALWAYS)
	print("SCROLL_MODE_SHOW_NEVER: ", ScrollContainer.SCROLL_MODE_SHOW_NEVER)

	# Try to access SCROLL_MODE_HIDDEN to see if it exists
	if "SCROLL_MODE_HIDDEN" in ScrollContainer:
		print("SCROLL_MODE_HIDDEN exists")
	else:
		print("SCROLL_MODE_HIDDEN DOES NOT EXIST")

	quit()
