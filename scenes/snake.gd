class_name Snake
extends Node2D


@onready var map = get_parent()

var head : SnakeHex = null
var max_length := 5


func _ready() -> void:
	z_index = 10 #place above highlight

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
	var show_highlight : bool = (get_move_position() != global_position)
	Highlighter.highlight_position(get_move_position(), show_highlight)

func get_move_position() -> Vector2:
	return map.get_move_position(head, round_hexagonal(get_input_vector()))
func get_input_vector() -> Vector2:
	var mouse_input_vector := head.global_position.direction_to(get_global_mouse_position())
	return mouse_input_vector

func move(duration := 0.25) -> void:
	if head.move_tween:
		head.move_tween.kill()
	var move_position = get_move_position()
	extend()
	head.move(move_position, duration)


func round_hexagonal(base_vector) -> Vector2:
	var hex_direction : Vector2
	hex_direction.x = roundi(base_vector.x)
	#max out vertical input to eliminate "sticky" horizontal movement
	hex_direction.y = ceili(abs(base_vector.y)) * sign(base_vector.y)
	#move when holding mouse button
	return hex_direction


func extend() -> void:
	var tail := get_tail()
	if tail:
		var new_hex : SnakeHex = map.create_hex(map.mover_hex_scn, map.get_hex_coords(tail.last_position), modulate)
		tail.next_segment = new_hex
		new_hex.prev_segment = tail

func make_head(hex_coords : Vector2) -> void:
	head = map.create_hex(map.mover_hex_scn, hex_coords, modulate)

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
