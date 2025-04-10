extends Node2D

const SCALE = 6

var hex_scn = preload("res://scenes/hex.tscn")

var hex_dict: Dictionary[Vector2, Node2D] = {}

func _ready() -> void:
	populate_map()

func populate_map():
	var w = 10 * SCALE

	print(get_window().size)

	var i = 0
	while ((i-1) * w * 0.75 < get_window().size.x):
		var j = floori(0.5 * i) * -1
		while ((j-1) * w * 0.886 < get_window().size.y):
			var x = 0.75 * w * i
			var y = 0.866 * w * (j + 0.5 * i)

			var hex = hex_scn.instantiate()
			hex.scale *= 6
			hex.position = Vector2(x, y)
			hex.modulate = Color(randf(), randf(), randf())
			add_child(hex)

			hex_dict[Vector2(i, j)] = hex

			j += 1
		i += 1
