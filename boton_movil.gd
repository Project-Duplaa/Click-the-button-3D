extends Area3D
class_name BotonMovil

## BotonMovil (Dron de Núcleo Rúnico) - Clicklike 3D
## Mecánica Dinámica de Alto Nivel:
## 1. Movimiento orbital fluido sin colisión con el bio-contenedor central.
## 2. Sistema de Bloqueo por Cadenas: cada 20 clics, el dron se bloquea e invoca 3 palancas
##    industriales en la arena con balizas de luz.
## 3. Modo Frenesí de Sobrecarga (12s): al activar las 3 palancas, desata una supernova que
##    repele enemigos y multiplica x3 todas las recompensas de clics y oro.

const AudioManager = preload("res://audio_manager.gd")
const PalancaEscena = preload("res://palanca_boton.tscn")

enum EstadoBoton { ACTIVO, ENCADENADO, SOBRECARGA_FRENESI }

signal click_presionado(total_clicks: int)
signal estado_cambiado(nuevo_estado: EstadoBoton)
signal estabilidad_actualizada(actual: float, maximo: float, en_colapso: bool)

# Parámetros de Movimiento y Vuelo
@export var rapidez_base: float = 2.4
@export var rapidez_maxima: float = 9.5
@export var radio_onda_choque: float = 6.0
@export var empuje_onda: float = 8.5
@export var clics_para_bloqueo: int = 20

# Variables de estabilidad compatibles con HUD
var tiempo_estabilidad_actual: float = 14.0
var tiempo_estabilidad_max: float = 14.0
var en_colapso: bool = false

# Ruta perimetral con punto central de partida
var ruta: Array[Vector3] = [
	Vector3(0.0, 1.25, 0.0),     # 0: Altar Central (Punto de inicio)
	Vector3(13.0, 1.25, 8.5),    # 1: Sureste
	Vector3(15.0, 1.25, -9.0),   # 2: Noreste
	Vector3(0.0, 1.25, -15.5),   # 3: Norte
	Vector3(-15.0, 1.25, -9.0),  # 4: Noroeste
	Vector3(-13.0, 1.25, 8.5),   # 5: Suroeste
	Vector3(0.0, 1.25, 14.0)     # 6: Sur
]

var estado_actual: EstadoBoton = EstadoBoton.ACTIVO
var indice_ruta: int = 0
var total_clicks: int = 0
var rapidez_movimiento: float = 0.0 # Inicia en 0 en el centro hasta el primer clic
var escala_actual: float = 1.0
var jugador: Node3D = null

var _altura_base: float = 1.25
var _reloj_flotacion: float = 0.0
var _esta_presionado: bool = false
var _en_teletransporte: bool = false
var _impulso_evasion: Vector3 = Vector3.ZERO
var _cooldown_click: float = 0.0

# Sistema de Cadenas y Palancas
var cadenas_activas: int = 0
var palancas_instancias: Array = []
var _tiempo_frenesi: float = 0.0

@onready var parte_boton: MeshInstance3D = $Pedestal/BotonPulsable
@onready var anillo_runico: MeshInstance3D = $Pedestal/AnilloRunico
@onready var luz_nucleo: OmniLight3D = $LuzNucleo
@onready var nodo_cadenas: Node3D = $CadenasContencion
@onready var cadena_1: MeshInstance3D = $CadenasContencion/Cadena1
@onready var cadena_2: MeshInstance3D = $CadenasContencion/Cadena2
@onready var cadena_3: MeshInstance3D = $CadenasContencion/Cadena3
@onready var candado_visual: MeshInstance3D = $CadenasContencion/CandadoVisual

func _ready():
	add_to_group("boton_movil")
	input_ray_pickable = true
	input_event.connect(_on_input_event)
	
	jugador = get_tree().get_first_node_in_group("jugador")
	
	# Al inicio el botón aparece exactamente en el medio de la arena
	global_position = Vector3(0.0, _altura_base, 0.0)
	indice_ruta = 0
	rapidez_movimiento = 0.0 # Flotando en espera hasta recibir el primer clic
	total_clicks = 0
		
	if nodo_cadenas != null:
		nodo_cadenas.visible = false
		
	call_deferred("_crear_palancas_en_arena")

