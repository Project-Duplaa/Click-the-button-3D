extends "res://enemigo_base.gd"

const BunkerVisualKit = preload("res://bunker_visual_kit.gd")
const CatalogoBendiciones = preload("res://catalogo_bendiciones.gd")
const ProyectilEnemigoEscena = preload("res://proyectil_enemigo.tscn")

var _manager: Node = null
var _reloj_descarga: float = 2.6
var _reloj_dash: float = 5.2
var _dash_vel: Vector3 = Vector3.ZERO
var _dash_timer: float = 0.0
var _lbl_hp: Label3D = null

func configurar_espejo(mgr: Node) -> void:
	_manager = mgr

func _ready() -> void:
	tipo_enemigo_id = "espejo_sombrio"
	resistencia_knockback = 0.55
	rango_ataque = 2.0
	xp_otorgada = 180
	oro_otorgado = 130

	var mult_hp := 1.0
	var mult_dmg := 1.0
	var mult_vel := 1.0
	var lm = get_tree().get_first_node_in_group("logros_manager")
	if lm != null and lm.has_method("obtener_multiplicadores_tormento"):
		var m = lm.obtener_multiplicadores_tormento()
		mult_hp = float(m.get("vida_enemigos", 1.0))
		mult_dmg = float(m.get("dano_enemigos", 1.0))
		mult_vel = float(m.get("velocidad_enemigos", 1.0))

	vida_maxima = 850.0 * mult_hp
	dano_ataque = 20.0 * mult_dmg
	dano_contacto = 18.0 * mult_dmg
	rapidez = 4.2 * mult_vel

	_asegurar_componentes()
	super._ready()
	add_to_group("jefes")
	add_to_group("bosses")
	set_meta("es_jefe", true)
	set_meta("tipo_enemigo_id", "espejo_sombrio")

	_lbl_hp = get_node_or_null("LabelEspejoHP") as Label3D
	if _lbl_hp == null:
		_lbl_hp = Label3D.new()
		_lbl_hp.name = "LabelEspejoHP"
		_lbl_hp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_lbl_hp.no_depth_test = true
		_lbl_hp.font_size = 38
		_lbl_hp.position = Vector3(0.0, 3.6, 0.0)
		_lbl_hp.modulate = Color(0.88, 0.42, 1.0)
		add_child(_lbl_hp)
	_actualizar_label_hp()

func _asegurar_componentes() -> void:
	if get_node_or_null("CollisionShape3D") == null:
		var col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var cap = CapsuleShape3D.new()
		cap.radius = 0.55
		cap.height = 2.4
		col.shape = cap
		col.position = Vector3(0.0, 1.2, 0.0)
		add_child(col)

	var modelo = get_node_or_null("Modelo")
	if modelo == null:
		var escena_mod = load("res://assets/modelos/jefe_espejo_sombrio.glb") as PackedScene
		if escena_mod != null:
			modelo = escena_mod.instantiate()
			modelo.name = "Modelo"
			add_child(modelo)

func _actualizar_label_hp() -> void:
	if _lbl_hp != null:
		_lbl_hp.text = "🪞 EL ESPEJO SOMBRÍO\n[%d / %d HP]" % [maxi(0, int(ceil(vida))), int(ceil(vida_maxima))]

func _calcular_velocidad_ia(delta: float) -> Vector3:
	if jugador == null or not is_instance_valid(jugador):
		return Vector3.ZERO

	var dif_xz := jugador.global_position - global_position
	dif_xz.y = 0.0
	var dist := dif_xz.length()
	var dir: Vector3 = ArenaColiseo.calcular_direccion_persecucion(self, jugador.global_position, _nav_estado, delta)
	if dir.length_squared() > 0.0025:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 8.0)

	_reloj_dash -= delta
	if _reloj_dash <= 0.0 and dist > 3.5:
		_reloj_dash = 5.0
		_dash_timer = 0.28
		_dash_vel = dir * (rapidez * 3.1)
		AudioManager.play("corte_giratorio", 0.78)
		if get_parent() != null:
			BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 0.3, 2.8, Color(0.75, 0.20, 0.95), 0.30)

	_reloj_descarga -= delta
	if _reloj_descarga <= 0.0:
		_reloj_descarga = 2.85
		var origen_ref := global_position + Vector3(0.0, 1.35, 0.0)
		var dir_3d := ((jugador.global_position + Vector3(0.0, 0.9, 0.0)) - origen_ref).normalized()
		_disparar_rafaga_espejo(dir_3d)

	if _dash_timer > 0.0:
		_dash_timer = maxf(0.0, _dash_timer - delta)
		return _dash_vel

	return dir * rapidez

func _disparar_rafaga_espejo(dir: Vector3) -> void:
	if ProyectilEnemigoEscena == null or get_parent() == null:
		return
	var base_dir = dir if dir.length_squared() > 0.01 else Vector3.FORWARD
	for ang_deg in [-18.0, 0.0, 18.0]:
		var proj = ProyectilEnemigoEscena.instantiate()
		get_parent().add_child(proj)
		var dir_rot = base_dir.rotated(Vector3.UP, deg_to_rad(ang_deg))
		var origen = global_position + Vector3(0.0, 1.35, 0.0) + dir_rot * 0.9
		if proj.has_method("iniciar"):
			proj.iniciar(origen, dir_rot, dano_ataque * 0.85, 9.5)

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false) -> void:
	super.recibir_dano(cantidad, fuente, es_critico)
	_actualizar_label_hp()

func morir() -> void:
	if _muerto:
		return

	MetaprogresoManager.agregar_esquirlas(1)
	MetaprogresoManager.guardar()

	var lm = get_tree().get_first_node_in_group("logros_manager")
	if lm != null:
		if lm.has_method("registrar_baja_espejo"):
			lm.registrar_baja_espejo()
		if lm.has_method("registrar_baja_enemigo"):
			lm.registrar_baja_enemigo("espejo_sombrio", true)

	if _manager != null and is_instance_valid(_manager) and _manager.has_signal("jefe_espejo_derrotado"):
		_manager.emit_signal("jefe_espejo_derrotado")

	# Recompensa inmediata: cofrecito + bendición de alta rareza gratis
	var hud = get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("mostrar_selector_bendiciones") and jugador != null and is_instance_valid(jugador):
		var suerte_boost = 1.25
		if jugador.has_method("obtener_suerte_total"):
			suerte_boost += jugador.obtener_suerte_total()
		var run_b = jugador.bendiciones_run if "bendiciones_run" in jugador else {}
		var opciones = CatalogoBendiciones.obtener_3_opciones(run_b, suerte_boost)
		if not opciones.is_empty():
			hud.call_deferred("mostrar_selector_bendiciones", 1, opciones)

	var pool = get_tree().get_first_node_in_group("damage_numbers")
	if pool != null and pool.has_method("mostrar_texto"):
		pool.mostrar_texto(global_position + Vector3(0, 3.0, 0), "✨ ¡ESPEJO SOMBRÍO DERROTADO! +1 ESQUIRLA ASTRAL ✨", Color(0.95, 0.55, 1.0), 1.8)

	AudioManager.play("legendario", 1.2)
	super.morir()
