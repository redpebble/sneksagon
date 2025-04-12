extends Node2D

enum Direction {
	UP, UP_LEFT, UP_RIGHT, DOWN, DOWN_LEFT, DOWN_RIGHT
}

const SCALE = 6
const SIDE_LENGTH = 5

var hex_scn = preload("res://scenes/hex.tscn")

var hex_dict: Dictionary[Vector2, Node2D] = {}

func _ready() -> void:
	create_grid()
	create_hex(2, 4, Color(randf(), randf(), randf()))
	await move_hex_adjacent(Vector2(2, 4), Direction.UP).finished
	await move_hex_adjacent(Vector2(2, 3), Direction.UP_RIGHT).finished
	await move_hex_adjacent(Vector2(3, 2), Direction.DOWN_RIGHT).finished
	await move_hex_adjacent(Vector2(4, 2), Direction.DOWN).finished
	await move_hex_adjacent(Vector2(4, 3), Direction.DOWN_LEFT).finished
	move_hex_adjacent(Vector2(3, 4), Direction.UP_LEFT)

func get_hex_screen_position(i, j) -> Vector2:
	var w = SIDE_LENGTH * 2 * SCALE
	var x = 0.75 * w * i
	var y = 0.866 * w * (j + 0.5 * i)
	return Vector2(x, y)

func get_adjacent_hex_index(i, j, direction) -> Vector2:
	match direction:
		Direction.UP:         return Vector2(i, j-1)
		Direction.UP_LEFT:    return Vector2(i-1, j)
		Direction.UP_RIGHT:   return Vector2(i+1, j-1)
		Direction.DOWN:       return Vector2(i, j+1)
		Direction.DOWN_LEFT:  return Vector2(i-1, j+1)
		Direction.DOWN_RIGHT: return Vector2(i+1, j)
		_: return Vector2(i, j)

func create_hex(i, j, hex_color):
	var hex = hex_scn.instantiate()
	hex.scale *= SCALE
	hex.position = get_hex_screen_position(i, j)
	hex.modulate = hex_color
	call_deferred("add_child", hex)
	hex_dict[Vector2(i, j)] = hex

func create_grid():
	var w = SIDE_LENGTH * 2 * SCALE
	var i = 0
	while ((i-1) * w * 0.75 < get_window().size.x):
		var j = floori(0.5 * i) * -1
		while ((j-1) * w * 0.886 < get_window().size.y):
			var d = wrapi(j - wrapi(i, 0, 3), 0, 3) / 15.0
			create_hex(i, j, Color.WHITE.darkened(d))
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

func move_hex_adjacent(from: Vector2, direction: Direction) -> Tween:
	return move_hex(from, get_adjacent_hex_index(from.x, from.y, direction))


#func create_grid():
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
