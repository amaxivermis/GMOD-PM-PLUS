shader_type spatial;
render_mode unshaded;

group_uniforms Basics;
uniform sampler2D BaseTexture: filter_linear, source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = texture(BaseTexture, UV).rgb;
}