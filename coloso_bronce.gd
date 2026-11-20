extends CharacterBody3D

# Jefe 4: Coloso de Bronce (Minuto 13:30)
# Titán colosal acorazado. 9500 HP.
# Incluye Coraza de Bronce/Magma rompible con el Núcleo (3 y 4 clics), interrupción de Pisada Sísmica y Knockback físico real.

signal jefe_derrotado

const AudioManager = preload("res://audio_manager.gd")
const ArenaColiseo = preload("res://arena_coliseo.gd")

@export var rapidez: float = 3.2
@export var vida_maxima: float = 22000.0
@export var dano_pisada: float = 115.0
@export var radio_pisada: float = 5.8
@export var tiempo_telegraph: float = 0.70
@export var duracion_vulnerabilidad: float = 3.5
@export var mult_dano_vulnerable: float = 2.0

var vida: float = 22000.0
var muerto: bool = false
var jugador: Node3D = null
var hud: Node = null
var _boton_movil: Node = null

var _reloj_ataque: float = 0.0
var _esta_telegrafando: bool = false
var _coraza_activa: bool = false
var _fase1_usada: bool = false
var _fase2_usada: bool = false
var _clics_coraza: int = 0
var _clics_necesarios_coraza: int = 3
var _aturdido: bool = false
var _en_enrage: bool = false
var _reloj_vulnerabilidad: float = 0.0
var _ultimo_seg_vuln_hud: int = -1
var _luz_color_base: Color = Color(1.0, 0.55, 0.15, 1.0)
var _luz_energia_base: float = 2.0
var _knockback_velocity: Vector3 = Vector3.ZERO
var _i_frame_timer: float = 0.0

# Controlador de 3 Fases y Stagger + Peligros Fase 2 (Zonas de Magma)
var _fase_ctrl: JefeFaseController = null
var _zonas_magma_f2: Array = []
var _reloj_magma_f2: float = 0.0
var _reloj_tick_magma_f2: float = 0.0

var _escudo_bronce_mesh: Node3D = null
var _escudo_burbuja: MeshInstance3D = null
var _escudo_anillo1: MeshInstance3D = null
var _escudo_anillo2: MeshInstance3D = null
var _escudo_anillo_suelo: MeshInstance3D = null

var _escala_base: Vector3 = Vector3.ONE
var _anim_ctrl: AnimadorEntidad = AnimadorEntidad.new()
var _decal_pisada: ThreatDecal3D = null
var _nav_estado: Dictionary = {}

@onready var modelo: Node3D = $Modelo if has_node("Modelo") else null
@onready var telegraph_mesh: MeshInstance3D = $TelegraphPisada if has_node("TelegraphPisada") else null
@onready var luz_coloso: OmniLight3D = $LuzColoso

func _ready():
	add_to_group("enemigos")
	add_to_group("enemies")
	add_to_group("jefes")
	add_to_group("bosses")
	ArenaColiseo.configurar_cuerpo_terreno(self, false, true)
	vida = vida_maxima
	if modelo != null:
		_escala_base = modelo.scale
		_anim_ctrl.vincular_modelo(modelo)
	jugador = get_tree().get_first_node_in_group("jugador")
	hud = get_tree().get_first_node_in_group("hud")
	if hud == null:
		hud = get_parent().get_node_or_null("ClickHUD")

	if telegraph_mesh != null:
		telegraph_mesh.visible = false
		telegraph_mesh.queue_free()
		telegraph_mesh = null
	_decal_pisada = BunkerVisualKit.create_threat_decal(self, "DecalPisadaColoso")
	_decal_pisada.configurar_circulo(radio_pisada + 1.0, Color(0.95, 0.30, 0.06, 1.0), Color(1.0, 0.62, 0.12, 1.0), Color(1.0, 0.88, 0.36, 1.0))
	if luz_coloso != null:
		_luz_color_base = luz_coloso.light_color
		_luz_energia_base = luz_coloso.light_energy

	_crear_coraza_visual()

	_fase_ctrl = JefeFaseController.new()
	_fase_ctrl.name = "JefeFaseController"
	_fase_ctrl.configurar(self, 7, 5.5, 14.0, 18.0)
	add_child(_fase_ctrl)
	_fase_ctrl.fase_cambiada.connect(_on_fase_cambiada)
	_fase_ctrl.stagger_iniciado.connect(_on_stagger_iniciado)
	_fase_ctrl.stagger_progreso.connect(_on_stagger_progreso)
	_fase_ctrl.stagger_completado.connect(_on_stagger_completado)
	_fase_ctrl.stagger_fallado.connect(_on_stagger_fallado)
	_fase_ctrl.conmocion_terminada.connect(_on_conmocion_terminada)

	call_deferred("_conectar_boton_movil")
	AudioManager.play("jefe_alerta", 0.8, 3.0)

	if hud != null and hud.has_method("mostrar_barra_jefe"):
		hud.mostrar_barra_jefe("🌋 COLOSO DE BRONCE", vida_maxima, vida)

