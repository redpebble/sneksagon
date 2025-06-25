class_name AppleHex
extends ObjectHex

signal just_collected(this_apple)

@onready var eat_sfx = $EatSFX
var collected := false : set = set_collected

func eat() -> void:
	collected = true
	just_collected.emit(self)
	eat_sfx.play_random()
	await eat_sfx.finished
	queue_free()

func set_collected(state):
	collected = state
	visible = not collected
