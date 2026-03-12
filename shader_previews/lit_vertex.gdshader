shader_type spatial;
render_mode unshaded;

global uniform vec3 SunDirection;

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

// this is weird but godot light shaders dont seem to work when vertex lighting is on so i have to fake it for now
varying vec2 VertexLighting;


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

vec2 CalculateLighting(vec3 Normal, vec3 View)
{
	// I tried some parts my best to mimic it although some parts of source code I found online didn't seem to be easy to understand
	float diffuse_lighting = 0.0;
	float specular_lighting = 0.0;
	
	float dotN = dot(Normal, SunDirection);
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

	diffuse_lighting = dotN;

	// Specular and rim lighting
	if (Phong)
	{
		vec3 rim = vec3(0.0);

		vec3 vReflect = 2.0 * Normal * dot( Normal , View ) - View; // Reflect view through normal
		float LdotR = saturate(dot( vReflect, SunDirection ));					// L.R	(use half-angle instead?)
		specular_lighting = vec3(pow( LdotR, float(PhongExponent) )).y;

		specular_lighting *= saturate(dot( Normal, SunDirection ));		// Mask with N.L
		//specular_lighting *= LIGHT_COLOR;											// Modulate with light color

		if (Rimlight)
		{
			rim  = vec3(pow( max(-dot( vReflect, SunDirection ), 0.0), float(RimlightExponent) ));	// Raise to rim exponent
			rim *= (1.0 - dotN);		// Mask with N.L
			rim *= vec3(0.2, 0.5, 1.0);
			specular_lighting += rim.y * RimlightBoost;
		}

		specular_lighting *= PhongBoost * Fresnel(Normal, View, PhongFresnelRanges);
	}
	
	return vec2(diffuse_lighting, specular_lighting);
}

void vertex() {
	VertexLighting = CalculateLighting(NORMAL, CAMERA_DIRECTION_WORLD);
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
	
	ALBEDO *= vec3(VertexLighting.x) + vec3(0.07, 0.15, 0.3);
	ALBEDO += VertexLighting.y;
	//ALBEDO += vec3(0.07, 0.15, 0.3) * 0.5;
}
