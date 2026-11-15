extends CharacterBody3D

# La Parca Roja - Jefe Final Colosal de Clicklike 3D
# 5000 HP, velocidad implacable, guadaña de sombra, marcas rojas telegrafiadas, cargas sombrías y proyectiles en abanico.
# Incluye Cristales de Escudo Clicables en órbita, Knockback físico real y desbloqueo del Portal de Ascensión al morir.

signal parca_derrotada

const AudioManager = preload("res://audio_manager.gd")

@export var rapidez: float = 5.6
@export var vida_maxima: float = 5000.0
@export var dano_guadana: float = 55.0
@export var radio_golpe: float = 4.2
@export var tiempo_telegraph: float = 0.85

@export var clics_base_escudo: int = 3
@export var duracion_vulnerabilidad: float = 9.0

var vida: float = 5000.0
var muerto: bool = false
var jugador: Node3D = null
var hud: Node = null
var _boton_movil: Node = null

var tiene_escudo_runico: bool = true
var _reloj_escudo_roto: float = 0.0

var _reloj_ataque: float = 0.0
var _esta_telegrafando: bool = false
var _en_enrage: bool = false
var _knockback_velocity: Vector3 = Vector3.ZERO

# Estados del Escudo y Golpe de Gracia
var escudo_activo: bool = true
var clics_para_romper_escudo: int = 3
var clics_actuales_escudo: int = 0
var _reloj_vulnerabilidad: float = 0.0
var _en_agonia_final: bool = false

# Mecánica de Carga Sombría (Phantom Dash)
var _reloj_carga: float = 5.0
var _esta_cargando: bool = false
var _dir_carga: Vector3 = Vector3.ZERO
var _telegraph_carga: MeshInstance3D = null

var _escudo_mesh: MeshInstance3D = null
var _luz_escudo: OmniLight3D = null

var _escala_base: Vector3 = Vector3.ONE
var _anim_ctrl: AnimadorEntidad = AnimadorEntidad.new()

@onready var modelo: Node3D = $Modelo if has_node("Modelo") else null
@onready var telegraph_marca: MeshInstance3D = $TelegraphMarca
@onready var luz_roja: OmniLight3D = $LuzParca
@onready var aura_roja: MeshInstance3D = $AuraParca

func _ready():
	add_to_group("enemigos")
	add_to_group("enemies")
	add_to_group("jefes")
	add_to_group("bosses")
	vida = vida_maxima
	if modelo != null:
		_escala_base = modelo.scale
		_anim_ctrl.vincular_modelo(modelo)
	clics_para_romper_escudo = _calcular_clics_necesarios()
	jugador = get_tree().get_first_node_in_group("jugador")
	hud = get_tree().get_first_node_in_group("hud")
	if hud == null:
		hud = get_parent().get_node_or_null("ClickHUD")

	if telegraph_marca != null:
		telegraph_marca.visible = false

	_crear_escudo_visual()
	_crear_telegraph_carga()
	call_deferred("_conectar_boton_movil")

	print("=====================================================")
	print("¡LA PARCA ROJA HA DESCENDIDO AL COLISEO! (5000 HP)")
	print("🛡️ BARRERA ESPECTRAL DINÁMICA: Clics necesarios: ", clics_para_romper_escudo)
	print("=====================================================")
	AudioManager.play("jefe_alerta", 0.65, 3.0)

	if hud != null and hud.has_method("mostrar_barra_jefe"):
		var titulo_inicial = "💀 LA PARCA ROJA [🛡️ ESCUDO: 0/%d CLICS AL NÚCLEO]" % clics_para_romper_escudo
		hud.mostrar_barra_jefe(titulo_inicial, vida_maxima, vida)

func aplicar_knockback(impulso: Vector3, _duracion_stun: float = 0.08):
	var kb = impulso * 0.4
	kb.y = 0.0
	_knockback_velocity += kb
	if _knockback_velocity.length() > 14.0:
		_knockback_velocity = _knockback_velocity.normalized() * 14.0

func _calcular_clics_necesarios() -> int:
	var pct_perdido = 1.0 - (vida / vida_maxima)
	return clics_base_escudo + int(pct_perdido * 3.99)

