extends CharacterBody3D

# Jefe 3: Maestra Sanguinaria (Minuto 10:30)
# Comandante arquera de élite. 4800 HP.
# Incluye Cristales de Escudo Clicables al 50% HP, fijación rúnica, disipación de tormenta (3 clics) y Knockback real.

signal jefe_derrotado

const AudioManager = preload("res://audio_manager.gd")

@export var rapidez: float = 4.85
@export var vida_maxima: float = 10500.0
@export var dano_flecha: float = 48.0
@export var dano_lluvia: float = 85.0
@export var distancia_kiting: float = 7.0

var vida: float = 10500.0
var muerto: bool = false
var jugador: Node3D = null
var hud: Node = null
var _boton_movil: Node = null

var _reloj_disparo: float = 1.0
var _reloj_lluvia: float = 6.0
var _esta_canalizando: bool = false
var _pos_lluvia_objetivo: Vector3 = Vector3.ZERO
var _telegraph_lluvia: MeshInstance3D = null

var _clics_tormenta: int = 0
var _clics_necesarios_tormenta: int = 3
var _reloj_fijacion_luz: float = 0.0
var _aturdida: bool = false
var _knockback_velocity: Vector3 = Vector3.ZERO
var _i_frame_timer: float = 0.0

var _cristales_invocados: bool = false
var _cristales_activos: Array = []
var _angulo_cristales: float = 0.0

var _escala_base: Vector3 = Vector3.ONE
var _anim_ctrl: AnimadorEntidad = AnimadorEntidad.new()

@onready var modelo: Node3D = $Modelo if has_node("Modelo") else null
@onready var luz_arco: OmniLight3D = $LuzMaestra

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

	_crear_telegraph_lluvia()
	call_deferred("_conectar_boton_movil")
	AudioManager.play("jefe_alerta", 1.2)

	if hud != null and hud.has_method("mostrar_barra_jefe"):
		hud.mostrar_barra_jefe("🏹 MAESTRA SANGUINARIA", vida_maxima, vida)

func aplicar_knockback(impulso: Vector3, _duracion_stun: float = 0.08):
	var kb = impulso * 0.5
	kb.y = 0.0
	_knockback_velocity += kb
	if _knockback_velocity.length() > 14.0:
		_knockback_velocity = _knockback_velocity.normalized() * 14.0

func _conectar_boton_movil():
	_boton_movil = get_tree().get_first_node_in_group("boton_movil")
	if _boton_movil != null:
		if not _boton_movil.click_presionado.is_connected(_on_boton_click):
			_boton_movil.click_presionado.connect(_on_boton_click)

func _crear_telegraph_lluvia():
	_telegraph_lluvia = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 4.0
	cyl.bottom_radius = 4.0
	cyl.height = 0.05
	_telegraph_lluvia.mesh = cyl
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.95, 0.1, 0.45, 0.55)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_telegraph_lluvia.material_override = mat
	_telegraph_lluvia.top_level = true
	_telegraph_lluvia.visible = false
	add_child(_telegraph_lluvia)

func _invocar_cristales_escudo():
	_cristales_invocados = true
	_crear_texto_flotante("💎 ¡4 CRISTALES SANGUINARIOS! ¡CLIC EN ELLOS!", true)
	for i in range(4):
		var area = Area3D.new()
		area.name = "CristalSanguinario_%d" % i
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
		mat.albedo_color = Color(1.0, 0.2, 0.65)
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
	_angulo_cristales += delta * 2.6
	var limpios: Array = []
	for i in range(_cristales_activos.size()):
		var c = _cristales_activos[i]
		if is_instance_valid(c):
			var ang = _angulo_cristales + (TAU / float(max(_cristales_activos.size(), 1))) * i
			c.position = Vector3(cos(ang) * 2.4, 1.9, sin(ang) * 2.4)
			c.rotate_y(delta * 3.0)
			limpios.append(c)
	_cristales_activos = limpios

