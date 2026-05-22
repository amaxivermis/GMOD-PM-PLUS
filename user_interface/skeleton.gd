extends VBoxContainer

signal bone_renamed
@onready var undo_redo: UndoRedo = UndoRedo.new()
var skeleton: Skeleton3D
var bone_mappings = []
var current_rotated = -1

var bones_display: MultiMeshInstance3D

func _ready() -> void:
	visible = false
	get_node("/root/SkeletonManager").SkeletonChanged.connect(set_skeleton)

func set_skeleton(imported_skeleton):
	visible = true
	skeleton = imported_skeleton
	
	generate_bone_gizmos()
	update_tree()

func generate_bone_gizmos():
	
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
	add_child(torsoPos)
	
	torsoIk.target_node = torsoPos.get_path()
	torsoPos.global_position = skeleton.get_bone_global_pose(skeleton.find_bone(torsoIk.root_bone)).origin + skeleton.global_basis.y * 10.0
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
	var ArmIk = FABRIK3D.new()
	ArmIk.setting_count = 1
	ArmIk.set_root_bone_name(0, "ValveBiped.Bip01_L_Clavicle")
	
	if skeleton.find_bone(ArmIk.get_root_bone_name(0)) == -1:
		ArmIk.set_root_bone_name(0, "ValveBiped.Bip01_L_UpperArm")
	
	ArmIk.set_end_bone_name(0, "ValveBiped.Bip01_L_Hand")
	ArmIk.override_tip_basis = false
	
	if right:
		ArmIk.set_root_bone_name(0, ArmIk.get_root_bone_name(0).replacen("_L_", "_R_"))
		ArmIk.set_end_bone_name(0, ArmIk.get_end_bone_name(0).replacen("_L_", "_R_"))
	
	var ArmPos = Node3D.new()
	skeleton.add_child(ArmIk)
	add_child(ArmPos)
	
	ArmIk.set_target_node(0, ArmPos.get_path())
	ArmPos.global_position = skeleton.get_bone_global_pose(skeleton.find_bone(ArmIk.root_bone)).origin + skeleton.global_basis.x * (-10.0 if right else 10.0)
	
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
	var legIk = FABRIK3D.new()
	legIk.setting_count = 1
	legIk.set_root_bone_name(0, "ValveBiped.Bip01_L_Thigh")
	legIk.set_end_bone_name(0, "ValveBiped.Bip01_L_Foot")
	
	if right:
		legIk.set_root_bone_name(0, legIk.get_root_bone_name(0).replacen("_L_", "_R_"))
		legIk.set_end_bone_name(0, legIk.get_end_bone_name(0).replacen("_L_", "_R_"))
	
	var legPos = Node3D.new()
	skeleton.add_child(legIk)
	add_child(legPos)
	
	legIk.set_target_node(0, legPos.get_path())
	legPos.global_position = skeleton.get_bone_global_pose(skeleton.find_bone(legIk.root_bone)).origin + skeleton.global_basis.y * -10.0
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

func _process(_delta: float) -> void:
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
