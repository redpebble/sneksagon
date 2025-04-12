extends Node2D

const SCALE = 6
const SIDE_LENGTH = 5

var hex_scn = preload("res://scenes/hex.tscn")

var hex_dict: Dictionary[Vector2, Node2D] = {}

func _ready() -> void:
	#populate_map()
	pass

#func populate_map():
	#var w = 10 * SCALE
#
	#print(get_window().size)
#
	#var i = 0
	#while ((i-1) * w * 0.75 < get_window().size.x):
		#var j = floori(0.5 * i) * -1
		#while ((j-1) * w * 0.886 < get_window().size.y):
			#var x = 0.75 * w * i
			#var y = 0.866 * w * (j + 0.5 * i)
#
			#var hex = hex_scn.instantiate()
			#hex.scale *= 6
			#hex.position = Vector2(x, y)
			#hex.modulate = Color(randf(), randf(), randf())
			#add_child(hex)
#
			#hex_dict[Vector2(i, j)] = hex
#
			#j += 1
		#i += 1


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