func _exit_tree() -> void:
	if _decal_pisada != null and is_instance_valid(_decal_pisada):
		_decal_pisada.cancelar()
	_limpiar_zonas_magma_f2(true)
	if _fase_ctrl != null and is_instance_valid(_fase_ctrl):
		_fase_ctrl.limpiar(hud, true)

func aplicar_knockback(impulso: Vector3, _duracion_stun: float = 0.08):
	var kb = impulso * 0.35
	kb.y = 0.0
	_knockback_velocity += kb
	if _knockback_velocity.length() > 10.0:
		_knockback_velocity = _knockback_velocity.normalized() * 10.0

func _crear_coraza_visual():
	_escudo_bronce_mesh = Node3D.new()
	_escudo_bronce_mesh.name = "CorazaBronceVisual"

	# 1. Burbuja cristalina de alta transparencia (no opaca, deja ver 100% el modelo)
	_escudo_burbuja = MeshInstance3D.new()
	var esfera = SphereMesh.new()
	esfera.radius = 2.9
	esfera.height = 5.6
	_escudo_burbuja.mesh = esfera
	_escudo_burbuja.position = Vector3(0, 2.7, 0)

	var mat_burbuja = StandardMaterial3D.new()
	mat_burbuja.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_burbuja.albedo_color = Color(1.0, 0.72, 0.2, 0.08)
	mat_burbuja.roughness = 0.08
	mat_burbuja.metallic = 0.8
	mat_burbuja.rim_enabled = true
	mat_burbuja.rim = 1.0
	mat_burbuja.rim_tint = 0.6
	mat_burbuja.emission_enabled = true
	mat_burbuja.emission = Color(1.0, 0.65, 0.15)
	mat_burbuja.emission_energy_multiplier = 0.30
	mat_burbuja.cull_mode = BaseMaterial3D.CULL_BACK
	_escudo_burbuja.material_override = mat_burbuja
	_escudo_bronce_mesh.add_child(_escudo_burbuja)

	# 2. Anillo orbital horizontal de energía rúnica
	_escudo_anillo1 = MeshInstance3D.new()
	var t1 = TorusMesh.new()
	t1.outer_radius = 2.85
	t1.inner_radius = 2.72
	t1.rings = 36
	t1.ring_segments = 8
	_escudo_anillo1.mesh = t1
	_escudo_anillo1.position = Vector3(0, 2.7, 0)
	var mat_anillo1 = StandardMaterial3D.new()
	mat_anillo1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_anillo1.albedo_color = Color(1.0, 0.80, 0.25, 0.85)
	mat_anillo1.emission_enabled = true
	mat_anillo1.emission = Color(1.0, 0.75, 0.2)
	mat_anillo1.emission_energy_multiplier = 1.2
	_escudo_anillo1.material_override = mat_anillo1
	_escudo_bronce_mesh.add_child(_escudo_anillo1)

	# 3. Segundo anillo orbital inclinado
	_escudo_anillo2 = MeshInstance3D.new()
	var t2 = TorusMesh.new()
	t2.outer_radius = 2.7
	t2.inner_radius = 2.58
	t2.rings = 36
	t2.ring_segments = 8
	_escudo_anillo2.mesh = t2
	_escudo_anillo2.position = Vector3(0, 2.3, 0)
	_escudo_anillo2.rotation_degrees = Vector3(25.0, 0.0, 18.0)
	var mat_anillo2 = mat_anillo1.duplicate() as StandardMaterial3D
	_escudo_anillo2.material_override = mat_anillo2
	_escudo_bronce_mesh.add_child(_escudo_anillo2)

	# 4. Anillo rúnico a ras de suelo
	_escudo_anillo_suelo = MeshInstance3D.new()
	var t_suelo = TorusMesh.new()
	t_suelo.outer_radius = 3.2
	t_suelo.inner_radius = 3.05
	t_suelo.rings = 40
	t_suelo.ring_segments = 8
	_escudo_anillo_suelo.mesh = t_suelo
	_escudo_anillo_suelo.position = Vector3(0, 0.08, 0)
	var mat_suelo = mat_anillo1.duplicate() as StandardMaterial3D
	mat_suelo.albedo_color = Color(1.0, 0.75, 0.2, 0.7)
	_escudo_anillo_suelo.material_override = mat_suelo
	_escudo_bronce_mesh.add_child(_escudo_anillo_suelo)

	_escudo_bronce_mesh.visible = false
	add_child(_escudo_bronce_mesh)

