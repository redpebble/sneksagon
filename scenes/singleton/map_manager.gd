extends Node

signal hex_scale_changed(scale)

const HEX_COL_RATIO = 0.75
const HEX_ROW_RATIO = 0.866

var map_node : Node2D = null
var wave_timer : SceneTreeTimer = null

# we're using arrays to deal with grid position overwriting issues when the snake moves
var entities : Dictionary[Vector2, Array] = {}
var valid_coords : Dictionary[Vector2, Hex] = {} # there is no Set structure in GDScript
var background : Dictionary[Vector2, Hex] = {}

var grid_map_origin := Vector2.ZERO
var hex_scale: int = 60 : set = set_hex_scale

var apple_scene = preload("res://scenes/hex/apple_hex.tscn")
var block_scene = preload("res://scenes/hex/block_hex.tscn")

var directions := {
	"up"         = Vector2.UP,
	"up_left"    = Vector2.UP + Vector2.LEFT,
	"up_right"   = Vector2.UP + Vector2.RIGHT,
	"down"       = Vector2.DOWN,
	"down_left"  = Vector2.DOWN + Vector2.LEFT,
	"down_right" = Vector2.DOWN + Vector2.RIGHT
}

enum Layers {
	BACKGROUND,
	TILES,
	ENTITIES
}

func set_hex_scale(_hex_scale):
	hex_scale = _hex_scale
	hex_scale_changed.emit()

# use hex coordinates to get position in world
func get_hex_world_position(coords : Vector2, offset : Vector2 = grid_map_origin) -> Vector2:
	var x = 0.75 * get_hex_width() * coords.x
	var y = 0.866 * get_hex_width() * (coords.y + 0.5 * coords.x)
	return Vector2(x, y) + offset

# use world position to derive hex coordinates
func get_hex_coords(world_position : Vector2) -> Vector2:
	world_position -= grid_map_origin
	var i = roundi(world_position.x / (0.75 * get_hex_width()))
	var j = roundi(world_position.y / (0.866 * get_hex_width()) - 0.5 * i)
	return Vector2i(i, j)

func get_hex_width() -> float:
	return 2 * hex_scale

func get_adjacent_hex_coords(coords : Vector2, direction : Vector2) -> Vector2:
	match direction:
		directions.up:         return coords + Vector2(0, -1)
		directions.up_left:    return coords + Vector2(-1, 0)
		directions.up_right:   return coords + Vector2(1, -1)
		directions.down:       return coords + Vector2(0, 1)
		directions.down_left:  return coords + Vector2(-1, 1)
		directions.down_right: return coords + Vector2(1, 0)
		_: return coords

func create_hex(hex_instance : Hex, coords : Vector2, layer : int, color := Color.BLACK) -> Node2D:
	hex_instance.grid_coords = coords
	hex_instance.scale *= hex_scale
	hex_instance.position = get_hex_world_position(coords)
	hex_instance.modulate = color
	
	match layer:
		Layers.BACKGROUND:
			background[coords] = hex_instance
		Layers.TILES:
			valid_coords[coords] = hex_instance
		Layers.ENTITIES:
			record_entity(hex_instance, coords)
	
	map_node.call_deferred("add_child", hex_instance)
	return hex_instance

func clear() -> void:
	for entity_array in entities.values():
		for i in entity_array:
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
			hex.moved.disconnect(_on_hex_moved)
			hex.tree_exiting.disconnect(_on_hex_tree_exiting.bind(hex))
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
	hex.moved.connect(_on_hex_moved)
	hex.tree_exiting.connect(_on_hex_tree_exiting.bind(hex))
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

func is_empty_cell(coords : Vector2) -> bool:
	return entities.get(coords) == null

func spawn_apple() -> void:
	var empty_cell = get_random_empty_cell()
	if empty_cell != null:
		var apple_inst : AppleHex = apple_scene.instantiate()
		apple_inst.just_collected.connect(_on_apple_just_collected)
		create_hex(apple_inst, empty_cell, MapManager.Layers.ENTITIES, Color.RED)
	else:
		push_warning("No empty cells. Apple not spawned.")

func spawn_block(at_coords : Vector2) -> void:
	if not is_empty_cell(at_coords):
		return
	create_hex(block_scene.instantiate(), at_coords, MapManager.Layers.ENTITIES, Color.BLUE)

func _on_apple_just_collected() -> void:
	spawn_apple()

func scale_to_hex_width(node: Node2D, input_width : float):
	if input_width == 0.0:
		push_warning("Cannot calculate scale value from input of 0. Returning 1.0.")
		return
	node.scale = Vector2.ONE * get_hex_width() / input_width

# Background Animations ---------------------------------------------------------------------------#

func start_wave_timer():
	wave_timer = get_tree().create_timer(3.0)
	wave_timer.timeout.connect(_on_wave_timer_timeout)

func _on_wave_timer_timeout():
	start_wave_timer()
	var grid := valid_coords.keys()
	var screen_size : Vector2 = get_window().size
	var edge_coverage = 2
	var cols : int = edge_coverage + floori(screen_size.x / MapManager.get_hex_width() / MapManager.HEX_COL_RATIO)
	var rows : int = edge_coverage + floori(screen_size.y / MapManager.get_hex_width() / MapManager.HEX_ROW_RATIO)
	var origin_offset = floor(Vector2i(cols, floori(rows / 2.0)) / 2.0)
	
	for i in cols:
		for j in rows:
			var shift_amount : int = floori(0.5 * i) * -1
			var shifted_j    : int = j + shift_amount
			var coords = Vector2(i, shifted_j) - Vector2(origin_offset)
			
			if background.get(coords):
				var h : Hex = background[coords]
				h.pulse(0.3, 2.0)
		await get_tree().create_timer(0.2).timeout

func begin_background_pulse():
	var pulse_interval = 0.03
	var all_coords = background.keys()
	while not all_coords.is_empty():
		var hex = background[all_coords.pop_back()]
		hex.loop(hex.pulse.bind(0.2, 8.0), 0.3)
		all_coords.shuffle()
		await get_tree().create_timer(pulse_interval).timeout
