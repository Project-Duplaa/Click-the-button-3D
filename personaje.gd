extends CharacterBody3D

const AudioManager = preload("res://audio_manager.gd")
const ArenaColiseo = preload("res://arena_coliseo.gd")
const VfxCombate = preload("res://vfx_combate.gd")
const PROYECTIL_ESCENA = preload("res://proyectil.tscn")
const ORBE_ARCANO_ESCENA = preload("res://orbe_arcano.tscn")
const EvolucionManager = preload("res://evolucion_manager.gd")
const ArbolMejorasDatos = preload("res://arbol_mejoras_datos.gd")
const MetaprogresoManager = preload("res://metaprogreso_manager.gd")
const ArbolInterconectadoDatos = preload("res://arbol_interconectado_datos.gd")
const CatalogoBendicionesScript = preload("res://catalogo_bendiciones.gd")
const DamageNumbersPoolScript = preload("res://damage_numbers_pool.gd")
const AudioDopaminaScript = preload("res://audio_dopamina.gd")
const CursorTacticoScript = preload("res://cursor_tactico.gd")
const LogrosManagerScript = preload("res://logros_manager.gd")
const ESCENA_DAMAGE_NUMBER_3D = preload("res://damage_number_3d.tscn")

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
signal corrupta_aplicada(id_corrupta: String)

@export var camara: Camera3D
@export var speed_caminar = 3.2
@export var speed_correr = 5.8
@export var tiempo_arranque = 0.20
@onready var anim = $Modelo/AnimationPlayer if has_node("Modelo/AnimationPlayer") else null

# Estadísticas RPG / Autobattler (Balanceado estilo Vampire Survivors: ágil y escalable)
@export var clase_inicial: String = "Novato"
var clase: String = "Novato"
var clase_base: String = "Novato"
var subclase_tier2: String = ""
var bono_subclase_onda_radio_mult: float = 1.0
var bendiciones_corruptas: Array = []
var _cooldown_rotacion_caotica: float = 20.0
var _bonus_caotico_actual: String = "ninguno"
var _bonus_caotico_mult: float = 1.0
var _temporizador_paso_coloso: float = 0.0
var _telemetria_registros: Array = []
var _dano_total_acumulado: float = 0.0
var ultimo_atacante_tipo: String = "enemigo"
var ultimo_atacante_nombre: String = "Gladiador Rival"
var _estado_juicio_emperador: bool = false
var vida_maxima: float = 100.0
var vida: float = 100.0
var dano: float = 10.0
var rango_ataque: float = 2.6
var cadencia_ataque: float = 1.35
var oro: int = 0
var xp: int = 0
var xp_siguiente_nivel: int = 48
var nivel: int = 1
var bajas: int = 0

# Sistema Incremental: Monedas, Clics y Árbol de Ascensión
var clics_disponibles: int = 0
var clics_totales: int = 0
var mejoras_arbol: Dictionary = {}

# Sistema de Fortuna (suerte, moneda de run y reliquias). Se reinician con cada run (escena nueva).
var suerte: float = 0.0 # Suerte de la run: cartas de nivel, tréboles, santuarios
var suerte_arbol: float = 0.0 # Suerte permanente del nodo Trébol del Coliseo (se recalcula)
var suerte_corrupta: float = 0.0
var multiplicador_abismo_recompensas: float = 1.0
var denarios: int = 0 # Moneda exclusiva de la run para santuarios. NO pasa al metaprogreso
var reliquias: Dictionary = {} # id_reliquia -> stacks
var duplicar_proxima_carta: bool = false # La próxima carta de nivel se aplica dos veces

# CAPA 1: Estadísticas base puras según clase
var base_vida_maxima: float = 100.0
var base_dano: float = 10.0
var base_cadencia_ataque: float = 1.35
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
var bono_clics_tormento_mult: float = 1.0

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
@export var punto_reaparicion: Vector3 = Vector3(0.0, 0.0, 3.0)
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

# Mejoras dedicadas al Botón Móvil y Palancas (Rama "boton")
var btn_calor_reduc_pct: float = 0.0
var btn_tamano_pct: float = 0.0
var btn_enfriamiento_pct: float = 0.0
var btn_ventana_ritmo_pct: float = 0.0
var btn_dano_perfecto_pct: float = 0.0
var btn_control_orbita_pct: float = 0.0
var btn_clics_bloqueo_extra: int = 0
var btn_calor_max_extra: float = 0.0
var btn_dano_termico_pct: float = 0.0
var btn_alcance_palancas: float = 0.0
var btn_frenesi_duracion_seg: float = 0.0
var btn_fiebre_eficiencia_pct: float = 0.0
var keystone_btn_criogenico: bool = false
var keystone_btn_rompecadenas: bool = false

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
var _modelo_escala_base: Vector3 = Vector3(-2.8, 2.8, -2.8)
var _tween_modelo_ataque: Tween = null
var _cooldown_inmunidad_jefe: float = 0.0
var _inclinacion_giro: float = 0.0
var _turno_ataque_novato: bool = false
var _arma_der_ref: Node3D = null
var _arma_izq_ref: Node3D = null
var _luz_orbe_ref: OmniLight3D = null
var _modelo_ref: Node3D = null
var _boton_movil_ref: Node3D = null
var _procesando_recibir_dano: bool = false

func obtener_vidas_maximas() -> int:
	return vidas_base + bonus_vidas_arbol

func _ready():
	add_to_group("jugador")
	add_to_group("player")
	ArenaColiseo.configurar_cuerpo_terreno(self, false, false)
	if camara == null and get_viewport() != null:
		camara = get_viewport().get_camera_3d()

	var mod_inicial = get_node_or_null("Modelo") as Node3D
	_modelo_ref = mod_inicial
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
	aplicar_clase(clase_inicial if not clase_inicial.is_empty() else "Novato")
	MetaprogresoManager.aplicar_a_personaje(self)
	reapariciones = max(0, obtener_vidas_maximas() - 1)
	vida = vida_maxima
	call_deferred("_bootstrap_core_systems")
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

func _on_malla_cambiada(nuevo_modelo: Node3D) -> void:
	if nuevo_modelo == null:
		return
	_modelo_ref = nuevo_modelo
	if _tween_modelo_ataque != null and _tween_modelo_ataque.is_valid():
		_tween_modelo_ataque.kill()
		_tween_modelo_ataque = null
	nuevo_modelo.position = Vector3.ZERO
	nuevo_modelo.rotation = Vector3(0.0, PI, 0.0)
	nuevo_modelo.scale = Vector3(2.8, 2.8, 2.8)
	_modelo_pos_base = nuevo_modelo.position
	_modelo_rot_base = nuevo_modelo.rotation
	_modelo_escala_base = nuevo_modelo.scale
	_inclinacion_giro = 0.0
	if _anim_ctrl == null:
		_anim_ctrl = AnimadorEntidad.new(nuevo_modelo)
	else:
		_anim_ctrl.vincular_modelo(nuevo_modelo)
	anim = _anim_ctrl.obtener_animation_player()
	if _anim_ctrl.esta_listo():
		_anim_ctrl.reproducir_bucle("idle", 0.05, 1.0, 0)
	equipar_armas_clase(clase)

func equipar_armas_clase(nombre_clase: String) -> void:
	var mod: Node3D = get_node_or_null("Modelo") as Node3D
	if mod == null:
		return
	var armas: Dictionary = AnimadorEntidad.equipar_armas_en_esqueleto(mod, nombre_clase, true)
	AnimadorEntidad.aplicar_identidad_visual_clase(mod, nombre_clase, true)
	_arma_der_ref = armas.get("derecha", null)
	_arma_izq_ref = armas.get("izquierda", null)
	_luz_orbe_ref = armas.get("luz_orbe", null)
	_preview_baston = _arma_der_ref if nombre_clase in ["Mago", "Arúspice", "Taumaturgo del Vacío", "Flamen Volcánico", "Pontífice del Vacío Estelar", "Señor del Magma Imperial", "Archimago del Vacío", "Piromante Cataclísmico"] else null
	_preview_espada = _arma_der_ref if nombre_clase in ["Guerrero", "Murmillo", "Secutor Radiante", "Provocator Sangriento", "Paladín del Sol Invictus", "Campeón Augusto de Sangre", "Paladín Solar", "Berserker Sangriento"] else null
	_preview_arco = _arma_izq_ref if nombre_clase in ["Cazador", "Arquero", "Sagittario", "Velites Balístico", "Dimachaerus Espectral", "Centurión Balístico Astral", "Sombra del Anfiteatro", "Francotirador Astral", "Maestro de Sombras"] else null

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

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and es_arquetipo("Guerrero"):
			_actualizar_estado_bloqueo(event.pressed)
	elif event is InputEventKey:
		if (event.keycode == KEY_F or event.keycode == KEY_Q) and es_arquetipo("Guerrero"):
			_actualizar_estado_bloqueo(event.pressed)
		elif event.pressed and not event.echo and event.keycode == KEY_SPACE:
			_intentar_dash_tactico()

func _intentar_dash_tactico():
	if _muerto_definitivo or _dash_cooldown > 0.0:
		return
	if bendiciones_corruptas.has("corrupta_coloso_inamovible"):
		_spawn_texto_3d("🗿 ¡COLOSO INAMOVIBLE (SIN DASH)!", Color(0.85, 0.72, 0.45))
		return
	if subclase_tier2 in ["Dimachaerus Espectral", "Sombra del Anfiteatro", "Maestro de Sombras"]:
		_crear_senuelo_sombra(global_position)
	var cd_base = 2.0
	if bendiciones_run.has("global_dash_frenetico"):
		cd_base *= pow(0.75, float(bendiciones_run["global_dash_frenetico"]))
	if mejoras_arbol.has("mov_dash"):
		cd_base *= maxf(0.45, 1.0 - float(mejoras_arbol["mov_dash"]) * 0.12)
	var lvl_vortice = int(mejoras_arbol.get("cosm_vortice_tiempo", 0))
	if lvl_vortice > 0:
		cd_base *= maxf(0.30, pow(0.70, float(lvl_vortice)))
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
	if _anim_ctrl != null and _anim_ctrl.esta_listo():
		_anim_ctrl.reproducir_accion("dash", 3, 0.04, 1.4, 0.24)

	AudioManager.play("corte_espada", 1.35)
	if bendiciones_run.has("global_dash_frenetico"):
		_repeler_enemigos_alrededor(3.6, 9.0, dano * 0.85 * float(bendiciones_run["global_dash_frenetico"]))
		VfxCombate.spawn_explosion_nova(get_parent(), global_position + Vector3(0, 0.4, 0), 3.4, Color(0.25, 0.92, 1.0), Color.WHITE, 0.24, true, true)
	if sinergias_activas.has("sinergia_juggernaut"):
		_repeler_enemigos_alrededor(4.8, 14.0, (dano + armadura_plana * 1.5))
		VfxCombate.spawn_explosion_nova(get_parent(), global_position + Vector3(0, 0.5, 0), 4.6, Color(1.0, 0.55, 0.12), Color(1.0, 0.95, 0.65), 0.30, true, true)
	elif not bendiciones_run.has("global_dash_frenetico"):
		BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 0.3, 1.9, BunkerVisualKit.COL_CYAN_ELECTRIC, 0.20)

