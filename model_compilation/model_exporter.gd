class_name ModelExporter extends Node

static func setup_prerequistes(scene, reference_skeleton: Skeleton3D, bodygroups_manager: BodygroupManager, texture_groups: Array[MaterialManager.TextureGroup], file_path) -> String:
	# starting off
	
	if scene == null:
		return "You can't compile a blank model."
	
	var skeleton: Skeleton3D = PMPlusUtils.get_skeleton(scene)
	
	if skeleton == null:
		return "The model imported is not an armature"
	if skeleton.get_bone_count() == 0:
		return "The skeleton doesn't have any bones"
	
	var proportion_bones = SMDExporter.gather_skeleton_nodes_with_proportion(skeleton, reference_skeleton)
	if proportion_bones == null:
		return "None of the character bones have been renamed at all"
	
	var mesh_skeleton_node_data = SMDExporter.generate_skeleton_nodes(proportion_bones)
	var mesh_skeleton_trans_data = SMDExporter.generate_skeleton_transforms(skeleton, proportion_bones)
	
	# write the directory first
	var error = DirAccess.make_dir_recursive_absolute(file_path)
	if error != OK:
		return "Failed to create " + file_path + ": " + error_string(error)
	
	# time to write the bodygroups
	
	var bodygroup_qc_data = ""
	
	for i in range(0, bodygroups_manager.list.item_count):
		
		bodygroup_qc_data += "$bodygroup \"" + bodygroups_manager.list.get_item_text(i) + "\"\n{\n"
		
		# get the mesh count
		var mesh_count = bodygroups_manager.tree_groups_mesh_count[i]
		
		for j in range(0, mesh_count):
			# look for meshes, otherwise we just write blank
			var meshes: Array[BodygroupManager.BodygroupInfo] = []
			
			for k: BodygroupManager.BodygroupInfo in bodygroups_manager.tree_groups.values():
				if k.bodygroup_index != i:
					continue
				
				if k.mesh_index != j + 1:
					continue
				
				meshes.append(k)
			
			print(meshes.size())
			
			if meshes.size() == 0:
				bodygroup_qc_data += "	blank\n"
			else:
				var smd_name = "bodygroup_" + str(i) + "_mesh_" + str(j)
				bodygroup_qc_data += "	studio \"" + smd_name + ".smd\"\n"
				create_smd_file(file_path, smd_name, scene, mesh_skeleton_node_data, mesh_skeleton_trans_data, meshes, proportion_bones)
		
		# end it now
		bodygroup_qc_data += "}\n"
		
		#var data = "version 1\nnodes\n"
		#data += mesh_skeleton_node_data
		## ending the bones list
		#data += "end\n"
		#
		## now time for skeleton data
		#data += "skeleton\ntime 0\n"
		#data += mesh_skeleton_trans_data
		## ending the skeleton data
		#data += "end\ntriangles\n"
		#
		# now time for the vertex data
		#var meshes_found = PMPlusUtils.get_meshes(scene)
		
		#for i in meshes_found:
			#var materials = i[1].get_surface_count()
			#
			#for j in range(0, materials):
				#var mesh_data = i[0].surface_get_arrays(j)
				#var mesh_data_original = i[1].surface_get_arrays(j)
				#var mat_name = i[1].surface_get_material(j).resource_name
				#
				#var model_string_data: PackedStringArray
				#var array_size = mesh_data[Mesh.ARRAY_INDEX].size()
				#array_size += array_size / 3
				#
				#model_string_data.resize(array_size)
				#
				#var thread = Thread.new()
				#thread.start(SMDExporter.compile_mesh_data_to_smd.bind(model_string_data, SMDExporter.generate_bone_remap(proportion_bones, skeleton), skeleton, mesh_data, mesh_data_original, mat_name))
				#thread.wait_to_finish()
				#
				#data += "\n".join(model_string_data) + "\n"
		
		#data += "end\n"
		#
		#var file = FileAccess.open(file_path + "/temp.smd", FileAccess.WRITE)
		#file.store_string(data)
		#file.close()
	
	# setting up some stuff
	error = DirAccess.make_dir_recursive_absolute(file_path + "/anims")
	if error != OK:
		return "Failed to create " + file_path + "/anims: " + error_string(error)
	
	error = DirAccess.make_dir_recursive_absolute(file_path + "/arms_compile")
	if error != OK:
		return "Failed to create " + file_path + "/arms_compile:" + error_string(error)
	
	# setting up the anims
	var male_ref = FileAccess.open(file_path + "/anims/reference_male.smd", FileAccess.WRITE)
	male_ref.store_string(ReferenceSMDCode.reference_male)
	male_ref.close()
	
	var female_ref = FileAccess.open(file_path + "/anims/reference_female.smd", FileAccess.WRITE)
	female_ref.store_string(ReferenceSMDCode.reference_female)
	female_ref.close()
	
	# generating the portions
	var proportions_file = FileAccess.open(file_path + "/anims/proportions.smd", FileAccess.WRITE)
	
	var proportions_data = "version 1\nnodes\n"
	proportions_data += mesh_skeleton_node_data + "end\nskeleton\n"
	proportions_data += "time 0\n" + mesh_skeleton_trans_data + "time 1\n" + mesh_skeleton_trans_data + "end"
	
	proportions_file.store_string(proportions_data)
	proportions_file.close()
	
	# generating the arms smd
	var arms_file = FileAccess.open(file_path + "/arms_compile/" + PropertySetting.settings["ModelName"].to_snake_case() + "_arms.smd", FileAccess.WRITE)
	
	var arms_file_data = "version 1\nnodes\n"
	arms_file_data += mesh_skeleton_node_data + "end\nskeleton\n"
	arms_file_data += "time 0\n" + mesh_skeleton_trans_data + "end\n"
	
	var old_meshes: Array[Mesh] = []
	var new_meshes: Array[Mesh] = []
	
	for i in PMPlusUtils.get_meshes(scene):
		new_meshes.append(i[0])
		old_meshes.append(i[1])
	
	arms_file_data += "triangles\n" + SMDExporter.generate_arms_from_meshes(skeleton, old_meshes, new_meshes, proportion_bones, SMDExporter.generate_bone_remap(proportion_bones, skeleton)) + "end"
	
	arms_file.store_string(arms_file_data)
	arms_file.close()
	
	# ragdoll smd
	var collision_data = "version 1\nnodes\n"
	collision_data += mesh_skeleton_node_data + "end\nskeleton\n"
	collision_data += "time 0\n" + mesh_skeleton_trans_data + "end\n"
	collision_data += "triangles\n" + SMDExporter.generate_collisions_smd_data(skeleton, proportion_bones) + "end"
	
	var physics_file = FileAccess.open(file_path + "/pm_physics.smd", FileAccess.WRITE)
	physics_file.store_string(collision_data)
	physics_file.close()
	
	# making the .qc
	# first getting the definebones
	
	var compile_data = QCCompileTemplates.pm_compile
	
	var bone_physics_data = ""
	for i in ParameterList.list:
		
		if i == null:
			continue
		
		if not i.has_meta("jiggle_bone"):
			continue
		
		var start_bone = i.parameters["Start"]
		var end_bone = i.parameters["End"]
		
		var start_index = skeleton.find_bone(start_bone)
		var end_index = skeleton.find_bone(end_bone)
		
		# handling errors
		var errors = ""
		
		# the reason it's only used here is because the ordering can be weird
		if SMDExporter.get_bone_index(proportion_bones, start_bone) == -1:
			errors += "\n" + start_bone + " won't be included in the compiled skeleton"
		
		if SMDExporter.get_bone_index(proportion_bones, end_bone) == -1:
			errors += "\n" + end_bone + " won't be included in the compiled skeleton"
		
		if end_index < start_index:
			errors += "\nStart bone can't be higher in index than the end bone"
		
		if errors != "":
			return errors
		
		# plus one given how the loop works
		for j in range(start_index, end_index + 1):
			bone_physics_data += "$jigglebone \"" + skeleton.get_bone_name(j) + "\"\n{\n"
			bone_physics_data += "	is_flexible\n	{\n"
			
			# loop through every parameter, skipping the first two
			for k in range(2, i.parameters.size()):
				var key = i.parameters.keys()[k] as String
				var value = i.parameters[key]
				
				if key == "Length":
					continue
				
				bone_physics_data += "		" + key.to_snake_case() + " " + str(value) + "\n"
			
			# add in a lenght bone, calculated automatically for simplicity
			var length = 10.0
			
			if j + 1 <= end_index:
				length = (skeleton.get_bone_global_pose(j).origin - skeleton.get_bone_global_pose(j + 1).origin).length()
				# It's in inches, old-ass system ew, but we use metric here
				length *= 39.37008
				
			bone_physics_data += "		length " + str(length) + "\n"
			
			# close it in
			bone_physics_data += "	}\n}\n"
	
	compile_data = compile_data.replace("//replacewithbodygroupstuff//", bodygroup_qc_data)
	compile_data = compile_data.replace("//replacewithbonephsicsstuff//", bone_physics_data)
	
	if texture_groups.size() > 1:
		var texture_group_data = "$texturegroup skinfamilies\n {\n"
		
		for i in range(0, texture_groups.size()):
			texture_group_data += "\t{ "
			
			var suffix = ""
			if i != 0:
				suffix = "_" + str(i + 1)
			
			for j in range(0, texture_groups[i].shader_materials.size()):
				texture_group_data += " \"" + texture_groups[i].shader_materials[j].resource_name + suffix + "\""
			
			texture_group_data += " }\n"
		
		texture_group_data += "}\n"
		
		compile_data = compile_data.replace("[texture_group_plz]", texture_group_data)
	else:
		compile_data = compile_data.replace("[texture_group_plz]", "")
	
	compile_data = compile_data.replacen("[author_plz]", PropertySetting.settings["AuthorName"])
	compile_data = compile_data.replacen("[pm_2_plz]", PropertySetting.settings["ModelName"].to_snake_case())
	compile_data = compile_data.replace("[replace_gender]", PropertySetting.settings["AnimationGender"].to_lower())
	compile_data = compile_data.replace("[replace_material]",PropertySetting.settings["SurfaceMaterial"].to_lower())
	
	# physics stuff
	compile_data = compile_data.replace("[mass]", str(PropertySetting.settings["Mass"]))
	compile_data = compile_data.replace("[inertia]", str(PropertySetting.settings["Inertia"]))
	compile_data = compile_data.replace("[damping]", str(PropertySetting.settings["Damping"]))
	compile_data = compile_data.replace("[rotdamping]", str(PropertySetting.settings["RotationDamping"]))
	
	var qc_comp = FileAccess.open(file_path + "/compile.qc", FileAccess.WRITE)
	qc_comp.store_string(compile_data)
	qc_comp.close()
	
	# now time for the arms
	
	var arms_compile_data = QCCompileTemplates.arms_compile
	
	arms_compile_data = arms_compile_data.replacen("[author_plz]", PropertySetting.settings["AuthorName"])
	arms_compile_data = arms_compile_data.replacen("[pm_2_plz]", PropertySetting.settings["ModelName"].to_snake_case())
	arms_compile_data = arms_compile_data.replace("[replace_material]", PropertySetting.settings["SurfaceMaterial"].to_lower())
	
	var arms_qc_comp = FileAccess.open(file_path + "/arms_compile/arms_compile.qc", FileAccess.WRITE)
	arms_qc_comp.store_string(arms_compile_data)
	arms_qc_comp.close()
	
	return ""

