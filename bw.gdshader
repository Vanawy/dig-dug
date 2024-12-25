shader_type canvas_item;


uniform sampler2D sources: filter_nearest;
uniform sampler2D scr_tex: hint_screen_texture;

float circle(vec2 position, float radius, float feather)
{
	return smoothstep(radius, radius + feather, length(position));
}

void fragment() {

	ivec2 size = textureSize(sources, 0);
	float mult = 1.0;
	for (int i = 0; i < size.x; i++) {
		vec4 source = texelFetch(sources, ivec2(i, 0), 0);
		if (source.z < 0.01) {
			continue;
		}
		mult = min(mult, circle(SCREEN_UV - source.xy, source.z, source.z * 1.6));
	}

    vec4 original_color = texture(scr_tex, UV);
    	//COLOR = vec4(vec3(1.0), 1.0);
    COLOR = mix(original_color, COLOR, mult);
}
