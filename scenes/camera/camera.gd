class_name ShakyCamera
extends Camera2D

@onready var screen_shake = $ScreenShake

func _ready() -> void:
	GameManager.camera = self

func small_shake() -> void:
	screen_shake.start(0.25, 30, 8.5, 0)
