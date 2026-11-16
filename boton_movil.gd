extends Area3D
class_name BotonMovil

## BotonMovil (Dron de Núcleo Rúnico) - Clicklike 3D Overdrive
## 1. Órbita Elástica Táctica alrededor del jugador combinada con atracción suave a ruta,
##    manteniendo tensión espacial entre WASD y Ratón (Hilo de Resonancia).
## 2. Anillo de Ritmo (Perfect Click Timing): pulsar en la ventana dulce otorga Clic Perfecto (x1.5 Fiebre y Onda).
## 3. Sistema de Bloqueo por Cadenas (3 palancas) y Modo Frenesí de Sobrecarga (12s, x3 recompensas).
## 4. La Forja de Núcleos (3 Core Chassis):
##    - "estandar": Bronce/Rúnico, balanceado (rapidez 2.6, bloqueo 20 clics).
##    - "gravitatorio": Obsidiana/Violeta (-45% rapidez, pulso magnético cada 1.2s en 8.5m, +35% onda, +25% XP a bajas en 6.5m).
##    - "cometa": Mercurio/Cian (+55% rapidez, clics x2, ventana dulce +45%, estela voltaica en suelo cada 0.35s).
## 5. Bendiciones Corruptas:
##    - "corrupta_sobrecarga_sin_freno": Cadenas cada 12 clics, Frenesí 24s y x5 clics/oro.
##    - "corrupta_hilo_corto": Clampa la órbita del botón a radio máximo de 5.5m del jugador.

const AudioManager = preload("res://audio_manager.gd")
const PalancaEscena = preload("res://palanca_boton.tscn")
const BunkerVisualKit = preload("res://bunker_visual_kit.gd")
const MetaprogresoManager = preload("res://metaprogreso_manager.gd")

enum EstadoBoton { ACTIVO, ENCADENADO, SOBRECARGA_FRENESI }

signal click_presionado(total_clicks: int)
signal estado_cambiado(nuevo_estado: EstadoBoton)
signal estabilidad_actualizada(actual: float, maximo: float, en_colapso: bool)
signal calor_actualizado(calor_actual: float, calor_maximo: float, sobrecalentado: bool)
signal chasis_cambiado(id_chasis: String)

# Parámetros de Movimiento y Vuelo
@export var rapidez_base: float = 2.6
@export var rapidez_maxima: float = 9.5
@export var radio_onda_choque: float = 6.5
@export var empuje_onda: float = 9.5
@export var clics_para_bloqueo: int = 20

# Parámetros de Sobrecalentamiento / Sobrecarga Térmica
@export var calor_maximo: float = 100.0
@export var calor_por_clic: float = 16.0
@export var umbral_sobrecarga_termica: float = 60.0
@export var retardo_enfriamiento: float = 0.50
@export var velocidad_enfriamiento: float = 28.0

# Estado térmico del núcleo
var calor_actual: float = 0.0
var sobrecalentado: bool = false
var _tiempo_sin_clic: float = 0.0

# Variables de estabilidad compatibles con HUD (sincronizadas con calor)
var tiempo_estabilidad_actual: float = 100.0
var tiempo_estabilidad_max: float = 100.0
var en_colapso: bool = false

# ------------------------------------------------------------------------------
# Sistema de Chasis ("La Forja de Núcleos")
# ------------------------------------------------------------------------------
@export var chasis_actual: String = "estandar"
var factor_chasis_cometa: int = 1
var mult_ventana_ritmo: float = 1.0
var mult_radio_onda_chasis: float = 1.0
var _reloj_pulso_gravitatorio: float = 0.0
var _reloj_peligro_cometa: float = 0.0

var clics_recibidos: int:
	get: return total_clicks
var clics_run_boton: int:
	get: return total_clicks

# Ruta táctica de anclaje con punto central de partida
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
var rapidez_movimiento: float = 0.0
var escala_actual: float = 1.0
var jugador: Node3D = null

var _altura_base: float = 1.25
var _reloj_flotacion: float = 0.0
var _angulo_orbita: float = 0.0
var _esta_presionado: bool = false
var _en_teletransporte: bool = false
var _impulso_evasion: Vector3 = Vector3.ZERO
var _cooldown_click: float = 0.0

# Anillo de Ritmo (Perfect Click)
var _fase_ritmo: float = 0.0
var _velocidad_ritmo: float = 1.35
var _anillo_ritmo_visual: MeshInstance3D = null

# Sistema de Cadenas y Palancas
var cadenas_activas: int = 0
var palancas_instancias: Array = []
var _tiempo_frenesi: float = 0.0