func aplicar_knockback(impulso: Vector3, _duracion_stun: float = 0.08):
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

	if _cooldown_inmunidad_jefe > 0.0:
		_cooldown_inmunidad_jefe = maxf(0.0, _cooldown_inmunidad_jefe - delta)

	if _dash_cooldown > 0.0:
		_dash_cooldown = maxf(0.0, _dash_cooldown - delta)

	# Control de invulnerabilidad temporal (i-frames con parpadeo de modelo)
	if _reloj_invulnerable > 0.0:
		_reloj_invulnerable = maxf(_reloj_invulnerable - delta, 0.0)
		if _modelo_ref != null and is_instance_valid(_modelo_ref):
			_modelo_ref.visible = fmod(_reloj_invulnerable, 0.20) < 0.10
			if _reloj_invulnerable <= 0.0:
				_modelo_ref.visible = true

	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var entrada = Vector3(input_dir.x, 0.0, input_dir.y)

	var giro_cam = camara.global_rotation.y if camara != null else 0.0
	var direction = entrada.rotated(Vector3.UP, giro_cam).normalized()

	# Actualizar estado de bloqueo continuo (arquetipo Guerrero y subclases)
	if es_arquetipo("Guerrero"):
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
	if is_on_floor():
		velocity.y = minf(velocity.y, 0.0)

	var tasa_giro_visual := 0.0
	if direction.length_squared() > 0.01:
		var yaw_objetivo := atan2(-direction.x, -direction.z)
		var yaw_prev := rotation.y
		var vel_giro := 15.0 if not bloqueando else 10.5
		rotation.y = lerp_angle(rotation.y, yaw_objetivo, minf(1.0, delta * vel_giro))
		tasa_giro_visual = angle_difference(yaw_prev, rotation.y) / maxf(delta, 0.001)
	var rapidez_horiz := Vector2(velocity.x, velocity.z).length()
	var factor_vel := clampf(rapidez_horiz / maxf(1.0, speed_correr), 0.0, 1.0)
	var banco_obj := clampf(-tasa_giro_visual * 0.018 * factor_vel, -0.14, 0.14)
	_inclinacion_giro = lerpf(_inclinacion_giro, banco_obj, minf(1.0, delta * 12.0))
	if _modelo_ref != null and is_instance_valid(_modelo_ref) and (_tween_modelo_ataque == null or not _tween_modelo_ataque.is_valid()):
		_modelo_ref.rotation.z = _modelo_rot_base.z + _inclinacion_giro

	move_and_slide()

	var antes = estado
	estado = elegir_estado()
	ruido = RUIDO[estado]
	if estado != antes and prueba != 0:
		print("estado ", Estado.keys()[estado], " · ruido ", ruido, " m")

	if _anim_ctrl != null:
		_anim_ctrl.actualizar(delta)

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
		var decay = 6.5 * maxf(0.35, 1.0 - btn_fiebre_eficiencia_pct * 0.80)
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
			BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 0.25, 2.4, BunkerVisualKit.COL_PLASMA_ORANGE, 0.30)

	# Efectos continuos de Bendiciones Corruptas
	if bendiciones_corruptas.has("corrupta_coloso_inamovible") and Vector2(velocity.x, velocity.z).length() > 0.8:
		_temporizador_paso_coloso += delta
		if _temporizador_paso_coloso >= 0.45:
			_temporizador_paso_coloso = 0.0
			_repeler_enemigos_alrededor(2.8, 5.5, dano * 0.55)
			BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 0.3, 2.7, Color(0.95, 0.55, 0.15), 0.26)

	# Detección continua de aproximación a jefes con auras de empuje o rebote activo
	var tiene_aura_repulsion: bool = (
		bendiciones_corruptas.has("corrupta_coloso_inamovible")
		or bendiciones_run.has("global_estela_fuego")
		or sinergias_activas.has("sinergia_juggernaut")
		or bendiciones_run.has("global_dash_frenetico")
	)
	if tiene_aura_repulsion and _cooldown_inmunidad_jefe <= 0.0 and is_inside_tree() and get_tree() != null:
		if get_tree().get_node_count_in_group("jefes") > 0:
			var jefes = get_tree().get_nodes_in_group("jefes")
			for j in jefes:
				if is_instance_valid(j) and not ("muerto" in j and j.muerto) and ("vida" in j and j.vida > 0.0):
					if global_position.distance_squared_to(j.global_position) <= 10.24:
						_reaccionar_inmunidad_empuje_jefe(j)
						break

	if bendiciones_corruptas.has("corrupta_avaricia_sangrienta") and vida > 1.0 and not _muerto_definitivo:
		vida = maxf(1.0, vida - 1.0 * delta)

	if bendiciones_corruptas.has("corrupta_destino_caotico"):
		_cooldown_rotacion_caotica -= delta
		if _cooldown_rotacion_caotica <= 0.0:
			_cooldown_rotacion_caotica = 20.0
			var stats_rot = ["dano", "cadencia", "critico"]
			_bonus_caotico_actual = stats_rot[randi() % stats_rot.size()]
			_bonus_caotico_mult = randf_range(0.50, 1.80)
			recalcular_stats_incrementales()
			_spawn_texto_3d("🎲 CAOS: +%d%% %s (20s)" % [int(round(_bonus_caotico_mult * 100.0)), _bonus_caotico_actual.to_upper()], Color(0.95, 0.35, 1.0))

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
	var lista: Array = tree.get_nodes_in_group("enemigos")
	if lista.is_empty():
		lista = tree.get_nodes_in_group("enemies")
	return lista

func _procesar_autobattler(delta: float):
	var mult_cad_fiebre = 1.25 if en_overdrive else (1.10 if multiplicador_fiebre_actual >= 3 else 1.0)
	_reloj_ataque = maxf(_reloj_ataque - delta * mult_cad_fiebre, 0.0)
	if _reloj_ataque <= 0.001:
		var objetivo = _obtener_enemigo_cercano()
		if objetivo != null:
			var d_sq = global_position.distance_squared_to(objetivo.global_position)
			if d_sq <= rango_ataque * rango_ataque:
				_ejecutar_ataque(objetivo)
				_reloj_ataque = cadencia_ataque
			else:
				_reloj_ataque = 0.045
		else:
			_reloj_ataque = 0.06

func _obtener_enemigo_cercano() -> Node3D:
	if not is_inside_tree() or get_tree() == null:
		return null
	var enemigos = _obtener_todos_los_enemigos()
	var mas_cercano_normal: Node3D = null
	var menor_dist_sq_normal: float = 99999999.0
	var mas_cercano_respaldo: Node3D = null
	var menor_dist_sq_respaldo: float = 99999999.0
	var mi_pos := global_position
	for e in enemigos:
		if is_instance_valid(e) and e is Node3D:
			if "muerto" in e and e.muerto:
				continue
			var dist_sq: float = mi_pos.distance_squared_to(e.global_position)
			var es_inmune_arma: bool = ("solo_dano_boton" in e and bool(e.solo_dano_boton))
			if not es_inmune_arma:
				if dist_sq < menor_dist_sq_normal:
					menor_dist_sq_normal = dist_sq
					mas_cercano_normal = e
			elif dist_sq < menor_dist_sq_respaldo:
				menor_dist_sq_respaldo = dist_sq
				mas_cercano_respaldo = e
	if mas_cercano_normal != null and menor_dist_sq_normal <= rango_ataque * rango_ataque:
		return mas_cercano_normal
	return mas_cercano_normal if mas_cercano_normal != null else mas_cercano_respaldo

