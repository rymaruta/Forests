shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform sampler2D bark_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 bark_color : source_color = vec3(0.42, 0.28, 0.18);
uniform vec3 bark_dark : source_color = vec3(0.22, 0.14, 0.08);
uniform float uv_scale_x = 1.05;
uniform float uv_scale_y = 2.1;

varying vec3 v_world;

float _hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float _n2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = _hash21(i);
	float b = _hash21(i + vec2(1, 0));
	float c = _hash21(i + vec2(0, 1));
	float d = _hash21(i + vec2(1, 1));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = vec2(UV.x * uv_scale_x, UV.y * uv_scale_y);
	vec3 tex = texture(bark_tex, uv).rgb;
	float ang = atan(v_world.z, v_world.x);
	float y = v_world.y;

	// 有機縦溝：角度をノイズで曲げ、溝幅もばらつかせる（規則柱・ゼブラ禁止）
	// 裾・趾は溝を弱め（マウンドを壊さない）、幹中腹で読む
	float trunk_mask = smoothstep(0.15, 0.55, y);
	float warp = _n2(vec2(ang * 0.9, y * 0.55)) * 1.1
		+ _n2(vec2(ang * 2.1 + 3.0, y * 1.1)) * 0.55
		+ _n2(vec2(y * 0.8, ang * 0.4)) * 0.40;
	float bands = 4.5;
	float u = fract((ang / 6.2831853) * bands + warp + y * 0.18);
	float width = 0.18 + 0.14 * _n2(vec2(floor((ang / 6.2831853) * bands + warp * 2.0), y * 0.35));
	float groove = 1.0 - smoothstep(0.0, width, abs(u - 0.5));
	groove = pow(groove, 1.55) * trunk_mask;
	float grain = _n2(vec2(ang * 4.5, y * 3.2));
	groove = mix(groove, groove * (0.72 + grain * 0.55), 0.45);

	float tex_g = tex.r * 0.55 + 0.22;
	groove = mix(tex_g * trunk_mask, groove, 0.70);

	float ndl = clamp(dot(NORMAL, normalize(vec3(0.2, 1.0, 0.15))), 0.0, 1.0);
	ndl = mix(0.86, 1.0, ndl);
	vec3 base = mix(bark_dark, bark_color, 0.38 + groove * 0.44);
	base *= 0.90 + ndl * 0.14;
	ALBEDO = base;
	ROUGHNESS = 0.99;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