# Telemetría Visual Industrial (BunkerVisualKit)
var _anillo_termico_suelo: MeshInstance3D = null
var _mat_anillo_termico: ShaderMaterial = null
var _mat_dron_emissive: StandardMaterial3D = null
var _mat_boton_pulsable: StandardMaterial3D = null
var _mat_anillo_runico: StandardMaterial3D = null
var _reloj_pulso_termico: float = 0.0

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
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("player")

	global_position = Vector3(0.0, _altura_base, 0.0)
	indice_ruta = 0
	rapidez_movimiento = 0.0
	total_clicks = 0
	calor_actual = 0.0
	sobrecalentado = false
	_tiempo_sin_clic = 0.0

	if nodo_cadenas != null:
		nodo_cadenas.visible = false

	_crear_anillo_ritmo_visual()
	_inicializar_visual_termico_bunker()
	
	MetaprogresoManager.asegurar_inicializado()
	var chasis_inicial: String = chasis_actual
	var ch_meta = str(MetaprogresoManager.chasis_equipado)
	if ch_meta != "":
		chasis_inicial = ch_meta
	aplicar_chasis(chasis_inicial)

	_sincronizar_telemetria_termica()
	_actualizar_visual_termico(0.0)
	call_deferred("_crear_palancas_en_arena")

## Cambio dinámico y pre-run del Chasis del Núcleo Rúnico
func aplicar_chasis(id_chasis: String) -> void:
	chasis_actual = id_chasis.to_lower()
	match chasis_actual:
		"gravitatorio":
			rapidez_base = 1.45
			clics_para_bloqueo = 20
			factor_chasis_cometa = 1
			mult_ventana_ritmo = 1.0
			mult_radio_onda_chasis = 1.35
			_configurar_paleta_chasis(Color(0.68, 0.20, 0.95), Color(0.18, 0.05, 0.28))
		"cometa":
			rapidez_base = 4.0
			clics_para_bloqueo = 20
			factor_chasis_cometa = 2
			mult_ventana_ritmo = 1.45
			mult_radio_onda_chasis = 1.0
			_configurar_paleta_chasis(Color(0.20, 0.95, 0.92), Color(0.04, 0.28, 0.32))
		_:
			chasis_actual = "estandar"
			rapidez_base = 2.6
			clics_para_bloqueo = 20
			factor_chasis_cometa = 1
			mult_ventana_ritmo = 1.0
			mult_radio_onda_chasis = 1.0
			_configurar_paleta_chasis(BunkerVisualKit.COL_CYAN_ELECTRIC, Color(0.05, 0.22, 0.28))

	if total_clicks > 0:
		rapidez_movimiento = clampf(rapidez_base + (total_clicks * 0.12), rapidez_base, rapidez_maxima)

	emit_signal("chasis_cambiado", chasis_actual)
	_actualizar_visual_termico(0.0)

func _configurar_paleta_chasis(col_emision: Color, col_albedo: Color) -> void:
	for mat in [_mat_dron_emissive, _mat_boton_pulsable, _mat_anillo_runico]:
		if mat != null:
			mat.emission = col_emision
			mat.albedo_color = col_albedo
	if luz_nucleo != null and not _esta_presionado:
		luz_nucleo.light_color = col_emision
	if _mat_anillo_termico != null:
		_mat_anillo_termico.set_shader_parameter("base_color", col_emision)

func _inicializar_visual_termico_bunker():
	_anillo_termico_suelo = BunkerVisualKit.create_hazard_ground_ring(
		1.65,
		BunkerVisualKit.COL_CYAN_ELECTRIC,
		BunkerVisualKit.COL_PLASMA_ORANGE,
		0.78,
		0.95,
		0.30,
		0.14
	)
	_anillo_termico_suelo.name = "AnilloTermicoSuelo"
	_anillo_termico_suelo.position = Vector3(0.0, -1.18, 0.0)
	add_child(_anillo_termico_suelo)
	_mat_anillo_termico = _anillo_termico_suelo.material_override as ShaderMaterial
	if _mat_anillo_termico != null:
		_mat_anillo_termico.set_shader_parameter("segment_count", 24.0)
		_mat_anillo_termico.set_shader_parameter("rotation_speed", 0.55)
		_mat_anillo_termico.set_shader_parameter("pulse_frequency", 4.0)
		_mat_anillo_termico.set_shader_parameter("pulse_intensity", 0.25)

	_mat_dron_emissive = BunkerVisualKit.make_emissive_mat(
		BunkerVisualKit.COL_CYAN_ELECTRIC,
		2.8,
		Color(0.05, 0.22, 0.28),
		0.20,
		0.20
	)
	_mat_boton_pulsable = BunkerVisualKit.make_emissive_mat(
		BunkerVisualKit.COL_CYAN_ELECTRIC,
		3.0,
		Color(0.08, 0.30, 0.36),
		0.18,
		0.20
	)
	_mat_anillo_runico = BunkerVisualKit.make_emissive_mat(
		BunkerVisualKit.COL_CYAN_ELECTRIC,
		2.5,
		Color(0.10, 0.28, 0.35),
		0.25,
		0.22
	)

	if parte_boton != null:
		parte_boton.material_override = _mat_boton_pulsable
	if anillo_runico != null:
		anillo_runico.material_override = _mat_anillo_runico

	var modelo_dron: Node = get_node_or_null("Pedestal/ModeloDrone")
	if modelo_dron == null:
		modelo_dron = get_node_or_null("Pedestal/ModeloDron")
	if modelo_dron != null:
		BunkerVisualKit.override_glb_hierarchy(modelo_dron, {
			"Main_Spherical_Chassis*": BunkerVisualKit.get_chassis_mat(),
			"Side_Armor*": BunkerVisualKit.get_armor_grey_mat(),
			"Bottom_Stabilizer*": BunkerVisualKit.get_titanium_mat(),
			"Rear_Thruster*": BunkerVisualKit.get_chrome_mat(),
		}, true)
		BunkerVisualKit.set_glb_node_material(modelo_dron, "Front_Reactor_Turbine_Glow", _mat_dron_emissive, false)
		BunkerVisualKit.set_glb_node_material(modelo_dron, "Top_Energy_Window_Glow", _mat_dron_emissive, false)