static func create_smd_file(file_path, file_name, scene, skeleton_nodes, skeleton_transforms, meshes: Array[BodygroupManager.BodygroupInfo], proportion_bones):
	var skeleton = PMPlusUtils.get_skeleton(scene)
	var data = "version 1\nnodes\n"
	data += skeleton_nodes
	# ending the bones list
	data += "end\n"
	
	# now time for skeleton data
	data += "skeleton\ntime 0\n"
	data += skeleton_transforms
	# ending the skeleton data
	data += "end\ntriangles\n"
	# now time for the vertex data
	
	var meshes_found = []
	
	for i in meshes:
		meshes_found.append(PMPlusUtils.get_meshes(i.mesh_instance)[0])
	
	var model_string_data: PackedStringArray
	var triangle_offset = 0
	
	# resize the array real quick
	#var array_size = 0
	#for i in range(0, meshes.size()):
	#	var mat_index = meshes[i].surface_index
	#	var mesh_data = meshes_found[i][0].surface_get_arrays(mat_index)
	#	
	#	var cur_array_size = mesh_data[Mesh.ARRAY_INDEX].size()
	#	cur_array_size += cur_array_size / 3
	#	array_size += cur_array_size
	
	#model_string_data.resize(array_size)
	
	for i in range(0, meshes.size()):
		var mat_index = meshes[i].surface_index
		
		var mesh_data = meshes_found[i][0].surface_get_arrays(mat_index)
		var mesh_data_original = meshes_found[i][1].surface_get_arrays(mat_index)
		var mat_name = meshes_found[i][1].surface_get_material(mat_index).resource_name
		
		for j in range(0, mesh_data[Mesh.ARRAY_INDEX].size()):
			mesh_data[Mesh.ARRAY_INDEX][j] += triangle_offset
			mesh_data_original[Mesh.ARRAY_INDEX][j] += triangle_offset
		
		var array_size = mesh_data[Mesh.ARRAY_INDEX].size()
		array_size += array_size / 3
		
		var temp_model_data: PackedStringArray
		temp_model_data.resize(array_size)
			
		var thread = Thread.new()
		thread.start(SMDExporter.compile_mesh_data_to_smd.bind(temp_model_data, SMDExporter.generate_bone_remap(proportion_bones, skeleton), skeleton, mesh_data, mesh_data_original, mat_name))
		thread.wait_to_finish()
		
		model_string_data.append_array(temp_model_data)
	
	data += "\n".join(model_string_data) + "\n"
		
	data += "end\n"
		
	var file = FileAccess.open(file_path + "/" + file_name + ".smd", FileAccess.WRITE)
	file.store_string(data)
	file.close()