func _conectar_boton_movil():
	_boton_movil = get_tree().get_first_node_in_group("boton_movil")
	if _boton_movil != null:
		if not _boton_movil.click_presionado.is_connected(_on_boton_click):
			_boton_movil.click_presionado.connect(_on_boton_click)

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	if _i_frame_timer > 0.0:
		_i_frame_timer = maxf(_i_frame_timer - delta, 0.0)

	if _boton_movil == null or not is_instance_valid(_boton_movil):
		_conectar_boton_movil()

	_anim_ctrl.actualizar(delta)
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 14.0 * delta)
	_actualizar_zonas_magma_f2(delta)
	if _fase_ctrl != null:
		_fase_ctrl.actualizar(delta, hud, not muerto)
		if _fase_ctrl.fase_actual != JefeFaseController.FaseJefe.FASE_1 and not muerto:
			_reloj_magma_f2 -= delta
			if _reloj_magma_f2 <= 0.0 and not _fase_ctrl.esta_conmocionado():
				_reloj_magma_f2 = 4.4 if _en_enrage else 5.4
				_invocar_zonas_magma_f2(2 if _en_enrage else 1)

	if _escudo_bronce_mesh != null and _escudo_bronce_mesh.visible:
		if _escudo_anillo1 != null:
			_escudo_anillo1.rotate_y(delta * 1.8)
		if _escudo_anillo2 != null:
			_escudo_anillo2.rotate_y(-delta * 2.2)
		if _escudo_anillo_suelo != null:
			_escudo_anillo_suelo.rotate_y(delta * 0.9)

	if _reloj_vulnerabilidad > 0.0:
		_reloj_vulnerabilidad = maxf(_reloj_vulnerabilidad - delta, 0.0)
		if luz_coloso != null:
			var pulso := 0.5 + 0.5 * sin(_reloj_vulnerabilidad * 10.0)
			luz_coloso.light_color = Color(1.0, 0.88, 0.30).lerp(Color(0.35, 0.95, 1.0), pulso * 0.45)
			luz_coloso.light_energy = _luz_energia_base * (1.55 + 0.55 * pulso)
		var seg_actual := int(ceil(_reloj_vulnerabilidad))
		if _reloj_vulnerabilidad <= 0.0:
			_terminar_vulnerabilidad()
		elif seg_actual != _ultimo_seg_vuln_hud:
			_ultimo_seg_vuln_hud = seg_actual
			_actualizar_hud()

	var bloqueado_por_fase := _fase_ctrl != null and (_fase_ctrl.esta_en_transicion() or _fase_ctrl.esta_canalizando() or _fase_ctrl.esta_conmocionado())
	if _aturdido or _esta_telegrafando or bloqueado_por_fase:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta) + _knockback_velocity.x
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta) + _knockback_velocity.z
		var es_stun_anim := _aturdido or (_fase_ctrl != null and _fase_ctrl.esta_conmocionado())
		_anim_ctrl.reproducir_bucle("stunned" if es_stun_anim else "telegraph", 0.12, 1.0, 1)
		move_and_slide()
		return

	_reloj_ataque = maxf(_reloj_ataque - delta, 0.0)

	if is_instance_valid(jugador) and jugador is Node3D:
		var dir = (jugador.global_position - global_position)
		dir.y = 0.0
		var dist = dir.length()

		if dist > 0.1:
			look_at(global_position + dir.normalized(), Vector3.UP)

		var vel_actual := rapidez * (1.22 if _en_enrage else 1.0)
		if dist <= radio_pisada and _reloj_ataque <= 0.001:
			_iniciar_pisada_telegrafiada()
		else:
			var dir_mov = ArenaColiseo.calcular_direccion_persecucion(self, jugador.global_position, _nav_estado, delta)
			velocity.x = dir_mov.x * vel_actual + _knockback_velocity.x
			velocity.z = dir_mov.z * vel_actual + _knockback_velocity.z
			if dir_mov.length_squared() > 0.01:
				look_at(global_position + dir_mov, Vector3.UP)
			_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), _en_enrage, is_on_floor(), vel_actual)
	else:
		velocity.x = _knockback_velocity.x
		velocity.z = _knockback_velocity.z
		_anim_ctrl.actualizar_locomocion(0.0, false, is_on_floor(), rapidez)

	if is_on_floor():
		velocity.y = minf(velocity.y, 0.0)
	move_and_slide()

func _iniciar_pisada_telegrafiada():
	_esta_telegrafando = true

	if _decal_pisada != null and is_instance_valid(_decal_pisada):
		_decal_pisada.configurar_circulo(radio_pisada + 1.0, Color(0.95, 0.30, 0.06, 1.0), Color(1.0, 0.62, 0.12, 1.0), Color(1.0, 0.88, 0.36, 1.0))
		_decal_pisada.iniciar_cuenta_regresiva(tiempo_telegraph, false)

	get_tree().create_timer(tiempo_telegraph).timeout.connect(_ejecutar_pisada_telegrafiada)

