extends CharacterBody3D

# Jefe 1: Centurión Corrupto (Oleada 3 / Minuto 3)
# Comandante de la guardia caída. 420 HP.
# Dificultad 1 (Tutorial de interacción con el botón):
# Mecánica: Canaliza "Sentencia de Muerte" (golpe letal) que se interrumpe con 1 solo clic en el Botón Móvil para desarmarlo y aturdirlo.

signal jefe_derrotado

const AudioManager = preload("res://audio_manager.gd")

@export var rapidez: float = 3.2
@export var vida_maxima: float = 420.0
@export var dano_golpe: float = 24.0
@export var dano_sentencia: float = 52.0
@export var rango_ataque: float = 3.0
@export var tiempo_telegraph: float = 0.70

var vida: float = 420.0
var jugador: Node3D = null
var hud: Node = null
var _boton_movil: Node = null

var _reloj_ataque: float = 0.0
var _reloj_grito: float = 7.0
var _reloj_sentencia: float = 11.0
var _esta_telegrafando: bool = false
var _canalizando_sentencia: bool = false
var _grito_activo: bool = false
var _aturdido: bool = false

@onready var telegraph_mesh: MeshInstance3D = $TelegraphSuelo
@onready var luz_aura: OmniLight3D = $LuzCenturion

func _ready():
	add_to_group("enemigos")
	add_to_group("jefes")
	vida = vida_maxima
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
		
	if _aturdido or _esta_telegrafando or _canalizando_sentencia:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
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
			
		# MECÁNICA DEL BOTÓN: Canalización de Sentencia de Muerte (Interrumpible con 1 Clic)
		if _reloj_sentencia <= 0.001 and dist <= 10.0:
			_iniciar_sentencia_de_muerte()
			return
			
		# Habilidad: Grito de Guerra
		if _reloj_grito <= 0.001 and dist <= 12.0:
			_ejecutar_grito_guerra()
			
		var vel_actual = rapidez * (1.35 if _grito_activo else 1.0)
		
		if dist <= rango_ataque and _reloj_ataque <= 0.001:
			_iniciar_ataque_telegrafiado()
		else:
			var dir_mov = dir.normalized()
			velocity.x = dir_mov.x * vel_actual
			velocity.z = dir_mov.z * vel_actual
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		
	move_and_slide()

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
	if not _canalizando_sentencia:
		return # Fue interrumpido por el clic en el botón móvil
		
	_canalizando_sentencia = false
	if telegraph_mesh != null:
		telegraph_mesh.visible = false
		
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
		
	# Rayo visual de impacto rúnico hacia el centurión
	var pos_origen = global_position
	if is_instance_valid(_boton_movil):
		pos_origen = _boton_movil.global_position
	_crear_rayo_hacia_jefe(pos_origen)
	
	# CASO 1: Interrupción activa de Sentencia de Muerte con 1 clic
	if _canalizando_sentencia:
		_canalizando_sentencia = false
		_aturdido = true
		if telegraph_mesh != null:
			telegraph_mesh.visible = false
			
		AudioManager.play("puzzle_completo", 1.2)
		_sacudir_camara(0.3)
		_crear_texto_flotante("💥 ¡DESARMADO POR EL NÚCLEO! (Aturdido)", true)
		
		# Empujón y aturdimiento durante 2.5s
		velocity = -global_transform.basis.z * 5.0
		if hud != null and hud.has_method("actualizar_barra_jefe"):
			hud.actualizar_barra_jefe(vida, "⚔️ CENTURIÓN [💥 ¡DESARMADO Y ATURDIDO!]")
			
		get_tree().create_timer(2.5).timeout.connect(func():
			_aturdido = false
			_actualizar_hud()
		)
		return
		
	# CASO 2: Clic regular -> Empujón defensivo al Centurión para ayudar al jugador
	if is_instance_valid(jugador):
		var dir_empuje = (global_position - jugador.global_position).normalized()
		velocity += dir_empuje * 5.5
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
	_esta_telegrafando = false
	_reloj_ataque = 1.3
	
	AudioManager.play("corte_giratorio", 1.1)
	
	if is_instance_valid(jugador) and jugador is Node3D:
		var dist = global_position.distance_to(jugador.global_position)
		if dist <= rango_ataque + 0.8:
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(dano_golpe)
			elif jugador.has_node("Salud"):
				jugador.get_node("Salud").recibir_golpe(int(dano_golpe))
			_sacudir_camara(0.3)

func recibir_dano(cantidad: float, es_critico: bool = false):
	# Si está aturdido tras ser desarmado por el botón móvil, recibe +30% de daño
	var dano_final = cantidad * (1.30 if _aturdido else 1.0)
	vida = maxf(vida - dano_final, 0.0)
	
	var escena_num = load("res://damage_number_3d.tscn")
	if escena_num != null and is_inside_tree() and get_parent() != null:
		var n = escena_num.instantiate()
		var pos_num = global_position + Vector3(randf_range(-0.4, 0.4), 2.8, randf_range(-0.4, 0.4))
		get_parent().add_child(n)
		n.global_position = pos_num
		n.iniciar(dano_final, es_critico or _aturdido, false)
		
	_actualizar_hud()
	if vida <= 0.0:
		morir()

func morir():
	if hud != null and hud.has_method("ocultar_barra_jefe"):
		hud.ocultar_barra_jefe()
		
	AudioManager.play("enemigo_muerte", 0.8, 2.5)
	_sacudir_camara(0.35)
	
	var pj = get_tree().get_first_node_in_group("jugador")
	if pj != null:
		if pj.has_method("registrar_baja"):
			pj.registrar_baja()
		if pj.has_method("recoger_drop"):
			pj.recoger_drop(0, 25)
			pj.recoger_drop(1, 30)
			
	emit_signal("jefe_derrotado")
	queue_free()

func _actualizar_hud():
	if hud != null and hud.has_method("actualizar_barra_jefe"):
		hud.actualizar_barra_jefe(vida, "⚔️ CENTURIÓN CORRUPTO")

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
