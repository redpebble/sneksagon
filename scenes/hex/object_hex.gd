class_name ObjectHex
extends Hex

signal moved(hex_node, from_pos, to_pos)
signal bump_finished

@onready var last_coords := grid_coords
@onready var original_color := modulate

var scale_factor = 0.8

var move_tween : Tween = null
var scale_tween : Tween = null

func _ready() -> void:
	z_index = 10
	scale *= scale_factor

func move(to_coords : Vector2, duration := 0.3) -> Tween:
	if move_tween:
		move_tween.kill()
	
	last_coords = grid_coords
	# do not "move" if position would not change
	if to_coords == last_coords:
		return null
	move_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	move_tween.tween_property(self, "global_position", MapManager.get_hex_world_position(to_coords), duration)
	
	moved.emit(self, last_coords, to_coords)
	grid_coords = to_coords
	return move_tween

func bump(to_coords : Vector2, amount : float, duration : float):
	var initial_pos = MapManager.get_hex_world_position(grid_coords)
	var bump_pos = MapManager.get_hex_world_position(to_coords)
	var bump_vector = initial_pos.direction_to(bump_pos) * amount
	
	if move_tween:
		move_tween.kill()
	move_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	move_tween.tween_property(self, "global_position", initial_pos + bump_vector, duration * 0.3)
	move_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "global_position", initial_pos - (bump_vector * 0.3), duration * 0.4)
	move_tween.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN_OUT)
	move_tween.tween_property(self, "global_position", initial_pos, duration * 0.5)
	move_tween.finished.connect(_on_bump_tween_finished)

func pulse(scale_multiplier : float, duration : float):
	if scale_tween:
		scale_tween.kill()
	var original_scale = Vector2.ONE * MapManager.hex_scale * scale_factor
	scale_tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	scale_tween.tween_property(self, "scale", original_scale * scale_multiplier, duration * 0.5)
	#scale_tween.parallel().tween_property(self, "modulate", original_color.lightened(0.1), duration * 0.5)
	scale_tween.tween_property(self, "scale", original_scale, duration * 0.5)
	#scale_tween.parallel().tween_property(self, "modulate", original_color, duration * 0.5)

func _on_bump_tween_finished():
	bump_finished.emit()

func set_color(col : Color):
	modulate = col
