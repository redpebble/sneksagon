class_name ShakyCamera
extends Camera2D

@onready var screen_shake = $ScreenShake

func _ready() -> void:
	GameManager.camera = self

func small_shake() -> void:
	screen_shake.start(0.25, 30, 8.5, 0)

func spin():
	ignore_rotation = false
	rotation = 0
	var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	t.tween_property(self, "rotation", 2 * PI * 2, 1.8)
