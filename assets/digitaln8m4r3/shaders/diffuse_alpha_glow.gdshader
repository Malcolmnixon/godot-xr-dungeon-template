// Author: DigitalN8m4r3 - Miodrag Sejic and Mux213 - Bastiaan Oli
// License: Public Domain CC0
shader_type spatial;
render_mode blend_mix, specular_disabled, depth_draw_always;

uniform sampler2D albedo_texture : source_color;
uniform bool useAlpha;
uniform bool useEmission;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(.0, .0);


void fragment() {
	vec2 uv = UV * uv_scale + uv_offset;
// Albedo Texture
	vec4 diffuse = texture(albedo_texture, uv);
	ALBEDO = diffuse.rgb * diffuse.a;
	if (useAlpha)
	ALPHA *= diffuse.a * diffuse.a;
	if (useEmission)
	EMISSION = diffuse.rgb * (1.0 - diffuse.a);
}
