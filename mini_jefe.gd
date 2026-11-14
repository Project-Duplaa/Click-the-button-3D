extends CharacterBody3D

# Mini-Jefe: Gladiador de Élite de la Arena (Oleada 6 / Minuto 6)
# 950 HP, cargas telegrafiadas, Muralla de Hierro con Cristales Clicables y Knockback físico real.

signal jefe_derrotado

const AudioManager = preload("res://audio_manager.gd")

@export var rapidez: float = 3.4
@export var vida_maxima: float = 950.0
@export var dano_golpe: float = 34.0
@export var rango_ataque: float = 3.4
@export var tiempo_telegraph: float = 0.70

var vida: float = 950.0
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

# Mecánica de Muralla de Hierro
var _muralla_activa: bool = false
var _clics_muralla: int = 0
var _clics_necesarios_muralla: int = 2
var _fase1_muralla_usada: bool = false
var _fase2_muralla_usada: bool = false
var _aturdido: bool = false

var _escudo_hierro_mesh: MeshInstance3D = null

var _escala_base: Vector3 = Vector3.ONE
var _anim_ctrl: AnimadorEntidad = AnimadorEntidad.new()

@onready var telegraph_mesh: MeshInstance3D = $TelegraphSuelo
@onready var modelo: Node3D = $Modelo if has_node("Modelo") else null

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

	_crear_escudo_hierro_visual()
	call_deferred("_conectar_boton_movil")
	AudioManager.play("jefe_alerta", 1.15)

	if hud != null and hud.has_method("mostrar_barra_jefe"):
		hud.mostrar_barra_jefe("⚔️ GLADIADOR DE ÉLITE", vida_maxima, vida)

func aplicar_knockback(impulso: Vector3):
	var kb = impulso * 0.45
	kb.y = 0.0
	_knockback_velocity += kb
	if _knockback_velocity.length() > 12.0:
		_knockback_velocity = _knockback_velocity.normalized() * 12.0

func _crear_escudo_hierro_visual():
	_escudo_hierro_mesh = MeshInstance3D.new()
	var esfera = SphereMesh.new()
	esfera.radius = 2.0
	esfera.height = 3.8
	_escudo_hierro_mesh.mesh = esfera
	_escudo_hierro_mesh.position = Vector3(0, 1.9, 0)

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.85, 0.55, 0.15, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.45, 0.05)
	mat.emission_energy_multiplier = 2.4
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_escudo_hierro_mesh.material_override = mat
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

	if _boton_movil == null or not is_instance_valid(_boton_movil):
		_conectar_boton_movil()

	_anim_ctrl.actualizar(delta)
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 16.0 * delta)
	if _escudo_hierro_mesh != null and _escudo_hierro_mesh.visible:
		_escudo_hierro_mesh.rotate_y(delta * 2.0)

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

		if dist <= rango_ataque and _reloj_ataque <= 0.001:
			_iniciar_ataque_telegrafiado()
		else:
			var dir_mov = dir.normalized()
			var mult_colapso = 1.0
			var b_movil = get_tree().get_first_node_in_group("boton_movil")
			if b_movil != null and "en_colapso" in b_movil and b_movil.en_colapso:
				mult_colapso = 1.25
			velocity.x = dir_mov.x * rapidez * mult_colapso + _knockback_velocity.x
			velocity.z = dir_mov.z * rapidez * mult_colapso + _knockback_velocity.z
			_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), false, is_on_floor(), rapidez)
	else:
		velocity.x = _knockback_velocity.x
		velocity.z = _knockback_velocity.z
		_anim_ctrl.actualizar_locomocion(0.0, false, is_on_floor(), rapidez)

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
	_esta_telegrafando = false
	_reloj_ataque = 1.4
	_anim_ctrl.reproducir_accion("attack-melee-right", 2, 0.08, 1.0)

	AudioManager.play("danio_jugador", 0.8)

	if is_instance_valid(jugador) and jugador is Node3D:
		var dist = global_position.distance_to(jugador.global_position)
		if dist <= rango_ataque + 1.2:
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(dano_golpe)
			elif jugador.has_node("Salud"):
				jugador.get_node("Salud").recibir_golpe(int(dano_golpe))
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

func recibir_dano(cantidad: float, es_critico: bool = false):
	if muerto:
		return
	var dano_final = cantidad
	if _muralla_activa:
		dano_final *= 0.15
		AudioManager.play("escudo_bloqueo", 1.0)
		_crear_texto_flotante("🛡️ ¡MURALLA! (2 Clics al Núcleo)", false)
	elif _aturdido:
		dano_final *= 1.5

	vida = maxf(vida - dano_final, 0.0)
	_anim_ctrl.disparar_golpe()

	if not _fase1_muralla_usada and vida <= (vida_maxima * 0.65):
		_activar_muralla(1)
	elif not _fase2_muralla_usada and vida <= (vida_maxima * 0.30):
		_activar_muralla(2)

	var pool = get_tree().get_first_node_in_group("damage_numbers")
	var pos_num = global_position + Vector3(randf_range(-0.4, 0.4), 2.8, randf_range(-0.4, 0.4))
	if pool != null and pool.has_method("mostrar_dano"):
		pool.mostrar_dano(pos_num, dano_final, es_critico or _aturdido, false)
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
	if pj != null and pj.has_method("registrar_baja"):
		pj.registrar_baja()

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
	var orbe = MeshInstance3D.new()
	var esfera = SphereMesh.new()
	esfera.radius = 0.3
	esfera.height = 0.6
	orbe.mesh = esfera
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.6, 0.1)
	orbe.material_override = mat
	if get_parent() != null:
		get_parent().add_child(orbe)
		orbe.global_position = desde_pos + Vector3(0, 1.0, 0)
		var dest = global_position + Vector3(0, 1.9, 0)
		var tw = create_tween()
		tw.tween_property(orbe, "global_position", dest, 0.16)
		tw.tween_callback(func():
			if is_instance_valid(orbe):
				orbe.queue_free()
		)

func _crear_texto_flotante(texto: String, es_crit: bool = false):
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