func _crear_palancas_en_arena():
	var posiciones_palancas = [
		Vector3(-16.0, 0.0, 13.0),   # Palanca 1: Suroeste
		Vector3(0.0, 0.0, -17.0),    # Palanca 2: Norte
		Vector3(16.0, 0.0, 13.0)     # Palanca 3: Sureste
	]
	
	var arena = get_parent()
	for i in range(posiciones_palancas.size()):
		var p = PalancaEscena.instantiate()
		p.id_palanca = i + 1
		p.name = "PalancaTerminal_%d" % (i + 1)
		arena.add_child(p)
		p.global_position = posiciones_palancas[i]
		p.palanca_activada.connect(_on_palanca_activada)
		palancas_instancias.append(p)

func _physics_process(delta: float):
	_cooldown_click = maxf(_cooldown_click - delta, 0.0)
	emit_signal("estabilidad_actualizada", tiempo_estabilidad_actual, tiempo_estabilidad_max, (estado_actual == EstadoBoton.ENCADENADO))
	
	# Manejo del temporizador de Frenesí
	if estado_actual == EstadoBoton.SOBRECARGA_FRENESI:
		_tiempo_frenesi -= delta
		if _tiempo_frenesi <= 0.0:
			_terminar_frenesi()
			
	# Rotación continua de cadenas si está bloqueado
	if estado_actual == EstadoBoton.ENCADENADO and nodo_cadenas != null:
		nodo_cadenas.rotate_y(delta * 2.2)
		
	if _en_teletransporte:
		return
		
	# 1. Movimiento orbital perimetral limpio
	if estado_actual != EstadoBoton.ENCADENADO:
		if total_clicks == 0:
			# Al inicio se mantiene quieto levitando exactamente en el medio
			global_position.x = 0.0
			global_position.z = 0.0
		elif ruta.size() > 0:
			# Evasión activa del jugador si está cerca (se vuelve más esquivo con más clics)
			if jugador != null and total_clicks >= 5:
				var dist_pj = global_position.distance_to(jugador.global_position)
				if dist_pj < 3.8:
					var dir_huida = (global_position - jugador.global_position).normalized()
					dir_huida.y = 0.0
					_impulso_evasion = _impulso_evasion.lerp(dir_huida * (1.2 + total_clicks * 0.05), delta * 6.0)

			var destino = ruta[indice_ruta]
			var plano_dir = Vector2(destino.x - global_position.x, destino.z - global_position.z)
			
			if plano_dir.length() < 1.3:
				indice_ruta = (indice_ruta + 1) % ruta.size()
				# Si completó una vuelta y ya no estamos en el inicio, no detenerse en el medio
				if indice_ruta == 0 and total_clicks > 0:
					indice_ruta = 1
			else:
				var dir_norm = plano_dir.normalized()
				var vel_mov = Vector3(dir_norm.x, 0.0, dir_norm.y) * rapidez_movimiento
				global_position += (vel_mov + _impulso_evasion) * delta
				
				# Contención dentro de los límites de la arena 60x60
				global_position.x = clampf(global_position.x, -26.0, 26.0)
				global_position.z = clampf(global_position.z, -26.0, 26.0)
	else:
		# En estado encadenado se mantiene quieto flotando en su waypoint actual
		global_position += _impulso_evasion * delta
		
	_impulso_evasion = _impulso_evasion.move_toward(Vector3.ZERO, delta * 12.0)
	
	# 2. Flotación suave vertical (bobbing)
	_reloj_flotacion += delta * (4.8 if estado_actual == EstadoBoton.SOBRECARGA_FRENESI else 3.0)
	if not _esta_presionado:
		global_position.y = _altura_base + sin(_reloj_flotacion) * 0.14
		
	# 3. Rotación del anillo de energía
	if anillo_runico != null:
		var mult_rot = 3.5 if estado_actual == EstadoBoton.SOBRECARGA_FRENESI else (0.8 if estado_actual == EstadoBoton.ENCADENADO else 1.5)
		anillo_runico.rotate_y(delta * mult_rot)

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _cooldown_click > 0.0:
			return
		var cam = get_viewport().get_camera_3d()
		if cam != null:
			var ray_from = cam.project_ray_origin(event.position)
			var ray_dir = cam.project_ray_normal(event.position)
			var ray_to = ray_from + ray_dir * 120.0
			
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
			query.collide_with_areas = true
			query.collide_with_bodies = false
			var result = space_state.intersect_ray(query)
			if result and result.collider == self:
				get_viewport().set_input_as_handled()
				_cooldown_click = 0.08
				pulsar_boton()

func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _cooldown_click > 0.0:
			return
		get_viewport().set_input_as_handled()
		_cooldown_click = 0.08
		pulsar_boton()