func _ejecutar_ataque(enemigo: Node3D):
	var origen_disp := global_position + Vector3(0.0, 0.9, 0.0)
	var objetivo_disp := enemigo.global_position + Vector3(0.0, 0.9, 0.0)
	var dif_3d := objetivo_disp - origen_disp
	var dir_3d := dif_3d.normalized() if dif_3d.length_squared() > 0.001 else Vector3.FORWARD
	var dir = Vector3(dir_3d.x, 0.0, dir_3d.z)
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
		basis = Basis.looking_at(dir)
	else:
		dir = -global_transform.basis.z.normalized()
		dir.y = 0.0

	var es_crit = FortunaManager.tirar(prob_critico)
	var mult_frenesi = 1.0 + float(_frenesi_clic_stacks) * frenesi_clic_pct_por_stack
	var mult_coloso_bajo = 1.80 if (keystone_coloso and vida < vida_maxima * 0.50) else 1.0
	var mult_usura_oro = (1.0 + floor(float(oro) / 100.0) * 0.025) if keystone_usura else 1.0
	var dano_ataque_actual = dano * (mult_critico if es_crit else 1.0) * mult_frenesi * mult_coloso_bajo * mult_usura_oro
	var bonus_asc = mejoras_arbol.get("hib_ascension", 0) >= 1 or ascension_suprema

	# Mecánicas exclusivas de las Subclases Tier 2 y Tier 3
	match subclase_tier2:
		"Secutor Radiante", "Paladín del Sol Invictus", "Paladín Solar":
			accion = "attack-melee-right"
			_reloj_anim_accion = 0.28
			if _anim_ctrl != null:
				_anim_ctrl.reproducir_accion("attack-melee-right", 2, 0.05, 1.2)
			_ejecutar_animacion_procedural_ataque("melee")
			_crear_onda_solar(dir, es_crit, dano_ataque_actual)
			registrar_dano_telemetria("armas", dano_ataque_actual)
			return
		"Provocator Sangriento", "Campeón Augusto de Sangre", "Berserker Sangriento":
			var es_t3 = subclase_tier2 in ["Campeón Augusto de Sangre"]
			var pct_vida_perdida = clampf(1.0 - (vida / maxf(1.0, vida_maxima)), 0.0, 0.95)
			var factor_berserk = 0.55 if es_t3 else 0.40
			var mult_berserk = 1.0 + (pct_vida_perdida * factor_berserk)
			var dano_berserk = dano_ataque_actual * mult_berserk
			_ejecutar_corte_giratorio_berserker(es_crit, dano_berserk)
			var curacion_vamp = 3.5 if es_t3 else 2.0
			vida = minf(vida + curacion_vamp, vida_maxima)
			registrar_dano_telemetria("armas", dano_berserk)
			return
		"Velites Balístico", "Centurión Balístico Astral", "Francotirador Astral":
			accion = "shoot-bow"
			_reloj_anim_accion = 0.20
			if _anim_ctrl != null:
				_anim_ctrl.reproducir_accion("shoot-bow", 2, 0.05, 1.25)
			_ejecutar_animacion_procedural_ataque("arco")
			var es_t3 = subclase_tier2 in ["Centurión Balístico Astral", "Francotirador Astral"]
			var mult_riel = 1.20 if es_t3 else 1.15
			_disparar_riel_astral(dir, dano_ataque_actual * mult_riel, es_crit)
			registrar_dano_telemetria("armas", dano_ataque_actual * mult_riel)
			return
		"Dimachaerus Espectral", "Sombra del Anfiteatro", "Maestro de Sombras":
			accion = "attack-melee-left"
			_reloj_anim_accion = 0.18
			if _anim_ctrl != null:
				_anim_ctrl.reproducir_accion("attack-melee-left", 2, 0.04, 1.4)
			var es_t3 = subclase_tier2 in ["Sombra del Anfiteatro", "Maestro de Sombras"]
			var cant_dagas = 10 if es_t3 else 8
			var mult_daga = 0.35 if es_t3 else 0.42
			_disparar_espiral_dagas_sombras(dano_ataque_actual * mult_daga, es_crit, cant_dagas)
			registrar_dano_telemetria("armas", dano_ataque_actual * mult_daga * float(cant_dagas))
			return
		"Taumaturgo del Vacío", "Pontífice del Vacío Estelar", "Archimago del Vacío":
			accion = "cast-magic"
			_reloj_anim_accion = 0.25
			if _anim_ctrl != null:
				_anim_ctrl.reproducir_accion("cast-magic", 2, 0.05, 1.1)
			_ejecutar_animacion_procedural_ataque("mago")
			_lanzar_orbe_vacio(dir_3d, enemigo, dano_ataque_actual, es_crit)
			registrar_dano_telemetria("armas", dano_ataque_actual)
			return
		"Flamen Volcánico", "Señor del Magma Imperial", "Piromante Cataclísmico":
			accion = "cast-magic"
			_reloj_anim_accion = 0.25
			if _anim_ctrl != null:
				_anim_ctrl.reproducir_accion("cast-magic", 2, 0.05, 1.1)
			_ejecutar_animacion_procedural_ataque("mago")
			_lanzar_meteoro_magma(dir_3d, enemigo, dano_ataque_actual, es_crit)
			registrar_dano_telemetria("armas", dano_ataque_actual)
			return
		"Custodio del Núcleo", "Titán Supremo del Núcleo", "Avatar del Núcleo":
			accion = "cast-magic"
			_reloj_anim_accion = 0.22
			if _anim_ctrl != null:
				_anim_ctrl.reproducir_accion("cast-magic", 2, 0.05, 1.2)
			var es_t3 = subclase_tier2 in ["Titán Supremo del Núcleo", "Avatar del Núcleo"]
			var mult_golpe = 1.15 if es_t3 else 1.10
			_ejecutar_golpe_avatar_resonancia(dir, dano_ataque_actual * mult_golpe, es_crit)
			registrar_dano_telemetria("armas", dano_ataque_actual * mult_golpe)
			return

	if clase in ["Novato", "Recluta del Coliseo"]:
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
							registrar_dano_telemetria("armas", dano_melee)
						VfxCombate.spawn_impacto(get_parent(), e.global_position + Vector3(0.0, 0.95, 0.0), Color(1.0, 0.84, 0.2) if es_crit else Color(0.28, 0.90, 1.0), Color.WHITE, 0.95, es_crit)
						AudioManager.play("golpe_impacto", randf_range(0.95, 1.15))
	elif clase in ["Guerrero", "Murmillo"]:
		# CORTE GIRATORIO MELEE EN ÁREA 360° (Whirlwind)
		_ejecutar_corte_giratorio_guerrero(false, es_crit, dano_ataque_actual)
	elif clase in ["Mago", "Arúspice"]:
		# Especialidad Mago/Arúspice: Orbe Arcano teledirigido con detonación en área AOE
		accion = "cast-magic"
		_reloj_anim_accion = 0.28
		if _anim_ctrl != null:
			_anim_ctrl.reproducir_accion("cast-magic", 2, 0.05, 1.1)
		_ejecutar_animacion_procedural_ataque("mago")
		_pulsar_orbe_mago()
		if ORBE_ARCANO_ESCENA != null:
			var cant_orbes = 1 + (1 if bendiciones_run.get("mago_orbe_triple", 0) > 0 else 0) + int(bendiciones_run.get("mago_orbe_triple", 0))
			var paso_orbe = 14.0
			var inicio_orbe = -((cant_orbes - 1) * paso_orbe) * 0.5
			var origen_m = global_position + Vector3(0, 0.9, 0)
			VfxCombate.spawn_destello_disparo(get_parent(), origen_m, dir_3d, Color(0.70, 0.35, 1.0), 0.72)
			for i in range(cant_orbes):
				var orbe = ORBE_ARCANO_ESCENA.instantiate()
				var dir_o = dir_3d.rotated(Vector3.UP, deg_to_rad(inicio_orbe + i * paso_orbe)).normalized()
				get_parent().add_child(orbe)
				orbe.iniciar(origen_m, dir_o, dano_ataque_actual, enemigo, "orbe_arcano")
			registrar_dano_telemetria("armas", dano_ataque_actual * float(cant_orbes))
	else:
		# Especialidad Cazador/Sagittario: Disparo múltiple de flechas (Multishot) en abanico
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
		var dano_flecha = dano_ataque_actual * 0.60
		var origen = global_position + Vector3(0, 0.9, 0)
		VfxCombate.spawn_destello_disparo(get_parent(), origen, dir_3d, Color(1.0, 0.85, 0.2) if es_crit else Color(0.20, 0.92, 1.0), 0.68)

		if PROYECTIL_ESCENA != null:
			var angulo_inicio = -((cant_flechas - 1) * angulo_paso) * 0.5
			for i in range(cant_flechas):
				var angulo = angulo_inicio + (i * angulo_paso)
				var dir_flecha = dir_3d.rotated(Vector3.UP, deg_to_rad(angulo)).normalized()
				var p = PROYECTIL_ESCENA.instantiate()
				get_parent().add_child(p)
				if "rebotes_restantes" in p:
					p.rebotes_restantes = rebotes_armas
				p.iniciar(origen, dir_flecha, dano_flecha, vel_flecha, perforaciones, es_crit, "flecha")
			registrar_dano_telemetria("armas", dano_flecha * float(cant_flechas))

func _crear_onda_solar(dir: Vector3, es_crit: bool, dano_onda: float) -> void:
	AudioManager.play("corte_espada", 1.25)
	var es_t3 = subclase_tier2 in ["Paladín del Sol Invictus", "Paladín Solar"]
	var r_onda = (rango_ataque + 1.8) if es_t3 else (rango_ataque + 1.2)
	_repeler_enemigos_alrededor(r_onda, 8.0, dano_onda)
	var parent_n := get_parent()
	VfxCombate.spawn_tajo(parent_n, global_position + Vector3(0.0, 0.95, 0.0), dir, r_onda * 0.92, Color(1.0, 0.80, 0.14), Color(1.0, 0.99, 0.85), Color(1.0, 0.42, 0.06), false, 0.24, 10.0)
	VfxCombate.spawn_explosion_nova(parent_n, global_position + Vector3(0.0, 0.45, 0.0) + dir * 1.1, r_onda * 0.72, Color(1.0, 0.72, 0.12), Color(1.0, 0.98, 0.82), 0.30, true, true)
	if es_t3 or es_crit:
		VfxCombate.spawn_columna_fuego(parent_n, global_position + dir * 1.8, 1.9, Color(1.0, 0.78, 0.18), Color(1.0, 0.98, 0.85), 0.34)

func _ejecutar_corte_giratorio_berserker(es_crit: bool, dano_corte: float) -> void:
	accion = "whirlwind"
	_reloj_anim_accion = 0.30
	var tiene_clip_whirl := _anim_ctrl != null and _anim_ctrl.tiene_clip("whirlwind")
	if _anim_ctrl != null:
		_anim_ctrl.reproducir_accion("whirlwind", 3, 0.04, 1.4)
	if not tiene_clip_whirl:
		_girar_modelo_360(0.24)
	AudioManager.play("corte_giratorio", 1.3)
	_crear_efecto_disco_cortante(rango_ataque + 0.65, true, es_crit)
	_repeler_enemigos_alrededor(rango_ataque + 0.8, 9.5, dano_corte)

func _disparar_riel_astral(dir: Vector3, dano_riel: float, es_crit: bool) -> void:
	AudioManager.play("disparo_arco", 1.45)
	var objetivos = _obtener_todos_los_enemigos()
	var origen = global_position + Vector3(0, 0.95, 0)
	var col_riel := Color(1.0, 0.84, 0.2) if es_crit else Color(0.20, 0.92, 1.0)
	VfxCombate.spawn_riel_laser(get_parent(), origen, dir, 13.0, col_riel, Color.WHITE, 0.28)
	var impacto_alguno := false
	for e in objetivos:
		if is_instance_valid(e) and e is Node3D:
			var hacia_e = (e.global_position - origen)
			hacia_e.y = 0.0
			var dist = hacia_e.length()
			if dist <= 13.0 and hacia_e.normalized().dot(dir) > 0.82:
				if e.has_method("recibir_dano"):
					e.recibir_dano(dano_riel, es_crit)
					impacto_alguno = true
				VfxCombate.spawn_impacto(get_parent(), e.global_position + Vector3(0.0, 0.95, 0.0), col_riel, Color.WHITE, 1.15, true)
	if impacto_alguno:
		AudioManager.play("golpe_impacto", 1.3)

func _disparar_espiral_dagas_sombras(dano_daga: float, es_crit: bool, cant_dagas: int = 8) -> void:
	AudioManager.play("corte_espada", 1.4)
	if PROYECTIL_ESCENA != null and get_parent() != null:
		var num_dagas = cant_dagas + proyectiles_extra
		var origen = global_position + Vector3(0, 0.8, 0)
		BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 0.25, 2.5, Color(0.70, 0.20, 1.0), 0.24)
		for i in range(num_dagas):
			var ang = (TAU / float(num_dagas)) * float(i)
			var dir_d = Vector3(cos(ang), 0.0, sin(ang)).normalized()
			var p = PROYECTIL_ESCENA.instantiate()
			get_parent().add_child(p)
			p.iniciar(origen, dir_d, dano_daga, 20.0, 1 + perforacion_armas, es_crit, "sombra")

