class_name Snake
extends Node2D

signal collided
signal died

@export var color := Color.BLACK
@export var base_move_interval : float = 0.2 # seconds
@export var automatic_movement := false
@export var input_type := 0 # 0 - mouse, 1 - keyboard, 2 - controller

@onready var move_interval := base_move_interval
@onready var map = get_parent()
@onready var move_sfx = $MoveSFX
@onready var move_timer = $MoveTimer

var snake_hex_scene = preload("res://scenes/hex/snake_hex.tscn")
var head : SnakeHex = null
var move_vector := Vector2.ZERO

func _ready() -> void:
	move_timer.wait_time = move_interval
	move_timer.one_shot = true
	move_timer.timeout.connect(_on_move_timer_timeout)
	

func _process(_delta: float) -> void:
	if not is_moving():
		update_highlight()
		if not automatic_movement:
			read_inputs()
	queue_redraw()

func read_inputs():
	if is_moving():
		return
	if Input.is_action_pressed("move"):
		if move_vector != Vector2.ZERO:
			var to_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, move_vector)
			move(to_coords, move_interval)

func _input(event: InputEvent) -> void:
	if head == null:
		return
	
	var input_vector = Vector2.ZERO
	match input_type:
		0: # mouse
			if InputEventMouseMotion:
				input_vector = get_mouse_input_vector()
		1: # keyboard
			input_vector = get_keyboard_input_vector(event)
		2: # controller
			input_vector = get_joystick_input_vector()
	
	var potential_vector = get_closest_valid_vector(input_vector)
	if potential_vector != Vector2.ZERO:
		move_vector = potential_vector

func get_mouse_input_vector() -> Vector2:
	var v = Vector2.ZERO
	if head:
		var head_pos = MapManager.get_hex_world_position(head.grid_coords)
		var mouse_pos = get_global_mouse_position()
		var min_dist = MapManager.HEX_WIDTH * 0.2
		if head_pos.distance_to(mouse_pos) > min_dist:
			v = head_pos.direction_to(mouse_pos)
	return v

func get_joystick_input_vector():
	var x = Input.get_axis("joystick-left", "joystick-right")
	var y = Input.get_axis("joystick-up", "joystick-down")
	var v = Vector2(x, y)
	# set input deadzone
	if v.length() < 0.5:
		v = Vector2.ZERO
	return v

func get_keyboard_input_vector(event : InputEvent):
	var v = Vector2.ZERO
	if event.is_pressed():
		match get_event_action(event):
			"up-left":    v = Vector2.UP + Vector2.LEFT
			"up":         v = Vector2.UP
			"up-right":   v = Vector2.UP + Vector2.RIGHT
			"down-left":  v = Vector2.DOWN + Vector2.LEFT
			"down":       v = Vector2.DOWN
			"down-right": v = Vector2.DOWN + Vector2.RIGHT
	return v

# https://forum.godotengine.org/t/how-to-get-action-name-from-event/44909/2
func get_event_action(event: InputEvent):
	var x: Array[StringName] = InputMap.get_actions()
	for a in x:
		if event.is_action(a):
			return a
	return null

func update_highlight():
	var show_highlight : = true
	var to_coords := Vector2.ZERO
	if head:
		to_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, move_vector)
		show_highlight = is_valid_coords(to_coords)
	Highlighter.highlight_coords(to_coords, show_highlight)

func round_hexagonal(base_vector) -> Vector2:
	var hex_direction : Vector2
	hex_direction.x = roundi(base_vector.x)
	#max out vertical input to eliminate "sticky" horizontal movement
	hex_direction.y = ceili(abs(base_vector.y)) * sign(base_vector.y)
	# default to the last move vector if the base vector is perfectly left or right
	if hex_direction == Vector2.LEFT or hex_direction == Vector2.RIGHT:
		hex_direction = move_vector
	return hex_direction


## TRAVERSAL ##
func _on_move_timer_timeout():
	if not automatic_movement:
		return
	var to_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, move_vector)
	move(to_coords, move_interval)

func move(to_coords : Vector2, duration := 0.3) -> void:
	var alive = handle_collisions(to_coords)
	
	if alive:
		move_sfx.play_random()
		var move_tween = head.move(to_coords, duration)
		if move_tween:
			await move_tween.finished
		if automatic_movement:
			move_timer.start(duration)
	else:
		collide(to_coords, duration)

func is_valid_coords(to_coords: Vector2) -> bool:
	var invalid_coords = [head.grid_coords]
	# no backward movement if larger than one segment
	if get_length() > 1:
		invalid_coords.append(head.last_coords)
	
	return not invalid_coords.has(to_coords)

# Checks for valid vectors, starting from the input vector, alternating sides for each check
# Returns the closest vector which would move to a valid coordinate
func get_closest_valid_vector(input_vector : Vector2):
	var closest := Vector2.ZERO
	var angle_interval = PI/3
	var raw_input_angle = input_vector.angle()
	var adjusted_input_angle = input_vector.rotated(angle_interval).angle()
	# gets the distance from the nearest hexagonal move direction, offset to center the value at 0
	var side_favor = abs(fmod(angle_difference(angle_interval, adjusted_input_angle), angle_interval)) - PI/6
	var side_flip : int = 1 if side_favor < 0 else -1
	# reverse flipping on negative input angles
	if raw_input_angle < 0:
		side_flip *= -1
	
	for i in 6: # check each direction
		side_flip *= 1 if (i % 2) else -1 # alternate sides
		var rotation_amount = i * angle_interval * side_flip
		var potential_vector = round_hexagonal(input_vector.normalized().rotated(rotation_amount))
		var potential_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, potential_vector)
		if is_valid_coords(potential_coords):
			closest = potential_vector
			break
	return closest

func is_moving() -> bool:
	if head:
		return head.chain_is_moving()
	else:
		return false

func handle_collisions(to_coords : Vector2) -> bool:
	var alive := true
	var entities_at_coords = MapManager.entities.get(to_coords)
	var map_has_coords = MapManager.valid_coords.has(to_coords)
	
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

func collide(collision_coords : Vector2, duration : float):
	get_tail().move_finished.connect(die)
	head.chain_bump(collision_coords, 30, duration * 0.8)
	collided.emit()

func die():
	get_tail().move_finished.disconnect(die)
	move_timer.stop()
	move_vector = Vector2.ZERO
	died.emit()


## SEGMENT CONTROL ##
func make_head(hex_coords : Vector2) -> void:
	head = MapManager.create_hex(snake_hex_scene.instantiate(), hex_coords, color.lightened(0.15))
	if automatic_movement:
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
