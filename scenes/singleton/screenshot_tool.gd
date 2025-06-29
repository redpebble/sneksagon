extends Node

@onready var save_dialog : FileDialog = $SaveDialog
@onready var last_pause_state = get_tree().paused


# Setup -----------------------------------------------------------------------#

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	close_dialog()
	var x = ProjectSettings.get("display/window/size/viewport_width")
	var y = ProjectSettings.get("display/window/size/viewport_height")
	save_dialog.max_size = Vector2(x, y) * 0.8
	
	save_dialog.add_button("Generate Filename", true, "generate_filename")
	
	save_dialog.confirmed.connect(_on_save_dialog_confirmed)
	save_dialog.visibility_changed.connect(_on_save_dialog_visibility_changed)
	save_dialog.custom_action.connect(_on_save_dialog_custom_action)



func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if Input.is_action_just_pressed("screenshot"):
		if save_dialog.visible:
			close_dialog()
		else:
			open_dialog()


func save_screenshot(directory : String, filename):
	if not OS.is_debug_build() : return
	
	await RenderingServer.frame_post_draw
	var image = get_viewport().get_texture().get_image()
	var error = image.save_png(directory + "/" + filename)
	
	if error == OK:
		print("Screenshot saved to ", directory)
		OS.shell_show_in_file_manager(directory)
	else:
		printerr("Did not save screenshot to ", directory)


func generate_default_filename() -> String:
	var date = Time.get_date_string_from_system().replace(".","_") 
	var time :String = Time.get_time_string_from_system().replace(":","")
	var project = ProjectSettings.get("application/config/name")
	var filename = project + " " + date + " " + time + ".jpg"
	return filename

# Dialog ----------------------------------------------------------------------#

func open_dialog():
	last_pause_state = get_tree().paused
	get_tree().paused = true
	save_dialog.show()

func close_dialog():
	save_dialog.hide()
	get_tree().paused = last_pause_state

func _on_save_dialog_confirmed() -> void:
	close_dialog()
	save_screenshot(save_dialog.current_dir, save_dialog.get_line_edit().text)

func _on_save_dialog_visibility_changed() -> void:
	if not save_dialog.visible:
		close_dialog()

func _on_save_dialog_custom_action(action : String) -> void:
	match action:
		"generate_filename":
			save_dialog.get_line_edit().text = generate_default_filename()
