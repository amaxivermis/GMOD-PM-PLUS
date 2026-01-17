shader_type spatial;

group_uniforms Basics;
uniform sampler2D BaseTexture: filter_linear, source_color;
uniform sampler2D BumpMap: filter_linear, hint_normal;

group_uniforms PhongReflection;
uniform bool Phong;
uniform int PhongExponent;
uniform float PhongBoost;
uniform vec3 PhongFresnelRanges = vec3(0.0, 0.0, 0.0);

group_uniforms RimLighting;
uniform bool Rimlight;
uniform int RimlightExponent;
uniform float RimlightBoost;

group_uniforms AlphaAndTranscluency;
uniform bool Translucent;
uniform bool AlphaTesting;
uniform float AlphaTestReference;
uniform bool AllowAlphaToCoverage;

group_uniforms Lighting;
uniform bool HalfLambert;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 base_texture = texture(BaseTexture, UV);

	ALBEDO = base_texture.rgb;
	NORMAL_MAP = texture(BumpMap, UV).rgb;

	if (AlphaTesting)
	{
		ALPHA = base_texture.a;
		if (AllowAlphaToCoverage)
			ALPHA_SCISSOR_THRESHOLD = AlphaTestReference;
		else
			ALPHA_HASH_SCALE = AlphaTestReference;
	}
	else if (Translucent)
	{
		ALPHA = base_texture.a;
	}
}

float saturate(float value)
{
	return min(1.0f, max(0.0f, value));
}

//source engine fresnel Ranges
float Fresnel2( vec3 vNormal, vec3 vEyeDir )
{
	float fresnel = 1.0-saturate( dot( vNormal, vEyeDir ) );				// 1-(N.V) for Fresnel term
	return fresnel * fresnel;											// Square for a more subtle look
}

float Fresnel(vec3 vNormal, vec3 vEyeDir, vec3 vRanges)
{

	float result, f = Fresnel2( vNormal, vEyeDir );			// Traditional Fresnel

	if ( f > 0.5f )
		result = mix( vRanges.y, vRanges.z, (2.0*f)-1.0 );		// Blend between mid and high values
	else
        result = mix( vRanges.x, vRanges.y, 2.0*f );			// Blend between low and mid values

	return result;
}

void light()
{
	float dotN = dot(NORMAL, LIGHT);
	if (HalfLambert)
	{
		dotN = saturate(dotN * 0.5 + 0.5);
		dotN *= dotN;
	}
	else
		dotN = saturate(dotN);
		//dotN = pow(
		//	(dot(NORMAL, LIGHT) / 2.0) + 0.5
		//, 2.0f);

	DIFFUSE_LIGHT += ALBEDO * ATTENUATION * LIGHT_COLOR * dotN;

	// Specular and rim lighting
	if (Phong)
	{
		vec3 specular_lighting = vec3(0.0);
		vec3 rim = vec3(0.0);

		vec3 vReflect = 2.0 * NORMAL * dot( NORMAL , VIEW ) - VIEW; // Reflect view through normal
		float LdotR = saturate(dot( vReflect, LIGHT ));					// L.R	(use half-angle instead?)
		specular_lighting = vec3(pow( LdotR, float(PhongExponent) ));

		specular_lighting *= saturate(dot( NORMAL, LIGHT ));		// Mask with N.L
		specular_lighting *= LIGHT_COLOR;											// Modulate with light color

		if (Rimlight)
		{
			rim  = vec3(pow( max(-dot( vReflect, LIGHT ), 0.0), float(RimlightExponent) ));	// Raise to rim exponent
			rim *= (1.0 - dotN);		// Mask with N.L
			rim *= vec3(0.2, 0.5, 1.0);
			SPECULAR_LIGHT += rim * RimlightBoost;
		}

		SPECULAR_LIGHT += ATTENUATION * specular_lighting * PhongBoost * Fresnel(NORMAL, VIEW, PhongFresnelRanges);
	}

	/*if (Phong)
	{
		vec3 reflection_dir = -reflect(VIEW, NORMAL);
		float range_fresnel = Fresnel(NORMAL, VIEW, PhongFresnelRanges);
		float dotR = max(dot(LIGHT, reflection_dir), 0.0);
		dotR = pow(dotR, float(PhongExponent)) * PhongBoost;
		SPECULAR_LIGHT += max(dotR, 0.0) * LIGHT_COLOR * ATTENUATION * range_fresnel;

		if (Rimlight)
		{
			DIFFUSE_LIGHT += pow(max(dot(-reflection_dir, normalize(vec3(0.0, 0.0, PhongFresnelRanges.z))), 0.0), float(RimlightExponent)) * RimlightBoost;
		}
	}*/
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
