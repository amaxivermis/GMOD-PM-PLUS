extends Node

signal bone_renamed

var skeleton: Skeleton3D
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("/root/SkeletonManager").SkeletonChanged.connect(set_skeleton)

func set_skeleton(imported_skeleton):
	skeleton = imported_skeleton

func _toggle_rename() -> void:
	
	# find bones to rename for the arms
	var left_done = false
	var right_done = false
	
	var not_renamed = []
	
	for i in range(0, skeleton.get_bone_count()):
		var bone_name = get_bone_name_formated(i)
		
		
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
		
		while parent != -1 and bone_has_array_term(get_bone_name_formated(parent), arm_bones) and get_bone_side(get_bone_name_formated(parent)) == side  and not get_bone_name_formated(parent).contains("finger"):
			highest_index = parent
			parent = skeleton.get_bone_parent(parent)
		
		# now loop through the children
		var children_should_loop = true
		while children_should_loop:
			
			children_should_loop = false
			
			for j in skeleton.get_bone_children(lowest_index):
				if bone_has_array_term(get_bone_name_formated(j), arm_bones) and not bone_has_array_term(get_bone_name_formated(j), banned_terms) and not get_bone_name_formated(j).contains("finger"):
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
		var bone_name = get_bone_name_formated(i)
		
		
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
		
		while parent != -1 and bone_has_array_term(get_bone_name_formated(parent), leg_bones) and get_bone_side(get_bone_name_formated(parent)):
			highest_index = parent
			parent = skeleton.get_bone_parent(parent)
		
		# now loop through the children
		var children_should_loop = true
		while children_should_loop:
			
			children_should_loop = false
			
			for j in skeleton.get_bone_children(lowest_index):
				if bone_has_array_term(get_bone_name_formated(j), leg_bones) and not bone_has_array_term(get_bone_name_formated(j), banned_terms):
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
			var child_name = get_bone_name_formated(j)
			
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
		var bone_name = get_bone_name_formated(i)
		
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

func get_bone_name_formated(index):
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
