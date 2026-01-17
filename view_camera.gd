class_name ViewCamera extends Camera3D

# this seems like the only way i can do viewports embed
static var singleton: ViewCamera

var can_move = false
var rotator: RotGizmo = null
var rotation_node: Node3D = null
var selected_vector: Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	singleton = self


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not can_move:
		
		if rotator != null:
			handle_rotation()
		
		return
	
	var direction = Input.get_vector("move_left", "move_right", "move_front", "move_back")
	position += basis * Vector3(direction.x, 0.0, direction.y) * delta * 5.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion && can_move:
		rotation_degrees -= Vector3(event.relative.y, event.relative.x, 0.0) * 0.1
		rotation_degrees.x = clampf(rotation_degrees.x, -90.0, 90.0)
	
	if event.is_action_pressed("toggle_move"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		can_move = true
	elif event.is_action_released("toggle_move"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		can_move = false
	
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			if not event.is_released():
				handle_raycast()
			else:
				rotator = null


func handle_raycast():
	var space_state = get_world_3d().direct_space_state
	var mousepos = get_viewport().get_mouse_position()

	var origin = project_ray_origin(mousepos)
	var end = origin + project_ray_normal(mousepos) * 100.0
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	
	var result: Dictionary = space_state.intersect_ray(query)
	
	if result == null:
		return
	
	if result.values().size() <= 0:
		return
	
	var collider = result["collider"]
	if collider is RotGizmo:
		rotator = collider
		rotation_node = collider.get_child(result["shape"] * 2)
		
		selected_vector = get_rotator_vector_from_ray()
	else:
		rotator = null

func handle_rotation():
	var pointing_dir = get_rotator_vector_from_ray()
	var up_dir = rotation_node.global_basis.y.normalized()
	
	rotator.rotate(up_dir, selected_vector.signed_angle_to(pointing_dir, up_dir))
	
	selected_vector = pointing_dir

func get_rotator_vector_from_ray():
	var mousepos = get_viewport().get_mouse_position()
	var ray = project_ray_normal(mousepos)
	
	var temp_basis: Transform3D = Transform3D()
	temp_basis.origin = project_ray_origin(mousepos)
	
	temp_basis.basis.z = ray
	temp_basis.basis.y = Vector3.RIGHT.cross(ray)
	temp_basis.basis.x = temp_basis.basis.y.cross(ray)
	
	var static_basis: Transform3D = rotation_node.global_transform
	
	# adjusting the x and z to be static, to get predictable results
	
	#static_basis.basis.z = Vector3.RIGHT.cross(static_basis.basis.y)
	#static_basis.basis.x = static_basis.basis.y.cross(static_basis.basis.z)
	
	var adjusted_ray = (static_basis * temp_basis).basis.z
	var start_ray = (static_basis * temp_basis).origin
	
	var collision_point = start_ray + (adjusted_ray * (start_ray.y / -adjusted_ray.y))
	rotation_node.to_global(collision_point)
	collision_point = collision_point.normalized()
	
	# the forward angle
	return collision_point
