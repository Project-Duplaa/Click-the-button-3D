extends CharacterBody3D

const AudioManager = preload("res://audio_manager.gd")
const EvolucionManager = preload("res://evolucion_manager.gd")
const ArbolMejorasDatos = preload("res://arbol_mejoras_datos.gd")
const MetaprogresoManager = preload("res://metaprogreso_manager.gd")
const ArbolInterconectadoDatos = preload("res://arbol_interconectado_datos.gd")

enum Estado { QUIETO, CAMINAR, CORRER, AIRE }
const RUIDO = [0.0, 2.5, 6.5, 0.0]

signal stats_actualizadas(vida, max_vida, xp, xp_sig, nivel, oro, bajas)
signal nivel_subido(nuevo_nivel)
signal economia_actualizada(oro_actual, clics_disponibles, clics_totales)
signal mejora_arbol_comprada(id_mejora, nuevo_nivel)

@export var camara: Camera3D
@export var speed_caminar = 3.2
@export var speed_correr = 5.8
@export var tiempo_arranque = 0.20
@onready var anim = $Modelo/AnimationPlayer

# Estadísticas RPG / Autobattler (Novato débil al inicio para sensación incremental real)
var clase: String = "Novato"
var vida_maxima: float = 55.0
var vida: float = 55.0
var dano: float = 5.5
var rango_ataque: float = 2.0
var cadencia_ataque: float = 1.35
var oro: int = 0
var xp: int = 0
var xp_siguiente_nivel: int = 60
var nivel: int = 1
var bajas: int = 0

# Sistema Incremental: Monedas, Clics y Árbol de Ascensión
var clics_disponibles: int = 0
var clics_totales: int = 0
var mejoras_arbol: Dictionary = {}

# Estadísticas base puras según clase
var base_vida_maxima: float = 55.0
var base_dano: float = 5.5
var base_cadencia_ataque: float = 1.35
var base_rango_ataque: float = 2.0
var base_speed_caminar: float = 2.3
var base_speed_correr: float = 3.8

# Sistema de Vidas, Reapariciones y Derrota Definitiva
var vidas_base: int = 1
var bonus_vidas_arbol: int = 0
@export var reapariciones: int = 0 # 0 reapariciones = 1 vida base al inicio (modo roguelike hardcore incremental)
@export var invulnerable_tiempo: float = 2.0
@export var punto_reaparicion: Vector3 = Vector3(0, 0.5, 0)
var _reloj_invulnerable: float = 0.0
var _muerto_definitivo: bool = false
var _cooldown_ultimo_aliento: float = 0.0

# Estadísticas Incrementales del Árbol (55 Nodos en 5 Tiers)
var escudo_almas: float = 0.0
var max_escudo_almas: float = 0.0
var armadura_plana: float = 0.0
var mitigacion_pasiva_pct: float = 0.0
var bonus_dano_pct: float = 0.0
var bonus_dano_armas_pct: float = 0.0
var bonus_dano_clic_pct: float = 0.0
var clics_por_pulsacion: int = 1
var bonus_radio_aoe_clic: float = 0.0
var bonus_empuje_clic_pct: float = 0.0
var bonus_eco_clic_prob: float = 0.0
var bonus_critico_clic_prob: float = 0.0
var bonus_dano_critico_pct: float = 0.0
var bonus_velocidad_mov_pct: float = 0.0
var radio_iman_extra: float = 0.0
var regen_vida_seg: float = 0.0
var vida_por_baja: float = 0.0
var bonus_invulnerable_seg: float = 0.0
var reflejo_dano_pct: float = 0.0
var oro_por_baja_pct: float = 0.0
var xp_ganada_pct: float = 0.0
var bonus_cadencia_pct: float = 0.0
var autoclick_tasa: float = 0.0
var _autoclick_acumulador: float = 0.0
var proyectiles_extra: int = 0
var perforacion_armas: int = 0
var oro_pasivo_seg: float = 0.0
var _oro_pasivo_acum: float = 0.0
var interes_oleada_pct: float = 0.0
var clic_cura_escudo: float = 0.0
var xp_a_oro_pct: float = 0.0
var clic_genera_oro_pct: float = 0.0
var tempestad_oro_dmg: float = 0.0
var contador_cataclismo: int = 0

# Keystones Supremos
var keystone_cataclismo: bool = false
var keystone_soberania: bool = false
var keystone_segunda_vida: bool = false
var keystone_coloso: bool = false
var keystone_aliento: bool = false
var keystone_usura: bool = false
var keystone_fabrica: bool = false
var keystone_bucle: bool = false
var keystone_oro_liquido: bool = false
var keystone_zenit: bool = false
var ascension_suprema: bool = false

# Modificadores de compatibilidad legacy
var bonus_vida_max: float = 0.0
var bonus_velocidad_pct: float = 0.0
var bonus_oro_pct: float = 0.0
var prob_critico: float = 0.05
var mult_critico: float = 2.0
var contador_clics_sobrecarga: int = 0
var _reloj_incremental_pasivo: float = 0.0
var _clics_pasivos_frac: float = 0.0

var evolucion_manager: EvolucionManager = null

var _reloj_ataque: float = 0.0
var _reloj_anim_accion: float = 0.0

var multiplicador = 1.0
var empuje = Vector3.ZERO
var accion = ""
var avance = Vector3.ZERO

var estado = Estado.QUIETO
var ruido = 0.0

# Mecánicas de Combate de Guerrero (Tanque)
var bloqueando: bool = false
var reduccion_dano_bloqueo: float = 0.75
var velocidad_bloqueo_multiplicador: float = 0.50
var _escudo_visual: Node3D = null
var _preview_baston: Node3D = null
var _preview_espada: Node3D = null
var _preview_arco: Node3D = null

func obtener_vidas_maximas() -> int:
	return vidas_base + bonus_vidas_arbol

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
	_crear_escudo_visual()
	aplicar_clase("Novato")
	MetaprogresoManager.aplicar_a_personaje(self)
	reapariciones = max(0, obtener_vidas_maximas() - 1)
	vida = vida_maxima
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and clase == "Guerrero":
			_actualizar_estado_bloqueo(event.pressed)
	elif event is InputEventKey and clase == "Guerrero":
		if event.keycode == KEY_F or event.keycode == KEY_Q:
			_actualizar_estado_bloqueo(event.pressed)
