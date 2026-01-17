class_name ModelEditor extends Node

class ExportProgress:
	var current_action: String
	var progress: float

static var undo_manager: UndoRedo
static var error_dialogue: AcceptDialog

func _enter_tree() -> void:
	undo_manager = UndoRedo.new()
	error_dialogue = $ErrorDialog

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("redo"):
		undo_manager.redo()
	elif event.is_action_pressed("undo"):
		undo_manager.undo()

func _prompt_model() -> void:
	$ModelSearch.popup_centered()

func _show_settings() -> void:
	$Settings.popup_centered()

func _import_model(path: String) -> void:
	var model = get_node_or_null("GModPlayer")
	if model != null:
		model.queue_free()
	
	if path.get_extension().to_lower() == "glb":
		import_gltf(path)
	
	if model != null:
		await RenderingServer.frame_post_draw
		get_node_or_null("GModPlayer2").name = "GModPlayer"

func import_gltf(path: String):
	print("Importing GLTF: " + path)
	
	var gltf_document_load = GLTFDocument.new()
	var gltf_state_load = GLTFState.new()
	#gltf_state_load.import_as_skeleton_bones = true
	var error = gltf_document_load.append_from_file(path, gltf_state_load)
	if error == OK:
		var gltf_scene_root_node = gltf_document_load.generate_scene(gltf_state_load, 30.0)
		add_child(gltf_scene_root_node)
		
		if PMPlusUtils.get_skeleton(gltf_scene_root_node) == null:
			show_error("The imported file is not an armature")
			return
		
		update_scene(gltf_scene_root_node)
	else:
		show_error("Couldn't open glTF file (error code: %s)." % error_string(error))

func update_scene(scene):
	scene.name = "GModPlayer"
	$Panels/Control/TabContainer/Mesh/Mesh.set_scene(scene)
	$Panels/Control/TabContainer/Skeleton/Skeleton.set_scene(scene)
	$Panels/Control/TabContainer/Collisions/Collisions.set_scene(scene)
	$Panels/ModelData2/TabContainer/Materials/Materials.import_scene(scene)
	$Panels/Control/TabContainer/Skeleton/Skeleton.update_tree()

static func show_warning(text: String):
	error_dialogue.popup_centered()
	error_dialogue.title = "Warning"
	error_dialogue.dialog_text = text

static func show_error(text: String):
	error_dialogue.popup_centered()
	error_dialogue.title = "Error"
	error_dialogue.get_node("Label").text = text

func export_model():
	
	var pm_name = PropertySetting.settings["ModelName"]
	var setup_path = OS.get_temp_dir() + "/" + pm_name.to_snake_case()
	var material_manager = $Panels/ModelData2/TabContainer/Materials/Materials
	
	$ExportProgress.visible = true
	
	var errors = ModelExporter.setup_prerequistes(get_node_or_null("GModPlayer"), $"reference_male2/reference_male/Skeleton3D", $Panels/Control/TabContainer/Mesh/Mesh/Bodygroups, material_manager.shader_material_groups, setup_path)
	if errors != "":
		$ExportProgress.visible = false
		show_error(errors)
		return
	
	errors = ModelExporter.compile_model(setup_path + "/compile.qc")
	if errors != "":
		$ExportProgress.visible = false
		show_error(errors)
		return
	
	var addon_path = ApplicationSetting.settings["GmodPath"] + "/garrysmod/addons/" + pm_name
	# the reason for this is because rename_absolute is weird, it works on linux but not on Windows unless we make the directory different, but it copies the name
	var compile_path = ApplicationSetting.settings["GmodPath"] + "/garrysmod/models/models/"
	
	errors = ModelExporter.setup_model_path(material_manager.shader_material_groups, addon_path, compile_path)
	if errors != "":
		$ExportProgress.visible = false
		show_error(errors)
		return
	
	$ExportProgress.visible = false

func _on_settings_close_requested() -> void:
	$Settings.visible = false
