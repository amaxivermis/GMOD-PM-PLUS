extends VBoxContainer

signal bone_renamed

var scene
@onready var undo_redo: UndoRedo = UndoRedo.new()
var skeleton: Skeleton3D
var bone_mappings = []
var current_rotated = -1

var bones_display: MultiMeshInstance3D

#these are used to rename everything
var arm_bones = [
	"hand",
	"clavicle",
	"shoulder",
	"arm",
]

# the reason the toe isn't included is because there should not be that many, so we just check for the child on the foot
var leg_bones = [
	"leg",
	"thigh",
	"calf",
	"knee",
	"foot"
]

var spine_bones = [
	"neck",
	"spine",
	"pelvis",
	"bust",
	"hip",
	"waist",
	"chest",
	"head",
	"torso"
]

var banned_terms = [
	"end_",
	"_end",
	"_sub"
]

func _ready() -> void:
	visible = false

func set_scene(imported_scene):
	visible = true
	scene = imported_scene
	
	var child = scene.get_child(0)
	skeleton = child.get_child(0)
	var old_basis = child.basis
	var child_basis = skeleton.get_bone_pose(0)
	child.transform = Transform3D.IDENTITY
	
	child_basis.basis = old_basis * child_basis.basis
	
	skeleton.set_bone_pose(0, child_basis)
	
	generate_bone_gizmos(skeleton)

func generate_bone_gizmos(skeleton: Skeleton3D):
	
	var bone_mesh: ArrayMesh = load("res://collisions/bone.obj")
	
	bones_display = MultiMeshInstance3D.new()
	skeleton.add_child(bones_display)
	
	bones_display.multimesh = MultiMesh.new()
	bones_display.multimesh.mesh = bone_mesh
	bones_display.multimesh.use_colors = true
	bones_display.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	bones_display.multimesh.instance_count = skeleton.get_bone_count()
	bones_display.material_override = ShaderMaterial.new()
	bones_display.material_override.shader = load("res://collisions/bone.gdshader")
	
	var bones_needed = []
	
	for i in range(0, skeleton.get_bone_count()):
		
		var parent_transform = skeleton.global_transform * skeleton.get_bone_global_pose(i)
		
		for j in skeleton.get_bone_children(i):
			var child_transform = skeleton.global_transform * skeleton.get_bone_global_pose(j)
			
			var bone_direction = child_transform.origin - parent_transform.origin
			var bone_distance = bone_direction.length()
			bone_direction = bone_direction.normalized()
			
			if bone_distance < 0.0002:
				continue
			
			var bone_transform = Transform3D.IDENTITY
			bone_transform.origin = parent_transform.origin
			
			bone_transform.basis.y = bone_direction
			if bone_direction != Vector3.BACK:
				bone_transform.basis.x = Vector3.BACK.cross(bone_direction)
				bone_transform.basis.z = bone_transform.basis.x.cross(bone_direction)
			else:
				bone_transform.basis.z = Vector3.RIGHT.cross(bone_direction)
				bone_transform.basis.x = bone_transform.basis.z.cross(bone_direction)
				
			bone_transform.basis = bone_transform.basis.scaled(Vector3.ONE * bone_distance)
			
			bones_needed.append(bone_transform)
	
	bones_display.multimesh.instance_count = bones_needed.size()
	
	for i in range(0, bones_needed.size()):
		bones_display.multimesh.set_instance_transform(i, bones_needed[i])

func update_tree():
	await RenderingServer.frame_post_draw
	
	
	
	var items = []
	var stuff_to_look = []
	
	# find every bone without a parent
	for i in range(0, skeleton.get_bone_count()):
		if skeleton.get_bone_parent(i) == -1:
			stuff_to_look.append(i)
	
	items.resize(skeleton.get_bone_count())
	
	var tree = $Bones/Tree
	tree.clear()
	
	# creating the root
	tree.create_item(null, -1)
	bone_mappings.clear()
	
	# adding the bones first
	
	for i in stuff_to_look:
		var root = tree.create_item(null, 0)
		root.set_text(0, str(skeleton.get_bone_name(i)) )
		items[i] = root
	
	var loop_index = 0
	while loop_index < stuff_to_look.size():
		var index = stuff_to_look[loop_index]
		# we will look at these
		for j in skeleton.get_bone_children(index):
			var newitem: TreeItem = tree.create_item(items[index], -1)
			newitem.set_text(0, str(skeleton.get_bone_name(j)) )
			newitem.set_editable(0, true)
			
			stuff_to_look.push_back(j)
			items[j] = newitem
			
		
		loop_index += 1
	bone_mappings = items
	
	#var root = $Tree.create_item(null, 0)
	#root.set_text(0, str(skeleton.get_bone_name(0)) )


