shader_type canvas_item;

uniform float edge_softness : hint_range(0.05, 1.0) = 0.72;
uniform float threshold : hint_range(0.0, 0.95) = 0.18;
uniform float contrast : hint_range(0.25, 4.0) = 1.5;

varying vec4 particle_color;

void vertex() {
	particle_color = COLOR;
}

void fragment() {
	vec4 tile = texture(TEXTURE, UV);

	float wisp = clamp((tile.a - threshold) / max(1.0 - threshold, 0.001), 0.0, 1.0);
	wisp = pow(wisp, contrast);

	float dist = min(length(UV - vec2(0.5)) * 2.0, 1.0);
	float mask = 1.0 - smoothstep(1.0 - edge_softness, 1.0, dist);

	COLOR = vec4(tile.rgb * particle_color.rgb, wisp * mask * particle_color.a);
}
