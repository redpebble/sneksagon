class_name MoverHex
extends Hex

signal moved(hex_node, from_pos, to_pos)

@export var connect_segments := true

@onready var map = get_parent()
@onready var last_position := global_position

var head : MoverHex = self
var prev_segment : MoverHex = null
var next_segment : MoverHex = null
var move_tween : Tween = null
var max_length := 5


func _ready() -> void:
	z_index = 10
	if prev_segment == null:
		head = self
	scale *= 0.8

func _process(_delta: float) -> void:
	read_inputs()
	queue_redraw()

func _draw() -> void:
	if not connect_segments:
		return
	if next_segment:
		draw_line(Vector2.ZERO, to_local(next_segment.global_position), modulate, 1)


func read_inputs():
	if not is_head():
		return
	if move_tween and move_tween.is_running():
		return
	update_highlight()
	if Input.is_action_pressed("lmb"):
		move()

func update_highlight():
	var show_highlight : bool = (get_move_position() != global_position)
	Highlighter.highlight_position(get_move_position(), show_highlight)

func get_move_position() -> Vector2:
	return map.get_move_position(self, round_hexagonal(get_input_vector()))
func get_input_vector():
	var mouse_input_vector := global_position.direction_to(get_global_mouse_position())
	return mouse_input_vector

func move(duration := 0.25) -> Tween:
	if move_tween:
		move_tween.kill()
	
	last_position = global_position
	var move_position = get_move_position()
	# do not "move" if position would not change
	## FIXME: look here to deal with collisions
	if is_head() and move_position == last_position:
		return
	# all other segments replace the position of their predecessor
	if not is_head():
		move_position = prev_segment.last_position
	move_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	move_tween.tween_property(self, "global_position", move_position, duration)
	
	if next_segment:
		next_segment.move()
	
	## FIXME Just for testing ##
	if is_head():
		extend()
	############################
	
	moved.emit(self, last_position, move_position)
	return move_tween


func round_hexagonal(base_vector) -> Vector2:
	var hex_direction : Vector2
	hex_direction.x = roundi(base_vector.x)
	#max out vertical input to eliminate "sticky" horizontal movement
	hex_direction.y = ceili(abs(base_vector.y)) * sign(base_vector.y)
	#move when holding mouse button
	return hex_direction


func extend():
	if head.get_length() >= max_length:
		return
	if next_segment == null:
		next_segment = map.create_hex(map.mover_hex_scn, map.get_hex_coords(last_position), modulate)
		next_segment.prev_segment = self
		next_segment.head = head
	else:
		next_segment.extend()


func is_head():
	return head == self

# returns the length from the calling segment to the end of the chain
func get_length() -> int:
	var length = 1
	if next_segment:
		length += next_segment.get_length()
	return length
