class_name Snake
extends Node2D

@export var color := Color.BLACK
@onready var map = get_parent()

var head : SnakeHex = null
var max_length := 5


#func _ready() -> void:
	#z_index = 10 #place above highlight

func _process(_delta: float) -> void:
	read_inputs()
	queue_redraw()

func read_inputs():
	if head and head.move_tween and head.move_tween.is_running():
		return
	update_highlight()
	if Input.is_action_pressed("lmb"):
		move()

func update_highlight():
	var show_highlight : bool = (get_move_position() != head.global_position)
	Highlighter.highlight_position(get_move_position(), show_highlight)

func get_move_position() -> Vector2:
	var head_pos := head.global_position
	var move_pos := head_pos
	var potential_pos = map.get_move_position(head, round_hexagonal(get_input_vector()))
	if potential_pos != head_pos:
		move_pos = potential_pos
	return move_pos

func get_input_vector() -> Vector2:
	var mouse_input_vector := head.global_position.direction_to(get_global_mouse_position())
	return mouse_input_vector

func move(duration := 0.25) -> void:
	if head.move_tween:
		head.move_tween.kill()
	var to_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, round_hexagonal(get_input_vector()))
	if to_coords != head.grid_coords:
		extend()
		head.move(to_coords, duration)

func round_hexagonal(base_vector) -> Vector2:
	var hex_direction : Vector2
	hex_direction.x = roundi(base_vector.x)
	#max out vertical input to eliminate "sticky" horizontal movement
	hex_direction.y = ceili(abs(base_vector.y)) * sign(base_vector.y)
	#move when holding mouse button
	return hex_direction

func extend() -> void:
	if get_length() >= max_length : return
	var tail := get_tail()
	if tail:
		var new_hex : SnakeHex = map.create_hex(map.mover_hex_scn, tail.last_coords, color)
		tail.next_segment = new_hex
		new_hex.prev_segment = tail

func make_head(hex_coords : Vector2) -> void:
	head = map.create_hex(map.mover_hex_scn, hex_coords, color)

func get_tail() -> SnakeHex:
	var current_hex := head
	while current_hex.next_segment != null:
		current_hex = current_hex.next_segment
	return current_hex

# returns the length from the calling segment to the end of the chain
func get_length() -> int:
	var current_hex := head
	var length = 0
	while current_hex != null:
		length += 1
		current_hex = current_hex.next_segment
	return length
