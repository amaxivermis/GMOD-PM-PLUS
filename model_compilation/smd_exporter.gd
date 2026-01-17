class_name SMDExporter extends Node

const inches_to_metres = 0.0254

static var valve_bones = [
	"ValveBiped.Bip01_Pelvis",
	"ValveBiped.Bip01_Spine",
	"ValveBiped.Bip01_Spine1",
	"ValveBiped.Bip01_Spine2",
	"ValveBiped.Bip01_Spine4",
	"ValveBiped.Bip01_Neck1",
	"ValveBiped.Bip01_Head1",
	"ValveBiped.Bip01_R_Clavicle",
	"ValveBiped.Bip01_R_UpperArm",
	"ValveBiped.Bip01_R_Forearm",
	"ValveBiped.Bip01_R_Hand",
	"ValveBiped.Bip01_R_Finger0",
	"ValveBiped.Bip01_R_Finger01",
	"ValveBiped.Bip01_R_Finger02",
	"ValveBiped.Bip01_R_Finger1",
	"ValveBiped.Bip01_R_Finger11",
	"ValveBiped.Bip01_R_Finger12",
	"ValveBiped.Bip01_R_Finger2",
	"ValveBiped.Bip01_R_Finger21",
	"ValveBiped.Bip01_R_Finger22",
	"ValveBiped.Bip01_R_Finger3",
	"ValveBiped.Bip01_R_Finger31",
	"ValveBiped.Bip01_R_Finger32",
	"ValveBiped.Bip01_R_Finger4",
	"ValveBiped.Bip01_R_Finger41",
	"ValveBiped.Bip01_R_Finger42",
	"ValveBiped.Bip01_L_Clavicle",
	"ValveBiped.Bip01_L_UpperArm",
	"ValveBiped.Bip01_L_Forearm",
	"ValveBiped.Bip01_L_Hand",
	"ValveBiped.Bip01_L_Finger0",
	"ValveBiped.Bip01_L_Finger01",
	"ValveBiped.Bip01_L_Finger02",
	"ValveBiped.Bip01_L_Finger1",
	"ValveBiped.Bip01_L_Finger11",
	"ValveBiped.Bip01_L_Finger12",
	"ValveBiped.Bip01_L_Finger2",
	"ValveBiped.Bip01_L_Finger21",
	"ValveBiped.Bip01_L_Finger22",
	"ValveBiped.Bip01_L_Finger3",
	"ValveBiped.Bip01_L_Finger31",
	"ValveBiped.Bip01_L_Finger32",
	"ValveBiped.Bip01_L_Finger4",
	"ValveBiped.Bip01_L_Finger41",
	"ValveBiped.Bip01_L_Finger42",
	"ValveBiped.Bip01_R_Thigh",
	"ValveBiped.Bip01_R_Calf",
	"ValveBiped.Bip01_R_Foot",
	"ValveBiped.Bip01_R_Toe0",
	"ValveBiped.Bip01_L_Thigh",
	"ValveBiped.Bip01_L_Calf",
	"ValveBiped.Bip01_L_Foot",
	"ValveBiped.Bip01_L_Toe0",
]

class SMDBone:
	var name: String
	var parent_name: String
	# the reason this is global pose is so structuring the model to have proportions makes it easy
	var global_pose: Transform3D