func _physics_process(delta):
	if _muerto_definitivo:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	# Control de invulnerabilidad temporal (i-frames con parpadeo de modelo)
	if _reloj_invulnerable > 0.0:
		_reloj_invulnerable = maxf(_reloj_invulnerable - delta, 0.0)
		var modelo_nodo = get_node_or_null("Modelo")
		if modelo_nodo != null:
			modelo_nodo.visible = fmod(_reloj_invulnerable, 0.20) < 0.10
			if _reloj_invulnerable <= 0.0:
				modelo_nodo.visible = true

	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var entrada = Vector3(input_dir.x, 0.0, input_dir.y)

	var giro_cam = camara.global_rotation.y if camara != null else 0.0
	var direction = entrada.rotated(Vector3.UP, giro_cam).normalized()

	# Actualizar estado de bloqueo continuo (solo disponible para Guerrero)
	if clase == "Guerrero":
		var presiona_bloqueo = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) \
			or (InputMap.has_action("bloquear") and Input.is_action_pressed("bloquear")) \
			or Input.is_key_pressed(KEY_F) or Input.is_key_pressed(KEY_Q)
		_actualizar_estado_bloqueo(presiona_bloqueo)
	elif bloqueando:
		_actualizar_estado_bloqueo(false)

	var corre = Input.is_action_pressed("correr") and not bloqueando
	var speed = speed_correr if corre else speed_caminar
	if bloqueando:
		speed *= velocidad_bloqueo_multiplicador

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
	_procesar_incremental_pasivo(delta)
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

	var es_crit = randf() < prob_critico
	var dano_ataque_actual = dano * (mult_critico if es_crit else 1.0)
	var bonus_asc = mejoras_arbol.get("hib_ascension", 0) >= 1

	if clase == "Novato":
		# Corte melee con barrido en arco frontal (Cleave) y tajo luminoso visible
		accion = "attack-melee-right"
		_reloj_anim_accion = 0.30
		_ejecutar_animacion_procedural_ataque("melee")
		_crear_tajo_espada(dir, es_crit)
		AudioManager.play("corte_espada", randf_range(0.95, 1.15))
		
		var dano_melee = dano_ataque_actual
		var rango_cleave = rango_ataque + (0.5 if bonus_asc else 0.0)
		var enemigos = get_tree().get_nodes_in_group("enemigos")
		for e in enemigos:
			if is_instance_valid(e) and e is Node3D:
				var dist = global_position.distance_to(e.global_position)
				if dist <= rango_cleave:
					var hacia_e = (e.global_position - global_position).normalized()
					hacia_e.y = 0.0
					if dir.dot(hacia_e) > (0.20 if bonus_asc else 0.35): # Cono frontal de 120-150 grados
						if e.has_method("recibir_dano"):
							e.recibir_dano(dano_melee, es_crit)
						AudioManager.play("golpe_impacto", randf_range(0.95, 1.15))
	elif clase == "Guerrero":
		# CORTE GIRATORIO MELEE EN ÁREA 360° (Whirlwind)
		_ejecutar_corte_giratorio_guerrero(false, es_crit, dano_ataque_actual)
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
			orbe.iniciar(origen, dir, dano_ataque_actual, enemigo)
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
		if bonus_asc:
			cant_flechas += 1
			
		var perforaciones = (1 if nivel < 5 else 2) + (2 if bonus_asc else 0)
		var vel_flecha = 15.0
		var dano_flecha = dano_ataque_actual * 0.65 # Balance para que el multishot no triplique el daño total
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
	# El combate es 100% automático (Autobattler continuo por proximidad).
	# La única interacción de clic permitida en el juego es sobre el Botón Móvil 3D.
	pass

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
	if _reloj_invulnerable > 0.0 or _muerto_definitivo:
		return

	# 1. Mitigación Pasiva por Armadura Rúnica y Constitución (Fórmula asintótica PoE)
	var mitigacion_armadura = armadura_plana / (armadura_plana + 120.0)
	var mitigacion_total = clampf(mitigacion_pasiva_pct + mitigacion_armadura, 0.0, 0.75)
	cantidad *= (1.0 - mitigacion_total)

	# 2. Mitigación por Bloqueo Activo de Escudo (Mecánica Tanque del Guerrero)
	if bloqueando and clase == "Guerrero":
		var dano_mitigado = cantidad * (1.0 - reduccion_dano_bloqueo)
		var mitigado_total = cantidad - dano_mitigado
		AudioManager.play("escudo_bloqueo", randf_range(0.95, 1.05))
		
		# Feedback visual de escudo y etiqueta 3D
		_parpadear_escudo()
		_mostrar_feedback_bloqueo(mitigado_total, dano_mitigado)
		_repeler_enemigos_alrededor(2.8, 6.5)
		
		cantidad = dano_mitigado
		if cantidad <= 0.0:
			return

	# 3. Retribución de Espinas (Devuelve daño en cono frontal)
	if reflejo_dano_pct > 0.0:
		_repeler_enemigos_alrededor(3.5, 4.0)

	# 4. Absorción por Escudo de Almas (Aegis)
	if escudo_almas > 0.0:
		if escudo_almas >= cantidad:
			escudo_almas -= cantidad
			cantidad = 0.0
		else:
			cantidad -= escudo_almas
			escudo_almas = 0.0
		if cantidad <= 0.0:
			AudioManager.play("escudo_bloqueo", 1.25)
			emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
			return

	# 5. Keystones Supremos Preventivos de Muerte (Último Aliento y Armadura de Oro Líquido)
	if vida - cantidad <= 0.0:
		# Keystone: Armadura de Oro Líquido (Consume 150 oro en vez de vida)
		if keystone_oro_liquido and oro >= 150:
			oro -= 150
			vida = maxf(vida_maxima * 0.35, 1.0)
			_reloj_invulnerable = 2.0
			AudioManager.play("altar_activado", 1.25, 2.0)
			_spawn_texto_3d("🪙 ¡ORO LÍQUIDO ABSORBIÓ EL IMPACTO!", Color(1.0, 0.85, 0.2))
			emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
			emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)
			return
		# Keystone: Último Aliento (Sobrevive a 1 HP con 3.5s i-frames)
		if keystone_aliento and _cooldown_ultimo_aliento <= 0.0:
			vida = 1.0
			_reloj_invulnerable = 3.5
			_cooldown_ultimo_aliento = 90.0
			_repeler_enemigos_alrededor(10.0, 14.0)
			AudioManager.play("altar_activado", 1.4, 3.0)
			_spawn_texto_3d("🔥 ¡ÚLTIMO ALIENTO ACTIVADO! (3.5s Invulnerable)", Color(1.0, 0.45, 0.15))
			emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
			return

	vida = maxf(vida - cantidad, 0.0)
	AudioManager.play("danio_jugador", randf_range(0.9, 1.1))
	if is_inside_tree() and get_parent() != null:
		var escena = load("res://damage_number_3d.tscn")
		if escena != null:
			var num = escena.instantiate()
			var pos_num = global_position + Vector3(randf_range(-0.2, 0.2), 2.0, randf_range(-0.2, 0.2))
			get_parent().add_child(num)
			num.global_position = pos_num
			num.iniciar(cantidad, false, true)
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	if vida <= 0.0:
		_procesar_caida_jugador()