func _crear_senuelo_sombra(pos: Vector3) -> void:
	if get_parent() == null:
		return
	var deco = Node3D.new()
	var mat_holo := BunkerVisualKit.create_hologram_material(Color(0.68, 0.18, 1.0), Color(0.95, 0.72, 1.0), 3.0, 28.0, 3.5)
	var cuerpo_m := MeshInstance3D.new()
	var caps := CapsuleMesh.new()
	caps.radius = 0.28
	caps.height = 1.25
	cuerpo_m.mesh = caps
	cuerpo_m.position = Vector3(0, 0.75, 0)
	cuerpo_m.material_override = mat_holo
	deco.add_child(cuerpo_m)

	var anillo_m := BunkerVisualKit.make_torus(deco, "AuraSenuelo", 0.55, 0.68, mat_holo, Vector3(0, 0.14, 0))
	get_parent().add_child(deco)
	deco.global_position = ArenaColiseo.clamping_y_ajustar_a_suelo(pos, 1.2, 0.0)
	var tw = deco.create_tween()
	tw.tween_property(anillo_m, "rotation:y", PI * 1.5, 0.22)
	tw.tween_callback(func():
		if is_instance_valid(self):
			_repeler_enemigos_alrededor(4.5, 10.0, dano * 1.25)
			registrar_dano_telemetria("armas", dano * 1.25)
			AudioManager.play("orbe_explosion", 1.4)
		if is_instance_valid(deco):
			VfxCombate.spawn_explosion_nova(deco.get_parent(), deco.global_position + Vector3(0, 0.6, 0), 3.6, Color(0.72, 0.20, 1.0), Color(0.98, 0.82, 1.0), 0.30, true, true)
			deco.queue_free()
	)

func _lanzar_orbe_vacio(dir: Vector3, enemigo: Node3D, dano_v: float, _es_crit: bool) -> void:
	if ORBE_ARCANO_ESCENA != null and get_parent() != null:
		var orbe = ORBE_ARCANO_ESCENA.instantiate()
		var origen = global_position + Vector3(0, 0.9, 0)
		get_parent().add_child(orbe)
		orbe.iniciar(origen, dir, dano_v, enemigo, "orbe_vacio")
		VfxCombate.spawn_destello_disparo(get_parent(), origen, dir, Color(0.60, 0.16, 1.0), 0.75)
		var pos_ref = enemigo.global_position if is_instance_valid(enemigo) else global_position + dir * 4.5
		var tw_sing = create_tween()
		tw_sing.tween_interval(0.32)
		tw_sing.tween_callback(func():
			if is_instance_valid(self):
				var p_dest = enemigo.global_position if is_instance_valid(enemigo) else pos_ref
				_crear_vortice_vacio(p_dest)
		)

func _crear_vortice_vacio(pos: Vector3) -> void:
	if get_parent() == null:
		return
	var pos_suelo := ArenaColiseo.clamping_y_ajustar_a_suelo(pos, 1.5, 0.04)
	var vortice: Node3D = VfxCombate.crear_zona_suelo_shader(
		get_parent(),
		pos_suelo,
		3.1,
		0,
		Color(0.58, 0.14, 1.00),
		Color(0.18, 0.03, 0.45),
		Color(0.95, 0.78, 1.00),
		2.5
	)
	if vortice == null:
		return
	var tick_state := [0.0]
	var tw = vortice.create_tween()
	tw.tween_method(func(_v):
		if not is_instance_valid(vortice):
			return
		var now = Time.get_ticks_msec() / 1000.0
		if now - tick_state[0] < 0.35:
			return
		tick_state[0] = now
		if not is_instance_valid(self):
			return
		for e in _obtener_todos_los_enemigos():
			if is_instance_valid(e) and e is Node3D:
				var dist = pos_suelo.distance_to(e.global_position)
				if dist <= 5.5 and dist > 0.4:
					var hacia = (pos_suelo - e.global_position).normalized()
					if e.has_method("aplicar_knockback"):
						e.aplicar_knockback(hacia * 4.5)
					if e.has_method("recibir_dano"):
						var mult_tick = 0.14 if (subclase_tier2 in ["Pontífice del Vacío Estelar", "Archimago del Vacío"]) else 0.16
						e.recibir_dano(dano * mult_tick, false)
						registrar_dano_telemetria("armas", dano * mult_tick)
	, 0.0, 1.0, 2.45)

func _lanzar_meteoro_magma(dir: Vector3, enemigo: Node3D, dano_m: float, _es_crit: bool) -> void:
	if ORBE_ARCANO_ESCENA != null and get_parent() != null:
		var orbe = ORBE_ARCANO_ESCENA.instantiate()
		var origen = global_position + Vector3(0, 0.9, 0)
		get_parent().add_child(orbe)
		orbe.iniciar(origen, dir, dano_m, enemigo, "orbe_magma")
		VfxCombate.spawn_destello_disparo(get_parent(), origen, dir, Color(1.0, 0.48, 0.08), 0.78)
		var pos_ref = enemigo.global_position if is_instance_valid(enemigo) else global_position + dir * 4.5
		var tw_m = create_tween()
		tw_m.tween_interval(0.32)
		tw_m.tween_callback(func():
			if is_instance_valid(self):
				var p_dest = enemigo.global_position if is_instance_valid(enemigo) else pos_ref
				_crear_charco_magma(p_dest)
		)

func _crear_charco_magma(pos: Vector3) -> void:
	if get_parent() == null:
		return
	var pos_suelo := ArenaColiseo.clamping_y_ajustar_a_suelo(pos, 1.5, 0.04)
	VfxCombate.spawn_explosion_nova(get_parent(), pos_suelo + Vector3(0, 0.2, 0), 2.5, Color(1.0, 0.44, 0.06), Color(1.0, 0.94, 0.48), 0.30, true, false)
	var charco: Node3D = VfxCombate.crear_zona_suelo_shader(
		get_parent(),
		pos_suelo,
		2.65,
		1,
		Color(1.00, 0.42, 0.06),
		Color(0.62, 0.10, 0.02),
		Color(1.00, 0.92, 0.45),
		2.8
	)
	if charco == null:
		return
	var tick_state := [0.0]
	var tw = charco.create_tween()
	tw.tween_method(func(_v):
		if not is_instance_valid(charco):
			return
		var now = Time.get_ticks_msec() / 1000.0
		if now - tick_state[0] < 0.35:
			return
		tick_state[0] = now
		if not is_instance_valid(self):
			return
		for e in _obtener_todos_los_enemigos():
			if is_instance_valid(e) and e is Node3D and charco.global_position.distance_to(e.global_position) <= 2.55:
				if e.has_method("recibir_dano"):
					var mult_burn = 0.16 if (subclase_tier2 in ["Señor del Magma Imperial", "Piromante Cataclísmico"]) else 0.18
					e.recibir_dano(dano * mult_burn, false)
					registrar_dano_telemetria("armas", dano * mult_burn)
	, 0.0, 1.0, 2.75)

func _ejecutar_golpe_avatar_resonancia(dir: Vector3, dano_g: float, _es_crit: bool) -> void:
	AudioManager.play("corte_espada", 1.35)
	_repeler_enemigos_alrededor(5.0, 10.0, dano_g * 1.25)
	VfxCombate.spawn_tajo(get_parent(), global_position + Vector3(0, 0.95, 0), dir, 4.2, Color(0.18, 0.94, 1.0), Color(1.0, 0.96, 0.55), Color(0.28, 0.55, 1.0), false, 0.24, 14.0)
	VfxCombate.spawn_tajo(get_parent(), global_position + Vector3(0, 1.05, 0), dir, 4.0, Color(1.0, 0.82, 0.18), Color.WHITE, Color(0.25, 0.92, 1.0), true, 0.22, 22.0)
	VfxCombate.spawn_explosion_nova(get_parent(), global_position + Vector3(0, 0.65, 0) + dir * 0.9, 4.4, Color(0.22, 0.92, 1.0), Color(1.0, 0.95, 0.65), 0.32, true, true)

func click_attack():
	# El combate es 100% automático (Autobattler continuo por proximidad).
	# La única interacción de clic permitida en el juego es sobre el Botón Móvil 3D.
	pass

