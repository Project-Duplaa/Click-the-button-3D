extends CharacterBody3D

# Jefe 1: Centurión Corrupto (Minuto 3:00)
# Comandante de la guardia caída. 850 HP.
# Incluye Cristales de Escudo Clicables al 50% HP, interrupción de Sentencia de Muerte con Botón Móvil y Knockback real.

signal jefe_derrotado

const AudioManager = preload("res://audio_manager.gd")

@export var rapidez: float = 3.65
@export var vida_maxima: float = 1750.0
@export var dano_golpe: float = 45.0
@export var dano_sentencia: float = 95.0
@export var rango_ataque: float = 3.0
@export var tiempo_telegraph: float = 0.60

var vida: float = 1750.0
var muerto: bool = false
var jugador: Node3D = null
var hud: Node = null
var _boton_movil: Node = null

var _reloj_ataque: float = 0.0
var _reloj_grito: float = 5.5
var _reloj_sentencia: float = 11.0
var _esta_telegrafando: bool = false
var _canalizando_sentencia: bool = false
var _grito_activo: bool = false
var _aturdido: bool = false
var _knockback_velocity: Vector3 = Vector3.ZERO
var _i_frame_timer: float = 0.0

# Cristales de Escudo Clicables al 50% HP
var _cristales_invocados: bool = false
var _cristales_activos: Array = []
var _angulo_cristales: float = 0.0

var _escala_base: Vector3 = Vector3.ONE
var _anim_ctrl: AnimadorEntidad = AnimadorEntidad.new()

@onready var modelo: Node3D = $Modelo if has_node("Modelo") else null
@onready var telegraph_mesh: MeshInstance3D = $TelegraphSuelo
@onready var luz_aura: OmniLight3D = $LuzCenturion

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

	call_deferred("_conectar_boton_movil")
	AudioManager.play("jefe_alerta", 1.25)

	if hud != null and hud.has_method("mostrar_barra_jefe"):
		hud.mostrar_barra_jefe("⚔️ CENTURIÓN CORRUPTO", vida_maxima, vida)

func aplicar_knockback(impulso: Vector3, _duracion_stun: float = 0.08):
	var kb = impulso * 0.45
	kb.y = 0.0
	_knockback_velocity += kb
	if _knockback_velocity.length() > 12.0:
		_knockback_velocity = _knockback_velocity.normalized() * 12.0

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

	_anim_ctrl.actualizar(delta)
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 16.0 * delta)
	_actualizar_orbita_cristales(delta)

	if _boton_movil == null or not is_instance_valid(_boton_movil):
		_conectar_boton_movil()

	if _aturdido or _esta_telegrafando or _canalizando_sentencia:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta) + _knockback_velocity.x
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta) + _knockback_velocity.z
		_anim_ctrl.reproducir_bucle("stunned" if _aturdido else "telegraph", 0.12, 1.0, 1)
		move_and_slide()
		return

	_reloj_ataque = maxf(_reloj_ataque - delta, 0.0)
	_reloj_grito = maxf(_reloj_grito - delta, 0.0)
	_reloj_sentencia = maxf(_reloj_sentencia - delta, 0.0)

	if is_instance_valid(jugador) and jugador is Node3D:
		var dir = (jugador.global_position - global_position)
		dir.y = 0.0
		var dist = dir.length()

		if dist > 0.1:
			look_at(global_position + dir.normalized(), Vector3.UP)

		if _reloj_sentencia <= 0.001 and dist <= 10.0:
			_iniciar_sentencia_de_muerte()
			return

		if _reloj_grito <= 0.001 and dist <= 12.0:
			_ejecutar_grito_guerra()

		var vel_actual = rapidez * (1.35 if _grito_activo else 1.0)

		if dist <= rango_ataque and _reloj_ataque <= 0.001:
			_iniciar_ataque_telegrafiado()
		else:
			var dir_mov = dir.normalized()
			velocity.x = dir_mov.x * vel_actual + _knockback_velocity.x
			velocity.z = dir_mov.z * vel_actual + _knockback_velocity.z
			_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), _grito_activo, is_on_floor(), vel_actual)
	else:
		velocity.x = _knockback_velocity.x
		velocity.z = _knockback_velocity.z
		_anim_ctrl.actualizar_locomocion(0.0, false, is_on_floor(), rapidez)

	move_and_slide()