func _crear_escudo_visual():
	_escudo_mesh = MeshInstance3D.new()
	var esfera = SphereMesh.new()
	esfera.radius = 2.4
	esfera.height = 4.8
	_escudo_mesh.mesh = esfera
	_escudo_mesh.position = Vector3(0, 2.4, 0)

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.2, 0.65, 1.0, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.75, 1.0)
	mat.emission_energy_multiplier = 3.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_escudo_mesh.material_override = mat
	add_child(_escudo_mesh)

	_luz_escudo = OmniLight3D.new()
	_luz_escudo.light_color = Color(0.2, 0.8, 1.0)
	_luz_escudo.light_energy = 3.2
	_luz_escudo.omni_range = 6.0
	_luz_escudo.position = Vector3(0, 2.4, 0)
	add_child(_luz_escudo)

func _crear_telegraph_carga():
	_telegraph_carga = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2.4, 0.05, 10.0)
	_telegraph_carga.mesh = box
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.08, 0.08, 0.5)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_telegraph_carga.material_override = mat
	_telegraph_carga.position = Vector3(0, 0.04, -5.0)
	_telegraph_carga.visible = false
	add_child(_telegraph_carga)

func _conectar_boton_movil():
	_boton_movil = get_tree().get_first_node_in_group("boton_movil")
	if _boton_movil != null:
		if not _boton_movil.click_presionado.is_connected(_on_boton_click):
			_boton_movil.click_presionado.connect(_on_boton_click)

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	_anim_ctrl.actualizar(delta)
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 16.0 * delta)
	if aura_roja != null:
		aura_roja.rotate_y(delta * 2.5)
	if _escudo_mesh != null and _escudo_mesh.visible:
		_escudo_mesh.rotate_y(delta * 1.8)

	if _boton_movil == null or not is_instance_valid(_boton_movil):
		_boton_movil = get_tree().get_first_node_in_group("boton_movil")
		if _boton_movil != null and not _boton_movil.click_presionado.is_connected(_on_boton_click):
			_boton_movil.click_presionado.connect(_on_boton_click)

	if _en_agonia_final:
		velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
		_anim_ctrl.reproducir_bucle("stunned", 0.12, 1.0, 1)
		move_and_slide()
		global_position.x += randf_range(-0.03, 0.03)
		global_position.z += randf_range(-0.03, 0.03)
		return

	if not escudo_activo:
		_reloj_vulnerabilidad -= delta
		if _reloj_vulnerabilidad <= 0.0:
			_restaurar_escudo()

	if _esta_telegrafando:
		velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta) + _knockback_velocity.x
		velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta) + _knockback_velocity.z
		_anim_ctrl.reproducir_bucle("telegraph", 0.12, 1.0, 1)
		move_and_slide()
		return

	if _esta_cargando:
		_anim_ctrl.reproducir_bucle("sprint", 0.08, 1.45, 1)
		move_and_slide()
		return

	_reloj_ataque = maxf(_reloj_ataque - delta, 0.0)
	_reloj_carga = maxf(_reloj_carga - delta, 0.0)

	if is_instance_valid(jugador) and jugador is Node3D:
		var dir = (jugador.global_position - global_position)
		dir.y = 0.0
		var dist = dir.length()

		if dist > 0.1:
			look_at(global_position + dir.normalized(), Vector3.UP)

		var vel_base = rapidez * (1.25 if _en_enrage else 1.0)
		var vel_actual = vel_base * (0.6 if not escudo_activo else 1.0)
		var tiempo_actual_telegraph = 0.55 if _en_enrage else tiempo_telegraph

		if dist > 7.5 and _reloj_carga <= 0.001 and _reloj_ataque <= 0.001:
			_iniciar_carga_sombria()
		elif dist <= radio_golpe and _reloj_ataque <= 0.001:
			_iniciar_corte_guadana(tiempo_actual_telegraph)
		else:
			var dir_mov = dir.normalized()
			velocity.x = dir_mov.x * vel_actual + _knockback_velocity.x
			velocity.z = dir_mov.z * vel_actual + _knockback_velocity.z
			_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), _en_enrage, is_on_floor(), vel_actual)
	else:
		velocity.x = _knockback_velocity.x
		velocity.z = _knockback_velocity.z
		_anim_ctrl.actualizar_locomocion(0.0, false, is_on_floor(), rapidez)

	move_and_slide()