static func compile_model(qc_file) -> String:
	# compiling the definebones
	
	
	var output: Array[String] = []
	var path = ApplicationSetting.settings["StudioMDLPath"]
	
	var args: Array[String] = [
		'-game',
		ApplicationSetting.settings["GmodPath"] + "/garrysmod",
		"-definebones",
		"-nop4",
		"-parsecompletion",
		"-verbose", 
		qc_file
	]
	
	run_windows_program(path, args, output, true)
	var errors = get_errors(output[0])
	
	if errors != "":
		return errors
	
	var split_output = output[0].split("\n")
	# looping through the commands now
	var define_bones = ""
	
	for i in split_output:
		if not i.contains("$definebone"):
			continue
		
		define_bones += i
	
	# replacing the data now
	var qc_comp = FileAccess.open(qc_file, FileAccess.READ)
	var qc_data = qc_comp.get_as_text()
	qc_data = qc_data.replace("//replaceplz//", define_bones)
	qc_comp.close()
	
	qc_comp = FileAccess.open(qc_file, FileAccess.WRITE)
	qc_comp.store_string(qc_data)
	qc_comp.close()
	
	# as well as the arms
	var arms_qc_comp = FileAccess.open(qc_file.get_base_dir() + "/arms_compile/arms_compile.qc", FileAccess.READ)
	var arms_qc_data = arms_qc_comp.get_as_text()
	arms_qc_data = arms_qc_data.replace("//replaceplz//", define_bones)
	arms_qc_comp.close()
	
	arms_qc_comp = FileAccess.open(qc_file.get_base_dir() + "/arms_compile/arms_compile.qc", FileAccess.WRITE)
	arms_qc_comp.store_string(arms_qc_data)
	arms_qc_comp.close()
	
	# compile again
	args.erase("-definebones")
	var ouput2 = []
	run_windows_program(path, args, ouput2, true)
	
	errors = get_errors(ouput2[0])
	
	if errors != "":
		return errors
	
	args[args.find(qc_file)] = args[args.find(qc_file)].get_base_dir() + "/arms_compile/arms_compile.qc"
	run_windows_program(path, args, output, true)
	
	errors = get_errors(ouput2[0])
	
	return errors

