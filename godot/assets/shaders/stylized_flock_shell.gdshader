shader_type spatial;
// 冠の縁だけ柔らかいフェルト殻。discardディザ禁止・半透明で溶かす。
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform sampler2D leaf_tex : source_color, filter_linear, repeat_enable;
uniform vec3 leaf_color : source_color = vec3(0.52, 0.58, 0.40);
uniform float density : hint_range(0.0, 1.0) = 0.55;
uniform float shell_tint : hint_range(0.5, 1.2) = 1.04;

varying vec3 v_world;
varying vec3 v_n;

float _hash31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

void vertex() {
	float lift = 0.014 + _hash31(VERTEX * 36.0) * 0.012;
	VERTEX += NORMAL * lift;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_n = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float facing = abs(dot(normalize(v_n), VIEW));
	float edge = pow(1.0 - facing, 1.35);
	// 面中央はほぼ消す。縁だけ薄い毛羽
	float mask = smoothstep(0.08, 0.85, edge);
	float n1 = _hash31(v_world * 62.0);
	float n2 = _hash31(v_world * 110.0 + 2.4);
	float pile = n1 * 0.55 + n2 * 0.45;
	float a = mask * density * (0.35 + pile * 0.65);
	if (a < 0.04) {
		discard;
	}
	vec3 tex = texture(leaf_tex, v_world.xz * 3.6).rgb;
	float tex_l = dot(tex, vec3(0.3, 0.5, 0.2));
	vec3 base = leaf_color * (0.90 + tex_l * 0.16) * shell_tint;
	base += vec3(0.03, 0.028, 0.014) * edge;
	ALBEDO = base;
	ALPHA = clamp(a, 0.0, 0.72);
}
