extends VBoxContainer

var skeleton

func _ready():
	visible = false
	get_node("/root/SkeletonManager").SkeletonChanged.connect(set_skeleton)

func set_skeleton(imported_skeleton):
	visible = true
	skeleton = imported_skeleton
	$Bodygroups.setup_group_tree(skeleton)
	$Jigglebones.reset()
	$Jigglebones.current_skeleton = skeleton

func _on_scale(value: float) -> void:
	if value < 0.0002:
		return
	
	skeleton.scale = Vector3(value, value, value)

func _on_offset(value: float) -> void:
	skeleton.position.y = value
