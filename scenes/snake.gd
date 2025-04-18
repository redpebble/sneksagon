class_name Snake
extends Node2D

@export var color := Color.BLACK
@onready var map = get_parent()

var snake_hex_scene = preload("res://scenes/hex/snake_hex.tscn")

var head : SnakeHex = null


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
	var to_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, round_hexagonal(get_input_vector()))
	Highlighter.highlight_coords(to_coords, is_valid_move(to_coords))

func get_input_vector() -> Vector2:
	var head_pos = head.global_position
	var mouse_pos = get_global_mouse_position()

	if head_pos.distance_to(mouse_pos) < MapManager.HEX_WIDTH / 2.0:
		return Vector2.ZERO
	
	return head_pos.direction_to(mouse_pos)

func is_valid_move(to_coords: Vector2) -> bool:
	if to_coords == head.grid_coords || !MapManager.valid_coords.has(to_coords):
		return false
	
	var entities = MapManager.entities.get(to_coords)
	if entities:
		for e in entities:
			if e is SnakeHex && e != get_tail():
				return false
	
	return true

func move(duration := 0.25) -> void:
	if head.move_tween:
		head.move_tween.kill()
	var to_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, round_hexagonal(get_input_vector()))

	if !is_valid_move(to_coords):
		return

	var entities = MapManager.entities.get(to_coords)
	if entities:
		for e in entities:
			if e is AppleHex:
				extend()
				e.eat()
	
	head.move(to_coords, duration)

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
		var new_hex : SnakeHex = MapManager.create_hex(snake_hex_scene.instantiate(), tail.grid_coords, color)
		tail.next_segment = new_hex
		new_hex.prev_segment = tail

func make_head(hex_coords : Vector2) -> void:
	head = MapManager.create_hex(snake_hex_scene.instantiate(), hex_coords, color.lightened(0.15))

func get_tail() -> SnakeHex:
	var current_hex := head
	while current_hex.next_segment != null:
		current_hex = current_hex.next_segment
	return current_hex

func get_length() -> int:
	var current_hex := head
	var length = 0
	while current_hex != null:
		length += 1
		current_hex = current_hex.next_segment
	return length