func _process(delta: float) -> void:
	if skeleton == null:
		return
	
	var bones_needed = []
	var colours = []
	
	for i in range(0, skeleton.get_bone_count()):
		
		var parent_transform = skeleton.get_bone_global_pose(i)
		
		for j in skeleton.get_bone_children(i):
			var child_transform = skeleton.get_bone_global_pose(j)
			
			var bone_direction = child_transform.origin - parent_transform.origin
			var bone_distance = bone_direction.length()
			bone_direction = bone_direction.normalized()
			
			if bone_distance < 0.0002:
				continue
			
			var bone_transform = Transform3D.IDENTITY
			bone_transform.origin = parent_transform.origin
			
			bone_transform.basis.y = bone_direction
			if abs(bone_direction.z) < 0.6:
				bone_transform.basis.x = Vector3.BACK.cross(bone_direction)
				bone_transform.basis.z = bone_transform.basis.x.cross(bone_direction)
			else:
				bone_transform.basis.z = Vector3.RIGHT.cross(bone_direction)
				bone_transform.basis.x = bone_transform.basis.z.cross(bone_direction)
			
			bone_transform.basis = bone_transform.basis.scaled(Vector3.ONE * bone_distance)
			
			#bone_transform.basis = Basis.looking_at(bone_direction).scaled(Vector3.ONE * bone_distance)
			#bone_transform.basis = Basis(bone_transform.basis.x, -bone_transform.basis.z, bone_transform.basis.y)
			
			bones_needed.append(bone_transform)
			
			var colour = Color.RED if current_rotated == i else Color.YELLOW
			colours.append(colour)
	
	for i in range(0, bones_needed.size()):
		bones_display.multimesh.set_instance_transform(i, bones_needed[i])
		bones_display.multimesh.set_instance_color(i, colours[i])

