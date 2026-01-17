extends Control
class_name ShaderSetting

var shader_parameter: String
var shader_material: ShaderMaterial

func configure(shader: ShaderMaterial, parameter: String, type: int, hint_string: String, current_value: Variant):
	$Property.text = parameter.capitalize()
	
	shader_parameter = parameter
	shader_material = shader
	
	$Bool.visible = (type == TYPE_BOOL)
	if $Bool.visible:
		$Bool.button_pressed = current_value as bool
		$Bool.toggled.connect(Callable(self, bool_toggle.get_method()))
	
	$Number.visible = (type == TYPE_FLOAT)
	if $Number.visible:
		$Number.value = current_value
		$Number.value_changed.connect(Callable(self, number_change.get_method()))
	else:
		# try again
		if type == TYPE_INT:
			$Number.visible = true
			$Number.step = 1.0
			$Number.value = current_value
			$Number.value_changed.connect(int_change)
	
	$Vector.visible = (type == TYPE_VECTOR3)
	if $Vector.visible:
		custom_minimum_size.y *= 2.0
		$Vector/X.value = current_value.x
		$Vector/Y.value = current_value.y
		$Vector/Z.value = current_value.z
		
		for i in $Vector.get_children():
			if i is SpinBox:
				i.value_changed.connect(vector_change)
	
	$Texture.visible = (hint_string == "Texture2D")
	if $Texture.visible:
		$Texture.pressed.connect(Callable(self, prompt_texture.get_method()))
		$Texture/TextureOpen.file_selected.connect(Callable(self, texture_change.get_method()))
		$Texture.icon = shader_material.get_shader_parameter(parameter)

func bool_toggle(toggled_on):
	shader_material.set_shader_parameter(shader_parameter, toggled_on)
	#updated.emit(shader_parameter, toggled_on)

func number_change(value: float):
	shader_material.set_shader_parameter(shader_parameter, value)

func int_change(value: int):
	shader_material.set_shader_parameter(shader_parameter, value)

# underscore, as this is just so we get no error
func vector_change(_new_value):
	var value = Vector3($Vector/X.value, $Vector/Y.value, $Vector/Z.value)
	shader_material.set_shader_parameter(shader_parameter, value)

func prompt_texture():
	$Texture/TextureOpen.popup_centered()

func texture_change(path: String):
	var image = Image.new().load_from_file(path)
	var texture = ImageTexture.new().create_from_image(image)
	texture.resource_name = make_path_acceptable(path).validate_filename()
	print(texture.resource_name)
	
	shader_material.set_shader_parameter(shader_parameter, texture)
	$Texture.icon = texture

# i need to make sure users don't get pissed off with me because their name got leaked
func make_path_acceptable(path: String):
	return path.substr(path.length() / 3, path.length()).replacen(" ", "").get_basename()
