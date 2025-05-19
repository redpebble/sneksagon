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
	queue_redraw()

func update_move_vector():
	var potential_vector = get_closest_valid_vector(input_parser.get_input_vector())
	if potential_vector != Vector2.ZERO:
		move_vector = potential_vector

func update_highlight():
	var show_highlight : = true
	var to_coords := Vector2.ZERO
	if head:
		to_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, move_vector)
		show_highlight = is_valid_coords(to_coords)
	Highlighter.highlight_coords(to_coords, show_highlight)


## TRAVERSAL ##
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
		head.chain_anim(head.move.bind(to_coords, move_interval))
		if automatic_movement:
			move_timer.start(move_interval)

func is_moving() -> bool:
	if head:
		return head.is_chain_tweening()
	else:
		return false

## Checks if the coordinates are part of the map
## and are not "behind" the head.
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
	
func round_hexagonal(base_vector) -> Vector2:
	var hex_direction : Vector2
	hex_direction.x = roundi(base_vector.x)
	#max out vertical input to eliminate "sticky" horizontal movement
	hex_direction.y = ceili(abs(base_vector.y)) * sign(base_vector.y)
	# default to the last move vector if the base vector is perfectly left or right
	if hex_direction == Vector2.LEFT or hex_direction == Vector2.RIGHT:
		hex_direction = move_vector
	return hex_direction

## Returns and array of flags for the collision:
## [dead, bump]
func handle_collisions(to_coords : Vector2) -> Array:
	var dead := false
	var bump := false
	var entities_at_coords = MapManager.entities.get(to_coords)
	var map_has_coords = MapManager.valid_coords.has(to_coords)
	
	if not map_has_coords:
		print("moved off map")
		dead = true
		bump = true
	elif entities_at_coords:
		for e in entities_at_coords:
			var is_body_part = e is SnakeHex && e != get_tail() and get_length() > 2
			var is_obstacle = is_body_part or e is BlockHex
			var is_collectable = e is AppleHex and not e.collected
			
			if is_body_part:
				e.chain_anim(e.detach, 0.05)
				print("hit body")
				dead = true
			
			if is_collectable:
				head.chain_anim(head.pulse.bind(1.15, 0.3), 0.15)
				e.eat()
				extend()
			
			if is_obstacle:
				bump = true
	
	return [dead, bump]

func collide(collision_coords : Vector2, duration : float, dead : bool):
	if dead:
		get_tail().bump_finished.connect(die)
	var bump_distance = MapManager.get_hex_width() * 0.25
	head.chain_anim(head.bump.bind(collision_coords, bump_distance, duration), 0.03)
	collide_sfx.play_random()
	collided.emit()

func die():
	get_tail().bump_finished.disconnect(die)
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
