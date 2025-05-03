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
	if Input.is_action_pressed("lmb"):
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
	
	var potential_coords = MapManager.get_adjacent_hex_coords(head.grid_coords, input_vector)
	if is_valid_coords(potential_coords):
		move_vector = input_vector

func get_mouse_input_vector() -> Vector2:
	var v = Vector2.ZERO
	if head:
		var head_pos = MapManager.get_hex_world_position(head.grid_coords)
		var mouse_pos = get_global_mouse_position()
		var min_dist = MapManager.HEX_WIDTH * 0.2
		if head_pos.distance_to(mouse_pos) > min_dist:
			v = head_pos.direction_to(mouse_pos)
	return round_hexagonal(v)

func get_joystick_input_vector():
	var v = Vector2.ZERO
	var x = Input.get_axis("joystick-left", "joystick-right")
	var y = Input.get_axis("joystick-up", "joystick-down")
	if v.length() > 0.5:
		v = Vector2(x, y)
	return round_hexagonal(v)

func get_keyboard_input_vector(event : InputEvent):
	var v = Vector2.ZERO
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
	head.bump(collision_coords, 40, duration * 0.9)
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
