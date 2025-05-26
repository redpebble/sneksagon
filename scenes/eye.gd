extends Node2D

@onready var iris = $Iris
@onready var pupil = $Iris/Pupil
@onready var shine = $Shine

@export_range(0.1, 0.5, 0.01) var tracking_strength = 0.3

var max_mouse_distance = 50
var max_pupil_offset = 150
var min_scale_x = 0.3

func _ready() -> void:
	MapManager.scale_to_hex_width(self, iris.texture.get_width() * 2.2)

func _process(delta: float) -> void:
	# follow mouse angle
	var mouse_direction = global_position.direction_to(get_global_mouse_position())
	iris.rotation = lerp_angle(iris.rotation, mouse_direction.angle(), tracking_strength)
	
	# offset pupil toward mouse
	var mouse_distance = global_position.distance_to(get_global_mouse_position())
	var new_offset  : float = min(max_pupil_offset, remap(mouse_distance, 0, max_mouse_distance, 0, max_pupil_offset))
	pupil.offset.x = lerp(pupil.offset.x, new_offset / pupil.scale.x, tracking_strength)
	
	# enlarge pupil when mouse is close by
	var new_scale_x : float = max(min_scale_x, remap(mouse_distance, 0, max_mouse_distance, 1, min_scale_x))
	pupil.scale.x  = lerp(pupil.scale.x, new_scale_x, tracking_strength)
	
	# shift the shine slowly to add weight to the motion
	var shine_pivot = mouse_direction.normalized() * 10
	shine.offset = lerp(shine.offset, shine_pivot, tracking_strength * 0.2)
