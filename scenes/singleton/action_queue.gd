class_name ActionQueue
extends Node
 
var priority_queue : Dictionary[int, Array] = {
	1: [], # Deletions
	2: [], # Movement
	3: [], # Segment Creations
	4: []  # Other Creations
}

func execute_queue():
	#print(priority_queue)
	for action_list : Array in priority_queue.values():
		if action_list.is_empty():
			continue
		for i in action_list:
			var action : Callable = action_list.pop_front()
			var args : Array = action.get_bound_arguments()
			action.get_object().callv(action.get_method(), args)
			print("Executed " + str(action) + " | Arguments: " + str(args))

func queue(action : Callable, priority : int):
	priority_queue[priority].append(action)
	print("Queue ++   ", priority_queue)

func is_empty() -> bool:
	var is_empty = true
	for action_list : Array in priority_queue.values():
		if not action_list.is_empty():
			is_empty = false
			break
	return is_empty