func _ejecutar_pisada_telegrafiada():
	if muerto or not _esta_telegrafando:
		_esta_telegrafando = false
		if _decal_pisada != null and is_instance_valid(_decal_pisada):
			_decal_pisada.cancelar()
		return
	var en_area := false
	if is_instance_valid(jugador) and jugador is Node3D:
		if _decal_pisada != null and is_instance_valid(_decal_pisada):
			en_area = _decal_pisada.punto_en_area(jugador.global_position)
		else:
			en_area = global_position.distance_to(jugador.global_position) <= (radio_pisada + 1.0)
	if _decal_pisada != null and is_instance_valid(_decal_pisada):
		_decal_pisada.cancelar()
	_esta_telegrafando = false
	_reloj_ataque = 1.6
	_anim_ctrl.reproducir_accion("attack-melee-right", 2, 0.08, 0.85)

	AudioManager.play("danio_jugador", 0.6, 2.5)
	_sacudir_camara(0.4)

	if en_area and is_instance_valid(jugador) and jugador is Node3D:
		if jugador.has_method("recibir_dano"):
			jugador.recibir_dano(dano_pisada)
		elif jugador.has_node("Salud"):
			jugador.get_node("Salud").recibir_golpe(int(dano_pisada))
		_sacudir_camara(0.5)

func _on_boton_click(_total_clicks: int):
	if vida <= 0.0 or muerto:
		return

	var pos_origen = global_position
	if is_instance_valid(_boton_movil):
		pos_origen = _boton_movil.global_position
	_crear_rayo_hacia_jefe(pos_origen)

	# Prioridad absoluta: Canalización de Stagger en Enrage (<25% HP)
	if _fase_ctrl != null and _fase_ctrl.registrar_clic_nucleo(hud):
		_sacudir_camara(0.24)
		return

	if _esta_telegrafando:
		_esta_telegrafando = false
		if _decal_pisada != null and is_instance_valid(_decal_pisada):
			_decal_pisada.cancelar()
		AudioManager.play("puzzle_completo", 1.2)
		_sacudir_camara(0.3)
		_crear_texto_flotante("💥 ¡PISADA SÍSMICA INTERRUMPIDA!", true)
		aplicar_knockback(-global_transform.basis.z * 12.0)
		return

	if _coraza_activa:
		_clics_coraza += 1
		AudioManager.play("altar_activado", 1.1 + (_clics_coraza * 0.2))
		_sacudir_camara(0.2)
		_crear_texto_flotante("⚡ CORAZA %d/%d" % [_clics_coraza, _clics_necesarios_coraza], true)

		if _clics_coraza >= _clics_necesarios_coraza:
			_romper_coraza()
		else:
			_actualizar_hud()
	else:
		var bonus_runico = 110.0
		AudioManager.play("orbe_explosion", 1.1)
		_sacudir_camara(0.18)
		_crear_texto_flotante("⚡ DESCARGA NÚCLEO 110", true)
		recibir_dano(bonus_runico, true)

func _formatear_mult_vulnerable() -> String:
	if is_equal_approx(mult_dano_vulnerable, roundf(mult_dano_vulnerable)):
		return "x%d" % int(roundf(mult_dano_vulnerable))
	return "x%.1f" % mult_dano_vulnerable

func _romper_coraza():
	_coraza_activa = false
	_aturdido = true
	_reloj_vulnerabilidad = maxf(duracion_vulnerabilidad, 0.5)
	_ultimo_seg_vuln_hud = int(ceil(_reloj_vulnerabilidad))
	if _escudo_bronce_mesh != null:
		_escudo_bronce_mesh.visible = false

	if luz_coloso != null:
		luz_coloso.light_color = Color(1.0, 0.90, 0.32)
		luz_coloso.light_energy = _luz_energia_base * 2.1

	if get_parent() != null and is_inside_tree():
		BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 1.4, 8.5, Color(1.0, 0.84, 0.22, 1.0), 0.50)

	AudioManager.play("puzzle_completo", 1.0)
	_sacudir_camara(0.45)
	_crear_texto_flotante("💥 ¡CORAZA DESTRUIDA! VULNERABLE %s (%ds)" % [_formatear_mult_vulnerable(), _ultimo_seg_vuln_hud], true)

	velocity = Vector3.ZERO
	_reloj_ataque = _reloj_vulnerabilidad
	_actualizar_hud()

func _terminar_vulnerabilidad() -> void:
	_reloj_vulnerabilidad = 0.0
	_ultimo_seg_vuln_hud = -1
	_aturdido = false
	if luz_coloso != null:
		luz_coloso.light_color = _luz_color_base
		luz_coloso.light_energy = _luz_energia_base
	_actualizar_hud()

