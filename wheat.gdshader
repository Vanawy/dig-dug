shader_type canvas_item;
render_mode blend_mix;



// Wind settings.
// original wind shader from https://github.com/Maujoe/godot-simple-wind-shader-2d/tree/master/assets/maujoe.simple_wind_shader_2d
// original script modified by HungryProton so that the assets are moving differently : https://pastebin.com/VL3AfV8D
//
// speed - The speed of the wind movement.
uniform float speed = 1.0;
// minStrength - The minimal strength of the wind movement.
uniform float minStrength : hint_range(0.0, 1.0) = 0.05;
// maxStrength - The maximal strength of the wind movement.
uniform float maxStrength : hint_range(0.0, 1.0) = 0.01;
// strengthScale - Scalefactor for the wind strength.
uniform float strengthScale = 100.0;
// interval - The time between minimal and maximal strength changes.
uniform float interval = 3.5;
// detail - The detail (number of waves) of the wind movement.
uniform float detail = 1.0;
// distortion - The strength of geometry distortion.
uniform float distortion : hint_range(0.0, 1.0);
// heightOffset - The height where the wind begins to move. By default 0.0.
uniform float heightOffset : hint_range(0.0, 1.0);


uniform float timeOffsetScale = 1.0;

uniform float col = 1.0;

varying vec4 custom;

float getWind(vec2 vertex, vec2 uv, float time){
    float diff = pow(maxStrength - minStrength, 2.0);
    float strength = clamp(minStrength + diff + sin(time / interval) * diff, minStrength, maxStrength) * strengthScale;
    float wind = (sin(time) + cos(time * detail)) * strength * max(0.0, (1.0-uv.y) - heightOffset);

    return wind;
}

void vertex() {

	// r UV offset
	// g Wind time offset
	// b unused
	// a visibility (0 -hidden, 1-visible)
	custom = INSTANCE_CUSTOM;

	// from wind shader
    vec4 pos = MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);

	float offset = custom.y * timeOffsetScale;
    float time = TIME * speed + offset;
    //float time = TIME * speed + pos.x * pos.y  ; not working when moving...
    VERTEX.x += getWind(VERTEX.xy, UV, time);
}

void fragment() {
	if (custom.a > 0.5) {
		COLOR = texture(TEXTURE, UV / vec2(col, 1) + vec2(custom.x, 0));
	} else {
		COLOR = vec4(0.0);
	}
}
