class_name MaterialManager extends VBoxContainer

class TextureGroup:
	var shader_materials: Array[ShaderMaterial]

var shader_setting_scene = preload("res://user_interface/materials/shader_setting.tscn")
var shader_material_groups: Array[TextureGroup] = []
var current_texture_group: TextureGroup

var scene

var current_index = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false


func import_scene(import):
	visible = true
	scene = import
	
	$Settings/VBoxContainer/MaterialList.clear()
	shader_material_groups.clear()
	setup_materials(0)

func remove_group(index):
	shader_material_groups.remove_at(index)
	if index >= shader_material_groups.size():
		index -= 1
	
	switch_body_group(index)

func setup_materials(index):
	var children = [ scene ]
	var materials = []
	
	current_texture_group = TextureGroup.new()
	shader_material_groups.insert(index, current_texture_group)
	
	for i in children:
		
		if i.name.contains("ValveBiped_Bip01"):
			continue
		
		children.append_array(i.get_children())
		
		if i is MeshInstance3D:
			
			print(i.name)
			
			for j in range(0, i.get_surface_override_material_count()):
				var mesh_mat: Material = i.get_active_material(j)
				
				var skip = false
				for k in materials:
					if k.resource_name == mesh_mat.resource_name:
						i.set_surface_override_material(j, k)
						skip = true
						break
				
				if skip:
					continue
				
				var new_mat = ShaderMaterial.new()
				new_mat.resource_name = mesh_mat.resource_name
				new_mat.shader = load("res://shader_previews/lit_vertex.gdshader")
				
				if index == 0:
					$Settings/VBoxContainer/MaterialList.add_item(mesh_mat.resource_name)
				
				if mesh_mat is BaseMaterial3D:
					new_mat.set_shader_parameter("BaseTexture", mesh_mat.albedo_texture)
					new_mat.set_shader_parameter("BumpTexture", mesh_mat.normal_texture)
					
					if mesh_mat.albedo_texture == null:
						new_mat.shader = load("res://shader_previews/unlit_generic.gdshader")
						new_mat.set_shader_parameter("BaseTexture", mesh_mat.emission_texture)
				
				current_texture_group.shader_materials.append(new_mat)
				
				i.set_surface_override_material(j, new_mat)
				materials.append(new_mat)
	
	refresh_shader_settings()

func switch_body_group(index):
	var children = [ scene ]
	
	for i in children:
		children.append_array(i.get_children())
		
		if i is MeshInstance3D:
			#var bake_mesh: ArrayMesh = ArrayMesh.new()
			#i.bake_mesh_from_current_skeleton_pose(bake_mesh)
			
			for j in range(0, i.get_surface_override_material_count()):
				var mesh_mat: Material = i.get_active_material(j)
				
				for k in shader_material_groups[index].shader_materials:
					if k.resource_name == mesh_mat.resource_name:
						i.set_surface_override_material(j, k)
						break
	
	refresh_shader_settings()

func _on_material_list_item_selected(index: int) -> void:
	current_index = index
	refresh_shader_settings()


func _on_shader_mode_item_selected(index: int) -> void:
	var shader_to_load = load("res://shader_previews/lit_vertex.gdshader")
	
	match index:
		0:
			shader_to_load = load("res://shader_previews/lit_vertex.gdshader")
		1:
			shader_to_load = load("res://shader_previews/unlit_generic.gdshader")
	
	current_texture_group.shader_materials[current_index].shader = shader_to_load
	
	refresh_shader_settings()

func refresh_shader_settings():
	
	for i in $Settings/VBoxContainer/Settings.get_children():
		i.queue_free()
	
	var shader_index = 0
	
	match current_texture_group.shader_materials[current_index].shader.resource_path:
		"res://shader_previews/lit_vertex.gdshader":
			shader_index = 0
		"res://shader_previews/unlit_generic.gdshader":
			shader_index = 1
	
	$Settings/VBoxContainer/ShaderMode/OptionButton.selected = shader_index
	
	var current_group: VBoxContainer
	
	for i in current_texture_group.shader_materials[current_index].shader.get_shader_uniform_list(true):
		if i["type"] == 0:
			
			var category = FoldableContainer.new()
			category.folded = true
			$Settings/VBoxContainer/Settings.add_child(category)
			category.title = i["name"]
			
			current_group = VBoxContainer.new()
			category.add_child(current_group)
			
			continue
		
		# now it's normal
		var setting: ShaderSetting = shader_setting_scene.instantiate()
		var value = current_texture_group.shader_materials[current_index].get_shader_parameter(i["name"])
		
		if value == null:
			value = RenderingServer.shader_get_parameter_default(current_texture_group.shader_materials[current_index].shader.get_rid(), i["name"])
		
		setting.configure(current_texture_group.shader_materials[current_index], i["name"], i["type"], i["hint_string"], value)
		current_group.add_child(setting)