func _toggle_rename() -> void:
	
	# find bones to rename for the arms
	var left_done = false
	var right_done = false
	
	var not_renamed = []
	
	for i in range(0, skeleton.get_bone_count()):
		var bone_name = get_bone_name_formated(skeleton, i)
		
		
		if bone_name.contains("finger") or not bone_has_array_term(bone_name, arm_bones) or bone_has_array_term(bone_name, banned_terms):
			continue
		
		# check what side the bone is
		var side = get_bone_side(bone_name)
		
		#print(bone_name, side)
		
		if side == 0:
			continue
		
		if side == 1 and right_done:
			continue
		
		if side == -1 and left_done:
			continue
		
		var highest_index = i
		var lowest_index = i
		
		# loop through every parent until we find the highest one
		var parent = skeleton.get_bone_parent(i)
		
		while parent != -1 and bone_has_array_term(get_bone_name_formated(skeleton, parent), arm_bones) and get_bone_side(get_bone_name_formated(skeleton, parent)) == side  and not get_bone_name_formated(skeleton, parent).contains("finger"):
			highest_index = parent
			parent = skeleton.get_bone_parent(parent)
		
		# now loop through the children
		var children_should_loop = true
		while children_should_loop:
			
			children_should_loop = false
			
			for j in skeleton.get_bone_children(lowest_index):
				if bone_has_array_term(get_bone_name_formated(skeleton, j), arm_bones) and not bone_has_array_term(get_bone_name_formated(skeleton, j), banned_terms) and not get_bone_name_formated(skeleton, j).contains("finger"):
					children_should_loop = true
					lowest_index = j
					break
		
		
		# now time to count the amount of bones
		var bone_length = 1
		var current_bone = lowest_index
		
		while current_bone != highest_index:
			bone_length += 1
			current_bone = skeleton.get_bone_parent(current_bone)
		
		var bone_renaming_pattern = []
		
		if bone_length == 3:
			bone_renaming_pattern = [
				"ValveBiped.Bip01_X_Hand",
				"ValveBiped.Bip01_X_Forearm",
				"ValveBiped.Bip01_X_UpperArm"
			]
		elif bone_length == 4:
			bone_renaming_pattern = [
				"ValveBiped.Bip01_X_Hand",
				"ValveBiped.Bip01_X_Forearm",
				"ValveBiped.Bip01_X_UpperArm",
				"ValveBiped.Bip01_X_Clavicle"
			]
		else:
			var warning = "Arm bones (" + ("Right" if side == 1 else "Left") + ")"
			warning += ", too many or few bones compared to the list, rename some bones if there's too many"
			not_renamed.append(warning)
		
		print(bone_length)
		
		if side == 1:
			right_done = true
		else:
			left_done = true
		
		if bone_renaming_pattern == []:
			continue
		
		
		
		var current_index = lowest_index
		
		for j in range(0, bone_length):
			
			var renaming = bone_renaming_pattern[j]
			renaming = renaming.replacen("_X_", "_R_" if side == 1 else "_L_")
			
			
			skeleton.set_bone_name(current_index, renaming)
			current_index = skeleton.get_bone_parent(current_index)
	
	# time for the legs
	left_done = false
	right_done = false
	
	for i in range(0, skeleton.get_bone_count()):
		var bone_name = get_bone_name_formated(skeleton, i)
		
		
		if not bone_has_array_term(bone_name, leg_bones) or bone_has_array_term(bone_name, banned_terms):
			continue
		
		# check what side the bone is
		var side = get_bone_side(bone_name)
		
		if side == 0:
			continue
		
		if side == 1 and right_done:
			continue
		
		if side == -1 and left_done:
			continue
		
		var highest_index = i
		var lowest_index = i
		
		# loop through every parent until we find the highest one
		var parent = skeleton.get_bone_parent(i)
		
		while parent != -1 and bone_has_array_term(get_bone_name_formated(skeleton, parent), leg_bones) and get_bone_side(get_bone_name_formated(skeleton, parent)):
			highest_index = parent
			parent = skeleton.get_bone_parent(parent)
		
		# now loop through the children
		var children_should_loop = true
		while children_should_loop:
			
			children_should_loop = false
			
			for j in skeleton.get_bone_children(lowest_index):
				if bone_has_array_term(get_bone_name_formated(skeleton, j), leg_bones) and not bone_has_array_term(get_bone_name_formated(skeleton, j), banned_terms):
					children_should_loop = true
					lowest_index = j
					break
		
		
		# now time to count the amount of bones
		var bone_length = 1
		var current_bone = lowest_index
		
		while current_bone != highest_index:
			bone_length += 1
			current_bone = skeleton.get_bone_parent(current_bone)
		
		var bone_renaming_pattern = []
		
		if bone_length == 3:
			bone_renaming_pattern = [
				"ValveBiped.Bip01_X_Foot",
				"ValveBiped.Bip01_X_Calf",
				"ValveBiped.Bip01_X_Thigh",
			]
		else:
			var warning = "Leg bones (" + ("Right" if side == 1 else "Left") + ")"
			warning += ", too many or few bones compared to the list, rename some bones if there's too many"
			not_renamed.append(warning)
		
		if side == 1:
			right_done = true
		else:
			left_done = true
		
		if bone_renaming_pattern == []:
			continue
		
		var current_index = lowest_index
		
		for j in range(0, bone_length):
			
			var renaming = bone_renaming_pattern[j]
			renaming = renaming.replacen("_X_", "_R_" if side == 1 else "_L_")
			
			
			skeleton.set_bone_name(current_index, renaming)
			current_index = skeleton.get_bone_parent(current_index)
		
		# check for a toe bone
		for j in skeleton.get_bone_children(lowest_index):
			var child_name = get_bone_name_formated(skeleton, j)
			
			if child_name.contains("toe") and not bone_has_array_term(child_name, banned_terms):
				
				var renaming = "ValveBiped.Bip01_X_Toe0"
				renaming = renaming.replacen("_X_", "_R_" if side == 1 else "_L_")
				
				skeleton.set_bone_name(j,renaming)
				break
	
	# fingers are renamed a bit differently, and they have an option which impacts them
	rename_finger_bones()
	# time for the spine, but this is done differently unlike most other stuff
	rename_spine_bones(not_renamed)
	
	if not_renamed != []:
		var message = "The following bones were not named: \n"
		
		for i in not_renamed:
			message += "\n\n" + i
		
		ModelEditor.show_warning(message)
	
	update_tree()
	bone_renamed.emit()

