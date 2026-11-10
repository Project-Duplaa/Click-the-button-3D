extends CharacterBody3D

const AudioManager = preload("res://audio_manager.gd")
const EvolucionManager = preload("res://evolucion_manager.gd")

enum Estado { QUIETO, CAMINAR, CORRER, AIRE }
const RUIDO = [0.0, 2.5, 6.5, 0.0]

signal stats_actualizadas(vida, max_vida, xp, xp_sig, nivel, oro, bajas)
signal nivel_subido(nuevo_nivel)

@export var camara: Camera3D
@export var speed_caminar = 3.2
@export var speed_correr = 5.8
@export var tiempo_arranque = 0.20
@onready var anim = $Modelo/AnimationPlayer

# Estadísticas RPG / Autobattler
var clase: String = "Novato"
var vida_maxima: float = 100.0
var vida: float = 100.0
var dano: float = 12.0
var rango_ataque: float = 2.8
var cadencia_ataque: float = 0.80
var oro: int = 0
var xp: int = 0
var xp_siguiente_nivel: int = 60
var nivel: int = 1
var bajas: int = 0

var evolucion_manager: EvolucionManager = null

var _reloj_ataque: float = 0.0
var _reloj_anim_accion: float = 0.0

var multiplicador = 1.0
var empuje = Vector3.ZERO
var accion = ""
var avance = Vector3.ZERO

var estado = Estado.QUIETO
var ruido = 0.0

func _ready():
	add_to_group("jugador")
	if camara == null and get_viewport() != null:
		camara = get_viewport().get_camera_3d()
	
	if anim == null and has_node("Modelo/AnimationPlayer"):
		anim = $Modelo/AnimationPlayer
	
	if has_node("EvolucionManager"):
		evolucion_manager = $EvolucionManager
	else:
		evolucion_manager = EvolucionManager.new()
		evolucion_manager.name = "EvolucionManager"
		add_child(evolucion_manager)
	
	evolucion_manager.configurar_con_personaje(self)
	aplicar_clase("Novato")
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var entrada = Vector3(input_dir.x, 0.0, input_dir.y)

	var giro_cam = camara.global_rotation.y if camara != null else 0.0
	var direction = entrada.rotated(Vector3.UP, giro_cam).normalized()

	var corre = Input.is_action_pressed("correr")
	var speed = speed_correr if corre else speed_caminar

	var objetivo = direction * speed * multiplicador
	var paso = speed / tiempo_arranque * delta
	avance = avance.move_toward(objetivo, paso)

	velocity.x = avance.x + empuje.x
	velocity.z = avance.z + empuje.z

	if direction.length() > 0:
		basis = Basis.looking_at(direction)

	move_and_slide()

	var antes = estado
	estado = elegir_estado()
	ruido = RUIDO[estado]
	if estado != antes and prueba != 0:
		print("estado ", Estado.keys()[estado], " · ruido ", ruido, " m")
		
	# Manejo de animación de ataque / acción
	if _reloj_anim_accion > 0.0:
		_reloj_anim_accion -= delta
		if _reloj_anim_accion <= 0.0:
			accion = ""
			
	animar()
	_procesar_autobattler(delta)
	_prueba()

func _procesar_autobattler(delta: float):
	_reloj_ataque = maxf(_reloj_ataque - delta, 0.0)
	if _reloj_ataque <= 0.001:
		var objetivo = _obtener_enemigo_cercano()
		if objetivo != null:
			var d = global_position.distance_to(objetivo.global_position)
			if d <= rango_ataque:
				_ejecutar_ataque(objetivo)
				_reloj_ataque = cadencia_ataque

func _obtener_enemigo_cercano() -> Node3D:
	if not is_inside_tree() or get_tree() == null:
		return null
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	var mas_cercano: Node3D = null
	var menor_dist = 9999.0
	for e in enemigos:
		if is_instance_valid(e) and e is Node3D:
			var dist = global_position.distance_to(e.global_position)
			if dist < menor_dist:
				menor_dist = dist
				mas_cercano = e
	return mas_cercano

