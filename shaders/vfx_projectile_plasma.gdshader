shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

uniform vec4 main_color : source_color = vec4(0.25, 0.85, 1.00, 1.0);
uniform vec4 core_color : source_color = vec4(0.95, 0.99, 1.00, 1.0);
uniform float energy : hint_range(0.5, 6.0) = 2.8;
uniform float alpha_mult : hint_range(0.0, 1.0) = 0.90;
uniform float flow_speed = 6.0;
uniform float is_tail : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float ndotv = abs(dot(normalize(NORMAL), normalize(VIEW)));
	vec3 col = main_color.rgb;
	float alpha = 0.0;

	if (is_tail < 0.5) {
		float rim = pow(clamp(1.0 - ndotv, 0.0, 1.0), 1.65);
		float bands = 0.82 + 0.18 * sin(UV.y * 18.0 - TIME * flow_speed);
		float center_hot = pow(clamp(ndotv, 0.0, 1.0), 2.2);
		col = mix(main_color.rgb, core_color.rgb, clamp(center_hot * 0.65 + rim * 0.45, 0.0, 1.0));
		alpha = clamp(max(rim * 0.85, center_hot * 0.72) * bands * alpha_mult, 0.0, 1.0);
	} else {
		// Capless CylinderMesh maps UV.y from 0.0 (head/top) to 0.5 (tip/bottom)
		float t_len = clamp(UV.y * 2.0, 0.0, 1.0);
		float length_fade = (1.0 - smoothstep(0.05, 0.98, t_len)) * smoothstep(0.0, 0.06, t_len);
		float edge_fade = pow(clamp(ndotv, 0.0, 1.0), 1.2);
		float streaks = 0.75 + 0.25 * sin((UV.x * 6.0 + t_len * 3.0) * 6.2831853 - TIME * flow_speed * 1.5);
		col = mix(main_color.rgb, core_color.rgb, clamp((1.0 - t_len) * 0.65 * edge_fade, 0.0, 1.0));
		alpha = clamp(length_fade * edge_fade * streaks * alpha_mult, 0.0, 1.0);
	}

	ALBEDO = col * energy;
	ALPHA = alpha;
}
