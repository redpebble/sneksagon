extends Node2D

signal move_action_pressed

enum input_types {MOUSE, KEYBOARD, CONTROLLER}
@export var input_type := input_types.MOUSE

var move_timeout : SceneTreeTimer = null
var key_input_queue : Array[String] = []

func _process(_delta: float) -> void:
	update_key_input_queue()
	if Input.is_action_pressed("move"):
		if move_timeout == null or move_timeout.time_left == 0:
			move_action_pressed.emit()
			move_timeout = get_tree().create_timer(0.01)


func update_key_input_queue():
	for i in MapManager.directions.keys():
		if Input.is_action_just_pressed(i):
			if !key_input_queue.has(i):
				key_input_queue.append(i)
		elif Input.is_action_just_released(i):
			key_input_queue.erase(i)

func get_input_vector() -> Vector2:
	var input_vector = Vector2.ZERO
	
	match input_type:
		input_types.MOUSE:
			if InputEventMouseMotion:
				var from_pos = get_parent().global_position
				input_vector = get_mouse_input_vector(from_pos)
		input_types.KEYBOARD:
			input_vector = get_keyboard_input_vector()
		input_types.CONTROLLER:
			input_vector = get_joystick_input_vector()
	
	return input_vector

func get_mouse_input_vector(from_pos : Vector2) -> Vector2:
	var v = Vector2.ZERO
	var mouse_pos = get_global_mouse_position()
	var min_dist = MapManager.get_hex_width() * 0.2
	if from_pos.distance_to(mouse_pos) > min_dist:
		v = from_pos.direction_to(mouse_pos)
	return v 

func get_joystick_input_vector(deadzone := 0.5) -> Vector2:
	var x = Input.get_axis("joystick_left", "joystick_right")
	var y = Input.get_axis("joystick_up", "joystick_down")
	var v = Vector2(x, y)
	if v.length() < deadzone:
		v = Vector2.ZERO
	return v

func get_keyboard_input_vector() -> Vector2:
	var v = Vector2.ZERO
	if key_input_queue.size() > 0:
		# set the vector to the most recently queued direction
		v = MapManager.directions.get(key_input_queue[-1])
	return v
