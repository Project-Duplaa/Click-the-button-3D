extends Area3D
class_name PalancaBoton

## PalancaBoton — Disyuntor Industrial Búnker Sci-Fi (Godot 4.7.2)
## Se arma cuando el Botón Móvil es encadenado. Alta legibilidad top-down (-40°):
## - Pilar baliza con domo Cone dinámico (apagado -> rojo pulsante -> flash -> verde neón estable)
## - Consola frontal inclinada con franjas ISO 3864 + tira LED + manija T-bar de doble horquilla
## - Haz Fresnel volumétrico sin cortes duros + anillo de contención en el suelo (1.6 m)

signal palanca_activada(id: int)

const AudioManager = preload("res://audio_manager.gd")
const Kit = preload("res://bunker_visual_kit.gd")

@export var id_palanca: int = 1
@export var distancia_max_clic: float = 3.5

var activada: bool = false
var habilitada: bool = false

@onready var luz_indicador: OmniLight3D = $LuzIndicador
@onready var haz_luz: MeshInstance3D = $HazLuz
@onready var manija: Node3D = $BaseControl/Manija
@onready var colision: CollisionShape3D = $CollisionShape3D
@onready var modelo_pilar: Node3D = get_node_or_null("ModeloPilar")
@onready var base_plinth: MeshInstance3D = get_node_or_null("BasePlinth")
@onready var caja_terminal: MeshInstance3D = get_node_or_null("BaseControl/Caja")
@onready var marco_acero: MeshInstance3D = get_node_or_null("BaseControl/MarcoAcero")
@onready var placa_hazard: MeshInstance3D = get_node_or_null("BaseControl/PlacaHazard")
@onready var tira_led: MeshInstance3D = get_node_or_null("BaseControl/TiraLedEstado")
@onready var empunadura: MeshInstance3D = get_node_or_null("BaseControl/Manija/Empunadura")
@onready var etiqueta_terminal: Label3D = get_node_or_null("EtiquetaTerminal")

var _ground_ring: MeshInstance3D = null
var _mat_ground_ring: ShaderMaterial = null
var _mat_haz: ShaderMaterial = null
var _mat_cone: StandardMaterial3D = null
var _mat_led: StandardMaterial3D = null
var _mat_empunadura: StandardMaterial3D = null

var _reloj_pulso: float = 0.0
var _tweens_activos: Array[Tween] = []

func _ready():
	add_to_group("palancas_boton")
	input_ray_pickable = true
	input_event.connect(_on_input_event)
	body_entered.connect(_on_body_entered)

	_inicializar_visual_bunker()
	desactivar_silencioso()

