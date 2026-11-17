extends CharacterBody3D

# Jefe 4: Coloso de Bronce (Minuto 13:30)
# Titán colosal acorazado. 9500 HP.
# Incluye Coraza de Bronce/Magma rompible con el Núcleo (3 y 4 clics), interrupción de Pisada Sísmica y Knockback físico real.

signal jefe_derrotado

const AudioManager = preload("res://audio_manager.gd")

@export var rapidez: float = 3.2
@export var vida_maxima: float = 22000.0
@export var dano_pisada: float = 115.0
@export var radio_pisada: float = 5.8
@export var tiempo_telegraph: float = 0.70

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
var _knockback_velocity: Vector3 = Vector3.ZERO
var _i_frame_timer: float = 0.0

var _escudo_bronce_mesh: MeshInstance3D = null

var _escala_base: Vector3 = Vector3.ONE
var _anim_ctrl: AnimadorEntidad = AnimadorEntidad.new()

@onready var modelo: Node3D = $Modelo if has_node("Modelo") else null
@onready var telegraph_mesh: MeshInstance3D = $TelegraphPisada
@onready var luz_coloso: OmniLight3D = $LuzColoso

func _ready():
	add_to_group("enemigos")
	add_to_group("enemies")
	add_to_group("jefes")
	add_to_group("bosses")
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

	_crear_coraza_visual()
	call_deferred("_conectar_boton_movil")
	AudioManager.play("jefe_alerta", 0.8, 3.0)

	if hud != null and hud.has_method("mostrar_barra_jefe"):
		hud.mostrar_barra_jefe("🌋 COLOSO DE BRONCE", vida_maxima, vida)

func aplicar_knockback(impulso: Vector3, _duracion_stun: float = 0.08):
	var kb = impulso * 0.35
	kb.y = 0.0
	_knockback_velocity += kb
	if _knockback_velocity.length() > 10.0:
		_knockback_velocity = _knockback_velocity.normalized() * 10.0

func _crear_coraza_visual():
	_escudo_bronce_mesh = MeshInstance3D.new()
	var esfera = SphereMesh.new()
	esfera.radius = 2.8
	esfera.height = 5.4
	_escudo_bronce_mesh.mesh = esfera
	_escudo_bronce_mesh.position = Vector3(0, 2.7, 0)

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.95, 0.6, 0.1, 0.45)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.0)
	mat.emission_energy_multiplier = 2.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_escudo_bronce_mesh.material_override = mat
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
	if _escudo_bronce_mesh != null and _escudo_bronce_mesh.visible:
		_escudo_bronce_mesh.rotate_y(delta * 1.5)

	if _aturdido or _esta_telegrafando:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta) + _knockback_velocity.x
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta) + _knockback_velocity.z
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

		if dist <= radio_pisada and _reloj_ataque <= 0.001:
			_iniciar_pisada_telegrafiada()
		else:
			var dir_mov = dir.normalized()
			velocity.x = dir_mov.x * rapidez + _knockback_velocity.x
			velocity.z = dir_mov.z * rapidez + _knockback_velocity.z
			_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), false, is_on_floor(), rapidez)
	else:
		velocity.x = _knockback_velocity.x
		velocity.z = _knockback_velocity.z
		_anim_ctrl.actualizar_locomocion(0.0, false, is_on_floor(), rapidez)

	move_and_slide()

func _iniciar_pisada_telegrafiada():
	_esta_telegrafando = true

	if telegraph_mesh != null:
		telegraph_mesh.visible = true
		telegraph_mesh.scale = Vector3(0.2, 1.0, 0.2)
		var tw = create_tween()
		tw.tween_property(telegraph_mesh, "scale", Vector3(1.0, 1.0, 1.0), tiempo_telegraph).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	get_tree().create_timer(tiempo_telegraph).timeout.connect(_ejecutar_pisada_telegrafiada)

