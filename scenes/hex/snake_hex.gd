class_name SnakeHex
extends ObjectHex

@onready var map = get_parent()

var prev_segment : SnakeHex = null
var next_segment : SnakeHex = null

func _process(_delta: float) -> void:
	queue_redraw() # required for the segment lines to render

func _draw() -> void:
	if next_segment:
		draw_line(Vector2.ZERO, to_local(next_segment.global_position), modulate, 1)

# overrides ObjectHex.move()
func move(to_coords : Vector2, duration := 0.25) -> Tween:
	if next_segment:
		next_segment.move(grid_coords, duration)
	return super.move(to_coords, duration)