func recoger_drop(tipo: int, valor: int):
	match tipo:
		0: # ORO
			var bonus_mult = 1.0 + oro_por_baja_pct + (float(mejoras_arbol.get("mon_oro", 0)) * 0.25)
			if ascension_suprema:
				bonus_mult *= 2.0
			oro += int(ceil(valor * bonus_mult))
		1: # EXP
			var xp_final = int(ceil(valor * (1.0 + xp_ganada_pct)))
			xp += xp_final
			# Puente Verde-Dorada: Alquimia de Recolección (XP a Oro)
			if xp_a_oro_pct > 0.0:
				var oro_alquimia = max(1, int(ceil(xp_final * xp_a_oro_pct)))
				oro += oro_alquimia
		2: # CORAZON
			vida = minf(vida + valor, vida_maxima)
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)

func registrar_baja():
	bajas += 1
	AudioManager.play("enemigo_muerte", randf_range(0.9, 1.2))
	# Vampirismo: curación inmediata al abatir enemigo
	if vida_por_baja > 0.0 and vida < vida_maxima:
		vida = minf(vida + vida_por_baja, vida_maxima)
	recoger_drop(1, 6) # 6 XP por baja
	recoger_drop(0, 3) # 3 Oro base por baja
	if evolucion_manager != null and evolucion_manager.has_method("notificar_baja"):
		evolucion_manager.notificar_baja()

func subir_nivel():
	xp -= xp_siguiente_nivel
	nivel += 1
	xp_siguiente_nivel = int(xp_siguiente_nivel * 1.55)
	
	# Escalado de especialidades por clase al subir nivel
	if clase == "Cazador":
		base_cadencia_ataque = maxf(0.18, base_cadencia_ataque * 0.92) # Velocidad de disparo escalable
		base_dano *= 1.08
	elif clase == "Guerrero":
		base_dano *= 1.10
		base_rango_ataque = minf(3.6, base_rango_ataque + 0.05)
	elif clase == "Mago":
		base_dano *= 1.12
	else:
		base_dano *= 1.06
		
	recalcular_stats_incrementales()
	vida = minf(vida + 30.0, vida_maxima) # Cura parcial +30 HP
	
	emit_signal("nivel_subido", nivel)
	if evolucion_manager != null:
		evolucion_manager.notificar_nivel(nivel)
	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)

## Vista previa visual temporal mientras el jugador sobrevuela una clase en el menú radial
func mostrar_preview_clase(nombre_clase: String):
	_asegurar_armas_preview()
	
	if _preview_baston != null:
		_preview_baston.visible = (nombre_clase == "Mago")
	if _preview_espada != null:
		_preview_espada.visible = (nombre_clase == "Guerrero")
	if _preview_arco != null:
		_preview_arco.visible = (nombre_clase == "Cazador")
		
	if _escudo_visual != null:
		_escudo_visual.visible = (nombre_clase == "Guerrero" or (clase == "Guerrero" and nombre_clase == ""))

