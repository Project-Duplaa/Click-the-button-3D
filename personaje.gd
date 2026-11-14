extends CharacterBody3D

const AudioManager = preload("res://audio_manager.gd")
const EvolucionManager = preload("res://evolucion_manager.gd")
const ArbolMejorasDatos = preload("res://arbol_mejoras_datos.gd")
const MetaprogresoManager = preload("res://metaprogreso_manager.gd")
const ArbolInterconectadoDatos = preload("res://arbol_interconectado_datos.gd")
const CatalogoBendicionesScript = preload("res://catalogo_bendiciones.gd")
const HiloResonanciaScript = preload("res://hilo_resonancia.gd")
const DamageNumbersPoolScript = preload("res://damage_numbers_pool.gd")
const AudioDopaminaScript = preload("res://audio_dopamina.gd")
const CursorTacticoScript = preload("res://cursor_tactico.gd")
const LogrosManagerScript = preload("res://logros_manager.gd")

enum Estado { QUIETO, CAMINAR, CORRER, AIRE }
const RUIDO = [0.0, 2.5, 6.5, 0.0]

signal stats_actualizadas(vida, max_vida, xp, xp_sig, nivel, oro, bajas)
signal nivel_subido(nuevo_nivel)
signal economia_actualizada(oro_actual, clics_disponibles, clics_totales)
signal mejora_arbol_comprada(id_mejora, nuevo_nivel)
signal denarios_actualizados(denarios_actuales)
signal suerte_cambiada(nueva_suerte)
signal fiebre_actualizada(valor_actual: float, multiplicador: int, en_overdrive: bool)
signal bendicion_adquirida(id_bendicion: String, nivel_actual: int)

@export var camara: Camera3D
@export var speed_caminar = 3.2
@export var speed_correr = 5.8
@export var tiempo_arranque = 0.20
@onready var anim = $Modelo/AnimationPlayer

# Estadísticas RPG / Autobattler (Balanceado estilo Vampire Survivors: ágil y escalable)
var clase: String = "Novato"
var vida_maxima: float = 100.0
var vida: float = 100.0
var dano: float = 12.0
var rango_ataque: float = 2.6
var cadencia_ataque: float = 0.85
var oro: int = 0
var xp: int = 0
var xp_siguiente_nivel: int = 25
var nivel: int = 1
var bajas: int = 0

# Sistema Incremental: Monedas, Clics y Árbol de Ascensión
var clics_disponibles: int = 0
var clics_totales: int = 0
var mejoras_arbol: Dictionary = {}

# Sistema de Fortuna (suerte, moneda de run y reliquias). Se reinician con cada run (escena nueva).
var suerte: float = 0.0 # Suerte de la run: cartas de nivel, tréboles, santuarios
var suerte_arbol: float = 0.0 # Suerte permanente del nodo Trébol del Coliseo (se recalcula)
var denarios: int = 0 # Moneda exclusiva de la run para santuarios. NO pasa al metaprogreso
var reliquias: Dictionary = {} # id_reliquia -> stacks
var duplicar_proxima_carta: bool = false # La próxima carta de nivel se aplica dos veces

# CAPA 1: Estadísticas base puras según clase
var base_vida_maxima: float = 100.0
var base_dano: float = 12.0
var base_cadencia_ataque: float = 0.85
var base_rango_ataque: float = 2.6
var base_speed_caminar: float = 3.4
var base_speed_correr: float = 5.4

# CAPA 3: Bonos Persistentes de Run (Cofres Dorados, Altares, Ascensión Tier 2 — NUNCA se borran al evolucionar)
var bono_run_dano_plana: float = 0.0
var bono_run_dano_mult: float = 1.0
var bono_run_vida_plana: float = 0.0
var bono_run_vel_plana: float = 0.0
var bono_run_vel_mult: float = 1.0
var bono_run_cadencia_mult: float = 1.0
var bono_run_crit_prob: float = 0.0
var bono_run_crit_mult: float = 0.0
var bono_run_armadura_plana: float = 0.0
var bono_run_proyectiles_extra: int = 0
var bono_run_perforacion_extra: int = 0
var bono_run_rebotes_extra: int = 0
var bono_run_onda_radio_mult: float = 1.0
var bono_run_onda_dano_mult: float = 1.0

# CAPA 4: Bendiciones Roguelike In-Run (24 Bendiciones + 6 Sinergias Duales)
var bendiciones_run: Dictionary = {} # id_bendicion -> stacks
var sinergias_activas: Array[String] = []

# Sistema de Fiebre / Overdrive (x1 a x5)
var medidor_fiebre: float = 0.0
var nivel_fiebre: int = 1
var multiplicador_fiebre_actual: int = 1
var en_overdrive: bool = false
var _cooldown_heraldo_fiebre: float = 0.0
var _frenesi_clic_stacks: int = 0
var _frenesi_clic_timer: float = 0.0

# Dash Táctico con i-frames
var _dash_cooldown: float = 0.0
var _dash_tiempo_activo: float = 0.0
var _dash_direccion: Vector3 = Vector3.ZERO
var _temporizador_estela_fuego: float = 0.0

# Sistema de Vidas, Reapariciones y Derrota Definitiva
var vidas_base: int = 1
var bonus_vidas_arbol: int = 0
@export var reapariciones: int = 0 # 0 reapariciones = 1 vida base al inicio (modo roguelike hardcore incremental)
@export var invulnerable_tiempo: float = 2.0
@export var punto_reaparicion: Vector3 = Vector3(0, 0.5, 0)
var _reloj_invulnerable: float = 0.0
var _muerto_definitivo: bool = false
var _cooldown_ultimo_aliento: float = 0.0

# Estadísticas Incrementales del Árbol (55 Nodos en 5 Tiers + 21 nodos antes desconectados)
var escudo_almas: float = 0.0
var max_escudo_almas: float = 0.0
var armadura_plana: float = 0.0
var mitigacion_pasiva_pct: float = 0.0
var prob_esquiva: float = 0.0
var bonus_dano_pct: float = 0.0
var bonus_dano_armas_pct: float = 0.0
var bonus_dano_clic_pct: float = 0.0
var clics_por_pulsacion: int = 1
var bonus_radio_aoe_clic: float = 0.0
var bonus_empuje_clic_pct: float = 0.0
var bonus_eco_clic_prob: float = 0.0
var bonus_critico_clic_prob: float = 0.0
var bonus_dano_critico_pct: float = 0.0
var bonus_velocidad_mov_pct: float = 0.0
var radio_iman_extra: float = 0.0
var regen_vida_seg: float = 0.0
var vida_por_baja: float = 0.0
var bonus_invulnerable_seg: float = 0.0
var reflejo_dano_pct: float = 0.0
var oro_por_baja_pct: float = 0.0
var xp_ganada_pct: float = 0.0
var bonus_cadencia_pct: float = 0.0
var autoclick_tasa: float = 0.0
var _autoclick_acumulador: float = 0.0
var proyectiles_extra: int = 0
var perforacion_armas: int = 0
var rebotes_armas: int = 0
var oro_pasivo_seg: float = 0.0
var _oro_pasivo_acum: float = 0.0
var interes_oleada_pct: float = 0.0
var clic_cura_escudo: float = 0.0
var xp_a_oro_pct: float = 0.0
var clic_genera_oro_pct: float = 0.0
var tempestad_oro_dmg: float = 0.0
var contador_cataclismo: int = 0

# Nodos del Árbol antes desconectados (ahora 100% operativos)
var prob_anomalia_extra_pct: float = 0.0
var dano_sobrecarga_extra: float = 0.0
var frenesi_clic_pct_por_stack: float = 0.0
var penetracion_clic_pct: float = 0.0
var resistencia_estados_pct: float = 0.0
var bloqueo_genera_clics: int = 0
var orbes_oro_duplicados_pct: float = 0.0
var detonacion_oro_pct: float = 0.0
var terremoto_clic_vida: int = 0
var oro_salud_conversion: int = 0

# Keystones Supremos
var keystone_cataclismo: bool = false
var keystone_soberania: bool = false
var keystone_segunda_vida: bool = false
var keystone_coloso: bool = false
var keystone_aliento: bool = false
var keystone_usura: bool = false
var keystone_fabrica: bool = false
var keystone_bucle: bool = false
var keystone_oro_liquido: bool = false
var keystone_zenit: bool = false
var ascension_suprema: bool = false

# Modificadores de compatibilidad legacy
var bonus_vida_max: float = 0.0
var bonus_velocidad_pct: float = 0.0
var bonus_oro_pct: float = 0.0
var prob_critico: float = 0.05
var mult_critico: float = 2.0
var bonus_nivel_critico: float = 0.0
var bonus_nivel_iman: float = 0.0
var contador_clics_sobrecarga: int = 0
var _reloj_incremental_pasivo: float = 0.0
var _clics_pasivos_frac: float = 0.0

var evolucion_manager: EvolucionManager = null
var _hilo_resonancia: Node3D = null

var _reloj_ataque: float = 0.0
var _reloj_anim_accion: float = 0.0

var multiplicador = 1.0
var empuje = Vector3.ZERO
var accion = ""
var avance = Vector3.ZERO

var estado = Estado.QUIETO
var ruido = 0.0

# Mecánicas de Combate de Guerrero (Tanque)
var bloqueando: bool = false
var reduccion_dano_bloqueo: float = 0.75
var velocidad_bloqueo_multiplicador: float = 0.50
var _escudo_visual: Node3D = null
var _preview_baston: Node3D = null
var _preview_espada: Node3D = null
var _preview_arco: Node3D = null
var _anim_ctrl: AnimadorEntidad = null
var _modelo_pos_base: Vector3 = Vector3.ZERO
var _modelo_rot_base: Vector3 = Vector3.ZERO
var _modelo_escala_base: Vector3 = Vector3(-2.6, 2.6, -2.6)
var _tween_modelo_ataque: Tween = null
var _turno_ataque_novato: bool = false
var _arma_der_ref: Node3D = null
var _arma_izq_ref: Node3D = null
var _luz_orbe_ref: OmniLight3D = null

func obtener_vidas_maximas() -> int:
	return vidas_base + bonus_vidas_arbol

func _ready():
	add_to_group("jugador")
	add_to_group("player")
	if camara == null and get_viewport() != null:
		camara = get_viewport().get_camera_3d()

	var mod_inicial = get_node_or_null("Modelo") as Node3D
	if mod_inicial != null:
		_modelo_pos_base = mod_inicial.position
		_modelo_rot_base = mod_inicial.rotation
		_modelo_escala_base = mod_inicial.scale
	_anim_ctrl = AnimadorEntidad.new(mod_inicial)
	anim = _anim_ctrl.obtener_animation_player()

	if has_node("EvolucionManager"):
		evolucion_manager = $EvolucionManager
	else:
		evolucion_manager = EvolucionManager.new()
		evolucion_manager.name = "EvolucionManager"
		add_child(evolucion_manager)

	evolucion_manager.configurar_con_personaje(self)
	if not evolucion_manager.malla_cambiada.is_connected(_on_malla_cambiada):
		evolucion_manager.malla_cambiada.connect(_on_malla_cambiada)
	_crear_escudo_visual()
	aplicar_clase("Novato")
	MetaprogresoManager.aplicar_a_personaje(self)
	reapariciones = max(0, obtener_vidas_maximas() - 1)
	vida = vida_maxima
	call_deferred("_bootstrap_core_systems")
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

func _on_malla_cambiada(nuevo_modelo: Node3D) -> void:
	if nuevo_modelo == null:
		return
	_modelo_pos_base = nuevo_modelo.position
	_modelo_rot_base = nuevo_modelo.rotation
	_modelo_escala_base = nuevo_modelo.scale
	if _anim_ctrl == null:
		_anim_ctrl = AnimadorEntidad.new(nuevo_modelo)
	else:
		_anim_ctrl.vincular_modelo(nuevo_modelo)
	anim = _anim_ctrl.obtener_animation_player()
	equipar_armas_clase(clase)

