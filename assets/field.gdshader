shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform vec3 grass_light : source_color = vec3(0.47, 0.71, 0.33);
uniform vec3 grass_dark : source_color = vec3(0.41, 0.65, 0.28);
uniform vec3 ring_color : source_color = vec3(0.76, 0.88, 0.58);

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	// Lush mowed park stripes + central circular dice plaza meadow
	float stripe = step(0.5, fract((local_pos.x + 36.0) / 9.0));
	vec3 base = mix(grass_dark, grass_light, stripe);

	float r = length(local_pos.xz);
	// Soft sunlit center dice ring accent
	float inner_glow = 1.0 - smoothstep(10.0, 18.0, r);
	base = mix(base, grass_light * 1.12, inner_glow * 0.38);
	float ring_line = 1.0 - smoothstep(0.0, 0.35, abs(r - 15.8));
	float outer_line = 1.0 - smoothstep(0.0, 0.30, abs(r - 17.2));

	ALBEDO = mix(base, ring_color, clamp(ring_line * 0.75 + outer_line * 0.4, 0.0, 1.0));
	ROUGHNESS = 0.92;
}