func _asegurar_armas_preview():
	if _preview_baston != null and is_instance_valid(_preview_baston):
		return
		
	# 1. Bastón de Mago con Orbe Cian Resplandeciente y Partículas (Réplica exacta de la referencia)
	_preview_baston = Node3D.new()
	_preview_baston.name = "PreviewBastonMago"
	
	# Palo del bastón
	var mesh_palo = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.025
	cyl.bottom_radius = 0.025
	cyl.height = 1.15
	mesh_palo.mesh = cyl
	var mat_palo = StandardMaterial3D.new()
	mat_palo.albedo_color = Color(0.38, 0.24, 0.16)
	mesh_palo.material_override = mat_palo
	_preview_baston.add_child(mesh_palo)
	
	# Orbe de cristal mágico cian
	var mesh_orbe = MeshInstance3D.new()
	var sph = SphereMesh.new()
	sph.radius = 0.09
	sph.height = 0.18
	mesh_orbe.mesh = sph
	mesh_orbe.position = Vector3(0, 0.58, 0)
	var mat_orbe = StandardMaterial3D.new()
	mat_orbe.albedo_color = Color(0.2, 0.85, 1.0)
	mat_orbe.emission_enabled = true
	mat_orbe.emission = Color(0.1, 0.9, 1.0)
	mat_orbe.emission_energy_multiplier = 3.8
	mesh_orbe.material_override = mat_orbe
	_preview_baston.add_child(mesh_orbe)
	
	# Luz y partículas mágicas del orbe
	var luz_orbe = OmniLight3D.new()
	luz_orbe.light_color = Color(0.25, 0.85, 1.0)
	luz_orbe.light_energy = 2.2
	luz_orbe.omni_range = 2.5
	luz_orbe.position = Vector3(0, 0.58, 0)
	_preview_baston.add_child(luz_orbe)
	
	var part_orbe = CPUParticles3D.new()
	part_orbe.emitting = true
	part_orbe.amount = 12
	part_orbe.lifetime = 0.7
	part_orbe.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	part_orbe.emission_sphere_radius = 0.12
	part_orbe.gravity = Vector3(0, 0.6, 0)
	part_orbe.color = Color(0.3, 0.9, 1.0, 0.9)
	part_orbe.position = Vector3(0, 0.58, 0)
	_preview_baston.add_child(part_orbe)
	
	# Posición del bastón sostenido en mano derecha
	_preview_baston.position = Vector3(0.48, 0.65, 0.22)
	_preview_baston.rotation_degrees = Vector3(8.0, 0.0, -14.0)
	_preview_baston.visible = false
	add_child(_preview_baston)
	
	# 2. Espada de Guerrero en mano derecha
	_preview_espada = Node3D.new()
	_preview_espada.name = "PreviewEspadaGuerrero"
	var mesh_espada = MeshInstance3D.new()
	var box_esp = BoxMesh.new()
	box_esp.size = Vector3(0.08, 0.85, 0.02)
	mesh_espada.mesh = box_esp
	var mat_esp = StandardMaterial3D.new()
	mat_esp.albedo_color = Color(0.85, 0.88, 0.95)
	mat_esp.metallic = 0.9
	mat_esp.roughness = 0.3
	mesh_espada.material_override = mat_esp
	_preview_espada.add_child(mesh_espada)
	_preview_espada.position = Vector3(0.45, 0.55, 0.15)
	_preview_espada.rotation_degrees = Vector3(-15.0, 0.0, 25.0)
	_preview_espada.visible = false
	add_child(_preview_espada)
	
	# 3. Arco de Cazador en mano izquierda
	_preview_arco = Node3D.new()
	_preview_arco.name = "PreviewArcoCazador"
	var mesh_arco = MeshInstance3D.new()
	var box_arco = BoxMesh.new()
	box_arco.size = Vector3(0.04, 0.95, 0.15)
	mesh_arco.mesh = box_arco
	var mat_arco = StandardMaterial3D.new()
	mat_arco.albedo_color = Color(0.65, 0.40, 0.22)
	mesh_arco.material_override = mat_arco
	_preview_arco.add_child(mesh_arco)
	_preview_arco.position = Vector3(-0.45, 0.60, 0.20)
	_preview_arco.rotation_degrees = Vector3(10.0, 0.0, 0.0)
	_preview_arco.visible = false
	add_child(_preview_arco)

func aplicar_clase(nombre: String):
	clase = nombre
	if clase != "Guerrero":
		if bloqueando:
			_actualizar_estado_bloqueo(false)
		if _escudo_visual != null:
			_escudo_visual.visible = false
	else:
		_crear_escudo_visual()
	match nombre:
		"Novato":
			base_vida_maxima = 55.0
			base_dano = 5.5
			base_rango_ataque = 2.0
			base_cadencia_ataque = 1.35
			base_speed_caminar = 2.3
			base_speed_correr = 3.8
		"Guerrero":
			base_vida_maxima = 160.0
			base_dano = 22.0
			base_rango_ataque = 3.2
			base_cadencia_ataque = 0.70
			base_speed_caminar = 3.2
			base_speed_correr = 5.6
		"Cazador":
			base_vida_maxima = 100.0
			base_dano = 14.0
			base_rango_ataque = 7.5
			base_cadencia_ataque = 0.45
			base_speed_caminar = 3.8
			base_speed_correr = 6.4
		"Mago":
			base_vida_maxima = 85.0
			base_dano = 28.0
			base_rango_ataque = 5.5
			base_cadencia_ataque = 0.90
			base_speed_caminar = 3.3
			base_speed_correr = 5.7
	vida = base_vida_maxima
	recalcular_stats_incrementales()

func aplicar_mejora(tipo_mejora: String):
	match tipo_mejora:
		"dano":
			base_dano *= 1.25
		"velocidad":
			base_speed_caminar *= 1.20
			base_speed_correr *= 1.20
		"vida":
			base_vida_maxima += 30.0
			vida = minf(vida + 30.0, vida_maxima + 30.0)
		"cadencia":
			base_cadencia_ataque = maxf(base_cadencia_ataque * 0.80, 0.18)
	recalcular_stats_incrementales()

# ==============================================================================
# SISTEMA INCREMENTAL: CÁLCULOS DEL ÁRBOL DE CONSTELACIONES EN 5 TIERS
# ==============================================================================

