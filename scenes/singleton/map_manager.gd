extends Node

const HEX_COL_RATIO = 0.75
const HEX_ROW_RATIO = 0.866
const HEX_SCALE: int = 55
const HEX_WIDTH = 2 * HEX_SCALE

var map_node: Node2D = null

# we're using arrays to deal with grid position overwriting issues when the snake moves
var entities : Dictionary[Vector2, Array] = {}

var valid_coords : Dictionary[Vector2, bool] = {} # there is no Set structure in GDScript
var grid_map_origin := Vector2.ZERO

var apple_scene = preload("res://scenes/hex/apple_hex.tscn")

var directions := {
	"up"         = Vector2.UP,
	"up_left"    = Vector2.UP + Vector2.LEFT,
	"up_right"   = Vector2.UP + Vector2.RIGHT,
	"down"       = Vector2.DOWN,
	"down_left"  = Vector2.DOWN + Vector2.LEFT,
	"down_right" = Vector2.DOWN + Vector2.RIGHT
}

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
		directions.up:         return coords + Vector2(0, -1)
		directions.up_left:    return coords + Vector2(-1, 0)
		directions.up_right:   return coords + Vector2(1, -1)
		directions.down:       return coords + Vector2(0, 1)
		directions.down_left:  return coords + Vector2(-1, 1)
		directions.down_right: return coords + Vector2(1, 0)
		_: return coords

func create_hex(hex_node: Hex, coords : Vector2, color : Color = Color.BLACK) -> Node2D:
	hex_node.grid_coords = coords
	hex_node.scale *= HEX_SCALE
	hex_node.position = get_hex_world_position(coords)
	hex_node.modulate = color

	if hex_node is ObjectHex: # includes sub-classes, i.e. SnakeHex, AppleHex
		record_entity(hex_node, coords)
		hex_node.moved.connect(_on_hex_moved)
		hex_node.tree_exiting.connect(_on_hex_tree_exiting.bind(hex_node))
	else:
		valid_coords[coords] = true

	map_node.call_deferred("add_child", hex_node)

	return hex_node

func clear() -> void:
	for entity_array in entities.values():
		for i in entity_array:
			#do not wait for a signal to erase
			i.tree_exiting.disconnect(_on_hex_tree_exiting)
			#force instant erasure
			erase_entity(i)
			#delete the entity
			i.queue_free()

# update entity data when moved
func _on_hex_moved(hex : Hex, from_coords : Vector2, to_coords : Vector2):
	erase_entity(hex, from_coords)
	record_entity(hex, to_coords)

# update entity data when exiting tree
# bypassed during clear()
func _on_hex_tree_exiting(hex : Hex):
	erase_entity(hex)

# remove entity at specified coordinates
# defaults to using the hex's current coords
func erase_entity(hex : Hex, coords : Vector2 = hex.grid_coords) -> void:
	if entities.get(coords) != null:
		#erase entity
		if entities[coords].has(hex):
			entities[coords].erase(hex)
		else:
			push_warning(str(hex) + " entry not found at coords " + str(coords))
		#clear dictionary entry entirely
		if entities[coords].is_empty():
			entities.erase(coords)
	else:
		push_warning("No record at coords " + str(coords) + ". During attempted deletion of " + str(hex))

# record entity at specified coordinates
func record_entity(hex : Hex, coords : Vector2):
	if entities.get(coords):
		entities[coords].append(hex)
	else:
		entities[coords] = [hex]

func get_random_empty_cell():
	var open_cells : Dictionary = valid_coords.duplicate()
	for i in entities:
		open_cells.erase(i)
	if open_cells:
		var rand_idx = randi() % open_cells.size()
		var rand_coords = open_cells.keys()[rand_idx]
		return rand_coords
	else:
		return null

func spawn_apple() -> void:
	var empty_cell = get_random_empty_cell()
	if empty_cell != null:
		create_hex(apple_scene.instantiate(), empty_cell)
	else:
		push_warning("No empty cells. Apple not spawned.")

func scale_to_hex_width(node: Node2D, input_width : float):
	if input_width == 0.0:
		push_warning("Cannot calculate scale value from input of 0. Returning 1.0.")
		return
	node.scale = Vector2.ONE * HEX_WIDTH / input_width
