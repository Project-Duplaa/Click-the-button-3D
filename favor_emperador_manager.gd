extends Node
class_name FavorEmperadorManager

## FavorEmperadorManager — Sistema de Aprobación de la Grada Imperial y Juicio del Emperador
## 1. Medidor de Favor (0.0..100.0):
##    - Clics perfectos (+2.5), Bajas élite/jefe (+15.0), Bajas normales (+0.5),
##      Esquiva dash de último segundo (+6.0), Fiebre x3+/Overdrive (+1.5/s), Contrato Lanista (+25.0).
##    - Decae -1.2/s tras 6.0s sin clics ni bajas.
##    - Eclipse de Plutón duplica (+100%) toda ganancia de Favor.
## 2. Regalos de la Multitud (Favor >= 80.0):
##    - Cada 8.0s la grada lanza 2-3 drops de Oro y Corazones en arcos parabólicos desde el perímetro.
## 3. Pulgar del Emperador 👍 / 👎:
##    - Al recibir daño letal (1 vida restante / derrota), se congela la partida (time_scale 0.22 por 1.8s).
##    - Si Favor >= 75: salvación garantizada (100%).
##    - Si Favor < 75: probabilidad = clamp(favor / 100.0, 0.10, 0.99).
##    - Si se salva: pulgar arriba, revive con 60% HP, resetea favor a 0.
##    - Si no: pulgar abajo, ejecución y derrota definitiva.
## 4. Contratos del Lanista:
##    - Cada 150s (primer contrato a los 75s), emite 1 de 4 contratos tácticos (45-60s).
##    - Recompensas: Denarios, Oro, +25 Favor y un Cofre de Gladiador.

const AudioManager = preload("res://audio_manager.gd")
const ArenaColiseo = preload("res://arena_coliseo.gd")
const BunkerVisualKit = preload("res://bunker_visual_kit.gd")
const CofreGladiadorScript = preload("res://cofre_gladiador.gd")

signal favor_cambiado(valor: float, nivel_txt: String)
signal pulgar_emperador_iniciado(favor_actual: float)
signal pulgar_emperador_resuelto(salvado: bool, prob: float)
signal contrato_actualizado(datos: Dictionary)
signal contrato_completado(titulo: String, desc_recompensa: String)

@export var favor: float = 0.0
var en_locura_coliseo: bool = false
var juicio_usado: bool = false

var _tiempo_sin_accion: float = 0.0
var _reloj_regalos_multitud: float = 0.0
var _partida_iniciada: bool = false

# Sistema de Contratos del Lanista
var _reloj_siguiente_contrato: float = 75.0
var _contrato_activo: Dictionary = {}
var _tiempo_restante_contrato: float = 0.0
var _progreso_contrato: int = 0
var _meta_contrato: int = 0

const TIPOS_CONTRATO := [
	{
		"id": "sangre",
		"titulo": "Sed de Sangre Imperial",
		"desc": "Aniquila 18 gladiadores en 45 segundos",
		"duracion": 45.0,
		"meta": 18
	},
	{
		"id": "precision",
		"titulo": "Ritmo de Diamante",
		"desc": "Pulsar 12 veces el Núcleo sin dejar caer el compás",
		"duracion": 50.0,
		"meta": 12
	},
	{
		"id": "intocable",
		"titulo": "Danza Sin Mancha",
		"desc": "Sobrevive 35 segundos sin recibir daño directo",
		"duracion": 35.0,
		"meta": 35
	},
	{
		"id": "hilo",
		"titulo": "Resonancia Voltaica",
		"desc": "Alcanza a 15 enemigos con el Hilo u Ondas de Clic",
		"duracion": 50.0,
		"meta": 15
	}
]

func _ready() -> void:
	add_to_group("favor_emperador_manager")
	add_to_group("favor_emperador")
	en_locura_coliseo = (favor >= 80.0)
	emit_signal("favor_cambiado", favor, _obtener_texto_nivel_favor())

func _process(delta: float) -> void:
	if not _partida_iniciada:
		var spawner = get_tree().get_first_node_in_group("oleadas_spawner")
		if spawner != null and "partida_iniciada" in spawner and spawner.partida_iniciada:
			_partida_iniciada = true
		else:
			return

	# 1. Decaimiento de Favor tras 6.0s sin actividad de combate
	_tiempo_sin_accion += delta
	if _tiempo_sin_accion >= 6.0 and favor > 0.0:
		modificar_favor(-1.2 * delta)

	# 2. Bonificación continua por Fiebre x3+ u Overdrive
	var pj = get_tree().get_first_node_in_group("jugador")
	if pj == null:
		pj = get_tree().get_first_node_in_group("player")
	if pj != null and is_instance_valid(pj):
		var en_over = ("en_overdrive" in pj and pj.en_overdrive)
		var mult_fever = ("multiplicador_fiebre_actual" in pj and pj.multiplicador_fiebre_actual >= 3)
		if en_over or mult_fever:
			modificar_favor(1.5 * delta)

	# 3. Regalos de la Grada en Locura del Coliseo (Favor >= 80)
	if en_locura_coliseo:
		_reloj_regalos_multitud += delta
		if _reloj_regalos_multitud >= 8.0:
			_reloj_regalos_multitud = 0.0
			_lanzar_regalos_grada()

	# 4. Progresión de Contratos del Lanista
	_procesar_contratos(delta)