func equipar_armas_clase(nombre_clase: String) -> void:
	var mod = get_node_or_null("Modelo") as Node3D
	if mod == null:
		return
	var armas := AnimadorEntidad.equipar_armas_en_esqueleto(mod, nombre_clase, true)
	_arma_der_ref = armas.get("derecha", null)
	_arma_izq_ref = armas.get("izquierda", null)
	_luz_orbe_ref = armas.get("luz_orbe", null)
	_preview_baston = _arma_der_ref if nombre_clase == "Mago" else null
	_preview_espada = _arma_der_ref if nombre_clase == "Guerrero" else null
	_preview_arco = _arma_izq_ref if nombre_clase == "Cazador" else null

func _bootstrap_core_systems():
	var tree = _obtener_tree()
	if tree == null or get_parent() == null:
		return
	var parent_arena = get_parent()

	if tree.get_first_node_in_group("damage_numbers_pool") == null:
		var pool = DamageNumbersPoolScript.new()
		pool.name = "DamageNumbersPool"
		parent_arena.add_child(pool)

	if tree.get_first_node_in_group("audio_dopamina") == null:
		var audio_dop = AudioDopaminaScript.new()
		audio_dop.name = "AudioDopamina"
		parent_arena.add_child(audio_dop)

	if tree.get_first_node_in_group("cursor_tactico") == null:
		var cur = CursorTacticoScript.new()
		cur.name = "CursorTactico"
		parent_arena.add_child(cur)

	if tree.get_first_node_in_group("logros_manager") == null:
		var logros = LogrosManagerScript.new()
		logros.name = "LogrosManager"
		parent_arena.add_child(logros)

	if tree.get_first_node_in_group("hilo_resonancia") == null:
		_hilo_resonancia = HiloResonanciaScript.new()
		_hilo_resonancia.name = "HiloResonancia"
		parent_arena.add_child(_hilo_resonancia)
	else:
		_hilo_resonancia = tree.get_first_node_in_group("hilo_resonancia") as Node3D

	var boton = tree.get_first_node_in_group("boton_movil") as Node3D
	if _hilo_resonancia != null and boton != null and _hilo_resonancia.has_method("configurar_extremos"):
		_hilo_resonancia.configurar_extremos(self, boton)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and clase == "Guerrero":
			_actualizar_estado_bloqueo(event.pressed)
	elif event is InputEventKey:
		if (event.keycode == KEY_F or event.keycode == KEY_Q) and clase == "Guerrero":
			_actualizar_estado_bloqueo(event.pressed)
		elif event.pressed and not event.echo and event.keycode == KEY_SPACE:
			_intentar_dash_tactico()

func _intentar_dash_tactico():
	if _muerto_definitivo or _dash_cooldown > 0.0:
		return
	var cd_base = 2.0
	if bendiciones_run.has("global_dash_frenetico"):
		cd_base *= pow(0.75, float(bendiciones_run["global_dash_frenetico"]))
	if mejoras_arbol.has("mov_dash"):
		cd_base *= maxf(0.45, 1.0 - float(mejoras_arbol["mov_dash"]) * 0.12)
	_dash_cooldown = maxf(0.45, cd_base)
	_dash_tiempo_activo = 0.22
	_reloj_invulnerable = maxf(_reloj_invulnerable, 0.32)

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var entrada = Vector3(input_dir.x, 0.0, input_dir.y)
	var giro_cam = camara.global_rotation.y if camara != null else 0.0
	var dir_mov = entrada.rotated(Vector3.UP, giro_cam).normalized()
	if dir_mov.length_squared() < 0.01:
		dir_mov = -global_transform.basis.z.normalized()
		dir_mov.y = 0.0
	_dash_direccion = dir_mov.normalized()

	AudioManager.play("corte_espada", 1.35)
	if bendiciones_run.has("global_dash_frenetico"):
		_repeler_enemigos_alrededor(3.6, 9.0, dano * 0.85 * float(bendiciones_run["global_dash_frenetico"]))
	if sinergias_activas.has("sinergia_juggernaut"):
		_repeler_enemigos_alrededor(4.8, 14.0, (dano + armadura_plana * 1.5))

func aplicar_knockback(impulso: Vector3):
	if resistencia_estados_pct >= 0.95:
		return
	var factor = clampf(1.0 - resistencia_estados_pct, 0.0, 1.0)
	empuje += Vector3(impulso.x, 0.0, impulso.z) * factor

func _physics_process(delta):
	if _muerto_definitivo:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	# Disipación suave de empuje / knockback
	if empuje.length_squared() > 0.001:
		empuje = empuje.move_toward(Vector3.ZERO, 18.0 * delta)
	else:
		empuje = Vector3.ZERO

	if _dash_cooldown > 0.0:
		_dash_cooldown = maxf(0.0, _dash_cooldown - delta)

	# Control de invulnerabilidad temporal (i-frames con parpadeo de modelo)
	if _reloj_invulnerable > 0.0:
		_reloj_invulnerable = maxf(_reloj_invulnerable - delta, 0.0)
		var modelo_nodo = get_node_or_null("Modelo")
		if modelo_nodo != null:
			modelo_nodo.visible = fmod(_reloj_invulnerable, 0.20) < 0.10
			if _reloj_invulnerable <= 0.0:
				modelo_nodo.visible = true

	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var entrada = Vector3(input_dir.x, 0.0, input_dir.y)

	var giro_cam = camara.global_rotation.y if camara != null else 0.0
	var direction = entrada.rotated(Vector3.UP, giro_cam).normalized()

	# Actualizar estado de bloqueo continuo (solo disponible para Guerrero)
	if clase == "Guerrero":
		var presiona_bloqueo = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) \
			or (InputMap.has_action("bloquear") and Input.is_action_pressed("bloquear")) \
			or Input.is_key_pressed(KEY_F) or Input.is_key_pressed(KEY_Q)
		_actualizar_estado_bloqueo(presiona_bloqueo)
	elif bloqueando:
		_actualizar_estado_bloqueo(false)

	var corre = Input.is_action_pressed("correr") and not bloqueando
	var speed = speed_correr if corre else speed_caminar
	if bloqueando:
		speed *= velocidad_bloqueo_multiplicador

	if _dash_tiempo_activo > 0.0:
		_dash_tiempo_activo = maxf(0.0, _dash_tiempo_activo - delta)
		avance = _dash_direccion * (speed_correr * 2.8)
	else:
		var objetivo = direction * speed * multiplicador
		var paso = speed / maxf(0.05, tiempo_arranque) * delta
		avance = avance.move_toward(objetivo, paso)

	velocity.x = avance.x + empuje.x
	velocity.z = avance.z + empuje.z

	if direction.length() > 0:
		basis = Basis.looking_at(direction)

	move_and_slide()

	var antes = estado
	estado = elegir_estado()
	ruido = RUIDO[estado]
	if estado != antes and prueba != 0:
		print("estado ", Estado.keys()[estado], " · ruido ", ruido, " m")

	if _anim_ctrl != null:
		_anim_ctrl.actualizar(delta)
		anim = _anim_ctrl.obtener_animation_player()

	# Manejo de animación de ataque / acción
	if _reloj_anim_accion > 0.0:
		_reloj_anim_accion -= delta
		if _reloj_anim_accion <= 0.0:
			accion = ""

	animar()
	_procesar_autobattler(delta)
	_procesar_incremental_pasivo(delta)
	_procesar_fiebre_y_bendiciones(delta)
	_prueba()

func _procesar_fiebre_y_bendiciones(delta: float):
	if _cooldown_heraldo_fiebre > 0.0:
		_cooldown_heraldo_fiebre = maxf(0.0, _cooldown_heraldo_fiebre - delta)

	if _frenesi_clic_timer > 0.0:
		_frenesi_clic_timer = maxf(0.0, _frenesi_clic_timer - delta)
		if _frenesi_clic_timer <= 0.0:
			_frenesi_clic_stacks = 0

	if medidor_fiebre > 0.0:
		var decay = 6.5
		if bendiciones_run.has("clic_fiebre_eterna"):
			decay *= pow(0.65, float(bendiciones_run["clic_fiebre_eterna"]))
		medidor_fiebre = maxf(0.0, medidor_fiebre - decay * delta)
		_actualizar_escalon_fiebre()

	if bendiciones_run.has("global_estela_fuego") and Vector2(velocity.x, velocity.z).length() > 1.2:
		_temporizador_estela_fuego += delta
		if _temporizador_estela_fuego >= 0.45:
			_temporizador_estela_fuego = 0.0
			var stacks_estela = int(bendiciones_run["global_estela_fuego"])
			_repeler_enemigos_alrededor(2.6, 2.0, dano * 0.45 * float(stacks_estela))

func _actualizar_escalon_fiebre():
	var ant_mult = multiplicador_fiebre_actual
	var ant_over = en_overdrive
	if medidor_fiebre >= 85.0:
		multiplicador_fiebre_actual = 5
		nivel_fiebre = 5
		en_overdrive = true
	elif medidor_fiebre >= 55.0:
		multiplicador_fiebre_actual = 3
		nivel_fiebre = 3
		en_overdrive = false
	elif medidor_fiebre >= 25.0:
		multiplicador_fiebre_actual = 2
		nivel_fiebre = 2
		en_overdrive = false
	else:
		multiplicador_fiebre_actual = 1
		nivel_fiebre = 1
		en_overdrive = false
	if ant_mult != multiplicador_fiebre_actual or ant_over != en_overdrive:
		fiebre_actualizada.emit(medidor_fiebre, multiplicador_fiebre_actual, en_overdrive)

func _obtener_todos_los_enemigos() -> Array:
	var tree = _obtener_tree()
	if tree == null:
		return []
	var lista: Array = []
	for e in tree.get_nodes_in_group("enemigos"):
		if is_instance_valid(e) and not lista.has(e):
			lista.append(e)
	for e in tree.get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not lista.has(e):
			lista.append(e)
	return lista

func _procesar_autobattler(delta: float):
	var mult_cad_fiebre = 1.25 if en_overdrive else (1.10 if multiplicador_fiebre_actual >= 3 else 1.0)
	_reloj_ataque = maxf(_reloj_ataque - delta * mult_cad_fiebre, 0.0)
	if _reloj_ataque <= 0.001:
		var objetivo = _obtener_enemigo_cercano()
		if objetivo != null:
			var d = global_position.distance_to(objetivo.global_position)
			if d <= rango_ataque:
				_ejecutar_ataque(objetivo)
				_reloj_ataque = cadencia_ataque

func _obtener_enemigo_cercano() -> Node3D:
	if not is_inside_tree() or get_tree() == null:
		return null
	var enemigos = _obtener_todos_los_enemigos()
	var mas_cercano: Node3D = null
	var menor_dist = 9999.0
	for e in enemigos:
		if is_instance_valid(e) and e is Node3D:
			var dist = global_position.distance_to(e.global_position)
			if dist < menor_dist:
				menor_dist = dist
				mas_cercano = e
	return mas_cercano

