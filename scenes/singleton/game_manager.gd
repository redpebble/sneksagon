extends Node

@export var snake_scene : PackedScene

var snake : Snake = null
var camera : ShakyCamera = null

func _ready() -> void:
	await get_tree().process_frame
	reset_level()

func reset_level():
	MapManager.clear()
	create_snake(Vector2.ZERO)
	MapManager.spawn_apple()

func create_snake(init_coords : Vector2):
	if snake == null:
		snake = snake_scene.instantiate()
		call_deferred("add_child", snake)
		snake.died.connect(_on_snake_died)
		snake.collided.connect(_on_snake_collided)
	snake.make_head(init_coords)

func _on_snake_died():
	reset_level()

func _on_snake_collided():
	camera.small_shake()