func _inicializar_visual_bunker() -> void:
	# 1. Anillo hazard en suelo (radio 1.6 m)
	_ground_ring = Kit.create_hazard_ground_ring(
		1.6,
		Kit.COL_CRIMSON_ALERT,
		Kit.COL_CRIMSON_ALERT,
		0.80,
		0.96,
		0.48,
		0.08
	)
	add_child(_ground_ring)
	_mat_ground_ring = _ground_ring.material_override as ShaderMaterial
	if _mat_ground_ring != null:
		_mat_ground_ring.set_shader_parameter("segment_count", 18.0)
		_mat_ground_ring.set_shader_parameter("rotation_speed", 0.85)
		_mat_ground_ring.set_shader_parameter("pulse_frequency", 3.6)
		_mat_ground_ring.set_shader_parameter("pulse_intensity", 0.35)

	# 2. Materiales PBR compartidos + instancias dinámicas únicas para este disyuntor
	if base_plinth != null:
		base_plinth.material_override = Kit.get_concrete_base_mat()
	if caja_terminal != null:
		caja_terminal.material_override = Kit.get_chassis_mat()
	if marco_acero != null:
		marco_acero.material_override = Kit.get_armor_grey_mat()
	if placa_hazard != null:
		placa_hazard.material_override = Kit.create_hazard_stripes_material(
			Kit.COL_HAZARD_YELLOW,
			Kit.COL_CARBON_STEEL,
			6.0,
			Vector2(3.6, 1.0)
		)

	_mat_cone = Kit.make_emissive_mat(Kit.COL_CRIMSON_ALERT, 2.8, Color(0.24, 0.04, 0.07), 0.10, 0.15)
	_mat_led = Kit.make_emissive_mat(Kit.COL_CRIMSON_ALERT, 2.8, Color(0.20, 0.05, 0.07), 0.20, 0.25)
	_mat_empunadura = Kit.make_emissive_mat(Kit.COL_CRIMSON_ALERT, 2.6, Color(0.24, 0.05, 0.07), 0.15, 0.28)
	_mat_haz = Kit.create_beam_material(Kit.COL_CRIMSON_ALERT, Color(1.0, 0.80, 0.74, 1.0), 2.6, 0.70)

	if modelo_pilar != null:
		Kit.override_glb_hierarchy(modelo_pilar, {
			"Cylinder*": Kit.get_chassis_mat(),
			"Cylinder_002": Kit.get_armor_grey_mat(),
			"Cylinder_003": Kit.get_armor_grey_mat(),
		}, true)
		Kit.set_glb_node_material(modelo_pilar, "Cone", _mat_cone, false)

	if tira_led != null:
		tira_led.material_override = _mat_led
	if empunadura != null:
		empunadura.material_override = _mat_empunadura
	if haz_luz != null:
		haz_luz.material_override = _mat_haz

	if etiqueta_terminal != null:
		Kit.apply_tactical_label_style(etiqueta_terminal, 30, Kit.COL_CRIMSON_ALERT)

func _physics_process(delta: float):
	if not visible or not habilitada or activada:
		return

	_reloj_pulso += delta * 7.5
	var pulso_01 := 0.5 + 0.5 * sin(_reloj_pulso)
	var energia_sirena := lerpf(1.7, 3.6, pulso_01)

	if _mat_cone != null:
		_mat_cone.emission_energy_multiplier = energia_sirena
	if _mat_led != null:
		_mat_led.emission_energy_multiplier = lerpf(1.8, 3.2, pulso_01)
	if _mat_empunadura != null:
		_mat_empunadura.emission_energy_multiplier = lerpf(1.6, 2.8, pulso_01)
	if luz_indicador != null:
		luz_indicador.light_energy = lerpf(2.2, 3.6, pulso_01)

	var dist_jug := _obtener_distancia_jugador()
	var en_rango := dist_jug <= distancia_max_clic
	if etiqueta_terminal != null:
		if en_rango:
			etiqueta_terminal.text = "DISYUNTOR %02d\n[PULSAR AHORA]" % id_palanca
			etiqueta_terminal.modulate = Kit.COL_HAZARD_YELLOW
		else:
			etiqueta_terminal.text = "DISYUNTOR %02d\n[ACÉRCATE · %.0fm]" % [id_palanca, dist_jug]
			etiqueta_terminal.modulate = Kit.COL_CRIMSON_ALERT

func _obtener_distancia_jugador() -> float:
	if get_tree() == null:
		return 0.0
	var jug := get_tree().get_first_node_in_group("jugador") as Node3D
	if jug == null:
		jug = get_tree().get_first_node_in_group("player") as Node3D
	if jug == null or not is_instance_valid(jug):
		return 0.0
	return Vector2(global_position.x, global_position.z).distance_to(Vector2(jug.global_position.x, jug.global_position.z))

func _registrar_tween(tw: Tween) -> Tween:
	_tweens_activos.append(tw)
	return tw

func _matar_tweens() -> void:
	for tw in _tweens_activos:
		if tw != null and tw.is_valid():
			tw.kill()
	_tweens_activos.clear()

func _aplicar_color_emisivo(mat: StandardMaterial3D, col: Color, energia: float, encendido: bool) -> void:
	if mat == null:
		return
	mat.emission_enabled = encendido
	if encendido:
		mat.albedo_color = col
		mat.emission = col
		mat.emission_energy_multiplier = energia
	else:
		mat.albedo_color = Color(0.14, 0.05, 0.07, 1.0)
		mat.emission = Color.BLACK
		mat.emission_energy_multiplier = 0.0