func _ejecutar_ataque(enemigo: Node3D):
	var dir = (enemigo.global_position - global_position).normalized()
	dir.y = 0.0
	if dir.length() > 0.01:
		basis = Basis.looking_at(dir)

	var es_crit = FortunaManager.tirar(prob_critico)
	var mult_frenesi = 1.0 + float(_frenesi_clic_stacks) * frenesi_clic_pct_por_stack
	var mult_coloso_bajo = 1.80 if (keystone_coloso and vida < vida_maxima * 0.50) else 1.0
	var mult_usura_oro = (1.0 + floor(float(oro) / 100.0) * 0.025) if keystone_usura else 1.0
	var dano_ataque_actual = dano * (mult_critico if es_crit else 1.0) * mult_frenesi * mult_coloso_bajo * mult_usura_oro
	var bonus_asc = mejoras_arbol.get("hib_ascension", 0) >= 1 or ascension_suprema

	if clase == "Novato":
		# Corte melee alternado con barrido en arco frontal (Cleave) y tajo luminoso visible
		var clip_melee := "attack-melee-right" if _turno_ataque_novato else "attack-melee-left"
		_turno_ataque_novato = not _turno_ataque_novato
		accion = clip_melee
		_reloj_anim_accion = 0.30
		if _anim_ctrl != null:
			_anim_ctrl.reproducir_accion(clip_melee, 2, 0.05, 1.25)
		_ejecutar_animacion_procedural_ataque("melee")
		_crear_tajo_espada(dir, es_crit)
		AudioManager.play("corte_espada", randf_range(0.95, 1.15))
		
		var dano_melee = dano_ataque_actual
		var rango_cleave = rango_ataque + (0.5 if bonus_asc else 0.0)
		var objetivos: Array = _obtener_todos_los_enemigos()
		objetivos.append_array(get_tree().get_nodes_in_group("rompibles"))
		for e in objetivos:
			if is_instance_valid(e) and e is Node3D:
				var dist = global_position.distance_to(e.global_position)
				if dist <= rango_cleave:
					var hacia_e = (e.global_position - global_position).normalized()
					hacia_e.y = 0.0
					if dir.dot(hacia_e) > (0.20 if bonus_asc else 0.35):
						if e.has_method("recibir_dano"):
							e.recibir_dano(dano_melee, es_crit)
						AudioManager.play("golpe_impacto", randf_range(0.95, 1.15))
	elif clase == "Guerrero":
		# CORTE GIRATORIO MELEE EN ÁREA 360° (Whirlwind)
		_ejecutar_corte_giratorio_guerrero(false, es_crit, dano_ataque_actual)
	elif clase == "Mago":
		# Especialidad Mago: Orbe Arcano teledirigido con detonación en área AOE
		accion = "cast-magic"
		_reloj_anim_accion = 0.28
		if _anim_ctrl != null:
			_anim_ctrl.reproducir_accion("cast-magic", 2, 0.05, 1.1)
		_ejecutar_animacion_procedural_ataque("mago")
		_pulsar_orbe_mago()
		var orbe_escena = load("res://orbe_arcano.tscn")
		if orbe_escena != null:
			var cant_orbes = 1 + (1 if bendiciones_run.get("mago_orbe_triple", 0) > 0 else 0) + int(bendiciones_run.get("mago_orbe_triple", 0))
			var paso_orbe = 14.0
			var inicio_orbe = -((cant_orbes - 1) * paso_orbe) * 0.5
			for i in range(cant_orbes):
				var orbe = orbe_escena.instantiate()
				var origen = global_position + Vector3(0, 0.9, 0)
				var dir_o = dir.rotated(Vector3.UP, deg_to_rad(inicio_orbe + i * paso_orbe)).normalized()
				get_parent().add_child(orbe)
				orbe.iniciar(origen, dir_o, dano_ataque_actual, enemigo)
	else:
		# Especialidad Cazador: Disparo múltiple de flechas (Multishot) en abanico
		accion = "shoot-bow"
		_reloj_anim_accion = 0.22
		if _anim_ctrl != null:
			_anim_ctrl.reproducir_accion("shoot-bow", 2, 0.05, 1.15)
		_ejecutar_animacion_procedural_ataque("arco")
		AudioManager.play("disparo_arco", randf_range(0.95, 1.15))

		var cant_flechas = 2
		var angulo_paso = 12.0
		if nivel >= 6:
			cant_flechas = 4
			angulo_paso = 9.0
		elif nivel >= 3:
			cant_flechas = 3
			angulo_paso = 11.0
		if bonus_asc:
			cant_flechas += 2
		cant_flechas += proyectiles_extra

		var perforaciones = (1 if nivel < 5 else 2) + (2 if bonus_asc else 0) + perforacion_armas
		var vel_flecha = 16.0
		var dano_flecha = dano_ataque_actual * 0.68
		var origen = global_position + Vector3(0, 0.9, 0)
		var proyectil_escena = load("res://proyectil.tscn")

		if proyectil_escena != null:
			var angulo_inicio = -((cant_flechas - 1) * angulo_paso) * 0.5
			for i in range(cant_flechas):
				var angulo = angulo_inicio + (i * angulo_paso)
				var dir_flecha = dir.rotated(Vector3.UP, deg_to_rad(angulo)).normalized()
				var p = proyectil_escena.instantiate()
				get_parent().add_child(p)
				if "rebotes_restantes" in p:
					p.rebotes_restantes = rebotes_armas
				p.iniciar(origen, dir_flecha, dano_flecha, vel_flecha, perforaciones)

func click_attack():
	# El combate es 100% automático (Autobattler continuo por proximidad).
	# La única interacción de clic permitida en el juego es sobre el Botón Móvil 3D.
	pass

func _ejecutar_animacion_procedural_ataque(tipo_ataque: String):
	var mod = get_node_or_null("Modelo") as Node3D
	if mod == null:
		return
	if _tween_modelo_ataque != null and _tween_modelo_ataque.is_valid():
		_tween_modelo_ataque.kill()
		mod.position = _modelo_pos_base
		mod.rotation = _modelo_rot_base
	_tween_modelo_ataque = create_tween()
	match tipo_ataque:
		"melee":
			# Embestida frontal (-Z local) y retorno sin deriva acumulativa
			_tween_modelo_ataque.tween_property(mod, "position:z", _modelo_pos_base.z - 0.28, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tween_modelo_ataque.tween_property(mod, "position:z", _modelo_pos_base.z, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"arco":
			# Breve retroceso al tensar (+Z) y proyección al soltar (-Z)
			_tween_modelo_ataque.tween_property(mod, "position:z", _modelo_pos_base.z + 0.12, 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tween_modelo_ataque.tween_property(mod, "position:z", _modelo_pos_base.z - 0.10, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tween_modelo_ataque.tween_property(mod, "position:z", _modelo_pos_base.z, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"mago":
			# Elevación de levitación mística
			_tween_modelo_ataque.tween_property(mod, "position:y", _modelo_pos_base.y + 0.24, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tween_modelo_ataque.tween_property(mod, "position:y", _modelo_pos_base.y, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _pulsar_orbe_mago() -> void:
	if _luz_orbe_ref != null and is_instance_valid(_luz_orbe_ref):
		var tw_luz = create_tween()
		tw_luz.tween_property(_luz_orbe_ref, "light_energy", 3.6, 0.08)
		tw_luz.tween_property(_luz_orbe_ref, "light_energy", 1.6, 0.18)

func _crear_tajo_espada(dir_ataque: Vector3, es_critico: bool = false):
	if not is_inside_tree() or get_parent() == null:
		return
	var tajo = Node3D.new()
	get_parent().add_child(tajo)
	var altura = global_position.y + 0.9
	tajo.global_position = Vector3(global_position.x, altura, global_position.z) + dir_ataque * 1.0

	if dir_ataque.length_squared() > 0.001 and absf(dir_ataque.dot(Vector3.UP)) < 0.999:
		tajo.look_at(tajo.global_position + dir_ataque, Vector3.UP)

	var mesh_inst = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.45

	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var color_base = Color(1.0, 0.88, 0.25, 0.95) if es_critico else (Color(1.0, 0.55, 0.15, 0.95) if clase == "Guerrero" else Color(0.35, 0.85, 1.0, 0.95))
	mat.albedo_color = color_base
	torus.material = mat
	mesh_inst.mesh = torus

	mesh_inst.scale = Vector3(1.4, 0.05, 0.8)
	mesh_inst.position = Vector3(0, 0, -0.3)
	tajo.add_child(mesh_inst)

	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(mesh_inst, "scale", Vector3(2.6, 0.03, 1.7), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mesh_inst, "position:z", -1.2, 0.16)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.16)
	tw.chain().tween_callback(tajo.queue_free)

func recibir_dano(cantidad: float):
	if _reloj_invulnerable > 0.0 or _muerto_definitivo:
		if bloqueo_genera_clics > 0:
			clics_disponibles += bloqueo_genera_clics
			clics_totales += bloqueo_genera_clics
			emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)
		return

	# Esquiva pasiva del árbol
	if prob_esquiva > 0.0 and FortunaManager.tirar(prob_esquiva):
		_spawn_texto_3d("💨 ¡ESQUIVADO!", Color(0.5, 0.95, 1.0))
		if bloqueo_genera_clics > 0:
			clics_disponibles += bloqueo_genera_clics
			clics_totales += bloqueo_genera_clics
		return

	# 1. Mitigación Pasiva por Armadura Rúnica y Constitución (Fórmula asintótica PoE)
	var mitigacion_armadura = armadura_plana / (armadura_plana + 120.0)
	var mitigacion_total = clampf(mitigacion_pasiva_pct + mitigacion_armadura, 0.0, 0.78)
	cantidad *= (1.0 - mitigacion_total)

	# 2. Mitigación por Bloqueo Activo de Escudo (Mecánica Tanque del Guerrero)
	if bloqueando and clase == "Guerrero":
		var dano_mitigado = cantidad * (1.0 - reduccion_dano_bloqueo)
		var mitigado_total = cantidad - dano_mitigado
		AudioManager.play("escudo_bloqueo", randf_range(0.95, 1.05))

		if bloqueo_genera_clics > 0:
			clics_disponibles += bloqueo_genera_clics
			clics_totales += bloqueo_genera_clics
			emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)

		_parpadear_escudo()
		_mostrar_feedback_bloqueo(mitigado_total, dano_mitigado)
		var dano_espinas_bloq = mitigado_total * (1.5 if bendiciones_run.has("guerrero_espinas_titan") else 0.4)
		_repeler_enemigos_alrededor(3.2, 6.5, dano_espinas_bloq)

		cantidad = dano_mitigado
		if cantidad <= 0.0:
			return

	# 3. Retribución de Espinas (Devuelve daño alrededor)
	if reflejo_dano_pct > 0.0 or bendiciones_run.has("guerrero_espinas_titan"):
		var d_ref = cantidad * (reflejo_dano_pct + float(bendiciones_run.get("guerrero_espinas_titan", 0)) * 0.65)
		_repeler_enemigos_alrededor(3.8, 4.5, d_ref)

	# 4. Absorción por Escudo de Almas (Aegis)
	if escudo_almas > 0.0:
		if escudo_almas >= cantidad:
			escudo_almas -= cantidad
			cantidad = 0.0
		else:
			cantidad -= escudo_almas
			escudo_almas = 0.0
		if cantidad <= 0.0:
			AudioManager.play("escudo_bloqueo", 1.25)
			emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
			return

	# 5. Keystones Supremos Preventivos de Muerte (Último Aliento y Armadura de Oro Líquido)
	if vida - cantidad <= 0.0:
		if keystone_oro_liquido and oro >= 150:
			oro -= 150
			vida = maxf(vida_maxima * 0.35, 1.0)
			_reloj_invulnerable = 2.0
			AudioManager.play("altar_activado", 1.25, 2.0)
			_spawn_texto_3d("🪙 ¡ORO LÍQUIDO ABSORBIÓ EL IMPACTO!", Color(1.0, 0.85, 0.2))
			emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
			emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)
			return
		if keystone_aliento and _cooldown_ultimo_aliento <= 0.0:
			vida = 1.0
			_reloj_invulnerable = 3.5
			_cooldown_ultimo_aliento = 90.0
			_repeler_enemigos_alrededor(10.0, 14.0, dano * 2.0)
			AudioManager.play("altar_activado", 1.4, 3.0)
			_spawn_texto_3d("🔥 ¡ÚLTIMO ALIENTO ACTIVADO! (3.5s Invulnerable)", Color(1.0, 0.45, 0.15))
			emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
			return

	vida = maxf(vida - cantidad, 0.0)
	if vida > 0.0 and cantidad > 0.0:
		_reloj_invulnerable = maxf(_reloj_invulnerable, 0.45 + minf(bonus_invulnerable_seg * 0.25, 0.45))
	AudioManager.play("danio_jugador", randf_range(0.9, 1.1))
	var tree_dmg = _obtener_tree()
	if tree_dmg != null:
		var pool_dmg = tree_dmg.get_first_node_in_group("damage_numbers")
		if pool_dmg != null and pool_dmg.has_method("mostrar_dano"):
			pool_dmg.mostrar_dano(global_position + Vector3(0, 1.9, 0), int(round(cantidad)), false, "jugador_herido")
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	if vida <= 0.0:
		_procesar_caida_jugador()

func ganar_xp(cantidad: int):
	if cantidad <= 0:
		return
	var xp_final = int(ceil(float(cantidad) * (1.0 + xp_ganada_pct)))
	xp += xp_final
	if xp_a_oro_pct > 0.0:
		var oro_alquimia = max(1, int(ceil(float(xp_final) * xp_a_oro_pct)))
		oro += oro_alquimia
	while xp >= xp_siguiente_nivel:
		subir_nivel()
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)

func recoger_drop(tipo: int, valor: int):
	match tipo:
		0: # ORO
			var bonus_mult = (1.0 + oro_por_baja_pct + (float(mejoras_arbol.get("mon_oro", 0)) * 0.25)) * float(multiplicador_fiebre_actual)
			if ascension_suprema:
				bonus_mult *= 2.0
			if orbes_oro_duplicados_pct > 0.0 and FortunaManager.tirar(orbes_oro_duplicados_pct):
				bonus_mult *= 2.0
			oro += int(ceil(float(valor) * bonus_mult))
		1: # EXP
			ganar_xp(valor)
			return
		2: # CORAZON
			var curacion = float(valor)
			if vida + curacion > vida_maxima and keystone_bucle:
				var exceso = int(ceil((vida + curacion - vida_maxima) * 0.5))
				clics_disponibles += max(1, exceso)
				clics_totales += max(1, exceso)
			vida = minf(vida + curacion, vida_maxima)
		3: # TREBOL: suerte permanente durante la run
			var ganancia_trebol: float = 0.05 * maxi(1, valor)
			suerte += ganancia_trebol
			suerte_cambiada.emit(obtener_suerte_total())
			_spawn_texto_3d("🍀 ¡TRÉBOL! +%.2f Suerte" % ganancia_trebol, Color(0.2, 1.0, 0.35))
			AudioManager.play("jackpot", 1.2)
		4: # IMAN: atrae todos los drops de la arena
			_atraer_todos_los_drops()
			_spawn_texto_3d("🧲 ¡VÓRTICE MAGNÉTICO!", Color(0.3, 0.85, 1.0))
			AudioManager.play("altar_activado", 1.3)
		5: # BOMBA: detonación en área
			_detonar_bomba_drop()
			_spawn_texto_3d("💣 ¡DETONACIÓN!", Color(1.0, 0.35, 0.1))
		6: # DENARIO: moneda de la run
			ganar_denarios(maxi(1, valor))
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)

func registrar_baja():
	bajas += 1
	AudioManager.play("enemigo_muerte", randf_range(0.9, 1.2))
	if vida_por_baja > 0.0:
		if vida + vida_por_baja > vida_maxima and keystone_bucle:
			clics_disponibles += 1
			clics_totales += 1
		vida = minf(vida + vida_por_baja, vida_maxima)
	ganar_xp(6)
	recoger_drop(0, 3)
	if evolucion_manager != null and evolucion_manager.has_method("notificar_baja"):
		evolucion_manager.notificar_baja()

func subir_nivel():
	xp = max(0, xp - xp_siguiente_nivel)
	nivel += 1
	xp_siguiente_nivel = int(round(float(xp_siguiente_nivel) * 1.30 + 10.0))

	# Escalado de especialidades por clase al subir nivel
	if clase == "Cazador":
		base_cadencia_ataque = maxf(0.18, base_cadencia_ataque * 0.94)
		base_dano *= 1.08
	elif clase == "Guerrero":
		base_dano *= 1.10
		base_rango_ataque = minf(3.8, base_rango_ataque + 0.05)
	elif clase == "Mago":
		base_dano *= 1.12
	else:
		base_dano *= 1.08
		base_cadencia_ataque = maxf(0.45, base_cadencia_ataque * 0.96)

	recalcular_stats_incrementales()
	vida = minf(vida + maxf(20.0, vida_maxima * 0.25), vida_maxima)
	AudioManager.play("altar_activado", 1.35, 0.0)
	var dop = get_tree().get_first_node_in_group("audio_dopamina") if is_inside_tree() else null
	if dop != null and dop.has_method("reproducir_acorde_nivel"):
		dop.reproducir_acorde_nivel()
	_spawn_texto_3d("⭐ ¡NIVEL %d!" % nivel, Color(0.95, 0.85, 0.25))

	if evolucion_manager != null:
		evolucion_manager.notificar_nivel(nivel)
	emit_signal("nivel_subido", nivel)
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)

	# Mostrar selector de 3 cartas Roguelike en ClickHUD si no está evolucionando en este preciso frame
	if is_inside_tree() and get_tree() != null:
		var hud = get_tree().get_first_node_in_group("click_hud")
		if hud == null and get_parent() != null:
			hud = get_parent().get_node_or_null("ClickHUD")
		if hud != null and hud.has_method("mostrar_selector_bendiciones"):
			hud.mostrar_selector_bendiciones(nivel)

