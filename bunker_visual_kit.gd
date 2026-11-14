extends RefCounted
class_name BunkerVisualKit

## BunkerVisualKit — Núcleo Visual Industrial / Sci-Fi (Godot 4.7.2)
## Centraliza tokens PBR del Visual Contract, fábricas cacheadas de materiales,
## constructores de shaders (anillos hazard, haz Fresnel, holograma, franjas ISO 3864),
## ondas expansivas, helpers geométricos y overrides por instancia de modelos .glb.

const SHADER_HAZARD_RING := preload("res://shaders/hazard_ground_ring.gdshader")
const SHADER_BEACON_BEAM := preload("res://shaders/beacon_beam.gdshader")
const SHADER_HOLOGRAM_CORE := preload("res://shaders/hologram_core.gdshader")
const SHADER_HAZARD_STRIPES := preload("res://shaders/hazard_stripes.gdshader")

# ==============================================================================
# TOKENS CROMÁTICOS Y PBR OFICIALES (VISUAL CONTRACT)
# ==============================================================================
const COL_BUNKER_CONCRETE := Color(0.133, 0.149, 0.180, 1.0) # #22262E
const COL_CARBON_STEEL := Color(0.082, 0.090, 0.110, 1.0)    # #15171C
const COL_ARMOR_GREY := Color(0.208, 0.231, 0.278, 1.0)      # #353B47
const COL_TITANIUM_BRUSH := Color(0.322, 0.357, 0.424, 1.0)  # #525B6C
const COL_CABLE_RUBBER := Color(0.043, 0.047, 0.055, 1.0)    # #0B0C0E
const COL_CHROME_STEEL := Color(0.720, 0.760, 0.820, 1.0)
const COL_INDUSTRIAL_COPPER := Color(0.760, 0.440, 0.220, 1.0)

const COL_HAZARD_YELLOW := Color(1.000, 0.718, 0.012, 1.0)   # #FFB703
const COL_CYAN_ELECTRIC := Color(0.000, 0.941, 1.000, 1.0)   # #00F0FF
const COL_CRIMSON_ALERT := Color(1.000, 0.118, 0.259, 1.0)   # #FF1E42
const COL_PLASMA_ORANGE := Color(1.000, 0.416, 0.000, 1.0)   # #FF6A00
const COL_NEON_GREEN := Color(0.000, 1.000, 0.400, 1.0)      # #00FF66
const COL_VAULT_GOLD := Color(1.000, 0.816, 0.000, 1.0)      # #FFD000
const COL_CRYO_BLUE := Color(0.302, 0.933, 0.918, 1.0)       # #4DEEEA

static var _cache_pbr: Dictionary = {}

# ==============================================================================
# FÁBRICAS CACHEADAS DE MATERIALES PBR INDUSTRIALES
# ==============================================================================

static func _get_or_create_pbr(key: String, albedo: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	if _cache_pbr.has(key):
		var cached = _cache_pbr[key]
		if cached is StandardMaterial3D and is_instance_valid(cached):
			return cached
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.metallic = metallic
	mat.roughness = roughness
	_cache_pbr[key] = mat
	return mat

static func get_chassis_mat() -> StandardMaterial3D:
	return _get_or_create_pbr("carbon_steel", COL_CARBON_STEEL, 0.85, 0.30)

static func get_concrete_base_mat() -> StandardMaterial3D:
	return _get_or_create_pbr("bunker_concrete", COL_BUNKER_CONCRETE, 0.10, 0.85)

static func get_armor_grey_mat() -> StandardMaterial3D:
	return _get_or_create_pbr("armor_grey", COL_ARMOR_GREY, 0.65, 0.45)

static func get_titanium_mat() -> StandardMaterial3D:
	return _get_or_create_pbr("titanium_brush", COL_TITANIUM_BRUSH, 0.90, 0.22)

static func get_chrome_mat() -> StandardMaterial3D:
	return _get_or_create_pbr("chrome_steel", COL_CHROME_STEEL, 0.96, 0.14)

static func get_rubber_conduit_mat() -> StandardMaterial3D:
	return _get_or_create_pbr("cable_rubber", COL_CABLE_RUBBER, 0.00, 0.95)

static func get_copper_coil_mat() -> StandardMaterial3D:
	return _get_or_create_pbr("industrial_copper", COL_INDUSTRIAL_COPPER, 0.88, 0.28)

# ==============================================================================
# FÁBRICAS DE EMISIVOS Y SHADERS
# ==============================================================================

static func make_emissive_mat(
	color: Color,
	energy: float = 2.2,
	albedo_tint: Color = Color(-1.0, -1.0, -1.0, 1.0),
	metallic: float = 0.15,
	roughness: float = 0.22,
	alpha: float = 1.0
) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var base_albedo := color if albedo_tint.r < 0.0 else albedo_tint
	base_albedo.a = clampf(alpha, 0.0, 1.0)
	mat.albedo_color = base_albedo
	mat.metallic = metallic
	mat.roughness = roughness
	if alpha < 0.999:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b, 1.0)
	mat.emission_energy_multiplier = energy
	return mat