func _iniciar_carga_sombria():
	_esta_telegrafando = true
	_esta_cargando = true
	_reloj_carga = randf_range(6.0, 8.5)

	if is_instance_valid(jugador):
		var dir = (jugador.global_position - global_position)
		dir.y = 0.0
		_dir_carga = dir.normalized()
		look_at(global_position + _dir_carga, Vector3.UP)

	if _telegraph_carga != null:
		_telegraph_carga.visible = true
		_telegraph_carga.scale = Vector3(0.2, 1.0, 1.0)
		var tw = create_tween()
		tw.tween_property(_telegraph_carga, "scale", Vector3(1.0, 1.0, 1.0), 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	get_tree().create_timer(0.55).timeout.connect(_ejecutar_carga_sombria)

func _ejecutar_carga_sombria():
	if _telegraph_carga != null:
		_telegraph_carga.visible = false
	_esta_telegrafando = false
	if muerto or _en_agonia_final:
		_esta_cargando = false
		return

	velocity = _dir_carga * (rapidez * 2.8)
	AudioManager.play("corte_giratorio", 0.75, 2.0)
	_sacudir_camara(0.25)

	get_tree().create_timer(0.40).timeout.connect(func():
		if not is_instance_valid(self) or not is_inside_tree() or muerto or _en_agonia_final:
			return
		_esta_cargando = false
		if is_instance_valid(jugador) and global_position.distance_to(jugador.global_position) <= (radio_golpe + 0.5):
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(40.0)
			elif jugador.has_node("Salud"):
				jugador.get_node("Salud").recibir_golpe(40)
			_sacudir_camara(0.45)
			if jugador.has_method("aplicar_knockback"):
				jugador.aplicar_knockback(_dir_carga * 10.0)
	)

func _iniciar_corte_guadana(tiempo_tel: float = 0.85):
	_esta_telegrafando = true

	if telegraph_marca != null:
		telegraph_marca.visible = true
		telegraph_marca.scale = Vector3(0.1, 1.0, 0.1)
		var tw = create_tween()
		tw.tween_property(telegraph_marca, "scale", Vector3(1.0, 1.0, 1.0), tiempo_tel).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	get_tree().create_timer(tiempo_tel).timeout.connect(_ejecutar_corte_guadana)

func _ejecutar_corte_guadana():
	if telegraph_marca != null:
		telegraph_marca.visible = false
	_esta_telegrafando = false
	if muerto or _en_agonia_final:
		return
	_reloj_ataque = 1.15
	_anim_ctrl.reproducir_accion("attack-melee-right", 2, 0.08, 1.15)

	AudioManager.play("danio_jugador", 0.65, 2.0)

	if is_instance_valid(jugador) and jugador is Node3D:
		var dist = global_position.distance_to(jugador.global_position)
		if dist <= radio_golpe + 1.0:
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(dano_guadana)
			elif jugador.has_node("Salud"):
				jugador.get_node("Salud").recibir_golpe(int(dano_guadana))
			_sacudir_camara(0.4)

	_disparar_ondas_guadana()

func _disparar_ondas_guadana():
	if not is_instance_valid(jugador):
		return
	var dir_base = (jugador.global_position - global_position)
	dir_base.y = 0.0
	if dir_base.length_squared() < 0.01:
		dir_base = -global_transform.basis.z
	dir_base = dir_base.normalized()

	var escena_proyectil = load("res://proyectil_enemigo.tscn")
	if escena_proyectil == null:
		return

	var angulos = [-24.0, 0.0, 24.0]
	for ang in angulos:
		var dir_rot = dir_base.rotated(Vector3.UP, deg_to_rad(ang))
		var p = escena_proyectil.instantiate()
		get_parent().add_child(p)
		var pos_inicio = global_position + Vector3(0, 1.4, 0) + dir_rot * 1.5
		p.iniciar(pos_inicio, dir_rot, 22.0, 6.2)

func _on_boton_click(_total_clicks: int):
	if not is_instance_valid(self) or vida <= 0.0:
		return

	var pos_origen = global_position
	if is_instance_valid(_boton_movil):
		pos_origen = _boton_movil.global_position

	_crear_rayo_hacia_parca(pos_origen)

	if _esta_cargando and _telegraph_carga != null and _telegraph_carga.visible:
		_esta_cargando = false
		_esta_telegrafando = false
		_telegraph_carga.visible = false
		AudioManager.play("puzzle_completo", 1.25)
		_sacudir_camara(0.35)
		_crear_texto_flotante("💥 ¡CARGA SOMBRÍA DESVIADA!", true)
		aplicar_knockback(-_dir_carga * 12.0)
		return

	if _en_agonia_final:
		_ejecutar_golpe_gracia_final()
		return

	if escudo_activo:
		clics_actuales_escudo += 1
		AudioManager.play("altar_activado", 1.0 + (clics_actuales_escudo * 0.16))
		_sacudir_camara(0.18)

		if is_instance_valid(jugador):
			var dir_empuje = (global_position - jugador.global_position).normalized()
			aplicar_knockback(dir_empuje * 12.0)

		_crear_texto_flotante("⚡ SOBRECARGA %d/%d" % [clics_actuales_escudo, clics_para_romper_escudo], true)

		if clics_actuales_escudo >= clics_para_romper_escudo:
			_romper_escudo()
		else:
			_actualizar_hud_jefe()
	else:
		var dano_runico = 150.0
		AudioManager.play("orbe_explosion", 1.2)
		_sacudir_camara(0.15)
		_crear_texto_flotante("⚡ ¡DESCARGA NÚCLEO! 150", true)
		recibir_dano(dano_runico, true)

func _romper_escudo():
	escudo_activo = false
	clics_actuales_escudo = 0
	_reloj_vulnerabilidad = 6.5 if _en_enrage else duracion_vulnerabilidad

	if _escudo_mesh != null:
		_escudo_mesh.visible = false
	if _luz_escudo != null:
		_luz_escudo.visible = false

	AudioManager.play("puzzle_completo", 1.1)
	_sacudir_camara(0.35)
	_crear_texto_flotante("💥 ¡ESCUDO ROTO! ¡ATACA!", true)

	velocity = Vector3.ZERO
	_reloj_ataque = maxf(_reloj_ataque, 1.4)
	_actualizar_hud_jefe()

func _restaurar_escudo():
	if _en_agonia_final or vida <= 0.0:
		return
	escudo_activo = true
	clics_actuales_escudo = 0
	clics_para_romper_escudo = _calcular_clics_necesarios()

	if _escudo_mesh != null:
		_escudo_mesh.visible = true
		var pct_perdido = 1.0 - (vida / vida_maxima)
		var mat = _escudo_mesh.material_override as StandardMaterial3D
		if mat != null:
			mat.albedo_color = Color(0.2, 0.65, 1.0, 0.35).lerp(Color(0.9, 0.1, 0.25, 0.55), pct_perdido)
			mat.emission = Color(0.15, 0.75, 1.0).lerp(Color(1.0, 0.15, 0.2), pct_perdido)

	if _luz_escudo != null:
		_luz_escudo.visible = true

	AudioManager.play("jefe_alerta", 1.3)
	_crear_texto_flotante("🛡️ ¡ESCUDO REGENERADO! (%d CLICS)" % clics_para_romper_escudo, false)
	_actualizar_hud_jefe()
	_invocar_sombras_guardianas()

func _invocar_sombras_guardianas():
	var escena_espectro = load("res://espectro.tscn")
	if escena_espectro == null:
		return
	for i in range(2):
		var e = escena_espectro.instantiate()
		get_parent().add_child(e)
		var offset = Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0))
		e.global_position = global_position + offset
		if "rapidez" in e:
			e.rapidez *= 1.15