func _girar_modelo_360(duracion: float) -> void:
	var modelo_nodo := get_node_or_null("Modelo") as Node3D
	if modelo_nodo == null:
		return
	if _tween_modelo_ataque != null and _tween_modelo_ataque.is_valid():
		_tween_modelo_ataque.kill()
	modelo_nodo.position = _modelo_pos_base
	modelo_nodo.rotation = _modelo_rot_base
	_tween_modelo_ataque = create_tween()
	_tween_modelo_ataque.tween_property(modelo_nodo, "rotation:y", _modelo_rot_base.y - TAU, maxf(0.12, duracion)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween_modelo_ataque.tween_callback(func():
		if is_instance_valid(modelo_nodo):
			modelo_nodo.rotation.y = _modelo_rot_base.y
	)


func _ejecutar_animacion_procedural_ataque(tipo_ataque: String):
	var mod = get_node_or_null("Modelo") as Node3D
	if mod == null:
		return
	if _tween_modelo_ataque != null and _tween_modelo_ataque.is_valid():
		_tween_modelo_ataque.kill()
		mod.position = _modelo_pos_base
	_tween_modelo_ataque = create_tween()
	match tipo_ataque:
		"melee":
			# Embestida sutil en el sitio para no deslizar ni levantar la pisada esquelética
			_tween_modelo_ataque.tween_property(mod, "position:z", _modelo_pos_base.z - 0.04, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tween_modelo_ataque.tween_property(mod, "position:z", _modelo_pos_base.z, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		"arco":
			# Micro retroceso al tensar (+Z) y retorno limpio al soltar (-Z)
			_tween_modelo_ataque.tween_property(mod, "position:z", _modelo_pos_base.z + 0.025, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tween_modelo_ataque.tween_property(mod, "position:z", _modelo_pos_base.z - 0.020, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tween_modelo_ataque.tween_property(mod, "position:z", _modelo_pos_base.z, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		"mago":
			# Sutil elevación arcana al proyectar hechizo sin despegar pies
			_tween_modelo_ataque.tween_property(mod, "position:y", _modelo_pos_base.y + 0.025, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tween_modelo_ataque.tween_property(mod, "position:y", _modelo_pos_base.y, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _pulsar_orbe_mago() -> void:
	if _luz_orbe_ref != null and is_instance_valid(_luz_orbe_ref):
		var tw_luz = create_tween()
		tw_luz.tween_property(_luz_orbe_ref, "light_energy", 3.6, 0.08)
		tw_luz.tween_property(_luz_orbe_ref, "light_energy", 1.6, 0.18)

func _crear_tajo_espada(dir_ataque: Vector3, es_critico: bool = false):
	if not is_inside_tree() or get_parent() == null:
		return
	var invertir_tajo: bool = not _turno_ataque_novato
	var c_main := Color(1.00, 0.84, 0.16) if es_critico else (Color(1.00, 0.56, 0.14) if es_arquetipo("Guerrero") else Color(0.20, 0.90, 1.00))
	var c_core := Color(1.00, 0.98, 0.85) if es_critico else Color(0.96, 0.99, 1.00)
	var c_edge := Color(1.00, 0.36, 0.06) if (es_critico or es_arquetipo("Guerrero")) else Color(0.08, 0.38, 0.95)
	var r_tajo := clampf(rango_ataque * 0.95, 2.3, 4.2)
	VfxCombate.spawn_tajo(
		get_parent(),
		Vector3(global_position.x, global_position.y + 0.92, global_position.z),
		dir_ataque,
		r_tajo,
		c_main,
		c_core,
		c_edge,
		invertir_tajo,
		0.20,
		15.0
	)
	if es_critico:
		VfxCombate.spawn_tajo(
			get_parent(),
			Vector3(global_position.x, global_position.y + 1.00, global_position.z),
			dir_ataque,
			r_tajo * 0.92,
			Color(1.00, 0.55, 0.10),
			Color.WHITE,
			c_main,
			not invertir_tajo,
			0.18,
			-18.0
		)

func recibir_dano(cantidad: float, fuente: String = ""):
	if fuente != "":
		ultimo_atacante_tipo = fuente
		ultimo_atacante_nombre = fuente.capitalize()
	else:
		var cercano = _obtener_enemigo_cercano()
		if cercano != null:
			if "tipo_enemigo_id" in cercano and str(cercano.tipo_enemigo_id) != "":
				ultimo_atacante_tipo = str(cercano.tipo_enemigo_id)
			elif cercano.scene_file_path != "":
				ultimo_atacante_tipo = cercano.scene_file_path.get_file().get_basename()
			else:
				ultimo_atacante_tipo = cercano.name
			ultimo_atacante_nombre = cercano.name.capitalize()
	if _procesando_recibir_dano:
		return
	_procesando_recibir_dano = true
	_recibir_dano_interno(cantidad)
	_procesando_recibir_dano = false

func _recibir_dano_interno(cantidad: float):
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
	var mitigacion_total = clampf(mitigacion_pasiva_pct + mitigacion_armadura, 0.0, 0.68)
	cantidad *= (1.0 - mitigacion_total)

	# 2. Mitigación por Bloqueo Activo de Escudo (Mecánica Tanque del Guerrero / Subclases)
	if bloqueando and es_arquetipo("Guerrero"):
		var dano_mitigado = cantidad * (1.0 - reduccion_dano_bloqueo)
		var mitigado_total = cantidad - dano_mitigado
		AudioManager.play("escudo_bloqueo", randf_range(0.95, 1.05))

		if bloqueo_genera_clics > 0:
			clics_disponibles += bloqueo_genera_clics
			clics_totales += bloqueo_genera_clics
			emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)

		_parpadear_escudo()
		_mostrar_feedback_bloqueo(mitigado_total, dano_mitigado)
		if subclase_tier2 in ["Secutor Radiante", "Paladín del Sol Invictus", "Paladín Solar"]:
			var es_t3 = subclase_tier2 in ["Paladín del Sol Invictus", "Paladín Solar"]
			var curacion = 10.0 if es_t3 else 4.0
			var mult_nova = 0.85 if es_t3 else 0.75
			var r_nova = 7.5 if es_t3 else 4.5
			vida = minf(vida + curacion, vida_maxima)
			_repeler_enemigos_alrededor(r_nova, 8.5, dano * mult_nova)
			registrar_dano_telemetria("armas", dano * mult_nova)
			_spawn_texto_3d("☀️ ¡%s! (+%d HP)" % ["SUPERNOVA SOLAR" if es_t3 else "NOVA SOLAR", int(curacion)], Color(1.0, 0.85, 0.2))
			AudioManager.play("altar_activado", 1.4)
		else:
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
		if _anim_ctrl != null and _anim_ctrl.esta_listo():
			_anim_ctrl.disparar_golpe()
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
	var xp_final = int(ceil(float(cantidad) * (1.0 + xp_ganada_pct) * multiplicador_abismo_recompensas))
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
			var factor_fiebre_oro: float = 1.0 + float(multiplicador_fiebre_actual - 1) * 0.35
			var bonus_mult = (1.0 + oro_por_baja_pct + (float(mejoras_arbol.get("mon_oro", 0)) * 0.25)) * factor_fiebre_oro * multiplicador_abismo_recompensas
			if ascension_suprema:
				bonus_mult *= 1.5
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
	ganar_xp(3)
	recoger_drop(0, 1)
	if evolucion_manager != null and evolucion_manager.has_method("notificar_baja"):
		evolucion_manager.notificar_baja()

func subir_nivel():
	xp = max(0, xp - xp_siguiente_nivel)
	nivel += 1
	xp_siguiente_nivel = int(round(float(xp_siguiente_nivel) * 1.32 + 18.0))

	# Escalado de especialidades por clase / arquetipo al subir nivel
	if es_arquetipo("Cazador"):
		base_cadencia_ataque = maxf(0.18, base_cadencia_ataque * 0.94)
		base_dano *= 1.08
	elif es_arquetipo("Guerrero"):
		base_dano *= 1.10
		base_rango_ataque = minf(4.0, base_rango_ataque + 0.05)
	elif es_arquetipo("Mago"):
		base_dano *= 1.12
	else:
		base_dano *= 1.08
		base_cadencia_ataque = maxf(0.45, base_cadencia_ataque * 0.96)

	recalcular_stats_incrementales()
	vida = minf(vida + maxf(8.0, vida_maxima * 0.10), vida_maxima)
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
	var tasa_ef: float = pct_total * 0.50
	var dividendo = mini(220, max(1, int(round(float(oro) * tasa_ef))))
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
		_escudo_visual.visible = (nombre_clase in ["Guerrero", "Murmillo", "Secutor Radiante", "Paladín del Sol Invictus", "Paladín Solar"] or (es_arquetipo("Guerrero") and bloqueando))

func _asegurar_armas_preview():
	equipar_armas_clase(clase)

func obtener_arquetipo_clase() -> String:
	return clase_base if clase_base != "Novato" and clase_base != "" else clase

func es_arquetipo(arq: String) -> bool:
	match arq:
		"Guerrero", "Murmillo":
			return clase in ["Guerrero", "Murmillo", "Secutor Radiante", "Provocator Sangriento", "Paladín del Sol Invictus", "Campeón Augusto de Sangre", "Paladín Solar", "Berserker Sangriento"] or clase_base in ["Guerrero", "Murmillo"]
		"Cazador", "Arquero", "Sagittario":
			return clase in ["Cazador", "Arquero", "Sagittario", "Velites Balístico", "Dimachaerus Espectral", "Centurión Balístico Astral", "Sombra del Anfiteatro", "Francotirador Astral", "Maestro de Sombras"] or clase_base in ["Cazador", "Arquero", "Sagittario"]
		"Mago", "Arúspice":
			return clase in ["Mago", "Arúspice", "Taumaturgo del Vacío", "Flamen Volcánico", "Pontífice del Vacío Estelar", "Señor del Magma Imperial", "Archimago del Vacío", "Piromante Cataclísmico"] or clase_base in ["Mago", "Arúspice"]
		_:
			return clase == arq or clase_base == arq

func aplicar_mejora_tier2(nombre_mejora: String):
	subclase_tier2 = nombre_mejora
	aplicar_clase(nombre_mejora)

func aplicar_subclase_tier3(nombre_subclase: String):
	subclase_tier2 = nombre_subclase
	aplicar_clase(nombre_subclase)

func aplicar_subclase_tier2(nombre_subclase: String):
	subclase_tier2 = nombre_subclase
	aplicar_clase(nombre_subclase)

func aplicar_clase(nombre: String):
	var ratio_vida_prev = clampf(vida / maxf(1.0, vida_maxima), 0.65, 1.0)
	clase = nombre
	match nombre:
		"Novato", "Recluta del Coliseo":
			clase_base = "Novato"
			subclase_tier2 = ""
			var orn_prev := get_node_or_null("OrnamentoTier")
			if orn_prev != null:
				remove_child(orn_prev)
				orn_prev.queue_free()
			base_vida_maxima = 100.0
			base_dano = 10.0
			base_rango_ataque = 2.6
			base_cadencia_ataque = 1.35
			base_speed_caminar = 3.4
			base_speed_correr = 5.4
		"Guerrero", "Murmillo":
			clase_base = "Guerrero"
			subclase_tier2 = ""
			base_vida_maxima = 160.0
			base_dano = 16.0
			base_rango_ataque = 3.2
			base_cadencia_ataque = 0.65
			base_speed_caminar = 3.2
			base_speed_correr = 5.6
		"Cazador", "Arquero", "Sagittario":
			clase_base = "Cazador"
			subclase_tier2 = ""
			base_vida_maxima = 100.0
			base_dano = 12.0
			base_rango_ataque = 7.5
			base_cadencia_ataque = 0.45
			base_speed_caminar = 3.8
			base_speed_correr = 6.4
		"Mago", "Arúspice":
			clase_base = "Mago"
			subclase_tier2 = ""
			base_vida_maxima = 85.0
			base_dano = 17.0
			base_rango_ataque = 5.5
			base_cadencia_ataque = 0.70
			base_speed_caminar = 3.3
			base_speed_correr = 5.7

		# TIER 2: Especializaciones del Coliseo
		"Secutor Radiante":
			clase_base = "Guerrero"
			subclase_tier2 = nombre
			base_vida_maxima = 190.0
			base_dano = 22.0
			base_rango_ataque = 3.4
			base_cadencia_ataque = 0.60
			bono_run_armadura_plana += 30.0
		"Provocator Sangriento":
			clase_base = "Guerrero"
			subclase_tier2 = nombre
			base_vida_maxima = 165.0
			base_dano = 19.0
			base_rango_ataque = 3.2
			base_cadencia_ataque = 0.48
		"Velites Balístico":
			clase_base = "Cazador"
			subclase_tier2 = nombre
			base_vida_maxima = 120.0
			base_dano = 16.0
			base_rango_ataque = 9.0
			base_cadencia_ataque = 0.38
			base_speed_caminar = 3.9
			base_speed_correr = 6.6
		"Dimachaerus Espectral":
			clase_base = "Cazador"
			subclase_tier2 = nombre
			base_vida_maxima = 125.0
			base_dano = 15.0
			base_rango_ataque = 6.0
			base_cadencia_ataque = 0.34
			bono_run_crit_prob += 0.10
			base_speed_caminar = 4.0
			base_speed_correr = 6.8
		"Taumaturgo del Vacío":
			clase_base = "Mago"
			subclase_tier2 = nombre
			base_vida_maxima = 110.0
			base_dano = 22.0
			base_rango_ataque = 6.2
			base_cadencia_ataque = 0.68
		"Flamen Volcánico":
			clase_base = "Mago"
			subclase_tier2 = nombre
			base_vida_maxima = 115.0
			base_dano = 22.0
			base_rango_ataque = 6.0
			base_cadencia_ataque = 0.68
		"Custodio del Núcleo":
			clase_base = "Novato"
			subclase_tier2 = nombre
			base_vida_maxima = 145.0
			base_dano = 20.0
			base_rango_ataque = 4.5
			base_cadencia_ataque = 0.52
			bono_subclase_onda_radio_mult = 1.5

		# TIER 3: Ascensión Definitiva
		"Paladín del Sol Invictus", "Paladín Solar":
			clase_base = "Guerrero"
			subclase_tier2 = nombre
			base_vida_maxima = 250.0
			base_dano = 32.0
			base_rango_ataque = 3.8
			base_cadencia_ataque = 0.52
			bono_run_armadura_plana += 60.0
		"Campeón Augusto de Sangre", "Berserker Sangriento":
			clase_base = "Guerrero"
			subclase_tier2 = nombre
			base_vida_maxima = 190.0
			base_dano = 28.0
			base_rango_ataque = 3.4
			base_cadencia_ataque = 0.40
		"Centurión Balístico Astral", "Francotirador Astral":
			clase_base = "Cazador"
			subclase_tier2 = nombre
			base_vida_maxima = 145.0
			base_dano = 24.0
			base_rango_ataque = 11.0
			base_cadencia_ataque = 0.30
			base_speed_caminar = 4.2
			base_speed_correr = 7.0
		"Sombra del Anfiteatro", "Maestro de Sombras":
			clase_base = "Cazador"
			subclase_tier2 = nombre
			base_vida_maxima = 150.0
			base_dano = 22.0
			base_rango_ataque = 6.5
			base_cadencia_ataque = 0.28
			bono_run_crit_prob += 0.20
			base_speed_caminar = 4.4
			base_speed_correr = 7.2
		"Pontífice del Vacío Estelar", "Archimago del Vacío":
			clase_base = "Mago"
			subclase_tier2 = nombre
			base_vida_maxima = 140.0
			base_dano = 32.0
			base_rango_ataque = 7.5
			base_cadencia_ataque = 0.62
		"Señor del Magma Imperial", "Piromante Cataclísmico":
			clase_base = "Mago"
			subclase_tier2 = nombre
			base_vida_maxima = 145.0
			base_dano = 32.0
			base_rango_ataque = 7.0
			base_cadencia_ataque = 0.62
		"Titán Supremo del Núcleo", "Avatar del Núcleo":
			clase_base = "Novato"
			subclase_tier2 = nombre
			base_vida_maxima = 180.0
			base_dano = 28.0
			base_rango_ataque = 5.5
			base_cadencia_ataque = 0.42
			bono_subclase_onda_radio_mult = 2.2

	if not es_arquetipo("Guerrero"):
		if bloqueando:
			_actualizar_estado_bloqueo(false)
		if _escudo_visual != null:
			_escudo_visual.visible = false
	else:
		_crear_escudo_visual()

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

	# Mejoras del Botón Móvil (Rama "boton")
	btn_calor_reduc_pct = 0.0
	btn_tamano_pct = 0.0
	btn_enfriamiento_pct = 0.0
	btn_ventana_ritmo_pct = 0.0
	btn_dano_perfecto_pct = 0.0
	btn_control_orbita_pct = 0.0
	btn_clics_bloqueo_extra = 0
	btn_calor_max_extra = 0.0
	btn_dano_termico_pct = 0.0
	btn_alcance_palancas = 0.0
	btn_frenesi_duracion_seg = 0.0
	btn_fiebre_eficiencia_pct = 0.0
	keystone_btn_criogenico = false
	keystone_btn_rompecadenas = false

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
			"btn_calor_reduc_pct":
				btn_calor_reduc_pct += (val * 0.01)
			"btn_tamano_pct":
				btn_tamano_pct += (val * 0.01)
			"btn_enfriamiento_pct":
				btn_enfriamiento_pct += (val * 0.01)
			"btn_ventana_ritmo_pct":
				btn_ventana_ritmo_pct += (val * 0.01)
				btn_dano_perfecto_pct += float(lvl) * 0.10
			"btn_control_orbita_pct":
				btn_control_orbita_pct += (val * 0.01)
			"btn_clics_bloqueo_extra":
				btn_clics_bloqueo_extra += int(val)
			"btn_calor_max_extra":
				btn_calor_max_extra += val
				btn_dano_termico_pct += float(lvl) * 0.12
			"btn_alcance_palancas":
				btn_alcance_palancas += val
			"btn_frenesi_duracion_seg":
				btn_frenesi_duracion_seg += val
			"btn_fiebre_eficiencia_pct":
				btn_fiebre_eficiencia_pct += (val * 0.01)
			"keystone_btn_criogenico":
				keystone_btn_criogenico = true
			"keystone_btn_rompecadenas":
				keystone_btn_rompecadenas = true

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

	var b_celeridad = int(bendiciones_run.get("celeridad_marcial", 0))
	if b_celeridad > 0:
		bonus_cadencia_pct += 0.18 * float(b_celeridad)

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

	# 6.5 Maestría Cósmica, Prestigio y Keystones Tier 6 (Sin duplicar lo ya sumado en match)
	MetaprogresoManager.asegurar_inicializado()
	var mult_prestigio = MetaprogresoManager.obtener_multiplicador_prestigio()
	if mult_prestigio > 1.0:
		bonus_dano_pct += (mult_prestigio - 1.0)
		bonus_dano_clic_pct += (mult_prestigio - 1.0)
	var lvl_inf_fortuna = float(mejoras_arbol.get("inf_fortuna_eterna", 0))
	if lvl_inf_fortuna > 0.0:
		oro_por_baja_pct += 0.02 * lvl_inf_fortuna
		xp_ganada_pct += 0.02 * lvl_inf_fortuna
	if int(mejoras_arbol.get("cosm_keystone_genesis", 0)) > 0:
		bonus_dano_pct += 0.50
		proyectiles_extra += 2
	if int(mejoras_arbol.get("cosm_corona_astral", 0)) > 0 and escudo_almas > 0.0:
		regen_vida_seg += 5.0 * float(mejoras_arbol.get("cosm_corona_astral", 0))

	bono_clics_tormento_mult = 1.0
	var _tree_tor = _obtener_tree()
	if _tree_tor != null:
		var _logros_tor = _tree_tor.get_first_node_in_group("logros_manager")
		if _logros_tor != null and _logros_tor.has_method("obtener_multiplicadores_tormento"):
			var mt: Dictionary = _logros_tor.obtener_multiplicadores_tormento()
			oro_por_baja_pct += float(mt.get("bono_oro_pct", 0.0))
			bono_clics_tormento_mult = 1.0 + float(mt.get("bono_clics_pct", 0.0))

	# 7. Consolidar estadísticas finales y Bendiciones Corruptas
	suerte_corrupta = 0.0
	if bendiciones_corruptas.has("corrupta_pacto_cristal"):
		vida_maxima = maxf(20.0, vida_maxima * 0.60)
		prob_critico += 0.25
	if bendiciones_corruptas.has("corrupta_hilo_corto"):
		bonus_cadencia_pct += 0.35
	if bendiciones_corruptas.has("corrupta_avaricia_sangrienta"):
		oro_por_baja_pct += 1.20
		bonus_dano_pct += 0.40
	if bendiciones_corruptas.has("corrupta_coloso_inamovible"):
		armadura_plana += 120.0
		resistencia_estados_pct = 1.0
	if bendiciones_corruptas.has("corrupta_destino_caotico"):
		suerte_corrupta = -0.35
		match _bonus_caotico_actual:
			"dano":
				bonus_dano_pct += _bonus_caotico_mult
			"cadencia":
				bonus_cadencia_pct += minf(0.45, _bonus_caotico_mult * 0.25)
			"critico":
				prob_critico += minf(0.65, _bonus_caotico_mult * 0.35)

	dano = (base_dano + bono_run_dano_plana) * (1.0 + bonus_dano_pct + bonus_dano_armas_pct) * bono_run_dano_mult
	if bendiciones_corruptas.has("corrupta_pacto_cristal"):
		dano *= 1.4
	cadencia_ataque = maxf(0.12, (base_cadencia_ataque * bono_run_cadencia_mult) * (1.0 - minf(bonus_cadencia_pct, 0.72)))
	speed_caminar = (base_speed_caminar + bono_run_vel_plana) * (1.0 + bonus_velocidad_mov_pct) * bono_run_vel_mult
	speed_correr = (base_speed_correr + bono_run_vel_plana) * (1.0 + bonus_velocidad_mov_pct) * bono_run_vel_mult
	if bendiciones_corruptas.has("corrupta_coloso_inamovible"):
		speed_caminar *= 0.75
		speed_correr *= 0.75

	if vida_maxima > vida_anterior_max:
		vida = minf(vida + (vida_maxima - vida_anterior_max), vida_maxima)
	vida = minf(vida, vida_maxima)

	escudo_almas = maxf(escudo_almas, max_escudo_almas)

	if not _muerto_definitivo:
		reapariciones = max(reapariciones, obtener_vidas_maximas() - 1)

	if has_node("Salud"):
		var s = get_node("Salud")
		s.vida = int(vida)
		s.vida_inicial = int(vida_maxima)
		s.reapariciones = reapariciones

	var _tree_btn = _obtener_tree()
	if _tree_btn != null:
		var _btn_mov = _tree_btn.get_first_node_in_group("boton_movil")
		if _btn_mov != null and _btn_mov.has_method("aplicar_mejoras_arbol"):
			_btn_mov.aplicar_mejoras_arbol()

	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)

func obtener_mejoras_boton() -> Dictionary:
	return {
		"calor_reduc_pct": btn_calor_reduc_pct,
		"tamano_pct": btn_tamano_pct,
		"enfriamiento_pct": btn_enfriamiento_pct,
		"ventana_ritmo_pct": btn_ventana_ritmo_pct,
		"dano_perfecto_pct": btn_dano_perfecto_pct,
		"control_orbita_pct": btn_control_orbita_pct,
		"clics_bloqueo_extra": btn_clics_bloqueo_extra,
		"calor_max_extra": btn_calor_max_extra,
		"dano_termico_pct": btn_dano_termico_pct,
		"alcance_palancas": btn_alcance_palancas,
		"frenesi_duracion_seg": btn_frenesi_duracion_seg,
		"fiebre_eficiencia_pct": btn_fiebre_eficiencia_pct,
		"keystone_criogenico": keystone_btn_criogenico,
		"keystone_rompecadenas": keystone_btn_rompecadenas,
	}

func puede_comprar_mejora(id: String) -> bool:
	var nodos = ArbolInterconectadoDatos.generar_arbol()
	if nodos.has(id):
		var n: SkillNodeData = nodos[id]
		return MetaprogresoManager.puede_comprar(n)
	return false

func comprar_mejora(id: String) -> bool:
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
	var inc_fiebre = (16.0 if es_perfecto else 8.5) * (1.0 + btn_fiebre_eficiencia_pct)
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

	# 2. Audio Dopamina Pentatónico y Cursor Táctico
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
		if PROYECTIL_ESCENA != null:
			var num_f = 6 + 2 * max(niv_dagas, 1)
			VfxCombate.spawn_destello_disparo(get_parent(), pos_boton + Vector3(0, 0.5, 0), Vector3.FORWARD, Color(0.20, 0.94, 1.0), 0.72)
			for i in range(num_f):
				var ang = (TAU / float(num_f)) * float(i)
				var dir_f = Vector3(cos(ang), 0.0, sin(ang)).normalized()
				var p = PROYECTIL_ESCENA.instantiate()
				get_parent().add_child(p)
				if "rebotes_restantes" in p:
					p.rebotes_restantes = (3 if sinergias_activas.has("sinergia_verdugo_cortes") else rebotes_armas)
				p.iniciar(pos_boton + Vector3(0, 0.5, 0), dir_f, dano * 0.85, 16.0, 2, sinergias_activas.has("sinergia_verdugo_cortes"), "clic_daga")

	var niv_onda_sismica = int(bendiciones_run.get("meteoro_orbital", 0)) + int(bendiciones_run.get("guerrero_onda_sismica", 0))
	if niv_onda_sismica > 0:
		_ejecutar_corte_giratorio_guerrero(true, es_perfecto, dano * (1.2 + 0.3 * float(niv_onda_sismica)))

	if bendiciones_run.has("nova_helada") or bendiciones_run.has("mago_singularidad_boton") or sinergias_activas.has("sinergia_singularidad_cursor") or sinergias_activas.has("sinergia_estrella_enana") or sinergias_activas.has("sinergia_horizonte_sucesos"):
		var niv_sing = max(int(bendiciones_run.get("nova_helada", 0)), int(bendiciones_run.get("mago_singularidad_boton", 1)))
		var radio_atr = 6.5 + 1.5 * float(niv_sing)
		VfxCombate.spawn_pulso_implosion(get_parent(), pos_boton, minf(radio_atr, 8.5), Color(0.55, 0.22, 1.0), Color(0.75, 0.96, 1.0), 0.30)
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
	var mult_fiebre_clk: int = 1 + int(floor(float(multiplicador_fiebre_actual - 1) * 0.5))
	var clics_ganados = clics_por_pulsacion * mult_fiebre_clk
	if ascension_suprema:
		clics_ganados = int(round(float(clics_ganados) * 1.5))
	if es_anomalia:
		clics_ganados += 3 * mult_fiebre_clk
	if multiplicador_abismo_recompensas > 1.0 or bono_clics_tormento_mult > 1.0:
		clics_ganados = int(round(float(clics_ganados) * bono_clics_tormento_mult * multiplicador_abismo_recompensas))

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
		VfxCombate.spawn_explosion_nova(get_parent(), global_position + Vector3(0, 0.3, 0), 5.2, Color(1.0, 0.32, 0.14), Color(1.0, 0.86, 0.45), 0.28, true, true)

	# Puente Dorada-Azul 3: Tempestad de Oro
	if tempestad_oro_dmg > 0.0:
		_repeler_enemigos_alrededor(5.5, 4.0, tempestad_oro_dmg)
		BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 0.4, 5.2, BunkerVisualKit.COL_VAULT_GOLD, 0.28)

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
			VfxCombate.spawn_explosion_nova(get_parent(), global_position + Vector3(0, 0.5, 0), 9.5, Color(0.18, 0.90, 1.0), Color.WHITE, 0.40, true, true)
			BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 0.8, 15.0, BunkerVisualKit.COL_CYAN_ELECTRIC, 0.44)
			if camara != null and camara.has_method("sacudir"):
				camara.sacudir(0.32)
			_spawn_texto_3d("⚡⚡ ¡CATACLISMO CINÉTICO!", Color(0.3, 0.85, 1.0))
			AudioManager.play("victoria", 1.25)

	if evolucion_manager != null:
		evolucion_manager.registrar_click()

	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)

func obtener_radio_atraccion_extra() -> float:
	return radio_iman_extra + bonus_nivel_iman

func obtener_bonus_onda_clic() -> Dictionary:
	var r_mult = (1.0 + (bonus_radio_aoe_clic * 0.20)) * bono_run_onda_radio_mult * bono_subclase_onda_radio_mult
	var d_mult = (1.0 + bonus_dano_clic_pct + penetracion_clic_pct * 0.5) * bono_run_onda_dano_mult
	if keystone_soberania:
		d_mult += 2.0
	if bendiciones_corruptas.has("corrupta_pacto_cristal"):
		d_mult *= 2.2
	if bendiciones_corruptas.has("corrupta_hilo_corto"):
		d_mult *= 2.5
	var r_extra = bonus_radio_aoe_clic * 0.5
	var m_empuje = 1.0 + bonus_empuje_clic_pct
	var es_crit = FortunaManager.tirar(prob_critico + bonus_critico_clic_prob)
	return {
		"radio_mult": r_mult,
		"dano_mult": d_mult,
		"radio_extra": r_extra,
		"mult_empuje": m_empuje,
		"mult_dano_clic": d_mult,
		"es_critico": es_crit
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
				if _boton_movil_ref == null or not is_instance_valid(_boton_movil_ref):
					_boton_movil_ref = get_tree().get_first_node_in_group("boton_movil") as Node3D
				if _boton_movil_ref != null and _boton_movil_ref.has_method("_detonar_onda_choque"):
					_boton_movil_ref._detonar_onda_choque(false)

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
	return suerte + suerte_arbol + suerte_corrupta + ReliquiaDatos.calcular_suerte(reliquias)

func activar_multiplicador_abismo(mult: float = 4.0) -> void:
	multiplicador_abismo_recompensas = maxf(1.0, mult)
	recalcular_stats_incrementales()

func obtener_suerte_total() -> float:
	if FortunaManager != null and FortunaManager.has_method("obtener_suerte_efectiva"):
		return FortunaManager.obtener_suerte_efectiva()
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
	VfxCombate.spawn_explosion_nova(get_parent(), global_position + Vector3(0, 0.5, 0), clampf(radio * 0.85, 2.5, 8.0), Color(1.0, 0.48, 0.08), Color(1.0, 0.95, 0.65), 0.36, true, true)
	if camara != null and camara.has_method("sacudir"):
		camara.sacudir(0.28)

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
	var pool = get_tree().get_first_node_in_group("damage_numbers") if get_tree() != null else null
	if pool != null and pool.has_method("mostrar_texto"):
		pool.mostrar_texto(global_position + Vector3(0, 2.3, 0), texto, color, 1.0)
		return
	var escena = ESCENA_DAMAGE_NUMBER_3D
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
	VfxCombate.spawn_explosion_nova(get_parent(), global_position + Vector3(0, 0.5, 0), 5.5, Color(0.22, 0.90, 1.0), Color.WHITE, 0.34, true, true)
	var enemigos = _obtener_todos_los_enemigos()
	var rayos_vis := 0
	for e in enemigos:
		if is_instance_valid(e) and e is Node3D:
			if global_position.distance_to(e.global_position) <= 24.0:
				if e.has_method("recibir_dano"):
					e.recibir_dano(dano_descarga, true)
				if rayos_vis < 10:
					rayos_vis += 1
					VfxCombate.spawn_rayo_celestial(get_parent(), e.global_position, Color(0.22, 0.90, 1.0), Color.WHITE, 14.0, 0.28)
	if rayos_vis == 0:
		VfxCombate.spawn_rayo_celestial(get_parent(), global_position + Vector3(2.2, 0.0, -1.8), Color(0.22, 0.90, 1.0), Color.WHITE, 14.0, 0.28)
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
	if bloqueando and es_arquetipo("Guerrero"):
		var rapidez = Vector2(velocity.x, velocity.z).length()
		if rapidez < 0.2:
			if _anim_ctrl.tiene_clip("holding-both"):
				_anim_ctrl.reproducir_bucle("holding-both", 0.14, 1.0, 1)
				return
		else:
			var vel_blq := clampf(rapidez / maxf(1.0, speed_caminar * velocidad_bloqueo_multiplicador), 0.72, 1.35)
			_anim_ctrl.reproducir_bucle("block-walk", 0.14, vel_blq, 1)
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
				print("[prueba] pos: ", global_position.snappedf(0.01), " · vel: ", snappedf(r, 0.01), " · anim: ", anim.current_animation if anim != null else "null")
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
				print("cuadro ", _cuadro, ": ", snappedf(r, 0.01), " · anim: ", anim.current_animation if anim != null else "null")
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
	var panel_central = BoxMesh.new()
	panel_central.size = Vector3(0.88, 1.15, 0.06)
	mesh_inst.mesh = panel_central

	var mat_holo = BunkerVisualKit.create_hologram_material(Color(0.18, 0.84, 1.0), Color(0.85, 0.98, 1.0), 2.4, 30.0, 2.8)
	mesh_inst.material_override = mat_holo
	_escudo_visual.add_child(mesh_inst)

	var mat_borde = BunkerVisualKit.get_titanium_mat()
	BunkerVisualKit.make_box(_escudo_visual, "MarcoSup", Vector3(1.42, 0.07, 0.09), mat_borde, Vector3(0, 0.59, 0))
	BunkerVisualKit.make_box(_escudo_visual, "MarcoInf", Vector3(1.36, 0.07, 0.09), mat_borde, Vector3(0, -0.59, 0))
	for lado in [-1.0, 1.0]:
		var ala = MeshInstance3D.new()
		var wing_mesh = BoxMesh.new()
		wing_mesh.size = Vector3(0.38, 1.08, 0.06)
		ala.mesh = wing_mesh
		ala.material_override = mat_holo
		ala.position = Vector3(lado * 0.56, 0.0, 0.09)
		ala.rotation_degrees.y = lado * -26.0
		_escudo_visual.add_child(ala)

	_escudo_visual.position = Vector3(0, 0.95, -0.72)
	_escudo_visual.visible = false
	add_child(_escudo_visual)

func _parpadear_escudo():
	if _escudo_visual == null or not is_instance_valid(_escudo_visual):
		return
	var mesh_inst = _escudo_visual.get_child(0) as MeshInstance3D
	if mesh_inst != null and mesh_inst.material_override is ShaderMaterial:
		var mat = mesh_inst.material_override as ShaderMaterial
		var tw = create_tween()
		tw.tween_method(
			func(e: float):
				if is_instance_valid(mat):
					mat.set_shader_parameter("energy", e),
			4.8,
			2.4,
			0.18
		)
	elif mesh_inst != null and mesh_inst.material_override is StandardMaterial3D:
		var mat_s = mesh_inst.material_override as StandardMaterial3D
		var tw_s = create_tween()
		tw_s.tween_property(mat_s, "emission_energy_multiplier", 4.5, 0.06)
		tw_s.tween_property(mat_s, "emission_energy_multiplier", 2.0, 0.15)
	VfxCombate.spawn_impacto(get_parent(), global_position + (-global_transform.basis.z * 0.85) + Vector3(0, 0.95, 0), Color(0.22, 0.92, 1.0), Color.WHITE, 0.85, false)

func _obtener_tree() -> SceneTree:
	if is_inside_tree():
		return get_tree()
	return Engine.get_main_loop() as SceneTree

func _mostrar_feedback_bloqueo(mitigado: float, _recibido: float):
	_spawn_texto_3d("🛡️ BLOQUEO (-%d)" % int(mitigado), Color(0.2, 0.8, 1.0))

func _repeler_enemigos_alrededor(radio: float, fuerza: float, dano_extra: float = 0.0):
	var enemigos = _obtener_todos_los_enemigos()
	var radio_sq := radio * radio
	var mi_pos := global_position
	for e in enemigos:
		if is_instance_valid(e) and e is Node3D:
			if "muerto" in e and e.muerto:
				continue
			var dist_sq = mi_pos.distance_squared_to(e.global_position)
			if dist_sq <= radio_sq:
				if dano_extra > 0.0 and e.has_method("recibir_dano"):
					e.recibir_dano(dano_extra, false)

				var es_jefe: bool = e.is_in_group("jefes") or e.is_in_group("bosses") or ("es_jefe" in e and e.es_jefe)
				if es_jefe:
					_reaccionar_inmunidad_empuje_jefe(e)
					continue

				var dir = (e.global_position - global_position).normalized()
				dir.y = 0.0
				if e.has_method("aplicar_knockback"):
					e.aplicar_knockback(dir * fuerza)
				elif "velocity" in e:
					e.velocity += dir * fuerza

func _reaccionar_inmunidad_empuje_jefe(jefe: Node3D) -> void:
	if _cooldown_inmunidad_jefe > 0.0 or not is_inside_tree() or get_parent() == null:
		return
	_cooldown_inmunidad_jefe = 0.45
	var pos_mid := (global_position + jefe.global_position) * 0.5
	pos_mid.y = global_position.y + 0.12
	BunkerVisualKit.spawn_shockwave_ring(get_parent(), pos_mid, 0.35, 3.2, Color(1.0, 0.28, 0.35), 0.35)
	VfxCombate.spawn_impacto(get_parent(), pos_mid + Vector3(0.0, 0.45, 0.0), Color(1.0, 0.45, 0.35), Color.WHITE, 0.95, true)
	AudioManager.play("escudo_bloqueo", 0.85, 1.0)
	var dir_rebote := (global_position - jefe.global_position).normalized()
	dir_rebote.y = 0.0
	empuje += dir_rebote * 4.2
	_spawn_texto_3d("⛔ ¡JEFE INAMOVIBLE!", Color(1.0, 0.35, 0.35))

func _ejecutar_corte_giratorio_guerrero(es_click: bool = false, es_crit: bool = false, dano_custom: float = -1.0):
	accion = "whirlwind"
	_reloj_anim_accion = 0.36
	var tiene_clip_whirl := _anim_ctrl != null and _anim_ctrl.tiene_clip("whirlwind")
	if _anim_ctrl != null:
		_anim_ctrl.reproducir_accion("whirlwind", 3, 0.05, 1.2)
	
	AudioManager.play("corte_giratorio", randf_range(0.95, 1.15))
	if not tiene_clip_whirl:
		_girar_modelo_360(0.28)
	_crear_efecto_disco_cortante(rango_ataque, false, es_crit or es_click)

	var enemigos: Array = _obtener_todos_los_enemigos()
	if is_inside_tree() and get_tree() != null:
		enemigos.append_array(get_tree().get_nodes_in_group("rompibles"))
	var dano_base_calc = dano if dano_custom <= 0.0 else dano_custom
	var dano_aplicar = dano_base_calc * (1.25 if es_click else 1.0)

	var r_corte_sq := (rango_ataque + 0.6) * (rango_ataque + 0.6)
	var mi_pos := global_position
	for e in enemigos:
		if is_instance_valid(e) and e is Node3D:
			if "muerto" in e and e.muerto:
				continue
			if mi_pos.distance_squared_to(e.global_position) <= r_corte_sq:
				if e.has_method("recibir_dano"):
					e.recibir_dano(dano_aplicar, es_crit or es_click)

				var es_jefe: bool = e.is_in_group("jefes") or e.is_in_group("bosses") or ("es_jefe" in e and e.es_jefe)
				if es_jefe:
					_reaccionar_inmunidad_empuje_jefe(e)
					continue

				var dir_empuje = (e.global_position - global_position).normalized()
				dir_empuje.y = 0.0
				var f_emp = 8.5 if es_click else 6.0
				if e.has_method("aplicar_knockback"):
					e.aplicar_knockback(dir_empuje * f_emp)
				elif "velocity" in e:
					e.velocity += dir_empuje * f_emp

func _crear_efecto_disco_cortante(radio: float, es_berserker: bool = false, es_crit: bool = false):
	if not is_inside_tree() or get_parent() == null:
		return
	var c_main := Color(1.00, 0.16, 0.22) if es_berserker else (Color(1.00, 0.84, 0.16) if es_crit else Color(1.00, 0.62, 0.14))
	var c_core := Color(1.00, 0.78, 0.72) if es_berserker else Color(1.00, 0.98, 0.82)
	var c_edge := Color(0.58, 0.04, 0.18) if es_berserker else Color(0.95, 0.28, 0.06)
	VfxCombate.spawn_torbellino(get_parent(), global_position + Vector3(0, 0.86, 0), maxf(radio * 1.08, 2.2), c_main, c_core, c_edge, 0.28)

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
		if _estado_juicio_emperador:
			return
		var tree = _obtener_tree()
		if tree != null:
			var favor_mgr = tree.get_first_node_in_group("favor_emperador_manager")
			if favor_mgr != null and favor_mgr.has_method("intentar_juicio_emperador_al_morir"):
				if favor_mgr.intentar_juicio_emperador_al_morir(self):
					_estado_juicio_emperador = true
					_reloj_invulnerable = 999.0
					return

		finalizar_muerte_definitiva()

func revivir_por_emperador(fraccion_hp: float = 0.60) -> void:
	_estado_juicio_emperador = false
	_muerto_definitivo = false
	vida = vida_maxima * clampf(fraccion_hp, 0.15, 1.0)
	_reloj_invulnerable = 3.0
	_repeler_enemigos_alrededor(12.0, 16.0, dano * 2.0)
	AudioManager.play("victoria", 1.4)
	_spawn_texto_3d("👑 ¡EL EMPERADOR CONCEDE CLEMENCIA!", Color(1.0, 0.85, 0.2))
	if has_node("Salud"):
		var s = get_node("Salud")
		s.vida = int(vida)
		s.cambio.emit(s.vida)
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

func finalizar_muerte_definitiva() -> void:
	_muerto_definitivo = true
	_estado_juicio_emperador = false
	vida = 0.0
	if _tween_modelo_ataque != null and _tween_modelo_ataque.is_valid():
		_tween_modelo_ataque.kill()
		_tween_modelo_ataque = null
	var mod := get_node_or_null("Modelo") as Node3D
	if mod != null:
		mod.position = _modelo_pos_base
		mod.rotation = _modelo_rot_base
	if _anim_ctrl != null and _anim_ctrl.esta_listo():
		_anim_ctrl.reproducir_muerte(1.0)

	MetaprogresoManager.registrar_nemesis_verdugo(ultimo_atacante_tipo, ultimo_atacante_nombre, oro, clics_disponibles)

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
				partida.perder("Caíste ante %s" % ultimo_atacante_nombre)
			else:
				partida.perder("Agotaste tus %d vidas ante %s" % [obtener_vidas_maximas(), ultimo_atacante_nombre])

func aplicar_bendicion_corrupta(id_corrupta: String) -> void:
	if id_corrupta == "":
		return
	if not bendiciones_corruptas.has(id_corrupta):
		bendiciones_corruptas.append(id_corrupta)
	match id_corrupta:
		"corrupta_pacto_cristal":
			_spawn_texto_3d("🩸 PACTO CRISTAL: -40% HP · x2.2 CLIC", Color(0.95, 0.15, 0.30))
		"corrupta_hilo_corto":
			_spawn_texto_3d("⚡ HILO CORTO: x2.5 ONDA · 5.5m RANGO", Color(0.4, 0.9, 1.0))
		"corrupta_avaricia_sangrienta":
			_spawn_texto_3d("🪙 AVARICIA SANGRIENTA: -1 HP/s · +120% ORO", Color(1.0, 0.8, 0.1))
		"corrupta_coloso_inamovible":
			_spawn_texto_3d("🗿 COLOSO INAMOVIBLE: +120 ARMADURA · SIN DASH", Color(0.8, 0.7, 0.5))
		"corrupta_destino_caotico":
			_spawn_texto_3d("🎲 DESTINO CAÓTICO: Bonos Aleatorios c/20s", Color(0.9, 0.4, 1.0))
			_cooldown_rotacion_caotica = 0.05
		"corrupta_sobrecarga_sin_freno":
			_spawn_texto_3d("🔥 SOBRECARGA SIN FRENO: x5 FRENESÍ c/12 CLICS", Color(1.0, 0.3, 0.1))
	recalcular_stats_incrementales()
	corrupta_aplicada.emit(id_corrupta)

func tiene_corrupta_sobrecarga_sin_freno() -> bool:
	return bendiciones_corruptas.has("corrupta_sobrecarga_sin_freno")

func registrar_dano_telemetria(fuente: String, cantidad: float) -> void:
	if cantidad <= 0.0:
		return
	var t_ahora = Time.get_ticks_msec() / 1000.0
	_telemetria_registros.append({
		"tiempo": t_ahora,
		"fuente": fuente,
		"cantidad": cantidad
	})
	_dano_total_acumulado += cantidad

func obtener_telemetria_dps() -> Dictionary:
	var t_ahora = Time.get_ticks_msec() / 1000.0
	var t_limite = t_ahora - 5.0
	var dps_total := 0.0
	var dps_armas := 0.0
	var dps_onda := 0.0
	var dps_hilo := 0.0

	var nuevos_registros: Array = []
	for r in _telemetria_registros:
		if r["tiempo"] >= t_limite:
			nuevos_registros.append(r)
			var cant: float = r["cantidad"]
			dps_total += cant
			match r["fuente"]:
				"armas":
					dps_armas += cant
				"onda":
					dps_onda += cant
				"hilo":
					dps_hilo += cant
				_:
					dps_armas += cant
	_telemetria_registros = nuevos_registros

	return {
		"dps_total": dps_total / 5.0,
		"dps_armas": dps_armas / 5.0,
		"dps_onda": dps_onda / 5.0,
		"dps_hilo": dps_hilo / 5.0,
		"dano_total_acumulado": _dano_total_acumulado,
		"ventana_segundos": 5.0
	}

func notificar_baja_enemigo(_tipo: String = "", _pos: Vector3 = Vector3.ZERO) -> void:
	if bendiciones_corruptas.has("corrupta_avaricia_sangrienta"):
		vida = minf(vida + 3.0, vida_maxima)
	if subclase_tier2 == "Berserker Sangriento":
		vida = minf(vida + 3.0, vida_maxima)
	registrar_baja()

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
