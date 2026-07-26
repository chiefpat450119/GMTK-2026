shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D noise_tex : repeat_enable, filter_linear;

uniform float drain : hint_range(0.0, 1.0) = 0.0;
uniform float noise_scale : hint_range(0.1, 8.0) = 1.6;
uniform float noise_bias : hint_range(0.0, 4.0) = 1.0;
uniform float partial_drain : hint_range(0.0, 1.0) = 0.55;
uniform float final_drain : hint_range(0.0, 1.0) = 0.65;
uniform float final_from : hint_range(0.0, 1.0) = 0.85;
uniform float drift : hint_range(0.0, 0.2) = 0.01;

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 noise_uv = SCREEN_UV * vec2(res.x / res.y, 1.0) * noise_scale;
	noise_uv += vec2(TIME * drift, TIME * drift * 0.6);
	float n = texture(noise_tex, noise_uv).r;

	float local = clamp(drain * (1.0 + noise_bias) - n * noise_bias, 0.0, 1.0);
	float ceiling = mix(partial_drain, final_drain, smoothstep(final_from, 1.0, drain));
	float amount = smoothstep(0.0, 1.0, local) * ceiling;

	vec3 screen = texture(screen_tex, SCREEN_UV).rgb;
	float grey = dot(screen, vec3(0.299, 0.587, 0.114));

	COLOR = vec4(vec3(grey), amount);
}
