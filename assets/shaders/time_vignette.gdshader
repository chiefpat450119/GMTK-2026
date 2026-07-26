shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float pulse : hint_range(0.0, 1.0) = 1.0;
uniform vec4 tint : source_color = vec4(0.62, 0.09, 0.08, 1.0);
uniform float radius_weak : hint_range(0.0, 2.0) = 1.35;
uniform float radius_full : hint_range(0.0, 2.0) = 0.72;
uniform float feather : hint_range(0.05, 2.0) = 0.5;
uniform float max_opacity : hint_range(0.0, 1.0) = 0.85;
uniform float desaturation : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	float dist = length((UV - vec2(0.5)) * 2.0);
	float inner = mix(radius_weak, radius_full, intensity);
	float ring = smoothstep(inner, inner + feather, dist);
	float amount = ring * intensity * pulse * max_opacity;

	vec3 screen = texture(screen_tex, SCREEN_UV).rgb;
	float grey = dot(screen, vec3(0.299, 0.587, 0.114));
	vec3 drained = mix(screen, vec3(grey), desaturation) * tint.rgb;

	COLOR = vec4(drained, amount);
}
