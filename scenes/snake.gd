class_name Snake
extends Node2D

signal collided
signal died

@export var color := Color.BLACK
@export var base_move_interval : float = 0.2 # seconds
@export var automatic_movement := false

@onready var move_interval := base_move_interval
@onready var map = MapManager.map_node
@onready var move_sfx = $MoveSFX
@onready var collide_sfx = $CollideSFX
@onready var move_timer = $MoveTimer
@onready var input_parser = $InputParser
@onready var fangs = $HeadCosmetics/Fangs
@onready var eye = $HeadCosmetics/Eye

var snake_hex_scene = preload("res://scenes/hex/snake_hex.tscn")
var head : SnakeHex = null
var move_vector := Vector2.ZERO

func _ready() -> void:
	input_parser.move_action_pressed.connect(_on_move_action_pressed)
	move_timer.timeout.connect(_on_move_timer_timeout)

func _process(_delta: float) -> void:
	if head:
		global_position = head.global_position
	if not is_moving():
		update_move_vector()
		update_highlight()
	update_eye_target()

func update_highlight():
	var show_highlight : = true
	var to_coords := Vector2.ZERO
	if head:
		to_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, move_vector)
		show_highlight = is_valid_coords(to_coords)
	Highlighter.highlight_coords(to_coords, show_highlight)

func update_eye_target():
	var target_vector := Vector2.ZERO
	var to_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, move_vector)
	var coords_pos = MapManager.get_hex_world_position(to_coords)
	
	match input_parser.input_type:
		input_parser.input_types.MOUSE:
			target_vector = get_global_mouse_position()
		input_parser.input_types.CONTROLLER:
			var raw_joystick_input : Vector2 = input_parser.get_joystick_input_vector(0.1)
			var proxy_direction = raw_joystick_input.normalized()
			var proxy_distance = eye.max_target_distance
			
			if input_parser.get_joystick_input_vector() == Vector2.ZERO:
				# reduce look strength when input is not registered as movement
				proxy_distance *= 0.2
			else:
				# snap to intended move direction
				var coords_direction = global_position.direction_to(coords_pos)
				var angle_diff = coords_direction.dot(proxy_direction)
				var snap_weight = ease(remap(angle_diff, 0.7, 1.0, 0.0, 1.0), 1.4)
				proxy_direction = proxy_direction.slerp(coords_direction, snap_weight)
			
			var proxy_offset = proxy_direction * proxy_distance
			target_vector = eye.global_position + proxy_offset
		_:
			target_vector = coords_pos
	
	eye.target_vector = target_vector

# TRAVERSAL -------------------------------------------------------------------------------------- #

func update_move_vector():
	var potential_vector = get_closest_valid_vector(input_parser.get_input_vector())
	if potential_vector != Vector2.ZERO:
		move_vector = potential_vector

func _on_move_timer_timeout():
	if not automatic_movement:
		return
	move()

func _on_move_action_pressed():
	if not automatic_movement:
		move()

func move() -> void:
	if is_moving():
		return
	var to_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, move_vector)
	var collision_flags = handle_collisions(to_coords)
	
	# BUMP
	if collision_flags[1] == true:
		collide(to_coords, move_interval, collision_flags[0])
	# NORMAL MOVEMENT
	else:
		move_sfx.play_random()
		var move_action = head.propagate.bind(head.move.bind(to_coords, move_interval))
		MapManager.action_queue.queue(move_action, 2)
	
	if automatic_movement:
		move_timer.start(move_interval * 2)
	
	var dest_position = MapManager.get_hex_world_position(to_coords)
	var move_direction = global_position.direction_to(dest_position)
	fangs.match_rotation_to(move_direction)

func is_moving() -> bool:
	if head:
		return head.is_chain_tweening()
	else:
		return false

## Checks if the coordinates are part of the map
## and are not "behind" the head.
func is_valid_coords(to_coords: Vector2) -> bool:
	var invalid_coords = [head.grid_coords]
	if get_length() > 1:
		invalid_coords.append(head.last_coords)
	
	return not invalid_coords.has(to_coords)

