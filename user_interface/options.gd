extends HBoxContainer

signal import_model
signal compile_model
signal open_settings

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var model_popup: PopupMenu = $Model.get_popup()
	model_popup.id_pressed.connect(model_option_pressed)
	
	var editor_popup: PopupMenu = $Editor.get_popup()
	editor_popup.id_pressed.connect(editor_option_pressed)
	
	var help_popup: PopupMenu = $Help.get_popup()
	help_popup.id_pressed.connect(help_option_pressed)
	
	$Help/Troubleshooting.close_requested.connect($Help/Troubleshooting.set_visible.bind(false))
	$Help/Licenses.close_requested.connect($Help/Licenses.set_visible.bind(false))

func model_option_pressed(id):
	print("Model press: " + str(id))
	if id == 0:
		import_model.emit()
	elif id == 1:
		compile_model.emit()

func editor_option_pressed(id):
	print("Editor press: " + str(id))
	if id == 0:
		open_settings.emit()
	elif id == 1:
		var undo = InputEventAction.new()
		undo.pressed = true
		undo.action = "undo"
		Input.parse_input_event(undo)
	elif id == 2:
		var redo = InputEventAction.new()
		redo.pressed = true
		redo.action = "redo"
		Input.parse_input_event(redo)

func help_option_pressed(id):
	print("Editor press: " + str(id))
	if id == 1:
		OS.shell_open("https://amaxivermis.neocities.org/news/gmod_pm_plus_guide")
	elif id == 2:
		$Help/Troubleshooting.popup_centered()
	elif id == 3:
		$Help/Licenses.popup_centered()
