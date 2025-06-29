shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.0;
varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	vec4 previous_color = texture(TEXTURE, UV) * modulate;
	vec4 flash_color = vec4(1.0, 1.0, 1.0, previous_color.a);
	vec4 new_color = mix(previous_color, flash_color, strength);
	
	COLOR = new_color;
}