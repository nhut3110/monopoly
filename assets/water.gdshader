shader_type spatial;
render_mode diffuse_burley;
uniform vec4 water_color : source_color = vec4(0.24, 0.48, 0.54, 1.0);
varying vec3 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float ripple = sin(world_position.x * 0.55 + TIME * 0.8) * sin(world_position.z * 0.42 - TIME * 0.6);
	ALBEDO = water_color.rgb * (1.0 + ripple * 0.05);
	ROUGHNESS = 0.48;
	METALLIC = 0.08;
}