func modificar_favor(cantidad: float) -> void:
	var cant_final := cantidad
	if cant_final > 0.0:
		_tiempo_sin_accion = 0.0
		var eventos = get_tree().get_first_node_in_group("eventos_coliseo_manager")
		if eventos != null and "mutador_actual" in eventos and eventos.mutador_actual == "eclipse":
			cant_final *= 2.0

	var previo = favor
	favor = clampf(favor + cant_final, 0.0, 100.0)

	var locura_previa = en_locura_coliseo
	en_locura_coliseo = (favor >= 80.0)

	if not locura_previa and en_locura_coliseo:
		AudioManager.play("victoria", 1.3)
		_anunciar_evento_3d("🏛️ ¡LOCURA EN LAS GRADAS! El Emperador exige gloria", Color(1.0, 0.85, 0.2))
	elif locura_previa and not en_locura_coliseo:
		_reloj_regalos_multitud = 0.0

	if absf(previo - favor) >= 0.05:
		emit_signal("favor_cambiado", favor, _obtener_texto_nivel_favor())

func _obtener_texto_nivel_favor() -> String:
	if favor >= 80.0:
		return "¡LOCURA DEL COLISEO!"
	elif favor >= 75.0:
		return "Entusiasmo Imperial"
	elif favor >= 50.0:
		return "Aprobación"
	elif favor >= 25.0:
		return "Indiferencia"
	return "Desdén"

# ==============================================================================
# NOTIFICACIONES EXTERNAS DE EVENTOS
# ==============================================================================

func notificar_clic_boton(es_perfecto: bool, _calor: float) -> void:
	_partida_iniciada = true
	_tiempo_sin_accion = 0.0
	if es_perfecto:
		modificar_favor(2.5)

	if not _contrato_activo.is_empty() and _contrato_activo["id"] == "precision":
		_progreso_contrato += 1
		_actualizar_datos_contrato_ui()
		if _progreso_contrato >= _meta_contrato:
			_completar_contrato_activo()

func notificar_baja(_tipo_enemigo: String, es_elite_o_jefe: bool) -> void:
	_partida_iniciada = true
	_tiempo_sin_accion = 0.0
	modificar_favor(15.0 if es_elite_o_jefe else 0.5)

	if not _contrato_activo.is_empty() and _contrato_activo["id"] == "sangre":
		_progreso_contrato += 1
		_actualizar_datos_contrato_ui()
		if _progreso_contrato >= _meta_contrato:
			_completar_contrato_activo()

func notificar_esquiva_dash() -> void:
	_tiempo_sin_accion = 0.0
	modificar_favor(6.0)
	AudioManager.play("corte_giratorio", 1.35)
	_anunciar_evento_3d("✨ ¡ESQUIVA PERFECTA! (+6.0 Favor)", Color(0.35, 0.95, 1.0))

func notificar_electro_hilo(cantidad_enemigos: int = 1) -> void:
	if not _contrato_activo.is_empty() and _contrato_activo["id"] == "hilo":
		_progreso_contrato += cantidad_enemigos
		_actualizar_datos_contrato_ui()
		if _progreso_contrato >= _meta_contrato:
			_completar_contrato_activo()

func notificar_dano_jugador(_cantidad: float) -> void:
	if not _contrato_activo.is_empty() and _contrato_activo["id"] == "intocable":
		_progreso_contrato = 0
		_anunciar_evento_3d("❌ Contrato Intocable: Daño recibido, reiniciando racha", Color(1.0, 0.3, 0.3))
		_actualizar_datos_contrato_ui()

# ==============================================================================
# PULGAR DEL EMPERADOR (SALVACIÓN O EJECUCIÓN DEFINITIVA)
# ==============================================================================