func rename_finger_bones():
	for side in range(0, 2):
		var hand = "ValveBiped.Bip01_R_Hand" if side == 0 else "ValveBiped.Bip01_L_Hand"
		var hand_index = skeleton.find_bone(hand)
		
		if hand_index == -1:
			return
		
		# check for the fingers, and sort them later
		var start_fingers = []
		
		for j in skeleton.get_bone_children(hand_index):
			var finger_name = skeleton.get_bone_name(j)
			
			if bone_has_array_term(finger_name, banned_terms):
				continue
			
			start_fingers.append(j)
		
		start_fingers.sort_custom(sort_finger_bones)
		
		var first_renaming = []
		var finger_count = start_fingers.size()
		
		if PropertySetting.settings["HasThumbs"]:
			first_renaming.append("ValveBiped.Bip01_X_Finger0")
			finger_count -= 1
		
		if finger_count == 1:
			first_renaming.append_array([
				"ValveBiped.Bip01_X_Finger2"
			])
		elif finger_count == 2:
			first_renaming.append_array([
				"ValveBiped.Bip01_X_Finger1",
				"ValveBiped.Bip01_X_Finger3"
			])
		elif finger_count == 3:
			first_renaming.append_array([
				"ValveBiped.Bip01_X_Finger1",
				"ValveBiped.Bip01_X_Finger2",
				"ValveBiped.Bip01_X_Finger3"
			])
		elif finger_count == 4:
			first_renaming.append_array([
				"ValveBiped.Bip01_X_Finger1",
				"ValveBiped.Bip01_X_Finger2",
				"ValveBiped.Bip01_X_Finger3",
				"ValveBiped.Bip01_X_Finger4"
			])
		
		if first_renaming == []:
			return
		
		# now we count the amount of bones
		
		for j in start_fingers:
			var bones_found = [j]
			
			for k in bones_found:
				for l in skeleton.get_bone_children(k):
					if bone_has_array_term(skeleton.get_bone_name(l), banned_terms):
						continue
					
					bones_found.append(l)
					continue
			
			var additional_numbers = [""]
			
			if bones_found.size() == 2:
				additional_numbers.append("2")
			elif bones_found.size() == 3:
				additional_numbers.append("1")
				additional_numbers.append("2")
			
			# time to rename
			
			for k in bones_found:
				var bone_rename = first_renaming[start_fingers.find(j)] + additional_numbers[bones_found.find(k)]
				bone_rename = bone_rename.replace("_X_", "_R_" if side == 0 else "_L_")
				skeleton.set_bone_name(k, bone_rename)

func rename_spine_bones(not_renamed: Array = []):
	var spine_indices = []
	
	for i in range(0, skeleton.get_bone_count()):
		var bone_name = get_bone_name_formated(skeleton, i)
		
		if bone_has_array_term(bone_name, spine_bones) and get_bone_side(bone_name) == 0 and not bone_has_array_term(bone_name, banned_terms):
			spine_indices.insert(0, i)
		
	var bone_renaming_pattern = []
	
	# sort the spines by height
	spine_indices.sort_custom(sort_spine_bones)
	
	if spine_indices.size() == 2:
		bone_renaming_pattern = [
			"ValveBiped.Bip01_Pelvis",
			"ValveBiped.Bip01_Head1"
		]
	elif spine_indices.size() == 3:
		bone_renaming_pattern = [
			"ValveBiped.Bip01_Pelvis",
			"ValveBiped.Bip01_Spine2",
			"ValveBiped.Bip01_Head1"
		]
	elif spine_indices.size() == 4:
		bone_renaming_pattern = [
			"ValveBiped.Bip01_Pelvis",
			"ValveBiped.Bip01_Spine2",
			"ValveBiped.Bip01_Neck1",
			"ValveBiped.Bip01_Head1"
		]
	elif spine_indices.size() == 5:
		bone_renaming_pattern = [
			"ValveBiped.Bip01_Pelvis",
			"ValveBiped.Bip01_Spine",
			"ValveBiped.Bip01_Spine2",
			"ValveBiped.Bip01_Neck1",
			"ValveBiped.Bip01_Head1"
		]
	elif spine_indices.size() == 6:
		bone_renaming_pattern = [
			"ValveBiped.Bip01_Pelvis",
			"ValveBiped.Bip01_Spine",
			"ValveBiped.Bip01_Spine1",
			"ValveBiped.Bip01_Spine2",
			"ValveBiped.Bip01_Neck1",
			"ValveBiped.Bip01_Head1",
		]
	elif spine_indices.size() == 7:
		bone_renaming_pattern = [
			"ValveBiped.Bip01_Pelvis",
			"ValveBiped.Bip01_Spine",
			"ValveBiped.Bip01_Spine1",
			"ValveBiped.Bip01_Spine2",
			"ValveBiped.Bip01_Spine4",
			"ValveBiped.Bip01_Neck1",
			"ValveBiped.Bip01_Head1",
		]
	else:
		var warning = "Spine bones"
		warning += ", too many or few bones compared to the list, rename some bones if there's too many"
		not_renamed.append(warning)
	
	if bone_renaming_pattern != []:
		
		for j in range(0, spine_indices.size()):
			skeleton.set_bone_name(spine_indices[j], bone_renaming_pattern[j])