func desactivar_escudo_runico(_duracion: float = 7.0):
	if _coraza_activa:
		_romper_coraza()

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false):
	if muerto:
		return
	var fuente_str := "normal"
	if typeof(fuente) == TYPE_BOOL:
		es_critico = fuente
	else:
		fuente_str = str(fuente)
	if _coraza_activa:
		AudioManager.play("escudo_bloqueo", 0.9)
		_crear_texto_flotante("🛡️ ¡CORAZA! (%d Clics al Núcleo)" % (_clics_necesarios_coraza - _clics_coraza), false)
		return

	if _i_frame_timer > 0.0 and str(fuente) != "ejecucion":
		return
	_i_frame_timer = 0.14

	var es_conmocionado := _fase_ctrl != null and _fase_ctrl.esta_conmocionado()
	var es_vulnerable := _aturdido or _reloj_vulnerabilidad > 0.0 or es_conmocionado
	var mult_vuln := maxf(mult_dano_vulnerable if es_vulnerable else 1.0, _fase_ctrl.obtener_mult_dano() if _fase_ctrl != null else 1.0)
	var dano_final = cantidad * mult_vuln * (1.0 + MetaprogresoManager.obtener_bono_bestiario("coloso"))

	# TOPE DE DAÑO POR GOLPE: Ningún impacto supera el 5% de la vida máxima
	var max_dano_por_golpe = vida_maxima * 0.05
	dano_final = minf(dano_final, max_dano_por_golpe)

	vida = maxf(vida - dano_final, 0.0)
	_anim_ctrl.disparar_golpe()

	if _fase_ctrl != null and vida > 0.0:
		_fase_ctrl.evaluar_vida(vida, vida_maxima, not muerto, hud)

	if not _fase1_usada and vida <= (vida_maxima * 0.70):
		_fase1_usada = true
		_i_frame_timer = 0.6
		_activar_coraza(3, "BRONCE")
	elif not _fase2_usada and vida <= (vida_maxima * 0.35):
		_fase2_usada = true
		_i_frame_timer = 0.6
		_activar_coraza(4, "MAGMA")

	var pool = get_tree().get_first_node_in_group("damage_numbers")
	var pos_num = global_position + Vector3(randf_range(-0.5, 0.5), 3.4, randf_range(-0.5, 0.5))
	if pool != null and pool.has_method("mostrar_dano"):
		pool.mostrar_dano(pos_num, int(round(dano_final)), es_critico or es_vulnerable, fuente_str)
	else:
		var escena_num = load("res://damage_number_3d.tscn")
		if escena_num != null and is_inside_tree() and get_parent() != null:
			var n = escena_num.instantiate()
			get_parent().add_child(n)
			n.global_position = pos_num
			n.iniciar(dano_final, es_critico or es_vulnerable, false)

	_actualizar_hud()
	if vida <= 0.0:
		morir()

func _activar_coraza(clics_req: int, tipo_str: String):
	_reloj_vulnerabilidad = 0.0
	_ultimo_seg_vuln_hud = -1
	_aturdido = false
	if luz_coloso != null:
		luz_coloso.light_color = _luz_color_base
		luz_coloso.light_energy = _luz_energia_base
	_coraza_activa = true
	_clics_necesarios_coraza = clics_req
	_clics_coraza = 0

	if _escudo_bronce_mesh != null:
		_escudo_bronce_mesh.visible = true
		var col_base := Color(1.0, 0.35, 0.1) if tipo_str == "MAGMA" else Color(1.0, 0.75, 0.2)
		if _escudo_burbuja != null and _escudo_burbuja.material_override is StandardMaterial3D:
			var mb := _escudo_burbuja.material_override as StandardMaterial3D
			mb.albedo_color = Color(col_base.r, col_base.g, col_base.b, 0.08)
			mb.emission = col_base
		if _escudo_anillo1 != null and _escudo_anillo1.material_override is StandardMaterial3D:
			var m1 := _escudo_anillo1.material_override as StandardMaterial3D
			m1.albedo_color = Color(col_base.r, col_base.g, col_base.b, 0.85)
			m1.emission = col_base
		if _escudo_anillo2 != null and _escudo_anillo2.material_override is StandardMaterial3D:
			var m2 := _escudo_anillo2.material_override as StandardMaterial3D
			m2.albedo_color = Color(col_base.r, col_base.g, col_base.b, 0.85)
			m2.emission = col_base
		if _escudo_anillo_suelo != null and _escudo_anillo_suelo.material_override is StandardMaterial3D:
			var ms := _escudo_anillo_suelo.material_override as StandardMaterial3D
			ms.albedo_color = Color(col_base.r, col_base.g, col_base.b, 0.70)
			ms.emission = col_base

	AudioManager.play("jefe_alerta", 1.1)
	_crear_texto_flotante("🛡️ ¡CORAZA DE %s ACTIVA!" % tipo_str, true)
	_actualizar_hud()

