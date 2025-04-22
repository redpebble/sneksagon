class_name VariableStreamPlayer2D
extends AudioStreamPlayer2D

@export var audio_files : Array[AudioStream] = []
@export_range(0.00, 0.10, 0.01) var pitch_variance = 0.0
@export var base_pitch = 1.0

var rng = RandomNumberGenerator.new()


func _ready():
	rng.randomize()

func play_random():
	if not audio_files.is_empty():
		select_rand_stream()
	choose_random_pitch()
	play()

func select_rand_stream(array : Array = audio_files):
	var random_index: = rng.randi() % array.size()
	stream = array[random_index]

func choose_random_pitch():
	pitch_scale = base_pitch + rng.randf_range(-pitch_variance, pitch_variance)