static func compile_mesh_data_to_smd(data: PackedStringArray, bone_remap: Dictionary, skeleton: Skeleton3D, mesh_data, mesh_data_original, mat_name):
	for k in range(0, mesh_data[Mesh.ARRAY_INDEX].size()):
		var line_data = ""
		@warning_ignore("integer_division")
		var skips = 1 + (k / 3)
		k += skips
		
		if (k - skips) % 3 == 0:
			data[k - 1] = mat_name
				
		# now the data
		# reversing the order, i see this with gmod :\
		var index_reverse = k - skips
		@warning_ignore("integer_division")
		index_reverse = (2 - (index_reverse % 3)) + ((index_reverse / 3) * 3)
		var vertex_index = mesh_data[Mesh.ARRAY_INDEX][index_reverse]
		
		var position: Vector3 = (skeleton.global_transform * mesh_data[Mesh.ARRAY_VERTEX][vertex_index]) / inches_to_metres
		var normal: Vector3 = mesh_data[Mesh.ARRAY_NORMAL][vertex_index]
		var uv: Vector2 = mesh_data[Mesh.ARRAY_TEX_UV][vertex_index]
		#uv = Vector2.ONE - uv
				
		line_data += "0 " + str(position.x) + " " + str(-position.z) + " " + str(position.y) + "    "
		line_data += str(normal.x) + " " + str(-normal.z) + " " + str(normal.y) + "    "
		line_data += str(uv.x) + " " + str(1.0 - uv.y)
				
		# weight time
		#var eight_bones = (i[0].surface_get_format(j) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS) == Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		#var bone_count = 8 if eight_bones else 4
		var bone_count = 4
		var bones_found = 0
		var bone_data = " [replace] "
		
		for p in range(0, bone_count):
			var bone_index: int = mesh_data_original[Mesh.ARRAY_BONES][(vertex_index * bone_count) + p]
			var bone_weight: float = mesh_data_original[Mesh.ARRAY_WEIGHTS][(vertex_index * bone_count) + p]
			
			bone_index = bone_remap[bone_index]
			
			if bone_weight > 0.00000002:
				bones_found += 1
				bone_data += str(bone_index) + " " + str(bone_weight) + " "
		
		bone_data = bone_data.replace("[replace]", str(bones_found))
		line_data += bone_data
		
		data[k] = line_data

static func generate_arms_from_meshes(skeleton: Skeleton3D, original_meshes: Array[Mesh], new_meshes: Array[Mesh], bones: Array[SMDBone], bone_remap: Dictionary):
	var data = ""
	
	for i in range(0, new_meshes.size()):
		var materials = original_meshes[i].get_surface_count()
		
		for j in range(0, materials):
			var mesh_data = new_meshes[i].surface_get_arrays(j)
			var mesh_data_original = original_meshes[i].surface_get_arrays(j)
			var mat_name = original_meshes[i].surface_get_material(j).resource_name
			
			# the reason we are doing this is to delete triangles and vertices that shouldn't be in the arms
			for k in range(0, mesh_data[Mesh.ARRAY_INDEX].size() / 3):
				var triangle_data = mat_name + "\n"
				var should_triangle_be_created = true
				
				# loop through the triangle now
				for l in range(0, 3):
					
					var triangle_index = (k * 3) + (2 - l)
					triangle_index = mesh_data[Mesh.ARRAY_INDEX][triangle_index]
					#triangle_index =  (2 - (triangle_index % 3)) + ((triangle_index / 3) * 3)
					
					if not is_arm_vertex(mesh_data_original, triangle_index, bones, bone_remap):
						should_triangle_be_created = false
						break
					
					triangle_data += get_vertex_smd_line(mesh_data, mesh_data_original, triangle_index, skeleton, bone_remap) + "\n"
				
				if should_triangle_be_created:
					data += triangle_data
	
	return data

static func get_vertex_smd_line(mesh_data, mesh_data_original, vertex_index: int, skeleton: Skeleton3D , bone_remap: Dictionary):
	var line_data = ""
	
	var position: Vector3 = (skeleton.global_transform * mesh_data[Mesh.ARRAY_VERTEX][vertex_index]) / inches_to_metres
	var normal: Vector3 = mesh_data[Mesh.ARRAY_NORMAL][vertex_index]
	var uv: Vector2 = mesh_data[Mesh.ARRAY_TEX_UV][vertex_index]
	#uv = Vector2.ONE - uv
	
	line_data += "0 " + str(position.x) + " " + str(-position.z) + " " + str(position.y) + "    "
	line_data += str(normal.x) + " " + str(-normal.z) + " " + str(normal.y) + "    "
	line_data += str(uv.x) + " " + str(1.0 - uv.y)
	
	# weight time
	#var eight_bones = (i[0].surface_get_format(j) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS) == Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
	#var bone_count = 8 if eight_bones else 4
	var bone_count = 4
	var bones_found = 0
	var bone_data = " [replace] "
	
	for p in range(0, bone_count):
		var bone_index: int = mesh_data_original[Mesh.ARRAY_BONES][(vertex_index * bone_count) + p]
		var bone_weight: float = mesh_data_original[Mesh.ARRAY_WEIGHTS][(vertex_index * bone_count) + p]
		
		bone_index = bone_remap[bone_index]
		
		if bone_weight > 0.00000002:
			bones_found += 1
			bone_data += str(bone_index) + " " + str(bone_weight) + " "
	
	bone_data = bone_data.replace("[replace]", str(bones_found))
	line_data += bone_data
	return line_data

