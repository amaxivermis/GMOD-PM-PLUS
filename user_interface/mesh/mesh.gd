extends VBoxContainer

var scene

func set_scene(imported_scene):
	visible = true
	scene = imported_scene
	$Bodygroups.setup_group_tree(scene)
	$Jigglebones.reset()
	$Jigglebones.current_skeleton = PMPlusUtils.get_skeleton(scene)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false

func _on_scale(value: float) -> void:
	if value < 0.0002:
		return
	
	scene.scale = Vector3(value, value, value)

func _on_offset(value: float) -> void:
	var skeleton = PMPlusUtils.get_skeleton(scene)
	skeleton.position.y = value
