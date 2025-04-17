class_name ObjectHex
extends Hex

signal moved(hex_node, from_pos, to_pos)

@export var connect_segments := true
@onready var last_position := global_position

var move_tween : Tween = null


func _ready() -> void:
	scale *= 0.8

func _process(_delta: float) -> void:
	queue_redraw()

func move(new_pos : Vector2, duration := 0.25) -> Tween:
	if move_tween:
		move_tween.kill()
	
	last_position = global_position
	# do not "move" if position would not change
	if new_pos == last_position:
		return
	move_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	move_tween.tween_property(self, "global_position", new_pos, duration)
	
	
	moved.emit(self, last_position, new_pos)
	return move_tween

func set_color(col : Color):
	modulate = col