static func is_arm_vertex(mesh: Array, index: int, bones: Array[SMDBone], bone_remap: Dictionary):
	#index = remap[index]
	
	# loop through the weights
	var bone_count = 4
	var total_weight = 0.0
	
	for p in range(0, bone_count):
		var bone_index: int = mesh[Mesh.ARRAY_BONES][(index * bone_count) + p]
		# remap since some bones are different
		bone_index = bone_remap[bone_index]
		
		var bone_weight: float = mesh[Mesh.ARRAY_WEIGHTS][(index * bone_count) + p]
		
		# skip like it is :)
		
		var bone_parent = bones[bone_index]
		
		while bone_parent != null:
			if bone_parent.name == "ValveBiped.Bip01_R_UpperArm" or bone_parent.name == "ValveBiped.Bip01_L_UpperArm":
				if bone_weight > 0.01:
					total_weight += bone_weight
					break
				#	return true
			
			bone_parent = get_parent_bone(bones, bone_parent)
	
	return total_weight > 0.85

static func generate_collisions_smd_data(skeleton: Skeleton3D, bones: Array[SMDBone]):
	var data = ""
	
	for i in skeleton.get_children():
		if i is not BoneAttachment3D:
			continue
		
		if not i.name.contains("ValveBiped_"):
			continue
		
		var adjusted_name = i.name.replace("ValveBiped_", "ValveBiped.")
		
		var mesh = (i.get_child(0)as MeshInstance3D).mesh
		
		if mesh == null:
			continue
		
		var mesh_data = mesh.surface_get_arrays(0)
		
		for j in range(0, mesh_data[Mesh.ARRAY_INDEX].size()):
			if j % 3 == 0:
				data += "phy\n"
			
			var triangle_index = (2 - (j % 3)) + ((j / 3) * 3)
			triangle_index = mesh_data[Mesh.ARRAY_INDEX][triangle_index]
			
			var position: Vector3 = mesh_data[Mesh.ARRAY_VERTEX][triangle_index]
			position = i.global_transform * position
			position /= inches_to_metres
			
			var normal: Vector3 = Vector3.UP
			var uv: Vector2 = Vector2.ZERO
			#uv = Vector2.ONE - uv
					
			data += "0 " + str(position.x) + " " + str(-position.z) + " " + str(position.y) + "    "
			data += str(normal.x) + " " + str(-normal.z) + " " + str(normal.y) + "    "
			data += str(uv.x) + " " + str(1.0 - uv.y)
			
			data += " 1 " + str(get_bone_index(bones, adjusted_name)) + " 1.0\n"
	
	return data