func esta_en_sobrecarga_termica() -> bool:
	return not sobrecalentado and calor_actual >= umbral_sobrecarga_termica

func _sincronizar_telemetria_termica():
	tiempo_estabilidad_max = calor_maximo
	tiempo_estabilidad_actual = clampf(calor_maximo - calor_actual, 0.0, calor_maximo)
	en_colapso = sobrecalentado or (estado_actual == EstadoBoton.ENCADENADO)
	emit_signal("calor_actualizado", calor_actual, calor_maximo, sobrecalentado)
	emit_signal("estabilidad_actualizada", tiempo_estabilidad_actual, tiempo_estabilidad_max, en_colapso)

func _actualizar_visual_termico(delta: float):
	_reloj_pulso_termico += delta
	var ratio_calor: float = clampf(calor_actual / maxf(calor_maximo, 1.0), 0.0, 1.0)

	var col_base_chasis: Color = BunkerVisualKit.COL_CYAN_ELECTRIC
	if chasis_actual == "gravitatorio":
		col_base_chasis = Color(0.68, 0.20, 0.95)
	elif chasis_actual == "cometa":
		col_base_chasis = Color(0.20, 0.95, 0.92)

	var col_emision: Color = col_base_chasis
	var energia_emision: float = 2.6

	if sobrecalentado:
		var onda_6hz: float = 0.5 + 0.5 * sin(_reloj_pulso_termico * TAU * 6.0)
		col_emision = BunkerVisualKit.COL_CRIMSON_ALERT.lerp(BunkerVisualKit.COL_PLASMA_ORANGE, onda_6hz * 0.35)
		energia_emision = lerpf(1.4, 4.8, onda_6hz)
	elif estado_actual == EstadoBoton.ENCADENADO:
		var onda_lock: float = 0.5 + 0.5 * sin(_reloj_pulso_termico * TAU * 3.0)
		col_emision = BunkerVisualKit.COL_CRIMSON_ALERT
		energia_emision = lerpf(2.0, 3.8, onda_lock)
	elif estado_actual == EstadoBoton.SOBRECARGA_FRENESI:
		var onda_fren: float = 0.5 + 0.5 * sin(_reloj_pulso_termico * TAU * 4.5)
		col_emision = BunkerVisualKit.COL_VAULT_GOLD
		energia_emision = lerpf(3.2, 5.2, onda_fren)
	elif calor_actual >= umbral_sobrecarga_termica:
		var t_sobre: float = clampf((calor_actual - umbral_sobrecarga_termica) / maxf(calor_maximo - umbral_sobrecarga_termica, 1.0), 0.0, 1.0)
		var onda_rapida: float = 0.5 + 0.5 * sin(_reloj_pulso_termico * TAU * lerpf(3.5, 5.5, t_sobre))
		col_emision = BunkerVisualKit.COL_PLASMA_ORANGE.lerp(BunkerVisualKit.COL_CRIMSON_ALERT, t_sobre * 0.38)
		energia_emision = lerpf(2.6, 4.4, onda_rapida)
	else:
		var t_sub: float = clampf(calor_actual / maxf(umbral_sobrecarga_termica, 1.0), 0.0, 1.0)
		col_emision = col_base_chasis.lerp(BunkerVisualKit.COL_HAZARD_YELLOW, t_sub * 0.35)
		energia_emision = lerpf(2.4, 3.1, t_sub)

	for mat in [_mat_dron_emissive, _mat_boton_pulsable, _mat_anillo_runico]:
		if mat != null:
			mat.emission = col_emision
			mat.albedo_color = col_emision.darkened(0.45)
			mat.emission_energy_multiplier = energia_emision

	if luz_nucleo != null and not _esta_presionado:
		luz_nucleo.light_color = col_emision
		luz_nucleo.light_energy = energia_emision

	if _anillo_termico_suelo != null:
		_anillo_termico_suelo.position.y = -1.18
		if _mat_anillo_termico != null:
			_mat_anillo_termico.set_shader_parameter("progress", ratio_calor)
			var estado_act: float = 1.0 if (sobrecalentado or calor_actual >= umbral_sobrecarga_termica) else 0.0
			_mat_anillo_termico.set_shader_parameter("active_state", estado_act)
			_mat_anillo_termico.set_shader_parameter("base_color", col_base_chasis)
			_mat_anillo_termico.set_shader_parameter(
				"active_color",
				BunkerVisualKit.COL_CRIMSON_ALERT if sobrecalentado else BunkerVisualKit.COL_PLASMA_ORANGE
			)

