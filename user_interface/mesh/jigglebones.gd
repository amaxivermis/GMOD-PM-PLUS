extends FoldableContainer

@onready var jiggle_bone_paremeters: PackedScene = load("res://user_interface/mesh/jiggle_bone_parameters.tscn")

var current_skeleton: Skeleton3D
var parameters: Array[ParameterList]

func reset() -> void:
	parameters.clear()
	
	for i in $VBoxContainer/Elements.get_children():
		i.queue_free()

func _on_add_pressed() -> void:
	var full_container = Control.new()
	full_container.custom_minimum_size.y = 295.0 + 14.0
	#full_container.custom_minimum_size.x = 0.0
	#full_container.set_anchors_preset(PRESET_HCENTER_WIDE)
	$VBoxContainer/Elements.add_child(full_container)
	
	var full_panel = ColorRect.new()
	full_panel.color = Color.BLACK
	full_panel.set_anchors_preset(PRESET_FULL_RECT)
	
	full_container.add_child(full_panel)
	
	var h_box = HBoxContainer.new()
	h_box.set_anchors_preset(PRESET_FULL_RECT)
	full_container.add_child(h_box)
	
	var param_list = jiggle_bone_paremeters.instantiate() as ParameterList
	
	
	var start: OptionButton = param_list.get_node("Start/OptionButton")
	var end: OptionButton = param_list.get_node("End/OptionButton")
	
	for i in range(0, current_skeleton.get_bone_count()):
		var bone_name = current_skeleton.get_bone_name(i)
		start.add_item(bone_name)
		end.add_item(bone_name)
	
	start.size = start.custom_minimum_size
	end.size = end.custom_minimum_size
	
	h_box.add_child(param_list)
	param_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parameters.append(param_list)
	
	
	var v_box = VBoxContainer.new()
	v_box.alignment = BoxContainer.ALIGNMENT_CENTER
	#box2.size_flags_horizontal = Control.SIZE_EXPAND
	h_box.add_child(v_box)
	
	var delete_button: Button = Button.new()
	delete_button.expand_icon = true
	delete_button.icon = load("res://user_interface/icons/trash.svg")
	delete_button.custom_minimum_size = Vector2(24.0, 24.0)
	delete_button.pressed.connect(delete_instance.bind(full_container, param_list))
	v_box.add_child(delete_button)
	
	change_backgrounds()

func delete_instance(node, list: ParameterList):
	node.queue_free()
	parameters.erase(list)
	
	change_backgrounds()

func change_backgrounds():
	var elements_children = $VBoxContainer/Elements.get_children()
	
	for i in range(0, elements_children.size()):
		var control = elements_children[i]
		
		if control.is_queued_for_deletion():
			continue
		
		var param_index = parameters.find(control.get_child(1).get_child(0))
		
		if param_index == -1:
			continue
		
		var panel = control.get_child(0) as Control
		panel.self_modulate.a = 0.2 if (param_index % 2 == 0) else 0.05
