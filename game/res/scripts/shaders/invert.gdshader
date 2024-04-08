// Code taken from: https://godotshaders.com/shader/invert-color/
// Not distributed under public domain. Check page to see applicable license
shader_type canvas_item;

void fragment(){
	vec4 color = texture(TEXTURE, UV);
	COLOR = vec4(1.0 - color.rgb, color.a);
}