func armar():
	_matar_tweens()
	activada = false
	habilitada = true
	visible = true
	_reloj_pulso = 0.0

	if colision != null:
		colision.disabled = false

	_aplicar_color_emisivo(_mat_cone, Kit.COL_CRIMSON_ALERT, 2.8, true)
	_aplicar_color_emisivo(_mat_led, Kit.COL_CRIMSON_ALERT, 2.8, true)
	_aplicar_color_emisivo(_mat_empunadura, Kit.COL_CRIMSON_ALERT, 2.6, true)

	if luz_indicador != null:
		luz_indicador.light_color = Kit.COL_CRIMSON_ALERT
		luz_indicador.light_energy = 3.0
		luz_indicador.visible = true

	if haz_luz != null:
		haz_luz.visible = true
		haz_luz.scale = Vector3.ONE
		if _mat_haz != null:
			_mat_haz.set_shader_parameter("beam_color", Kit.COL_CRIMSON_ALERT)
			_mat_haz.set_shader_parameter("core_color", Color(1.0, 0.80, 0.74, 1.0))
			_mat_haz.set_shader_parameter("energy", 2.6)
			_mat_haz.set_shader_parameter("alpha_multiplier", 0.70)

	if _ground_ring != null:
		_ground_ring.visible = true
		_ground_ring.scale = Vector3.ONE
		if _mat_ground_ring != null:
			_mat_ground_ring.set_shader_parameter("overall_alpha", 1.0)
			_mat_ground_ring.set_shader_parameter("base_color", Kit.COL_CRIMSON_ALERT)
			_mat_ground_ring.set_shader_parameter("active_color", Kit.COL_CRIMSON_ALERT)
			_mat_ground_ring.set_shader_parameter("active_state", 1.0)
			_mat_ground_ring.set_shader_parameter("rotation_speed", 0.90)
			_mat_ground_ring.set_shader_parameter("pulse_frequency", 3.6)
			_mat_ground_ring.set_shader_parameter("pulse_intensity", 0.35)

	if manija != null:
		manija.rotation_degrees.x = -40.0

	if etiqueta_terminal != null:
		etiqueta_terminal.text = "DISYUNTOR %02d\n[ACTIVAR]" % id_palanca
		etiqueta_terminal.modulate = Kit.COL_CRIMSON_ALERT

func desactivar_silencioso():
	_matar_tweens()
	activada = false
	habilitada = false
	visible = false

	if colision != null:
		colision.disabled = true

	_aplicar_color_emisivo(_mat_cone, Color.BLACK, 0.0, false)
	_aplicar_color_emisivo(_mat_led, Color.BLACK, 0.0, false)
	_aplicar_color_emisivo(_mat_empunadura, Color.BLACK, 0.0, false)

	if luz_indicador != null:
		luz_indicador.light_energy = 0.0
		luz_indicador.visible = false
	if haz_luz != null:
		haz_luz.visible = false
	if _ground_ring != null:
		_ground_ring.visible = false