## Checks for valid vectors, starting from the input vector, alternating sides for each check
## Returns the closest vector which would move to a valid coordinate
func get_closest_valid_vector(input_vector : Vector2):
	var closest := Vector2.ZERO
	var angle_interval = PI/3
	var raw_input_angle = input_vector.angle()
	var adjusted_input_angle = input_vector.rotated(angle_interval).angle()
	# gets the distance from the nearest hexagonal move direction, offset to center the value at 0
	var side_favor = abs(fmod(angle_difference(angle_interval, adjusted_input_angle), angle_interval)) - PI/6
	var side_flip : int = 1 if side_favor < 0 else -1
	# left and right sides are inverted when the input is directed upward
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

## Converts a vector to a hexagonal direction.
func round_hexagonal(base_vector) -> Vector2:
	var hex_direction : Vector2
	hex_direction.x = roundi(base_vector.x)
	# max out vertical input to eliminate "sticky" horizontal movement
	hex_direction.y = ceili(abs(base_vector.y)) * sign(base_vector.y)
	# default to the last move vector if the base vector is perfectly left or right
	if hex_direction == Vector2.LEFT or hex_direction == Vector2.RIGHT:
		hex_direction = move_vector
	return hex_direction

## Executes specific logic per entity type and
## returns collision flags: [hit_wall, bump]
func handle_collisions(to_coords : Vector2) -> Array:
	var hit_wall := false
	var bump := false
	var entities_at_coords = MapManager.entities.get(to_coords)
	var map_has_coords = MapManager.valid_coords.has(to_coords)
	
	if not map_has_coords:
		hit_wall = true
		bump = true
	elif entities_at_coords:
		for e in entities_at_coords:
			var is_body_part = e is SnakeHex and e != get_tail()
			var is_obstacle = is_body_part or e is BlockHex
			var is_collectable = e is AppleHex and not e.collected
			
			if is_body_part:
				# detach segments after collision point
				detach_at(e)
			
			if is_collectable:
				MapManager.action_queue.queue(e.eat, 1)
				MapManager.action_queue.queue(extend, 3)
				head.propagate(head.swell.bind(1.15, 0.3), 0.15)
				fangs.close()
			
			if is_obstacle:
				bump = true
	
	return [hit_wall, bump]

func collide(collision_coords : Vector2, duration : float, hit_wall : bool):
	var bump_distance = MapManager.get_hex_width() * 0.25
	if hit_wall:
		# only animate the head bumping
		head.bump(collision_coords, bump_distance, duration)
		detach_at(head.next_segment)
	else:
		head.propagate(head.bump.bind(collision_coords, bump_distance, duration), 0.03)
	
	eye.start_spin(duration)
	
	collide_sfx.play_random()
	collided.emit()

## Stops current motion and emits the "died" signal
func die():
	move_timer.stop()
	move_vector = Vector2.ZERO
	died.emit()

# SEGMENT CONTROL -------------------------------------------------------------------------------- #

## Creates the base segment of a snake at the given coordinates.
func make_head(hex_coords : Vector2) -> void:
	var s = snake_hex_scene.instantiate()
	var c = hex_coords
	var l = MapManager.Layers.ENTITIES
	head = MapManager.create_hex(s, c, l, color.lightened(0.15))
	head.set_shape_state(0)
	if automatic_movement:
		move_timer.start(move_interval)

## Creates a new segment at the tail's grid coordinates.
func extend() -> void:
	var tail := get_tail()
	if tail:
		var s = snake_hex_scene.instantiate()
		var c = tail.grid_coords
		var l = MapManager.Layers.ENTITIES
		var new_hex : SnakeHex = MapManager.create_hex(s, c, l, color)
		new_hex.set_shape_state(2)
		tail.next_segment = new_hex
		new_hex.prev_segment = tail
		print("extended")

## Detaches the given segment and all that follow it.
func detach_at(segment : SnakeHex):
	if segment and segment != head:
		segment.propagate(segment.detach.bind(0.15), 0.04)

## Gets the snake's last segment.
func get_tail() -> SnakeHex:
	var current_hex := head
	while current_hex.next_segment != null:
		current_hex = current_hex.next_segment
	return current_hex

## Returns the number of sequential segments connected to the head.
func get_length() -> int:
	var current_hex := head
	var length = 0
	while current_hex != null:
		length += 1
		current_hex = current_hex.next_segment
	return length
