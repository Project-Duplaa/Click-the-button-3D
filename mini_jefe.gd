extends CharacterBody3D

# Mini-Jefe: Gladiador de Élite de la Arena (Minuto 6:45)
# 2200 HP, cargas telegrafiadas, Muralla de Hierro (3 clics) y Knockback físico real.

signal jefe_derrotado

const AudioManager = preload("res://audio_manager.gd")
const ArenaColiseo = preload("res://arena_coliseo.gd")
const VfxCombate = preload("res://vfx_combate.gd")

@export var rapidez: float = 3.95
@export var vida_maxima: float = 4800.0
@export var dano_golpe: float = 65.0
@export var rango_ataque: float = 3.4
@export var tiempo_telegraph: float = 0.55

var vida: float = 4800.0
var muerto: bool = false
var jugador: Node3D = null
var hud: Node = null
var _boton_movil: Node = null

var tiene_escudo_runico: bool = true
var _reloj_escudo_roto: float = 0.0

var _reloj_ataque: float = 0.0
var _esta_telegrafando: bool = false
var _posicion_ataque_telegraph: Vector3 = Vector3.ZERO
var _knockback_velocity: Vector3 = Vector3.ZERO
var _i_frame_timer: float = 0.0

# Mecánica de Muralla de Hierro
var _muralla_activa: bool = false
var _clics_muralla: int = 0
var _clics_necesarios_muralla: int = 4
var _fase1_muralla_usada: bool = false
var _fase2_muralla_usada: bool = false
var _aturdido: bool = false

var _escudo_hierro_mesh: Node3D = null
var _escudo_burbuja: MeshInstance3D = null
var _escudo_anillo1: MeshInstance3D = null
var _escudo_anillo2: MeshInstance3D = null
var _escudo_anillo_suelo: MeshInstance3D = null

var _escala_base: Vector3 = Vector3.ONE
var _anim_ctrl: AnimadorEntidad = AnimadorEntidad.new()
var _nav_estado: Dictionary = {}

@onready var telegraph_mesh: MeshInstance3D = $TelegraphSuelo
@onready var modelo: Node3D = $Modelo if has_node("Modelo") else null

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

	_crear_escudo_hierro_visual()
	call_deferred("_conectar_boton_movil")
	AudioManager.play("jefe_alerta", 1.15)

	if hud != null and hud.has_method("mostrar_barra_jefe"):
		hud.mostrar_barra_jefe("⚔️ GLADIADOR DE ÉLITE", vida_maxima, vida)

func aplicar_knockback(impulso: Vector3, _duracion_stun: float = 0.08):
	var kb = impulso * 0.45
	kb.y = 0.0
	_knockback_velocity += kb
	if _knockback_velocity.length() > 12.0:
		_knockback_velocity = _knockback_velocity.normalized() * 12.0

