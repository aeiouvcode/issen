shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float fade_near = 26.0;
uniform float fade_far = 44.0;
varying float vdist;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	float top = 1.0 - UV.y;
	VERTEX.x += sin(TIME * 1.1 + MODEL_MATRIX[3].x * 0.6 + MODEL_MATRIX[3].z * 0.3) * 0.09 * top * top;
	vdist = length(MODEL_MATRIX[3].xyz - CAMERA_POSITION_WORLD);
}
void fragment() {
	vec4 t = texture(tex, UV);
	float fade = 1.0 - smoothstep(fade_near, fade_far, vdist);
	ALBEDO = mix(t.rgb, vec3(0.55, 0.52, 0.48), 0.55);
	ALPHA = t.a * fade;
	ALPHA_SCISSOR_THRESHOLD = 0.35;
}