static func gather_skeleton_nodes_with_proportion(skeleton: Skeleton3D, reference_skeleton: Skeleton3D):
	var bones: Array[SMDBone] = []
	
	for i in range(0, skeleton.get_bone_count()):
		var bone: SMDBone = SMDBone.new()
		bone.name = skeleton.get_bone_name(i)
		bone.global_pose = skeleton.global_transform * skeleton.get_bone_global_pose(i)
		bone.global_pose.basis = bone.global_pose.basis.scaled(Vector3.ONE / bone.global_pose.basis.get_scale())
		
		var parent = skeleton.get_bone_parent(i)
		
		if parent == -1:
			bone.parent_name = ""
		else:
			bone.parent_name = skeleton.get_bone_name(parent)
		
		# reparent the bones that should be reparented and ones that don't exist
		var ref_bone_index = reference_skeleton.find_bone(bone.name)
		if ref_bone_index != -1:
			var ref_basis = reference_skeleton.get_bone_global_pose(ref_bone_index).basis
			bone.global_pose.basis = ref_basis #ref_basis.scaled(bone.global_pose.basis.get_scale())
			
			var ref_bone_parent_index = reference_skeleton.get_bone_parent(ref_bone_index)
				
			if ref_bone_parent_index != -1:
				bone.parent_name = reference_skeleton.get_bone_name(ref_bone_parent_index)
					
				#print("new parent for " + bone.name + " is " + bone.parent_name)
			
		bones.append(bone)
	
	# now add in the bones that don't exist yet
	for i in valve_bones:
		var index = skeleton.find_bone(i)
		if index >= 0:
			continue
		
		# time to add it
		var ref_index = reference_skeleton.find_bone(i)
		var ref_index_parent = reference_skeleton.get_bone_parent(ref_index)
		var parent_name = ""
		
		var parent_global_pose = Transform3D.IDENTITY
		
		
		
		if ref_index_parent != -1:
			parent_name = reference_skeleton.get_bone_name(ref_index_parent)
			
			var ref_index_parent_2 = get_bone_index(bones, parent_name)
			
			if ref_index_parent_2 != -1:
				parent_global_pose = bones[ref_index_parent_2].global_pose
				#parent_global_pose.origin /= skeleton.global_basis.get_scale()
		
		var bone: SMDBone = SMDBone.new()
		bone.name = i
		bone.parent_name = parent_name
		
		# just adding the pose like this, and scale correctly
		var local_bone_pose = reference_skeleton.get_bone_pose(ref_index)
		#local_bone_pose.origin /= root_scale
		
		bone.global_pose = parent_global_pose * local_bone_pose
		
		var index_to_add_at = 0
		
		while bones[index_to_add_at].name != parent_name:
			index_to_add_at += 1
			
			if index_to_add_at >= bones.size():
				return null
		
		bones.insert(index_to_add_at + 1, bone)
	
	# now remove every bone above the pelvis area
	var pelvis = get_bone_index(bones, valve_bones[0])
	var parent = get_parent_bone(bones, bones[pelvis])
	
	while parent != null:
		var new_parent = get_parent_bone(bones, parent)
		bones.erase(parent)
		parent = new_parent
	
	bones = sort_bone_array(bones)
	
	# now we check every bone and reparent the remaing to the pelvis
	for i in range(1, bones.size()):
		var rel_parent = get_parent_bone(bones, bones[i])
		
		if rel_parent == null && bones[i].name != bones[pelvis].name:
			bones[i].parent_name = bones[pelvis].name
	
	
	# do the hand stuff
	#for side in range(0, 2):
		#var prefix = "ValveBiped.Bip01_R_Finger" if side == 0 else "ValveBiped.Bip01_L_Finger"
		#var hand = "ValveBiped.Bip01_R_Hand" if side == 0 else "ValveBiped.Bip01_L_Hand"
		#var hand_index = get_bone_index(bones, hand)
		#
		#var new_basis = Basis.IDENTITY
		#new_basis.x = (bones[hand_index].global_pose.origin - get_parent_bone(bones, bones[hand_index] ).global_pose.origin).normalized()
		#
		## finding the z of the bone, look at all the fingers, and fine the lowest and highest x
		#var lowest_num = 10
		#var highest_num = -1
		#
		#for j in bones:
			#if j.parent_name != hand:
				#continue
			#
			#if not j.name.contains(prefix):
				#continue
			#
			#var number = j.name.trim_prefix(prefix).substr(0, 1).to_int()
			#
			#if number > highest_num:
				#highest_num = number
			#elif number < lowest_num:
				#lowest_num = number
		#
		## our character has no fingers, damn you Joel for that call
		#if highest_num <= -1:
			#break
		#
		#new_basis.z = (bones[get_bone_index(bones, prefix + str(highest_num))].global_pose.origin - bones[get_bone_index(bones, prefix + str(lowest_num))].global_pose.origin).normalized()
		## and now we can do a cross product
		##new_basis.y = new_basis.z.cross(new_basis.x)
		#
		## change some stuff, first the hand and then rotate the fingers
		#var angle_roll = new_basis.z.signed_angle_to(bones[hand_index].global_pose.basis.z, bones[hand_index].global_pose.basis.x)
		#
		## now time to roll
		#var bone_parents_with_children = [ get_parent_bone(bones, bones[hand_index]) ]
		#
		#for i: SMDBone in bone_parents_with_children:
			#for j in bones:
				#if j.parent_name != i.name:
					#continue
				#
				#bone_parents_with_children.append(j)
				#
				#j.global_pose.basis = j.global_pose.basis.rotated(j.global_pose.basis.x ,-angle_roll)
	
	return bones

