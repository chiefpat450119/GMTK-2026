shader_type canvas_item;
render_mode blend_mix;

varying vec4 v_modulate;

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform float progress : hint_range(0.0, 1.0) = 0.0;

group_uniforms erosion;

uniform float noise_scale : hint_range(0.5, 32.0) = 4.5;
uniform vec2 noise_offset = vec2(0.0);
uniform vec2 sweep_dir = vec2(0.0, 1.0);
uniform float sweep_weight : hint_range(0.0, 1.0) = 0.45;
uniform float grain_scale : hint_range(1.0, 16.0) = 5.0;
uniform float grain_amount : hint_range(0.0, 1.0) = 0.2;
uniform float edge_width : hint_range(0.001, 0.5) = 0.07;

group_uniforms edge;
uniform vec4 edge_color : source_color = vec4(1.0, 0.78, 0.42, 1.0);
uniform float edge_energy : hint_range(0.0, 4.0) = 1.3;
uniform float edge_reach : hint_range(1.0, 8.0) = 1.6;

group_uniforms wind;
uniform vec2 wind_dir = vec2(0.35, -1.0);
uniform float wind_smear : hint_range(0.0, 0.25) = 0.03;
uniform float noise_drift : hint_range(0.0, 0.5) = 0.05;

void vertex() {
	v_modulate = COLOR;
}

void fragment() {
	vec2 tex_size = vec2(1.0) / TEXTURE_PIXEL_SIZE;
	vec2 aspect = tex_size / max(tex_size.x, tex_size.y);

	vec2 noise_uv = UV * aspect * noise_scale + noise_offset;
	noise_uv += normalize(wind_dir) * TIME * noise_drift;

	float patches = texture(noise_tex, noise_uv).r;
	float grain = texture(noise_tex, noise_uv * grain_scale + vec2(0.37, 0.71)).r;
	float sweep = clamp(dot(UV - vec2(0.5), normalize(sweep_dir)) + 0.5, 0.0, 1.0);
	float threshold = mix(patches, sweep, sweep_weight) + (grain - 0.5) * grain_amount;
	threshold = clamp(threshold, 0.0, 1.0);

	float lead = edge_width * edge_reach;
	float cut = progress * (1.0 + edge_width + lead) - lead;

	float solid = smoothstep(cut, cut + edge_width, threshold);
	float rim_end = cut + edge_width * max(edge_reach, 1.01);
	float rim = (1.0 - smoothstep(cut + edge_width, rim_end, threshold)) * solid;

	vec2 uv = UV - normalize(wind_dir) * wind_smear * rim * progress;
	vec4 tex = texture(TEXTURE, uv);

	vec3 col = mix(tex.rgb, edge_color.rgb * edge_energy, rim * edge_color.a);
	COLOR = vec4(col, tex.a * solid) * v_modulate;
}