func recalcular_stats_incrementales():
	# 1. Reiniciar a estadísticas base de clase
	dano = base_dano
	cadencia_ataque = base_cadencia_ataque
	rango_ataque = base_rango_ataque
	speed_caminar = base_speed_caminar
	speed_correr = base_speed_correr
	prob_critico = 0.05
	mult_critico = 2.0

	# 2. Resetear acumuladores del Árbol de Constelaciones
	bonus_vidas_arbol = 0
	escudo_almas = 0.0
	max_escudo_almas = 0.0
	armadura_plana = 0.0
	mitigacion_pasiva_pct = 0.0
	bonus_dano_pct = 0.0
	bonus_dano_armas_pct = 0.0
	bonus_dano_clic_pct = 0.0
	clics_por_pulsacion = 1
	bonus_radio_aoe_clic = 0.0
	bonus_empuje_clic_pct = 0.0
	bonus_eco_clic_prob = 0.0
	bonus_critico_clic_prob = 0.0
	bonus_dano_critico_pct = 0.0
	bonus_velocidad_mov_pct = 0.0
	radio_iman_extra = 0.0
	regen_vida_seg = 0.0
	vida_por_baja = 0.0
	bonus_invulnerable_seg = 0.0
	reflejo_dano_pct = 0.0
	oro_por_baja_pct = 0.0
	xp_ganada_pct = 0.0
	bonus_cadencia_pct = 0.0
	autoclick_tasa = 0.0
	proyectiles_extra = 0
	perforacion_armas = 0
	oro_pasivo_seg = 0.0
	interes_oleada_pct = 0.0
	clic_cura_escudo = 0.0
	xp_a_oro_pct = 0.0
	clic_genera_oro_pct = 0.0
	tempestad_oro_dmg = 0.0

	# Keystones Supremos
	keystone_cataclismo = false
	keystone_soberania = false
	keystone_segunda_vida = false
	keystone_coloso = false
	keystone_aliento = false
	keystone_usura = false
	keystone_fabrica = false
	keystone_bucle = false
	keystone_oro_liquido = false
	keystone_zenit = false
	ascension_suprema = false

	var bonus_vida_plana: float = 0.0

	# 3. Mapeo genérico desde ArbolInterconectadoDatos
	var arbol_nodos = ArbolInterconectadoDatos.generar_arbol()
	for id in mejoras_arbol.keys():
		var lvl = int(mejoras_arbol[id])
		if lvl <= 0 or not arbol_nodos.has(id):
			continue
		var nodo: SkillNodeData = arbol_nodos[id]
		var val = nodo.valor_por_nivel * lvl

		match nodo.estadistica_afectada:
			"salud_maxima":
				bonus_vida_plana += val
			"mitigacion_dano_pct":
				mitigacion_pasiva_pct += (val * 0.01)
			"armadura_plana":
				armadura_plana += val
			"escudo_almas":
				max_escudo_almas += val
			"vidas_extra":
				bonus_vidas_arbol += int(val)
			"keystone_segunda_vida":
				bonus_vidas_arbol += 1
				keystone_segunda_vida = true
			"velocidad_mov_pct":
				bonus_velocidad_mov_pct += (val * 0.01)
			"radio_iman":
				radio_iman_extra += val
			"regen_vida_seg":
				regen_vida_seg += val
			"vida_por_baja":
				vida_por_baja += val
			"invulnerable_extra_seg":
				bonus_invulnerable_seg += val
			"reflejo_dano_pct":
				reflejo_dano_pct += (val * 0.01)
			"dano_clic_pct":
				bonus_dano_clic_pct += (val * 0.01)
			"clics_por_pulsacion":
				clics_por_pulsacion += int(val)
			"radio_aoe_clic":
				bonus_radio_aoe_clic += val
			"empuje_clic_pct":
				bonus_empuje_clic_pct += (val * 0.01)
			"critico_clic_prob":
				bonus_critico_clic_prob += (val * 0.01)
				prob_critico += (val * 0.01)
			"dano_critico_pct":
				bonus_dano_critico_pct += (val * 0.01)
				mult_critico += (val * 0.01)
			"eco_clic_prob":
				bonus_eco_clic_prob += (val * 0.01)
			"oro_por_baja_pct":
				oro_por_baja_pct += (val * 0.01)
			"xp_ganada_pct":
				xp_ganada_pct += (val * 0.01)
			"cadencia_armas_pct":
				bonus_cadencia_pct += (val * 0.01)
			"dano_armas_pct":
				bonus_dano_armas_pct += (val * 0.01)
			"autoclick_tasa":
				autoclick_tasa += val
			"autoclick_overclock_pct":
				autoclick_tasa *= (1.0 + (val * 0.01))
			"proyectiles_extra":
				proyectiles_extra += int(val)
			"perforacion_armas":
				perforacion_armas += int(val)
			"rango_ataque_pct":
				rango_ataque *= (1.0 + (val * 0.01))
			"oro_pasivo_seg":
				oro_pasivo_seg += val
			"interes_oleada_pct":
				interes_oleada_pct += (val * 0.01)
			"clic_cura_escudo":
				clic_cura_escudo += val
			"xp_a_oro_pct":
				xp_a_oro_pct += (val * 0.01)
			"clic_genera_oro_pct":
				clic_genera_oro_pct += (val * 0.01)
			"tempestad_oro_dmg":
				tempestad_oro_dmg += val
			"keystone_cataclismo":
				keystone_cataclismo = true
			"keystone_soberania":
				keystone_soberania = true
			"keystone_coloso":
				keystone_coloso = true
			"keystone_aliento":
				keystone_aliento = true
			"keystone_usura":
				keystone_usura = true
			"keystone_fabrica":
				keystone_fabrica = true
			"keystone_bucle":
				keystone_bucle = true
			"keystone_oro_liquido":
				keystone_oro_liquido = true
			"keystone_zenit":
				keystone_zenit = true
			"ascension_suprema":
				ascension_suprema = true

	# 4. Modificadores de compatibilidad legacy
	var lvl_dano_old = mejoras_arbol.get("mon_dano", 0)
	var lvl_vida_old = mejoras_arbol.get("mon_vida", 0)
	var lvl_vel_old = mejoras_arbol.get("mon_vel", 0)
	bonus_dano_pct += (lvl_dano_old * 0.18)
	bonus_vida_plana += (lvl_vida_old * 25.0)
	bonus_velocidad_mov_pct += (lvl_vel_old * 0.10)

	# 5. Aplicar efectos de Keystones especiales
	if keystone_coloso:
		armadura_plana += vida_maxima * 0.25
	if ascension_suprema:
		bonus_dano_pct += 1.0
		bonus_velocidad_mov_pct += 0.50

	# 6. Consolidar estadísticas
	dano = base_dano * (1.0 + bonus_dano_pct + bonus_dano_armas_pct)
	cadencia_ataque = maxf(0.12, base_cadencia_ataque * (1.0 - minf(bonus_cadencia_pct, 0.70)))
	speed_caminar = base_speed_caminar * (1.0 + bonus_velocidad_mov_pct)
	speed_correr = base_speed_correr * (1.0 + bonus_velocidad_mov_pct)

	var vida_anterior_max = vida_maxima
	vida_maxima = base_vida_maxima + bonus_vida_plana
	if vida_maxima > vida_anterior_max:
		vida = minf(vida + (vida_maxima - vida_anterior_max), vida_maxima)

	escudo_almas = max_escudo_almas

	# Ajustar reapariciones acordes a las vidas desbloqueadas
	if not _muerto_definitivo:
		reapariciones = max(reapariciones, obtener_vidas_maximas() - 1)

	# Sincronizar componente Salud si existe
	if has_node("Salud"):
		var s = get_node("Salud")
		s.vida = int(vida)
		s.vida_inicial = int(vida_maxima)
		s.reapariciones = reapariciones

	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)

