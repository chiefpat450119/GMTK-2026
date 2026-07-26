shader_type canvas_item;
// Additive so overlapping sparks pile up into a hot core. A ShaderMaterial replaces
// the CanvasItemMaterial the project's other hot effects get this from.
render_mode blend_add;

// Carves a noise tile into thin bright filaments. Expects a NoiseTexture2D with no
// colour ramp: the raw value is read from red, and the particle colour does the
// tinting.

uniform float filament_sharpness : hint_range(1.0, 24.0) = 9.0;
uniform float threshold : hint_range(0.0, 0.95) = 0.42;
uniform float core_boost : hint_range(0.0, 8.0) = 3.0;
uniform float edge_softness : hint_range(0.05, 1.0) = 0.55;
uniform float tiling : hint_range(0.5, 4.0) = 1.0;
uniform vec2 crawl = vec2(0.7, -0.35);

varying vec4 particle_color;

void vertex() {
	particle_color = COLOR;
}

void fragment() {
	// Sliding the lookup animates the filaments for one fetch, and lands each spark
	// on a different slice of the tile. Needs texture_repeat on the emitter.
	float n = texture(TEXTURE, UV * tiling + crawl * TIME).r;

	// Ridge, not peak: distance from the noise's mid band puts the bright line where
	// the value crosses over. Peaks would give round blobs.
	float ridge = 1.0 - abs(n * 2.0 - 1.0);
	ridge = clamp((ridge - threshold) / max(1.0 - threshold, 0.001), 0.0, 1.0);
	ridge = pow(ridge, filament_sharpness);

	float dist = min(length(UV - vec2(0.5)) * 2.0, 1.0);
	float mask = 1.0 - smoothstep(1.0 - edge_softness, 1.0, dist);

	// Scales the core's brightness rather than mixing it towards white: the particle
	// colour is already past 1.0 for the glow to catch, and mixing towards white
	// would pull it back down. Keeps the hue and drives it further into HDR instead.
	float hot = 1.0 + core_boost * smoothstep(0.35, 1.0, ridge);
	COLOR = vec4(particle_color.rgb * hot, ridge * mask * particle_color.a);
}
