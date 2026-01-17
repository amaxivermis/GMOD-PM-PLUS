class_name BodygroupManager extends FoldableContainer

# these classes are mainly for keeping track of where the materials belong
class BodygroupInfo:
	var bodygroup_index: int
	var mesh_index: int
	# we get the meshes here, since they're easier to do this way
	var mesh_instance: MeshInstance3D
	var surface_index: int

@onready var list: ItemList = $VBoxContainer/GroupList
@onready var tree = $VBoxContainer/Tree

var tree_groups: Dictionary[TreeItem, BodygroupInfo]
var tree_groups_mesh_count: Array[int] = []

func setup_group_tree(scene):
	
	tree_groups_mesh_count.clear()
	tree_groups.clear()
	
	tree_groups_mesh_count.append(1)
	
	list.clear()
	list.add_item("Body")
	
	var tree = $VBoxContainer/Tree
	tree.clear()
	
	tree.set_column_expand(1, true)
	tree.set_column_expand(2, false)
	# creating the root
	var root = tree.create_item(null, -1)
	
	for i: MeshInstance3D in PMPlusUtils.get_mesh_instances(scene):
		var mesh_found: TreeItem = tree.create_item(root, -1)
		
		mesh_found.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
		mesh_found.set_icon(0, load("res://user_interface/icons/mesh_icon.png"))
		mesh_found.set_icon_max_width(0, 16)
		mesh_found.set_text(0, i.name)
		
		mesh_found.set_expand_right(0, true)
		mesh_found.set_expand_right(1, false)
		mesh_found.set_expand_right(2, false)
		
		mesh_found.set_selectable(0, false)
		mesh_found.set_selectable(1, false)
		mesh_found.set_selectable(2, false)
		
		mesh_found.set_editable(0, false)
		mesh_found.set_editable(1, false)
		mesh_found.set_editable(2, false)
		
		for j in range(0, i.mesh.get_surface_count()):
			var material_found: TreeItem = tree.create_item(mesh_found, -1)
			var info = BodygroupInfo.new()
			info.bodygroup_index = 0
			info.mesh_index = 1
			info.mesh_instance = i
			info.surface_index = j
			tree_groups[material_found] = info
			
			material_found.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
			material_found.set_icon(0, load("res://user_interface/icons/material_icon.png"))
			material_found.set_icon_max_width(0, 16)
			material_found.set_text(0, i.mesh.surface_get_material(j).resource_name)
			
			material_found.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			material_found.set_range(1, 1.0)
			material_found.set_range_config(1, 1.0, 1.0, 1.0)
			material_found.set_editable(1, true)
			
			material_found.set_cell_mode(2, TreeItem.CELL_MODE_CHECK)
			material_found.set_editable(2, true)
			material_found.set_checked(2, true)

func prompt_new_item() -> void:
	var naming = $VBoxContainer/Controls/AddName
	naming.popup_centered()

func add_new_item():
	var naming = $VBoxContainer/Controls/AddName
	var new_name = naming.get_node("LineEdit").text
	
	list.add_item(new_name)
	tree_groups_mesh_count.append(1)
	set_item_name(list.item_count - 1, new_name)

func set_item_name(index, new_name):
	var increment = 0
	
	while find_item(index, new_name) != -1:
		increment += 1
		
		if new_name.ends_with("." + str(increment - 1)):
			new_name = new_name.trim_suffix("." + str(increment - 1))
		
		new_name += "." + str(increment)
	
	list.set_item_text(index, new_name)

func find_item(index, text):
	for i in range(0, list.item_count):
		if list.get_item_text(i) == text and index != i:
			return i
	
	return -1

func _on_remove_pressed() -> void:
	var selected = list.get_selected_items()[0]
	list.remove_item(selected)
	list.select(selected - 1)
	
	for i: TreeItem in tree_groups.keys():
		if tree_groups[i].bodygroup_index == selected:
			tree_groups[i].bodygroup_index = 0
			tree_groups[i].mesh_index = 1
		elif tree_groups[i].bodygroup_index > selected:
			tree_groups[i].bodygroup_index -= 1
	
	_on_group_list_item_selected(selected - 1)

func _on_group_list_item_selected(index: int) -> void:
	$VBoxContainer/Controls/Remove.disabled = (index == 0)
	
	$VBoxContainer/BodyGroupAmount/SpinBox.value = tree_groups_mesh_count[index]
	
	for i: TreeItem in tree_groups.keys():
		update_tree_item(i)

func _on_tree_item_edited() -> void:
	var edited_item = tree.get_edited()
	var edited_column = tree.get_edited_column()
	
	bodygroup_area_check(edited_item, edited_column)
	mesh_index_check(edited_item, edited_column)

func bodygroup_area_check(item, column):
	if column != 2:
		return
	
	if not tree_groups.has(item):
		return
	
	if item.is_checked(2):
		tree_groups[item].bodygroup_index = list.get_selected_items()[0]
		tree_groups[item].mesh_index = 1
	else:
		tree_groups[item].bodygroup_index = 0
		tree_groups[item].mesh_index = 1
	
	update_tree_item(item)

func mesh_index_check(item, column):
	if column != 1:
		return
	
	if not tree_groups.has(item):
		return
	
	tree_groups[item].mesh_index = roundi(item.get_range(1))
	update_tree_item(item)

func _on_spin_box_value_changed(value: float) -> void:
	var current_group = list.get_selected_items()[0]
	tree_groups_mesh_count[current_group] = roundi(value)
	
	# time to check
	for i: TreeItem in tree_groups.keys():
		if tree_groups[i].bodygroup_index != current_group:
			continue
		
		var mesh_index = clampi(tree_groups[i].mesh_index, 1, roundi(value))
		
		tree_groups[i].mesh_index = mesh_index
		update_tree_item(i)

func update_tree_item(item: TreeItem):
	var current_group = list.get_selected_items()[0]
	
	if tree_groups[item].bodygroup_index == current_group:
		item.set_checked(2, true)
		item.set_editable(1, true)
		item.set_range(1, tree_groups[item].mesh_index)
		item.set_range_config(1, 1, tree_groups_mesh_count[current_group], 1)
	else:
		item.set_checked(2, false)
		item.set_editable(1, false)
