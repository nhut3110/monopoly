shader_type spatial;
uniform vec4 original_a;
uniform vec4 original_b;
uniform vec4 original_c;
uniform vec4 paint_a;
uniform vec4 paint_b;
uniform vec4 paint_c;
void fragment() {
	vec3 paint = COLOR.rgb;
	if (distance(paint, original_a.rgb) < 0.015) paint = paint_a.rgb;
	else if (distance(paint, original_b.rgb) < 0.015) paint = paint_b.rgb;
	else if (distance(paint, original_c.rgb) < 0.015) paint = paint_c.rgb;
	ALBEDO = paint;
	ROUGHNESS = 0.85;
}
