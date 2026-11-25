extends RefCounted
class_name VfxCombate

## VfxCombate — Sistema Centralizado de Efectos Visuales de Combate (Godot 4.7.2 GL Compatibility)
## Provee mallas cacheadas estáticamente, materiales shader aditivos HDR y control estricto
## de concurrencia para tajos, explosiones, rayos, áreas de peligro y proyectiles estilizados.

const ArenaColiseo = preload("res://arena_coliseo.gd")
const BunkerVisualKit = preload("res://bunker_visual_kit.gd")

const SHADER_SLASH_ARC := preload("res://shaders/vfx_slash_arc.gdshader")
const SHADER_ENERGY_BEAM := preload("res://shaders/vfx_energy_beam.gdshader")
const SHADER_IMPACT_NOVA := preload("res://shaders/vfx_impact_nova.gdshader")
const SHADER_GROUND_HAZARD := preload("res://shaders/vfx_ground_hazard.gdshader")
const SHADER_PROJECTILE_PLASMA := preload("res://shaders/vfx_projectile_plasma.gdshader")

const MAX_VFX_CONCURRENTES: int = 56
const UMBRAL_VFX_SECUNDARIOS: int = 42
const MAX_POOL_IMPACTOS: int = 32

static var _vfx_activos: int = 0
static var _mallas_init: bool = false
static var _pool_impactos: Array[MeshInstance3D] = []
static var _cache_proj_sheath: Dictionary = {}
static var _cache_proj_tail: Dictionary = {}
static var _cache_proj_core: Dictionary = {}
static var _cache_proj_arc: Dictionary = {}

static var _mesh_slash_arc: ArrayMesh = null
static var _mesh_whirlwind_ring: ArrayMesh = null
static var _mesh_spark_burst: ArrayMesh = null
static var _mesh_beam_cyl: CylinderMesh = null
static var _mesh_nova_sphere: SphereMesh = null
static var _mesh_plane_unit: PlaneMesh = null
static var _mesh_arrow_rain: CylinderMesh = null

static var _mesh_bolt_core: CylinderMesh = null
static var _mesh_bolt_sheath: CylinderMesh = null
static var _mesh_bolt_tail: CylinderMesh = null
static var _mesh_dagger_blade: BoxMesh = null
static var _mesh_orb_core: SphereMesh = null
static var _mesh_orb_shell: SphereMesh = null
static var _mesh_orb_ring: TorusMesh = null
static var _mesh_guadana_blade: ArrayMesh = null

# ==============================================================================
# CACHÉ DE MALLAS Y GESTIÓN DE CONCURRENCIA
# ==============================================================================

static func _asegurar_mallas() -> void:
	if _mallas_init:
		return
	_mallas_init = true

	_mesh_slash_arc = _construir_malla_arco(155.0, 0.46, 1.0, 18, 0.08)
	_mesh_whirlwind_ring = _construir_malla_arco(360.0, 0.36, 1.0, 32, 0.04)
	_mesh_guadana_blade = _construir_malla_arco(125.0, 0.56, 1.0, 14, 0.05)
	_mesh_spark_burst = _construir_malla_chispas()

	_mesh_beam_cyl = CylinderMesh.new()
	_mesh_beam_cyl.top_radius = 1.0
	_mesh_beam_cyl.bottom_radius = 1.0
	_mesh_beam_cyl.height = 1.0
	_mesh_beam_cyl.radial_segments = 10
	_mesh_beam_cyl.rings = 1
	_mesh_beam_cyl.cap_top = false
	_mesh_beam_cyl.cap_bottom = false

	_mesh_nova_sphere = SphereMesh.new()
	_mesh_nova_sphere.radius = 1.0
	_mesh_nova_sphere.height = 2.0
	_mesh_nova_sphere.radial_segments = 18
	_mesh_nova_sphere.rings = 10

	_mesh_plane_unit = PlaneMesh.new()
	_mesh_plane_unit.size = Vector2(2.0, 2.0)

	_mesh_arrow_rain = CylinderMesh.new()
	_mesh_arrow_rain.top_radius = 0.015
	_mesh_arrow_rain.bottom_radius = 0.065
	_mesh_arrow_rain.height = 1.45
	_mesh_arrow_rain.radial_segments = 6

	_mesh_bolt_core = CylinderMesh.new()
	_mesh_bolt_core.top_radius = 0.015
	_mesh_bolt_core.bottom_radius = 0.068
	_mesh_bolt_core.height = 0.92
	_mesh_bolt_core.radial_segments = 8

	_mesh_bolt_sheath = CylinderMesh.new()
	_mesh_bolt_sheath.top_radius = 0.06
	_mesh_bolt_sheath.bottom_radius = 0.14
	_mesh_bolt_sheath.height = 0.96
	_mesh_bolt_sheath.radial_segments = 8
	_mesh_bolt_sheath.cap_top = false
	_mesh_bolt_sheath.cap_bottom = false

	_mesh_bolt_tail = CylinderMesh.new()
	_mesh_bolt_tail.top_radius = 0.13
	_mesh_bolt_tail.bottom_radius = 0.01
	_mesh_bolt_tail.height = 1.45
	_mesh_bolt_tail.radial_segments = 8
	_mesh_bolt_tail.cap_top = false
	_mesh_bolt_tail.cap_bottom = false

	_mesh_dagger_blade = BoxMesh.new()
	_mesh_dagger_blade.size = Vector3(0.11, 0.035, 0.86)

	_mesh_orb_core = SphereMesh.new()
	_mesh_orb_core.radius = 0.24
	_mesh_orb_core.height = 0.48
	_mesh_orb_core.radial_segments = 14
	_mesh_orb_core.rings = 8

	_mesh_orb_shell = SphereMesh.new()
	_mesh_orb_shell.radius = 0.37
	_mesh_orb_shell.height = 0.74
	_mesh_orb_shell.radial_segments = 16
	_mesh_orb_shell.rings = 10

	_mesh_orb_ring = TorusMesh.new()
	_mesh_orb_ring.inner_radius = 0.39
	_mesh_orb_ring.outer_radius = 0.44
	_mesh_orb_ring.rings = 20
	_mesh_orb_ring.ring_segments = 6

