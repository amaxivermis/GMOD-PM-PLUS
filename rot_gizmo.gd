class_name RotGizmo extends StaticBody3D

var index = 0
var raycast: RayCast3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_rot_data(col_index, raycaster):
	raycast = raycaster
	index = col_index