func intentar_juicio_emperador_al_morir(pj: Node) -> bool:
	if juicio_usado or pj == null or favor < 40.0:
		return false
	juicio_usado = true

	emit_signal("pulgar_emperador_iniciado", favor)

	# Slowdown cinematográfico en tiempo real
	Engine.time_scale = 0.22
	var timer = get_tree().create_timer(1.8, true, false, true)
	await timer.timeout
	Engine.time_scale = 1.0
	if not is_inside_tree():
		return false

	var prob: float = 1.0 if favor >= 75.0 else clampf(favor / 100.0, 0.10, 0.99)
	var salvado: bool = (randf() < prob)

	emit_signal("pulgar_emperador_resuelto", salvado, prob)

	if salvado:
		AudioManager.play("victoria", 1.35)
		_anunciar_evento_3d("👍 ¡PULGAR ARRIBA! El Emperador te otorga clemencia", Color(1.0, 0.85, 0.2))
		favor = 0.0
		emit_signal("favor_cambiado", favor, _obtener_texto_nivel_favor())
		if pj.has_method("revivir_por_emperador"):
			pj.revivir_por_emperador(0.60)
		else:
			if "vida_maxima" in pj and "vida" in pj:
				pj.vida = pj.vida_maxima * 0.60
			if "_muerto_definitivo" in pj:
				pj._muerto_definitivo = false
			if "_reloj_invulnerable" in pj:
				pj._reloj_invulnerable = 3.5
			if pj.has_method("_crear_feedback_reaparicion"):
				pj._crear_feedback_reaparicion()
	else:
		AudioManager.play("jefe_alerta", 1.4)
		_anunciar_evento_3d("👎 ¡PULGAR ABAJO! El Emperador decreta tu fin", Color(1.0, 0.15, 0.15))
		if pj.has_method("finalizar_muerte_definitiva"):
			pj.finalizar_muerte_definitiva()
		else:
			var partida = get_tree().get_first_node_in_group("partida")
			if partida != null and partida.has_method("perder"):
				partida.perder("El Emperador bajó su pulgar. Caíste para siempre en la arena.")

	return true

# ==============================================================================
# REGALOS DE LA MULTITUD (LLUVIA PARABÓLICA DE SUMINISTROS)
# ==============================================================================

func _lanzar_regalos_grada() -> void:
	var arena = get_parent()
	if arena == null:
		return

	AudioManager.play("altar_activado", 1.25)
	var cant_regalos = randi_range(2, 3)

	var pj: Node3D = get_tree().get_first_node_in_group("jugador") as Node3D if get_tree() != null else null
	for i in range(cant_regalos):
		var angulo = randf() * TAU
		var pos_inicio = Vector3(cos(angulo) * 50.0, 8.0, sin(angulo) * 50.0)
		var pos_destino: Vector3
		if pj != null and is_instance_valid(pj):
			var a_dest: float = randf() * TAU
			var d_dest: float = randf_range(6.0, 16.0)
			pos_destino = ArenaColiseo.clamping_y_ajustar_a_suelo(pj.global_position + Vector3(cos(a_dest) * d_dest, 0.0, sin(a_dest) * d_dest), 2.2, 0.25)
		else:
			pos_destino = ArenaColiseo.punto_aleatorio(8.0, 38.0, null, 0.25)

		var tipo_drop = 0 if randf() < 0.70 else 2 # 0: Oro, 2: Corazón
		_crear_proyectil_regalo(pos_inicio, pos_destino, tipo_drop)

func _crear_proyectil_regalo(inicio: Vector3, destino: Vector3, tipo_drop: int) -> void:
	var nodo_regalo = Node3D.new()
	get_parent().add_child(nodo_regalo)
	nodo_regalo.global_position = inicio

	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.32
	sphere.height = 0.64
	mesh_inst.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.2) if tipo_drop == 0 else Color(1.0, 0.2, 0.35)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 2.5
	mesh_inst.material_override = mat
	nodo_regalo.add_child(mesh_inst)

	var tw = nodo_regalo.create_tween()
	var duracion = randf_range(1.1, 1.45)
	tw.tween_method(func(t: float):
		if not is_instance_valid(nodo_regalo):
			return
		var p_lineal = inicio.lerp(destino, t)
		p_lineal.y += sin(t * PI) * 5.5
		nodo_regalo.global_position = p_lineal
	, 0.0, 1.0, duracion).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tw.chain().tween_callback(func():
		if not is_instance_valid(nodo_regalo):
			return
		var pos_final = ArenaColiseo.clamping_y_ajustar_a_suelo(nodo_regalo.global_position, 1.4, 0.30)
		nodo_regalo.queue_free()

		# Instanciar drop real al impactar el suelo
		var escena_drop = load("res://drop_item.tscn")
		if escena_drop != null and get_parent() != null:
			var drop = escena_drop.instantiate()
			get_parent().add_child(drop)
			drop.global_position = pos_final
			if drop.has_method("iniciar"):
				drop.iniciar(tipo_drop, 25 if tipo_drop == 0 else 20)
		BunkerVisualKit.spawn_shockwave_ring(get_parent(), pos_final, 0.3, 1.8, mat.albedo_color, 0.25)
	)