func _entrar_sobrecalentamiento():
	sobrecalentado = true
	en_colapso = true
	_tiempo_sin_clic = -0.35
	_sincronizar_telemetria_termica()
	_actualizar_visual_termico(0.0)
	AudioManager.play("jefe_alerta", 1.25)
	AudioManager.play("escudo_bloqueo", 0.8)
	BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 0.8, 3.6, BunkerVisualKit.COL_CRIMSON_ALERT, 0.42)
	_spawn_floating_text("🌡️ ¡NÚCLEO SOBRECALENTADO! Déjalo enfriar")

func _salir_sobrecalentamiento():
	sobrecalentado = false
	en_colapso = (estado_actual == EstadoBoton.ENCADENADO)
	_sincronizar_telemetria_termica()
	_actualizar_visual_termico(0.0)
	AudioManager.play("altar_activado", 1.35)
	var col_halo := BunkerVisualKit.COL_CYAN_ELECTRIC
	if chasis_actual == "gravitatorio":
		col_halo = Color(0.68, 0.20, 0.95)
	BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 0.6, 2.8, col_halo, 0.35)
	_spawn_floating_text("❄️ ¡NÚCLEO ENFRIADO! Listo")

func _crear_anillo_ritmo_visual():
	_anillo_ritmo_visual = MeshInstance3D.new()
	_anillo_ritmo_visual.name = "AnilloRitmoPerfecto"
	var torus = TorusMesh.new()
	torus.inner_radius = 0.72
	torus.outer_radius = 0.80
	_anillo_ritmo_visual.mesh = torus
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.2, 0.95, 1.0, 0.55)
	_anillo_ritmo_visual.material_override = mat
	_anillo_ritmo_visual.position = Vector3(0.0, 0.55, 0.0)
	add_child(_anillo_ritmo_visual)

func _crear_palancas_en_arena():
	var posiciones_palancas = [
		Vector3(-16.0, 0.0, 13.0),
		Vector3(0.0, 0.0, -17.0),
		Vector3(16.0, 0.0, 13.0)
	]

	var arena = get_parent()
	if arena == null:
		return
	for i in range(posiciones_palancas.size()):
		var p = PalancaEscena.instantiate()
		p.id_palanca = i + 1
		p.name = "PalancaTerminal_%d" % (i + 1)
		arena.add_child(p)
		p.global_position = posiciones_palancas[i]
		p.palanca_activada.connect(_on_palanca_activada)
		palancas_instancias.append(p)

func _es_ventana_ritmo_perfecta() -> bool:
	var centro: float = 0.76
	var radio_v: float = 0.16 * mult_ventana_ritmo
	return _fase_ritmo >= (centro - radio_v) and _fase_ritmo <= (centro + radio_v)

