extends Node2D

@onready var iris = $Iris
@onready var pupil = $Iris/Pupil
@onready var shine = $Shine

@export_range(10, 100, 5) var tracking_speed = 10

var max_mouse_distance := 120.0
var max_pupil_offset := 140.0
var min_scale_x = 0.3

func _ready() -> void:
	MapManager.scale_to_hex_width(self, iris.texture.get_width() * 1.2)

func _process(delta: float) -> void:
	var mouse_direction = global_position.direction_to(get_global_mouse_position())
	var mouse_distance = global_position.distance_to(get_global_mouse_position())
	var distance_weight = ease(mouse_distance / max_mouse_distance, 0.6)
	
	# follow mouse angle
	iris.rotation = lerp_angle(iris.rotation, mouse_direction.angle(), tracking_speed * delta)
	
	# offset pupil toward mouse
	var new_offset = min(max_pupil_offset, max_pupil_offset * distance_weight)
	pupil.offset.x = lerp(pupil.offset.x, new_offset / pupil.scale.x, tracking_speed * 1.5 * delta)
	
	# enlarge pupil when mouse is close by
	var new_scale_x = lerp(1.0, min_scale_x, distance_weight)
	pupil.scale.x  = lerp(pupil.scale.x, new_scale_x, tracking_speed * delta)
	
	# shift the shine slowly to add weight to the motion
	var shine_pivot = mouse_direction.normalized() * 15
	shine.offset = lerp(shine.offset, shine_pivot, tracking_speed * delta * 0.2)