func _ejecutar_ataque(enemigo: Node3D):
	var dir = (enemigo.global_position - global_position).normalized()
	dir.y = 0.0
	if dir.length() > 0.01:
		basis = Basis.looking_at(dir)

	if clase == "Novato" or clase == "Guerrero":
		# Corte melee con barrido en arco frontal (Cleave) y tajo luminoso visible
		accion = "attack-melee-right"
		_reloj_anim_accion = 0.30
		_ejecutar_animacion_procedural_ataque("melee")
		_crear_tajo_espada(dir, false)
		AudioManager.play("corte_espada", randf_range(0.95, 1.15))
		
		var dano_melee = dano
		var rango_cleave = rango_ataque + (0.6 if clase == "Guerrero" else 0.0)
		var enemigos = get_tree().get_nodes_in_group("enemigos")
		for e in enemigos:
			if is_instance_valid(e) and e is Node3D:
				var dist = global_position.distance_to(e.global_position)
				if dist <= rango_cleave:
					var hacia_e = (e.global_position - global_position).normalized()
					hacia_e.y = 0.0
					if dir.dot(hacia_e) > 0.35: # Cono frontal de 120 grados
						if e.has_method("recibir_dano"):
							e.recibir_dano(dano_melee)
						AudioManager.play("golpe_impacto", randf_range(0.95, 1.15))
						
	elif clase == "Mago":
		# Especialidad Mago: Orbe Arcano teledirigido con detonación en área AOE
		accion = "attack-melee-right"
		_reloj_anim_accion = 0.28
		_ejecutar_animacion_procedural_ataque("mago")
		var orbe_escena = load("res://orbe_arcano.tscn")
		if orbe_escena != null:
			var orbe = orbe_escena.instantiate()
			var origen = global_position + Vector3(0, 0.9, 0)
			get_parent().add_child(orbe)
			orbe.iniciar(origen, dir, dano, enemigo)
	else:
		# Especialidad Cazador: Disparo múltiple de flechas (Multishot) en abanico
		accion = "attack-melee-right"
		_reloj_anim_accion = 0.22
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
			
		var perforaciones = 1 if nivel < 5 else 2
		var vel_flecha = 15.0
		var dano_flecha = dano * 0.65 # Balance para que el multishot no triplique el daño total
		var origen = global_position + Vector3(0, 0.9, 0)
		var proyectil_escena = load("res://proyectil.tscn")
		
		if proyectil_escena != null:
			var angulo_inicio = -((cant_flechas - 1) * angulo_paso) * 0.5
			for i in range(cant_flechas):
				var angulo = angulo_inicio + (i * angulo_paso)
				var dir_flecha = dir.rotated(Vector3.UP, deg_to_rad(angulo)).normalized()
				var p = proyectil_escena.instantiate()
				get_parent().add_child(p)
				p.iniciar(origen, dir_flecha, dano_flecha, vel_flecha, perforaciones)

func click_attack():
	# Click manual tipo clicker con tajo crítico dorado y sonido contundente
	var dir_click = -basis.z
	var objetivo = _obtener_enemigo_cercano()
	if objetivo != null:
		var d = (objetivo.global_position - global_position)
		d.y = 0.0
		if d.length_squared() > 0.01:
			dir_click = d.normalized()
			basis = Basis.looking_at(dir_click)
			
	accion = "attack-melee-right"
	_reloj_anim_accion = 0.20
	_ejecutar_animacion_procedural_ataque("melee")
	_crear_tajo_espada(dir_click, true) # Tajo dorado de crítico
	AudioManager.play("corte_espada", 1.25)
	AudioManager.play("click", 1.15)
	
	if objetivo != null and global_position.distance_to(objetivo.global_position) <= rango_ataque + 2.5:
		if objetivo.has_method("recibir_dano"):
			objetivo.recibir_dano(dano * 0.85, true)
			AudioManager.play("golpe_impacto", 1.2)
			
	# Bono incremental de click
	oro += 1
	recoger_drop(0, 1) # +1 XP por click
	if evolucion_manager != null:
		evolucion_manager.registrar_click()

