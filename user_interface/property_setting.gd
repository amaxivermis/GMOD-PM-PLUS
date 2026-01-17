class_name PropertySetting extends Control

static var settings: Dictionary = {}
var old_value

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_property()
	
	var child = get_child(1)
	
	if child is LineEdit:
		child.text_submitted.connect(value_submitted.bind("text"))
		old_value = child.text
	elif child is SpinBox:
		child.value_changed.connect(value_submitted.bind("value"))
		old_value = child.value
	elif child is OptionButton:
		child.item_selected.connect(value_submitted.bind("selected"))
		old_value = child.selected
	elif child is BaseButton:
		child.toggled.connect(value_submitted.bind("button_pressed"))
		old_value = child.button_pressed

func value_submitted(value, property):
	var child = get_child(1)
	
	ModelEditor.undo_manager.create_action("Set " + name.capitalize())
	ModelEditor.undo_manager.add_do_property(child, property, value)
	ModelEditor.undo_manager.add_undo_property(child, property, old_value)
	ModelEditor.undo_manager.commit_action()
	
	settings[name] = value
	old_value = value

func _process(_delta: float) -> void:
	set_property()

func set_property():
	var child = get_child(1)
	
	if child is LineEdit:
		settings[name] = child.text
	elif child is SpinBox:
		settings[name] = child.value
	elif child is OptionButton:
		settings[name] = child.get_item_text(child.selected)
	elif child is BaseButton:
		settings[name] = child.button_pressed
