extends Node2D

@onready var iris = $Iris
@onready var pupil = $Iris/Pupil
@onready var shine = $Shine

@export_range(10, 100, 5) var tracking_speed = 10

var max_target_distance := 120.0
var max_pupil_offset := 120.0
var min_scale_x = 0.4
var spin_duration : float

var target_vector : Vector2 = global_position
var initial_spin_direction : Vector2
var spin_timer : SceneTreeTimer = null

func _ready() -> void:
	MapManager.scale_to_hex_width(self, iris.texture.get_width() * 1.4)

func _process(delta: float) -> void:
	spin_target_vector()
	follow_target(delta)

func follow_target(delta: float):
	var target_direction = global_position.direction_to(target_vector)
	var target_distance = global_position.distance_to(target_vector)
	var distance_weight = ease(target_distance / max_target_distance, 0.6)
	
	# follow target angle
	iris.rotation = lerp_angle(iris.rotation, target_direction.angle(), tracking_speed * delta)
	
	# enlarge pupil when target is close
	var new_scale_x = lerp(1.0, min_scale_x, distance_weight)
	pupil.scale.x  = lerp(pupil.scale.x, new_scale_x, clamp(tracking_speed * delta, 0.0, 1.0))
	
	# offset pupil
	var new_offset = min(max_pupil_offset, max_pupil_offset * distance_weight)
	pupil.offset.x = lerp(pupil.offset.x, new_offset / pupil.scale.x, tracking_speed * 1.5 * delta)
	
	# shift the shine slowly to add weight to the motion
	var shine_pivot = target_direction.normalized() * 15
	shine.offset = lerp(shine.offset, shine_pivot, tracking_speed * delta * 0.2)

func start_spin(duration : float):
	if target_vector:
		initial_spin_direction = global_position.direction_to(target_vector).rotated(PI / 3)
	else:
		initial_spin_direction = Vector2.ONE.rotated(randf() * 2 * PI)
	spin_duration = duration
	spin_timer = get_tree().create_timer(spin_duration)

func spin_target_vector():
	if spin_timer and spin_timer.time_left > 0:
		var spin_strength = spin_timer.time_left / spin_duration
		var spin_position = 10 * spin_strength
		var spin_distance = 40 * spin_strength
		var spin_vector = global_position + initial_spin_direction.rotated(spin_position) * spin_distance
		target_vector = lerp(spin_vector, target_vector, ease(spin_strength, 0.3) * 0.1)