func _destruir_cristal(cristal: Node):
	if is_instance_valid(cristal):
		cristal.queue_free()
	_cristales_activos.erase(cristal)
	AudioManager.play("corte_giratorio", 1.5)
	if _cristales_activos.is_empty():
		_aturdida = true
		_crear_texto_flotante("💥 ¡BARRERA SANGUINARIA ROTA! (Aturdida 3s)", true)
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(self):
				_aturdida = false
				_actualizar_hud()
		)
	_actualizar_hud()

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	if _i_frame_timer > 0.0:
		_i_frame_timer = maxf(_i_frame_timer - delta, 0.0)

	if _boton_movil == null or not is_instance_valid(_boton_movil):
		_conectar_boton_movil()

	_reloj_fijacion_luz = maxf(_reloj_fijacion_luz - delta, 0.0)
	_anim_ctrl.actualizar(delta)
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 16.0 * delta)
	_actualizar_orbita_cristales(delta)

	if _aturdida or _esta_canalizando:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta) + _knockback_velocity.x
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta) + _knockback_velocity.z
		_anim_ctrl.reproducir_bucle("stunned" if _aturdida else "telegraph", 0.12, 1.0, 1)
		move_and_slide()
		return

	_reloj_disparo = maxf(_reloj_disparo - delta, 0.0)
	_reloj_lluvia = maxf(_reloj_lluvia - delta, 0.0)

	if is_instance_valid(jugador) and jugador is Node3D:
		var hacia_jugador = (jugador.global_position - global_position)
		hacia_jugador.y = 0.0
		var dist = hacia_jugador.length()

		if dist > 0.1:
			look_at(global_position + hacia_jugador.normalized(), Vector3.UP)

		if _reloj_lluvia <= 0.001 and dist <= 18.0:
			_iniciar_lluvia_flechas()
			return

		if _reloj_disparo <= 0.001 and dist <= 16.0:
			_disparar_rafaga(hacia_jugador.normalized())
			_reloj_disparo = 1.6

		var vel_actual = rapidez * (0.4 if _reloj_fijacion_luz > 0.0 else 1.0)

		if dist < distancia_kiting:
			var dir_huida = -hacia_jugador.normalized()
			velocity.x = dir_huida.x * vel_actual + _knockback_velocity.x
			velocity.z = dir_huida.z * vel_actual + _knockback_velocity.z
		elif dist > (distancia_kiting + 4.0):
			var dir_acercar = hacia_jugador.normalized()
			velocity.x = dir_acercar.x * (vel_actual * 0.7) + _knockback_velocity.x
			velocity.z = dir_acercar.z * (vel_actual * 0.7) + _knockback_velocity.z
		else:
			var lateral = hacia_jugador.normalized().rotated(Vector3.UP, deg_to_rad(90))
			velocity.x = lateral.x * (vel_actual * 0.6) + _knockback_velocity.x
			velocity.z = lateral.z * (vel_actual * 0.6) + _knockback_velocity.z
		_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), false, is_on_floor(), vel_actual)
	else:
		velocity.x = _knockback_velocity.x
		velocity.z = _knockback_velocity.z
		_anim_ctrl.actualizar_locomocion(0.0, false, is_on_floor(), rapidez)

	move_and_slide()

func _disparar_rafaga(dir_frente: Vector3):
	_anim_ctrl.reproducir_accion("attack-ranged", 2, 0.06, 1.2)
	AudioManager.play("disparo_arquero", 1.1)
	var escena_flecha = load("res://proyectil_enemigo.tscn")
	if escena_flecha == null:
		return

	var angulos = [-16.0, 0.0, 16.0]
	for ang in angulos:
		var dir_rot = dir_frente.rotated(Vector3.UP, deg_to_rad(ang))
		var f = escena_flecha.instantiate()
		get_parent().add_child(f)
		var pos_inicio = global_position + Vector3(0, 1.8, 0) + dir_rot * 1.2
		f.iniciar(pos_inicio, dir_rot, dano_flecha, 7.5)

