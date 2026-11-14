extends CharacterBody3D

# Jefe 3: Maestra Sanguinaria (Oleada 9 / Minuto 9)
# Comandante arquera de élite. 1800 HP.
# Dificultad 3 (Precisión en combate a distancia):
# Mecánica 1: Cada clic al Botón Móvil la fija con luz rúnica y reduce su velocidad de kiting en -60%.
# Mecánica 2: Su "Tormenta de Flechas" se disipa y la aturde si el jugador acierta 2 clics al Botón Móvil durante la canalización.

signal jefe_derrotado

const AudioManager = preload("res://audio_manager.gd")

@export var rapidez: float = 4.2
@export var vida_maxima: float = 1800.0
@export var dano_flecha: float = 18.0
@export var dano_lluvia: float = 38.0
@export var distancia_kiting: float = 7.0

var vida: float = 1800.0
var jugador: Node3D = null
var hud: Node = null
var _boton_movil: Node = null

var _reloj_disparo: float = 1.0
var _reloj_lluvia: float = 6.0
var _esta_canalizando: bool = false
var _pos_lluvia_objetivo: Vector3 = Vector3.ZERO
var _telegraph_lluvia: MeshInstance3D = null

# Mecánicas del Botón
var _clics_tormenta: int = 0
var _clics_necesarios_tormenta: int = 2
var _reloj_fijacion_luz: float = 0.0
var _aturdida: bool = false

@onready var luz_arco: OmniLight3D = $LuzMaestra

func _ready():
	add_to_group("enemigos")
	add_to_group("jefes")
	vida = vida_maxima
	jugador = get_tree().get_first_node_in_group("jugador")
	hud = get_tree().get_first_node_in_group("hud")
	if hud == null:
		hud = get_parent().get_node_or_null("ClickHUD")
		
	_crear_telegraph_lluvia()
	call_deferred("_conectar_boton_movil")
	AudioManager.play("jefe_alerta", 1.2)
	
	if hud != null and hud.has_method("mostrar_barra_jefe"):
		hud.mostrar_barra_jefe("🏹 MAESTRA SANGUINARIA", vida_maxima, vida)

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

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if _boton_movil == null or not is_instance_valid(_boton_movil):
		_conectar_boton_movil()
		
	_reloj_fijacion_luz = maxf(_reloj_fijacion_luz - delta, 0.0)
	
	if _aturdida or _esta_canalizando:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
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
			
		# Habilidad: Tormenta de Flechas
		if _reloj_lluvia <= 0.001 and dist <= 18.0:
			_iniciar_lluvia_flechas()
			return
			
		if _reloj_disparo <= 0.001 and dist <= 16.0:
			_disparar_rafaga(hacia_jugador.normalized())
			_reloj_disparo = 1.6
			
		# Velocidad afectada si está fijada por el Núcleo (-60% velocidad)
		var vel_actual = rapidez * (0.4 if _reloj_fijacion_luz > 0.0 else 1.0)
		
		# Kiting inteligente
		if dist < distancia_kiting:
			var dir_huida = -hacia_jugador.normalized()
			velocity.x = dir_huida.x * vel_actual
			velocity.z = dir_huida.z * vel_actual
		elif dist > (distancia_kiting + 4.0):
			var dir_acercar = hacia_jugador.normalized()
			velocity.x = dir_acercar.x * (vel_actual * 0.7)
			velocity.z = dir_acercar.z * (vel_actual * 0.7)
		else:
			var lateral = hacia_jugador.normalized().rotated(Vector3.UP, deg_to_rad(90))
			velocity.x = lateral.x * (vel_actual * 0.6)
			velocity.z = lateral.z * (vel_actual * 0.6)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		
	move_and_slide()

func _disparar_rafaga(dir_frente: Vector3):
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
	_crear_texto_flotante("⚡ ¡PULSA EL NÚCLEO (0/2) PARA DISIPAR!", true)
	
	if hud != null and hud.has_method("actualizar_barra_jefe"):
		hud.actualizar_barra_jefe(vida, "🏹 MAESTRA [⚡ ¡DISIPA LA TORMENTA: 0/2 CLICS!]")
		
	if _telegraph_lluvia != null:
		_telegraph_lluvia.global_position = _pos_lluvia_objetivo
		_telegraph_lluvia.visible = true
		_telegraph_lluvia.scale = Vector3(0.2, 1.0, 0.2)
		var tw = create_tween()
		tw.tween_property(_telegraph_lluvia, "scale", Vector3(1.0, 1.0, 1.0), 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	get_tree().create_timer(1.6).timeout.connect(_ejecutar_lluvia_flechas)

func _ejecutar_lluvia_flechas():
	if not _esta_canalizando:
		return # Fue disipada por los 2 clics al botón móvil
		
	_esta_canalizando = false
	if _telegraph_lluvia != null:
		_telegraph_lluvia.visible = false
		
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
	
	# CASO 1: Disipar Tormenta de Flechas si está canalizando
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
		
	# CASO 2: Clic regular -> Fijación Rúnica (-60% velocidad de kiting por 3.5s)
	_reloj_fijacion_luz = 3.5
	AudioManager.play("altar_activado", 1.2)
	_crear_texto_flotante("⚡ ¡FIJADA POR EL NÚCLEO! (-60% Vel)", true)
	if luz_arco != null:
		luz_arco.light_energy = 5.0
		get_tree().create_timer(3.5).timeout.connect(func():
			if luz_arco != null:
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
		_aturdida = false
		_actualizar_hud()
	)

func recibir_dano(cantidad: float, es_critico: bool = false):
	var dano_final = cantidad * (1.25 if _aturdida else 1.0)
	vida = maxf(vida - dano_final, 0.0)
	
	var escena_num = load("res://damage_number_3d.tscn")
	if escena_num != null and is_inside_tree() and get_parent() != null:
		var n = escena_num.instantiate()
		var pos_num = global_position + Vector3(randf_range(-0.4, 0.4), 2.8, randf_range(-0.4, 0.4))
		get_parent().add_child(n)
		n.global_position = pos_num
		n.iniciar(dano_final, es_critico or _aturdida, false)
		
	_actualizar_hud()
	if vida <= 0.0:
		morir()

func morir():
	if hud != null and hud.has_method("ocultar_barra_jefe"):
		hud.ocultar_barra_jefe()
		
	if _telegraph_lluvia != null and is_instance_valid(_telegraph_lluvia):
		_telegraph_lluvia.queue_free()
		
	AudioManager.play("enemigo_muerte", 0.7, 3.0)
	_sacudir_camara(0.4)
	
	var pj = get_tree().get_first_node_in_group("jugador")
	if pj != null:
		if pj.has_method("registrar_baja"):
			pj.registrar_baja()
		if pj.has_method("recoger_drop"):
			pj.recoger_drop(0, 60)
			pj.recoger_drop(1, 75)
			
	emit_signal("jefe_derrotado")
	queue_free()

func _actualizar_hud():
	if hud == null:
		return
	var titulo = "🏹 MAESTRA SANGUINARIA"
	if _aturdida:
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