func _physics_process(delta: float):
	_cooldown_click = maxf(_cooldown_click - delta, 0.0)

	_tiempo_sin_clic += delta
	if estado_actual == EstadoBoton.SOBRECARGA_FRENESI:
		calor_actual = 0.0
		sobrecalentado = false
	elif _tiempo_sin_clic >= retardo_enfriamiento and calor_actual > 0.0:
		var tasa: float = (velocidad_enfriamiento * 0.92) if sobrecalentado else velocidad_enfriamiento
		calor_actual = maxf(0.0, calor_actual - tasa * delta)
		if sobrecalentado and calor_actual <= 0.0:
			_salir_sobrecalentamiento()

	_sincronizar_telemetria_termica()
	_actualizar_visual_termico(delta)

	_fase_ritmo = fmod(_fase_ritmo + delta * _velocidad_ritmo, 1.0)
	if _anillo_ritmo_visual != null:
		var esc_anillo = lerpf(1.75, 0.75, _fase_ritmo)
		_anillo_ritmo_visual.scale = Vector3(esc_anillo, 1.0, esc_anillo)
		var mat = _anillo_ritmo_visual.material_override as StandardMaterial3D
		if mat != null:
			if sobrecalentado:
				mat.albedo_color = Color(1.0, 0.18, 0.25, 0.35)
			elif _es_ventana_ritmo_perfecta():
				mat.albedo_color = Color(1.0, 0.88, 0.18, 0.88)
			else:
				var col_ring := Color(0.2, 0.95, 1.0, 0.42)
				if chasis_actual == "gravitatorio":
					col_ring = Color(0.72, 0.35, 1.0, 0.45)
				elif chasis_actual == "cometa":
					col_ring = Color(0.2, 1.0, 0.95, 0.55)
				mat.albedo_color = col_ring

	if estado_actual == EstadoBoton.SOBRECARGA_FRENESI:
		_tiempo_frenesi -= delta
		if _tiempo_frenesi <= 0.0:
			_terminar_frenesi()

	if estado_actual == EstadoBoton.ENCADENADO and nodo_cadenas != null:
		nodo_cadenas.rotate_y(delta * 2.2)

	if chasis_actual == "gravitatorio" and total_clicks > 0 and estado_actual != EstadoBoton.ENCADENADO:
		_reloj_pulso_gravitatorio += delta
		if _reloj_pulso_gravitatorio >= 1.2:
			_reloj_pulso_gravitatorio = 0.0
			_ejecutar_pulso_gravitatorio()

	if chasis_actual == "cometa" and total_clicks > 0 and estado_actual != EstadoBoton.ENCADENADO:
		_reloj_peligro_cometa += delta
		if _reloj_peligro_cometa >= 0.35:
			_reloj_peligro_cometa = 0.0
			_crear_zona_voltaica_suelo()

	if _en_teletransporte:
		return

	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			jugador = get_tree().get_first_node_in_group("player")

	if estado_actual != EstadoBoton.ENCADENADO:
		if total_clicks == 0:
			global_position.x = 0.0
			global_position.z = 0.0
		elif ruta.size() > 0:
			_angulo_orbita += delta * (0.65 + minf(total_clicks * 0.015, 0.85))
			var destino_waypoint = ruta[indice_ruta]
			var destino_final = destino_waypoint

			if jugador != null and is_instance_valid(jugador):
				var dist_pj = global_position.distance_to(jugador.global_position)
				var radio_ideal = 7.5
				var pos_orbita = jugador.global_position + Vector3(cos(_angulo_orbita) * radio_ideal, 0.0, sin(_angulo_orbita) * radio_ideal)
				destino_final = destino_waypoint.lerp(pos_orbita, 0.55)

				if dist_pj < 3.5:
					var dir_huida = (global_position - jugador.global_position).normalized()
					dir_huida.y = 0.0
					_impulso_evasion = _impulso_evasion.lerp(dir_huida * (1.4 + minf(total_clicks * 0.04, 2.5)), delta * 6.0)

			var plano_dir = Vector2(destino_final.x - global_position.x, destino_final.z - global_position.z)
			var dist_wp = Vector2(destino_waypoint.x - global_position.x, destino_waypoint.z - global_position.z).length()

			if dist_wp < 2.2 or plano_dir.length() < 1.2:
				indice_ruta = (indice_ruta + 1) % ruta.size()
				if indice_ruta == 0 and total_clicks > 0:
					indice_ruta = 1
			else:
				var dir_norm = plano_dir.normalized()
				var vel_mov = Vector3(dir_norm.x, 0.0, dir_norm.y) * rapidez_movimiento
				global_position += (vel_mov + _impulso_evasion) * delta

				var tiene_hilo_corto: bool = false
				if jugador != null and is_instance_valid(jugador):
					if "bendiciones_corruptas" in jugador and jugador.bendiciones_corruptas.has("corrupta_hilo_corto"):
						tiene_hilo_corto = true
					elif "bendiciones_run" in jugador and jugador.bendiciones_run.has("corrupta_hilo_corto"):
						tiene_hilo_corto = true

				if tiene_hilo_corto and jugador != null and is_instance_valid(jugador):
					var off_pj = global_position - jugador.global_position
					off_pj.y = 0.0
					if off_pj.length() > 5.5:
						var clamped_pos = jugador.global_position + off_pj.normalized() * 5.5
						global_position.x = clamped_pos.x
						global_position.z = clamped_pos.z
				else:
					global_position.x = clampf(global_position.x, -25.0, 25.0)
					global_position.z = clampf(global_position.z, -25.0, 25.0)
	else:
		global_position += _impulso_evasion * delta

	_impulso_evasion = _impulso_evasion.move_toward(Vector3.ZERO, delta * 12.0)

	_reloj_flotacion += delta * (4.8 if estado_actual == EstadoBoton.SOBRECARGA_FRENESI else 3.0)
	if not _esta_presionado:
		global_position.y = _altura_base + sin(_reloj_flotacion) * 0.14

	if anillo_runico != null:
		var mult_rot = 3.5 if estado_actual == EstadoBoton.SOBRECARGA_FRENESI else (0.8 if estado_actual == EstadoBoton.ENCADENADO else (2.4 if calor_actual >= umbral_sobrecarga_termica else 1.5))
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