func aplicar_bendicion_roguelike(id_bendicion: String):
	if id_bendicion == "":
		return
	var repeticiones: int = 2 if duplicar_proxima_carta else 1
	duplicar_proxima_carta = false

	var stacks_prev = int(bendiciones_run.get(id_bendicion, 0))
	bendiciones_run[id_bendicion] = stacks_prev + repeticiones

	var datos_b = CatalogoBendicionesScript.obtener_bendicion(id_bendicion)
	var nom_b = str(datos_b.get("nombre", id_bendicion))
	_spawn_texto_3d("✨ %s (Nv.%d)" % [nom_b, int(bendiciones_run[id_bendicion])], Color(0.35, 0.95, 1.0))
	bendicion_adquirida.emit(id_bendicion, int(bendiciones_run[id_bendicion]))

	# Verificar desbloqueo automático de Sinergias Duales
	var nuevas_sinergias = CatalogoBendicionesScript.verificar_nuevas_sinergias(bendiciones_run, sinergias_activas)
	for sin_data in nuevas_sinergias:
		var s_id = str(sin_data.get("id", ""))
		if s_id != "" and not sinergias_activas.has(s_id):
			sinergias_activas.append(s_id)
			_spawn_texto_3d("🔥 ¡SINERGIA DUAL: %s!" % str(sin_data.get("nombre", s_id)).to_upper(), Color(1.0, 0.78, 0.2))
			AudioManager.play("legendario", 1.25)

	recalcular_stats_incrementales()

func registrar_bono_cofre_dorado(tipo: String, valor: float):
	match tipo:
		"dano_plana":
			bono_run_dano_plana += valor
		"dano_mult":
			bono_run_dano_mult *= (1.0 + valor)
		"vida_plana":
			bono_run_vida_plana += valor
		"velocidad_plana":
			bono_run_vel_plana += valor
		"cadencia_mult":
			bono_run_cadencia_mult *= maxf(0.5, 1.0 - valor)
		"crit_prob":
			bono_run_crit_prob += valor
		"armadura":
			bono_run_armadura_plana += valor
		"proyectiles":
			bono_run_proyectiles_extra += int(round(valor))
		_:
			bono_run_dano_plana += valor
	recalcular_stats_incrementales()
	vida = minf(vida + maxf(25.0, valor), vida_maxima)
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

func aplicar_interes_oleada():
	var pct_total = interes_oleada_pct
	if keystone_usura:
		pct_total += 0.20
	if bendiciones_run.has("global_interes_compuesto"):
		pct_total += float(bendiciones_run["global_interes_compuesto"]) * 0.08
	if pct_total <= 0.0 or oro <= 0:
		return
	var dividendo = max(1, int(round(float(oro) * pct_total)))
	oro += dividendo
	_spawn_texto_3d("📈 ¡DIVIDENDO DE OLEADA: +%d ORO!" % dividendo, Color(1.0, 0.88, 0.25))
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)

func obtener_efecto_nodo(id_nodo: String) -> float:
	var lvl = int(mejoras_arbol.get(id_nodo, 0))
	if lvl <= 0:
		return 0.0
	var arbol_nodos = ArbolInterconectadoDatos.generar_arbol()
	if arbol_nodos.has(id_nodo):
		var n: SkillNodeData = arbol_nodos[id_nodo]
		return n.valor_por_nivel * float(lvl)
	return float(lvl)

## Vista previa visual temporal mientras el jugador sobrevuela una clase en el menú radial
func mostrar_preview_clase(nombre_clase: String):
	var clase_mostrar := nombre_clase if not nombre_clase.is_empty() else clase
	equipar_armas_clase(clase_mostrar)
	if _escudo_visual != null:
		_escudo_visual.visible = (nombre_clase == "Guerrero" or (clase == "Guerrero" and bloqueando))

func _asegurar_armas_preview():
	equipar_armas_clase(clase)

func aplicar_clase(nombre: String):
	var ratio_vida_prev = clampf(vida / maxf(1.0, vida_maxima), 0.65, 1.0)
	clase = nombre
	if clase != "Guerrero":
		if bloqueando:
			_actualizar_estado_bloqueo(false)
		if _escudo_visual != null:
			_escudo_visual.visible = false
	else:
		_crear_escudo_visual()
	match nombre:
		"Novato":
			base_vida_maxima = 100.0
			base_dano = 12.0
			base_rango_ataque = 2.6
			base_cadencia_ataque = 0.85
			base_speed_caminar = 3.4
			base_speed_correr = 5.4
		"Guerrero":
			base_vida_maxima = 160.0
			base_dano = 22.0
			base_rango_ataque = 3.2
			base_cadencia_ataque = 0.70
			base_speed_caminar = 3.2
			base_speed_correr = 5.6
		"Cazador":
			base_vida_maxima = 100.0
			base_dano = 14.0
			base_rango_ataque = 7.5
			base_cadencia_ataque = 0.45
			base_speed_caminar = 3.8
			base_speed_correr = 6.4
		"Mago":
			base_vida_maxima = 85.0
			base_dano = 28.0
			base_rango_ataque = 5.5
			base_cadencia_ataque = 0.90
			base_speed_caminar = 3.3
			base_speed_correr = 5.7
	# Recalcular preservando 100% de los bonos de run y árbol
	equipar_armas_clase(nombre)
	recalcular_stats_incrementales()
	vida = maxf(vida_maxima * ratio_vida_prev, base_vida_maxima)
	vida = minf(vida, vida_maxima)

func aplicar_mejora(tipo_mejora: String, mult_rareza: float = 1.0):
	var repeticiones: int = 2 if duplicar_proxima_carta else 1
	duplicar_proxima_carta = false
	for _i in range(repeticiones):
		_aplicar_mejora_interna(tipo_mejora, mult_rareza)
	recalcular_stats_incrementales()
	if tipo_mejora == "vida":
		vida = minf(vida + 20.0 * mult_rareza * repeticiones, vida_maxima)
		emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

func equipar_build_test_parca():
	print(">>> [TEST] Equipando build de supervivencia para testear a La Parca Roja <<<")
	if clase == "Novato":
		aplicar_clase("Guerrero")
	nivel = 15
	base_vida_maxima = maxf(base_vida_maxima, 280.0)
	base_dano = maxf(base_dano, 42.0)
	base_cadencia_ataque = minf(base_cadencia_ataque, 0.35)
	base_rango_ataque = maxf(base_rango_ataque, 4.0)
	base_speed_caminar = maxf(base_speed_caminar, 4.2)
	base_speed_correr = maxf(base_speed_correr, 6.8)
	reapariciones = 3
	_muerto_definitivo = false
	mejoras_arbol["mon_dano"] = 4
	mejoras_arbol["mon_vida"] = 3
	mejoras_arbol["mon_vel"] = 3
	mejoras_arbol["mon_cadencia"] = 3
	mejoras_arbol["clk_critico"] = 2
	mejoras_arbol["hib_ascension"] = 1
	recalcular_stats_incrementales()
	vida = vida_maxima
	if has_node("Salud"):
		var s = get_node("Salud")
		s.vida = int(vida)
		if "vida_inicial" in s:
			s.vida_inicial = int(vida)
		s.reapariciones = reapariciones
		s.cambio.emit(s.vida)
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	AudioManager.play("altar_activado", 1.25, 2.0)
	_spawn_texto_3d("⚡ ¡BUILD DE SUPERVIVENCIA EQUIPADA!", Color(1.0, 0.88, 0.25))

# ==============================================================================
# SISTEMA INCREMENTAL: CÁLCULOS EN 4 CAPAS (CLASE + ÁRBOL + BONOS RUN + BENDICIONES)
# ==============================================================================