func morir():
	if muerto:
		return
	muerto = true
	if _decal_pisada != null and is_instance_valid(_decal_pisada):
		_decal_pisada.cancelar()
	_limpiar_zonas_magma_f2(false)
	if _fase_ctrl != null and is_instance_valid(_fase_ctrl):
		_fase_ctrl.limpiar(hud, false)
	if hud != null and hud.has_method("ocultar_barra_jefe"):
		hud.ocultar_barra_jefe()

	AudioManager.play("enemigo_muerte", 0.5, 3.5)
	_sacudir_camara(0.55)

	var pj = get_tree().get_first_node_in_group("jugador") if is_inside_tree() else null
	MetaprogresoManager.procesar_baja_completa(self, pj, "coloso", true)
	if pj != null:
		if pj.has_method("recoger_drop"):
			pj.recoger_drop(0, 120)
			pj.recoger_drop(1, 150)

	emit_signal("jefe_derrotado")
	queue_free()

func _actualizar_hud():
	if hud == null:
		return
	var titulo := "🌋 COLOSO DE BRONCE"
	var estado_tag := "NORMAL"
	if _fase_ctrl != null and _fase_ctrl.esta_canalizando():
		titulo = "🌋 COLOSO DE BRONCE [⚡ CATACLISMO — ¡PULSA EL NÚCLEO!]"
		estado_tag = "CANALIZANDO"
	elif _fase_ctrl != null and _fase_ctrl.esta_conmocionado():
		var segs_c := maxi(1, int(ceil(maxf(_reloj_vulnerabilidad, _fase_ctrl.tiempo_conmocion_restante()))))
		titulo = "🌋 COLOSO DE BRONCE [💥 CONMOCIONADO %s · %ds - ¡ATACA!]" % [_formatear_mult_vulnerable(), segs_c]
		estado_tag = "VULNERABLE"
	elif _coraza_activa:
		titulo = "🌋 COLOSO DE BRONCE [🛡️ CORAZA: %d/%d CLICS AL NÚCLEO]" % [_clics_coraza, _clics_necesarios_coraza]
		estado_tag = "ESCUDO"
	elif _aturdido or _reloj_vulnerabilidad > 0.0:
		var segs := maxi(1, int(ceil(_reloj_vulnerabilidad)))
		titulo = "🌋 COLOSO DE BRONCE [💥 VULNERABLE %s · %ds - ¡ATACA!]" % [_formatear_mult_vulnerable(), segs]
		estado_tag = "VULNERABLE"
	elif _en_enrage:
		titulo = "🌋 COLOSO DE BRONCE [🔥 ENRAGE — FRAGUA DESATADA]"
		estado_tag = "ENRAGE"
	elif _fase_ctrl != null and _fase_ctrl.fase_actual == JefeFaseController.FaseJefe.FASE_2:
		titulo = "🌋 COLOSO DE BRONCE [🔥 FASE II — SUELO INCANDESCENTE]"
		estado_tag = "NORMAL"

	if hud.has_method("actualizar_barra_jefe"):
		hud.actualizar_barra_jefe(vida, titulo, estado_tag)

func _on_fase_cambiada(nueva_fase: int) -> void:
	if muerto:
		return
	if nueva_fase == int(JefeFaseController.FaseJefe.FASE_2):
		AudioManager.play("jefe_alerta", 0.95, 3.0)
		_sacudir_camara(0.50)
		_crear_texto_flotante("⚡ FASE II — ¡SUELO INCANDESCENTE!", true)
		_luz_color_base = Color(1.0, 0.34, 0.08, 1.0)
		_luz_energia_base = 2.8
		if luz_coloso != null and _reloj_vulnerabilidad <= 0.0:
			luz_coloso.light_color = _luz_color_base
			luz_coloso.light_energy = _luz_energia_base
		if get_parent() != null and is_inside_tree():
			BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 1.6, 12.0, Color(1.0, 0.40, 0.08, 1.0), 0.55)
		_reloj_magma_f2 = 4.8
		_invocar_zonas_magma_f2(2)
		_actualizar_hud()
	elif nueva_fase == int(JefeFaseController.FaseJefe.ENRAGE):
		_en_enrage = true
		AudioManager.play("rugido_jefe", 0.9, 3.5)
		_sacudir_camara(0.60)
		_crear_texto_flotante("🔥 ¡ENRAGE — FRAGUA DESATADA!", true)
		_luz_color_base = Color(1.0, 0.14, 0.08, 1.0)
		_luz_energia_base = 3.8
		if luz_coloso != null and _reloj_vulnerabilidad <= 0.0:
			luz_coloso.light_color = _luz_color_base
			luz_coloso.light_energy = _luz_energia_base
		if get_parent() != null and is_inside_tree():
			BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 1.6, 14.0, Color(1.0, 0.16, 0.12, 1.0), 0.55)
		_actualizar_hud()

