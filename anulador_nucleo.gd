extends "res://enemigo_base.gd"
class_name AnuladorNucleo

## AnuladorNucleo — Disruptor Blindado de Fase (Solo Vulnerable al Botón Móvil)
## Avanza hacia el Botón Móvil para inyectarle calor térmico mediante un haz sifón
## (forzando clics con ritmo perfecto cerca del núcleo) y garantiza 1 Esquirla Astral al caer.

const BunkerVisualKit = preload("res://bunker_visual_kit.gd")
const ESCENA_MODELO_ANULADOR = preload("res://assets/modelos/enemigo_canalizador_vacio.glb")

const RANGO_SIFON: float = 6.5

var _boton: Node3D = null
var _anillo_ext: MeshInstance3D = null
var _anillo_int: MeshInstance3D = null
var _haz_sifon: MeshInstance3D = null
var _cilindro_sifon: CylinderMesh = null
var _fase_rot: float = 0.0

func _ready() -> void:
	tipo_enemigo_id = "anulador_nucleo"
	solo_dano_boton = true
	rapidez = 2.65
	vida_maxima = 88.0
	dano_contacto = 18.0
	rango_ataque = 1.75
	cadencia_ataque = 1.15
	resistencia_knockback = 0.72
	xp_otorgada = 55
	oro_otorgado = 18

	add_to_group("enemigos_solo_boton")
	add_to_group("indicadores_tacticos")
	_construir_visual_anulador()
	super._ready()
	_boton = get_tree().get_first_node_in_group("boton_movil") as Node3D

func actualizar_modo_esencial(activo: bool) -> void:
	var lbl = get_node_or_null("EscudoAnuladorVisual/EtiquetaSoloBoton")
	if lbl != null:
		lbl.visible = not activo

func _construir_visual_anulador() -> void:
	if get_node_or_null("CollisionShape3D") == null:
		var col := CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var cap := CapsuleShape3D.new()
		cap.radius = 0.72
		cap.height = 2.75
		col.shape = cap
		col.position = Vector3(0.0, 1.375, 0.0)
		add_child(col)

	if get_node_or_null("Modelo") == null:
		var esc_mod := ESCENA_MODELO_ANULADOR
		if esc_mod != null:
			var mod := esc_mod.instantiate() as Node3D
			if mod != null:
				mod.name = "Modelo"
				mod.scale = Vector3.ONE * 1.22
				add_child(mod)

	if get_node_or_null("EscudoAnuladorVisual") == null:
		var holder := Node3D.new()
		holder.name = "EscudoAnuladorVisual"
		add_child(holder)

		# 1. Domo violeta-cian
		var domo := MeshInstance3D.new()
		domo.name = "DomoAnulador"
		var sph := SphereMesh.new()
		sph.radius = 1.28
		sph.height = 2.56
		sph.radial_segments = 22
		sph.rings = 12
		domo.mesh = sph
		var mat_domo := StandardMaterial3D.new()
		mat_domo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat_domo.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat_domo.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat_domo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat_domo.albedo_color = Color(0.65, 0.22, 1.0, 0.26)
		domo.material_override = mat_domo
		domo.position = Vector3(0.0, 1.35, 0.0)
		domo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(domo)
		_escudo_fase_mesh = domo

		# 2. Doble anillo orbital cruzado
		_anillo_ext = MeshInstance3D.new()
		_anillo_ext.name = "AnilloExtAnulador"
		var tor1 := TorusMesh.new()
		tor1.inner_radius = 1.32
		tor1.outer_radius = 1.44
		tor1.rings = 28
		tor1.ring_segments = 10
		_anillo_ext.mesh = tor1
		_anillo_ext.material_override = BunkerVisualKit.make_emissive_mat(
			Color(0.55, 0.30, 1.0), 2.8, Color(0.55, 0.25, 1.0), 0.2, 0.2
		)
		_anillo_ext.position = Vector3(0.0, 1.35, 0.0)
		_anillo_ext.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(_anillo_ext)

		_anillo_int = MeshInstance3D.new()
		_anillo_int.name = "AnilloIntAnulador"
		var tor2 := TorusMesh.new()
		tor2.inner_radius = 1.02
		tor2.outer_radius = 1.12
		tor2.rings = 24
		tor2.ring_segments = 8
		_anillo_int.mesh = tor2
		_anillo_int.material_override = BunkerVisualKit.make_emissive_mat(
			BunkerVisualKit.COL_CYAN_ELECTRIC, 2.5, BunkerVisualKit.COL_CYAN_ELECTRIC, 0.2, 0.2
		)
		_anillo_int.position = Vector3(0.0, 1.35, 0.0)
		_anillo_int.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(_anillo_int)

		# 3. Escudo de fase refractario puro (sin contaminación de textos flotantes)
	if get_node_or_null("HazSifonTermico") == null:
		_haz_sifon = MeshInstance3D.new()
		_haz_sifon.name = "HazSifonTermico"
		_cilindro_sifon = CylinderMesh.new()
		_cilindro_sifon.top_radius = 0.055
		_cilindro_sifon.bottom_radius = 0.095
		_cilindro_sifon.height = 1.0
		_cilindro_sifon.radial_segments = 10
		_haz_sifon.mesh = _cilindro_sifon
		var mat_haz := StandardMaterial3D.new()
		mat_haz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat_haz.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat_haz.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat_haz.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat_haz.albedo_color = Color(1.0, 0.22, 0.65, 0.85)
		_haz_sifon.material_override = mat_haz
		_haz_sifon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_haz_sifon.visible = false
		add_child(_haz_sifon)

