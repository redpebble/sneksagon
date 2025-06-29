class_name AppleHex
extends ObjectHex

signal just_collected

@onready var eat_sfx = $EatSFX
var collected := false : set = set_collected


func _init() -> void:
	#super._ready()
	if randf() > 0.5:
		ModifierManager.add_new_modifier(self)

func eat() -> void:
	collected = true
	just_collected.emit()
	eat_sfx.play_random()
	await eat_sfx.finished
	queue_free()

func set_collected(state):
	collected = state
	visible = not collected
