class_name Modifier
extends Node2D

# TRIGGER SPECIFICATIONS ------------------------------------------------------#

enum LocalTriggers {
	NONE,
	THIS_MOVES,
	THIS_DETACHES
}
const LOCAL_TRIGGER_SIGNALS = {
	LocalTriggers.NONE : "",
	LocalTriggers.THIS_MOVES : "moved",
	LocalTriggers.THIS_DETACHES : "detach_started"
}


enum GlobalTriggers {
	NONE,
	ANY_DETACH
}
const GLOBAL_TRIGGER_SIGNALS = {
	GlobalTriggers.NONE : "",
	GlobalTriggers.ANY_DETACH : "snake_segment_detached"
}


# SETUP VARIABLES -------------------------------------------------------------#

@export var mod_name : String = ""
@export var effects : Array = []
@export var local_trigger : LocalTriggers
@export var global_trigger : GlobalTriggers
@export_range(1, 3, 1, "or_greater") var proc_interval : int = 1
@export var proc_limit : int = -1


# INTERNAL VARIABLES ----------------------------------------------------------#

var trigger_receipts : int = 0
var proc_count : int = 0

func _ready() -> void:
	scale *= 0.6

func proc_effect(global_state := false):
	if can_proc():
		if global_state:
			# proc global effect
			pass
		else:
			# proc local effect
			pass
		proc_count += 1
		#print("proc " + mod_name + " | global: ", global_state)

func _on_trigger_received(global_state : bool):
	trigger_receipts += 1
	if at_interval():
		proc_effect(global_state)

func link_to(new_parent : Node2D):
	if new_parent is SnakeHex:
		self.reparent(new_parent, false)
		connect_global_trigger()
		connect_local_trigger()


# TRIGGER CONNECTION ----------------------------------------------------------#

func connect_global_trigger():
	var signal_name = GLOBAL_TRIGGER_SIGNALS[global_trigger]
	if GameManager.has_signal(signal_name):
		GameManager.connect(signal_name, _on_trigger_received.bind(true))

func connect_local_trigger():
	var signal_name = LOCAL_TRIGGER_SIGNALS[local_trigger]
	if get_parent().has_signal(signal_name):
		get_parent().connect(signal_name, _on_trigger_received.bind(false))


# CHECKS ----------------------------------------------------------------------#

func at_interval() -> bool:
	return trigger_receipts % proc_interval == 0

func can_proc() -> bool:
	if proc_limit < 0:
		return true
	elif proc_count < proc_limit:
		return true
	return false
