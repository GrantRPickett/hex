extends SceneTree

func _init():
	var trigger = DialogueTrigger.new()
	var entry = LevelDialogueEntry.new()
	print("Setting trigger.entry = entry...")
	trigger.entry = entry
	print("Done.")
	quit()