static func setup_model_path(materials: Array[MaterialManager.TextureGroup], addon_path, compile_path):
	
	var error = Error.OK
	
	if DirAccess.dir_exists_absolute(addon_path):
		var dir = DirAccess.open(addon_path)
		
		for file in dir.get_files():
			dir.remove(file)
		
		error = DirAccess.remove_absolute(addon_path)
		
		if error != OK:
			return "Couldn't delete the directory " + addon_path + ": " + error_string(error)
	
	error = DirAccess.make_dir_recursive_absolute(addon_path)
	if error != OK:
		return "Couldn't create the directory " + addon_path + ": " + error_string(error)
	
	error = DirAccess.rename_absolute(compile_path, addon_path + "/models")
	if error != OK:
		return "Couldn't move " + compile_path + " to " + addon_path + "/models: " + error_string(error)
	
	# set up the auto run
	error = DirAccess.make_dir_recursive_absolute(addon_path + "/lua/autorun")
	if error != OK:
		return "Couldn't create the directory " + addon_path + "/lua/autorun: " + error_string(error)
	
	var lua_autorun = FileAccess.open(addon_path + "/lua/autorun/" + PropertySetting.settings["ModelName"].to_snake_case() + ".lua", FileAccess.WRITE)
	
	var autorun_data = '
