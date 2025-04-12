extends Node2D

const SCALE = 6
const SIDE_LENGTH = 5
const w = SIDE_LENGTH * 2 * SCALE

@export_range(0.0, 0.5, 0.05) var grid_contrast : float = 0.15

var hex_scn = preload("res://scenes/hex.tscn")

var map : Dictionary[Vector2, Node2D] = {}
var entities : Dictionary[Vector2, Node2D] = {}
var map_origin := Vector2.ZERO
var move_tween : Tween = null
var player_hex = null


func _ready() -> void:
	populate_grid()
	player_hex = create_hex(2, 4, Color.BLACK, true)

func _process(_delta: float) -> void:
	move_player()


func move_player():
	if not player_hex:
		return
	if move_tween and move_tween.is_running():
		return
	#get player coordinates
	var player_pos = player_hex.global_position
	var player_coords = get_hex_coordinates(player_pos)
	#get input direction
	var input_vector : Vector2 = player_pos.direction_to(get_global_mouse_position())
	var move_direction : Vector2
	move_direction.x = roundi(input_vector.x)
	#max out vertical input to eliminate "sticky" horizontal movement
	move_direction.y = ceili(abs(input_vector.y)) * sign(input_vector.y)
	#move when holding mouse button
	if Input.is_action_pressed("lmb"):
		move_hex_adjacent(player_coords, move_direction)


# use hex coordinates to get position in world
func get_hex_world_position(i, j, offset := Vector2.ZERO) -> Vector2:
	var x = 0.75 * w * i
	var y = 0.866 * w * (j + 0.5 * i)
	return Vector2(x, y) + offset
# use world position to derive hex coordinates
func get_hex_coordinates(world_position : Vector2) -> Vector2:
	world_position -= map_origin
	var i = roundi(world_position.x / (0.75 * w))
	var j = roundi(world_position.y / (0.866 * w) - 0.5 * i)
	return Vector2i(i, j)

func get_adjacent_hex_index(coords : Vector2, direction : Vector2) -> Vector2:
	match direction:
		Vector2.UP:                   return coords + Vector2(0, -1)
		Vector2.UP + Vector2.LEFT:    return coords + Vector2(-1, 0)
		Vector2.UP + Vector2.RIGHT:   return coords + Vector2(1, -1)
		Vector2.DOWN:                 return coords + Vector2(0, 1)
		Vector2.DOWN + Vector2.LEFT:  return coords + Vector2(-1, 1)
		Vector2.DOWN + Vector2.RIGHT: return coords + Vector2(1, 0)
		_: return coords

func create_hex(i, j, hex_color, is_entitiy := false) -> Node2D:
	var hex = hex_scn.instantiate()
	hex.scale *= SCALE
	hex.position = get_hex_world_position(i, j, map_origin)
	hex.modulate = hex_color
	call_deferred("add_child", hex)
	if is_entitiy:
		entities[Vector2(i, j)] = hex
		print(Vector2(i, j))
	else:
		map[Vector2(i, j)] = hex
	return hex

func move_hex(from : Vector2, to : Vector2, duration := 0.3) -> Tween:
	if move_tween:
		move_tween.kill()
	var hex := entities[from]
	move_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	move_tween.tween_property(hex, "position", get_hex_world_position(to.x, to.y, map_origin), duration)
	entities.erase(from)
	entities[to] = hex
	return move_tween

func move_hex_adjacent(from: Vector2, direction : Vector2) -> Tween:
	return move_hex(from, get_adjacent_hex_index(from, direction))

func populate_grid():
	var playfield = get_window().size * 0.75
	var cols = floor(playfield.x / w / 0.75)
	var rows = floor(playfield.y / w / 0.866)
	var window_center : Vector2 = get_window().size * 0.5
	var map_dimensions := Vector2(cols, rows)
	
	map_origin = window_center - (map_dimensions - Vector2(1.0, 0.5)) * Vector2(0.75, 0.866) * w * 0.5
	
	for i in map_dimensions.x:
		for j in map_dimensions.y:
			var shift_amount = floori(0.5 * i) * -1
			var adjusted_j = j + shift_amount
			var d = wrapi(adjusted_j - wrapi(i, 0, 3), 0, 3) * grid_contrast
			create_hex(i, adjusted_j, Color.WHITE.darkened(d))
