shader_type canvas_item;
render_mode blend_mix;

uniform float hp_ratio : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 color = COLOR;
	float avg = (color.r + color.g + color.b)  / 3.0;
	COLOR.rgb = mix(vec3(avg), color.rgb, hp_ratio);
}
