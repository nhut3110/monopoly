shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.64, 0.72, 0.92, 1.0);
uniform vec4 upper_mid_color : source_color = vec4(0.86, 0.75, 0.87, 1.0);
uniform vec4 lower_mid_color : source_color = vec4(0.98, 0.84, 0.76, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.99, 0.92, 0.82, 1.0);

void fragment() {
	float y = clamp(UV.y, 0.0, 1.0);
	vec3 col = mix(top_color.rgb, upper_mid_color.rgb, smoothstep(0.0, 0.38, y));
	col = mix(col, lower_mid_color.rgb, smoothstep(0.32, 0.74, y));
	col = mix(col, bottom_color.rgb, smoothstep(0.65, 1.0, y));

	// Soft luminous studio halo behind the diorama board
	float halo = exp(-2.4 * length((UV - vec2(0.5, 0.50)) * vec2(0.85, 1.2)));
	col = mix(col, vec3(1.0, 0.99, 0.96), halo * 0.24);

	// Soft cloud/bokeh arcs in corners for AAA mobile polish
	vec2 p = (UV - vec2(0.5)) * vec2(1.777, 1.0);
	float bokeh = 0.0;
	bokeh += smoothstep(0.28, 0.05, length(p - vec2(-0.68, -0.32))) * 0.14;
	bokeh += smoothstep(0.32, 0.06, length(p - vec2(0.72, -0.28))) * 0.14;
	bokeh += smoothstep(0.36, 0.06, length(p - vec2(-0.62, 0.36))) * 0.12;
	bokeh += smoothstep(0.34, 0.06, length(p - vec2(0.66, 0.34))) * 0.12;
	col = mix(col, vec3(1.0, 1.0, 1.0), clamp(bokeh, 0.0, 0.22));

	float vignette = 1.0 - 0.055 * dot((UV - vec2(0.5)) * vec2(1.0, 0.85), (UV - vec2(0.5)) * vec2(1.0, 0.85));
	COLOR = vec4(col * vignette, 1.0);
}