func _iniciar_lluvia_flechas():
	_esta_canalizando = true
	_clics_tormenta = 0
	_reloj_lluvia = 8.5
	_pos_lluvia_objetivo = jugador.global_position
	_pos_lluvia_objetivo.y = 0.05

	AudioManager.play("alerta_oleada", 1.5, 2.0)
	_crear_texto_flotante("⚡ ¡PULSA EL NÚCLEO (0/%d) PARA DISIPAR!" % _clics_necesarios_tormenta, true)

	if hud != null and hud.has_method("actualizar_barra_jefe"):
		hud.actualizar_barra_jefe(vida, "🏹 MAESTRA [⚡ ¡DISIPA LA TORMENTA: 0/%d CLICS!]" % _clics_necesarios_tormenta)

	if _telegraph_lluvia != null:
		_telegraph_lluvia.global_position = _pos_lluvia_objetivo
		_telegraph_lluvia.visible = true
		_telegraph_lluvia.scale = Vector3(0.2, 1.0, 0.2)
		var tw = create_tween()
		tw.tween_property(_telegraph_lluvia, "scale", Vector3(1.0, 1.0, 1.0), 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	get_tree().create_timer(1.6).timeout.connect(_ejecutar_lluvia_flechas)

func _ejecutar_lluvia_flechas():
	if _telegraph_lluvia != null:
		_telegraph_lluvia.visible = false
	if muerto or not _esta_canalizando:
		_esta_canalizando = false
		return

	_esta_canalizando = false
	if _telegraph_lluvia != null:
		_telegraph_lluvia.visible = false
	_anim_ctrl.reproducir_accion("cast", 2, 0.08, 1.1)

	AudioManager.play("impacto_flecha", 1.2, 2.5)
	_sacudir_camara(0.35)

	if is_instance_valid(jugador) and jugador is Node3D:
		var dist = Vector2(jugador.global_position.x, jugador.global_position.z).distance_to(Vector2(_pos_lluvia_objetivo.x, _pos_lluvia_objetivo.z))
		if dist <= 4.2:
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(dano_lluvia)
			elif jugador.has_node("Salud"):
				jugador.get_node("Salud").recibir_golpe(int(dano_lluvia))
			_sacudir_camara(0.4)

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

	if _esta_canalizando:
		_clics_tormenta += 1
		AudioManager.play("altar_activado", 1.1 + (_clics_tormenta * 0.2))
		_sacudir_camara(0.2)
		_crear_texto_flotante("⚡ DISIPAR %d/%d" % [_clics_tormenta, _clics_necesarios_tormenta], true)

		if hud != null and hud.has_method("actualizar_barra_jefe"):
			hud.actualizar_barra_jefe(vida, "🏹 MAESTRA [⚡ ¡DISIPA LA TORMENTA: %d/%d CLICS!]" % [_clics_tormenta, _clics_necesarios_tormenta])

		if _clics_tormenta >= _clics_necesarios_tormenta:
			_disipar_tormenta()
		return

	_reloj_fijacion_luz = 3.5
	AudioManager.play("altar_activado", 1.2)
	_crear_texto_flotante("⚡ ¡FIJADA POR EL NÚCLEO! (-60% Vel)", true)
	if luz_arco != null:
		luz_arco.light_energy = 5.0
		get_tree().create_timer(3.5).timeout.connect(func():
			if is_instance_valid(self) and luz_arco != null:
				luz_arco.light_energy = 2.8
		)

func _disipar_tormenta():
	_esta_canalizando = false
	_aturdida = true
	if _telegraph_lluvia != null:
		_telegraph_lluvia.visible = false

	AudioManager.play("puzzle_completo", 1.15)
	_sacudir_camara(0.35)
	_crear_texto_flotante("💥 ¡TORMENTA DISIPADA! (Aturdida 2.5s)", true)

	if hud != null and hud.has_method("actualizar_barra_jefe"):
		hud.actualizar_barra_jefe(vida, "🏹 MAESTRA [💥 ¡TORMENTA DISIPADA!]")

	get_tree().create_timer(2.5).timeout.connect(func():
		if is_instance_valid(self):
			_aturdida = false
			_actualizar_hud()
	)

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
	var mult = 1.6 if _aturdida else (0.15 if not _cristales_activos.is_empty() else 1.0)
	var dano_final = cantidad * mult * (1.0 + MetaprogresoManager.obtener_bono_bestiario("maestra"))

	# TOPE DE DAÑO POR GOLPE: Ningún impacto supera el 6% de la vida máxima
	var max_dano_por_golpe = vida_maxima * 0.06
	dano_final = minf(dano_final, max_dano_por_golpe)

	vida = maxf(vida - dano_final, 0.0)
	_anim_ctrl.disparar_golpe()

	if not _cristales_invocados and vida <= vida_maxima * 0.5:
		_i_frame_timer = 0.6
		_invocar_cristales_escudo()

	var pool = get_tree().get_first_node_in_group("damage_numbers")
	var pos_num = global_position + Vector3(randf_range(-0.4, 0.4), 2.8, randf_range(-0.4, 0.4))
	if pool != null and pool.has_method("mostrar_dano"):
		pool.mostrar_dano(pos_num, int(round(dano_final)), es_critico or _aturdida, fuente_str)
	else:
		var escena_num = load("res://damage_number_3d.tscn")
		if escena_num != null and is_inside_tree() and get_parent() != null:
			var n = escena_num.instantiate()
			get_parent().add_child(n)
			n.global_position = pos_num
			n.iniciar(dano_final, es_critico or _aturdida, false)

	_actualizar_hud()
	if vida <= 0.0:
		morir()

func morir():
	if muerto:
		return
	muerto = true
	if hud != null and hud.has_method("ocultar_barra_jefe"):
		hud.ocultar_barra_jefe()

	if _telegraph_lluvia != null and is_instance_valid(_telegraph_lluvia):
		_telegraph_lluvia.queue_free()

	AudioManager.play("enemigo_muerte", 0.7, 3.0)
	_sacudir_camara(0.4)

	var pj = get_tree().get_first_node_in_group("jugador")
	MetaprogresoManager.procesar_baja_completa(self, pj, "maestra", true)
	if pj != null:
		if pj.has_method("recoger_drop"):
			pj.recoger_drop(0, 60)
			pj.recoger_drop(1, 75)

	emit_signal("jefe_derrotado")
	queue_free()

func _actualizar_hud():
	if hud == null:
		return
	var titulo = "🏹 MAESTRA SANGUINARIA"
	if not _cristales_activos.is_empty():
		titulo = "🏹 MAESTRA [💎 CRISTALES: %d/3]" % _cristales_activos.size()
	elif _aturdida:
		titulo = "🏹 MAESTRA [💥 ¡ATURDIDA!]"
	elif _reloj_fijacion_luz > 0.0:
		titulo = "🏹 MAESTRA [⚡ FIJADA (-60% VEL)]"

	if hud.has_method("actualizar_barra_jefe"):
		hud.actualizar_barra_jefe(vida, titulo)

func _crear_rayo_hacia_jefe(desde_pos: Vector3):
	var orbe = MeshInstance3D.new()
	var esfera = SphereMesh.new()
	esfera.radius = 0.28
	esfera.height = 0.56
	orbe.mesh = esfera
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.9, 0.2, 0.6)
	orbe.material_override = mat
	if get_parent() != null:
		get_parent().add_child(orbe)
		orbe.global_position = desde_pos + Vector3(0, 1.0, 0)
		var dest = global_position + Vector3(0, 2.0, 0)
		var tw = create_tween()
		tw.tween_property(orbe, "global_position", dest, 0.16)
		tw.tween_callback(func():
			if is_instance_valid(orbe):
				orbe.queue_free()
		)

func _crear_texto_flotante(texto: String, es_crit: bool = false):
	var pool = get_tree().get_first_node_in_group("damage_numbers")
	if pool != null and pool.has_method("mostrar_texto"):
		pool.mostrar_texto(global_position + Vector3(0, 3.2, 0), texto, Color(1.0, 0.45, 0.85), 1.2)
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
