shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

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
	ndl = (ndl + 0.35) / 1.35;
	vec3 base = mix(bark_dark, bark_color, 0.25 + groove * 0.55);
	base *= 0.7 + ndl * 0.4;
	ALBEDO = base;
	ROUGHNESS = 0.9;
	SPECULAR = 0.08;
}