static func create_hazard_stripes_material(
	color_a: Color = COL_HAZARD_YELLOW,
	color_b: Color = COL_CARBON_STEEL,
	freq: float = 8.0,
	uv_scale: Vector2 = Vector2.ONE,
	angle_deg: float = 45.0
) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_HAZARD_STRIPES
	mat.set_shader_parameter("color_a", color_a)
	mat.set_shader_parameter("color_b", color_b)
	mat.set_shader_parameter("stripe_frequency", freq)
	mat.set_shader_parameter("uv_scale", uv_scale)
	mat.set_shader_parameter("stripe_angle_deg", angle_deg)
	return mat

static func create_hologram_material(
	holo_color: Color = COL_CYAN_ELECTRIC,
	rim_color: Color = Color(0.75, 0.98, 1.0, 1.0),
	energy: float = 2.2,
	scan_freq: float = 34.0,
	scan_speed: float = 2.5
) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_HOLOGRAM_CORE
	mat.set_shader_parameter("holo_color", holo_color)
	mat.set_shader_parameter("rim_color", rim_color)
	mat.set_shader_parameter("energy", energy)
	mat.set_shader_parameter("scanline_frequency", scan_freq)
	mat.set_shader_parameter("scanline_speed", scan_speed)
	return mat

static func create_beam_material(
	beam_color: Color = COL_CRIMSON_ALERT,
	core_color: Color = Color(1.0, 0.80, 0.74, 1.0),
	energy: float = 2.6,
	alpha_mult: float = 0.70
) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_BEACON_BEAM
	mat.set_shader_parameter("beam_color", beam_color)
	mat.set_shader_parameter("core_color", core_color)
	mat.set_shader_parameter("energy", energy)
	mat.set_shader_parameter("alpha_multiplier", alpha_mult)
	return mat

# ==============================================================================
# ANILLOS DE SUELO TÁCTICOS Y ONDAS DE CHOQUE
# ==============================================================================