static func sort_bone_array(bones: Array[SMDBone]):
	#var pelvis = get_bone_index(bones, valve_bones[0])
	
	var biped_bones: Array[SMDBone] = []
	biped_bones.resize(valve_bones.size())
	
	for i in bones:
		var index = valve_bones.find(i.name)
		if valve_bones.has(i.name):
			biped_bones[index] = i
	
	# now clear out all the arrays that are empty
	for i in range(0, biped_bones.size()):
		if biped_bones[i] == null:
			biped_bones.remove_at(i)
	
	# this might be a disaster but add in the bones that aren't there
	for i in bones:
		if not biped_bones.has(i):
			biped_bones.append(i)
	
	return biped_bones

static func generate_skeleton_nodes(bones: Array[SMDBone]) -> String:
	var data = ""
	
	for index in range(0, bones.size()):
		data += str(index) + " \"" + bones[index].name + "\" " + str(get_bone_index(bones, bones[index].parent_name)) + "\n"
	
	return data

static func generate_skeleton_transforms(skeleton : Skeleton3D, bones: Array[SMDBone]) -> String:
	var data = ""
	
	for i in range(0, bones.size()):
		
		var bone_transform = bones[i].global_pose
		#bone_transform.basis = bone_transform.basis.scaled(Vector3.ONE / bone_transform.basis.get_scale())
		
		var parent_transform = skeleton.global_transform
		var parent_bone = get_parent_bone(bones, bones[i])
		
		if parent_bone != null:
			parent_transform = parent_bone.global_pose
			#parent_transform.basis = parent_transform.basis.scaled(Vector3.ONE / parent_transform.basis.get_scale())
		
		# convert the bone transform to a local one, but keep the pose
		bone_transform = parent_transform.affine_inverse() * bone_transform
		# now that it's local, we do some operations to correct to bone stuff
		#bone_transform.origin *= root_scale
		
		if i == 0:
			bone_transform = skeleton.global_transform * bone_transform
			bone_transform.origin = Vector3(bone_transform.origin.x, -bone_transform.origin.z, bone_transform.origin.y)
			#bone_transform.origin.z += height_offset
		
		bone_transform.origin /= inches_to_metres
		
		var new_rot = bone_transform.basis.get_euler(5)
		if i == 0:
			new_rot.x += PI / 2.0
		
		data += str(i) + " " + str(bone_transform.origin.x) + " " + str(bone_transform.origin.y) + " " + str(bone_transform.origin.z) + "    " + str(new_rot.x) + " " + str(new_rot.y) + " " + str(new_rot.z) + "\n"
	
	return data

static func get_parent_bone(bones: Array[SMDBone], bone: SMDBone) -> SMDBone:
	for i in bones:
		if i.name == bone.parent_name:
			return i
	
	return null

static func generate_bone_remap(bones: Array[SMDBone], original_skeleton: Skeleton3D) -> Dictionary:
	var bone_remap: Dictionary = {}
	
	# doing this because it seems to break whenever i remove the parent bones
	var pevlis_index = original_skeleton.find_bone(valve_bones[0])
	if pevlis_index != -1:
		for i in range(0, pevlis_index + 1):
			bone_remap[i] = get_bone_index(bones, valve_bones[0])
	
	
	for i in range(0, original_skeleton.get_bone_count()):
		var bone_name = original_skeleton.get_bone_name(i)
		
		for j in range(0, bones.size()):
			if bones[j].name == bone_name:
				bone_remap[i] = j
				break
	
	return bone_remap

static func get_bone_index(bones: Array[SMDBone], bone_name):
	if bone_name == "":
		return -1
	
	for i in range(0, bones.size()):
		if bones[i].name == bone_name:
			return i
	
	return -1
