class_name ModelEditor extends Node

class ExportProgress:
	var current_action: String
	var progress: float

static var undo_manager: UndoRedo
static var error_dialogue: AcceptDialog

func _init() -> void:
	# I searched this up and I had to add this line to get it to work
	RenderingServer.set_debug_generate_wireframes(true)

func _enter_tree() -> void:
	undo_manager = UndoRedo.new()
	error_dialogue = $ErrorDialog

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("redo"):
		undo_manager.redo()
	elif event.is_action_pressed("undo"):
		undo_manager.undo()

func _prompt_model() -> void:
	
	if get_node("/root/SkeletonManager").SkeletonInstance != null:
		$ImportOverride.popup_centered()
		await $ImportOverride.confirmed
		$ModelSearch.popup_centered()
	else:
		$ModelSearch.popup_centered()

func _show_settings() -> void:
	$Settings.popup_centered()

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
	
	var errors = ModelExporter.setup_prerequistes(get_node("/root/SkeletonManager").SkeletonInstance, $"reference_male2/reference_male/Skeleton3D", $Panels/Control/TabContainer/Mesh/Mesh/Bodygroups, material_manager.shader_material_groups, setup_path)
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