func sort_finger_bones(a, b):
	var a_zed = (skeleton.global_transform * skeleton.get_bone_global_pose(a)).origin.z
	var b_zed = (skeleton.global_transform * skeleton.get_bone_global_pose(b)).origin.z
	
	return a_zed > b_zed

func sort_spine_bones(a, b):
	var a_height = (skeleton.global_transform * skeleton.get_bone_global_pose(a)).origin.y
	var b_height = (skeleton.global_transform * skeleton.get_bone_global_pose(b)).origin.y
	
	var a_children = skeleton.get_bone_children(a)
	for i in a_children:
		a_height += skeleton.get_bone_global_pose(a).origin.y / (a_children.size() / 4.0)
	
	var b_children = skeleton.get_bone_children(b)
	for i in b_children:
		b_height += skeleton.get_bone_global_pose(b).origin.y / (b_children.size() / 4.0)
	
	return a_height < b_height

func get_bone_side(bone_name) -> int:
	if bone_name.contains("right") or bone_name.begins_with("r_") or bone_name.ends_with("_r"):
		return 1
	elif bone_name.contains("left") or bone_name.begins_with("l_") or bone_name.ends_with("_l"):
		return -1
	
	return 0

func get_bone_name_formated(skeleton: Skeleton3D, index):
	var bone_name = skeleton.get_bone_name(index)
	# converting to snake case since it's easier
	#bone_name = bone_name.to_pascal_case()
	bone_name = bone_name.remove_chars("0123456789_-., ")
	bone_name = bone_name.validate_filename()
	bone_name = bone_name.to_snake_case()
	print(bone_name)
	return bone_name

func bone_has_array_term(string: String, array: PackedStringArray) -> bool:
	for i in array:
		if string.contains(i):
			return true
	
	return false