# ==============================================================================
# CONTRATOS DEL LANISTA (MISIÓN DINÁMICA DE COMBATE)
# ==============================================================================

func _procesar_contratos(delta: float) -> void:
	if _contrato_activo.is_empty():
		_reloj_siguiente_contrato -= delta
		if _reloj_siguiente_contrato <= 0.0:
			_reloj_siguiente_contrato = 150.0
			_iniciar_nuevo_contrato()
	else:
		_tiempo_restante_contrato -= delta
		if _contrato_activo["id"] == "intocable":
			_progreso_contrato = int(round(_meta_contrato - maxf(_tiempo_restante_contrato, 0.0)))
			if _progreso_contrato >= _meta_contrato:
				_completar_contrato_activo()
				return

		if _tiempo_restante_contrato <= 0.0:
			_fallar_contrato_activo()
		else:
			_actualizar_datos_contrato_ui()

func _iniciar_nuevo_contrato() -> void:
	var plantilla = TIPOS_CONTRATO[randi() % TIPOS_CONTRATO.size()]
	_contrato_activo = plantilla.duplicate(true)
	_tiempo_restante_contrato = float(_contrato_activo["duracion"])
	_progreso_contrato = 0
	_meta_contrato = int(_contrato_activo["meta"])

	AudioManager.play("alerta_oleada", 1.35)
	_anunciar_evento_3d("📜 NUEVO CONTRATO DEL LANISTA: %s" % _contrato_activo["titulo"], Color(1.0, 0.78, 0.2))
	_actualizar_datos_contrato_ui()

func _actualizar_datos_contrato_ui() -> void:
	if _contrato_activo.is_empty():
		emit_signal("contrato_actualizado", {})
		return
	var datos = {
		"id": _contrato_activo["id"],
		"titulo": _contrato_activo["titulo"],
		"desc": _contrato_activo["desc"],
		"progreso": _progreso_contrato,
		"meta": _meta_contrato,
		"tiempo_restante": _tiempo_restante_contrato,
		"activo": true
	}
	emit_signal("contrato_actualizado", datos)

func _completar_contrato_activo() -> void:
	var tit = str(_contrato_activo.get("titulo", "Contrato"))
	_contrato_activo.clear()
	_tiempo_restante_contrato = 0.0

	modificar_favor(25.0)
	AudioManager.play("victoria", 1.3)

	var pj = get_tree().get_first_node_in_group("jugador")
	if pj == null:
		pj = get_tree().get_first_node_in_group("player")

	if pj != null and is_instance_valid(pj):
		if pj.has_method("recoger_drop"):
			pj.recoger_drop(0, 75)
		if pj.has_method("ganar_denarios"):
			pj.ganar_denarios(15)

		# Spawnea un Cofre de Gladiador cerca del jugador
		var cofre = CofreGladiadorScript.new()
		get_parent().add_child(cofre)
		var offset = Vector3(randf_range(-3.5, 3.5), 0.0, randf_range(-3.5, 3.5)).normalized() * 3.0
		cofre.global_position = ArenaColiseo.clamping_y_ajustar_a_suelo(pj.global_position + offset, 1.8, 0.0)

	# Notificar a LogrosManager si implementa la función
	var logros = get_tree().get_first_node_in_group("logros_manager")
	if logros != null and logros.has_method("registrar_contrato_completado"):
		logros.registrar_contrato_completado()

	var desc_rec = "+75 Oro, +15 Denarios, +25 Favor y Cofre Gladiador"
	_anunciar_evento_3d("🏆 ¡CONTRATO CUMPLIDO! %s" % tit, Color(0.2, 1.0, 0.4))
	emit_signal("contrato_completado", tit, desc_rec)
	emit_signal("contrato_actualizado", {})

func _fallar_contrato_activo() -> void:
	var tit = str(_contrato_activo.get("titulo", "Contrato"))
	_contrato_activo.clear()
	_tiempo_restante_contrato = 0.0
	_anunciar_evento_3d("⏳ Contrato Expirado: %s" % tit, Color(0.7, 0.7, 0.7))
	emit_signal("contrato_actualizado", {})

func _anunciar_evento_3d(txt: String, col: Color) -> void:
	var pool = get_tree().get_first_node_in_group("damage_numbers")
	var pj = get_tree().get_first_node_in_group("jugador")
	if pj == null:
		pj = get_tree().get_first_node_in_group("player")
	if pool != null and pj != null and is_instance_valid(pj):
		pool.mostrar_texto(pj.global_position + Vector3(0, 2.5, 0), txt, col, 1.35)

func _exit_tree() -> void:
	Engine.time_scale = 1.0