func pulsar_boton():
	for p in get_tree().get_nodes_in_group("parasitos_cursor"):
		if is_instance_valid(p) and "adherido_al_boton" in p and p.adherido_al_boton:
			if p.has_method("recibir_clic_directo"):
				p.recibir_clic_directo()
				_spawn_floating_text("🦠 ¡Parásito de Cursor golpeado!")
				return

	if sobrecalentado:
		_tiempo_sin_clic = -0.30
		calor_actual = minf(calor_maximo, calor_actual + 4.0)
		_sincronizar_telemetria_termica()
		_actualizar_visual_termico(0.0)
		AudioManager.play("escudo_bloqueo", 0.95)
		_spawn_floating_text("🌡️ ¡SOBRECALENTADO! Deja de hacer clic (%d%%)" % int(round(calor_actual)))
		var tw_over = create_tween()
		var base_x := position.x
		var base_z := position.z
		tw_over.tween_property(self, "position", Vector3(base_x + 0.11, position.y, base_z - 0.08), 0.035)
		tw_over.tween_property(self, "position", Vector3(base_x - 0.11, position.y, base_z + 0.08), 0.035)
		tw_over.tween_property(self, "position", Vector3(base_x, position.y, base_z), 0.035)
		return

	if estado_actual == EstadoBoton.ENCADENADO:
		AudioManager.play("escudo_bloqueo", 1.4)
		_spawn_floating_text("🔒 ¡BLOQUEADO POR CADENAS! (%d/3 palancas)" % cadenas_activas)
		var tw_shake = create_tween()
		tw_shake.tween_property(self, "position:x", position.x + 0.1, 0.04)
		tw_shake.tween_property(self, "position:x", position.x - 0.1, 0.04)
		tw_shake.tween_property(self, "position:x", position.x, 0.04)
		return

	_tiempo_sin_clic = 0.0
	var es_perfecto: bool = _es_ventana_ritmo_perfecta()
	var calor_previo: float = calor_actual

	if estado_actual == EstadoBoton.ACTIVO:
		var inc_calor: float = calor_por_clic * (0.65 if es_perfecto else 1.0)
		calor_actual = clampf(calor_actual + inc_calor, 0.0, calor_maximo)
	elif estado_actual == EstadoBoton.SOBRECARGA_FRENESI:
		calor_actual = 0.0

	var es_sobrecarga_termica: bool = (estado_actual == EstadoBoton.ACTIVO) and (calor_previo >= umbral_sobrecarga_termica or calor_actual >= umbral_sobrecarga_termica)

	total_clicks += (1 * factor_chasis_cometa)
	_esta_presionado = true
	emit_signal("click_presionado", total_clicks)

	var favor_mgr = get_tree().get_first_node_in_group("favor_emperador_manager")
	if favor_mgr != null and favor_mgr.has_method("notificar_clic_boton"):
		favor_mgr.notificar_clic_boton(es_perfecto, calor_actual)

	if total_clicks <= (1 * factor_chasis_cometa):
		indice_ruta = 1
		rapidez_movimiento = rapidez_base
		_spawn_floating_text("⚡ ¡NÚCLEO ACTIVADO! [%s]" % chasis_actual.to_upper())
		AudioManager.play("alerta_oleada", 1.25, 2.0)
	else:
		rapidez_movimiento = clampf(rapidez_base + (total_clicks * 0.12), rapidez_base, rapidez_maxima)

	var tiene_sobrecarga_sin_freno: bool = false
	if jugador != null and is_instance_valid(jugador):
		if "bendiciones_corruptas" in jugador and jugador.bendiciones_corruptas.has("corrupta_sobrecarga_sin_freno"):
			tiene_sobrecarga_sin_freno = true
		elif "bendiciones_run" in jugador and jugador.bendiciones_run.has("corrupta_sobrecarga_sin_freno"):
			tiene_sobrecarga_sin_freno = true

	var mult_recompensa = (5 if tiene_sobrecarga_sin_freno else 3) if estado_actual == EstadoBoton.SOBRECARGA_FRENESI else 1
	mult_recompensa *= factor_chasis_cometa

	AudioManager.play("click", 1.0 + (total_clicks % 8) * 0.04 + (0.2 if es_perfecto or mult_recompensa > 1 else 0.0))

	if parte_boton != null:
		var tw = create_tween()
		tw.tween_property(parte_boton, "position:y", 0.65, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(parte_boton, "position:y", 0.85, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.finished.connect(func(): _esta_presionado = false)

	if luz_nucleo != null:
		var col_luz = BunkerVisualKit.COL_CYAN_ELECTRIC
		if chasis_actual == "gravitatorio":
			col_luz = Color(0.68, 0.20, 0.95)
		elif chasis_actual == "cometa":
			col_luz = Color(0.20, 0.95, 0.92)

		if calor_actual >= calor_maximo:
			col_luz = BunkerVisualKit.COL_CRIMSON_ALERT
		elif es_sobrecarga_termica:
			col_luz = BunkerVisualKit.COL_PLASMA_ORANGE
		elif es_perfecto or mult_recompensa > 1:
			col_luz = BunkerVisualKit.COL_VAULT_GOLD

		luz_nucleo.light_color = col_luz
		var tw_luz = create_tween()
		tw_luz.tween_property(luz_nucleo, "light_energy", 4.8, 0.05)
		tw_luz.tween_property(luz_nucleo, "light_energy", 2.6, 0.18)

	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")

	var mult_termico: float = 1.5 if es_sobrecarga_termica else 1.0
	var dano_onda_base: float = 18.0 * (1.45 if es_perfecto else 1.0) * mult_termico
	if jugador != null and is_instance_valid(jugador):
		var xp_por_clic: int = (6 if es_perfecto else 4) + (2 if es_sobrecarga_termica else 0)
		for i in range(mult_recompensa):
			if jugador.has_method("registrar_clic_boton"):
				jugador.registrar_clic_boton(global_position, dano_onda_base, es_perfecto or es_sobrecarga_termica)
			elif jugador.has_method("registrar_click_jugador"):
				jugador.registrar_click_jugador(false)
			if jugador.has_method("ganar_xp"):
				jugador.ganar_xp(xp_por_clic)

		var fever_mult = jugador.multiplicador_fiebre if "multiplicador_fiebre" in jugador else 1
		if mult_recompensa > 1:
			_spawn_floating_text("🔥 ¡SOBRECARGA x%d! (Fiebre x%d)" % [mult_recompensa, fever_mult])
		elif calor_actual < calor_maximo and es_sobrecarga_termica:
			_spawn_floating_text("🔥 ¡SOBRECARGA TÉRMICA! (%d%% Calor)" % int(round(calor_actual)))
		elif es_perfecto:
			_spawn_floating_text("✨ ¡CLIC PERFECTO! (Fiebre x%d)" % fever_mult)
		elif calor_actual < calor_maximo:
			_spawn_floating_text("⚡ ¡CLIC! (Fiebre x%d)" % fever_mult)

	_detonar_onda_choque(mult_recompensa > 1, es_perfecto, es_sobrecarga_termica)

	if estado_actual == EstadoBoton.ACTIVO and calor_actual >= calor_maximo:
		_entrar_sobrecalentamiento()
	else:
		_sincronizar_telemetria_termica()
		_actualizar_visual_termico(0.0)

	var umbral_cadenas: int = 12 if tiene_sobrecarga_sin_freno else clics_para_bloqueo
	if total_clicks % umbral_cadenas == 0 and estado_actual == EstadoBoton.ACTIVO:
		activar_bloqueo_cadenas()
	elif total_clicks >= 12 and total_clicks % 10 == 0 and estado_actual == EstadoBoton.ACTIVO and not sobrecalentado:
		_ejecutar_teletransporte_seguro()

func _ejecutar_pulso_gravitatorio() -> void:
	BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 0.8, 8.5, Color(0.65, 0.22, 0.95, 0.55), 0.38)
	AudioManager.play("altar_activado", 1.45, -3.0)

	var radio_pull: float = 8.5
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if e is Node3D and is_instance_valid(e):
			var dist = global_position.distance_to(e.global_position)
			if dist <= radio_pull and dist > 0.4:
				e.set_meta("marcado_gravitatorio", true)
				var dir_pull = (global_position - e.global_position).normalized()
				dir_pull.y = 0.0
				if e.has_method("aplicar_knockback"):
					e.aplicar_knockback(dir_pull * 6.5)
				elif "velocity" in e:
					e.velocity += dir_pull * 6.5

func _crear_zona_voltaica_suelo() -> void:
	var arena = get_parent()
	if arena == null:
		return

	var zona = Area3D.new()
	zona.name = "ZonaVoltaicaCometa"
	zona.position = Vector3(global_position.x, 0.06, global_position.z)

	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 1.85
	cyl.height = 0.6
	col.shape = cyl
	zona.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var disc = CylinderMesh.new()
	disc.top_radius = 1.85
	disc.bottom_radius = 1.85
	disc.height = 0.04
	mesh_inst.mesh = disc

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.04, 0.55, 0.75, 0.22)
	mat.emission_enabled = true
	mat.emission = Color(0.10, 0.70, 0.90)
	mat.emission_energy_multiplier = 0.85
	mat.metallic = 0.3
	mat.roughness = 0.2
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_inst.material_override = mat
	zona.add_child(mesh_inst)

	arena.add_child(zona)

	var dano_zona = 14.0 * 0.65
	zona.body_entered.connect(func(cuerpo: Node):
		if cuerpo.is_in_group("enemigos") and cuerpo.has_method("recibir_dano"):
			cuerpo.recibir_dano(dano_zona, false)
			if cuerpo.has_method("aplicar_knockback"):
				var dir_emp = (cuerpo.global_position - zona.global_position).normalized()
				dir_emp.y = 0.0
				cuerpo.aplicar_knockback(dir_emp * 3.5)
	)

	var tw = zona.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 1.2).set_delay(0.3)
	tw.chain().tween_callback(zona.queue_free)

