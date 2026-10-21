shader_type spatial;
// 冠の縁だけ薄いフェルト殻。面全体のディザ禁止。シルエット近傍のみ穴を開ける。
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform sampler2D leaf_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 leaf_color : source_color = vec3(0.52, 0.58, 0.40);
uniform float density : hint_range(0.0, 1.0) = 0.58;
uniform float shell_tint : hint_range(0.5, 1.2) = 1.10;

varying vec3 v_world;
varying vec3 v_n;

float _hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

void vertex() {
	// 薄い縁だけ。厚すぎるとディザ輪郭になる
	float lift = 0.010 + _hash31(VERTEX * 36.0) * 0.006;
	VERTEX += NORMAL * lift;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float facing = abs(dot(normalize(v_n), VIEW));
	// 正面はほぼ残さない。縁だけ短いフェルト毛羽
	float edge = pow(1.0 - facing, 1.75);
	float n1 = _hash31(v_world * 64.0);
	float n2 = _hash31(v_world * 110.0 + 2.4);
	float pile = n1 * 0.55 + n2 * 0.45;
	float cut = pile * edge;
	// 極縁だけ。density 高め＝ほぼ捨てる
	if (cut < density * 0.70) {
		discard;
	}
	vec3 tex = texture(leaf_tex, v_world.xz * 3.6).rgb;
	float tex_l = dot(tex, vec3(0.3, 0.5, 0.2));
	vec3 base = leaf_color * (0.92 + tex_l * 0.16) * shell_tint;
	base *= 0.90 + edge * 0.18;
	ALBEDO = base;
	ALPHA = 1.0;
}
