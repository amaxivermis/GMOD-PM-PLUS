class_name ParameterList extends VBoxContainer

#This class is different, it contains sets of properties
static var list: Array[ParameterList] = []
var parameters: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_properties()
	list.append(self)

func _process(delta: float) -> void:
	set_properties()

func set_properties():
	for i in get_children():
		set_property(i)

func set_property(node):
	var child = node.get_child(1)
	
	if child is LineEdit:
		parameters[node.name] = child.text
	elif child is SpinBox:
		parameters[node.name] = child.value
	elif child is OptionButton:
		parameters[node.name] = child.get_item_text(child.selected)
	elif child is BaseButton:
		parameters[node.name] = child.button_pressed