func desactivar_escudo_runico(duracion: float = 7.0):
	_reloj_escudo_roto = duracion
	if escudo_activo:
		_romper_escudo()

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false):
	if _en_agonia_final or muerto:
		return
	var fuente_str := "normal"
	if typeof(fuente) == TYPE_BOOL:
		es_critico = fuente
	else:
		fuente_str = str(fuente)

	if escudo_activo:
		AudioManager.play("escudo_bloqueo", 1.1)
		_crear_texto_flotante("🛡️ ¡ESCUDO! (%d Clics al Núcleo)" % (clics_para_romper_escudo - clics_actuales_escudo), false)
		return

	var dano_final = cantidad * 1.25 * (1.0 + MetaprogresoManager.obtener_bono_bestiario("parca"))
	vida = maxf(vida - dano_final, 1.0)
	_anim_ctrl.disparar_golpe()

	clics_para_romper_escudo = _calcular_clics_necesarios()

	if not _en_enrage and vida <= (vida_maxima * 0.3):
		_en_enrage = true
		if luz_roja != null:
			luz_roja.light_energy = 6.0
			luz_roja.omni_range = 14.0

	var pool = get_tree().get_first_node_in_group("damage_numbers")
	var pos_num = global_position + Vector3(randf_range(-0.5, 0.5), 3.2, randf_range(-0.5, 0.5))
	if pool != null and pool.has_method("mostrar_dano"):
		pool.mostrar_dano(pos_num, int(round(dano_final)), es_critico, fuente_str)
	else:
		var escena_num = load("res://damage_number_3d.tscn")
		if escena_num != null and is_inside_tree() and get_parent() != null:
			var n = escena_num.instantiate()
			get_parent().add_child(n)
			n.global_position = pos_num
			n.iniciar(dano_final, es_critico, false)

	_actualizar_hud_jefe()

	if vida <= 1.0:
		_iniciar_agonia_final()