func recalcular_stats_incrementales():
	# 1. Reiniciar acumuladores desde la Capa 1 (Base de Clase)
	dano = base_dano + bono_run_dano_plana
	cadencia_ataque = base_cadencia_ataque * bono_run_cadencia_mult
	rango_ataque = base_rango_ataque
	speed_caminar = base_speed_caminar + bono_run_vel_plana
	speed_correr = base_speed_correr + bono_run_vel_plana
	prob_critico = 0.05 + bonus_nivel_critico + bono_run_crit_prob
	mult_critico = 2.0 + bono_run_crit_mult

	# 2. Resetear acumuladores del Árbol de Constelaciones
	bonus_vidas_arbol = 0
	escudo_almas = 0.0
	max_escudo_almas = 0.0
	armadura_plana = bono_run_armadura_plana
	mitigacion_pasiva_pct = 0.0
	prob_esquiva = 0.0
	bonus_dano_pct = 0.0
	bonus_dano_armas_pct = 0.0
	bonus_dano_clic_pct = 0.0
	clics_por_pulsacion = 1
	bonus_radio_aoe_clic = 0.0
	bonus_empuje_clic_pct = 0.0
	bonus_eco_clic_prob = 0.0
	bonus_critico_clic_prob = 0.0
	bonus_dano_critico_pct = 0.0
	bonus_velocidad_mov_pct = 0.0
	radio_iman_extra = 0.0
	regen_vida_seg = 0.0
	vida_por_baja = 0.0
	bonus_invulnerable_seg = 0.0
	reflejo_dano_pct = 0.0
	oro_por_baja_pct = 0.0
	xp_ganada_pct = 0.0
	bonus_cadencia_pct = 0.0
	autoclick_tasa = 0.0
	proyectiles_extra = bono_run_proyectiles_extra
	perforacion_armas = bono_run_perforacion_extra
	rebotes_armas = bono_run_rebotes_extra
	oro_pasivo_seg = 0.0
	interes_oleada_pct = 0.0
	clic_cura_escudo = 0.0
	xp_a_oro_pct = 0.0
	clic_genera_oro_pct = 0.0
	tempestad_oro_dmg = 0.0
	suerte_arbol = 0.0

	prob_anomalia_extra_pct = 0.0
	dano_sobrecarga_extra = 0.0
	frenesi_clic_pct_por_stack = 0.0
	penetracion_clic_pct = 0.0
	resistencia_estados_pct = 0.0
	bloqueo_genera_clics = 0
	orbes_oro_duplicados_pct = 0.0
	detonacion_oro_pct = 0.0
	terremoto_clic_vida = 0
	oro_salud_conversion = 0

	# Keystones Supremos
	keystone_cataclismo = false
	keystone_soberania = false
	keystone_segunda_vida = false
	keystone_coloso = false
	keystone_aliento = false
	keystone_usura = false
	keystone_fabrica = false
	keystone_bucle = false
	keystone_oro_liquido = false
	keystone_zenit = false
	ascension_suprema = false

	var bonus_vida_plana: float = bono_run_vida_plana

	# 3. Mapeo completo de los 55 nodos de ArbolInterconectadoDatos
	var arbol_nodos = ArbolInterconectadoDatos.generar_arbol()
	for id in mejoras_arbol.keys():
		var lvl = int(mejoras_arbol[id])
		if lvl <= 0 or not arbol_nodos.has(id):
			continue
		var nodo: SkillNodeData = arbol_nodos[id]
		var val = nodo.valor_por_nivel * float(lvl)

		match nodo.estadistica_afectada:
			"salud_maxima":
				bonus_vida_plana += val
			"mitigacion_dano_pct":
				mitigacion_pasiva_pct += (val * 0.01)
			"armadura_plana":
				armadura_plana += val
			"escudo_almas":
				max_escudo_almas += val
			"vidas_extra":
				bonus_vidas_arbol += int(val)
			"keystone_segunda_vida":
				bonus_vidas_arbol += 1
				keystone_segunda_vida = true
			"velocidad_mov_pct":
				bonus_velocidad_mov_pct += (val * 0.01)
			"radio_iman":
				radio_iman_extra += val
			"regen_vida_seg":
				regen_vida_seg += val
			"vida_por_baja":
				vida_por_baja += val
			"invulnerable_extra_seg":
				bonus_invulnerable_seg += val
			"reflejo_dano_pct":
				reflejo_dano_pct += (val * 0.01)
			"dano_clic_pct":
				bonus_dano_clic_pct += (val * 0.01)
			"clics_por_pulsacion":
				clics_por_pulsacion += int(val)
			"radio_aoe_clic":
				bonus_radio_aoe_clic += val
			"empuje_clic_pct":
				bonus_empuje_clic_pct += (val * 0.01)
			"critico_clic_prob":
				bonus_critico_clic_prob += (val * 0.01)
				prob_critico += (val * 0.01)
			"dano_critico_pct":
				bonus_dano_critico_pct += (val * 0.01)
				mult_critico += (val * 0.01)
			"eco_clic_prob":
				bonus_eco_clic_prob += (val * 0.01)
			"oro_por_baja_pct":
				oro_por_baja_pct += (val * 0.01)
			"xp_ganada_pct":
				xp_ganada_pct += (val * 0.01)
			"cadencia_armas_pct":
				bonus_cadencia_pct += (val * 0.01)
			"dano_armas_pct":
				bonus_dano_armas_pct += (val * 0.01)
			"autoclick_tasa":
				autoclick_tasa += val
			"autoclick_overclock_pct":
				autoclick_tasa *= (1.0 + (val * 0.01))
			"proyectiles_extra":
				proyectiles_extra += int(val)
			"perforacion_armas":
				perforacion_armas += int(val)
			"rango_ataque_pct":
				rango_ataque *= (1.0 + (val * 0.01))
			"oro_pasivo_seg":
				oro_pasivo_seg += val
			"interes_oleada_pct":
				interes_oleada_pct += (val * 0.01)
			"clic_cura_escudo":
				clic_cura_escudo += val
			"xp_a_oro_pct":
				xp_a_oro_pct += (val * 0.01)
			"clic_genera_oro_pct":
				clic_genera_oro_pct += (val * 0.01)
			"tempestad_oro_dmg":
				tempestad_oro_dmg += val
			"suerte":
				suerte_arbol += val
			"prob_anomalia_pct":
				prob_anomalia_extra_pct += (val * 0.01)
			"dano_sobrecarga":
				dano_sobrecarga_extra += val
			"frenesi_velocidad_clic":
				frenesi_clic_pct_por_stack += (val * 0.01)
			"penetracion_clic":
				penetracion_clic_pct += (val * 0.01)
			"resistencia_estados_pct":
				resistencia_estados_pct += (val * 0.01)
			"bloqueo_genera_clics":
				bloqueo_genera_clics += int(val)
			"orbes_oro_duplicados_pct":
				orbes_oro_duplicados_pct += (val * 0.01)
			"detonacion_oro_pct":
				detonacion_oro_pct += (val * 0.01)
			"terremoto_clic_vida":
				terremoto_clic_vida += int(val)
			"oro_salud_conversion":
				oro_salud_conversion += int(val)
			"keystone_cataclismo":
				keystone_cataclismo = true
			"keystone_soberania":
				keystone_soberania = true
			"keystone_coloso":
				keystone_coloso = true
			"keystone_aliento":
				keystone_aliento = true
			"keystone_usura":
				keystone_usura = true
			"keystone_fabrica":
				keystone_fabrica = true
				autoclick_tasa = maxf(autoclick_tasa, 6.0)
			"keystone_bucle":
				keystone_bucle = true
			"keystone_oro_liquido":
				keystone_oro_liquido = true
			"keystone_zenit":
				keystone_zenit = true
				mult_critico = maxf(mult_critico, 3.0)
			"ascension_suprema":
				ascension_suprema = true

	# 4. Conexión completa de IDs legacy y directos (ArbolMejorasDatos + alias)
	bonus_dano_pct += float(mejoras_arbol.get("mon_dano", 0)) * 0.18
	bonus_vida_plana += float(mejoras_arbol.get("mon_vida", 0)) * 25.0
	bonus_velocidad_mov_pct += float(mejoras_arbol.get("mon_vel", 0)) * 0.10
	oro_por_baja_pct += float(mejoras_arbol.get("mon_oro", 0)) * 0.25
	bonus_cadencia_pct += float(mejoras_arbol.get("mon_cadencia", 0)) * 0.12
	oro_pasivo_seg += float(mejoras_arbol.get("mon_pasivo", 0)) * 1.0
	clics_por_pulsacion += int(mejoras_arbol.get("clk_potencia", 0))
	bonus_radio_aoe_clic += float(mejoras_arbol.get("clk_onda", 0)) * 0.8
	bonus_dano_clic_pct += float(mejoras_arbol.get("clk_onda", 0)) * 0.35
	radio_iman_extra += float(mejoras_arbol.get("clk_iman", 0)) * 2.5
	autoclick_tasa += float(mejoras_arbol.get("clk_pasivo", 0)) * 0.4
	prob_critico += float(mejoras_arbol.get("clk_critico", 0)) * 0.08
	clic_genera_oro_pct += float(mejoras_arbol.get("hib_alquimia", 0)) * 0.15
	bonus_vidas_arbol += int(mejoras_arbol.get("hib_pacto", 0))
	mult_critico += float(mejoras_arbol.get("hib_filo_crit", 0)) * 0.60
	if int(mejoras_arbol.get("hib_ascension", 0)) >= 1:
		bonus_dano_pct += 0.75
		perforacion_armas += 2

	# Alias adicionales de nodos PoE
	bonus_dano_clic_pct += float(mejoras_arbol.get("clic_combo", 0)) * 0.15
	mitigacion_pasiva_pct += float(mejoras_arbol.get("def_reduccion", 0)) * 0.05
	prob_esquiva += float(mejoras_arbol.get("def_esquiva", 0)) * 0.05
	bonus_velocidad_mov_pct += float(mejoras_arbol.get("mov_vel", 0)) * 0.08
	radio_iman_extra += float(mejoras_arbol.get("mov_iman", 0)) * 2.5
	regen_vida_seg += float(mejoras_arbol.get("def_regen", 0)) * 1.5
	oro_por_baja_pct += float(mejoras_arbol.get("eco_oro_base", 0)) * 0.20
	xp_ganada_pct += float(mejoras_arbol.get("eco_xp_base", 0)) * 0.18
	suerte_arbol += float(mejoras_arbol.get("eco_suerte", 0)) * 0.05
	interes_oleada_pct += float(mejoras_arbol.get("eco_interes", 0)) * 0.06

	# 5. Capa 4: Aplicar las 24 Bendiciones Roguelike y 6 Sinergias Duales (CatalogoBendiciones + alias)
	var b_multidisparo = int(bendiciones_run.get("prisma_multidisparo", 0)) + int(bendiciones_run.get("cazador_lluvia_flechas", 0))
	if b_multidisparo > 0:
		proyectiles_extra += b_multidisparo

	var b_perforante = int(bendiciones_run.get("municion_perforante", 0)) + int(bendiciones_run.get("cazador_flecha_perforante", 0))
	if b_perforante > 0:
		perforacion_armas += 2 * b_perforante
		bonus_dano_armas_pct += 0.15 * float(b_perforante)

	var b_rebote = int(bendiciones_run.get("cadena_rayos", 0)) + int(bendiciones_run.get("cazador_rebote_ricochet", 0))
	if b_rebote > 0:
		rebotes_armas += b_rebote

	var b_crit = int(bendiciones_run.get("lentes_critico", 0)) + int(bendiciones_run.get("cazador_critico_letal", 0))
	if b_crit > 0:
		prob_critico += 0.10 * float(b_crit)
		mult_critico += 0.35 * float(b_crit)

	var b_fuego = int(bendiciones_run.get("anillo_fuego", 0)) + int(bendiciones_run.get("guerrero_torbellino_ignifugo", 0))
	if b_fuego > 0:
		rango_ataque += 0.8 * float(b_fuego)
		bonus_dano_pct += 0.25 * float(b_fuego)

	var b_sangre = int(bendiciones_run.get("sangre_coloso", 0)) + int(bendiciones_run.get("guerrero_sangre_hierro", 0))
	if b_sangre > 0:
		bonus_vida_plana += 40.0 * float(b_sangre)
		regen_vida_seg += 2.5 * float(b_sangre)

	var b_espinas = int(bendiciones_run.get("escudo_espinas", 0))
	if b_espinas > 0:
		armadura_plana += 20.0 * float(b_espinas)
		reflejo_dano_pct += 0.35 * float(b_espinas)

	var b_vamp = int(bendiciones_run.get("vampirismo_runico", 0)) + int(bendiciones_run.get("guerrero_vampirismo_brutal", 0))
	if b_vamp > 0:
		vida_por_baja += 4.0 * float(b_vamp)

	var b_meteoro = int(bendiciones_run.get("meteoro_orbital", 0)) + int(bendiciones_run.get("mago_supernova_arcana", 0))
	if b_meteoro > 0:
		bonus_dano_armas_pct += 0.35 * float(b_meteoro)

	var b_pulso = int(bendiciones_run.get("pulso_estatico", 0)) + int(bendiciones_run.get("mago_sobrecarga_cristal", 0))
	if b_pulso > 0:
		bonus_cadencia_pct += 0.18 * float(b_pulso)

	var b_sed = int(bendiciones_run.get("sed_de_sangre", 0))
	if b_sed > 0:
		bonus_cadencia_pct += 0.14 * float(b_sed)
		bonus_dano_armas_pct += 0.15 * float(b_sed)

	var b_hilo = int(bendiciones_run.get("sobrecarga_hilo", 0)) + int(bendiciones_run.get("clic_resonancia_conductora", 0))
	if b_hilo > 0:
		bonus_dano_clic_pct += 0.35 * float(b_hilo)

	var b_fiebre = int(bendiciones_run.get("fiebre_perpetua", 0)) + int(bendiciones_run.get("clic_ritmo_perfecto", 0))
	if b_fiebre > 0:
		bonus_critico_clic_prob += 0.15 * float(b_fiebre)
		bonus_dano_clic_pct += 0.30 * float(b_fiebre)

	var b_eco = int(bendiciones_run.get("eco_clic", 0))
	if b_eco > 0:
		bonus_eco_clic_prob += 0.20 * float(b_eco)

	var b_iman = int(bendiciones_run.get("iman_gravitatorio", 0)) + int(bendiciones_run.get("clic_iman_cinetico", 0))
	if b_iman > 0:
		radio_iman_extra += 3.0 * float(b_iman)
		bonus_velocidad_mov_pct += 0.10 * float(b_iman)

	var b_botas = int(bendiciones_run.get("botas_relampago", 0))
	if b_botas > 0:
		bonus_velocidad_mov_pct += 0.15 * float(b_botas)

	var b_paso = int(bendiciones_run.get("paso_etereo", 0))
	if b_paso > 0:
		prob_esquiva += 0.10 * float(b_paso)
		bonus_invulnerable_seg += 0.4 * float(b_paso)
		bonus_velocidad_mov_pct += 0.12 * float(b_paso)

	var b_supernova = int(bendiciones_run.get("supernova_inestable", 0))
	if b_supernova > 0:
		bonus_radio_aoe_clic += 1.8 * float(b_supernova)
		bonus_empuje_clic_pct += 0.30 * float(b_supernova)

	var b_nova = int(bendiciones_run.get("nova_helada", 0))
	if b_nova > 0:
		bonus_radio_aoe_clic += 1.2 * float(b_nova)

	var b_moneda = int(bendiciones_run.get("moneda_maldita", 0))
	if b_moneda > 0:
		oro_por_baja_pct += 0.30 * float(b_moneda)
		interes_oleada_pct += 0.08 * float(b_moneda)

	var b_midas = int(bendiciones_run.get("toque_de_midas", 0))
	if b_midas > 0:
		clic_genera_oro_pct += 0.25 * float(b_midas)
		xp_ganada_pct += 0.25 * float(b_midas)

	var b_canon = int(bendiciones_run.get("canon_mercenario", 0)) + int(bendiciones_run.get("global_ejecutor_jefes", 0))
	if b_canon > 0:
		bonus_dano_pct += 0.22 * float(b_canon) + clampf(floor(float(oro) / 50.0) * 0.04 * float(b_canon), 0.0, 2.0)

	var b_corazon = int(bendiciones_run.get("corazon_runico", 0)) + int(bendiciones_run.get("global_armadura_reactiva", 0))
	if b_corazon > 0:
		max_escudo_almas += 45.0 * float(b_corazon)

	# Sinergias Duales Activas (IDs de CatalogoBendiciones + alias)
	if sinergias_activas.has("sinergia_jaula_faraday") or sinergias_activas.has("sinergia_tormenta_perfecta"):
		bonus_dano_clic_pct += 0.75
		clics_por_pulsacion += 2
	if sinergias_activas.has("sinergia_estrella_enana") or sinergias_activas.has("sinergia_horizonte_sucesos"):
		bonus_dano_armas_pct += 0.55
		bonus_radio_aoe_clic += 2.5
	if sinergias_activas.has("sinergia_verdugo_cortes") or sinergias_activas.has("sinergia_horizonte_balistico"):
		proyectiles_extra += 2
		perforacion_armas += 2
		rebotes_armas += 3
		prob_critico += 0.25
	if sinergias_activas.has("sinergia_bastion_inmortal") or sinergias_activas.has("sinergia_juggernaut") or sinergias_activas.has("sinergia_avatar_sangre"):
		armadura_plana += 40.0
		vida_por_baja += 8.0
		bonus_vida_plana += 80.0
		regen_vida_seg *= 2.0
	if sinergias_activas.has("sinergia_singularidad_cursor"):
		bonus_radio_aoe_clic += 3.0
		bonus_dano_clic_pct += 0.65
	if sinergias_activas.has("sinergia_artilleria_midas") or sinergias_activas.has("sinergia_emperador_dorado"):
		oro_por_baja_pct += 0.50
		bonus_dano_pct += clampf(float(oro) * 0.002, 0.0, 2.0)

	# 6. Aplicar efectos de Keystones especiales
	var vida_anterior_max = vida_maxima
	bonus_vida_plana += ReliquiaDatos.aplicar_a_personaje(self, reliquias)
	vida_maxima = base_vida_maxima + bonus_vida_plana

	if keystone_coloso:
		armadura_plana += vida_maxima * 0.25
	if ascension_suprema:
		bonus_dano_pct += 1.0
		bonus_velocidad_mov_pct += 0.50
		proyectiles_extra += 2
	if oro_salud_conversion > 0:
		regen_vida_seg += floor(float(oro) / 400.0) * float(oro_salud_conversion)

	# 7. Consolidar estadísticas finales
	dano = (base_dano + bono_run_dano_plana) * (1.0 + bonus_dano_pct + bonus_dano_armas_pct) * bono_run_dano_mult
	cadencia_ataque = maxf(0.12, (base_cadencia_ataque * bono_run_cadencia_mult) * (1.0 - minf(bonus_cadencia_pct, 0.72)))
	speed_caminar = (base_speed_caminar + bono_run_vel_plana) * (1.0 + bonus_velocidad_mov_pct) * bono_run_vel_mult
	speed_correr = (base_speed_correr + bono_run_vel_plana) * (1.0 + bonus_velocidad_mov_pct) * bono_run_vel_mult

	if vida_maxima > vida_anterior_max:
		vida = minf(vida + (vida_maxima - vida_anterior_max), vida_maxima)

	escudo_almas = maxf(escudo_almas, max_escudo_almas)

	if not _muerto_definitivo:
		reapariciones = max(reapariciones, obtener_vidas_maximas() - 1)

	if has_node("Salud"):
		var s = get_node("Salud")
		s.vida = int(vida)
		s.vida_inicial = int(vida_maxima)
		s.reapariciones = reapariciones

	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)