player_manager.AddValidModel( "[pm_name_plz]", "models/[author_name_plz]/[pm2_name_plz]/[pm2_name_plz].mdl" )
list.Set( "PlayerOptionsModel", "[pm_name_plz]", "models/[author_name_plz]/[pm2_name_plz]/[pm2_name_plz].mdl" )
player_manager.AddValidHands( "[pm_name_plz]", "models/[author_name_plz]/[pm2_name_plz]/[pm2_name_plz]_arms.mdl", 0, "00000000" )
	'
	
	autorun_data = autorun_data.replacen("[pm_name_plz]", PropertySetting.settings["ModelName"])
	autorun_data = autorun_data.replacen("[pm2_name_plz]", PropertySetting.settings["ModelName"].to_snake_case())
	autorun_data = autorun_data.replacen("[author_name_plz]", PropertySetting.settings["AuthorName"])
	
	lua_autorun.store_string(autorun_data)
	lua_autorun.close()
	
	setup_materials(materials, addon_path)
	
	return ""

static func setup_materials(texture_groups: Array[MaterialManager.TextureGroup], addon_path):
	var material_path = addon_path + "/materials/models/" + PropertySetting.settings["AuthorName"] + "/" + PropertySetting.settings["ModelName"].to_snake_case()
	DirAccess.make_dir_recursive_absolute(material_path)
	
	for i in range(0, texture_groups.size()):
		for j: ShaderMaterial in texture_groups[i].shader_materials:
			
			var shader_type = ""
			
			if j.shader.resource_path == "res://shader_previews/lit_vertex.gdshader":
				shader_type = "VertexLitGeneric"
			else:
				shader_type = "UnlitGeneric"
			
			var file_suffix = ""
			if i != 0:
				file_suffix = "_" + str(i + 1)
			var vmt_code = shader_type + "\n{\n"
			
			for k in j.shader.get_shader_uniform_list():
				var param_name = k["name"]
				var value = j.get_shader_parameter(param_name)
				var hint_string = k["hint_string"]
				
				# default so we skip
				if value == null:
					# unless we have this, phong breaks if we have no normal map fsr
					if param_name == "BumpMap":
						value = load("res://model_compilation/flat_height.png") as Texture2D
						value.resource_name = "flat_height_912382513"
						hint_string = "Texture2D"
					else:
						continue
				
				# different process
				if hint_string == "Texture2D":
					var texture: Texture2D = value

					write_vtf_file(texture, material_path)

					vmt_code += "	$" + (param_name as String).to_lower() + " \"models/" + PropertySetting.settings["AuthorName"] + "/" + PropertySetting.settings["ModelName"].to_snake_case() + "/" + texture.resource_name + "\"\n"
					
					continue
				
				if k["type"] == TYPE_VECTOR3:
					vmt_code += "	$" + param_name.to_lower() + " \"[" + str(value.x) + " " + str(value.y) + " " + str(value.z) + "]\"\n"
					continue
				
				if k["type"] == TYPE_BOOL:
					value = int(value)
				
				vmt_code += "	$" + param_name.to_lower() + "  " + str(value) + "\n"
			
			vmt_code += "\n}"
			
			var vmt_file = FileAccess.open(material_path + "/" + j.resource_name + file_suffix + ".vmt", FileAccess.WRITE)
			vmt_file.store_string(vmt_code)
			vmt_file.close()

static func write_vtf_file(texture: Texture2D, material_directory):
	# just saving data for now
	var path = OS.get_temp_dir() + "/" + texture.resource_name + ".png"
	texture.get_image().save_png(path)
	
	var exe_path = ApplicationSetting.settings["VTFEditPath"]
	var args: Array[String] = [
		"-file",
		path,
		"-format",
		'"dxt5"'
	]
	
	
	run_windows_program(exe_path, args)
	
	DirAccess.rename_absolute(path.get_basename() + ".vtf", material_directory + "/" + texture.resource_name + ".vtf")

static func run_windows_program(path: String, args: Array[String], output: Array = [], read_stderr: bool = false) -> int:
	
	var current_args: Array[String] = args.duplicate()
	
	if OS.get_name() == "Linux":
		for i in range(0, current_args.size()):
			if current_args[i].is_absolute_path():
				var wins_path = []
				OS.execute("winepath", ["-w", current_args[i]], wins_path)
				
				current_args[i] = wins_path[0].replacen("\n", "")
		
		current_args.insert(0, path)
		path = "wine"
	
	return OS.execute(path, current_args, output, read_stderr)

static func get_errors(output: String):
	var errors = ""
	
	for i: String in output.split("\n"):
		var index = i.find("ERROR:")
		if index != -1:
			if i.find("Garry's Mod") < index:
				errors += i.substr(index)
	
	return errors
