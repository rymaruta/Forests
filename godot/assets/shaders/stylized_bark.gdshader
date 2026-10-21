shader_type spatial;
// マット粘土樹皮：エンジンLambertの円柱ハイライトを避け、溝はアルベドで読む
render_mode blend_mix, depth_draw_opaque, cull_back, unshaded;

uniform sampler2D bark_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 bark_color : source_color = vec3(0.42, 0.28, 0.18);
uniform vec3 bark_dark : source_color = vec3(0.22, 0.14, 0.08);
uniform float uv_scale_x = 1.05;
uniform float uv_scale_y = 2.1;

varying vec3 v_world;
varying vec3 v_normal;

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

float _groove_at(vec3 wpos) {
	float ang = atan(wpos.z, wpos.x);
	float y = wpos.y;
	// 裾〜幹中腹まで溝を読ませる（趾上面は弱め）
	float groove_mask = smoothstep(0.05, 0.22, y) * (1.0 - smoothstep(1.55, 1.75, y));
	float warp = _n2(vec2(ang * 0.50, y * 0.30)) * 1.5
		+ _n2(vec2(ang * 1.2 + 1.8, y * 0.7)) * 0.65;
	float a01 = ang / 6.2831853 + warp * 0.14;
	// 約3本の太い有機溝
	float gA = 0.5 + 0.5 * sin((a01 * 3.0 + warp * 0.5) * 6.2831853);
	float gB = 0.5 + 0.5 * sin((a01 * 5.5 + warp * 0.9 + 0.35) * 6.2831853);
	float gN = _n2(vec2(a01 * 3.2 + warp, y * 0.65));
	float groove = gA * 0.58 + gB * 0.22 + gN * 0.20;
	groove = smoothstep(0.22, 0.78, groove) * groove_mask;
	float grain = _n2(vec2(ang * 2.4, y * 1.6));
	groove = mix(groove, groove * (0.80 + grain * 0.38), 0.30);
	return groove;
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float g = _groove_at(v_world);
	VERTEX += NORMAL * (g - 0.32) * 0.022;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 uv = vec2(UV.x * uv_scale_x, UV.y * uv_scale_y);
	vec3 tex = texture(bark_tex, uv).rgb;
	float groove = _groove_at(v_world);
	float tex_g = tex.r * 0.34 + 0.28;
	float y_mask = smoothstep(0.05, 0.22, v_world.y);
	groove = mix(tex_g * y_mask * 0.55, groove, 0.78);

	// 彫り：遠目でも読める色差（黒帯ゼブラは避ける）
	vec3 base = mix(bark_color * 1.16, bark_dark * 0.52, clamp(groove * 1.18, 0.0, 1.0));
	base *= 0.97 + tex.g * 0.05;

	vec3 n = normalize(v_normal);
	vec3 t_ang = normalize(cross(n, vec3(0.0, 1.0, 0.0)));
	if (length(t_ang) < 1e-3) {
		t_ang = vec3(1.0, 0.0, 0.0);
	}
	n = normalize(n + t_ang * (groove - 0.45) * 0.85);

	// ほぼフラット：円柱のプラスチックハイライトを殺す
	vec3 L = normalize(vec3(0.22, 0.92, 0.28));
	float ndl = clamp(dot(n, L) * 0.5 + 0.5, 0.0, 1.0);
	float wrap = mix(0.985, 1.015, ndl);
	ALBEDO = base * wrap;
}