static func _construir_malla_arco(ang_total_deg: float, r_in: float, r_out: float, segs: int, elev_out: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ang_rad := deg_to_rad(ang_total_deg)
	var ang_ini := -ang_rad * 0.5
	for i in range(segs):
		var t0 := float(i) / float(segs)
		var t1 := float(i + 1) / float(segs)
		var a0 := ang_ini + t0 * ang_rad
		var a1 := ang_ini + t1 * ang_rad

		var p_in0 := Vector3(sin(a0) * r_in, 0.0, -cos(a0) * r_in)
		var p_out0 := Vector3(sin(a0) * r_out, elev_out, -cos(a0) * r_out)
		var p_in1 := Vector3(sin(a1) * r_in, 0.0, -cos(a1) * r_in)
		var p_out1 := Vector3(sin(a1) * r_out, elev_out, -cos(a1) * r_out)

		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(t0, 0.0))
		st.add_vertex(p_in0)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(t0, 1.0))
		st.add_vertex(p_out0)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(t1, 1.0))
		st.add_vertex(p_out1)

		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(t0, 0.0))
		st.add_vertex(p_in0)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(t1, 1.0))
		st.add_vertex(p_out1)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(t1, 0.0))
		st.add_vertex(p_in1)
	return st.commit()

static func _construir_malla_chispas() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dir_datos: Array = [
		[0.0, 18.0, 1.00],
		[52.0, 38.0, 0.88],
		[104.0, 14.0, 1.05],
		[156.0, 48.0, 0.84],
		[208.0, 22.0, 0.98],
		[260.0, 54.0, 0.80],
		[312.0, 28.0, 0.94],
	]
	for item in dir_datos:
		var az := deg_to_rad(float(item[0]))
		var el := deg_to_rad(float(item[1]))
		var largo := float(item[2])
		var d := Vector3(cos(el) * cos(az), sin(el), cos(el) * sin(az)).normalized()
		var up_ref := Vector3.UP if absf(d.y) < 0.95 else Vector3.FORWARD
		var s := d.cross(up_ref).normalized() * 0.11
		var u := s.cross(d).normalized() * 0.11

		var base_p := d * 0.14
		var mid_p := d * (largo * 0.36)
		var tip_p := d * largo

		var pts := [mid_p + s, mid_p + u, mid_p - s, mid_p - u]
		for k in range(4):
			var p_a: Vector3 = pts[k]
			var p_b: Vector3 = pts[(k + 1) % 4]
			var n_front := (tip_p - p_a).cross(p_b - p_a).normalized()
			st.set_normal(n_front)
			st.set_uv(Vector2(0.5, 1.0))
			st.add_vertex(tip_p)
			st.set_normal(n_front)
			st.set_uv(Vector2(0.0, 0.4))
			st.add_vertex(p_a)
			st.set_normal(n_front)
			st.set_uv(Vector2(1.0, 0.4))
			st.add_vertex(p_b)

			var n_back := (base_p - p_b).cross(p_a - p_b).normalized()
			st.set_normal(n_back)
			st.set_uv(Vector2(0.5, 0.0))
			st.add_vertex(base_p)
			st.set_normal(n_back)
			st.set_uv(Vector2(1.0, 0.4))
			st.add_vertex(p_b)
			st.set_normal(n_back)
			st.set_uv(Vector2(0.0, 0.4))
			st.add_vertex(p_a)
	return st.commit()

static func _parent_valido(parent: Node) -> bool:
	return parent != null and is_instance_valid(parent) and parent.is_inside_tree()

static func _puede_spawnear_secundario() -> bool:
	return _vfx_activos < UMBRAL_VFX_SECUNDARIOS

static func _puede_spawnear_principal() -> bool:
	return _vfx_activos < MAX_VFX_CONCURRENTES

static func _registrar_vfx(nodo: Node) -> void:
	_vfx_activos += 1
	if not nodo.tree_exited.is_connected(_al_salir_vfx):
		nodo.tree_exited.connect(_al_salir_vfx)

static func _desregistrar_vfx(nodo: Node) -> void:
	if nodo != null and is_instance_valid(nodo) and nodo.tree_exited.is_connected(_al_salir_vfx):
		nodo.tree_exited.disconnect(_al_salir_vfx)
		_vfx_activos = maxi(0, _vfx_activos - 1)

static func _al_salir_vfx() -> void:
	_vfx_activos = maxi(0, _vfx_activos - 1)

static func _altura_piso(parent: Node, pos: Vector3, offset: float = 0.04) -> float:
	if parent != null and is_instance_valid(parent) and parent.is_inside_tree() and parent.get_tree() != null:
		var arena := parent.get_tree().get_first_node_in_group("arena_coliseo")
		if arena != null and arena.has_method("altura_suelo_en"):
			return float(arena.call("altura_suelo_en", pos.x, pos.z)) + offset
	return ArenaColiseo.obtener_altura_suelo(pos.x, pos.z) + offset

static func _orientar_cilindro_entre(mi: Node3D, pos_a: Vector3, pos_b: Vector3, radio: float) -> void:
	var vec := pos_b - pos_a
	var dist := vec.length()
	if dist < 0.01:
		dist = 0.01
	var dir := vec.normalized() if vec.length_squared() > 0.0001 else Vector3.UP
	var up_ref := Vector3.UP if absf(dir.y) < 0.99 else Vector3.FORWARD
	var right := dir.cross(up_ref).normalized()
	var fwd := right.cross(dir).normalized()
	mi.global_position = (pos_a + pos_b) * 0.5
	mi.global_transform.basis = Basis(right * radio, dir * dist, fwd * radio)

# ==============================================================================
# TAJOS, TORBELLINOS Y EXPLOSIONES NOVA
# ==============================================================================