func _invocar_cristales_escudo():
	_cristales_invocados = true
	_crear_texto_flotante("💎 ¡CRISTALES DE ESCUDO! ¡CLIC EN ELLOS O EN EL NÚCLEO!", true)
	for i in range(3):
		var area = Area3D.new()
		area.name = "CristalEscudo_%d" % i
		area.add_to_group("cristal_jefe")
		area.input_ray_pickable = true
		var col = CollisionShape3D.new()
		var sph = SphereShape3D.new()
		sph.radius = 0.65
		col.shape = sph
		area.add_child(col)

		var mesh_i = MeshInstance3D.new()
		var prism = PrismMesh.new()
		prism.size = Vector3(0.6, 0.9, 0.6)
		mesh_i.mesh = prism
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.2, 0.95, 1.0)
		mesh_i.material_override = mat
		area.add_child(mesh_i)

		area.input_event.connect(func(_cam, ev, _pos, _norm, _idx):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_destruir_cristal(area)
		)
		add_child(area)
		_cristales_activos.append(area)
	_actualizar_hud()

func _actualizar_orbita_cristales(delta: float):
	if _cristales_activos.is_empty():
		return
	_angulo_cristales += delta * 2.4
	var limpios: Array = []
	for i in range(_cristales_activos.size()):
		var c = _cristales_activos[i]
		if is_instance_valid(c):
			var ang = _angulo_cristales + (TAU / float(max(_cristales_activos.size(), 1))) * i
			c.position = Vector3(cos(ang) * 2.2, 1.8, sin(ang) * 2.2)
			c.rotate_y(delta * 3.0)
			limpios.append(c)
	_cristales_activos = limpios

func _destruir_cristal(cristal: Node):
	if is_instance_valid(cristal):
		cristal.queue_free()
	_cristales_activos.erase(cristal)
	AudioManager.play("corte_giratorio", 1.5)
	_crear_texto_flotante("💎 ¡CRISTAL ROTO! (%d restantes)" % _cristales_activos.size(), true)
	if _cristales_activos.is_empty():
		_aturdido = true
		_crear_texto_flotante("💥 ¡ESCUDO QUEBRADO! (Aturdido 3s - Daño x2)", true)
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(self):
				_aturdido = false
				_actualizar_hud()
		)
	_actualizar_hud()

func _iniciar_sentencia_de_muerte():
	_canalizando_sentencia = true
	_reloj_sentencia = randf_range(12.0, 15.0)

	AudioManager.play("rugido_jefe", 1.3)
	_crear_texto_flotante("⚡ ¡PULSA EL NÚCLEO PARA DESARMARLO!", true)

	if hud != null and hud.has_method("actualizar_barra_jefe"):
		hud.actualizar_barra_jefe(vida, "⚔️ CENTURIÓN [⚡ ¡PULSA EL NÚCLEO PARA INTERRUMPIR!]")

	if telegraph_mesh != null:
		telegraph_mesh.visible = true
		telegraph_mesh.scale = Vector3(0.2, 1.0, 0.2)
		var mat = telegraph_mesh.mesh.material as StandardMaterial3D
		if mat != null:
			mat.albedo_color = Color(1.0, 0.1, 0.1, 0.8)
		var tw = create_tween()
		tw.tween_property(telegraph_mesh, "scale", Vector3(1.4, 1.0, 1.4), 2.2).set_trans(Tween.TRANS_LINEAR)

	get_tree().create_timer(2.2).timeout.connect(_ejecutar_sentencia_de_muerte)

func _ejecutar_sentencia_de_muerte():
	if muerto or not _canalizando_sentencia:
		return

	_canalizando_sentencia = false
	if telegraph_mesh != null:
		telegraph_mesh.visible = false
	_anim_ctrl.reproducir_accion("attack-melee-right", 2, 0.08, 1.25)

	AudioManager.play("danio_jugador", 0.6, 2.5)
	_sacudir_camara(0.45)

	if is_instance_valid(jugador) and jugador is Node3D:
		var dist = global_position.distance_to(jugador.global_position)
		if dist <= (rango_ataque * 1.4):
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(dano_sentencia)
			elif jugador.has_node("Salud"):
				jugador.get_node("Salud").recibir_golpe(int(dano_sentencia))

	_actualizar_hud()

func _on_boton_click(_total_clicks: int):
	if vida <= 0.0:
		return

	var pos_origen = global_position
	if is_instance_valid(_boton_movil):
		pos_origen = _boton_movil.global_position
	_crear_rayo_hacia_jefe(pos_origen)

	if not _cristales_activos.is_empty():
		_destruir_cristal(_cristales_activos[0])
		return

	if _canalizando_sentencia:
		_canalizando_sentencia = false
		_aturdido = true
		if telegraph_mesh != null:
			telegraph_mesh.visible = false

		AudioManager.play("puzzle_completo", 1.2)
		_sacudir_camara(0.3)
		_crear_texto_flotante("💥 ¡DESARMADO POR EL NÚCLEO! (Aturdido)", true)

		aplicar_knockback(-global_transform.basis.z * 10.0)
		if hud != null and hud.has_method("actualizar_barra_jefe"):
			hud.actualizar_barra_jefe(vida, "⚔️ CENTURIÓN [💥 ¡DESARMADO Y ATURDIDO!]")

		get_tree().create_timer(2.5).timeout.connect(func():
			if is_instance_valid(self):
				_aturdido = false
				_actualizar_hud()
		)
		return

	if is_instance_valid(jugador):
		var dir_empuje = (global_position - jugador.global_position).normalized()
		aplicar_knockback(dir_empuje * 10.0)
		_crear_texto_flotante("⚡ REPELIDO", false)
		AudioManager.play("altar_activado", 1.1)