func _toggle_repose() -> void:
	for i in range(0, skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(i)
		
		var bones_to_reset = [
			"Calf",
			"Thigh",
			"Foot",
			"Toe0",
			"UpperArm",
			"ForeArm",
			"Hand",
		]
		
		if !bones_to_reset.has(bone_name):
			continue
		
		var global_pose = skeleton.get_bone_pose(i)
		global_pose.basis = Basis.IDENTITY #ReferenceSkeleton.get_bone_pose(ref_index).basis
		
		skeleton.set_bone_pose(i, global_pose)
	
	# first we do the body
	var torsoIk = SkeletonIK3D.new()
	torsoIk.root_bone = "ValveBiped.Bip01_Pelvis"
	torsoIk.tip_bone = "ValveBiped.Bip01_Head1"
	torsoIk.override_tip_basis = false
	
	# check the pelvis area though
	var spines = [
		"ValveBiped.Bip01_Spine",
		"ValveBiped.Bip01_Spine1",
		"ValveBiped.Bip01_Spine2",
		"ValveBiped.Bip01_Spine4",
	]
	
	for i in spines:
		var index = skeleton.find_bone(i)
		if index == -1:
			continue
		
		if index < skeleton.find_bone(torsoIk.root_bone):
			torsoIk.root_bone = i
			break
	
	var torsoPos = Node3D.new()
	skeleton.add_child(torsoIk)
	scene.add_child(torsoPos)
	
	torsoIk.target_node = torsoPos.get_path()
	torsoPos.global_position = skeleton.get_bone_global_pose(skeleton.find_bone(torsoIk.root_bone)).origin + scene.basis.y * 10.0
	torsoIk.start(true)
	
	# apply bones
	for i in range(0, skeleton.get_bone_count()):
		var bone_pose = skeleton.get_bone_global_pose_override(i)
		
		if bone_pose == Transform3D.IDENTITY:
			continue
		
		skeleton.set_bone_global_pose(i, skeleton.get_bone_global_pose_override(i))
		skeleton.set_bone_rest(i, skeleton.get_bone_global_pose_override(i))
	
	# remove now
	torsoPos.queue_free()
	torsoIk.queue_free()
	
	setup_arm_ik(false)
	setup_arm_ik(true)
	
	setup_leg_ik(false)
	setup_leg_ik(true)
	
	#setup_foot_ik(skeleton, false)
	#setup_foot_ik(skeleton, true)

func setup_arm_ik(right: bool):
	var ArmIk = SkeletonIK3D.new()
	ArmIk.root_bone = "ValveBiped.Bip01_L_Clavicle"
	
	if skeleton.find_bone(ArmIk.root_bone) == -1:
		ArmIk.root_bone = "ValveBiped.Bip01_L_UpperArm"
	
	ArmIk.tip_bone = "ValveBiped.Bip01_L_Hand"
	ArmIk.override_tip_basis = false
	
	if right:
		ArmIk.root_bone = ArmIk.root_bone.replacen("_L_", "_R_")
		ArmIk.tip_bone = ArmIk.tip_bone.replacen("_L_", "_R_")
	
	var ArmPos = Node3D.new()
	skeleton.add_child(ArmIk)
	scene.add_child(ArmPos)
	
	ArmIk.target_node = ArmPos.get_path()
	ArmPos.global_position = skeleton.get_bone_global_pose(skeleton.find_bone(ArmIk.root_bone)).origin + scene.basis.x * (-10.0 if right else 10.0)
	
	ArmIk.start(true)
	
	# apply bones
	for i in range(0, skeleton.get_bone_count()):
		var bone_pose = skeleton.get_bone_global_pose_override(i)
		
		if bone_pose == Transform3D.IDENTITY:
			continue
		
		skeleton.set_bone_global_pose(i, skeleton.get_bone_global_pose_override(i))
		skeleton.set_bone_rest(i, skeleton.get_bone_global_pose_override(i))
	
	# fix the stuff
	var bottom_index = skeleton.find_bone(ArmIk.tip_bone)
	var bottom_trans = skeleton.get_bone_global_pose(bottom_index)
	bottom_trans.basis = skeleton.get_bone_global_pose(skeleton.get_bone_parent(bottom_index)).basis
	skeleton.set_bone_global_pose(bottom_index, bottom_trans)
	
	# remove now
	ArmPos.queue_free()
	ArmIk.queue_free()

func setup_leg_ik(right: bool):
	var legIk = SkeletonIK3D.new()
	legIk.root_bone = "ValveBiped.Bip01_L_Thigh"
	legIk.tip_bone = "ValveBiped.Bip01_L_Foot"
	legIk.override_tip_basis = false
	
	if right:
		legIk.root_bone = legIk.root_bone.replacen("_L_", "_R_")
		legIk.tip_bone = legIk.tip_bone.replacen("_L_", "_R_")
	
	var legPos = Node3D.new()
	skeleton.add_child(legIk)
	scene.add_child(legPos)
	
	legIk.target_node = legPos.get_path()
	legPos.global_position = skeleton.get_bone_global_pose(skeleton.find_bone(legIk.root_bone)).origin + scene.basis.y * -10.0
	legPos.rotation_degrees = Vector3(-90.0, -90.0, 0.0)
	
	legIk.start(true)
	
	# apply bones
	for i in range(0, skeleton.get_bone_count()):
		var bone_pose = skeleton.get_bone_global_pose_override(i)
		
		if bone_pose == Transform3D.IDENTITY:
			continue
		
		skeleton.set_bone_global_pose(i, skeleton.get_bone_global_pose_override(i))
		skeleton.set_bone_rest(i, skeleton.get_bone_global_pose_override(i))
	
	# fix the stuff
	var bottom_index = skeleton.find_bone(legIk.tip_bone)
	var bottom_trans = skeleton.get_bone_global_pose(bottom_index)
	bottom_trans.basis = skeleton.get_bone_global_pose(skeleton.get_bone_parent(bottom_index)).basis
	bottom_trans.basis = bottom_trans.basis.rotated(Vector3.RIGHT, PI / -2.0)
	skeleton.set_bone_global_pose(bottom_index, bottom_trans)
	
	# remove now
	legPos.queue_free()
	legIk.queue_free()



# just some ui stuff
var target_transform: Transform3D = Transform3D.IDENTITY
var mirror_target_transform: Transform3D = Transform3D.IDENTITY
var euler_rotation: Vector3 = Vector3.ZERO

func _on_tree_item_edited() -> void:
	var item: TreeItem = $Bones/Tree.get_edited()
	
	var new_name = item.get_text(0)
	var increment = 0
	var bone_index = bone_mappings.find(item)
	
	
	while skeleton.find_bone(new_name) != -1:
		if skeleton.find_bone(new_name) == bone_index:
			break
		
		increment += 1
			
		if new_name.ends_with("." + str(increment - 1)):
			new_name = new_name.trim_suffix("." + str(increment - 1))
			
		new_name += "." + str(increment)
	
	
	var old_name = skeleton.get_bone_name(bone_index)
	#skeleton.set_bone_name(bone_mappings.find(item), new_name)
	#item.set_text(0, new_name)
	ModelEditor.undo_manager.create_action("Rename bone")
	
	ModelEditor.undo_manager.add_do_method(skeleton.set_bone_name.bind(bone_index, new_name))
	ModelEditor.undo_manager.add_do_method(item.set_text.bind(0, new_name))
	ModelEditor.undo_manager.add_do_method(bone_renamed.emit)
	
	ModelEditor.undo_manager.add_undo_method(skeleton.set_bone_name.bind(bone_index, old_name))
	ModelEditor.undo_manager.add_undo_method(item.set_text.bind(0, old_name))
	ModelEditor.undo_manager.add_undo_method(bone_renamed.emit)
	
	ModelEditor.undo_manager.commit_action()
	
	bone_renamed.emit()

func _on_tree_item_selected() -> void:
	var item: TreeItem = $Bones/Tree.get_selected()
	
	var bone_data = skeleton.get_bone_pose(bone_mappings.find(item))
	
	$Gizmo3D.visible = true
	#$Gizmo3D.select(skeleton)
	$Gizmo3D.snapping = true
	$Gizmo3D.rotate_snap = float(PropertySetting.settings["RotationSnap"])
	
	target_transform = bone_data
	current_rotated = bone_mappings.find(item)
	
	var mirror_index = get_mirrored_index(current_rotated)
	if mirror_index != -1:
		mirror_target_transform = skeleton.get_bone_pose(mirror_index)
	
	adjust_gizmo_transform()

func _on_gizmo_3d_transform_begin(mode: Gizmo3D.TransformMode) -> void:
	#var relative = PropertySetting.settings["RelativeRotationEditing"]
	
	#var bone_data = skeleton.get_bone_pose(current_rotated)
	#if not relative:
	var bone_data = skeleton.get_bone_global_pose(current_rotated)
	
	target_transform = bone_data
	
	var mirror_index = get_mirrored_index(current_rotated)
	if mirror_index != -1:
		#mirror_target_transform = skeleton.get_bone_pose(mirror_index)
		#if not relative:
		mirror_target_transform = skeleton.get_bone_global_pose(mirror_index)

func _on_gizmo_3d_transform_changed(mode: Gizmo3D.TransformMode, value: Vector3) -> void:
	if current_rotated == -1:
		return
	
	skeleton.transform = Transform3D.IDENTITY
	skeleton.position.y = PropertySetting.settings["YOffset"]
	euler_rotation = value
	
	#var bone_data = skeleton.get_bone_global_pose(current_rotated)
	
	set_bone_rotation(current_rotated, target_transform, mirror_target_transform, euler_rotation, PropertySetting.settings["RelativeRotationEditing"], PropertySetting.settings["MirrorBone"])
	
	#if PropertySetting.settings["RelativeRotationEditing"]:
	#	bone_data.basis = ($Gizmo3D.basis * Basis.from_euler(value)).scaled(bone_data.basis.get_scale())
	#else:
	#	bone_data.basis = Basis.from_euler(value) * previous_transform.basis
	
	#set_bone_rotation(current_rotated, bone_data, PropertySetting.settings["MirrorBone"])

func _on_gizmo_3d_transform_end(mode: Gizmo3D.TransformMode) -> void:
	var relative = PropertySetting.settings["RelativeRotationEditing"]
	
	#var new_transform = skeleton.get_bone_pose(current_rotated)
	#if not relative:
	var new_transform = skeleton.get_bone_global_pose(current_rotated)
	
	var new_mirror_transform = new_transform
	var mirror_index = get_mirrored_index(current_rotated)
	#if mirror_index != -1:
	#	new_mirror_transform = skeleton.get_bone_pose(mirror_index)
	#	if not relative:
	new_mirror_transform = skeleton.get_bone_global_pose(mirror_index)
	
	ModelEditor.undo_manager.create_action("Rotate bone")
	ModelEditor.undo_manager.add_do_method(set_bone_rotation.bind(current_rotated, target_transform, mirror_target_transform, euler_rotation, PropertySetting.settings["RelativeRotationEditing"], PropertySetting.settings["MirrorBone"]))
	ModelEditor.undo_manager.add_undo_method(set_bone_rotation.bind(current_rotated, new_transform, new_mirror_transform, -euler_rotation, PropertySetting.settings["RelativeRotationEditing"], PropertySetting.settings["MirrorBone"]))
	ModelEditor.undo_manager.add_undo_method(adjust_gizmo_transform)
	ModelEditor.undo_manager.commit_action()
	
	adjust_gizmo_transform()

func adjust_gizmo_transform():
	var bone_transform = skeleton.get_bone_global_pose(current_rotated)
	
	$Gizmo3D.position = skeleton.global_transform * bone_transform.origin
	
	if PropertySetting.settings["RelativeRotationEditing"]:
		$Gizmo3D.basis = bone_transform.basis.scaled(Vector3.ONE / bone_transform.basis.get_scale())
	else:
		$Gizmo3D.basis = Basis.IDENTITY

func get_mirrored_index(index):
	var bone_name = skeleton.get_bone_name(index)
	var mirrored_bone = ""
	
	if bone_name.contains("_R_"):
		mirrored_bone = bone_name.replace("_R_", "_L_")
	elif bone_name.contains("_L_"):
		mirrored_bone = bone_name.replace("_L_", "_R_")
	else:
		return -1
	
	return skeleton.find_bone(mirrored_bone)


func set_bone_rotation(index, from_transform: Transform3D, from_mirror_transform: Transform3D, angle: Vector3, relative, mirrored):
	if relative:
		from_transform.basis = from_transform.basis * Basis.from_euler(angle)
		skeleton.set_bone_global_pose(index, from_transform)
	else:
		from_transform.basis = Basis.from_euler(angle) * from_transform.basis
		skeleton.set_bone_global_pose(index, from_transform)
	
	# mirroring time
	if not mirrored:
		return
	
	var mirror_index = get_mirrored_index(index)
	if mirror_index == -1:
		return
	
	if relative:
		from_mirror_transform.basis = from_mirror_transform.basis * Basis.from_euler(angle * Vector3(1.0, -1.0, -1.0))
		skeleton.set_bone_global_pose(mirror_index, from_mirror_transform)
		#var mirror_euler = angle * -1.0
		#var new_mirror_trans = from_mirror_transform
		#new_mirror_trans.basis = new_mirror_trans.basis * Basis.from_euler(mirror_euler)
		#
		#skeleton.set_bone_pose(mirror_index, new_mirror_trans)
		#
		#var bone_pointing_dir = skeleton.get_bone_pose(index).origin.normalized()
		#
		## we invert the rotation if it seems it doesn't rotate as intended
		#var mirror_origin_comp = skeleton.get_bone_global_pose(index).origin + (skeleton.get_bone_global_pose(index).basis * bone_pointing_dir)
		#mirror_origin_comp.x *= -1.0
		#
		#var bone_pointing_dir2 = skeleton.get_bone_pose(mirror_index).origin.normalized()
		#
		#var current_mirror_orig = skeleton.get_bone_global_pose(mirror_index).origin + (skeleton.get_bone_global_pose(mirror_index).basis * bone_pointing_dir2)
		#
		#if (current_mirror_orig - mirror_origin_comp).length() > 0.2:
			#mirror_euler *= -1.0
			#new_mirror_trans = from_mirror_transform
			#new_mirror_trans.basis = new_mirror_trans.basis * Basis.from_euler(mirror_euler)
			#skeleton.set_bone_pose(mirror_index, new_mirror_trans)
	else:
		from_mirror_transform.basis = Basis.from_euler(angle * Vector3(1.0, -1.0, -1.0)) * from_mirror_transform.basis
		skeleton.set_bone_global_pose(mirror_index, from_mirror_transform)