func _on_stagger_iniciado(clics_req: int, _duracion: float) -> void:
	_esta_telegrafando = false
	if _decal_pisada != null and is_instance_valid(_decal_pisada):
		_decal_pisada.cancelar()
	_crear_texto_flotante("⚡ ¡CATACLISMO! %d CLICS AL NÚCLEO" % clics_req, true)
	_actualizar_hud()

func _on_stagger_progreso(clics_restantes: int, clics_totales: int, _tiempo: float) -> void:
	var completados := clics_totales - clics_restantes
	_crear_texto_flotante("⚡ CONMOCIÓN %d/%d" % [completados, clics_totales], true)

func _on_stagger_completado(duracion_conm: float, _mult_dano: float, pct_ruptura: float) -> void:
	if muerto:
		return
	if _coraza_activa:
		_coraza_activa = false
		if _escudo_bronce_mesh != null:
			_escudo_bronce_mesh.visible = false
	_aturdido = true
	_esta_telegrafando = false
	_reloj_vulnerabilidad = maxf(_reloj_vulnerabilidad, duracion_conm)
	_ultimo_seg_vuln_hud = maxi(1, int(ceil(_reloj_vulnerabilidad)))
	_reloj_ataque = maxf(_reloj_ataque, duracion_conm)
	_sacudir_camara(0.55)

	var dano_ruptura := vida_maxima * pct_ruptura
	vida = maxf(vida - dano_ruptura, 0.0)
	_crear_texto_flotante("💥 ¡CONMOCIONADO! -%d HP (DAÑO %s)" % [int(round(dano_ruptura)), _formatear_mult_vulnerable()], true)
	if is_inside_tree():
		var pool = get_tree().get_first_node_in_group("damage_numbers")
		if pool != null and pool.has_method("mostrar_dano"):
			pool.mostrar_dano(global_position + Vector3(0.0, 3.6, 0.0), int(round(dano_ruptura)), true, "stagger_ruptura")
	_actualizar_hud()
	if vida <= 0.0:
		morir()

func _on_conmocion_terminada() -> void:
	if muerto:
		return
	if _reloj_vulnerabilidad <= 0.0:
		_terminar_vulnerabilidad()
	else:
		_actualizar_hud()

func _on_stagger_fallado() -> void:
	if muerto:
		return
	_sacudir_camara(0.70)
	_crear_texto_flotante("🌋 ¡CATACLISMO DE FRAGUA DESATADO!", true)
	_anim_ctrl.reproducir_accion("attack-melee-right", 2, 0.08, 0.95)
	if is_instance_valid(jugador) and jugador is Node3D:
		var dist := global_position.distance_to(jugador.global_position)
		var radio_m := _fase_ctrl.radio_ataque_mortal if _fase_ctrl != null else 14.0
		if dist <= radio_m:
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(150.0)
			elif jugador.has_node("Salud"):
				jugador.get_node("Salud").recibir_golpe(150)
	_invocar_zonas_magma_f2(2)
	_actualizar_hud()

func _invocar_zonas_magma_f2(cantidad: int = 1) -> void:
	if muerto or get_parent() == null or not is_inside_tree():
		return
	while _zonas_magma_f2.size() >= 4:
		var vieja = _zonas_magma_f2.pop_front()
		if is_instance_valid(vieja):
			vieja.queue_free()

	var padre := get_parent()
	for i in range(cantidad):
		var centro := global_position + Vector3(randf_range(-8.0, 8.0), 0.0, randf_range(-8.0, 8.0))
		if i == 0 and is_instance_valid(jugador) and jugador is Node3D:
			centro = jugador.global_position
		centro.y = 0.0

		var zona := Node3D.new()
		zona.name = "ZonaMagmaF2_%d" % _zonas_magma_f2.size()
		zona.set_meta("tiempo_telegraph", 1.1)
		zona.set_meta("duracion_telegraph", 1.1)
		zona.set_meta("tiempo_activo", 4.5)
		zona.set_meta("activo", false)
		zona.set_meta("radio", 3.4)

		var anillo := BunkerVisualKit.create_hazard_ground_ring(3.4, Color(1.0, 0.56, 0.10, 1.0), Color(1.0, 0.16, 0.04, 1.0), 0.68, 0.96, 0.50, 0.18)
		anillo.name = "AnilloMagma"
		anillo.position = Vector3(0.0, 0.05, 0.0)
		zona.add_child(anillo)

		var disco := MeshInstance3D.new()
		disco.name = "DiscoLava"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 3.25
		cyl.bottom_radius = 3.35
		cyl.height = 0.06
		cyl.radial_segments = 24
		disco.mesh = cyl
		disco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat_lava := StandardMaterial3D.new()
		mat_lava.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat_lava.albedo_color = Color(1.0, 0.24, 0.04, 0.72)
		mat_lava.emission_enabled = true
		mat_lava.emission = Color(1.0, 0.34, 0.04)
		mat_lava.emission_energy_multiplier = 1.65
		mat_lava.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		disco.material_override = mat_lava
		disco.position = Vector3(0.0, 0.03, 0.0)
		disco.visible = false
		zona.add_child(disco)

		padre.add_child(zona)
		zona.global_position = centro
		_zonas_magma_f2.append(zona)