func _ejecutar_grito_guerra():
	_reloj_grito = 9.0
	_grito_activo = true
	AudioManager.play("alerta_oleada", 1.4, 2.0)
	_sacudir_camara(0.2)

	_crear_texto_flotante("📢 ¡POR EL COLISEO!", true)

	if luz_aura != null:
		luz_aura.light_energy = 4.0

	get_tree().create_timer(3.5).timeout.connect(func():
		if is_instance_valid(self):
			_grito_activo = false
			if luz_aura != null:
				luz_aura.light_energy = 2.0
	)

func _iniciar_ataque_telegrafiado():
	_esta_telegrafando = true

	if telegraph_mesh != null:
		telegraph_mesh.visible = true
		telegraph_mesh.scale = Vector3(0.2, 1.0, 0.2)
		var mat = telegraph_mesh.mesh.material as StandardMaterial3D
		if mat != null:
			mat.albedo_color = Color(1, 0.45, 0.1, 0.5)
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
	_reloj_ataque = 1.3
	_anim_ctrl.reproducir_accion("attack-melee-right", 2, 0.08, 1.0)

	AudioManager.play("corte_giratorio", 1.1)

	if is_instance_valid(jugador) and jugador is Node3D:
		var dist = global_position.distance_to(jugador.global_position)
		if dist <= rango_ataque + 0.8:
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(dano_golpe)
			elif jugador.has_node("Salud"):
				jugador.get_node("Salud").recibir_golpe(int(dano_golpe))
			_sacudir_camara(0.3)

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
	var mult = 2.0 if _aturdido else (0.20 if not _cristales_activos.is_empty() else 1.0)
	var dano_final = cantidad * mult * (1.0 + MetaprogresoManager.obtener_bono_bestiario("centurion"))

	# TOPE DE DAÑO POR GOLPE: Ningún impacto supera el 8% de la vida máxima
	var max_dano_por_golpe = vida_maxima * 0.08
	dano_final = minf(dano_final, max_dano_por_golpe)

	vida = maxf(vida - dano_final, 0.0)
	_anim_ctrl.disparar_golpe()

	if not _cristales_invocados and vida <= vida_maxima * 0.5:
		_i_frame_timer = 0.6
		_invocar_cristales_escudo()

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

func morir():
	if muerto:
		return
	muerto = true
	if hud != null and hud.has_method("ocultar_barra_jefe"):
		hud.ocultar_barra_jefe()

	AudioManager.play("enemigo_muerte", 0.8, 2.5)
	_sacudir_camara(0.35)

	var pj = get_tree().get_first_node_in_group("jugador")
	MetaprogresoManager.procesar_baja_completa(self, pj, "centurion", true)
	if pj != null:
		if pj.has_method("recoger_drop"):
			pj.recoger_drop(0, 25)
			pj.recoger_drop(1, 30)

	emit_signal("jefe_derrotado")
	queue_free()

func _actualizar_hud():
	if hud != null and hud.has_method("actualizar_barra_jefe"):
		var txt = "⚔️ CENTURIÓN CORRUPTO"
		if not _cristales_activos.is_empty():
			txt = "⚔️ CENTURIÓN [💎 CRISTALES: %d/3]" % _cristales_activos.size()
		elif _aturdido:
			txt = "⚔️ CENTURIÓN [💥 VULNERABLE x2]"
		hud.actualizar_barra_jefe(vida, txt)

func _crear_rayo_hacia_jefe(desde_pos: Vector3):
	var orbe = MeshInstance3D.new()
	var esfera = SphereMesh.new()
	esfera.radius = 0.28
	esfera.height = 0.56
	orbe.mesh = esfera
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.8, 0.2)
	orbe.material_override = mat
	if get_parent() != null:
		get_parent().add_child(orbe)
		orbe.global_position = desde_pos + Vector3(0, 1.0, 0)
		var dest = global_position + Vector3(0, 1.8, 0)
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

func _sacudir_camara(intensidad: float = 0.25):
	var cam = get_viewport().get_camera_3d()
	if cam != null and cam.has_method("sacudir"):
		cam.sacudir(intensidad)
	else:
		var c = get_tree().get_first_node_in_group("camara")
		if c != null and c.has_method("sacudir"):
			c.sacudir(intensidad)
