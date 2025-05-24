extends Node2D

@export var hex_color : Color = Color.WHITE
@export_range(0.0, 0.5, 0.05) var grid_contrast : float = 0.15

@onready var camera = $Camera2D

var hex_scene = preload("res://scenes/hex/hex.tscn")

func _ready() -> void:
	MapManager.map_node = self
	#populate_grid()
	generate_grid(3)
	#populate_screen_remainder()

func populate_grid():
	var playfield : Vector2 = get_window().size * 0.6
	var cols : int = floori(playfield.x / MapManager.get_hex_width() / MapManager.HEX_COL_RATIO)
	var rows : int = floori(playfield.y / MapManager.get_hex_width() / MapManager.HEX_ROW_RATIO)
	var window_center : Vector2 = get_window().size * 0.5
	var map_dimensions := Vector2i(cols, rows)
	var map_size = (Vector2(map_dimensions) - Vector2(1.0, 0.5)) * Vector2(0.75, 0.866) * MapManager.get_hex_width()
	MapManager.grid_map_origin = window_center - (map_size * 0.5)
	MapManager.hex_scale = MapManager.hex_scale
	
	for i in map_dimensions.x:
		for j in map_dimensions.y:
			var shift_amount : int = floori(0.5 * i) * -1
			var adjusted_j   : int = j + shift_amount
			var d = wrapi(adjusted_j - wrapi(i, 0, 3), 0, 3) * grid_contrast
			MapManager.create_hex(hex_scene.instantiate(), Vector2(i, adjusted_j), hex_color.darkened(d))


func generate_grid(side_length : int):
	var long_diagonal : int = (2 * side_length) - 1
	var window_size : Vector2 = get_window().size
	var playfield = window_size * 0.6
	MapManager.grid_map_origin = window_size * 0.5
	MapManager.hex_scale = playfield.x / long_diagonal * 0.59 # magic number to fix scale
	
	var grid_center_offset = Vector2(-side_length + 1, side_length - 1)
	
	for j in long_diagonal:
		var growth_amount = j
		var i_shift = 0
		
		if j > floori(long_diagonal * 0.5): # past the midway point
			growth_amount = long_diagonal - growth_amount - 1
			i_shift = j - side_length + 1
		
		var line_length = side_length + growth_amount
		for i in line_length:
			# brightness patterning
			var d = wrapi(j + wrapi(i + i_shift , 0, 3), 0, 3) * grid_contrast
			# create hex with respect the grid's center
			var hex_coords = grid_center_offset + Vector2(i + i_shift, -j)
			MapManager.create_hex(hex_scene.instantiate(), hex_coords, hex_color.darkened(d))

func populate_screen_remainder():
	var grid := MapManager.valid_coords.keys()
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
			
			if not grid.has(coords):
				var d = wrapi(coords.y - wrapi(i, 0, 3), 0, 3) * grid_contrast
				MapManager.create_hex(hex_scene.instantiate(), coords, hex_color.darkened(d))