func _crear_escudo_hierro_visual():
	_escudo_hierro_mesh = Node3D.new()
	_escudo_hierro_mesh.name = "EscudoHierroVisual"

	# 1. Burbuja cristalina de alta transparencia (deja ver 100% el modelo)
	_escudo_burbuja = MeshInstance3D.new()
	var esfera = SphereMesh.new()
	esfera.radius = 2.1
	esfera.height = 4.0
	_escudo_burbuja.mesh = esfera
	_escudo_burbuja.position = Vector3(0, 1.9, 0)

	var mat_burbuja = StandardMaterial3D.new()
	mat_burbuja.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_burbuja.albedo_color = Color(1.0, 0.75, 0.2, 0.08)
	mat_burbuja.roughness = 0.08
	mat_burbuja.metallic = 0.45
	mat_burbuja.rim_enabled = true
	mat_burbuja.rim = 0.42
	mat_burbuja.rim_tint = 0.25
	mat_burbuja.emission_enabled = true
	mat_burbuja.emission = Color(1.0, 0.65, 0.15)
	mat_burbuja.emission_energy_multiplier = 0.14
	mat_burbuja.cull_mode = BaseMaterial3D.CULL_BACK
	_escudo_burbuja.material_override = mat_burbuja
	_escudo_hierro_mesh.add_child(_escudo_burbuja)

	# 2. Anillo orbital horizontal de energía rúnica
	_escudo_anillo1 = MeshInstance3D.new()
	var t1 = TorusMesh.new()
	t1.outer_radius = 2.15
	t1.inner_radius = 2.03
	t1.rings = 36
	t1.ring_segments = 8
	_escudo_anillo1.mesh = t1
	_escudo_anillo1.position = Vector3(0, 1.9, 0)
	var mat_anillo1 = StandardMaterial3D.new()
	mat_anillo1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_anillo1.albedo_color = Color(1.0, 0.78, 0.25, 0.62)
	mat_anillo1.emission_enabled = true
	mat_anillo1.emission = Color(1.0, 0.70, 0.15)
	mat_anillo1.emission_energy_multiplier = 0.55
	_escudo_anillo1.material_override = mat_anillo1
	_escudo_hierro_mesh.add_child(_escudo_anillo1)

	# 3. Segundo anillo orbital inclinado
	_escudo_anillo2 = MeshInstance3D.new()
	var t2 = TorusMesh.new()
	t2.outer_radius = 2.05
	t2.inner_radius = 1.94
	t2.rings = 36
	t2.ring_segments = 8
	_escudo_anillo2.mesh = t2
	_escudo_anillo2.position = Vector3(0, 1.6, 0)
	_escudo_anillo2.rotation_degrees = Vector3(25.0, 0.0, 18.0)
	var mat_anillo2 = mat_anillo1.duplicate() as StandardMaterial3D
	_escudo_anillo2.material_override = mat_anillo2
	_escudo_hierro_mesh.add_child(_escudo_anillo2)

	# 4. Anillo rúnico a ras de suelo
	_escudo_anillo_suelo = MeshInstance3D.new()
	var t_suelo = TorusMesh.new()
	t_suelo.outer_radius = 2.4
	t_suelo.inner_radius = 2.28
	t_suelo.rings = 40
	t_suelo.ring_segments = 8
	_escudo_anillo_suelo.mesh = t_suelo
	_escudo_anillo_suelo.position = Vector3(0, 0.08, 0)
	var mat_suelo = mat_anillo1.duplicate() as StandardMaterial3D
	mat_suelo.albedo_color = Color(1.0, 0.75, 0.2, 0.52)
	_escudo_anillo_suelo.material_override = mat_suelo
	_escudo_hierro_mesh.add_child(_escudo_anillo_suelo)

	_escudo_hierro_mesh.visible = false
	add_child(_escudo_hierro_mesh)

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
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 16.0 * delta)
	if _escudo_hierro_mesh != null and _escudo_hierro_mesh.visible:
		if _escudo_anillo1 != null:
			_escudo_anillo1.rotate_y(delta * 2.0)
		if _escudo_anillo2 != null:
			_escudo_anillo2.rotate_y(-delta * 2.3)
		if _escudo_anillo_suelo != null:
			_escudo_anillo_suelo.rotate_y(delta * 1.0)

	if _aturdido or _esta_telegrafando:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta) + _knockback_velocity.x
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta) + _knockback_velocity.z
		_anim_ctrl.reproducir_bucle("stunned" if _aturdido else "telegraph", 0.12, 1.0, 1)
		move_and_slide()
		return

	_reloj_ataque = maxf(_reloj_ataque - delta, 0.0)

	if is_instance_valid(jugador) and jugador is Node3D:
		var dir = (jugador.global_position - global_position)
		dir.y = 0.0
		var dist = dir.length()

		if dist > 0.1:
			look_at(global_position + dir.normalized(), Vector3.UP)

		var diff_y = absf(jugador.global_position.y - global_position.y)

		if dist <= rango_ataque and diff_y <= 0.48 and _reloj_ataque <= 0.001:
			_iniciar_ataque_telegrafiado()
		else:
			var dir_mov = ArenaColiseo.calcular_direccion_persecucion(self, jugador.global_position, _nav_estado, delta)
			var mult_colapso = 1.0
			var b_movil = get_tree().get_first_node_in_group("boton_movil")
			if b_movil != null and "en_colapso" in b_movil and b_movil.en_colapso:
				mult_colapso = 1.25
			velocity.x = dir_mov.x * rapidez * mult_colapso + _knockback_velocity.x
			velocity.z = dir_mov.z * rapidez * mult_colapso + _knockback_velocity.z
			if dir_mov.length_squared() > 0.01:
				look_at(global_position + dir_mov, Vector3.UP)
			_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), false, is_on_floor(), rapidez)
	else:
		velocity.x = _knockback_velocity.x
		velocity.z = _knockback_velocity.z
		_anim_ctrl.actualizar_locomocion(0.0, false, is_on_floor(), rapidez)

	if is_on_floor():
		velocity.y = minf(velocity.y, 0.0)
	move_and_slide()

