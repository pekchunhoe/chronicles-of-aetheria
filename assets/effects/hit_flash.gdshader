shader_type canvas_item;
render_mode unshaded;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	COLOR = vec4(mix(source.rgb, vec3(1.0, 0.94, 0.79), hit_flash), source.a) * vertex_tint;
}