func _iniciar_agonia_final():
	if _en_agonia_final:
		return
	_en_agonia_final = true
	escudo_activo = false
	if _escudo_mesh != null:
		_escudo_mesh.visible = false
	if _luz_escudo != null:
		_luz_escudo.visible = false

	AudioManager.play("derrota", 1.1)
	_sacudir_camara(0.4)
	_crear_texto_flotante("⚡ ¡PULSA EL NÚCLEO PARA PURIFICAR!", true)
	_actualizar_hud_jefe()

func _exit_tree():
	if Engine.time_scale != 1.0:
		Engine.time_scale = 1.0

func _ejecutar_golpe_gracia_final():
	vida = 0.0
	_sacudir_camara(0.7)

	Engine.time_scale = 0.15
	await get_tree().create_timer(0.15, true, false, true).timeout
	Engine.time_scale = 1.0
	if not is_instance_valid(self) or not is_inside_tree():
		return

	morir()

func morir():
	if muerto:
		return
	muerto = true

	if hud != null and hud.has_method("ocultar_barra_jefe"):
		hud.ocultar_barra_jefe()

	AudioManager.play("victoria", 1.0, 4.0)

	var pj = get_tree().get_first_node_in_group("jugador")
	MetaprogresoManager.procesar_baja_completa(self, pj, "parca", true)

	emit_signal("parca_derrotada")

	var portal = get_tree().get_first_node_in_group("portal_ascension")
	if portal != null and portal.has_method("desbloquear_portal"):
		portal.desbloquear_portal()

	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null:
		if partida.has_method("notificar_parca_derrotada"):
			partida.notificar_parca_derrotada()
		if partida.has_method("ganar"):
			partida.ganar()

	queue_free()

func _crear_rayo_hacia_parca(desde_pos: Vector3):
	var orbe = MeshInstance3D.new()
	var esfera = SphereMesh.new()
	esfera.radius = 0.35
	esfera.height = 0.7
	orbe.mesh = esfera

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.85, 0.1) if _en_agonia_final else Color(0.2, 0.85, 1.0)
	orbe.material_override = mat

	if get_parent() != null:
		get_parent().add_child(orbe)
		orbe.global_position = desde_pos + Vector3(0, 1.0, 0)
		var dest = global_position + Vector3(0, 2.0, 0)
		var tw = create_tween()
		tw.tween_property(orbe, "global_position", dest, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			if is_instance_valid(orbe):
				orbe.queue_free()
		)

func _crear_texto_flotante(texto: String, es_crit: bool = false):
	var pool = get_tree().get_first_node_in_group("damage_numbers")
	if pool != null and pool.has_method("mostrar_texto"):
		pool.mostrar_texto(global_position + Vector3(0, 3.4, 0), texto, Color(1.0, 0.85, 0.2), 1.3)
		return
	var escena_num = load("res://damage_number_3d.tscn")
	if escena_num != null and is_inside_tree() and get_parent() != null:
		var n = escena_num.instantiate()
		var pos_num = global_position + Vector3(randf_range(-0.4, 0.4), 3.4, randf_range(-0.4, 0.4))
		get_parent().add_child(n)
		n.global_position = pos_num
		n.iniciar(0.0, es_crit, false, texto)

func _actualizar_hud_jefe():
	if hud == null:
		return
	var titulo = ""
	if _en_agonia_final:
		titulo = "⚡ ¡PULSA EL BOTÓN MÓVIL PARA PURIFICAR A LA PARCA! ⚡"
	elif escudo_activo:
		titulo = "💀 LA PARCA ROJA [🛡️ ESCUDO: %d/%d CLICS AL NÚCLEO]" % [clics_actuales_escudo, clics_para_romper_escudo]
	else:
		var segs = maxf(ceil(_reloj_vulnerabilidad), 1.0)
		titulo = "💀 LA PARCA ROJA [⚡ VULNERABLE (%ds) - ¡ATACA!]" % int(segs)

	if hud.has_method("actualizar_barra_jefe"):
		hud.actualizar_barra_jefe(vida, titulo)
	elif hud.has_method("mostrar_barra_jefe"):
		hud.mostrar_barra_jefe(titulo, vida_maxima, vida)

func _sacudir_camara(intensidad: float = 0.3):
	var cam = get_viewport().get_camera_3d()
	if cam != null and cam.has_method("sacudir"):
		cam.sacudir(intensidad)
	else:
		var c = get_tree().get_first_node_in_group("camara")
		if c != null and c.has_method("sacudir"):
			c.sacudir(intensidad)