func _iniciar_ataque_telegrafiado():
	_esta_telegrafando = true
	_posicion_ataque_telegraph = global_position

	if telegraph_mesh != null:
		telegraph_mesh.visible = true
		telegraph_mesh.scale = Vector3(0.2, 1.0, 0.2)
		var tw = create_tween()
		tw.tween_property(telegraph_mesh, "scale", Vector3(1.0, 1.0, 1.0), tiempo_telegraph).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	get_tree().create_timer(tiempo_telegraph).timeout.connect(_ejecutar_golpe_telegrafiado)

func _ejecutar_golpe_telegrafiado():
	if telegraph_mesh != null:
		telegraph_mesh.visible = false
	if muerto or not _esta_telegrafando:
		_esta_telegrafando = false
		return
	_esta_telegrafando = false
	_reloj_ataque = 1.4
	_anim_ctrl.reproducir_accion("attack-melee-right", 2, 0.08, 1.0)

	AudioManager.play("danio_jugador", 0.8)
	VfxCombate.spawn_tajo(get_parent(), global_position + Vector3(0, 1.15, 0), -global_transform.basis.z, rango_ataque + 0.6, Color(1.0, 0.62, 0.12), Color(1.0, 0.96, 0.72), Color(0.95, 0.25, 0.05), false, 0.22, 12.0)
	BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 0.4, rango_ataque + 0.6, Color(1.0, 0.62, 0.12), 0.26)

	if is_instance_valid(jugador) and jugador is Node3D:
		var dist = global_position.distance_to(jugador.global_position)
		if dist <= rango_ataque + 1.2:
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(dano_golpe)
			elif jugador.has_node("Salud"):
				jugador.get_node("Salud").recibir_golpe(int(dano_golpe))
			VfxCombate.spawn_impacto(get_parent(), jugador.global_position + Vector3(0, 0.95, 0), Color(1.0, 0.65, 0.12), Color.WHITE, 1.15, true)
			_sacudir_camara(0.35)

func _on_boton_click(_total_clicks: int):
	if vida <= 0.0:
		return

	var pos_origen = global_position
	if is_instance_valid(_boton_movil):
		pos_origen = _boton_movil.global_position
	_crear_rayo_hacia_jefe(pos_origen)

	if _muralla_activa:
		_clics_muralla += 1
		AudioManager.play("altar_activado", 1.1 + (_clics_muralla * 0.2))
		_sacudir_camara(0.2)
		_crear_texto_flotante("⚡ RUPTURA %d/%d" % [_clics_muralla, _clics_necesarios_muralla], true)

		if _clics_muralla >= _clics_necesarios_muralla:
			_romper_muralla()
		else:
			_actualizar_hud()
	elif _aturdido:
		var bonus = 80.0
		AudioManager.play("orbe_explosion", 1.2)
		_sacudir_camara(0.18)
		_crear_texto_flotante("⚡ DESCARGA NÚCLEO 80", true)
		recibir_dano(bonus, true)

func _romper_muralla():
	_muralla_activa = false
	_aturdido = true
	if _escudo_hierro_mesh != null:
		_escudo_hierro_mesh.visible = false

	AudioManager.play("puzzle_completo", 1.1)
	VfxCombate.spawn_explosion_nova(get_parent(), global_position + Vector3(0, 1.1, 0), 3.4, Color(1.0, 0.72, 0.20), Color.WHITE, 0.34, true, true)
	_sacudir_camara(0.4)
	_crear_texto_flotante("💥 ¡MURALLA ROTA! (Aturdido 3s)", true)

	velocity = Vector3.ZERO
	_reloj_ataque = 3.0
	_actualizar_hud()

	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(self):
			_aturdido = false
			_actualizar_hud()
	)

