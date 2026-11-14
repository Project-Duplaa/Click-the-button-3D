shader_type spatial;
render_mode cull_back;

uniform vec4 color_a : source_color = vec4(1.0, 0.718, 0.012, 1.0);
uniform vec4 color_b : source_color = vec4(0.082, 0.090, 0.110, 1.0);
uniform float stripe_frequency = 8.0;
uniform float stripe_angle_deg = 45.0;
uniform float stripe_ratio : hint_range(0.05, 0.95) = 0.5;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform float edge_aa : hint_range(0.001, 0.15) = 0.02;
uniform float metallic_a : hint_range(0.0, 1.0) = 0.25;
uniform float metallic_b : hint_range(0.0, 1.0) = 0.80;
uniform float roughness_a : hint_range(0.0, 1.0) = 0.38;
uniform float roughness_b : hint_range(0.0, 1.0) = 0.42;
uniform float wear_amount : hint_range(0.0, 0.4) = 0.06;
uniform float emission_a : hint_range(0.0, 1.5) = 0.0;

void fragment() {
	vec2 uv = UV * uv_scale;
	float rad = radians(stripe_angle_deg);
	vec2 dir = vec2(cos(rad), sin(rad));
	float proj = dot(uv, dir) * stripe_frequency;

	float fw = max(fwidth(proj), edge_aa);
	float aa = clamp(fw, 0.002, 0.25);

	// Continuous symmetric distance around stripe A center to avoid seam wrap artifacts
	float shifted = fract(proj + 0.5 - stripe_ratio * 0.5);
	float d = abs(shifted - 0.5);
	float half_w = stripe_ratio * 0.5;
	float mask_a = 1.0 - smoothstep(half_w - aa, half_w + aa, d);

	// Subtle procedural industrial wear without external textures
	float micro = fract(sin(dot(floor(uv * 64.0), vec2(12.9898, 78.233))) * 43758.5453);
	float wear = (micro - 0.5) * wear_amount;

	vec3 col = mix(color_b.rgb, color_a.rgb, mask_a) + vec3(wear);
	ALBEDO = clamp(col, vec3(0.0), vec3(1.0));
	METALLIC = mix(metallic_b, metallic_a, mask_a);
	ROUGHNESS = clamp(mix(roughness_b, roughness_a, mask_a) - wear * 0.5, 0.05, 1.0);
	if (emission_a > 0.001) {
		EMISSION = color_a.rgb * mask_a * emission_a;
	}
}
