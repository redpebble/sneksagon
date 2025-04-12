extends Node2D

enum Direction {
	UP, UP_LEFT, UP_RIGHT, DOWN, DOWN_LEFT, DOWN_RIGHT
}

const SCALE = 6
const SIDE_LENGTH = 5
const w = SIDE_LENGTH * 2 * SCALE

var hex_scn = preload("res://scenes/hex.tscn")

var hex_dict: Dictionary[Vector2, Node2D] = {}
var map_origin := Vector2.ZERO


func _ready() -> void:
	populate_map()
	#create_grid()
	create_hex(2, 4, Color(randf(), randf(), randf()))
	await move_hex_adjacent(Vector2(2, 4), Direction.UP).finished
	await move_hex_adjacent(Vector2(2, 3), Direction.UP_RIGHT).finished
	await move_hex_adjacent(Vector2(3, 2), Direction.DOWN_RIGHT).finished
	await move_hex_adjacent(Vector2(4, 2), Direction.DOWN).finished
	await move_hex_adjacent(Vector2(4, 3), Direction.DOWN_LEFT).finished
	move_hex_adjacent(Vector2(3, 4), Direction.UP_LEFT)

func get_hex_screen_position(i, j, offset := Vector2.ZERO) -> Vector2:
	var w = SIDE_LENGTH * 2 * SCALE
	var x = 0.75 * w * i
	var y = 0.866 * w * (j + 0.5 * i)
	return Vector2(x, y) + offset

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
	hex.position = get_hex_screen_position(i, j, map_origin)
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
	t.tween_property(hex, "position", get_hex_screen_position(to.x, to.y, map_origin), 1.0)
	hex_dict.erase(from)
	hex_dict[to] = hex
	return t

func move_hex_adjacent(from: Vector2, direction: Direction) -> Tween:
	return move_hex(from, get_adjacent_hex_index(from.x, from.y, direction))


func populate_map():
	var cols = floor(get_window().size.x / w / 0.75)
	var rows = floor(get_window().size.y / w / 0.866)
	var window_center : Vector2 = get_window().size * 0.5
	var map_dimensions := Vector2(cols, rows)
	
	map_origin = window_center - (map_dimensions - Vector2(1.0, 0.5)) * Vector2(0.75, 0.866) * w * 0.5
	
	for i in map_dimensions.x:
		for j in map_dimensions.y:
			var adjusted_j = floori(0.5 * i) * -1 + j
			var d = wrapi(adjusted_j - wrapi(i, 0, 3), 0, 3) / 15.0
			create_hex(i, adjusted_j, Color.WHITE.darkened(d))
