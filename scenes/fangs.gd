extends Sprite2D


var rotation_offset = -PI/2
var rotation_tween : Tween = null

var point_direction = rotation

func _ready() -> void:
	MapManager.scale_to_hex_width(self, texture.get_size().x * 0.85)

func match_rotation_to(direction : Vector2):
	point_direction = direction.normalized().rotated(rotation_offset).angle()

func _process(delta: float) -> void:
	rotation = lerp_angle(rotation, point_direction, 13 * delta)

func close():
	var t = create_tween().set_trans(Tween.TRANS_CIRC)
	var orig_scale_x = scale.x
	
	t.set_ease(Tween.EASE_IN)
	t.tween_property(self, "scale:x", orig_scale_x * 0.4, 0.1)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale:x", orig_scale_x, 0.3)
