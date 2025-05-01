extends Node

@export var snake_scene : PackedScene

var snake : Snake = null
var camera : ShakyCamera = null

func _ready() -> void:
	start_level()

func start_level():
	create_snake()

func reset_level():
	MapManager.clear()
	snake.make_head(Vector2(0, 0))
	MapManager.spawn_apple()

func create_snake():
	snake = snake_scene.instantiate()
	call_deferred("add_child", snake)
	await get_tree().process_frame
	snake.make_head(Vector2.ZERO)
	snake.died.connect(_on_snake_died)
	snake.collided.connect(_on_snake_collided)

func _on_snake_died():
	reset_level()

func _on_snake_collided():
	camera.small_shake()
