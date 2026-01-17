extends VBoxContainer

static var bones_to_generate = [
	
	"ValveBiped.Bip01_Neck1",
	"ValveBiped.Bip01_Head1",
	"ValveBiped.Bip01_Spine1",
	"ValveBiped.Bip01_Spine4",
	"ValveBiped.Bip01_Pelvis",
	
	"ValveBiped.Bip01_R_Clavicle",
	"ValveBiped.Bip01_R_UpperArm",
	"ValveBiped.Bip01_R_Forearm",
	"ValveBiped.Bip01_R_Hand",
	
	"ValveBiped.Bip01_L_Clavicle",
	"ValveBiped.Bip01_L_UpperArm",
	"ValveBiped.Bip01_L_Forearm",
	"ValveBiped.Bip01_L_Hand",
	
	"ValveBiped.Bip01_R_Thigh",
	"ValveBiped.Bip01_R_Calf",
	"ValveBiped.Bip01_R_Foot",
	
	"ValveBiped.Bip01_L_Thigh",
	"ValveBiped.Bip01_L_Calf",
	"ValveBiped.Bip01_L_Foot",
]

static var bones_to_item: Array[TreeItem] = []

var scene

func _ready() -> void:
	visible = false

func update_tree():
	await RenderingServer.frame_post_draw
	
	var skeleton = PMPlusUtils.get_skeleton(scene)
	
	bones_to_item.clear()
	
	var items: Array[TreeItem] = []
	var stuff_to_look = []
	
	# find every bone without a parent
	for i in range(0, skeleton.get_bone_count()):
		if skeleton.get_bone_parent(i) == -1:
			stuff_to_look.append(i)
	
	items.resize(skeleton.get_bone_count())
	
	var bones_tree = $Inclusion/SelectedBones
	bones_tree.clear()
	
	# creating the root
	bones_tree.create_item(null, -1)
	
	# adding the bones first
	
	for i in stuff_to_look:
		var root = bones_tree.create_item(null, 0)
		root.set_text(0, str(skeleton.get_bone_name(i)) )
		root.set_expand_right(1, false)
		root.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
		root.set_editable(1, true)
		root.set_checked(1, true)
		items[i] = root
	
	bones_tree.set_column_expand(1, false)
	
	var loop_index = 0
	while loop_index < stuff_to_look.size():
		var index = stuff_to_look[loop_index]
		# we will look at these
		for j in skeleton.get_bone_children(index):
			var newitem: TreeItem = bones_tree.create_item(items[index], -1)
			newitem.set_text(0, str(skeleton.get_bone_name(j)) )
			
			newitem.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
			newitem.set_editable(1, true)
			newitem.set_checked(1, true)
			
			if bones_to_generate.has(newitem.get_text(0)):
				newitem.set_editable(1, false)
			
			stuff_to_look.push_back(j)
			items[j] = newitem
		
		loop_index += 1
	
	bones_to_item = items

func generate_collisions():
	
	var skeleton = PMPlusUtils.get_skeleton(scene)
	var mesh_array = PMPlusUtils.get_single_mesh(scene)
	
	for i in skeleton.get_children():
		if i.name.contains("ValveBiped_Bip01"):
			i.free()
	
	for i in bones_to_generate:
		# copy the data
		var self_array = []
		self_array.resize(Mesh.ARRAY_MAX)
		
		var bone_index = skeleton.find_bone(i)
		
		if bone_index == -1:
			continue
		
		var new_vertices = PackedVector3Array()
		
		var indices_mapped: Array[Vector3] = []
		for j in mesh_array[Mesh.ARRAY_INDEX]:
			indices_mapped.append(mesh_array[Mesh.ARRAY_VERTEX][j])
		
		for j in range(0, mesh_array[Mesh.ARRAY_VERTEX].size()):
			if vertex_part_of_bone(j, mesh_array, skeleton, bone_index):
				var vertex_pos = mesh_array[Mesh.ARRAY_VERTEX][j] #/ skeleton.get_bone_pose(0).basis.get_scale()
				new_vertices.append(skeleton.get_bone_global_pose(bone_index).affine_inverse() * vertex_pos)
		
		var bone_attachment = BoneAttachment3D.new()
		bone_attachment.name = skeleton.get_bone_name(bone_index)
		skeleton.add_child(bone_attachment)
		bone_attachment.bone_idx = bone_index
		
		var mesh_instance = MeshInstance3D.new()
		
		mesh_instance.material_override = load("res://collisions/override_material.tres")
		mesh_instance.material_overlay = load("res://collisions/overlay_material.tres")
		
		mesh_instance.mesh = $MeshGen.GenerateConvexHull(new_vertices)
		bone_attachment.add_child(mesh_instance)

func vertex_part_of_bone(index: int, array_data: Array, skeleton: Skeleton3D, bone_index: int) -> bool:
	for p in range(0, 4):
		var bone_index_attached: int = array_data[Mesh.ARRAY_BONES][(index * 4) + p]
		var bone_weight_attached: float = array_data[Mesh.ARRAY_WEIGHTS][(index * 4) + p]
		
		if not bones_to_item[bone_index_attached].is_checked(1) && bone_weight_attached > 0.0002:
			return false
		
		if bone_weight_attached <= 0.4:
			continue
		
		var current_bone = bone_index_attached
		
		while current_bone != -1:
			if current_bone == bone_index:
				#var length = (skeleton.get_bone_global_pose(bone_index).origin - array_data[Mesh.ARRAY_VERTEX][index]).length()
				return true
			if bones_to_generate.has(skeleton.get_bone_name(current_bone)):
				return false
			
			current_bone = skeleton.get_bone_parent(current_bone)
		
		#if bone_index == bone_index_attached:
		#	var length = (skeleton.get_bone_global_pose(bone_index).origin - array_data[Mesh.ARRAY_VERTEX][index]).length()
		#	if length > 0.1:
		#		return true
	
	return false

func set_scene(imported_scene):
	visible = true
	scene = imported_scene
	update_tree()
