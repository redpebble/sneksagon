class_name Snake
extends Node2D

signal died

@export var color := Color.BLACK
@onready var map = get_parent()
@onready var move_sfx = $MoveSFX

var snake_hex_scene = preload("res://scenes/hex/snake_hex.tscn")
var head : SnakeHex = null


func _process(_delta: float) -> void:
	if not is_moving():
		update_highlight()
		if head:
			read_inputs()
	queue_redraw()


## INPUT RESPONSE ##
func read_inputs():
	var input_vector = get_input_vector()
	var to_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, input_vector)
	
	if Input.is_action_pressed("lmb"):
		if input_vector != Vector2.ZERO:
			move(to_coords, 0.3)
			move_sfx.play_random()

func update_highlight():
	var show_highlight : = true
	var to_coords := Vector2.ZERO
	if head == null:
		show_highlight = false
	else:
		to_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, get_input_vector())
		show_highlight = is_valid_move(to_coords)
	Highlighter.highlight_coords(to_coords, show_highlight)

func get_input_vector() -> Vector2:
	var head_pos = head.global_position
	var mouse_pos = get_global_mouse_position()
	var min_dist = MapManager.HEX_WIDTH / 2.0
	
	if head_pos.distance_to(mouse_pos) < min_dist:
		return Vector2.ZERO
	
	return round_hexagonal(head.global_position.direction_to(mouse_pos))

func round_hexagonal(base_vector) -> Vector2:
	var hex_direction : Vector2
	hex_direction.x = roundi(base_vector.x)
	#max out vertical input to eliminate "sticky" horizontal movement
	hex_direction.y = ceili(abs(base_vector.y)) * sign(base_vector.y)
	#move when holding mouse button
	return hex_direction


## TRAVERSAL ##
func move(to_coords : Vector2, duration := 0.25) -> void:
	if head.move_tween:
		head.move_tween.kill()
	if !is_valid_move(to_coords):
		return
	
	var alive = handle_collisions(to_coords)
	
	await head.move(to_coords, duration).finished
	
	if not alive:
		died.emit()

func is_valid_move(to_coords: Vector2) -> bool:
	var invalid_coords = [head.grid_coords]
	# no backward movement if larger than one segment
	if get_length() > 1:
		invalid_coords.append(head.last_coords)
	
	if invalid_coords.has(to_coords) || !MapManager.valid_coords.has(to_coords):
		return false
	return true

func is_moving():
	return head and head.move_tween and head.move_tween.is_running()

func handle_collisions(to_coords : Vector2) -> bool:
	var alive := true
	var entities_at_coords = MapManager.entities.get(to_coords)
	if entities_at_coords:
		for e in entities_at_coords:
			if e is SnakeHex && e != get_tail() and get_length() > 2:
				alive = false
			if e is AppleHex and not e.collected:
				extend()
				e.eat()
	return alive


## SEGMENT CONTROL ##
func make_head(hex_coords : Vector2) -> void:
	head = MapManager.create_hex(snake_hex_scene.instantiate(), hex_coords, color.lightened(0.15))

func extend() -> void:
	var tail := get_tail()
	if tail:
		var new_hex : SnakeHex = MapManager.create_hex(snake_hex_scene.instantiate(), tail.grid_coords, color)
		tail.next_segment = new_hex
		new_hex.prev_segment = tail

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