func activar_bloqueo_cadenas():
	if estado_actual == EstadoBoton.ENCADENADO:
		return

	estado_actual = EstadoBoton.ENCADENADO
	emit_signal("estado_cambiado", estado_actual)
	cadenas_activas = 3
	_sincronizar_telemetria_termica()

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
	calor_actual = 0.0
	sobrecalentado = false
	_tiempo_sin_clic = 0.0
	_sincronizar_telemetria_termica()
	emit_signal("estado_cambiado", estado_actual)

	var tiene_sobrecarga_sin_freno: bool = false
	if jugador != null and is_instance_valid(jugador):
		if "bendiciones_corruptas" in jugador and jugador.bendiciones_corruptas.has("corrupta_sobrecarga_sin_freno"):
			tiene_sobrecarga_sin_freno = true
		elif "bendiciones_run" in jugador and jugador.bendiciones_run.has("corrupta_sobrecarga_sin_freno"):
			tiene_sobrecarga_sin_freno = true

	_tiempo_frenesi = 24.0 if tiene_sobrecarga_sin_freno else 12.0

	for p in palancas_instancias:
		if p != null and is_instance_valid(p):
			p.desactivar_silencioso()

	_detonar_onda_choque(true, true, false)
	AudioManager.play("alerta_oleada", 1.8, 4.0)

	if luz_nucleo != null:
		luz_nucleo.light_color = Color(1.0, 0.85, 0.15)
		luz_nucleo.light_energy = 5.5

	rapidez_movimiento = rapidez_base * 1.35
	var mult_txt = 5 if tiene_sobrecarga_sin_freno else 3
	_spawn_floating_text("🔥 ¡SOBRECARGA LIBERADA! (x%d CLICS & ORO - %ds) 🔥" % [mult_txt, int(_tiempo_frenesi)])

