extends Node

var modifier_folder = "res://scenes/modifiers/"
var modifiers : Array[PackedScene] = []


func _init() -> void:
	populate_modifiers()

func populate_modifiers():
	var dir = DirAccess.open(modifier_folder)
	for i in dir.get_files():
		var mod = load(modifier_folder + i)
		modifiers.append(mod)

func create_modifier() -> Modifier:
	var rand_index = randi() % modifiers.size()
	var mod_inst = modifiers[rand_index].instantiate()
	return mod_inst

func add_new_modifier(destination : Node2D) -> void:
	var m = create_modifier()
	destination.call_deferred("add_child", m)

func add_exisiting_modifier(destination : Node2D, m : Modifier) -> void:
	if !m.is_inside_tree():
		push_warning("could not add modifier. " + m.name + " is not inside tree.")
		return
	m.link_to(destination)

func transfer_modifier(source : Node2D, destination : Node2D) -> void:
	var m = get_modifier_at(source)
	if m:
		add_exisiting_modifier(m, destination)

func get_modifier_at(source : Node2D) -> Modifier:
	var m : Modifier = null
	for i in source.get_children():
		if i is Modifier:
			m = i
			break
	return m
