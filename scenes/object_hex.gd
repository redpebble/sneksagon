class_name ObjectHex
extends Hex

signal moved(hex_node, from_pos, to_pos)

@export var connect_segments := true
@onready var last_coords := grid_coords

var move_tween : Tween = null


func _ready() -> void:
	z_index = 10
	scale *= 0.8

func _process(_delta: float) -> void:
	queue_redraw()

func move(to_coords : Vector2, duration := 0.25) -> Tween:
	if move_tween:
		move_tween.kill()
	
	last_coords = grid_coords
	# do not "move" if position would not change
	if to_coords == last_coords:
		return
	move_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	move_tween.tween_property(self, "global_position", MapManager.get_hex_world_position(to_coords), duration)
	
	moved.emit(self, last_coords, to_coords)
	grid_coords = to_coords
	return move_tween

func set_color(col : Color):
	modulate = col