func _terminar_frenesi():
	estado_actual = EstadoBoton.ACTIVO
	_sincronizar_telemetria_termica()
	emit_signal("estado_cambiado", estado_actual)
	rapidez_movimiento = rapidez_base

	var col_luz = BunkerVisualKit.COL_CYAN_ELECTRIC
	if chasis_actual == "gravitatorio":
		col_luz = Color(0.68, 0.20, 0.95)
	elif chasis_actual == "cometa":
		col_luz = Color(0.20, 0.95, 0.92)

	if luz_nucleo != null:
		luz_nucleo.light_color = col_luz
		luz_nucleo.light_energy = 2.8

	_spawn_floating_text("Núcleo estabilizado a velocidad normal.")

func _ejecutar_teletransporte_seguro():
	if _en_teletransporte or estado_actual == EstadoBoton.ENCADENADO:
		return

	_en_teletransporte = true
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3(0.08, 0.08, 0.08), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	if not is_instance_valid(self) or not is_inside_tree():
		return

	indice_ruta = (indice_ruta + randi_range(2, 4)) % ruta.size()
	if indice_ruta == 0:
		indice_ruta = 1
	global_position = ruta[indice_ruta]

	var tw_pop = create_tween()
	tw_pop.tween_property(self, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_detonar_onda_choque(false, false, false)
	_en_teletransporte = false

func _detonar_onda_choque(es_supernova: bool, es_perfecto: bool = false, es_sobrecarga_termica: bool = false):
	var bonus_onda: Dictionary = {}
	if jugador != null and is_instance_valid(jugador) and jugador.has_method("obtener_bonus_onda_clic"):
		bonus_onda = jugador.obtener_bonus_onda_clic()

	var radio_extra: float = float(bonus_onda.get("radio_extra", 0.0))
	var radio_mult: float = float(bonus_onda.get("radio_mult", 1.0))
	var mult_empuje: float = float(bonus_onda.get("mult_empuje", 1.0))
	var mult_dano: float = float(bonus_onda.get("mult_dano_clic", bonus_onda.get("dano_mult", 1.0)))
	var es_crit: bool = bool(bonus_onda.get("es_critico", false)) or es_perfecto or es_sobrecarga_termica
	var mult_termico: float = 1.5 if es_sobrecarga_termica else 1.0

	var radio_efectivo = (radio_onda_choque + radio_extra) * radio_mult * (2.2 if es_supernova else (1.25 if es_perfecto else 1.0)) * mult_termico * mult_radio_onda_chasis
	var empuje_efectivo = empuje_onda * mult_empuje * (2.2 if es_supernova else (1.35 if es_perfecto else 1.0)) * (1.25 if es_sobrecarga_termica else 1.0)
	var dano_base = (28.0 if es_supernova else 15.0) * mult_dano * (1.35 if es_perfecto else 1.0) * mult_termico * float(factor_chasis_cometa)

	var enemigos = get_tree().get_nodes_in_group("enemigos").duplicate()
	for r in get_tree().get_nodes_in_group("rompibles"):
		if not enemigos.has(r):
			enemigos.append(r)
	var alcanzados_onda: int = 0
	for e in enemigos:
		if e is Node3D and is_instance_valid(e):
			var dist = global_position.distance_to(e.global_position)
			if dist <= radio_efectivo:
				if e.has_method("desactivar_escudo_runico"):
					e.desactivar_escudo_runico(8.0)
				if e.has_method("recibir_dano"):
					alcanzados_onda += 1
					e.recibir_dano(dano_base, "onda", es_crit)
					if jugador != null and is_instance_valid(jugador) and jugador.has_method("registrar_dano_telemetria"):
						jugador.registrar_dano_telemetria("onda", dano_base)
				var dir = (e.global_position - global_position)
				dir.y = 0.0
				if dir.length_squared() > 0.001:
					dir = dir.normalized()
				else:
					dir = Vector3.FORWARD
				if e.has_method("aplicar_knockback"):
					e.aplicar_knockback(dir * empuje_efectivo)
				elif "velocity" in e:
					e.velocity += dir * empuje_efectivo
	if alcanzados_onda > 0:
		var fav_mgr = get_tree().get_first_node_in_group("favor_emperador_manager")
		if fav_mgr != null and fav_mgr.has_method("notificar_electro_hilo"):
			fav_mgr.notificar_electro_hilo(alcanzados_onda)

func _spawn_floating_text(txt: String):
	var pool = get_tree().get_first_node_in_group("damage_numbers")
	if pool != null and pool.has_method("mostrar_texto"):
		pool.mostrar_texto(global_position + Vector3(0, 1.9, 0), txt, Color(0.25, 0.95, 1.0), 1.15)
		return
	var escena = load("res://damage_number_3d.tscn")
	if escena != null and get_parent() != null:
		var num = escena.instantiate()
		get_parent().add_child(num)
		num.global_position = global_position + Vector3(0, 1.9, 0)
		num.iniciar(0, true, false, txt)
