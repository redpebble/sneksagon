class_name SnakeHex
extends ObjectHex

signal bump_finished

@onready var map = get_parent()

var prev_segment : SnakeHex = null
var next_segment : SnakeHex = null

func _process(_delta: float) -> void:
	queue_redraw() # required for the segment lines to render

func _draw() -> void:
	if next_segment:
		draw_line(Vector2.ZERO, to_local(next_segment.global_position), modulate, 1)

# overrides ObjectHex.move()
func move(to_coords : Vector2, duration := 0.3) -> Tween:
	if next_segment:
		next_segment.move(grid_coords, duration)
	return super.move(to_coords, duration)

func bump(to_coords : Vector2, amount : float, duration : float):
	var bump_tween = create_tween().set_trans(Tween.TRANS_SINE)
	var initial_pos = MapManager.get_hex_world_position(grid_coords)
	var bump_pos = MapManager.get_hex_world_position(to_coords)
	var bump_vector = initial_pos.direction_to(bump_pos) * amount
	
	bump_tween.set_ease(Tween.EASE_IN)
	bump_tween.tween_property(self, "global_position", initial_pos + bump_vector, duration * 0.5)
	bump_tween.set_trans(Tween.TRANS_LINEAR)
	bump_tween.tween_property(self, "global_position", initial_pos - (bump_vector * 0.3), duration * 0.5)
	bump_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	bump_tween.tween_property(self, "global_position", initial_pos, duration * 0.3)
	bump_tween.finished.connect(_on_bump_tween_finished)
	
	var segment_interval := 0.04
	await get_tree().create_timer(segment_interval).timeout
	if next_segment:
		next_segment.bump(grid_coords, amount, duration)

func _on_bump_tween_finished():
	bump_finished.emit()
