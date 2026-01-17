class_name PMPlusUtils extends Node

static func get_single_mesh(node):
	return combine_mesh(get_meshes(node))

static func get_mesh_instances(node) -> Array[MeshInstance3D]:
	var children = [ node ]
	var nodes: Array[MeshInstance3D] = []
	
	for i in children:
		if i.name.contains("ValveBiped_Bip01"):
			continue
		
		children.append_array(i.get_children())
		
		if i is MeshInstance3D:
			nodes.append(i)
	
	return nodes

static func get_meshes(node):
	var children = [ node ]
	var meshes = []
	
	for i in children:
		if i.name.contains("ValveBiped_Bip01"):
			continue
		
		children.append_array(i.get_children())
		
		if i is MeshInstance3D:
			var bake_mesh: ArrayMesh = ArrayMesh.new()
			var parent = i.get_parent_node_3d()
			
			# this is because some meshes are attached to a bone
			if parent is BoneAttachment3D:
				bake_mesh = bake_mesh_from_attachment(i, parent)
				meshes.append([bake_mesh, bake_mesh])
			else:
				i.bake_mesh_from_current_skeleton_pose(bake_mesh)
				meshes.append([bake_mesh, i.mesh])
			
			
	
	return meshes

static func bake_mesh_from_attachment(mesh_instance: MeshInstance3D, attachment: BoneAttachment3D) -> ArrayMesh:
	
	var baked_mesh: ArrayMesh = ArrayMesh.new()
	
	for i in range(0, mesh_instance.mesh.get_surface_count()):
		
		var mesh_data = mesh_instance.mesh.surface_get_arrays(i)
		
		var single_mesh_array: Array = []
		single_mesh_array.resize(Mesh.ARRAY_MAX)
		
		var verts = PackedVector3Array()
		var normals = PackedVector3Array()
		var bone_indices = PackedInt32Array()
		var bone_weights = PackedFloat32Array()
		
		# easy one first
		single_mesh_array[Mesh.ARRAY_INDEX] = mesh_data[Mesh.ARRAY_INDEX]
		single_mesh_array[Mesh.ARRAY_TEX_UV] = mesh_data[Mesh.ARRAY_TEX_UV]
		
		# time to loop
		for j in range(0, mesh_data[Mesh.ARRAY_VERTEX].size()):
			verts.append(attachment.transform * mesh_instance.transform * mesh_data[Mesh.ARRAY_VERTEX][j])
			normals.append(attachment.basis * mesh_instance.basis * mesh_data[Mesh.ARRAY_NORMAL][j])
			
			# bones weights are a bit d i f f e r e n t
			bone_indices.append(attachment.bone_idx)
			bone_weights.append(1.0)
			
			for k in range(0, 3):
				bone_indices.append(0)
				bone_weights.append(0.0)
		
		single_mesh_array[Mesh.ARRAY_VERTEX] = verts
		single_mesh_array[Mesh.ARRAY_NORMAL] = normals
		single_mesh_array[Mesh.ARRAY_BONES] = bone_indices
		single_mesh_array[Mesh.ARRAY_WEIGHTS] = bone_weights
		
		baked_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, single_mesh_array)
		baked_mesh.surface_set_material(i, mesh_instance.get_active_material(i))
	
	return baked_mesh

static func combine_mesh(meshes) -> Array:
	var single_mesh_array: Array = []
	single_mesh_array.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	var indices = PackedInt32Array()
	var bone_indices = PackedInt32Array()
	var bone_weights = PackedFloat32Array()
	
	var vertex_offset = 0
	
	for i in meshes:
		var materials = i[1].get_surface_count()
		
		for j in range(0, materials):
			var mesh_data = i[0].surface_get_arrays(j)
			var mesh_data_original = i[1].surface_get_arrays(j)
			
			verts.append_array(mesh_data[Mesh.ARRAY_VERTEX])
			bone_indices.append_array(mesh_data_original[Mesh.ARRAY_BONES])
			bone_weights.append_array(mesh_data_original[Mesh.ARRAY_WEIGHTS])
			
			for k in mesh_data_original[Mesh.ARRAY_INDEX]:
				indices.append(vertex_offset + k)
			
			vertex_offset += mesh_data[Mesh.ARRAY_VERTEX].size()
	
	single_mesh_array[Mesh.ARRAY_VERTEX] = verts
	single_mesh_array[Mesh.ARRAY_INDEX] = indices
	single_mesh_array[Mesh.ARRAY_BONES] = bone_indices
	single_mesh_array[Mesh.ARRAY_WEIGHTS] = bone_weights
	
	return single_mesh_array

static func get_skeleton(node):
	
	var children = [ node ]
	
	for i in children:
		children.append_array(i.get_children())
		
		if i is Skeleton3D:
			return i
