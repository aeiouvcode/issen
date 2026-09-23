shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
#include "res://shaders/common.gdshaderinc"
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float prog = 1.0;   // 0..1 sweep
uniform float life = 1.0;   // 1 -> 0 dissolve
uniform float flip = 0.0;
uniform float tint = 0.0;   // red hit tint
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}
void fragment() {
	vec2 uv = UV;
	if (flip > 0.5) uv.x = 1.0 - uv.x;
	// rotate around the arc centre so the wet leading edge travels with prog
	vec2 c = vec2(0.5, 1.02);
	vec2 p = (uv - c) * vec2(2.0, 1.0);
	float a = (1.0 - prog) * 2.3;
	p = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * p;
	vec2 suv = p / vec2(2.0, 1.0) + c;
	vec4 t = texture(tex, suv);
	float inside = step(0.0, suv.x) * step(suv.x, 1.0) * step(0.0, suv.y) * step(suv.y, 1.0);
	float n = vnoise(UV * vec2(40.0, 9.0));
	float d = t.a - (1.0 - life) * (0.7 + 0.5 * n);
	ALBEDO = mix(t.rgb, vec3(0.62, 0.07, 0.08), tint);
	ALPHA = clamp(d * 2.5, 0.0, 1.0) * inside;
}
