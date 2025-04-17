class_name SnakeHex
extends ObjectHex

@onready var map = get_parent()

var prev_segment : SnakeHex = null
var next_segment : SnakeHex = null


func _draw() -> void:
	if next_segment:
		draw_line(Vector2.ZERO, to_local(next_segment.global_position), modulate, 1)

# overrides ObjectHex.move()
func move(pos : Vector2, duration := 0.25) -> Tween:
	if next_segment:
		next_segment.move(last_position, duration)
	return super.move(pos, duration)
