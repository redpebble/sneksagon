class_name AppleHex
extends ObjectHex

func _ready() -> void:
	super._ready()
	modulate = Color.RED

func eat() -> void:
	MapManager.spawn_apple()
	queue_free()