static func create_hazard_ground_ring(
	radio: float,
	color_base: Color = COL_HAZARD_YELLOW,
	color_activo: Color = COL_CYAN_ELECTRIC,
	inner_ratio: float = 0.80,
	outer_ratio: float = 0.96,
	track_alpha: float = 0.35,
	inner_fill_alpha: float = 0.0
) -> MeshInstance3D:
	var safe_outer := clampf(outer_ratio, 0.1, 0.98)
	var safe_inner := clampf(inner_ratio, 0.02, safe_outer - 0.02)
	var half_extent := maxf(radio, 0.1) / safe_outer

	var plane := PlaneMesh.new()
	plane.size = Vector2(half_extent * 2.0, half_extent * 2.0)

	var mat := ShaderMaterial.new()
	mat.shader = SHADER_HAZARD_RING
	mat.set_shader_parameter("inner_radius", safe_inner)
	mat.set_shader_parameter("outer_radius", safe_outer)
	mat.set_shader_parameter("base_color", color_base)
	mat.set_shader_parameter("active_color", color_activo)
	mat.set_shader_parameter("track_alpha", track_alpha)
	mat.set_shader_parameter("inner_fill_alpha", inner_fill_alpha)
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("active_state", 0.0)

	var ring := MeshInstance3D.new()
	ring.name = "GroundContainmentRing"
	ring.mesh = plane
	ring.material_override = mat
	ring.position = Vector3(0.0, 0.025, 0.0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ring

static func spawn_shockwave_ring(
	parent: Node,
	pos: Vector3,
	radio_inicio: float,
	radio_fin: float,
	color: Color = COL_CYAN_ELECTRIC,
	duracion: float = 0.45
) -> MeshInstance3D:
	if parent == null or not is_instance_valid(parent) or not parent.is_inside_tree():
		return null

	var plane := PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)

	var mat := ShaderMaterial.new()
	mat.shader = SHADER_HAZARD_RING
	mat.set_shader_parameter("inner_radius", 0.72)
	mat.set_shader_parameter("outer_radius", 0.94)
	mat.set_shader_parameter("edge_softness", 0.06)
	mat.set_shader_parameter("progress", 1.0)
	mat.set_shader_parameter("active_state", 1.0)
	mat.set_shader_parameter("segment_duty_cycle", 1.0)
	mat.set_shader_parameter("rotation_speed", 0.0)
	mat.set_shader_parameter("pulse_intensity", 0.0)
	mat.set_shader_parameter("base_color", color)
	mat.set_shader_parameter("active_color", color)
	mat.set_shader_parameter("track_alpha", 0.85)
	mat.set_shader_parameter("emission_strength", 2.4)
	mat.set_shader_parameter("overall_alpha", 0.92)

	var ring := MeshInstance3D.new()
	ring.name = "ShockwaveRing"
	ring.mesh = plane
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	parent.add_child(ring)
	var floor_y := pos.y + 0.035 if absf(pos.y) < 0.02 else pos.y
	ring.global_position = Vector3(pos.x, floor_y, pos.z)
	var start_r := maxf(radio_inicio, 0.05)
	var end_r := maxf(radio_fin, start_r + 0.1)
	ring.scale = Vector3(start_r, 1.0, start_r)

	var safe_dur := maxf(duracion, 0.05)
	var tw := ring.create_tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(end_r, 1.0, end_r), safe_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(
		func(a: float):
			if is_instance_valid(mat):
				mat.set_shader_parameter("overall_alpha", a),
		0.92,
		0.0,
		safe_dur
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.finished.connect(func():
		if is_instance_valid(ring):
			ring.queue_free()
	)
	return ring

# ==============================================================================
# OVERRIDES DE JERARQUÍAS .GLB POR INSTANCIA
# ==============================================================================

static func override_glb_hierarchy(root: Node, overrides: Dictionary, duplicate_materials: bool = true) -> Dictionary:
	var applied: Dictionary = {}
	if root == null or not is_instance_valid(root):
		return applied

	var meshes := _collect_mesh_instances(root)
	for mi in meshes:
		var matched_mat: Material = _resolve_override_material(mi.name, overrides)
		if matched_mat != null:
			var final_mat: Material = matched_mat.duplicate() if duplicate_materials else matched_mat
			mi.material_override = final_mat
			applied[mi.name] = final_mat
	return applied

static func set_glb_node_material(
	root: Node,
	exact_or_prefix: String,
	mat: Material,
	duplicate_mat: bool = true
) -> Array[MeshInstance3D]:
	var matched: Array[MeshInstance3D] = []
	if root == null or not is_instance_valid(root) or exact_or_prefix.is_empty():
		return matched

	var meshes := _collect_mesh_instances(root)
	if exact_or_prefix.contains("*"):
		for mi in meshes:
			if mi.name.match(exact_or_prefix):
				matched.append(mi)
	else:
		for mi in meshes:
			if mi.name == exact_or_prefix:
				matched.append(mi)
		if matched.is_empty():
			for mi in meshes:
				if mi.name.begins_with(exact_or_prefix):
					matched.append(mi)

	for i in range(matched.size()):
		var mi := matched[i]
		mi.material_override = mat.duplicate() if duplicate_mat else mat
	return matched

static func _collect_mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		if curr is MeshInstance3D:
			result.append(curr as MeshInstance3D)
		for child in curr.get_children():
			stack.append(child)
	return result

static func _resolve_override_material(node_name: String, overrides: Dictionary) -> Material:
	if overrides.has(node_name):
		return overrides[node_name] as Material

	var best_key := ""
	var best_score := -1
	for raw_key in overrides.keys():
		var key := str(raw_key)
		if key.contains("*") and node_name.match(key):
			var score := key.replace("*", "").length()
			if score > best_score:
				best_score = score
				best_key = key
		elif key.ends_with("_") and node_name.begins_with(key):
			var score := key.length()
			if score > best_score:
				best_score = score
				best_key = key

	if best_key != "":
		return overrides[best_key] as Material
	return null

# ==============================================================================
# ESTILO TÁCTICO Y HELPERS GEOMÉTRICOS
# ==============================================================================

static func apply_tactical_label_style(
	label: Label3D,
	font_size: int = 34,
	color_texto: Color = Color(0.92, 0.96, 1.0, 1.0)
) -> void:
	if label == null:
		return
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = font_size
	label.modulate = color_texto
	label.outline_size = 10
	label.outline_modulate = Color(0.03, 0.04, 0.06, 0.96)
	label.pixel_size = 0.0055
	label.shaded = false

static func make_cylinder(
	parent: Node,
	node_name: String,
	top_r: float,
	bottom_r: float,
	height: float,
	mat: Material = null,
	pos: Vector3 = Vector3.ZERO,
	radial_segments: int = 16,
	cap_top: bool = true,
	cap_bottom: bool = true
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height
	mesh.radial_segments = radial_segments
	mesh.cap_top = cap_top
	mesh.cap_bottom = cap_bottom

	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = pos
	if mat != null:
		mi.material_override = mat
	if parent != null:
		parent.add_child(mi)
	return mi

static func make_box(
	parent: Node,
	node_name: String,
	size: Vector3,
	mat: Material = null,
	pos: Vector3 = Vector3.ZERO,
	rot_deg: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size

	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot_deg
	if mat != null:
		mi.material_override = mat
	if parent != null:
		parent.add_child(mi)
	return mi

static func make_torus(
	parent: Node,
	node_name: String,
	inner_r: float,
	outer_r: float,
	mat: Material = null,
	pos: Vector3 = Vector3.ZERO,
	rot_deg: Vector3 = Vector3.ZERO,
	rings: int = 32,
	ring_segments: int = 12
) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_r
	mesh.outer_radius = outer_r
	mesh.rings = rings
	mesh.ring_segments = ring_segments

	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot_deg
	if mat != null:
		mi.material_override = mat
	if parent != null:
		parent.add_child(mi)
	return mi