func puede_comprar_mejora(id: String) -> bool:
	if ArbolInterconectadoDatos != null:
		var nodos = ArbolInterconectadoDatos.generar_arbol()
		if nodos.has(id):
			var n: SkillNodeData = nodos[id]
			return MetaprogresoManager.puede_comprar(n)
	return false

func comprar_mejora(id: String) -> bool:
	if ArbolInterconectadoDatos != null:
		var nodos = ArbolInterconectadoDatos.generar_arbol()
		if nodos.has(id):
			var n: SkillNodeData = nodos[id]
			var exito = MetaprogresoManager.comprar_nodo(n)
			if exito:
				recalcular_stats_incrementales()
				return true
	return false

func registrar_click_jugador(es_anomalia: bool = false):
	var clics_ganados = clics_por_pulsacion
	if es_anomalia:
		clics_ganados += 3
		
	# Eco de Clic (probabilidad de duplicar)
	if bonus_eco_clic_prob > 0.0 and randf() < bonus_eco_clic_prob:
		clics_ganados *= 2
		_spawn_texto_3d("🔁 ¡ECO DE CLIC!", Color(0.4, 0.8, 1.0))

	clics_disponibles += clics_ganados
	clics_totales += clics_ganados

	# Puente Azul-Verde: Clic cura escudo
	if clic_cura_escudo > 0.0:
		escudo_almas = minf(escudo_almas + clic_cura_escudo, max_escudo_almas + 60.0)

	# Puente Dorada-Azul: Clic genera oro
	if clic_genera_oro_pct > 0.0:
		var oro_alquimia = max(1, int(ceil(dano * clic_genera_oro_pct)))
		recoger_drop(0, oro_alquimia)

	# Sobrecarga de Tormenta
	if mejoras_arbol.has("clk_sobrecarga_1") or mejoras_arbol.has("clk_sobrecarga"):
		contador_clics_sobrecarga += 1
		if contador_clics_sobrecarga >= 6:
			contador_clics_sobrecarga = 0
			var mult_sob = float(mejoras_arbol.get("clk_sobrecarga_1", mejoras_arbol.get("clk_sobrecarga", 1)))
			_detonar_tormenta_arcana(80.0 * mult_sob)

	# Keystone: Cataclismo Cinético
	if keystone_cataclismo:
		contador_cataclismo += 1
		if contador_cataclismo >= 8:
			contador_cataclismo = 0
			_reloj_ataque = 0.0
			_repeler_enemigos_alrededor(16.0, 18.0)
			_spawn_texto_3d("⚡⚡ ¡CATACLISMO CINÉTICO!", Color(0.3, 0.85, 1.0))
			AudioManager.play("victoria", 1.25)

	if evolucion_manager != null:
		evolucion_manager.registrar_click()

	emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
	emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)

func obtener_radio_atraccion_extra() -> float:
	return radio_iman_extra + (float(mejoras_arbol.get("clk_iman", 0)) * 2.5)

func obtener_bonus_onda_clic() -> Dictionary:
	var r_mult = 1.0 + (bonus_radio_aoe_clic * 0.20) + (float(mejoras_arbol.get("clk_onda", 0)) * 0.30)
	var d_mult = 1.0 + bonus_dano_clic_pct + (float(mejoras_arbol.get("clk_dano_1", 0)) * 0.20)
	if keystone_soberania:
		d_mult += 2.0
	return {
		"radio_mult": r_mult,
		"dano_mult": d_mult
	}

func _procesar_incremental_pasivo(delta: float):
	if _cooldown_ultimo_aliento > 0.0:
		_cooldown_ultimo_aliento = maxf(0.0, _cooldown_ultimo_aliento - delta)

	# 1. Regeneración pasiva de vida
	if regen_vida_seg > 0.0 and vida < vida_maxima and not _muerto_definitivo:
		vida = minf(vida + (regen_vida_seg * delta), vida_maxima)

	# 2. Generación pasiva de oro
	if oro_pasivo_seg > 0.0:
		_oro_pasivo_acum += oro_pasivo_seg * delta
		if _oro_pasivo_acum >= 1.0:
			var g = int(_oro_pasivo_acum)
			_oro_pasivo_acum -= g
			oro += g

	# 3. Autoclicker interno
	if autoclick_tasa > 0.0:
		_autoclick_acumulador += autoclick_tasa * delta
		if _autoclick_acumulador >= 1.0:
			var clk_ent = int(_autoclick_acumulador)
			_autoclick_acumulador -= clk_ent
			clics_disponibles += clk_ent
			clics_totales += clk_ent
			if keystone_fabrica:
				var boton = get_tree().get_first_node_in_group("boton_movil")
				if boton != null and boton.has_method("_detonar_onda_choque"):
					boton._detonar_onda_choque()

	# 4. Contador de compatibilidad por segundo
	_reloj_incremental_pasivo += delta
	if _reloj_incremental_pasivo >= 1.0:
		_reloj_incremental_pasivo -= 1.0
		var lvl_minero = mejoras_arbol.get("mon_pasivo", 0)
		if lvl_minero > 0:
			oro += lvl_minero * 1
		emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
		emit_signal("economia_actualizada", oro, clics_disponibles, clics_totales)

func _spawn_texto_3d(texto: String, color: Color = Color.WHITE):
	if not is_inside_tree() or get_parent() == null:
		return
	var escena = load("res://damage_number_3d.tscn")
	if escena != null:
		var txt = escena.instantiate()
		var pos = global_position + Vector3(0, 2.4, 0)
		get_parent().add_child(txt)
		txt.global_position = pos
		if txt.has_method("iniciar"):
			txt.iniciar(0.0, false, false, texto)
			var label = txt.get_node_or_null("Label3D") as Label3D
			if label != null:
				label.modulate = color

