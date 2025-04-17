extends Node2D

@export_range(0.0, 1.0, 0.05) var min_brightness : float = 0.2
@export_range(0.0, 2.0, 0.1) var pulse_interval : float = 1.0
@onready var sprite := $Sprite2D

var pulse_tween : Tween


func _init() -> void:
	z_index = 1

func _ready() -> void:
	scale_to_width(MapManager.hex_width)

func scale_to_width(hex_width : float) -> void:
	var scale_amount = hex_width / sprite.texture.get_width()
	sprite.scale = Vector2.ONE * scale_amount

func highlight_position(pos : Vector2, show_highlight : bool) -> void:
	visible = show_highlight
	if sprite.global_position != pos:
		pulse()
	sprite.global_position = pos

func pulse():
	reset_brightness()
	if pulse_tween: pulse_tween.kill()
	pulse_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(sprite, "modulate:a", min_brightness, pulse_interval * 0.5)
	pulse_tween.tween_property(sprite, "modulate:a", 1, pulse_interval * 0.5)
	pulse_tween.finished.connect(pulse)

func reset_brightness():
	sprite.modulate.a = 1.0