func _physics_process(delta: float) -> void:
	if _muerto:
		return
	_fase_rot += delta
	if _anillo_ext != null and is_instance_valid(_anillo_ext):
		_anillo_ext.rotation = Vector3(_fase_rot * 1.4, _fase_rot * 2.0, 0.45)
	if _anillo_int != null and is_instance_valid(_anillo_int):
		_anillo_int.rotation = Vector3(-0.65, -_fase_rot * 2.4, _fase_rot * 1.1)

	if _boton == null or not is_instance_valid(_boton):
		_boton = get_tree().get_first_node_in_group("boton_movil") as Node3D

	_procesar_sifon_termico(delta)
	super._physics_process(delta)

func _calcular_velocidad_ia(delta: float) -> Vector3:
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			jugador = get_tree().get_first_node_in_group("player")
	if _boton == null or not is_instance_valid(_boton):
		_boton = get_tree().get_first_node_in_group("boton_movil") as Node3D

	var objetivo_pos: Vector3 = global_position
	if jugador != null and is_instance_valid(jugador) and global_position.distance_to(jugador.global_position) <= 2.6:
		objetivo_pos = jugador.global_position
	elif _boton != null and is_instance_valid(_boton):
		if global_position.distance_to(_boton.global_position) <= 3.6:
			return Vector3.ZERO
		objetivo_pos = _boton.global_position
	elif jugador != null and is_instance_valid(jugador):
		objetivo_pos = jugador.global_position
	else:
		return Vector3.ZERO

	var dir_norm: Vector3 = ArenaColiseo.calcular_direccion_persecucion(self, objetivo_pos, _nav_estado, delta)
	if dir_norm.length_squared() > 0.0025:
		look_at(global_position + dir_norm, Vector3.UP)
		return dir_norm * rapidez
	return Vector3.ZERO

func _procesar_sifon_termico(delta: float) -> void:
	if _haz_sifon == null or not is_instance_valid(_haz_sifon):
		return
	if _boton == null or not is_instance_valid(_boton):
		_haz_sifon.visible = false
		return

	var pos_a: Vector3 = global_position + Vector3(0.0, 1.4, 0.0)
	var pos_b: Vector3 = _boton.global_position
	var dist: float = pos_a.distance_to(pos_b)
	var estado_btn: int = int(_boton.get("estado_actual")) if "estado_actual" in _boton else 0

	# BotonMovil.EstadoBoton: 0 = ACTIVO, 1 = ENCADENADO, 2 = SOBRECARGA_FRENESI
	if dist <= RANGO_SIFON and estado_btn == 0:
		_haz_sifon.visible = true
		var vec: Vector3 = pos_b - pos_a
		var len_v: float = maxf(0.1, vec.length())
		var dir: Vector3 = vec / len_v
		var up_ref: Vector3 = Vector3.UP if absf(dir.y) < 0.99 else Vector3.FORWARD
		var right: Vector3 = dir.cross(up_ref).normalized()
		var fwd: Vector3 = right.cross(dir).normalized()
		_haz_sifon.global_position = (pos_a + pos_b) * 0.5
		_haz_sifon.global_transform.basis = Basis(right, dir, fwd)
		_cilindro_sifon.height = len_v

		if "calor_actual" in _boton:
			_boton.calor_actual = minf(95.0, float(_boton.calor_actual) + 8.5 * delta)
			if _boton.has_method("_sincronizar_telemetria_termica"):
				_boton._sincronizar_telemetria_termica()
	else:
		_haz_sifon.visible = false

func morir() -> void:
	if _muerto:
		return
	if _haz_sifon != null and is_instance_valid(_haz_sifon):
		_haz_sifon.visible = false
	var padre := get_parent()
	var pos_muerte := global_position
	var arbol := get_tree()
	super.morir()

	MetaprogresoManager.agregar_esquirlas(1)

	if jugador != null and is_instance_valid(jugador):
		if "clics_disponibles" in jugador:
			jugador.clics_disponibles += 2
		if "clics_totales" in jugador:
			jugador.clics_totales += 2
		if jugador.has_signal("economia_actualizada") and "oro" in jugador and "clics_disponibles" in jugador and "clics_totales" in jugador:
			jugador.emit_signal("economia_actualizada", jugador.oro, jugador.clics_disponibles, jugador.clics_totales)

	if arbol != null:
		var pool = arbol.get_first_node_in_group("damage_numbers")
		if pool != null and pool.has_method("mostrar_texto"):
			pool.mostrar_texto(pos_muerte + Vector3(0, 2.7, 0), "✨ +1 ESQUIRLA · ANULADOR DESTRUIDO!", Color(0.85, 0.55, 1.0), 1.45)

	if padre != null:
		BunkerVisualKit.spawn_shockwave_ring(padre, pos_muerte + Vector3(0, 0.6, 0), 0.5, 4.2, Color(0.55, 0.35, 1.0, 0.9), 0.40)
