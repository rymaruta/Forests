shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform sampler2D bark_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 bark_color : source_color = vec3(0.42, 0.28, 0.18);
uniform vec3 bark_dark : source_color = vec3(0.22, 0.14, 0.08);
uniform float uv_scale_x = 1.6;
uniform float uv_scale_y = 2.8;

void fragment() {
	vec2 uv = vec2(UV.x * uv_scale_x, UV.y * uv_scale_y);
	vec3 tex = texture(bark_tex, uv).rgb;
	float groove = tex.r;
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.2, 1.0, 0.15))), 0.0, 1.0);
	ndl = mix(0.65, 1.0, ndl);
	vec3 base = mix(bark_dark, bark_color, 0.3 + groove * 0.5);
	base *= 0.78 + ndl * 0.28;
	ALBEDO = base;
	ROUGHNESS = 0.92;
	SPECULAR = 0.0;
}
