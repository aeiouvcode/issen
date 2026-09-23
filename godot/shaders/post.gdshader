shader_type canvas_item;
#include "res://shaders/common.gdshaderinc"
uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform float hurt = 0.0;
void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 c = texture(screen, uv).rgb;
	vec2 px = FRAGCOORD.xy;
	float g = vnoise(px * 0.45) * 0.4 + vnoise(px * 0.06) * 0.6;
	c *= 0.95 + 0.08 * g;
	// ink-wash vignette: brown tea-stain toward the paper edge, ragged
	vec2 sz = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 d = min(uv, 1.0 - uv) * sz / min(sz.x, sz.y);
	float e = min(d.x, d.y);
	float rag = fbm(uv * vec2(7.0, 5.0)) * 0.08;
	float v = smoothstep(0.0, 0.10 + rag, e);
	c = mix(c * vec3(0.80, 0.66, 0.50), c, v);
	c = mix(c * 0.7, c, smoothstep(0.0, 0.008 + rag * 0.15, e));
	// large faint stains
	float s = smoothstep(0.62, 0.9, fbm(uv * 2.3 + 11.0));
	c *= 1.0 - s * 0.07;
	c = mix(c, c * vec3(1.0, 0.55, 0.5), hurt * (1.0 - v) * 0.35);
	COLOR = vec4(c, 1.0);
}