func _actualizar_zonas_magma_f2(delta: float) -> void:
	if _zonas_magma_f2.is_empty():
		return
	_reloj_tick_magma_f2 = maxf(_reloj_tick_magma_f2 - delta, 0.0)
	var activas: Array = []
	for z in _zonas_magma_f2:
		if not is_instance_valid(z):
			continue
		var t_tel := float(z.get_meta("tiempo_telegraph", 0.0))
		if t_tel > 0.0:
			t_tel = maxf(t_tel - delta, 0.0)
			z.set_meta("tiempo_telegraph", t_tel)
			var dur_tel := maxf(float(z.get_meta("duracion_telegraph", 1.1)), 0.1)
			var prog := 1.0 - clampf(t_tel / dur_tel, 0.0, 1.0)
			var anillo := z.get_node_or_null("AnilloMagma") as MeshInstance3D
			if anillo != null and anillo.material_override is ShaderMaterial:
				(anillo.material_override as ShaderMaterial).set_shader_parameter("progress", prog)
			if t_tel <= 0.0:
				z.set_meta("activo", true)
				var disco := z.get_node_or_null("DiscoLava") as Node3D
				if disco != null:
					disco.visible = true
				if anillo != null and anillo.material_override is ShaderMaterial:
					(anillo.material_override as ShaderMaterial).set_shader_parameter("active_state", 1.0)
		else:
			var t_act := float(z.get_meta("tiempo_activo", 0.0)) - delta
			z.set_meta("tiempo_activo", t_act)
			if t_act <= 0.0:
				z.queue_free()
				continue
			if _reloj_tick_magma_f2 <= 0.0 and is_instance_valid(jugador) and jugador is Node3D:
				var dist_z := Vector2(jugador.global_position.x - z.global_position.x, jugador.global_position.z - z.global_position.z).length()
				if dist_z <= float(z.get_meta("radio", 3.4)):
					_reloj_tick_magma_f2 = 0.75
					if jugador.has_method("recibir_dano"):
						jugador.recibir_dano(24.0)
					elif jugador.has_node("Salud"):
						jugador.get_node("Salud").recibir_golpe(24)
		activas.append(z)
	_zonas_magma_f2 = activas

func _limpiar_zonas_magma_f2(diferir_remocion: bool = false) -> void:
	for z in _zonas_magma_f2:
		if is_instance_valid(z):
			z.visible = false
			if not diferir_remocion and z.get_parent() != null:
				z.get_parent().remove_child(z)
			z.queue_free()
	_zonas_magma_f2.clear()

func _crear_rayo_hacia_jefe(desde_pos: Vector3):
	var orbe = MeshInstance3D.new()
	var esfera = SphereMesh.new()
	esfera.radius = 0.35
	esfera.height = 0.7
	orbe.mesh = esfera
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.5, 0.1)
	orbe.material_override = mat
	if get_parent() != null:
		get_parent().add_child(orbe)
		orbe.global_position = desde_pos + Vector3(0, 1.0, 0)
		var dest = global_position + Vector3(0, 2.7, 0)
		var tw = create_tween()
		tw.tween_property(orbe, "global_position", dest, 0.16)
		tw.tween_callback(func():
			if is_instance_valid(orbe):
				orbe.queue_free()
		)

func _crear_texto_flotante(texto: String, es_crit: bool = false):
	if get_tree() == null:
		return
	var pool = get_tree().get_first_node_in_group("damage_numbers")
	if pool != null and pool.has_method("mostrar_texto"):
		pool.mostrar_texto(global_position + Vector3(0, 3.8, 0), texto, Color(1.0, 0.7, 0.2), 1.2)
		return
	var escena_num = load("res://damage_number_3d.tscn")
	if escena_num != null and is_inside_tree() and get_parent() != null:
		var n = escena_num.instantiate()
		get_parent().add_child(n)
		n.global_position = global_position + Vector3(0, 3.8, 0)
		n.iniciar(0.0, es_crit, false, texto)

func _sacudir_camara(intensidad: float = 0.35):
	var cam = get_viewport().get_camera_3d()
	if cam != null and cam.has_method("sacudir"):
		cam.sacudir(intensidad)
	else:
		var c = get_tree().get_first_node_in_group("camara")
		if c != null and c.has_method("sacudir"):
			c.sacudir(intensidad)
