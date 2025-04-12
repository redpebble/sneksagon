extends Node2D

const SCALE = 6
const SIDE_LENGTH = 5

var hex_scn = preload("res://scenes/hex.tscn")

var hex_dict: Dictionary[Vector2, Node2D] = {}

func _ready() -> void:
	#populate_map()
	create_hex(3, 3)
	await move_hex(Vector2(3, 3), Vector2(3, 4)).finished
	move_hex(Vector2(3, 4), Vector2(4, 4))

func get_hex_screen_position(i, j) -> Vector2:
	var w = SIDE_LENGTH * 2 * SCALE
	var x = 0.75 * w * i
	var y = 0.866 * w * (j + 0.5 * i)
	return Vector2(x, y)

func create_hex(i, j):
	var hex = hex_scn.instantiate()
	hex.scale *= SCALE
	hex.position = get_hex_screen_position(i, j)
	hex.modulate = Color(randf(), randf(), randf())
	call_deferred("add_child", hex)
	hex_dict[Vector2(i, j)] = hex

func populate_map():
	var w = SIDE_LENGTH * 2 * SCALE

	var i = 0
	while ((i-1) * w * 0.75 < get_window().size.x):
		var j = floori(0.5 * i) * -1
		while ((j-1) * w * 0.886 < get_window().size.y):

			create_hex(i, j)

			j += 1
		i += 1


func move_hex(from : Vector2, to : Vector2) -> Tween:
	var hex := hex_dict[from]
	var t = create_tween()
	t.set_ease(Tween.EASE_IN_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(hex, "position", get_hex_screen_position(to.x, to.y), 1.0)
	hex_dict.erase(from)
	hex_dict[to] = hex
	return t

#func populate_map():
	#var unit_w = calculate_diagonal() * SCALE * 1.5
	#var unit_h = calculate_inradius() * SCALE
	#
	#var map_dimensions := Vector2(6, 10)
	#var window_center : Vector2 = get_window().size * 0.5
	#var map_origin : Vector2 = window_center - (map_dimensions - Vector2.ONE * 0.5) * Vector2(unit_w, unit_h) * 0.5
	#
	#for i in map_dimensions.x:
		#for j in map_dimensions.y:
			#var x = map_origin.x + i * unit_w
			#var y = map_origin.y + j * unit_h
			## every other row
			#if int(j) % 2 == 1:
				## offset by half a horizontal unit
				#x += unit_w * 0.5
			#var hex = hex_scn.instantiate()
			#hex.scale *= SCALE
			#hex.position = Vector2(x, y)
			#hex.modulate = Color(randf(), randf(), randf())
			#call_deferred("add_child", hex)
			#
			#hex_dict[Vector2(i, j)] = hex
#
#func calculate_inradius():
	#return SIDE_LENGTH * sqrt(3) * 0.5
#
#func calculate_diagonal():
	#return SIDE_LENGTH * 2
