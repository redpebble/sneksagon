class_name ObjectHex
extends Hex

signal moved(hex_node, from_pos, to_pos)
signal bump_finished

@onready var last_coords := grid_coords

var move_tween : Tween = null

func _ready() -> void:
	scale_factor = 0.75
	z_index = 10
	super()

func move(to_coords : Vector2, duration := 0.3) -> bool:
	if to_coords == grid_coords:
		return false
	
	#if move_tween:
		#move_tween.kill()
	move_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	move_tween.tween_property(self, "global_position", MapManager.get_hex_world_position(to_coords), duration)
	
	last_coords = grid_coords
	grid_coords = to_coords
	moved.emit(self, last_coords, grid_coords)
	print("moved")
	return true

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

func _on_bump_tween_finished():
	bump_finished.emit()

func set_color(col : Color):
	modulate = col