func puede_comprar_mejora(id: String) -> bool:
	if ArbolInterconectadoDatos != null:
		var nodos = ArbolInterconectadoDatos.generar_arbol()
		if nodos.has(id):
			var n: SkillNodeData = nodos[id]
			return MetaprogresoManager.puede_comprar(n)
	return false

func comprar_mejora(id: String) -> bool:
	if ArbolInterconectadoDatos != null:
		var nodos = ArbolInterconectadoDatos.generar_arbol()
		if nodos.has(id):
			var n: SkillNodeData = nodos[id]
			var exito = MetaprogresoManager.comprar_nodo(n)
			if exito:
				recalcular_stats_incrementales()
				return true
	return false

## Llamado desde BotonMovil cuando el jugador hace clic sobre el Núcleo Móvil 3D
func registrar_clic_boton(pos_boton: Vector3, dano_onda: float, es_perfecto: bool = false):
	# 1. Alimentar Medidor de Fiebre / Overdrive
	var inc_fiebre = 16.0 if es_perfecto else 8.5
	if bendiciones_run.has("clic_fiebre_eterna"):
		inc_fiebre *= 1.25
	medidor_fiebre = clampf(medidor_fiebre + inc_fiebre, 0.0, 100.0)
	_actualizar_escalon_fiebre()

	# Si alcanza Overdrive x5 (100% Fiebre), invocar al Heraldo del Clic como recompensa de alto riesgo
	if medidor_fiebre >= 99.0 and _cooldown_heraldo_fiebre <= 0.0:
		_cooldown_heraldo_fiebre = 45.0
		_spawn_texto_3d("🔥 ¡OVERDRIVE x5 MÁXIMO! ¡EL HERALDO RESPONDE!", Color(1.0, 0.35, 0.9))
		if is_inside_tree() and get_tree() != null:
			var spawner = get_tree().get_first_node_in_group("oleadas_spawner")
			if spawner == null and get_parent() != null:
				spawner = get_parent().get_node_or_null("OleadasSpawner")
			if spawner != null and spawner.has_method("invocar_heraldo_clic"):
				spawner.invocar_heraldo_clic()

	# 2. Descargar arco eléctrico a través del Hilo de Resonancia 3D
	if _hilo_resonancia == null and is_inside_tree() and get_tree() != null:
		_hilo_resonancia = get_tree().get_first_node_in_group("hilo_resonancia") as Node3D
	if _hilo_resonancia != null and _hilo_resonancia.has_method("disparar_descarga_clic"):
		var dano_hilo = int(round(maxf(dano_onda, dano * 1.35) * (1.0 + bonus_dano_clic_pct)))
		_hilo_resonancia.disparar_descarga_clic(dano_hilo, es_perfecto, nivel_fiebre)

	# 3. Audio Dopamina Pentatónico y Cursor Táctico
	if is_inside_tree() and get_tree() != null:
		var dop = get_tree().get_first_node_in_group("audio_dopamina")
		if dop != null and dop.has_method("reproducir_clic_combo"):
			dop.reproducir_clic_combo(clics_totales, es_perfecto, nivel_fiebre)
		var cur = get_tree().get_first_node_in_group("cursor_tactico")
		if cur != null and cur.has_method("notificar_clic"):
			cur.notificar_clic(es_perfecto, multiplicador_fiebre_actual)

	# 4. Efectos de Bendiciones Roguelike al hacer clic
	var niv_dagas = int(bendiciones_run.get("dagas_fantasma", 0)) + int(bendiciones_run.get("cazador_rafaga_clic", 0))
	if (niv_dagas > 0 or sinergias_activas.has("sinergia_verdugo_cortes") or sinergias_activas.has("sinergia_artilleria_midas")) and get_parent() != null:
		var proyectil_escena = load("res://proyectil.tscn")
		if proyectil_escena != null:
			var num_f = 6 + 2 * max(niv_dagas, 1)
			for i in range(num_f):
				var ang = (TAU / float(num_f)) * float(i)
				var dir_f = Vector3(cos(ang), 0.0, sin(ang)).normalized()
				var p = proyectil_escena.instantiate()
				get_parent().add_child(p)
				if "rebotes_restantes" in p:
					p.rebotes_restantes = (3 if sinergias_activas.has("sinergia_verdugo_cortes") else rebotes_armas)
				p.iniciar(pos_boton + Vector3(0, 0.5, 0), dir_f, dano * 0.85, 16.0, 2, sinergias_activas.has("sinergia_verdugo_cortes"))

	var niv_onda_sismica = int(bendiciones_run.get("meteoro_orbital", 0)) + int(bendiciones_run.get("guerrero_onda_sismica", 0))
	if niv_onda_sismica > 0:
		_ejecutar_corte_giratorio_guerrero(true, es_perfecto, dano * (1.2 + 0.3 * float(niv_onda_sismica)))

	if bendiciones_run.has("nova_helada") or bendiciones_run.has("mago_singularidad_boton") or sinergias_activas.has("sinergia_singularidad_cursor") or sinergias_activas.has("sinergia_estrella_enana") or sinergias_activas.has("sinergia_horizonte_sucesos"):
		var niv_sing = max(int(bendiciones_run.get("nova_helada", 0)), int(bendiciones_run.get("mago_singularidad_boton", 1)))
		var radio_atr = 6.5 + 1.5 * float(niv_sing)
		for e in _obtener_todos_los_enemigos():
			if is_instance_valid(e) and e is Node3D:
				var dist_b = pos_boton.distance_to(e.global_position)
				if dist_b <= radio_atr and dist_b > 0.4:
					var dir_at = (pos_boton - e.global_position).normalized()
					if e.has_method("aplicar_knockback"):
						e.aplicar_knockback(dir_at * 9.5)

	# 5. Ejecutar pipeline incremental de clic del jugador
	registrar_click_jugador(false)

