extends Node

var map_node: Node2D = null

var hex_scale: int = 30
@onready var hex_width = 2 * hex_scale

# use hex coordinates to get position in world
func get_hex_world_position(coords : Vector2, offset : Vector2 = map_node.grid_origin) -> Vector2:
	var x = 0.75 * hex_width * coords.x
	var y = 0.866 * hex_width * (coords.y + 0.5 * coords.x)
	return Vector2(x, y) + offset

# use world position to derive hex coordinates
func get_hex_coords(world_position : Vector2) -> Vector2:
	world_position -= map_node.grid_origin
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
