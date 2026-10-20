shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform sampler2D bark_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 bark_color : source_color = vec3(0.42, 0.28, 0.18);
uniform vec3 bark_dark : source_color = vec3(0.22, 0.14, 0.08);
uniform float uv_scale_x = 1.6;
uniform float uv_scale_y = 2.8;

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

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

void fragment() {
	vec2 uv = vec2(UV.x * uv_scale_x, UV.y * uv_scale_y);
	vec3 tex = texture(bark_tex, uv).rgb;
	float ang = atan(v_world.z, v_world.x);
	float y = v_world.y;
	// 有機縦溝：位相・幅・深さを高さで揺らす（規則フルート禁止）
	float twist = y * 0.48 + sin(y * 1.35) * 0.55 + _n2(vec2(ang * 0.7, y * 0.55)) * 1.1;
	float wiggle = _n2(vec2(ang * 1.4 + 2.1, y * 0.9)) * 0.55;
	float g1 = 0.5 + 0.5 * sin(ang * (5.5 + wiggle) + twist);
	float g2 = 0.5 + 0.5 * sin(ang * (8.5 + wiggle * 0.6) + twist * 1.25 + 1.1);
	float world_groove = g1 * 0.62 + g2 * 0.38;
	world_groove = smoothstep(0.35, 0.72, world_groove);
	// テクスチャ主導（規則 sine 柱禁止）
	float groove = mix(world_groove, tex.r * 0.88 + 0.06, 0.88);
	float ndl = clamp(dot(NORMAL, normalize(vec3(0.2, 1.0, 0.15))), 0.0, 1.0);
	ndl = mix(0.82, 1.0, ndl);
	// ゼブラ強溝禁止：コントラストは参照級に抑える
	vec3 base = mix(bark_dark, bark_color, 0.40 + groove * 0.38);
	base *= 0.90 + ndl * 0.14;
	ALBEDO = base;
	ROUGHNESS = 0.99;
	SPECULAR = 0.0;
	METALLIC = 0.0;
}
