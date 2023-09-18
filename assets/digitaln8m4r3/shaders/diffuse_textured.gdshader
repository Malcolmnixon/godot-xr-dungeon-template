// Author: DigitalN8m4r3 - Miodrag Sejic
// License: Public Domain CC0
shader_type spatial;
render_mode cull_back,specular_disabled,unshaded,shadows_disabled,ambient_light_disabled;
uniform vec4 color : source_color;
uniform sampler2D texture_albedo : source_color,filter_nearest;


void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = color.rgb * albedo_tex.rgb;
}
