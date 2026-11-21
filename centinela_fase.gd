extends "res://enemigo_base.gd"
class_name CentinelaFase

## CentinelaFase — Enemigo Blindado de Fase (Solo Vulnerable al Botón Móvil)
## Inmune a armas automáticas, proyectiles y ataques cuerpo a cuerpo del jugador.
## Únicamente recibe daño de las ondas, descargas de hilo y estelas del Botón Móvil.

const BunkerVisualKit = preload("res://bunker_visual_kit.gd")
const ESCENA_MODELO_CENTINELA = preload("res://assets/modelos/enemigo_guardia_pretoriano.glb")

var _anillo_orbital: MeshInstance3D = null
var _baliza_fase: MeshInstance3D = null
var _fase_rot: float = 0.0

func _ready() -> void:
	tipo_enemigo_id = "centinela_fase"
	solo_dano_boton = true
	rapidez = 3.55
	vida_maxima = 40.0
	dano_contacto = 15.0
	rango_ataque = 1.45
	cadencia_ataque = 0.95
	resistencia_knockback = 0.55
	xp_otorgada = 28
	oro_otorgado = 10

	add_to_group("enemigos_solo_boton")
	_construir_visual_fase()
	super._ready()

func _construir_visual_fase() -> void:
	if get_node_or_null("CollisionShape3D") == null:
		var col := CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var cap := CapsuleShape3D.new()
		cap.radius = 0.6
		cap.height = 2.45
		col.shape = cap
		col.position = Vector3(0.0, 1.225, 0.0)
		add_child(col)

	if get_node_or_null("Modelo") == null:
		var esc_mod := ESCENA_MODELO_CENTINELA
		if esc_mod != null:
			var mod := esc_mod.instantiate() as Node3D
			if mod != null:
				mod.name = "Modelo"
				mod.scale = Vector3.ONE * 1.08
				add_child(mod)

	if get_node_or_null("EscudoFaseVisual") == null:
		var holder := Node3D.new()
		holder.name = "EscudoFaseVisual"
		add_child(holder)

		# 1. Domo holográfico translúcido cian
		var domo := MeshInstance3D.new()
		domo.name = "DomoFase"
		var sph := SphereMesh.new()
		sph.radius = 1.05
		sph.height = 2.10
		sph.radial_segments = 20
		sph.rings = 12
		domo.mesh = sph
		var mat_domo := StandardMaterial3D.new()
		mat_domo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat_domo.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat_domo.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat_domo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat_domo.albedo_color = Color(0.08, 0.85, 1.0, 0.24)
		domo.material_override = mat_domo
		domo.position = Vector3(0.0, 1.15, 0.0)
		domo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(domo)
		_escudo_fase_mesh = domo

		# 2. Anillo orbital giratorio cian brillante
		_anillo_orbital = MeshInstance3D.new()
		_anillo_orbital.name = "AnilloOrbitalFase"
		var tor := TorusMesh.new()
		tor.inner_radius = 1.08
		tor.outer_radius = 1.18
		tor.rings = 28
		tor.ring_segments = 10
		_anillo_orbital.mesh = tor
		_anillo_orbital.material_override = BunkerVisualKit.make_emissive_mat(
			Color(0.10, 0.92, 1.0), 2.8, Color(0.15, 0.90, 1.0), 0.2, 0.2
		)
		_anillo_orbital.position = Vector3(0.0, 1.15, 0.0)
		_anillo_orbital.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(_anillo_orbital)

		# 3. Baliza diamante rotatoria superior
		_baliza_fase = MeshInstance3D.new()
		_baliza_fase.name = "BalizaFase"
		var prism := BoxMesh.new()
		prism.size = Vector3(0.24, 0.24, 0.24)
		_baliza_fase.mesh = prism
		_baliza_fase.material_override = BunkerVisualKit.make_emissive_mat(
			Color(0.25, 0.98, 1.0), 3.4, Color(0.25, 0.95, 1.0), 0.1, 0.1
		)
		_baliza_fase.position = Vector3(0.0, 2.38, 0.0)
		_baliza_fase.rotation_degrees = Vector3(45.0, 0.0, 45.0)
		_baliza_fase.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(_baliza_fase)

		# 4. Etiqueta táctica billboard
		var lbl := Label3D.new()
		lbl.name = "EtiquetaSoloBoton"
		lbl.text = "⚡ BOTÓN"
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		lbl.font_size = 34
		lbl.pixel_size = 0.0045
		lbl.modulate = Color(0.28, 0.96, 1.0, 0.95)
		lbl.outline_size = 8
		lbl.outline_modulate = Color(0.02, 0.10, 0.16, 0.95)
		lbl.position = Vector3(0.0, 2.65, 0.0)
		holder.add_child(lbl)

func _physics_process(delta: float) -> void:
	if _muerto:
		return
	_fase_rot += delta
	if _anillo_orbital != null and is_instance_valid(_anillo_orbital):
		_anillo_orbital.rotation = Vector3(0.26 * sin(_fase_rot * 1.4), _fase_rot * 2.2, 0.18 * cos(_fase_rot * 1.2))
	if _baliza_fase != null and is_instance_valid(_baliza_fase):
		_baliza_fase.rotate_y(delta * 2.8)
	super._physics_process(delta)

func morir() -> void:
	if _muerto:
		return
	var padre := get_parent()
	var pos_muerte := global_position
	var arbol := get_tree()
	var era_nemesis := es_nemesis
	super.morir()

	if era_nemesis or randf() < 0.35:
		MetaprogresoManager.agregar_esquirlas(1)
		if arbol != null:
			var pool = arbol.get_first_node_in_group("damage_numbers")
			if pool != null and pool.has_method("mostrar_texto"):
				pool.mostrar_texto(pos_muerte + Vector3(0, 2.5, 0), "✨ +1 ESQUIRLA ASTRAL (FASE ROTA)", Color(0.45, 0.98, 1.0), 1.35)

	if padre != null:
		BunkerVisualKit.spawn_shockwave_ring(padre, pos_muerte + Vector3(0, 0.5, 0), 0.4, 3.0, BunkerVisualKit.COL_CYAN_ELECTRIC, 0.35)
