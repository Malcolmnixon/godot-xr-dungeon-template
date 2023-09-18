// Author: DigitalN8m4r3 - Miodrag Sejic
// License: Public Domain CC0
shader_type spatial;
render_mode blend_mix, specular_disabled;

uniform sampler2D albedo_texture : source_color;
uniform sampler2D glow_texture : source_color;
uniform bool useEmission;
uniform vec3 color : source_color;
uniform float brightness : hint_range(0.0, 1.0, 0.1);
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(.0, .0);
void fragment() {
	vec2 uv = UV * uv_scale + uv_offset;
// Albedo Texture
	vec4 diffuse = texture(albedo_texture, uv);
// Emission Texture
	vec4 glow = texture(glow_texture, uv) * brightness;
	float e_energy_mul = 1.5;
	vec3 e_op = color * e_energy_mul;
	ALBEDO = diffuse.rgb;
	if (useEmission)
		EMISSION = glow.rgb * e_op;
}