static func spawn_tajo(
	parent: Node,
	origen: Vector3,
	dir: Vector3,
	radio: float = 2.6,
	color_main: Color = Color(0.20, 0.90, 1.00),
	color_core: Color = Color(0.98, 0.99, 1.00),
	color_edge: Color = Color(0.08, 0.42, 0.95),
	invertir: bool = false,
	duracion: float = 0.20,
	tilt_deg: float = 14.0
) -> Node3D:
	if not _parent_valido(parent) or not _puede_spawnear_principal():
		return null
	_asegurar_mallas()

	var holder := Node3D.new()
	holder.name = "VfxTajo"
	parent.add_child(holder)
	_registrar_vfx(holder)

	holder.global_position = origen
	var dir_plana := Vector3(dir.x, 0.0, dir.z)
	if dir_plana.length_squared() > 0.001:
		dir_plana = dir_plana.normalized()
		holder.look_at(origen + dir_plana, Vector3.UP)
	holder.rotate_object_local(Vector3.FORWARD, deg_to_rad(-tilt_deg if invertir else tilt_deg))

	var mat := ShaderMaterial.new()
	mat.shader = SHADER_SLASH_ARC
	mat.set_shader_parameter("main_color", color_main)
	mat.set_shader_parameter("core_color", color_core)
	mat.set_shader_parameter("edge_color", color_edge)
	mat.set_shader_parameter("progress", 0.0)
	mat.set_shader_parameter("energy", 3.4)
	mat.set_shader_parameter("alpha_mult", 1.0)
	mat.set_shader_parameter("sweep_mode", 0.0)
	mat.set_shader_parameter("flip_dir", -1.0 if invertir else 1.0)

	var arco := MeshInstance3D.new()
	arco.mesh = _mesh_slash_arc
	arco.material_override = mat
	arco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var r_s := maxf(radio, 0.8)
	arco.scale = Vector3(r_s * 0.86, 1.0, r_s * 0.86)
	holder.add_child(arco)

	var safe_dur := maxf(duracion, 0.08)
	var yaw_ini := deg_to_rad(18.0 if invertir else -18.0)
	var yaw_fin := deg_to_rad(-16.0 if invertir else 16.0)
	arco.rotation.y = yaw_ini

	var tw := holder.create_tween().set_parallel(true)
	tw.tween_method(
		func(p: float):
			if is_instance_valid(mat):
				mat.set_shader_parameter("progress", p),
		0.0,
		1.0,
		safe_dur
	)
	tw.tween_property(arco, "scale", Vector3(r_s * 1.12, 1.0, r_s * 1.12), safe_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(arco, "rotation:y", yaw_fin, safe_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(func():
		if is_instance_valid(holder):
			holder.queue_free()
	)
	return holder

static func spawn_torbellino(
	parent: Node,
	pos: Vector3,
	radio: float = 3.2,
	color_main: Color = Color(1.00, 0.68, 0.16),
	color_core: Color = Color(1.00, 0.96, 0.78),
	color_edge: Color = Color(0.95, 0.28, 0.08),
	duracion: float = 0.28
) -> Node3D:
	if not _parent_valido(parent) or not _puede_spawnear_principal():
		return null
	_asegurar_mallas()

	var holder := Node3D.new()
	holder.name = "VfxTorbellino"
	parent.add_child(holder)
	_registrar_vfx(holder)
	holder.global_position = pos

	var r_eff := maxf(radio, 0.8)
	var mat1 := ShaderMaterial.new()
	mat1.shader = SHADER_SLASH_ARC
	mat1.set_shader_parameter("main_color", color_main)
	mat1.set_shader_parameter("core_color", color_core)
	mat1.set_shader_parameter("edge_color", color_edge)
	mat1.set_shader_parameter("progress", 0.0)
	mat1.set_shader_parameter("energy", 3.2)
	mat1.set_shader_parameter("sweep_mode", 1.0)
	mat1.set_shader_parameter("flip_dir", 1.0)
	mat1.set_shader_parameter("streaks", 14.0)

	var mat2 := ShaderMaterial.new()
	mat2.shader = SHADER_SLASH_ARC
	mat2.set_shader_parameter("main_color", color_edge)
	mat2.set_shader_parameter("core_color", color_core)
	mat2.set_shader_parameter("edge_color", color_main)
	mat2.set_shader_parameter("progress", 0.0)
	mat2.set_shader_parameter("energy", 2.8)
	mat2.set_shader_parameter("sweep_mode", 1.0)
	mat2.set_shader_parameter("flip_dir", -1.0)
	mat2.set_shader_parameter("streaks", 10.0)

	var disco1 := MeshInstance3D.new()
	disco1.mesh = _mesh_whirlwind_ring
	disco1.material_override = mat1
	disco1.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disco1.rotation_degrees = Vector3(6.0, 0.0, 8.0)
	disco1.scale = Vector3(r_eff * 0.45, 1.0, r_eff * 0.45)
	holder.add_child(disco1)

	var disco2 := MeshInstance3D.new()
	disco2.mesh = _mesh_whirlwind_ring
	disco2.material_override = mat2
	disco2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disco2.position = Vector3(0.0, 0.14, 0.0)
	disco2.rotation_degrees = Vector3(-7.0, 120.0, -8.0)
	disco2.scale = Vector3(r_eff * 0.35, 1.0, r_eff * 0.35)
	holder.add_child(disco2)

	var safe_dur := maxf(duracion, 0.10)
	var tw := holder.create_tween().set_parallel(true)
	tw.tween_method(
		func(p: float):
			if is_instance_valid(mat1):
				mat1.set_shader_parameter("progress", p)
			if is_instance_valid(mat2):
				mat2.set_shader_parameter("progress", p),
		0.0,
		1.0,
		safe_dur
	)
	tw.tween_property(disco1, "scale", Vector3(r_eff * 1.12, 1.0, r_eff * 1.12), safe_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(disco2, "scale", Vector3(r_eff * 0.96, 1.0, r_eff * 0.96), safe_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(disco1, "rotation:y", TAU * 0.9, safe_dur)
	tw.tween_property(disco2, "rotation:y", -TAU * 0.75, safe_dur)
	tw.chain().tween_callback(func():
		if is_instance_valid(holder):
			holder.queue_free()
	)

	BunkerVisualKit.spawn_shockwave_ring(parent, pos, r_eff * 0.25, r_eff * 1.10, color_main, safe_dur * 0.95)
	return holder

static func spawn_explosion_nova(
	parent: Node,
	pos: Vector3,
	radio: float = 3.2,
	color_main: Color = Color(0.65, 0.25, 1.0),
	color_core: Color = Color(1.00, 0.96, 0.98),
	duracion: float = 0.34,
	con_chispas: bool = true,
	con_anillo_suelo: bool = true
) -> Node3D:
	if not _parent_valido(parent) or not _puede_spawnear_principal():
		return null
	_asegurar_mallas()

	var holder := Node3D.new()
	holder.name = "VfxExplosionNova"
	parent.add_child(holder)
	_registrar_vfx(holder)
	holder.global_position = pos

	var r_eff := maxf(radio, 0.4)
	var mat_dome := ShaderMaterial.new()
	mat_dome.shader = SHADER_IMPACT_NOVA
	mat_dome.set_shader_parameter("main_color", color_main)
	mat_dome.set_shader_parameter("core_color", color_core)
	mat_dome.set_shader_parameter("progress", 0.0)
	mat_dome.set_shader_parameter("energy", 3.4)
	mat_dome.set_shader_parameter("fresnel_power", 2.0)

	var esfera := MeshInstance3D.new()
	esfera.mesh = _mesh_nova_sphere
	esfera.material_override = mat_dome
	esfera.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	esfera.scale = Vector3.ONE * (r_eff * 0.24)
	holder.add_child(esfera)

	var mat_sparks: ShaderMaterial = null
	var sparks: MeshInstance3D = null
	if con_chispas:
		mat_sparks = ShaderMaterial.new()
		mat_sparks.shader = SHADER_PROJECTILE_PLASMA
		mat_sparks.set_shader_parameter("main_color", color_main)
		mat_sparks.set_shader_parameter("core_color", color_core)
		mat_sparks.set_shader_parameter("energy", 3.2)
		mat_sparks.set_shader_parameter("alpha_mult", 1.0)
		mat_sparks.set_shader_parameter("is_tail", 0.0)
		sparks = MeshInstance3D.new()
		sparks.mesh = _mesh_spark_burst
		sparks.material_override = mat_sparks
		sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sparks.rotation.y = randf() * TAU
		sparks.scale = Vector3.ONE * (r_eff * 0.35)
		holder.add_child(sparks)

	var safe_dur := maxf(duracion, 0.12)
	var tw := holder.create_tween().set_parallel(true)
	tw.tween_property(esfera, "scale", Vector3.ONE * (r_eff * 0.96), safe_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(
		func(p: float):
			if is_instance_valid(mat_dome):
				mat_dome.set_shader_parameter("progress", p),
		0.0,
		1.0,
		safe_dur
	)
	if sparks != null and mat_sparks != null:
		tw.tween_property(sparks, "scale", Vector3.ONE * (r_eff * 1.18), safe_dur * 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_method(
			func(a: float):
				if is_instance_valid(mat_sparks):
					mat_sparks.set_shader_parameter("alpha_mult", a),
			1.0,
			0.0,
			safe_dur * 0.85
		)
	tw.chain().tween_callback(func():
		if is_instance_valid(holder):
			holder.queue_free()
	)

	if con_anillo_suelo:
		BunkerVisualKit.spawn_shockwave_ring(parent, pos, r_eff * 0.18, r_eff * 1.05, color_main, safe_dur)
	return holder

static func spawn_pulso_implosion(
	parent: Node,
	pos: Vector3,
	radio: float = 7.5,
	color_main: Color = Color(0.68, 0.22, 0.98),
	color_core: Color = Color(0.95, 0.82, 1.00),
	duracion: float = 0.36
) -> Node3D:
	if not _parent_valido(parent) or not _puede_spawnear_principal():
		return null
	_asegurar_mallas()

	var holder := Node3D.new()
	holder.name = "VfxImplosion"
	parent.add_child(holder)
	_registrar_vfx(holder)

	var y_suelo := _altura_piso(parent, pos, 0.04)
	holder.global_position = Vector3(pos.x, y_suelo, pos.z)
	var r_eff := maxf(radio, 1.0)

	var mat_ring := ShaderMaterial.new()
	mat_ring.shader = SHADER_GROUND_HAZARD
	mat_ring.set_shader_parameter("color_primary", color_main)
	mat_ring.set_shader_parameter("color_secondary", color_main.darkened(0.5))
	mat_ring.set_shader_parameter("color_core", color_core)
	mat_ring.set_shader_parameter("mode", 0.0)
	mat_ring.set_shader_parameter("energy", 3.0)
	mat_ring.set_shader_parameter("alpha_mult", 0.95)
	mat_ring.set_shader_parameter("spin_speed", 3.8)

	var plano := MeshInstance3D.new()
	plano.mesh = _mesh_plane_unit
	plano.material_override = mat_ring
	plano.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plano.scale = Vector3(r_eff, 1.0, r_eff)
	holder.add_child(plano)

	var mat_core := ShaderMaterial.new()
	mat_core.shader = SHADER_IMPACT_NOVA
	mat_core.set_shader_parameter("main_color", color_main)
	mat_core.set_shader_parameter("core_color", color_core)
	mat_core.set_shader_parameter("progress", 0.1)
	mat_core.set_shader_parameter("energy", 3.6)

	var core := MeshInstance3D.new()
	core.mesh = _mesh_nova_sphere
	core.material_override = mat_core
	core.position = Vector3(0.0, 0.75, 0.0)
	core.scale = Vector3.ONE * 0.25
	holder.add_child(core)

	var safe_dur := maxf(duracion, 0.14)
	var tw := holder.create_tween().set_parallel(true)
	tw.tween_property(plano, "scale", Vector3(0.35, 1.0, 0.35), safe_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(plano, "rotation:y", PI * 1.4, safe_dur)
	tw.tween_property(core, "scale", Vector3.ONE * 1.25, safe_dur * 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(
		func(a: float):
			if is_instance_valid(mat_ring):
				mat_ring.set_shader_parameter("alpha_mult", a)
			if is_instance_valid(mat_core):
				mat_core.set_shader_parameter("progress", 1.0 - a * 0.9),
		0.95,
		0.0,
		safe_dur
	)
	tw.chain().tween_callback(func():
		if is_instance_valid(holder):
			holder.queue_free()
	)
	return holder

# ==============================================================================
# HACES ENERGÉTICOS, RIEL ASTRAL Y RAYOS SEGMENTADOS
# ==============================================================================

static func spawn_riel_laser(
	parent: Node,
	origen: Vector3,
	dir: Vector3,
	largo: float = 13.0,
	color_main: Color = Color(0.22, 0.92, 1.00),
	color_core: Color = Color(1.00, 0.99, 1.00),
	duracion: float = 0.28
) -> Node3D:
	if not _parent_valido(parent) or not _puede_spawnear_principal():
		return null
	_asegurar_mallas()

	var holder := Node3D.new()
	holder.name = "VfxRielLaser"
	parent.add_child(holder)
	_registrar_vfx(holder)

	var d := Vector3(dir.x, dir.y, dir.z)
	if d.length_squared() < 0.0001:
		d = Vector3.FORWARD
	d = d.normalized()
	var pos_fin := origen + d * maxf(largo, 1.0)

	var mat_in := ShaderMaterial.new()
	mat_in.shader = SHADER_ENERGY_BEAM
	mat_in.set_shader_parameter("beam_color", color_core)
	mat_in.set_shader_parameter("core_color", color_core)
	mat_in.set_shader_parameter("energy", 4.6)
	mat_in.set_shader_parameter("scroll_speed", 8.0)
	mat_in.set_shader_parameter("noise_freq", 10.0)
	mat_in.set_shader_parameter("core_width", 0.50)

	var core_cyl := MeshInstance3D.new()
	core_cyl.mesh = _mesh_beam_cyl
	core_cyl.material_override = mat_in
	core_cyl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(core_cyl)
	_orientar_cilindro_entre(core_cyl, origen, pos_fin, 0.14)

	var mat_out := ShaderMaterial.new()
	mat_out.shader = SHADER_ENERGY_BEAM
	mat_out.set_shader_parameter("beam_color", color_main)
	mat_out.set_shader_parameter("core_color", color_core)
	mat_out.set_shader_parameter("energy", 3.4)
	mat_out.set_shader_parameter("scroll_speed", 6.5)
	mat_out.set_shader_parameter("noise_freq", 14.0)
	mat_out.set_shader_parameter("core_width", 0.25)

	var out_cyl := MeshInstance3D.new()
	out_cyl.mesh = _mesh_beam_cyl
	out_cyl.material_override = mat_out
	out_cyl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(out_cyl)
	_orientar_cilindro_entre(out_cyl, origen, pos_fin, 0.36)

	# 3 anillos sónicos espaciados a lo largo del disparo
	var basis_beam := core_cyl.global_transform.basis.orthonormalized()
	for idx in range(3):
		var anillo := MeshInstance3D.new()
		anillo.mesh = _mesh_orb_ring
		anillo.material_override = mat_out
		anillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(anillo)
		anillo.global_position = origen + d * (1.2 + float(idx) * 3.4)
		anillo.global_transform.basis = basis_beam
		anillo.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		var base_s := 1.15 - float(idx) * 0.15
		anillo.scale = Vector3(base_s, base_s, base_s)

	spawn_destello_disparo(parent, origen, d, color_main, 0.95)

	var safe_dur := maxf(duracion, 0.12)
	var tw := holder.create_tween().set_parallel(true)
	tw.tween_method(
		func(dis: float):
			if is_instance_valid(mat_in):
				mat_in.set_shader_parameter("dissolve", dis)
			if is_instance_valid(mat_out):
				mat_out.set_shader_parameter("dissolve", dis)
			if is_instance_valid(core_cyl):
				_orientar_cilindro_entre(core_cyl, origen, pos_fin, lerpf(0.16, 0.02, dis))
			if is_instance_valid(out_cyl):
				_orientar_cilindro_entre(out_cyl, origen, pos_fin, lerpf(0.40, 0.05, dis)),
		0.0,
		1.0,
		safe_dur
	)
	tw.chain().tween_callback(func():
		if is_instance_valid(holder):
			holder.queue_free()
	)
	return holder

static func spawn_rayo_segmento(
	parent: Node,
	pos_a: Vector3,
	pos_b: Vector3,
	color_main: Color = Color(0.25, 0.90, 1.00),
	color_core: Color = Color(0.98, 0.99, 1.00),
	grosor: float = 0.13,
	duracion: float = 0.18,
	zigzag_amp: float = 0.22
) -> Node3D:
	if not _parent_valido(parent) or not _puede_spawnear_principal():
		return null
	_asegurar_mallas()

	var holder := Node3D.new()
	holder.name = "VfxRayoSegmento"
	parent.add_child(holder)
	_registrar_vfx(holder)

	var mat := ShaderMaterial.new()
	mat.shader = SHADER_ENERGY_BEAM
	mat.set_shader_parameter("beam_color", color_main)
	mat.set_shader_parameter("core_color", color_core)
	mat.set_shader_parameter("energy", 3.8)
	mat.set_shader_parameter("scroll_speed", 7.0)
	mat.set_shader_parameter("noise_freq", 9.0)
	mat.set_shader_parameter("core_width", 0.34)
	mat.set_shader_parameter("end_fade", 0.02)

	var num_segs := 5
	var dif := pos_b - pos_a
	var dist := dif.length()
	var amp := clampf(zigzag_amp * minf(dist * 0.15, 1.4), 0.05, 0.65)
	var dir_n := dif.normalized() if dist > 0.01 else Vector3.FORWARD
	var up_ref := Vector3.UP if absf(dir_n.y) < 0.95 else Vector3.FORWARD
	var perp_a := dir_n.cross(up_ref).normalized()
	var perp_b := dir_n.cross(perp_a).normalized()

	var puntos: Array[Vector3] = [pos_a]
	for i in range(1, num_segs):
		var frac := float(i) / float(num_segs)
		var pt := pos_a.lerp(pos_b, frac)
		pt += perp_a * randf_range(-amp, amp) + perp_b * randf_range(-amp * 0.55, amp * 0.55)
		puntos.append(pt)
	puntos.append(pos_b)

	for i in range(num_segs):
		var seg := MeshInstance3D.new()
		seg.mesh = _mesh_beam_cyl
		seg.material_override = mat
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(seg)
		_orientar_cilindro_entre(seg, puntos[i], puntos[i + 1], grosor)

	if _puede_spawnear_secundario():
		spawn_impacto(parent, pos_b, color_main, color_core, 0.68, false)

	var safe_dur := maxf(duracion, 0.08)
	var tw := holder.create_tween()
	tw.tween_method(
		func(d: float):
			if is_instance_valid(mat):
				mat.set_shader_parameter("dissolve", d),
		0.0,
		1.0,
		safe_dur
	)
	tw.tween_callback(func():
		if is_instance_valid(holder):
			holder.queue_free()
	)
	return holder

static func spawn_rayo_celestial(
	parent: Node,
	pos_objetivo: Vector3,
	color_main: Color = Color(0.28, 0.92, 1.00),
	color_core: Color = Color(1.00, 0.99, 1.00),
	altura: float = 14.0,
	duracion: float = 0.28
) -> Node3D:
	if not _parent_valido(parent) or not _puede_spawnear_principal():
		return null
	var y_suelo := _altura_piso(parent, pos_objetivo, 0.04)
	var base := Vector3(pos_objetivo.x, y_suelo, pos_objetivo.z)
	var cielo := base + Vector3(randf_range(-1.4, 1.4), maxf(altura, 5.0), randf_range(-1.4, 1.4))
	var rayo := spawn_rayo_segmento(parent, cielo, base, color_main, color_core, 0.22, duracion, 0.55)
	BunkerVisualKit.spawn_shockwave_ring(parent, base, 0.25, 2.35, color_main, duracion)
	return rayo

# ==============================================================================
# IMPACTOS RÁPIDOS, DESTELLOS DE DISPARO, COLUMNAS Y LLUVIA DE FLECHAS
# ==============================================================================

static func _obtener_impacto_pool(parent: Node) -> MeshInstance3D:
	while not _pool_impactos.is_empty():
		var raw_cand = _pool_impactos.pop_back()
		if is_instance_valid(raw_cand) and raw_cand is MeshInstance3D:
			var cand := raw_cand as MeshInstance3D
			if not cand.is_queued_for_deletion():
				if cand.get_parent() == parent:
					return cand
				cand.queue_free()
	var holder := MeshInstance3D.new()
	holder.name = "VfxImpacto"
	holder.mesh = _mesh_spark_burst
	holder.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_PROJECTILE_PLASMA
	mat.set_shader_parameter("is_tail", 0.0)
	holder.material_override = mat
	parent.add_child(holder)
	return holder

static func _liberar_impacto_pool(holder: MeshInstance3D) -> void:
	if not is_instance_valid(holder):
		return
	_desregistrar_vfx(holder)
	holder.visible = false
	if holder.has_meta(&"_tw_vfx"):
		var prev_tw = holder.get_meta(&"_tw_vfx")
		if prev_tw is Tween and prev_tw.is_valid():
			prev_tw.kill()
		holder.remove_meta(&"_tw_vfx")
	if holder.is_inside_tree() and _pool_impactos.size() < MAX_POOL_IMPACTOS:
		_pool_impactos.append(holder)
	else:
		holder.queue_free()

static func spawn_impacto(
	parent: Node,
	pos: Vector3,
	color_main: Color = Color(0.35, 0.92, 1.00),
	color_core: Color = Color.WHITE,
	escala: float = 1.0,
	es_critico: bool = false
) -> Node3D:
	if not _parent_valido(parent):
		return null
	if es_critico:
		if not _puede_spawnear_principal():
			return null
	elif not _puede_spawnear_secundario():
		return null
	_asegurar_mallas()

	var holder := _obtener_impacto_pool(parent)
	if holder.has_meta(&"_tw_vfx"):
		var old_tw = holder.get_meta(&"_tw_vfx")
		if old_tw is Tween and old_tw.is_valid():
			old_tw.kill()

	var mat := holder.material_override as ShaderMaterial
	mat.set_shader_parameter("main_color", color_main)
	mat.set_shader_parameter("core_color", color_core)
	mat.set_shader_parameter("energy", 3.6 if es_critico else 2.8)
	mat.set_shader_parameter("alpha_mult", 1.0)

	holder.visible = true
	_registrar_vfx(holder)
	holder.global_position = pos
	holder.rotation = Vector3(randf_range(-0.35, 0.35), randf() * TAU, randf_range(-0.35, 0.35))
	var s_fin := maxf(escala, 0.25) * (1.28 if es_critico else 0.90)
	holder.scale = Vector3.ONE * (s_fin * 0.22)

	var dur := 0.20 if es_critico else 0.14
	var tw := holder.create_tween().set_parallel(true)
	holder.set_meta(&"_tw_vfx", tw)
	tw.tween_property(holder, "scale", Vector3.ONE * s_fin, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_method(
		func(a: float):
			if is_instance_valid(mat):
				mat.set_shader_parameter("alpha_mult", a),
		1.0,
		0.0,
		dur
	)
	tw.chain().tween_callback(_liberar_impacto_pool.bind(holder))

	if es_critico and _puede_spawnear_secundario():
		BunkerVisualKit.spawn_shockwave_ring(parent, pos, 0.15, 1.35 * escala, color_main, 0.20)
	return holder

static func spawn_destello_disparo(
	parent: Node,
	pos: Vector3,
	dir: Vector3,
	color_main: Color = Color(0.25, 0.92, 1.00),
	escala: float = 0.65
) -> Node3D:
	if not _parent_valido(parent) or not _puede_spawnear_secundario():
		return null
	var d := dir.normalized() if dir.length_squared() > 0.001 else Vector3.FORWARD
	return spawn_impacto(parent, pos + d * 0.45, color_main, Color.WHITE, escala, false)

static func spawn_columna_fuego(
	parent: Node,
	pos: Vector3,
	radio: float = 2.4,
	color_main: Color = Color(1.00, 0.48, 0.08),
	color_core: Color = Color(1.00, 0.94, 0.65),
	duracion: float = 0.55
) -> Node3D:
	if not _parent_valido(parent) or not _puede_spawnear_principal():
		return null
	_asegurar_mallas()

	var holder := Node3D.new()
	holder.name = "VfxColumnaFuego"
	parent.add_child(holder)
	_registrar_vfx(holder)

	var y_suelo := _altura_piso(parent, pos, 0.03)
	var base := Vector3(pos.x, y_suelo, pos.z)
	holder.global_position = base

	var mat_col := ShaderMaterial.new()
	mat_col.shader = SHADER_ENERGY_BEAM
	mat_col.set_shader_parameter("beam_color", color_main)
	mat_col.set_shader_parameter("core_color", color_core)
	mat_col.set_shader_parameter("energy", 3.8)
	mat_col.set_shader_parameter("scroll_speed", 7.5)
	mat_col.set_shader_parameter("noise_freq", 8.0)
	mat_col.set_shader_parameter("core_width", 0.35)
	mat_col.set_shader_parameter("end_fade", 0.14)

	var r_eff := clampf(radio * 0.42, 0.45, 2.2)
	var col_mesh := MeshInstance3D.new()
	col_mesh.mesh = _mesh_beam_cyl
	col_mesh.material_override = mat_col
	col_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	col_mesh.position = Vector3(0.0, 2.6, 0.0)
	col_mesh.scale = Vector3(r_eff, 0.2, r_eff)
	holder.add_child(col_mesh)

	var safe_dur := maxf(duracion, 0.18)
	var tw := holder.create_tween().set_parallel(true)
	tw.tween_property(col_mesh, "scale", Vector3(r_eff * 1.15, 6.2, r_eff * 1.15), safe_dur * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(col_mesh, "position:y", 3.1, safe_dur * 0.35)
	tw.tween_method(
		func(d: float):
			if is_instance_valid(mat_col):
				mat_col.set_shader_parameter("dissolve", d),
		0.0,
		1.0,
		safe_dur
	)
	tw.chain().tween_callback(func():
		if is_instance_valid(holder):
			holder.queue_free()
	)

	spawn_explosion_nova(parent, base + Vector3(0.0, 0.25, 0.0), radio, color_main, color_core, safe_dur * 0.8, true, true)
	return holder

static func spawn_lluvia_flechas(
	parent: Node,
	pos_centro: Vector3,
	radio: float = 4.2,
	color_main: Color = Color(1.00, 0.15, 0.45),
	color_core: Color = Color(1.00, 0.85, 0.92),
	cantidad: int = 16
) -> Node3D:
	if not _parent_valido(parent) or not _puede_spawnear_principal():
		return null
	_asegurar_mallas()

	var holder := Node3D.new()
	holder.name = "VfxLluviaFlechas"
	parent.add_child(holder)
	_registrar_vfx(holder)

	var y_suelo := _altura_piso(parent, pos_centro, 0.04)
	var centro := Vector3(pos_centro.x, y_suelo, pos_centro.z)
	holder.global_position = centro

	var mat := ShaderMaterial.new()
	mat.shader = SHADER_PROJECTILE_PLASMA
	mat.set_shader_parameter("main_color", color_main)
	mat.set_shader_parameter("core_color", color_core)
	mat.set_shader_parameter("energy", 3.4)
	mat.set_shader_parameter("alpha_mult", 1.0)
	mat.set_shader_parameter("is_tail", 0.0)

	var n_flechas := clampi(cantidad, 6, 22)
	var r_eff := maxf(radio, 1.5)
	var max_delay := 0.24
	var dur_caida := 0.26

	var tw_master := holder.create_tween().set_parallel(true)
	for i in range(n_flechas):
		var ang := randf() * TAU
		var dist := sqrt(randf()) * (r_eff * 0.88)
		var off := Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		var flecha := MeshInstance3D.new()
		flecha.mesh = _mesh_arrow_rain
		flecha.material_override = mat
		flecha.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flecha.rotation_degrees = Vector3(172.0, randf() * 360.0, randf_range(-6.0, 6.0))
		var start_p := off + Vector3(randf_range(-0.6, 0.6), randf_range(10.5, 14.0), randf_range(-0.6, 0.6))
		var end_p := off + Vector3(0.0, 0.45, 0.0)
		flecha.position = start_p
		holder.add_child(flecha)

		var dly := (float(i) / float(n_flechas)) * max_delay
		tw_master.tween_property(flecha, "position", end_p, dur_caida).set_delay(dly).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_master.tween_property(flecha, "scale", Vector3(0.2, 0.1, 0.2), 0.10).set_delay(dly + dur_caida)

	tw_master.tween_method(
		func(a: float):
			if is_instance_valid(mat):
				mat.set_shader_parameter("alpha_mult", a),
		1.0,
		0.0,
		0.18
	).set_delay(max_delay + dur_caida)
	tw_master.chain().tween_callback(func():
		if is_instance_valid(holder):
			holder.queue_free()
	)

	spawn_explosion_nova(parent, centro + Vector3(0.0, 0.2, 0.0), r_eff * 0.92, color_main, color_core, 0.36, true, true)
	return holder

# ==============================================================================
# ÁREAS DE PELIGRO / VÓRTICES PERSISTENTES EN SUELO
# ==============================================================================

static func crear_zona_suelo_shader(
	parent: Node,
	pos: Vector3,
	radio: float = 2.6,
	modo: int = 0,
	color_a: Color = Color(0.55, 0.15, 0.95),
	color_b: Color = Color(0.18, 0.04, 0.48),
	color_core: Color = Color(0.95, 0.78, 1.00),
	duracion: float = 2.5
) -> Node3D:
	if not _parent_valido(parent):
		return null
	_asegurar_mallas()

	var holder := Node3D.new()
	holder.name = "VfxZonaSuelo_%d" % modo
	parent.add_child(holder)
	_registrar_vfx(holder)

	var clamped := ArenaColiseo.clamping_y_ajustar_a_suelo(pos, 1.5, 0.04)
	holder.global_position = clamped

	var mat := ShaderMaterial.new()
	mat.shader = SHADER_GROUND_HAZARD
	mat.set_shader_parameter("color_primary", color_a)
	mat.set_shader_parameter("color_secondary", color_b)
	mat.set_shader_parameter("color_core", color_core)
	mat.set_shader_parameter("mode", float(clampi(modo, 0, 2)))
	mat.set_shader_parameter("energy", 2.75)
	mat.set_shader_parameter("alpha_mult", 0.0)
	mat.set_shader_parameter("spin_speed", 2.4)

	var plano := MeshInstance3D.new()
	plano.mesh = _mesh_plane_unit
	plano.material_override = mat
	plano.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var r_eff := maxf(radio, 0.5)
	plano.scale = Vector3(r_eff * 0.3, 1.0, r_eff * 0.3)
	holder.add_child(plano)

	# Si es Vórtice del Vacío (modo 0), añadir núcleo oscuro gravitacional
	if modo == 0:
		var nucleo := MeshInstance3D.new()
		nucleo.mesh = _mesh_orb_core
		nucleo.position = Vector3(0.0, 0.32, 0.0)
		nucleo.scale = Vector3.ONE * 0.95
		var mat_negro := StandardMaterial3D.new()
		mat_negro.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat_negro.albedo_color = Color(0.03, 0.01, 0.08, 1.0)
		nucleo.material_override = mat_negro
		holder.add_child(nucleo)

	var safe_dur := maxf(duracion, 0.35)
	var tw := holder.create_tween()
	tw.set_parallel(true)
	tw.tween_property(plano, "scale", Vector3(r_eff, 1.0, r_eff), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(
		func(a: float):
			if is_instance_valid(mat):
				mat.set_shader_parameter("alpha_mult", a),
		0.0,
		0.96,
		0.18
	)
	tw.chain().tween_interval(maxf(0.05, safe_dur - 0.52))
	tw.chain().tween_method(
		func(a: float):
			if is_instance_valid(mat):
				mat.set_shader_parameter("alpha_mult", a),
		0.96,
		0.0,
		0.30
	)
	tw.chain().tween_callback(func():
		if is_instance_valid(holder):
			holder.queue_free()
	)
	return holder

# ==============================================================================
# CONSTRUCCIÓN DE VISUALES ESTILIZADOS PARA PROYECTILES Y ORBES
# ==============================================================================

static func obtener_colores_estilo(estilo: String, es_critico: bool = false) -> Dictionary:
	if es_critico:
		return {
			"main": Color(1.00, 0.82, 0.14),
			"core": Color(1.00, 0.99, 0.85),
			"edge": Color(1.00, 0.48, 0.06),
		}
	match estilo:
		"sombra":
			return {
				"main": Color(0.72, 0.22, 1.00),
				"core": Color(0.95, 0.82, 1.00),
				"edge": Color(0.32, 0.06, 0.65),
			}
		"clic_daga":
			return {
				"main": Color(0.18, 0.94, 1.00),
				"core": Color(1.00, 0.95, 0.55),
				"edge": Color(0.10, 0.50, 1.00),
			}
		"flecha_enemiga":
			return {
				"main": Color(1.00, 0.32, 0.08),
				"core": Color(1.00, 0.88, 0.45),
				"edge": Color(0.85, 0.08, 0.06),
			}
		"guadana":
			return {
				"main": Color(1.00, 0.14, 0.36),
				"core": Color(1.00, 0.72, 0.88),
				"edge": Color(0.55, 0.04, 0.45),
			}
		"sanguinaria":
			return {
				"main": Color(1.00, 0.16, 0.46),
				"core": Color(1.00, 0.86, 0.92),
				"edge": Color(0.68, 0.05, 0.28),
			}
		"orbe_vacio":
			return {
				"main": Color(0.58, 0.14, 1.00),
				"core": Color(0.95, 0.80, 1.00),
				"edge": Color(0.24, 0.04, 0.58),
			}
		"orbe_magma":
			return {
				"main": Color(1.00, 0.44, 0.06),
				"core": Color(1.00, 0.92, 0.42),
				"edge": Color(0.88, 0.12, 0.04),
			}
		"orbe_arcano":
			return {
				"main": Color(0.68, 0.32, 1.00),
				"core": Color(0.45, 0.96, 1.00),
				"edge": Color(0.35, 0.12, 0.88),
			}
		_:
			return {
				"main": Color(0.18, 0.90, 1.00),
				"core": Color(0.95, 0.99, 1.00),
				"edge": Color(0.08, 0.42, 0.95),
			}

static func construir_visual_proyectil(root: Node3D, estilo: String, es_critico: bool = false) -> Node3D:
	if root == null or not is_instance_valid(root):
		return null
	_asegurar_mallas()

	var prev := root.get_node_or_null("VfxProyectilVisual") as Node3D
	if prev != null:
		prev.visible = false
		prev.name = "_VfxOld"
		prev.queue_free()

	var cols := obtener_colores_estilo(estilo, es_critico)
	var col_main: Color = cols["main"]
	var col_core: Color = cols["core"]

	var holder := Node3D.new()
	holder.name = "VfxProyectilVisual"
	root.add_child(holder)

	var cache_key := "%s_%d" % [estilo, int(es_critico)]
	var mat_sheath := _cache_proj_sheath.get(cache_key, null) as ShaderMaterial
	if mat_sheath == null:
		mat_sheath = ShaderMaterial.new()
		mat_sheath.shader = SHADER_PROJECTILE_PLASMA
		mat_sheath.set_shader_parameter("main_color", col_main)
		mat_sheath.set_shader_parameter("core_color", col_core)
		mat_sheath.set_shader_parameter("energy", 3.4 if es_critico else 2.8)
		mat_sheath.set_shader_parameter("alpha_mult", 0.94)
		mat_sheath.set_shader_parameter("is_tail", 0.0)
		_cache_proj_sheath[cache_key] = mat_sheath

	var mat_tail := _cache_proj_tail.get(cache_key, null) as ShaderMaterial
	if mat_tail == null:
		mat_tail = ShaderMaterial.new()
		mat_tail.shader = SHADER_PROJECTILE_PLASMA
		mat_tail.set_shader_parameter("main_color", col_main)
		mat_tail.set_shader_parameter("core_color", col_core)
		mat_tail.set_shader_parameter("energy", 3.0 if es_critico else 2.4)
		mat_tail.set_shader_parameter("alpha_mult", 0.86)
		mat_tail.set_shader_parameter("flow_speed", 8.5)
		mat_tail.set_shader_parameter("is_tail", 1.0)
		_cache_proj_tail[cache_key] = mat_tail

	if estilo.begins_with("orbe"):
		var mat_core := _cache_proj_core.get(cache_key, null) as StandardMaterial3D
		if mat_core == null:
			mat_core = StandardMaterial3D.new()
			mat_core.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat_core.albedo_color = col_core if estilo != "orbe_vacio" else Color(0.04, 0.01, 0.10)
			_cache_proj_core[cache_key] = mat_core
		var m_core := MeshInstance3D.new()
		m_core.name = "NucleoOrbe"
		m_core.mesh = _mesh_orb_core
		m_core.material_override = mat_core
		m_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(m_core)

		var m_shell := MeshInstance3D.new()
		m_shell.name = "EnvolturaPlasma"
		m_shell.mesh = _mesh_orb_shell
		m_shell.material_override = mat_sheath
		m_shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(m_shell)

		var m_ring1 := MeshInstance3D.new()
		m_ring1.name = "AnilloOrbital1"
		m_ring1.mesh = _mesh_orb_ring
		m_ring1.material_override = mat_sheath
		m_ring1.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m_ring1.rotation_degrees = Vector3(28.0, 0.0, 18.0)
		holder.add_child(m_ring1)

		var m_ring2 := MeshInstance3D.new()
		m_ring2.name = "AnilloOrbital2"
		m_ring2.mesh = _mesh_orb_ring
		m_ring2.material_override = mat_sheath
		m_ring2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m_ring2.rotation_degrees = Vector3(-32.0, 60.0, -24.0)
		holder.add_child(m_ring2)

		var m_tail := MeshInstance3D.new()
		m_tail.name = "EstelaOrbe"
		m_tail.mesh = _mesh_bolt_tail
		m_tail.material_override = mat_tail
		m_tail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m_tail.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		m_tail.position = Vector3(0.0, 0.0, 0.72)
		m_tail.scale = Vector3(1.65, 1.15, 1.65)
		holder.add_child(m_tail)
		return holder

	if estilo == "guadana":
		var mat_arc := _cache_proj_arc.get(cache_key, null) as ShaderMaterial
		if mat_arc == null:
			mat_arc = ShaderMaterial.new()
			mat_arc.shader = SHADER_SLASH_ARC
			mat_arc.set_shader_parameter("main_color", col_main)
			mat_arc.set_shader_parameter("core_color", col_core)
			mat_arc.set_shader_parameter("edge_color", Color(0.45, 0.02, 0.35))
			mat_arc.set_shader_parameter("progress", 0.32)
			mat_arc.set_shader_parameter("energy", 3.6)
			mat_arc.set_shader_parameter("sweep_mode", 1.0)
			mat_arc.set_shader_parameter("streaks", 12.0)
			_cache_proj_arc[cache_key] = mat_arc

		var m_arc := MeshInstance3D.new()
		m_arc.name = "HojaGuadana"
		m_arc.mesh = _mesh_guadana_blade
		m_arc.material_override = mat_arc
		m_arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m_arc.scale = Vector3(1.15, 1.0, 1.05)
		holder.add_child(m_arc)

		var m_tail_g := MeshInstance3D.new()
		m_tail_g.mesh = _mesh_bolt_tail
		m_tail_g.material_override = mat_tail
		m_tail_g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m_tail_g.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		m_tail_g.position = Vector3(0.0, 0.0, 0.55)
		holder.add_child(m_tail_g)
		return holder

	# Proyectiles lineales: flechas, dardos sanguinarios, dagas de sombra / clic
	var usar_hoja := (estilo == "sombra" or estilo == "clic_daga")
	var mat_core_p := _cache_proj_core.get(cache_key, null) as StandardMaterial3D
	if mat_core_p == null:
		mat_core_p = StandardMaterial3D.new()
		mat_core_p.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat_core_p.albedo_color = col_core
		_cache_proj_core[cache_key] = mat_core_p

	var m_centro := MeshInstance3D.new()
	m_centro.name = "NucleoProyectil"
	m_centro.mesh = _mesh_dagger_blade if usar_hoja else _mesh_bolt_core
	m_centro.material_override = mat_core_p
	m_centro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not usar_hoja:
		m_centro.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	else:
		m_centro.rotation_degrees = Vector3(0.0, 0.0, 45.0)
	holder.add_child(m_centro)

	var m_funda := MeshInstance3D.new()
	m_funda.name = "EnvolturaProyectil"
	m_funda.mesh = _mesh_bolt_sheath
	m_funda.material_override = mat_sheath
	m_funda.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m_funda.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	if usar_hoja:
		m_funda.scale = Vector3(1.15, 0.95, 0.55)
	holder.add_child(m_funda)

	var m_estela := MeshInstance3D.new()
	m_estela.name = "EstelaProyectil"
	m_estela.mesh = _mesh_bolt_tail
	m_estela.material_override = mat_tail
	m_estela.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m_estela.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	m_estela.position = Vector3(0.0, 0.0, 0.85)
	holder.add_child(m_estela)
	return holder