func desactivar_escudo_runico(_duracion: float = 7.0):
	if _muralla_activa:
		_romper_muralla()

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false):
	if muerto:
		return
	if _i_frame_timer > 0.0 and str(fuente) != "ejecucion":
		return
	_i_frame_timer = 0.14
	var fuente_str := "normal"
	if typeof(fuente) == TYPE_BOOL:
		es_critico = fuente
	else:
		fuente_str = str(fuente)
	var dano_final = cantidad * (1.0 + MetaprogresoManager.obtener_bono_bestiario("mini_jefe"))
	if _muralla_activa:
		dano_final *= 0.10
		AudioManager.play("escudo_bloqueo", 1.0)
		_crear_texto_flotante("🛡️ ¡MURALLA! (%d Clics al Núcleo)" % (_clics_necesarios_muralla - _clics_muralla), false)
	elif _aturdido:
		dano_final *= 1.5

	# TOPE DE DAÑO POR GOLPE: Ningún impacto supera el 7% de la vida máxima
	var max_dano_por_golpe = vida_maxima * 0.07
	dano_final = minf(dano_final, max_dano_por_golpe)

	vida = maxf(vida - dano_final, 0.0)
	_anim_ctrl.disparar_golpe()

	if not _fase1_muralla_usada and vida <= (vida_maxima * 0.65):
		_i_frame_timer = 0.6
		_activar_muralla(1)
	elif not _fase2_muralla_usada and vida <= (vida_maxima * 0.30):
		_i_frame_timer = 0.6
		_activar_muralla(2)

	var pool = get_tree().get_first_node_in_group("damage_numbers")
	var pos_num = global_position + Vector3(randf_range(-0.4, 0.4), 2.8, randf_range(-0.4, 0.4))
	if pool != null and pool.has_method("mostrar_dano"):
		pool.mostrar_dano(pos_num, int(round(dano_final)), es_critico or _aturdido, fuente_str)
	else:
		var escena_num = load("res://damage_number_3d.tscn")
		if escena_num != null and is_inside_tree() and get_parent() != null:
			var n = escena_num.instantiate()
			get_parent().add_child(n)
			n.global_position = pos_num
			n.iniciar(dano_final, es_critico or _aturdido, false)

	_actualizar_hud()
	if vida <= 0.0:
		morir()

func _activar_muralla(fase: int):
	if fase == 1:
		_fase1_muralla_usada = true
	else:
		_fase2_muralla_usada = true

	_muralla_activa = true
	_clics_muralla = 0
	if _escudo_hierro_mesh != null:
		_escudo_hierro_mesh.visible = true

	AudioManager.play("jefe_alerta", 1.2)
	_crear_texto_flotante("🛡️ ¡POSTURA DEFENSIVA!", true)
	_actualizar_hud()

func morir():
	if muerto:
		return
	muerto = true
	if hud != null and hud.has_method("ocultar_barra_jefe"):
		hud.ocultar_barra_jefe()

	AudioManager.play("enemigo_muerte", 0.7)
	_sacudir_camara(0.4)

	var pj = get_tree().get_first_node_in_group("jugador")
	MetaprogresoManager.procesar_baja_completa(self, pj, "mini_jefe", true)

	if is_inside_tree() and get_parent() != null:
		FortunaManager.soltar_drops(get_parent(), global_position, "mini_jefe")

	emit_signal("jefe_derrotado")
	queue_free()

func _actualizar_hud():
	if hud == null:
		return
	var titulo = "⚔️ GLADIADOR DE ÉLITE"
	if _muralla_activa:
		titulo = "⚔️ GLADIADOR [🛡️ MURALLA: %d/%d CLICS AL NÚCLEO]" % [_clics_muralla, _clics_necesarios_muralla]
	elif _aturdido:
		titulo = "⚔️ GLADIADOR [💥 ¡DESESTABILIZADO!]"

	if hud.has_method("actualizar_barra_jefe"):
		hud.actualizar_barra_jefe(vida, titulo)

func _crear_rayo_hacia_jefe(desde_pos: Vector3):
	if get_parent() != null:
		VfxCombate.spawn_rayo_segmento(get_parent(), desde_pos + Vector3(0, 1.0, 0), global_position + Vector3(0, 1.9, 0), Color(1.0, 0.65, 0.12), Color.WHITE, 0.16, 0.18, 0.30)

func _crear_texto_flotante(texto: String, es_crit: bool = false):
	if get_tree() == null:
		return
	var pool = get_tree().get_first_node_in_group("damage_numbers")
	if pool != null and pool.has_method("mostrar_texto"):
		pool.mostrar_texto(global_position + Vector3(0, 3.2, 0), texto, Color(1.0, 0.85, 0.2), 1.2)
		return
	var escena_num = load("res://damage_number_3d.tscn")
	if escena_num != null and is_inside_tree() and get_parent() != null:
		var n = escena_num.instantiate()
		get_parent().add_child(n)
		n.global_position = global_position + Vector3(0, 3.2, 0)
		n.iniciar(0.0, es_crit, false, texto)

func _sacudir_camara(intensidad: float = 0.3):
	var cam = get_viewport().get_camera_3d()
	if cam != null and cam.has_method("sacudir"):
		cam.sacudir(intensidad)
	else:
		var c = get_tree().get_first_node_in_group("camara")
		if c != null and c.has_method("sacudir"):
			c.sacudir(intensidad)