func _ejecutar_animacion_procedural_ataque(tipo_ataque: String):
	var mod = get_node_or_null("Modelo")
	if mod == null:
		return
	var tw = create_tween()
	match tipo_ataque:
		"melee":
			# Embestida / estocada física hacia adelante y retorno elástico
			tw.tween_property(mod, "position:z", 0.40, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(mod, "position:z", 0.0, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"arco":
			# Tensión hacia atrás y latigazo hacia adelante
			tw.tween_property(mod, "position:z", -0.18, 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(mod, "position:z", 0.25, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(mod, "position:z", 0.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"mago":
			# Elevación de levitación mística
			tw.tween_property(mod, "position:y", 0.35, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(mod, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _crear_tajo_espada(dir_ataque: Vector3, es_critico: bool = false):
	if not is_inside_tree() or get_parent() == null:
		return
	var tajo = Node3D.new()
	get_parent().add_child(tajo)
	var altura = global_position.y + 0.9
	tajo.global_position = Vector3(global_position.x, altura, global_position.z) + dir_ataque * 1.0
	
	if dir_ataque.length_squared() > 0.001 and absf(dir_ataque.dot(Vector3.UP)) < 0.999:
		tajo.look_at(tajo.global_position + dir_ataque, Vector3.UP)
		
	var mesh_inst = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.45
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var color_base = Color(1.0, 0.88, 0.25, 0.95) if es_critico else (Color(1.0, 0.55, 0.15, 0.95) if clase == "Guerrero" else Color(0.35, 0.85, 1.0, 0.95))
	mat.albedo_color = color_base
	torus.material = mat
	mesh_inst.mesh = torus
	
	mesh_inst.scale = Vector3(1.4, 0.05, 0.8)
	mesh_inst.position = Vector3(0, 0, -0.3)
	tajo.add_child(mesh_inst)
	
	var luz = OmniLight3D.new()
	luz.light_color = color_base
	luz.light_energy = 2.6
	luz.omni_range = 3.6
	tajo.add_child(luz)
	
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(mesh_inst, "scale", Vector3(2.6, 0.03, 1.7), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mesh_inst, "position:z", -1.2, 0.16)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.16)
	tw.tween_property(luz, "light_energy", 0.0, 0.16)
	tw.chain().tween_callback(tajo.queue_free)

func recibir_dano(cantidad: float):
	vida = maxf(vida - cantidad, 0.0)
	AudioManager.play("danio_jugador", randf_range(0.9, 1.1))
	var escena = load("res://damage_number_3d.tscn")
	if escena != null:
		var num = escena.instantiate()
		var pos_num = global_position + Vector3(randf_range(-0.2, 0.2), 2.0, randf_range(-0.2, 0.2))
		get_parent().add_child(num)
		num.global_position = pos_num
		num.iniciar(cantidad, false, true)
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	if vida <= 0.0:
		if has_node("Salud"):
			var nodo_salud = get_node("Salud")
			if nodo_salud.has_method("recibir_golpe"):
				nodo_salud.recibir_golpe(9999)
		else:
			print("¡Jugador caído! Reiniciando salud...")
			vida = vida_maxima

func recoger_drop(tipo: int, valor: int):
	match tipo:
		0: # ORO
			oro += valor
		1: # EXP
			xp += valor
			if xp >= xp_siguiente_nivel:
				subir_nivel()
		2: # CORAZON
			vida = minf(vida + valor, vida_maxima)
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

func registrar_baja():
	bajas += 1
	AudioManager.play("enemigo_muerte", randf_range(0.9, 1.2))
	recoger_drop(1, 6) # 6 XP por baja
	recoger_drop(0, 3) # 3 Oro por baja

func subir_nivel():
	xp -= xp_siguiente_nivel
	nivel += 1
	xp_siguiente_nivel = int(xp_siguiente_nivel * 1.55)
	vida = minf(vida + 30.0, vida_maxima) # Cura parcial +30 HP para mayor tension de supervivencia
	
	# Escalado de especialidades por clase al subir nivel
	if clase == "Cazador":
		cadencia_ataque = maxf(0.18, cadencia_ataque * 0.92) # Velocidad de disparo escalable
		dano *= 1.08
	elif clase == "Guerrero":
		dano *= 1.10
		rango_ataque = minf(3.6, rango_ataque + 0.05)
	elif clase == "Mago":
		dano *= 1.12
		
	emit_signal("nivel_subido", nivel)
	if evolucion_manager != null:
		evolucion_manager.notificar_nivel(nivel)
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

func aplicar_clase(nombre: String):
	clase = nombre
	match nombre:
		"Novato":
			vida_maxima = 100.0
			vida = 100.0
			dano = 12.0
			rango_ataque = 2.8
			cadencia_ataque = 0.80
			speed_caminar = 3.2
			speed_correr = 5.5
		"Guerrero":
			vida_maxima = 160.0
			vida = 160.0
			dano = 22.0
			rango_ataque = 3.0
			cadencia_ataque = 0.70
			speed_caminar = 3.2
			speed_correr = 5.6
		"Cazador":
			vida_maxima = 100.0
			vida = 100.0
			dano = 14.0
			rango_ataque = 7.5
			cadencia_ataque = 0.45
			speed_caminar = 3.8
			speed_correr = 6.4
		"Mago":
			vida_maxima = 85.0
			vida = 85.0
			dano = 28.0
			rango_ataque = 5.5
			cadencia_ataque = 0.90
			speed_caminar = 3.3
			speed_correr = 5.7
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

func aplicar_mejora(tipo_mejora: String):
	match tipo_mejora:
		"dano":
			dano *= 1.25
		"velocidad":
			speed_caminar *= 1.20
			speed_correr *= 1.20
		"vida":
			vida_maxima += 30.0
			vida = minf(vida + 30.0, vida_maxima)
		"cadencia":
			cadencia_ataque = maxf(cadencia_ataque * 0.80, 0.2)
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

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
	if accion != "":
		anim.play(accion)
		return
	match estado:
		Estado.QUIETO: anim.play("idle")
		Estado.CAMINAR: anim.play("walk")
		Estado.CORRER: anim.play("sprint")
		Estado.AIRE: anim.play("fall")

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
				print("[prueba] pos: ", global_position.snappedf(0.01), " · vel: ", snappedf(r, 0.01), " · anim: ", anim.current_animation)
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
				print("cuadro ", _cuadro, ": ", snappedf(r, 0.01), " · anim: ", anim.current_animation)
			elif _cuadro == 60:
				Input.action_release("move_up")
				if InputMap.has_action(accion_prueba): Input.action_release(accion_prueba)
				_termino = true
