extends Node2D

@export_range(3, 30, 1) var hex_scale: int = 15
@export_range(0.0, 0.5, 0.05) var grid_contrast : float = 0.15
@export_range(0.0, 1.0, 0.05) var grid_brightness : float = 0.6
@export var static_hex_scn : PackedScene = null
@export var mover_hex_scn : PackedScene = null

@onready var hex_width = 2 * hex_scale

var map : Dictionary[Vector2, Node2D] = {} # FIXME no need for node2Ds themselves to be stored
var entities : Dictionary[Vector2, Array] = {}
var map_origin := Vector2.ZERO


func _ready() -> void:
	Highlighter.scale_to_width(hex_width)
	populate_grid()
	#create_hex(mover_hex_scn, Vector2(2, 4), Color.BLACK)
	$Snake.make_head(Vector2(2, 2))

# use hex coordinates to get position in world
func get_hex_world_position(coords : Vector2, offset : Vector2 = map_origin) -> Vector2:
	var x = 0.75 * hex_width * coords.x
	var y = 0.866 * hex_width * (coords.y + 0.5 * coords.x)
	return Vector2(x, y) + offset
# use world position to derive hex coordinates
func get_hex_coords(world_position : Vector2) -> Vector2:
	world_position -= map_origin
	var i = roundi(world_position.x / (0.75 * hex_width))
	var j = roundi(world_position.y / (0.866 * hex_width) - 0.5 * i)
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

func create_hex(scene : PackedScene, coords : Vector2, hex_color : Color) -> Node2D:
	var hex = scene.instantiate()
	hex.scale *= hex_scale
	hex.position = get_hex_world_position(coords)
	hex.modulate = hex_color
	call_deferred("add_child", hex)
	if scene != static_hex_scn:
		entities[coords] = [hex]
		hex.moved.connect(_on_hex_moved)
	else:
		map[coords] = hex
	return hex

func get_move_position(mover : Node2D, direction : Vector2) -> Vector2:
	var move_position := mover.global_position
	var from_coords = get_hex_coords(mover.global_position)
	var to_coords = get_adjacent_hex_coords(from_coords, direction)
	if map.get(to_coords) != null:
		if not entities.get(to_coords):
			move_position = get_hex_world_position(to_coords)
	return move_position

func populate_grid():
	var playfield : Vector2 = get_window().size * 0.75
	var cols : int = floori(playfield.x / hex_width / 0.75)
	var rows : int = floori(playfield.y / hex_width / 0.866)
	var window_center : Vector2 = get_window().size * 0.5
	var map_dimensions := Vector2i(cols, rows)
	var map_size = (Vector2(map_dimensions) - Vector2(1.0, 0.5)) * Vector2(0.75, 0.866) * hex_width
	map_origin = window_center - (map_size * 0.5)
	
	for i in map_dimensions.x:
		for j in map_dimensions.y:
			var shift_amount : int = floori(0.5 * i) * -1
			var adjusted_j   : int = j + shift_amount
			var d = wrapi(adjusted_j - wrapi(i, 0, 3), 0, 3) * grid_contrast
			d += 1.0 - grid_brightness
			create_hex(static_hex_scn, Vector2(i, adjusted_j), Color.WHITE.darkened(d))

# update entity data when moved
func _on_hex_moved(hex : Hex, from : Vector2, to : Vector2):
	var from_coords = get_hex_coords(from)
	var to_coords = get_hex_coords(to)
	if entities.get(from_coords):
		entities[from_coords].erase(hex)
		if entities[from_coords].is_empty():
			entities.erase(from_coords)
	entities[to_coords] = [hex]