func registrar_click_jugador(es_anomalia: bool = false):
	var clics_ganados = clics_por_pulsacion * multiplicador_fiebre_actual
	if ascension_suprema:
		clics_ganados *= 2
	if es_anomalia:
		clics_ganados += 3 * multiplicador_fiebre_actual

	# Eco de Clic (probabilidad de duplicar)
	if bonus_eco_clic_prob > 0.0 and FortunaManager.tirar(bonus_eco_clic_prob):
		clics_ganados *= 2
		_spawn_texto_3d("🔁 ¡ECO DE CLIC!", Color(0.4, 0.8, 1.0))

	clics_disponibles += clics_ganados
	clics_totales += clics_ganados

	# Frenesí hipercinético por clic
	if frenesi_clic_pct_por_stack > 0.0:
		_frenesi_clic_stacks = min(_frenesi_clic_stacks + 1, 5)
		_frenesi_clic_timer = 3.0

	# Puente Azul-Verde: Clic cura escudo
	if clic_cura_escudo > 0.0:
		escudo_almas = minf(escudo_almas + clic_cura_escudo, max_escudo_almas + 60.0)

	# Puente Dorada-Azul: Clic genera oro
	if clic_genera_oro_pct > 0.0:
		var oro_alquimia = max(1, int(ceil(dano * clic_genera_oro_pct)))
		recoger_drop(0, oro_alquimia)

	# Puente Azul-Verde 3: Sísmica Berserker bajo 50% HP
	if terremoto_clic_vida > 0 and vida <= vida_maxima * 0.50:
		_repeler_enemigos_alrededor(6.5, 11.0, dano * 0.75 * float(terremoto_clic_vida))

	# Puente Dorada-Azul 3: Tempestad de Oro
	if tempestad_oro_dmg > 0.0:
		_repeler_enemigos_alrededor(5.5, 4.0, tempestad_oro_dmg)

	# Sobrecarga de Tormenta
	if mejoras_arbol.has("clk_sobrecarga_1") or mejoras_arbol.has("clk_sobrecarga") or sinergias_activas.has("sinergia_tormenta_perfecta"):
		contador_clics_sobrecarga += 1
		var umbral_sob = 4 if sinergias_activas.has("sinergia_tormenta_perfecta") else 6
		if contador_clics_sobrecarga >= umbral_sob:
			contador_clics_sobrecarga = 0
			var mult_sob = maxf(1.0, float(mejoras_arbol.get("clk_sobrecarga_1", mejoras_arbol.get("clk_sobrecarga", 1))))
			_detonar_tormenta_arcana(80.0 * mult_sob + dano_sobrecarga_extra)

	# Keystone: Cataclismo Cinético
	if keystone_cataclismo:
		contador_cataclismo += 1
		if contador_cataclismo >= 8:
			contador_cataclismo = 0
			_reloj_ataque = 0.0
			_repeler_enemigos_alrededor(16.0, 18.0, dano * 1.5)
			_spawn_texto_3d("⚡⚡ ¡CATACLISMO CINÉTICO!", Color(0.3, 0.85, 1.0))
			AudioManager.play("victoria", 1.25)

	if evolucion_manager != null:
		evolucion_manager.registrar_click()

	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)

func obtener_radio_atraccion_extra() -> float:
	return radio_iman_extra + bonus_nivel_iman

func obtener_bonus_onda_clic() -> Dictionary:
	var r_mult = (1.0 + (bonus_radio_aoe_clic * 0.20)) * bono_run_onda_radio_mult
	var d_mult = (1.0 + bonus_dano_clic_pct + penetracion_clic_pct * 0.5) * bono_run_onda_dano_mult
	if keystone_soberania:
		d_mult += 2.0
	return {
		"radio_mult": r_mult,
		"dano_mult": d_mult
	}

func _procesar_incremental_pasivo(delta: float):
	if _cooldown_ultimo_aliento > 0.0:
		_cooldown_ultimo_aliento = maxf(0.0, _cooldown_ultimo_aliento - delta)

	# 1. Regeneración pasiva de vida
	if regen_vida_seg > 0.0 and not _muerto_definitivo:
		if vida < vida_maxima:
			vida = minf(vida + (regen_vida_seg * delta), vida_maxima)
		elif keystone_bucle:
			_clics_pasivos_frac += (regen_vida_seg * 0.25) * delta
			if _clics_pasivos_frac >= 1.0:
				var c_bucle = int(_clics_pasivos_frac)
				_clics_pasivos_frac -= c_bucle
				clics_disponibles += c_bucle
				clics_totales += c_bucle

	# 2. Generación pasiva de oro
	if oro_pasivo_seg > 0.0:
		_oro_pasivo_acum += oro_pasivo_seg * delta
		if _oro_pasivo_acum >= 1.0:
			var g = int(_oro_pasivo_acum)
			_oro_pasivo_acum -= g
			oro += g

	# 3. Autoclicker interno (Con fix para keystone_fabrica pasando argumento booleano)
	if autoclick_tasa > 0.0:
		_autoclick_acumulador += autoclick_tasa * delta
		if _autoclick_acumulador >= 1.0:
			var clk_ent = int(_autoclick_acumulador)
			_autoclick_acumulador -= clk_ent
			clics_disponibles += clk_ent
			clics_totales += clk_ent
			if keystone_bucle and escudo_almas < max_escudo_almas + 30.0:
				escudo_almas = minf(max_escudo_almas + 30.0, escudo_almas + float(clk_ent) * 1.5)
			if keystone_fabrica and is_inside_tree() and get_tree() != null:
				var boton = get_tree().get_first_node_in_group("boton_movil")
				if boton != null and boton.has_method("_detonar_onda_choque"):
					boton._detonar_onda_choque(false)

	# 4. Sincronización periódica por segundo
	_reloj_incremental_pasivo += delta
	if _reloj_incremental_pasivo >= 1.0:
		_reloj_incremental_pasivo -= 1.0
		emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
		emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)

# ==============================================================================
# SISTEMA DE FORTUNA: suerte, denarios, reliquias y cartas por rareza
# ==============================================================================

func obtener_suerte_personaje() -> float:
	return suerte + suerte_arbol + ReliquiaDatos.calcular_suerte(reliquias)

func obtener_suerte_total() -> float:
	return obtener_suerte_personaje() + FortunaManager.suerte + FortunaManager.suerte_oculta

func sumar_suerte(cantidad: float) -> void:
	suerte += cantidad
	suerte_cambiada.emit(obtener_suerte_total())

func ganar_denarios(cantidad: int) -> void:
	if cantidad <= 0:
		return
	denarios += cantidad
	denarios_actualizados.emit(denarios)
	_spawn_texto_3d("🪙 +%d Denarios" % cantidad, Color(0.85, 0.92, 1.0))

func gastar_denarios(cantidad: int) -> bool:
	if cantidad <= 0:
		return true
	if denarios < cantidad:
		return false
	denarios -= cantidad
	denarios_actualizados.emit(denarios)
	return true

func agregar_reliquia(id: String, stacks: int = 1) -> void:
	if id == "" or stacks <= 0 or ReliquiaDatos.obtener_datos(id).is_empty():
		return
	reliquias[id] = int(reliquias.get(id, 0)) + stacks
	recalcular_stats_incrementales()
	suerte_cambiada.emit(obtener_suerte_total())
	_spawn_texto_3d("%s %s" % [ReliquiaDatos.obtener_icono(id), ReliquiaDatos.obtener_nombre(id)], Color(0.9, 0.75, 1.0))
	AudioManager.play("legendario", 1.1)

func duplicar_reliquia(id: String = "") -> bool:
	if reliquias.is_empty():
		return false
	var objetivo: String = id
	if objetivo == "" or not reliquias.has(objetivo):
		var claves: Array = reliquias.keys()
		objetivo = claves[FortunaManager.rng.randi() % claves.size()]
	reliquias[objetivo] = int(reliquias[objetivo]) + 1
	recalcular_stats_incrementales()
	suerte_cambiada.emit(obtener_suerte_total())
	_spawn_texto_3d("⚒️ %s x%d" % [ReliquiaDatos.obtener_nombre(objetivo), reliquias[objetivo]], Color(1.0, 0.85, 0.2))
	AudioManager.play("jackpot", 1.1)
	return true

func _atraer_todos_los_drops() -> void:
	if not is_inside_tree() or get_tree() == null:
		return
	for d in get_tree().get_nodes_in_group("drops"):
		if is_instance_valid(d) and d.has_method("forzar_atraccion"):
			d.forzar_atraccion(self)
		elif is_instance_valid(d) and "atraido" in d:
			d.atraido = true

func _detonar_bomba_drop(radio: float = 7.0, dano_bomba: float = 140.0) -> void:
	for e in _obtener_todos_los_enemigos():
		if is_instance_valid(e) and e is Node3D and global_position.distance_to(e.global_position) <= radio:
			if e.has_method("recibir_dano"):
				e.recibir_dano(dano_bomba + dano * 1.5, true)
	_repeler_enemigos_alrededor(radio, 12.0)

func _aplicar_mejora_interna(tipo_mejora: String, mult_rareza: float) -> void:
	match tipo_mejora:
		"dano":
			bono_run_dano_mult *= (1.0 + 0.22 * mult_rareza)
		"velocidad":
			bono_run_vel_mult *= (1.0 + 0.15 * mult_rareza)
		"vida":
			bono_run_vida_plana += 30.0 * mult_rareza
		"cadencia":
			bono_run_cadencia_mult *= maxf(0.45, 1.0 - 0.16 * mult_rareza)
		"critico":
			bonus_nivel_critico += 0.08 * mult_rareza
		"iman":
			bonus_nivel_iman += 2.0 * mult_rareza
		"fortuna":
			sumar_suerte(0.10 * mult_rareza)
			_spawn_texto_3d("🍀 +%.2f Suerte" % (0.10 * mult_rareza), Color(0.2, 1.0, 0.4))

func _spawn_texto_3d(texto: String, color: Color = Color.WHITE):
	if not is_inside_tree() or get_parent() == null:
		return
	var pool = get_tree().get_first_node_in_group("damage_numbers_pool") if get_tree() != null else null
	if pool != null and pool.has_method("mostrar_texto"):
		pool.mostrar_texto(global_position + Vector3(0, 2.3, 0), texto, color, false)
		return
	var escena = load("res://damage_number_3d.tscn")
	if escena != null:
		var txt = escena.instantiate()
		var pos = global_position + Vector3(0, 2.4, 0)
		get_parent().add_child(txt)
		txt.global_position = pos
		if txt.has_method("iniciar"):
			txt.iniciar(0.0, false, false, texto)
			var label = txt.get_node_or_null("Label3D") as Label3D
			if label != null:
				label.modulate = color

