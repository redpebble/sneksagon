class_name Hex
extends Node2D

var grid_coords: Vector2
var scale_factor = 1.0

var scale_tween : Tween = null
var flash_tween : Tween = null

@onready var original_color := modulate
@onready var flash_shader : ShaderMaterial = $Circle.material

func _ready() -> void:
	scale *= scale_factor

func set_shape_state(state : int):
	match(state):
		0:
			$Polygon2D.visible = false
			$Circle.visible = false
		1:
			$Polygon2D.visible = true
			$Circle.visible = false
		2:
			$Polygon2D.visible = false
			$Circle.visible = true

func swell(scale_multiplier : float, duration : float):
	if scale_tween:
		scale_tween.kill()
	var original_scale = Vector2.ONE * MapManager.hex_scale * scale_factor
	scale_tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	scale_tween.tween_property(self, "scale", original_scale * scale_multiplier, duration * 0.5)
	scale_tween.tween_property(self, "scale", original_scale, duration * 0.5)

func shrink(duration : float) -> Tween:
	if scale_tween:
		scale_tween.kill()
	var scale_multiplier := 1.2
	var original_scale = Vector2.ONE * MapManager.hex_scale * scale_factor
	scale_tween = create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", original_scale * scale_multiplier, duration * 0.3)
	scale_tween.set_ease(Tween.EASE_IN)
	scale_tween.tween_property(self, "scale", Vector2.ZERO, duration * 0.7)
	return scale_tween

func pulse(amount : float, duration : float) -> Tween:
	if flash_tween:
		flash_tween.kill()
	flash_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	flash_tween.tween_method(_set_flash_strength, get_flash_strength(), amount, duration * 0.5)
	flash_tween.tween_method(_set_flash_strength, amount, 0.0, duration * 0.5)
	
	return flash_tween

func loop(animation : Callable, duration_variation : float):
	var original_animation = animation
	var args = animation.get_bound_arguments()
	if not args.is_empty() and args[-1] is float:
		var duration_scale = randf_range(0, duration_variation)
		args[-1] *= 1.0 - duration_scale
		animation = get(animation.get_method()).bindv(args)
	await animation.call().finished
	loop(original_animation, duration_variation)

func flash(amount : float, duration : float) -> Tween:
	if flash_tween:
		flash_tween.kill()
	flash_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	flash_tween.tween_method(_set_flash_strength, 1.0, 0.0, duration)
	return flash_tween

func _set_flash_strength(value : float) -> void:
	flash_shader.set_shader_parameter("strength", value)
func get_flash_strength() -> float:
	if flash_shader:
		return flash_shader.get_shader_parameter("strength")
	else:
		return 0.0
