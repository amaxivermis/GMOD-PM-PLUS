class_name ApplicationSetting extends Control

static var settings: Dictionary = {}
var file_browser: FileDialog

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if settings == {}:
		var config_file = FileAccess.open("user://config.json", FileAccess.READ)
		
		if config_file != null:
			var json_data = config_file.get_as_text()
			settings = JSON.parse_string(json_data)
	
	refresh_property()
	
	var load_button = get_node_or_null("Load")
	
	if load_button != null:
		load_button.pressed.connect(Callable(self, prompt_file.get_method()))
		
		file_browser = FileDialog.new()
		add_child(file_browser)
		file_browser.use_native_dialog = true
		file_browser.access = FileDialog.ACCESS_FILESYSTEM
		
		if load_button.has_meta("directory"):
			file_browser.file_mode = FileDialog.FILE_MODE_OPEN_DIR
			file_browser.dir_selected.connect(Callable(self, exe_opened.get_method()))
		else:
			file_browser.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			file_browser.add_filter("*.exe")
			file_browser.file_selected.connect(Callable(self, exe_opened.get_method()))
	
	set_property()
	
	#MinimalTheme.singleton.start()

func set_property():
	var child = get_child(1)
	
	if child is LineEdit:
		settings[name] = child.text
	elif child is CheckBox:
		settings[name] = child.button_pressed
	elif child is OptionButton:
		settings[name] = child.get_item_text(child.selected)
	elif child is ColorPickerButton:
		settings[name] = child.color
	elif child is SpinBox:
		settings[name] = child.value
	
	save_config()

func refresh_property():
	
	if not settings.has(name):
		return
	
	var child = get_child(1)
	
	if child is LineEdit:
		child.text = settings[name]
	elif child is CheckBox:
		child.button_pressed = settings[name]
	elif child is ColorPickerButton:
		child.color = settings[name]
	elif child is SpinBox:
		child.value = settings[name]

func save_config():
	var json_string = JSON.stringify(settings, "\t")
	
	var config_file = FileAccess.open("user://config.json", FileAccess.WRITE)
	config_file.store_string(json_string)
	config_file.close()

func prompt_file():
	file_browser.popup_centered()

func exe_opened(path: String):
	get_child(1).text = path
	set_property()