func _ejecutar_pisada_telegrafiada():
	if telegraph_mesh != null:
		telegraph_mesh.visible = false
	if muerto or not _esta_telegrafando:
		_esta_telegrafando = false
		return
	_esta_telegrafando = false
	_reloj_ataque = 1.6
	_anim_ctrl.reproducir_accion("attack-melee-right", 2, 0.08, 0.85)

	AudioManager.play("danio_jugador", 0.6, 2.5)
	_sacudir_camara(0.4)

	if is_instance_valid(jugador) and jugador is Node3D:
		var dist = global_position.distance_to(jugador.global_position)
		if dist <= radio_pisada + 1.0:
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(dano_pisada)
			elif jugador.has_node("Salud"):
				jugador.get_node("Salud").recibir_golpe(int(dano_pisada))
			_sacudir_camara(0.5)

func _on_boton_click(_total_clicks: int):
	if vida <= 0.0:
		return

	var pos_origen = global_position
	if is_instance_valid(_boton_movil):
		pos_origen = _boton_movil.global_position
	_crear_rayo_hacia_jefe(pos_origen)

	if _esta_telegrafando:
		_esta_telegrafando = false
		if telegraph_mesh != null:
			telegraph_mesh.visible = false
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

func _romper_coraza():
	_coraza_activa = false
	_aturdido = true
	if _escudo_bronce_mesh != null:
		_escudo_bronce_mesh.visible = false

	AudioManager.play("puzzle_completo", 1.0)
	_sacudir_camara(0.45)
	_crear_texto_flotante("💥 ¡CORAZA DESTRUIDA! (Aturdido 3.5s)", true)

	velocity = Vector3.ZERO
	_reloj_ataque = 3.5
	_actualizar_hud()

	get_tree().create_timer(3.5).timeout.connect(func():
		if is_instance_valid(self):
			_aturdido = false
			_actualizar_hud()
	)

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

	var dano_final = cantidad * (1.5 if _aturdido else 1.0) * (1.0 + MetaprogresoManager.obtener_bono_bestiario("coloso"))

	# TOPE DE DAÑO POR GOLPE: Ningún impacto supera el 5% de la vida máxima
	var max_dano_por_golpe = vida_maxima * 0.05
	dano_final = minf(dano_final, max_dano_por_golpe)

	vida = maxf(vida - dano_final, 0.0)
	_anim_ctrl.disparar_golpe()

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

func _activar_coraza(clics_req: int, tipo_str: String):
	_coraza_activa = true
	_clics_necesarios_coraza = clics_req
	_clics_coraza = 0

	if _escudo_bronce_mesh != null:
		_escudo_bronce_mesh.visible = true
		var mat = _escudo_bronce_mesh.material_override as StandardMaterial3D
		if mat != null:
			if tipo_str == "MAGMA":
				mat.albedo_color = Color(1.0, 0.2, 0.05, 0.55)
				mat.emission = Color(1.0, 0.1, 0.0)
			else:
				mat.albedo_color = Color(0.95, 0.6, 0.1, 0.45)
				mat.emission = Color(1.0, 0.5, 0.0)

	AudioManager.play("jefe_alerta", 1.1)
	_crear_texto_flotante("🛡️ ¡CORAZA DE %s ACTIVA!" % tipo_str, true)
	_actualizar_hud()

func morir():
	if muerto:
		return
	muerto = true
	if hud != null and hud.has_method("ocultar_barra_jefe"):
		hud.ocultar_barra_jefe()

	AudioManager.play("enemigo_muerte", 0.5, 3.5)
	_sacudir_camara(0.55)

	var pj = get_tree().get_first_node_in_group("jugador")
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
	var titulo = "🌋 COLOSO DE BRONCE"
	if _coraza_activa:
		titulo = "🌋 COLOSO [🛡️ CORAZA: %d/%d CLICS AL NÚCLEO]" % [_clics_coraza, _clics_necesarios_coraza]
	elif _aturdido:
		titulo = "🌋 COLOSO [💥 ¡CORAZA DESTRUIDA!]"

	if hud.has_method("actualizar_barra_jefe"):
		hud.actualizar_barra_jefe(vida, titulo)

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
