class_name SnakeHex
extends ObjectHex

signal move_finished

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

func chain_bump(to_coords : Vector2, amount : float, duration : float):
	var initial_pos = MapManager.get_hex_world_position(grid_coords)
	var bump_pos = MapManager.get_hex_world_position(to_coords)
	var bump_vector = initial_pos.direction_to(bump_pos) * amount
	
	if move_tween:
		move_tween.kill()
	move_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	move_tween.tween_property(self, "global_position", initial_pos + bump_vector, duration * 0.5)
	move_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "global_position", initial_pos - (bump_vector * 0.3), duration * 0.4)
	move_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	move_tween.tween_property(self, "global_position", initial_pos, duration * 0.5)
	move_tween.finished.connect(_on_move_tween_finished)
	
	var delay_inteval := 0.04
	await get_tree().create_timer(delay_inteval).timeout
	if next_segment:
		next_segment.chain_bump(grid_coords, amount, duration)

func _on_move_tween_finished():
	move_finished.emit()

func chain_is_moving() -> bool:
	var tweening = move_tween and move_tween.is_running()
	if not tweening and next_segment != null:
		tweening = next_segment.chain_is_moving()
	return tweening
