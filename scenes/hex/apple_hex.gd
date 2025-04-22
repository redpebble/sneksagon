class_name AppleHex
extends ObjectHex

@onready var eat_sfx = $EatSFX
var collected := false : set = set_collected

func _ready() -> void:
	super._ready()
	modulate = Color.RED

func eat() -> void:
	collected = true
	MapManager.spawn_apple()
	eat_sfx.play_random()
	await eat_sfx.finished
	queue_free()

func set_collected(state):
	collected = state
	visible = not collected