func _detonar_tormenta_arcana(dano_descarga: float):
	AudioManager.play("orbe_explosion", 1.3)
	var enemigos = _obtener_todos_los_enemigos()
	for e in enemigos:
		if is_instance_valid(e) and e is Node3D:
			if global_position.distance_to(e.global_position) <= 24.0:
				if e.has_method("recibir_dano"):
					e.recibir_dano(dano_descarga, true)
	_spawn_texto_3d("🌩️ ¡SOBRECARGA DE TORMENTA!", Color(0.35, 0.9, 1.0))

func _spawn_efecto_ascension():
	_spawn_texto_3d("👑 ¡ASCENSIÓN SUPREMA!", Color(1.0, 0.85, 0.25))

func elegir_estado():
	if not is_on_floor():
		return Estado.AIRE
	var rapidez = Vector2(velocity.x, velocity.z).length()
	if rapidez < 0.1:
		return Estado.QUIETO
	if rapidez > speed_caminar + 0.1:
		return Estado.CORRER
	return Estado.CAMINAR

func animar():
	if _anim_ctrl == null or not _anim_ctrl.esta_listo():
		return
	if bloqueando and clase == "Guerrero":
		var rapidez = Vector2(velocity.x, velocity.z).length()
		if rapidez < 0.2:
			if _anim_ctrl.tiene_clip("holding-both"):
				_anim_ctrl.reproducir_bucle("holding-both", 0.14, 1.0, 1)
				return
		else:
			_anim_ctrl.reproducir_bucle("walk", 0.14, 1.0, 1)
			return
	var rapidez_actual = Vector2(velocity.x, velocity.z).length()
	_anim_ctrl.actualizar_locomocion(rapidez_actual, estado == Estado.CORRER, is_on_floor(), speed_caminar)

@export_enum("Ninguna", "Avanzar 60 cuadros", "Avanzar 60 y soltar", "Avanzar y la accion desde el cuadro 30", "Mantener la accion 2 s", "Avanzar con la accion 60 cuadros", "Diagonal W+D 60 cuadros") var prueba = 0
@export var accion_prueba = "correr"

var _cuadro = 0
var _termino = false

func _prueba():
	if prueba == 0 or _termino:
		return
	_cuadro += 1
	match prueba:
		1:
			if _cuadro == 1: Input.action_press("move_up")
			elif _cuadro == 60:
				var r = Vector2(velocity.x, velocity.z).length()
				print("[prueba] pos: ", global_position.snappedf(0.01), " · vel: ", snappedf(r, 0.01), " · anim: ", anim.current_animation)
				Input.action_release("move_up")
				_termino = true
		2:
			if _cuadro == 1: Input.action_press("move_up")
			elif _cuadro == 60: Input.action_release("move_up")
			if _cuadro >= 60 and _cuadro <= 80:
				var r = Vector2(velocity.x, velocity.z).length()
				print("cuadro ", _cuadro, ": ", snappedf(r, 0.01))
			if _cuadro == 80: _termino = true
		3:
			if _cuadro == 1: Input.action_press("move_up")
			elif _cuadro == 30:
				if InputMap.has_action(accion_prueba): Input.action_press(accion_prueba)
			if _cuadro >= 30 and _cuadro <= 45:
				var r = Vector2(velocity.x, velocity.z).length()
				print("cuadro ", _cuadro, ": ", snappedf(r, 0.01), " · anim: ", anim.current_animation)
			elif _cuadro == 60:
				Input.action_release("move_up")
				if InputMap.has_action(accion_prueba): Input.action_release(accion_prueba)
				_termino = true

# ==============================================================================
# HABILIDADES Y MECÁNICAS EXCLUSIVAS DEL GUERRERO (TANQUE)
# ==============================================================================

func _actualizar_estado_bloqueo(activo: bool):
	if bloqueando == activo:
		return
	bloqueando = activo
	if _escudo_visual == null or not is_instance_valid(_escudo_visual):
		_crear_escudo_visual()
	if _escudo_visual != null:
		_escudo_visual.visible = bloqueando
	if bloqueando:
		AudioManager.play("escudo_bloqueo", 1.25, -2.0)

func _crear_escudo_visual():
	if _escudo_visual != null and is_instance_valid(_escudo_visual):
		return

	_escudo_visual = Node3D.new()
	_escudo_visual.name = "EscudoVisual"

	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.35, 1.15, 0.1)
	mesh_inst.mesh = box

	var mat = StandardMaterial3D.new()
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.2, 0.65, 1.0, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(0.25, 0.75, 1.0)
	mat.emission_energy_multiplier = 2.0
	mat.roughness = 0.2
	mesh_inst.material_override = mat

	var borde = MeshInstance3D.new()
	var box_borde = BoxMesh.new()
	box_borde.size = Vector3(1.42, 1.22, 0.05)
	borde.mesh = box_borde
	var mat_borde = StandardMaterial3D.new()
	mat_borde.albedo_color = Color(1.0, 0.85, 0.25)
	mat_borde.metallic = 0.85
	mat_borde.roughness = 0.3
	borde.material_override = mat_borde

	_escudo_visual.add_child(mesh_inst)
	_escudo_visual.add_child(borde)
	_escudo_visual.position = Vector3(0, 0.9, -0.65)
	_escudo_visual.visible = false
	add_child(_escudo_visual)

func _parpadear_escudo():
	if _escudo_visual == null or not is_instance_valid(_escudo_visual):
		return
	var mesh_inst = _escudo_visual.get_child(0) as MeshInstance3D
	if mesh_inst != null and mesh_inst.material_override != null:
		var mat = mesh_inst.material_override as StandardMaterial3D
		var tw = create_tween()
		tw.tween_property(mat, "emission_energy_multiplier", 4.5, 0.06)
		tw.tween_property(mat, "emission_energy_multiplier", 2.0, 0.15)

func _obtener_tree() -> SceneTree:
	if is_inside_tree():
		return get_tree()
	return Engine.get_main_loop() as SceneTree

func _mostrar_feedback_bloqueo(mitigado: float, _recibido: float):
	_spawn_texto_3d("🛡️ BLOQUEO (-%d)" % int(mitigado), Color(0.2, 0.8, 1.0))

func _repeler_enemigos_alrededor(radio: float, fuerza: float, dano_extra: float = 0.0):
	var enemigos = _obtener_todos_los_enemigos()
	for e in enemigos:
		if is_instance_valid(e) and e is Node3D:
			var dist = global_position.distance_to(e.global_position)
			if dist <= radio:
				if dano_extra > 0.0 and e.has_method("recibir_dano"):
					e.recibir_dano(dano_extra, false)
				var dir = (e.global_position - global_position).normalized()
				dir.y = 0.0
				if e.has_method("aplicar_knockback"):
					e.aplicar_knockback(dir * fuerza)
				elif "velocity" in e:
					e.velocity += dir * fuerza

func _ejecutar_corte_giratorio_guerrero(es_click: bool = false, es_crit: bool = false, dano_custom: float = -1.0):
	accion = "whirlwind"
	_reloj_anim_accion = 0.32
	if _anim_ctrl != null:
		_anim_ctrl.reproducir_accion("whirlwind", 3, 0.05, 1.2)
	
	AudioManager.play("corte_giratorio", randf_range(0.95, 1.15))
	
	var modelo_nodo = get_node_or_null("Modelo") as Node3D
	if modelo_nodo != null:
		if _tween_modelo_ataque != null and _tween_modelo_ataque.is_valid():
			_tween_modelo_ataque.kill()
		modelo_nodo.position = _modelo_pos_base
		modelo_nodo.rotation.y = _modelo_rot_base.y
		_tween_modelo_ataque = create_tween()
		_tween_modelo_ataque.tween_property(modelo_nodo, "rotation:y", _modelo_rot_base.y + TAU, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween_modelo_ataque.tween_callback(func():
			if is_instance_valid(modelo_nodo):
				modelo_nodo.rotation.y = _modelo_rot_base.y
		)

	_crear_efecto_disco_cortante(rango_ataque)

	var enemigos: Array = _obtener_todos_los_enemigos()
	if is_inside_tree() and get_tree() != null:
		enemigos.append_array(get_tree().get_nodes_in_group("rompibles"))
	var dano_base_calc = dano if dano_custom <= 0.0 else dano_custom
	var dano_aplicar = dano_base_calc * (1.25 if es_click else 1.0)

	for e in enemigos:
		if is_instance_valid(e) and e is Node3D:
			var dist = global_position.distance_to(e.global_position)
			if dist <= rango_ataque + 0.6:
				if e.has_method("recibir_dano"):
					e.recibir_dano(dano_aplicar, es_crit or es_click)

				var dir_empuje = (e.global_position - global_position).normalized()
				dir_empuje.y = 0.0
				var f_emp = 8.5 if es_click else 6.0
				if e.has_method("aplicar_knockback"):
					e.aplicar_knockback(dir_empuje * f_emp)
				elif "velocity" in e:
					e.velocity += dir_empuje * f_emp

func _crear_efecto_disco_cortante(radio: float):
	if not is_inside_tree() or get_parent() == null:
		return

	var mesh_inst = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = maxf(radio * 0.75, 0.5)
	torus.outer_radius = radio * 1.05
	torus.rings = 24
	torus.ring_segments = 12
	mesh_inst.mesh = torus

	var mat = StandardMaterial3D.new()
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.75, 0.2, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.65, 0.1)
	mat.emission_energy_multiplier = 3.2
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat

	get_parent().add_child(mesh_inst)
	mesh_inst.global_position = global_position + Vector3(0, 0.85, 0)
	mesh_inst.scale = Vector3(0.2, 0.2, 0.2)

	var tw = mesh_inst.create_tween().set_parallel(true)
	tw.tween_property(mesh_inst, "scale", Vector3(1.15, 1.0, 1.15), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tw.chain().tween_callback(mesh_inst.queue_free)

# ==============================================================================
# SISTEMA DE VIDAS, REAPARICIÓN CON I-FRAMES Y DERROTA DEFINITIVA
# ==============================================================================

func _procesar_caida_jugador():
	if _muerto_definitivo:
		return

	if reapariciones > 0:
		reapariciones -= 1
		vida = vida_maxima
		escudo_almas = max_escudo_almas
		global_position = punto_reaparicion
		velocity = Vector3.ZERO
		avance = Vector3.ZERO
		empuje = Vector3.ZERO
		_reloj_invulnerable = invulnerable_tiempo + bonus_invulnerable_seg

		if keystone_segunda_vida:
			_repeler_enemigos_alrededor(16.0, 18.0, dano * 3.0)
			AudioManager.play("victoria", 1.25)
			_spawn_texto_3d("✝️ ¡NOVA SAGRADA DE SEGUNDA OPORTUNIDAD!", Color(1.0, 0.9, 0.3))
		else:
			AudioManager.play("danio_jugador", 0.65, 3.0)
			_crear_feedback_reaparicion()

		if has_node("Salud"):
			var s = get_node("Salud")
			s.vida = int(vida)
			s.reapariciones = reapariciones
			s.cambio.emit(s.vida)

		emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	else:
		_muerto_definitivo = true
		vida = 0.0
		emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

		if has_node("Salud"):
			var s = get_node("Salud")
			s.vida = 0
			s.reapariciones = 0
			s.sin_vida.emit()

		var tree = _obtener_tree()
		if tree != null:
			var partida = tree.get_first_node_in_group("partida")
			if partida != null and partida.has_method("perder"):
				if obtener_vidas_maximas() == 1:
					partida.perder("Caíste en combate (1 vida)")
				else:
					partida.perder("Agotaste tus %d vidas en combate" % obtener_vidas_maximas())

func _crear_feedback_reaparicion():
	if not is_inside_tree() or get_parent() == null:
		return
	_spawn_texto_3d("✨ ¡REAPARICIÓN! (%d Vidas)" % (reapariciones + 1), Color(1.0, 0.9, 0.2))
	_repeler_enemigos_alrededor(7.0, 10.0)

	var luz = OmniLight3D.new()
	luz.light_color = Color(0.4, 0.85, 1.0)
	luz.light_energy = 4.0
	luz.omni_range = 10.0
	add_child(luz)
	luz.position = Vector3(0, 1.2, 0)
	var tw = create_tween()
	if tw != null:
		tw.tween_property(luz, "light_energy", 0.0, 0.8)
		tw.tween_callback(luz.queue_free)
	else:
		luz.queue_free()