func _detonar_tormenta_arcana(dano_descarga: float):
	AudioManager.play("orbe_explosion", 1.3)
	var tree = _obtener_tree()
	if tree == null:
		return
	var enemigos = tree.get_nodes_in_group("enemigos")
	for e in enemigos:
		if is_instance_valid(e) and e is Node3D:
			if global_position.distance_to(e.global_position) <= 24.0:
				if e.has_method("recibir_dano"):
					e.recibir_dano(dano_descarga, true)
	
	var escena = load("res://damage_number_3d.tscn")
	if escena != null and get_parent() != null:
		var num = escena.instantiate()
		get_parent().add_child(num)
		num.global_position = global_position + Vector3(0, 2.3, 0)
		num.iniciar(0, true, false, "🌩️ ¡SOBRECARGA DE TORMENTA!")

func _spawn_efecto_ascension():
	var escena = load("res://damage_number_3d.tscn")
	if escena != null and get_parent() != null:
		var num = escena.instantiate()
		get_parent().add_child(num)
		num.global_position = global_position + Vector3(0, 2.5, 0)
		num.iniciar(0, true, false, "👑 ¡ASCENSIÓN SUPREMA!")

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
	if anim == null:
		return
	if accion != "":
		anim.play(accion)
		return
	if bloqueando and clase == "Guerrero":
		var rapidez = Vector2(velocity.x, velocity.z).length()
		if rapidez < 0.2:
			anim.play("holding-both")
		else:
			anim.play("walk")
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

# ==============================================================================
# HABILIDADES Y MECÁNICAS EXCLUSIVAS DEL GUERRERO (TANQUE)
# ==============================================================================

func _actualizar_estado_bloqueo(activo: bool):
	if bloqueando == activo:
		return
	bloqueando = activo
	if _escudo_visual == null or not is_instance_valid(_escudo_visual):
		_crear_escudo_visual()
	if _escudo_visual != null:
		_escudo_visual.visible = bloqueando
	if bloqueando:
		AudioManager.play("escudo_bloqueo", 1.25, -2.0)

func _crear_escudo_visual():
	if _escudo_visual != null and is_instance_valid(_escudo_visual):
		return
	
	_escudo_visual = Node3D.new()
	_escudo_visual.name = "EscudoVisual"
	
	# Malla del escudo (barrera translúcida con brillo reactivo)
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.35, 1.15, 0.1)
	mesh_inst.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.2, 0.65, 1.0, 0.7) # Cyan místico
	mat.emission_enabled = true
	mat.emission = Color(0.25, 0.75, 1.0)
	mat.emission_energy_multiplier = 2.0
	mat.roughness = 0.2
	mesh_inst.material_override = mat
	
	# Borde dorado ornamental
	var borde = MeshInstance3D.new()
	var box_borde = BoxMesh.new()
	box_borde.size = Vector3(1.42, 1.22, 0.05)
	borde.mesh = box_borde
	var mat_borde = StandardMaterial3D.new()
	mat_borde.albedo_color = Color(1.0, 0.85, 0.25)
	mat_borde.metallic = 0.85
	mat_borde.roughness = 0.3
	borde.material_override = mat_borde
	
	_escudo_visual.add_child(mesh_inst)
	_escudo_visual.add_child(borde)
	_escudo_visual.position = Vector3(0, 0.9, -0.65)
	_escudo_visual.visible = false
	add_child(_escudo_visual)

func _parpadear_escudo():
	if _escudo_visual == null or not is_instance_valid(_escudo_visual):
		return
	var mesh_inst = _escudo_visual.get_child(0) as MeshInstance3D
	if mesh_inst != null and mesh_inst.material_override != null:
		var mat = mesh_inst.material_override as StandardMaterial3D
		var tw = create_tween()
		tw.tween_property(mat, "emission_energy_multiplier", 4.5, 0.06)
		tw.tween_property(mat, "emission_energy_multiplier", 2.0, 0.15)

func _obtener_tree() -> SceneTree:
	if is_inside_tree():
		return get_tree()
	return Engine.get_main_loop() as SceneTree

func _mostrar_feedback_bloqueo(mitigado: float, recibido: float):
	if not is_inside_tree() or get_parent() == null:
		return
	var escena = load("res://damage_number_3d.tscn")
	if escena != null:
		var num = escena.instantiate()
		var pos_num = global_position + Vector3(randf_range(-0.2, 0.2), 2.2, randf_range(-0.2, 0.2))
		get_parent().add_child(num)
		num.global_position = pos_num
		if num.has_method("iniciar"):
			num.iniciar(recibido, false, false, "🛡️ BLOQUEO (-%d)" % int(mitigado))
			var label = num.get_node_or_null("Label3D") as Label3D
			if label != null:
				label.modulate = Color(0.2, 0.8, 1.0) # Azul celeste defensivo

func _repeler_enemigos_alrededor(radio: float, fuerza: float):
	var tree = _obtener_tree()
	if tree == null:
		return
	var enemigos = tree.get_nodes_in_group("enemigos")
	for e in enemigos:
		if is_instance_valid(e) and e is Node3D:
			var dist = global_position.distance_to(e.global_position)
			if dist <= radio:
				var dir = (e.global_position - global_position).normalized()
				dir.y = 0.0
				if "velocity" in e:
					e.velocity += dir * fuerza

