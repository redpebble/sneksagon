class_name SnakeHex
extends ObjectHex

var prev_segment : SnakeHex = null
var next_segment : SnakeHex = null

func _process(_delta: float) -> void:
	queue_redraw() # required for the segment lines to render

func _draw() -> void:
	if next_segment:
		draw_line(Vector2.ZERO, to_local(next_segment.global_position), modulate, 1)

func chain_anim(method : Callable, delay_interval := 0.0) -> void:
	# defer call for this segment to avoid grid_coords being changed to soon
	method.call_deferred()
	if delay_interval > 0:
		await get_tree().create_timer(delay_interval).timeout
	if next_segment:
		# preserve arguments
		var args = method.get_bound_arguments()
		# switch to the next segment's method
		method = next_segment.get(method.get_method())
		# If position is being changed, pass along this segment's position
		if not args.is_empty() and args[0] is Vector2:
			args[0] = grid_coords
		# rebind arguments
		method = method.bindv(args)
		next_segment.chain_anim(method, delay_interval)

func is_chain_tweening() -> bool:
	var tweening = move_tween and move_tween.is_running()
	if not tweening and next_segment != null:
		tweening = next_segment.is_chain_tweening()
	return tweening