## Lógica central al hacer clic en el botón
func pulsar_boton():
	# Si está bloqueado por cadenas, no otorga progreso y avisa al jugador
	if estado_actual == EstadoBoton.ENCADENADO:
		AudioManager.play("escudo_bloqueo", 1.4)
		_spawn_floating_text("🔒 ¡BLOQUEADO POR CADENAS! (%d/3 palancas)" % cadenas_activas)
		# Pequeño temblor visual
		var tw_shake = create_tween()
		tw_shake.tween_property(self, "position:x", position.x + 0.1, 0.04)
		tw_shake.tween_property(self, "position:x", position.x - 0.1, 0.04)
		tw_shake.tween_property(self, "position:x", position.x, 0.04)
		return
		
	total_clicks += 1
	_esta_presionado = true
	emit_signal("click_presionado", total_clicks)
	
	# Al dar el primer clic: despertar y comenzar a moverse desde el centro
	if total_clicks == 1:
		indice_ruta = 1
		rapidez_movimiento = rapidez_base
		_spawn_floating_text("⚡ ¡NÚCLEO ACTIVADO! Despegando del altar...")
		AudioManager.play("alerta_oleada", 1.25, 2.0)
	else:
		# Escalado de velocidad del botón por clics (cada vez más rápido y esquivo)
		rapidez_movimiento = clampf(rapidez_base + (total_clicks * 0.15), rapidez_base, rapidez_maxima)
	
	# Multiplicador del modo Frenesí (x3 clics y x3 oro)
	var mult_recompensa = 3 if estado_actual == EstadoBoton.SOBRECARGA_FRENESI else 1
	
	AudioManager.play("click", 1.0 + (total_clicks % 8) * 0.04 + (0.2 if mult_recompensa > 1 else 0.0))
	
	# Animación física del botón
	if parte_boton != null:
		var tw = create_tween()
		tw.tween_property(parte_boton, "position:y", 0.65, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(parte_boton, "position:y", 0.85, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.finished.connect(func(): _esta_presionado = false)
		
	# Destello de luz adaptativo según el nivel de amenaza por clics
	if luz_nucleo != null:
		var col_luz = Color(0.12, 0.92, 1.0)
		if mult_recompensa > 1:
			col_luz = Color(1.0, 0.85, 0.2)
		elif total_clicks >= 40:
			col_luz = Color(1.0, 0.18, 0.18) # Rojo crítico
		elif total_clicks >= 20:
			col_luz = Color(1.0, 0.55, 0.12) # Naranja amenaza
		elif total_clicks >= 10:
			col_luz = Color(1.0, 0.85, 0.25) # Amarillo alerta
			
		luz_nucleo.light_color = col_luz
		var tw_luz = create_tween()
		tw_luz.tween_property(luz_nucleo, "light_energy", 4.5, 0.05)
		tw_luz.tween_property(luz_nucleo, "light_energy", 2.2, 0.18)
		
	# Recompensas al héroe multiplicadas
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
		
	if jugador != null:
		for i in range(mult_recompensa):
			if jugador.has_method("registrar_click_jugador"):
				jugador.registrar_click_jugador(false)
			if jugador.has_method("recoger_drop"):
				jugador.recoger_drop(0, 2)
				jugador.recoger_drop(1, 2)
				
		var clics_ganados = 1 * mult_recompensa
		var oro_ganado = 2 * mult_recompensa
		if mult_recompensa > 1:
			_spawn_floating_text("🔥 ¡SOBRECARGA x3! +%d⚡ +%d🪙" % [clics_ganados, oro_ganado])
		else:
			_spawn_floating_text("¡CLIC! +%d⚡ +%d🪙 (Vel: %.1f m/s)" % [clics_ganados, oro_ganado, rapidez_movimiento])
			
	# Onda de choque expansiva que repele enemigos
	_detonar_onda_choque(mult_recompensa > 1)
	
	# Verificar si se dispara el bloqueo por cadenas
	if total_clicks % clics_para_bloqueo == 0 and estado_actual == EstadoBoton.ACTIVO:
		activar_bloqueo_cadenas()
	elif total_clicks >= 10 and total_clicks % 8 == 0 and estado_actual == EstadoBoton.ACTIVO:
		_ejecutar_teletransporte_seguro()

# ==============================================================================
# MECÁNICA DE CADENAS Y PALANCAS
# ==============================================================================

func activar_bloqueo_cadenas():
	if estado_actual == EstadoBoton.ENCADENADO:
		return
		
	estado_actual = EstadoBoton.ENCADENADO
	emit_signal("estado_cambiado", estado_actual)
	cadenas_activas = 3
	
	if nodo_cadenas != null:
		nodo_cadenas.visible = true
	if cadena_1 != null: cadena_1.visible = true
	if cadena_2 != null: cadena_2.visible = true
	if cadena_3 != null: cadena_3.visible = true
	if candado_visual != null: candado_visual.visible = true
	
	if luz_nucleo != null:
		luz_nucleo.light_color = Color(1.0, 0.18, 0.18)
		luz_nucleo.light_energy = 3.8
		
	AudioManager.play("alerta_oleada", 1.45, 2.0)
	_spawn_floating_text("⚠️ ¡NÚCLEO ENCADENADO! Activa 3 palancas ⚡")
	
	# Armar las 3 palancas en el mapa
	for p in palancas_instancias:
		if p != null and is_instance_valid(p):
			p.armar()

func _on_palanca_activada(_id: int):
	if estado_actual != EstadoBoton.ENCADENADO:
		return
		
	cadenas_activas -= 1
	AudioManager.play("corte_giratorio", 1.6, 2.0)
	
	match cadenas_activas:
		2:
			if cadena_1 != null: cadena_1.visible = false
			_spawn_floating_text("⛓️ ¡Cadena 1/3 Rota!")
		1:
			if cadena_2 != null: cadena_2.visible = false
			_spawn_floating_text("⛓️ ¡Cadena 2/3 Rota!")
		0:
			if cadena_3 != null: cadena_3.visible = false
			if candado_visual != null: candado_visual.visible = false
			if nodo_cadenas != null: nodo_cadenas.visible = false
			_iniciar_frenesi_sobrecarga()

func _iniciar_frenesi_sobrecarga():
	estado_actual = EstadoBoton.SOBRECARGA_FRENESI
	emit_signal("estado_cambiado", estado_actual)
	_tiempo_frenesi = 12.0
	
	# Desactivar palancas
	for p in palancas_instancias:
		if p != null and is_instance_valid(p):
			p.desactivar_silencioso()
			
	# Detonación de supernova defensiva (limpia enemigos alrededor)
	_detonar_onda_choque(true)
	AudioManager.play("alerta_oleada", 1.8, 4.0)
	
	if luz_nucleo != null:
		luz_nucleo.light_color = Color(1.0, 0.85, 0.15)
		luz_nucleo.light_energy = 5.5
		
	rapidez_movimiento = rapidez_base * 1.35
	_spawn_floating_text("🔥 ¡SOBRECARGA LIBERADA! (x3 CLICS & ORO - 12s) 🔥")

func _terminar_frenesi():
	estado_actual = EstadoBoton.ACTIVO
	emit_signal("estado_cambiado", estado_actual)
	rapidez_movimiento = rapidez_base
	
	if luz_nucleo != null:
		luz_nucleo.light_color = Color(0.12, 0.92, 1.0)
		luz_nucleo.light_energy = 2.8
		
	_spawn_floating_text("Núcleo estabilizado a velocidad normal.")

# ==============================================================================
# FÍSICAS DE TELETRANSPORTE Y ONDA DE CHOQUE
# ==============================================================================

func _ejecutar_teletransporte_seguro():
	if _en_teletransporte or estado_actual == EstadoBoton.ENCADENADO:
		return
		
	_en_teletransporte = true
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3(0.08, 0.08, 0.08), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	
	# Seleccionar un waypoint diferente de la ruta perimetral
	indice_ruta = (indice_ruta + randi_range(2, 4)) % ruta.size()
	global_position = ruta[indice_ruta]
	
	var tw_pop = create_tween()
	tw_pop.tween_property(self, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_detonar_onda_choque(false)
	_en_teletransporte = false

func _detonar_onda_choque(es_supernova: bool):
	var radio_efectivo = radio_onda_choque * (2.2 if es_supernova else 1.0)
	var empuje_efectivo = empuje_onda * (2.5 if es_supernova else 1.0)
	
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if e is Node3D:
			var dist = global_position.distance_to(e.global_position)
			if dist <= radio_efectivo:
				if e.has_method("desactivar_escudo_runico"):
					e.desactivar_escudo_runico(8.0)
				if e.has_method("recibir_dano"):
					var dano_base = 25.0 if es_supernova else 14.0
					e.recibir_dano(dano_base, true)
				var dir = (e.global_position - global_position).normalized()
				dir.y = 0.0
				if "velocity" in e:
					e.velocity += dir * empuje_efectivo

func _spawn_floating_text(txt: String):
	var escena = load("res://damage_number_3d.tscn")
	if escena != null:
		var num = escena.instantiate()
		get_parent().add_child(num)
		num.global_position = global_position + Vector3(0, 1.9, 0)
		num.iniciar(0, true, false, txt)
