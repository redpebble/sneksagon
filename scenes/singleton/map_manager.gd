extends Node

const HEX_COL_RATIO = 0.75
const HEX_ROW_RATIO = 0.866
const HEX_SCALE: int = 30
const HEX_WIDTH = 2 * HEX_SCALE

var map_node: Node2D = null

# we're using arrays to deal with grid position overwriting issues when the snake moves
var entities : Dictionary[Vector2, Array] = {}

var valid_coords : Dictionary[Vector2, bool] = {} # there is no Set structure in GDScript
var grid_map_origin := Vector2.ZERO

var apple_scene = preload("res://scenes/hex/apple_hex.tscn")

# use hex coordinates to get position in world
func get_hex_world_position(coords : Vector2, offset : Vector2 = grid_map_origin) -> Vector2:
	var x = 0.75 * HEX_WIDTH * coords.x
	var y = 0.866 * HEX_WIDTH * (coords.y + 0.5 * coords.x)
	return Vector2(x, y) + offset

# use world position to derive hex coordinates
func get_hex_coords(world_position : Vector2) -> Vector2:
	world_position -= grid_map_origin
	var i = roundi(world_position.x / (0.75 * HEX_WIDTH))
	var j = roundi(world_position.y / (0.866 * HEX_WIDTH) - 0.5 * i)
	return Vector2i(i, j)

func get_adjacent_hex_coords(coords : Vector2, direction : Vector2) -> Vector2:
	match direction:
		Vector2.UP:                   return coords + Vector2(0, -1)
		Vector2.UP + Vector2.LEFT:    return coords + Vector2(-1, 0)
		Vector2.UP + Vector2.RIGHT:   return coords + Vector2(1, -1)
		Vector2.DOWN:                 return coords + Vector2(0, 1)
		Vector2.DOWN + Vector2.LEFT:  return coords + Vector2(-1, 1)
		Vector2.DOWN + Vector2.RIGHT: return coords + Vector2(1, 0)
		_: return coords

func create_hex(hex_node: Hex, coords : Vector2, color : Color = Color.BLACK) -> Node2D:
	hex_node.grid_coords = coords
	hex_node.scale *= HEX_SCALE
	hex_node.position = get_hex_world_position(coords)
	hex_node.modulate = color

	if hex_node is ObjectHex: # includes sub-classes, i.e. SnakeHex
		entities[coords] = [hex_node]
		hex_node.moved.connect(_on_hex_moved)
	else:
		valid_coords[coords] = true

	map_node.call_deferred("add_child", hex_node)

	return hex_node

# update entity data when moved
func _on_hex_moved(hex : Hex, from_coords : Vector2, to_coords : Vector2):
	if entities.get(from_coords):
		entities[from_coords].erase(hex)
		if entities[from_coords].is_empty():
			entities.erase(from_coords)
	entities[to_coords] = [hex]


func get_random_cell() -> Vector2:
	var coords_list = valid_coords.keys()
	return coords_list[randi_range(0, coords_list.size() - 1)]

func get_random_empty_cell() -> Vector2: # this is not very good lol
	var coords = null
	while coords == null:
		var check_coords = get_random_cell()
		if entities.get(check_coords) == null:
			coords = check_coords
	return coords

func spawn_apple() -> void:
	create_hex(apple_scene.instantiate(), get_random_empty_cell())