func _ejecutar_corte_giratorio_guerrero(es_click: bool = false, es_crit: bool = false, dano_custom: float = -1.0):
	accion = "attack-melee-right"
	_reloj_anim_accion = 0.32
	
	# Sonido de corte giratorio
	AudioManager.play("corte_giratorio", randf_range(0.95, 1.15))
	
	# Giro 360° visual del modelo
	var modelo_nodo = get_node_or_null("Modelo")
	if modelo_nodo != null:
		var tw = create_tween()
		tw.tween_property(modelo_nodo, "rotation:y", modelo_nodo.rotation.y + TAU, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Efecto visual de onda / disco cortante en 360°
	_crear_efecto_disco_cortante(rango_ataque)
	
	# Daño en área 360° a TODOS los enemigos dentro del alcance
	var tree = _obtener_tree()
	if tree == null:
		return
	var enemigos = tree.get_nodes_in_group("enemigos")
	var dano_base_calc = dano if dano_custom <= 0.0 else dano_custom
	var dano_aplicar = dano_base_calc * (1.25 if es_click else 1.0)
	var golpeados = 0
	
	for e in enemigos:
		if is_instance_valid(e) and e is Node3D:
			var dist = global_position.distance_to(e.global_position)
			if dist <= rango_ataque + 0.6:
				golpeados += 1
				if e.has_method("recibir_dano"):
					e.recibir_dano(dano_aplicar, es_crit or es_click)
				
				# Knockback / Empuje radial hacia afuera
				var dir_empuje = (e.global_position - global_position).normalized()
				dir_empuje.y = 0.0
				if "velocity" in e:
					e.velocity += dir_empuje * (8.5 if es_click else 6.0)
	
	if golpeados > 0:
		print("[Guerrero] ¡Corte Giratorio 360° impactó a %d enemigos! (Daño: %.1f)" % [golpeados, dano_aplicar])

func _crear_efecto_disco_cortante(radio: float):
	if not is_inside_tree() or get_parent() == null:
		return
	
	var mesh_inst = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = maxf(radio * 0.75, 0.5)
	torus.outer_radius = radio * 1.05
	torus.rings = 24
	torus.ring_segments = 12
	mesh_inst.mesh = torus
	
	var mat = StandardMaterial3D.new()
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.75, 0.2, 0.85) # Oro anaranjado de corte
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.65, 0.1)
	mat.emission_energy_multiplier = 3.2
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	
	get_parent().add_child(mesh_inst)
	mesh_inst.global_position = global_position + Vector3(0, 0.85, 0)
	mesh_inst.scale = Vector3(0.2, 0.2, 0.2)
	
	var tw = mesh_inst.create_tween().set_parallel(true)
	tw.tween_property(mesh_inst, "scale", Vector3(1.15, 1.0, 1.15), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.25)
	tw.chain().tween_callback(mesh_inst.queue_free)

# ==============================================================================
# SISTEMA DE VIDAS, REAPARICIÓN CON I-FRAMES Y DERROTA DEFINITIVA
# ==============================================================================

func _procesar_caida_jugador():
	if _muerto_definitivo:
		return
		
	if reapariciones > 0:
		reapariciones -= 1
		vida = vida_maxima
		escudo_almas = max_escudo_almas
		global_position = punto_reaparicion
		velocity = Vector3.ZERO
		avance = Vector3.ZERO
		empuje = Vector3.ZERO
		_reloj_invulnerable = invulnerable_tiempo + bonus_invulnerable_seg
		
		# Keystone: Segunda Oportunidad Sagrada (Nova masiva de repulsión y purga)
		if keystone_segunda_vida:
			_repeler_enemigos_alrededor(16.0, 18.0)
			AudioManager.play("victoria", 1.25)
			_spawn_texto_3d("✝️ ¡NOVA SAGRADA DE SEGUNDA OPORTUNIDAD!", Color(1.0, 0.9, 0.3))
		else:
			AudioManager.play("danio_jugador", 0.65, 3.0)
			_crear_feedback_reaparicion()
		
		# Sincronizar nodo Salud secundario
		if has_node("Salud"):
			var s = get_node("Salud")
			s.vida = int(vida)
			s.reapariciones = reapariciones
			s.cambio.emit(s.vida)
			
		emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
		print("⚡ [Personaje] ¡Caíste en combate! Reapareciendo en el centro. Reapariciones restantes: %d (Vidas: %d / %d)" % [reapariciones, reapariciones + 1, obtener_vidas_maximas()])
	else:
		_muerto_definitivo = true
		vida = 0.0
		emit_signal("stats_actualizadas", vida, vida_maxima, xp, xp_siguiente_nivel, nivel, oro, bajas)
		if obtener_vidas_maximas() == 1:
			print("💀 [Personaje] ¡Caíste en combate (1 vida)! Fin de la partida por derrota definitiva...")
		else:
			print("💀 [Personaje] ¡Agotaste tus %d vidas! Fin de la partida por derrota definitiva..." % obtener_vidas_maximas())
		
		if has_node("Salud"):
			var s = get_node("Salud")
			s.vida = 0
			s.reapariciones = 0
			s.sin_vida.emit()
			
		var tree = _obtener_tree()
		if tree != null:
			var partida = tree.get_first_node_in_group("partida")
			if partida != null and partida.has_method("perder"):
				if obtener_vidas_maximas() == 1:
					partida.perder("Caíste en combate (1 vida)")
				else:
					partida.perder("Agotaste tus %d vidas en combate" % obtener_vidas_maximas())

func _crear_feedback_reaparicion():
	if not is_inside_tree() or get_parent() == null:
		return
	
	# Texto flotante 3D de aviso
	var escena = load("res://damage_number_3d.tscn")
	if escena != null:
		var txt = escena.instantiate()
		var pos = global_position + Vector3(0, 2.4, 0)
		get_parent().add_child(txt)
		txt.global_position = pos
		if txt.has_method("iniciar"):
			txt.iniciar(0.0, false, false, "✨ ¡REAPARICIÓN! (%d Vidas)" % (reapariciones + 1))
			var label = txt.get_node_or_null("Label3D") as Label3D
			if label != null:
				label.modulate = Color(1.0, 0.9, 0.2)
	
	# Onda de choque de repulsión que despeja el centro
	_repeler_enemigos_alrededor(7.0, 10.0)
	
	# Pulso de luz temporal
	var luz = OmniLight3D.new()
	luz.light_color = Color(0.4, 0.85, 1.0)
	luz.light_energy = 4.0
	luz.omni_range = 10.0
	add_child(luz)
	luz.position = Vector3(0, 1.2, 0)
	var tw = create_tween()
	if tw != null:
		tw.tween_property(luz, "light_energy", 0.0, 0.8)
		tw.tween_callback(luz.queue_free)
	else:
		luz.queue_free()
