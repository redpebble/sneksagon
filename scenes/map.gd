extends Node2D

@export_range(0.0, 0.5, 0.05) var grid_contrast : float = 0.15
@export_range(0.0, 1.0, 0.05) var grid_opacity : float = 0.3

var hex_scene = preload("res://scenes/hex/hex.tscn")

func _ready() -> void:
	MapManager.map_node = self
	populate_grid()
	$Snake.make_head(Vector2(2, 2))

func populate_grid():
	var playfield : Vector2 = get_window().size * 0.75
	var cols : int = floori(playfield.x / MapManager.HEX_WIDTH / MapManager.HEX_COL_RATIO)
	var rows : int = floori(playfield.y / MapManager.HEX_WIDTH / MapManager.HEX_ROW_RATIO)
	var window_center : Vector2 = get_window().size * 0.5
	var map_dimensions := Vector2i(cols, rows)
	var map_size = (Vector2(map_dimensions) - Vector2(1.0, 0.5)) * Vector2(0.75, 0.866) * MapManager.HEX_WIDTH
	MapManager.grid_map_origin = window_center - (map_size * 0.5)
	
	for i in map_dimensions.x:
		for j in map_dimensions.y:
			var shift_amount : int = floori(0.5 * i) * -1
			var adjusted_j   : int = j + shift_amount
			var d = wrapi(adjusted_j - wrapi(i, 0, 3), 0, 3) * grid_contrast
			var color = Color.WHITE.darkened(d)
			color.a = grid_opacity
			MapManager.create_hex(hex_scene.instantiate(), Vector2(i, adjusted_j), color)