func accionar() -> bool:
	if not habilitada or activada:
		return false

	var dist_jug := _obtener_distancia_jugador()
	if dist_jug > distancia_max_clic:
		AudioManager.play("escudo_bloqueo", 1.15)
		_spawn_floating_text("⚠️ ¡Acércate más a la palanca! (%.1fm)" % dist_jug, Kit.COL_HAZARD_YELLOW)
		if manija != null:
			var tw_bloqueo := create_tween()
			tw_bloqueo.tween_property(manija, "rotation_degrees:x", -30.0, 0.05)
			tw_bloqueo.tween_property(manija, "rotation_degrees:x", -40.0, 0.07)
		return false

	activada = true
	_matar_tweens()
	AudioManager.play("altar_activado", 1.4, 0.0)

	# 1. Animación física de la manija T-bar bajando
	if manija != null:
		var tw_manija := _registrar_tween(create_tween())
		tw_manija.tween_property(manija, "rotation_degrees:x", 40.0, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 2. Transición inmediata de sirena Cone, LED y empuñadura: flash -> verde neón #00FF66 estable
	for mat in [_mat_cone, _mat_led, _mat_empunadura]:
		if mat != null:
			mat.emission_enabled = true
			mat.albedo_color = Kit.COL_NEON_GREEN
			mat.emission = Kit.COL_NEON_GREEN
			mat.emission_energy_multiplier = 4.8
			var tw_mat := _registrar_tween(create_tween())
			tw_mat.tween_property(mat, "emission_energy_multiplier", 2.6, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if luz_indicador != null:
		luz_indicador.light_color = Kit.COL_NEON_GREEN
		var tw_luz := _registrar_tween(create_tween())
		tw_luz.tween_property(luz_indicador, "light_energy", 5.2, 0.08)
		tw_luz.tween_property(luz_indicador, "light_energy", 2.4, 0.30)

	# 3. Haz de luz vira brevemente a verde neón y se desvanece suavemente
	if haz_luz != null:
		if _mat_haz != null:
			_mat_haz.set_shader_parameter("beam_color", Kit.COL_NEON_GREEN)
			_mat_haz.set_shader_parameter("core_color", Color(0.82, 1.0, 0.88, 1.0))
		var tw_haz := _registrar_tween(create_tween().set_parallel(true))
		tw_haz.tween_property(haz_luz, "scale:y", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		if _mat_haz != null:
			tw_haz.tween_method(
				func(a: float):
					if is_instance_valid(_mat_haz):
						_mat_haz.set_shader_parameter("alpha_multiplier", a),
				0.70,
				0.0,
				0.30
			)
		tw_haz.chain().tween_callback(func():
			if is_instance_valid(haz_luz):
				haz_luz.visible = false
		)

	# 4. Anillo de suelo se tiñe a verde y hace fade-out limpio + onda de choque
	if _ground_ring != null and _mat_ground_ring != null:
		_mat_ground_ring.set_shader_parameter("base_color", Kit.COL_NEON_GREEN)
		_mat_ground_ring.set_shader_parameter("active_color", Kit.COL_NEON_GREEN)
		_mat_ground_ring.set_shader_parameter("pulse_intensity", 0.10)
		var tw_ring := _registrar_tween(create_tween())
		tw_ring.tween_method(
			func(a: float):
				if is_instance_valid(_mat_ground_ring):
					_mat_ground_ring.set_shader_parameter("overall_alpha", a),
			1.0,
			0.0,
			0.45
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_ring.tween_callback(func():
			if is_instance_valid(_ground_ring):
				_ground_ring.visible = false
		)

	var fx_parent: Node = get_parent() if get_parent() != null else self
	Kit.spawn_shockwave_ring(fx_parent, global_position, 0.55, 3.2, Kit.COL_NEON_GREEN, 0.45)

	if etiqueta_terminal != null:
		etiqueta_terminal.text = "DISYUNTOR %02d\n[EN LÍNEA]" % id_palanca
		etiqueta_terminal.modulate = Kit.COL_NEON_GREEN

	_spawn_floating_text("¡TERMINAL %d ACTIVADO! ⚡" % id_palanca, Kit.COL_NEON_GREEN)
	emit_signal("palanca_activada", id_palanca)
	return true

func _on_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		accionar()

func _on_body_entered(body):
	if body != null and (body.is_in_group("jugador") or body.is_in_group("player")):
		accionar()

func _spawn_floating_text(txt: String, col: Color = Kit.COL_NEON_GREEN):
	var pool = get_tree().get_first_node_in_group("damage_numbers") if get_tree() != null else null
	if pool != null and pool.has_method("mostrar_texto"):
		pool.mostrar_texto(global_position + Vector3(0, 2.2, 0), txt, col, 1.2)
		return
	if get_parent() == null:
		return
	var escena = load("res://damage_number_3d.tscn")
	if escena != null:
		var num = escena.instantiate()
		get_parent().add_child(num)
		num.global_position = global_position + Vector3(0, 2.2, 0)
		num.iniciar(0, true, false, txt)
