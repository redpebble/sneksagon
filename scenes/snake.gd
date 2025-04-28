class_name Snake
extends Node2D

signal died

@export var color := Color.BLACK
@export var base_move_interval : float = 0.5 # seconds
@export var automatic_movement := false
@onready var map = get_parent()
@onready var move_sfx = $MoveSFX
@onready var move_timer = $MoveTimer

var snake_hex_scene = preload("res://scenes/hex/snake_hex.tscn")
var head : SnakeHex = null
var move_interval := base_move_interval
var move_vector := Vector2.ZERO

func _ready() -> void:
	move_timer.wait_time = move_interval
	move_timer.timeout.connect(_on_move_timer_timeout)

func _process(_delta: float) -> void:
	if automatic_movement:
		update_highlight(move_vector)
	elif not is_moving():
		update_highlight(get_input_vector())
		if head:
			read_inputs()
	queue_redraw()


## INPUT RESPONSE ##
func read_inputs():
	move_vector = get_input_vector()
	
	if Input.is_action_pressed("lmb"):
		if move_vector != Vector2.ZERO:
			var to_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, move_vector)
			move(to_coords, move_interval)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		move_vector = get_input_vector()

func _on_move_timer_timeout():
	if not automatic_movement:
		return
	
	var to_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, move_vector)
	move(to_coords, move_interval)

func update_highlight(intended_direction : Vector2):
	var show_highlight : = true
	var to_coords := Vector2.ZERO
	if head == null:
		show_highlight = false
	else:
		to_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, intended_direction)
		show_highlight = is_valid_move(to_coords)
	Highlighter.highlight_coords(to_coords, show_highlight)

func get_input_vector() -> Vector2:
	if not head:
		return Vector2.ZERO
	
	var head_pos = MapManager.get_hex_world_position(head.last_coords)
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
	if !is_valid_move(to_coords):
		return
	
	var alive = handle_collisions(to_coords)
	
	move_sfx.play_random()
	print("alive: ", alive)
	head.move(to_coords, duration)
	await move_timer.timeout
	if not alive:
		print("died")
		died.emit()

func is_valid_move(to_coords: Vector2) -> bool:
	var invalid_coords = [head.grid_coords]
	# no backward movement if larger than one segment
	if get_length() > 1:
		invalid_coords.append(head.last_coords)
	
	if invalid_coords.has(to_coords):
		return false
	return true

func is_moving():
	return head and head.move_tween and head.move_tween.is_running()

func handle_collisions(to_coords : Vector2) -> bool:
	var alive := true
	var entities_at_coords = MapManager.entities.get(to_coords)
	var map_has_coords = MapManager.valid_coords.has(to_coords)
	print(map_has_coords)
	if not map_has_coords:
		alive = false
	elif entities_at_coords:
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
	move_timer.start(move_interval)

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
