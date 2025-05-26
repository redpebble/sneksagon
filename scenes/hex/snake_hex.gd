class_name SnakeHex
extends ObjectHex

signal detach_finished

var propagation_timer : SceneTreeTimer = null
var prev_segment : SnakeHex = null
var next_segment : SnakeHex = null

func _process(_delta: float) -> void:
	queue_redraw() # required for the segment lines to render

func _draw() -> void:
	if next_segment:
		draw_line(Vector2.ZERO, to_local(next_segment.global_position), modulate, 1)

## Calls the provided function first, then has the next segment do the same.
func propagate(method : Callable, delay_interval := 0.0) -> void:
	# defer call for this segment to avoid grid_coords being changed to soon
	method.call_deferred()
	# delay before propogation
	if delay_interval > 0:
		propagation_timer = get_tree().create_timer(delay_interval)
		await propagation_timer.timeout
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
		next_segment.propagate(method, delay_interval)

func detach(duration := 0.2):
	if prev_segment:
		prev_segment.next_segment = null
	MapManager.erase_entity(self)
	flash(0.6, duration)
	await shrink(duration).finished
	detach_finished.emit()

# Waits to free until propogation has been sent from this segment
func _on_shrink_finished():
	if propagation_timer:
		await propagation_timer.timeout
	queue_free()

func is_chain_tweening() -> bool:
	var tweening = move_tween and move_tween.is_running()
	if not tweening and next_segment != null:
		tweening = next_segment.is_chain_tweening()
	return tweening
