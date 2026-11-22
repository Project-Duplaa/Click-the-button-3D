extends Area3D

## Altar Rúnico Industrial — Terminal de Contención Búnker Sci-Fi (Godot 4.7.2)
## Bloquea activación remota a larga distancia: requiere proximidad <= 4.5m (_jugador_cerca).
## 3 estados visuales claros desde cámara -40°: STANDBY / PROXIMIDAD (<= 4.5m) / ACTIVO.

signal activado(id_altar: int)

const AudioManager = preload("res://audio_manager.gd")
const Kit = preload("res://bunker_visual_kit.gd")
const ArenaColiseo = preload("res://arena_coliseo.gd")

const RADIO_PROXIMIDAD: float = 4.5
const ALTURA_NUCLEO_BASE: float = 2.02

@export var id_altar: int = 1
@export var nombre_altar: String = "Altar de la Resonancia"

var desbloqueado: bool = true
var activo: bool = false
var _reloj_flotacion: float = 0.0
var _reloj_pulso: float = 0.0
var _jugador_cerca: bool = false
var _mouse_hover: bool = false
var _prox_blend: float = 0.0
var _modo_esencial: bool = false

func actualizar_modo_esencial(activo_esencial: bool) -> void:
	_modo_esencial = activo_esencial
	_actualizar_etiqueta()

@onready var pedestal: Node3D = $Pedestal
@onready var modelo_altar: Node3D = $Pedestal/ModeloHazardAltar
@onready var runa_cristal: MeshInstance3D = $Pedestal/RunaCristal
@onready var holo_inner_ring: MeshInstance3D = $Pedestal/HoloCoreInnerRing
@onready var holo_outer_ring: MeshInstance3D = $Pedestal/HoloCoreOuterRing
@onready var luz_runa: OmniLight3D = $Pedestal/LuzRuna
@onready var etiqueta_altar: Label3D = get_node_or_null("Pedestal/EtiquetaAltar")
@onready var columna_mesh: MeshInstance3D = get_node_or_null("Pedestal/Columna")

var _ground_ring: MeshInstance3D = null
var _mat_ground_ring: ShaderMaterial = null
var _mat_beacon: StandardMaterial3D = null
var _mat_cyan_pod: StandardMaterial3D = null
var _mat_screen: ShaderMaterial = null
var _mat_holo_core: ShaderMaterial = null
var _mat_ring_inner: StandardMaterial3D = null
var _mat_ring_outer: StandardMaterial3D = null

func _ready():
	add_to_group("altares_runicos")
	add_to_group("indicadores_tacticos")
	global_position = ArenaColiseo.clamping_y_ajustar_a_suelo(global_position, 1.6, 0.0)
	input_ray_pickable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	_inicializar_visual_bunker()
	_actualizar_etiqueta()

func _inicializar_visual_bunker() -> void:
	# 1. Anillo de contención en suelo (2.2 m) con hazard_ground_ring.gdshader
	if pedestal != null:
		_ground_ring = Kit.create_hazard_ground_ring(
			2.2,
			Kit.COL_PLASMA_ORANGE,
			Kit.COL_CYAN_ELECTRIC,
			0.80,
			0.96,
			0.35,
			0.05
		)
		pedestal.add_child(_ground_ring)
		_mat_ground_ring = _ground_ring.material_override as ShaderMaterial
		if _mat_ground_ring != null:
			_mat_ground_ring.set_shader_parameter("segment_count", 24.0)
			_mat_ground_ring.set_shader_parameter("rotation_speed", 0.35)
			_mat_ground_ring.set_shader_parameter("pulse_frequency", 1.6)
			_mat_ground_ring.set_shader_parameter("pulse_intensity", 0.18)

	# 2. Materiales únicos por instancia para partes dinámicas y overrides del .glb
	_mat_beacon = Kit.make_emissive_mat(Kit.COL_PLASMA_ORANGE, 1.1, Color(0.35, 0.12, 0.04), 0.15, 0.22)
	_mat_cyan_pod = Kit.make_emissive_mat(Kit.COL_CYAN_ELECTRIC, 0.45, Color(0.05, 0.28, 0.32), 0.15, 0.22)
	_mat_screen = Kit.create_hologram_material(
		Color(0.95, 0.52, 0.08, 1.0),
		Color(1.0, 0.80, 0.38, 1.0),
		0.85,
		28.0,
		1.6
	)

	if modelo_altar != null:
		Kit.override_glb_hierarchy(modelo_altar, {
			"Altar_Base": Kit.get_concrete_base_mat(),
			"Altar_Cabinet": Kit.get_chassis_mat(),
			"Side_Panel_*": Kit.get_armor_grey_mat(),
			"Left_Deck_Riser": Kit.get_armor_grey_mat(),
			"Right_Deck_Riser": Kit.get_armor_grey_mat(),
			"Operator_Desk_Slope": Kit.get_armor_grey_mat(),
			"Keyboard_Matrix": Kit.get_chassis_mat(),
			"Monitor_Arm_Pole": Kit.get_titanium_mat(),
			"Terminal_Monitor_Bezel": Kit.get_chassis_mat(),
			"Floor_Cable_*": Kit.get_rubber_conduit_mat(),
		}, true)
		Kit.set_glb_node_material(modelo_altar, "Emergency_Red_Beacon", _mat_beacon, false)
		Kit.set_glb_node_material(modelo_altar, "Activation_Cyan_Pod", _mat_cyan_pod, false)
		Kit.set_glb_node_material(modelo_altar, "Terminal_Screen_Display", _mat_screen, false)

	# 3. Núcleo holográfico y anillos giroscópicos por instancia
	_mat_holo_core = Kit.create_hologram_material(
		Kit.COL_PLASMA_ORANGE,
		Kit.COL_HAZARD_YELLOW,
		1.25,
		34.0,
		2.0
	)
	if runa_cristal != null:
		runa_cristal.position = Vector3(0.0, ALTURA_NUCLEO_BASE, 0.05)
		runa_cristal.material_override = _mat_holo_core

	_mat_ring_inner = Kit.make_emissive_mat(Kit.COL_PLASMA_ORANGE, 1.35, Kit.COL_TITANIUM_BRUSH, 0.85, 0.25)
	if holo_inner_ring != null:
		holo_inner_ring.position = Vector3(0.0, ALTURA_NUCLEO_BASE, 0.05)
		holo_inner_ring.material_override = _mat_ring_inner

	_mat_ring_outer = Kit.make_emissive_mat(Kit.COL_CRYO_BLUE, 1.0, Kit.COL_TITANIUM_BRUSH, 0.85, 0.25)
	if holo_outer_ring != null:
		holo_outer_ring.position = Vector3(0.0, ALTURA_NUCLEO_BASE, 0.05)
		holo_outer_ring.material_override = _mat_ring_outer

	if etiqueta_altar != null:
		Kit.apply_tactical_label_style(etiqueta_altar, 28, Color(0.88, 0.92, 0.98))

func _physics_process(delta: float):
	if not desbloqueado:
		return
	_reloj_pulso += delta

	# Verificar proximidad real al jugador (4.5 m)
	var pj := get_tree().get_first_node_in_group("player") as Node3D
	if pj == null:
		pj = get_tree().get_first_node_in_group("jugador") as Node3D
	if pj != null and is_instance_valid(pj):
		_jugador_cerca = global_position.distance_to(pj.global_position) <= RADIO_PROXIMIDAD and absf(global_position.y - pj.global_position.y) <= 1.25
	else:
		_jugador_cerca = false

	var target_prox := 1.0 if (_jugador_cerca or _mouse_hover) and not activo else 0.0
	_prox_blend = lerpf(_prox_blend, target_prox, minf(1.0, delta * 7.0))

	# Velocidades de flotación y giroscopio según estado (STANDBY / PROXIMIDAD / ACTIVO)
	var float_speed := 4.0 if activo else lerpf(1.7, 3.0, _prox_blend)
	var float_amp := 0.075 if activo else lerpf(0.045, 0.065, _prox_blend)
	_reloj_flotacion += delta * float_speed
	var y_core := ALTURA_NUCLEO_BASE + sin(_reloj_flotacion) * float_amp

	if runa_cristal != null:
		runa_cristal.rotate_y(delta * (3.6 if activo else lerpf(0.9, 2.2, _prox_blend)))
		runa_cristal.position.y = y_core

	if holo_inner_ring != null:
		holo_inner_ring.position.y = y_core
		var spd_in := 4.4 if activo else lerpf(0.95, 2.5, _prox_blend)
		holo_inner_ring.rotate_object_local(Vector3.UP, delta * spd_in)
		holo_inner_ring.rotate_y(delta * (1.1 if activo else 0.35))

	if holo_outer_ring != null:
		holo_outer_ring.position.y = y_core
		var spd_out := 3.2 if activo else lerpf(0.65, 1.85, _prox_blend)
		holo_outer_ring.rotate_object_local(Vector3.UP, -delta * spd_out)
		holo_outer_ring.rotate_y(-delta * (0.85 if activo else 0.25))

	_actualizar_estado_visual_dinamico()
	_actualizar_etiqueta()

func _actualizar_estado_visual_dinamico() -> void:
	if activo:
		return

	# Transición suave STANDBY <-> PROXIMIDAD
	var pulse_freq := lerpf(2.2, 8.5, _prox_blend)
	var pulse_01 := 0.5 + 0.5 * sin(_reloj_pulso * pulse_freq)

	if _mat_beacon != null:
		var col_b := Kit.COL_PLASMA_ORANGE.lerp(Kit.COL_CRIMSON_ALERT, _prox_blend)
		_mat_beacon.albedo_color = col_b.darkened(0.35)
		_mat_beacon.emission = col_b
		_mat_beacon.emission_energy_multiplier = lerpf(0.6, 1.3, _prox_blend) + pulse_01 * lerpf(0.8, 1.7, _prox_blend)

	if _mat_cyan_pod != null:
		_mat_cyan_pod.emission_energy_multiplier = lerpf(0.45, 1.85, _prox_blend) + pulse_01 * (0.45 * _prox_blend)

	if _mat_screen != null:
		var scr_col := Color(0.95, 0.52, 0.08).lerp(Kit.COL_CRYO_BLUE, _prox_blend * 0.75)
		_mat_screen.set_shader_parameter("holo_color", scr_col)
		_mat_screen.set_shader_parameter("rim_color", Color(1.0, 0.80, 0.38).lerp(Color(0.80, 0.99, 1.0), _prox_blend * 0.8))
		_mat_screen.set_shader_parameter("energy", lerpf(0.85, 1.85, _prox_blend))
		_mat_screen.set_shader_parameter("scanline_speed", lerpf(1.6, 3.2, _prox_blend))

	if _mat_holo_core != null:
		var holo_col := Kit.COL_PLASMA_ORANGE.lerp(Kit.COL_CRYO_BLUE, _prox_blend * 0.85)
		var rim_col := Kit.COL_HAZARD_YELLOW.lerp(Color(0.82, 0.99, 1.0), _prox_blend)
		_mat_holo_core.set_shader_parameter("holo_color", holo_col)
		_mat_holo_core.set_shader_parameter("rim_color", rim_col)
		_mat_holo_core.set_shader_parameter("energy", lerpf(1.25, 2.05, _prox_blend))
		_mat_holo_core.set_shader_parameter("scanline_speed", lerpf(2.0, 3.5, _prox_blend))

	if _mat_ring_inner != null:
		var col_in := Kit.COL_PLASMA_ORANGE.lerp(Kit.COL_CYAN_ELECTRIC, _prox_blend)
		_mat_ring_inner.emission = col_in
		_mat_ring_inner.emission_energy_multiplier = lerpf(1.3, 2.2, _prox_blend)

	if _mat_ring_outer != null:
		var col_out := Kit.COL_CRYO_BLUE.lerp(Kit.COL_CYAN_ELECTRIC, _prox_blend)
		_mat_ring_outer.emission = col_out
		_mat_ring_outer.emission_energy_multiplier = lerpf(0.95, 1.85, _prox_blend)

	if _mat_ground_ring != null:
		_mat_ground_ring.set_shader_parameter("active_state", _prox_blend * 0.65)
		_mat_ground_ring.set_shader_parameter("rotation_speed", lerpf(0.35, 1.05, _prox_blend))
		_mat_ground_ring.set_shader_parameter("track_alpha", lerpf(0.35, 0.60, _prox_blend))
		_mat_ground_ring.set_shader_parameter("inner_fill_alpha", lerpf(0.05, 0.12, _prox_blend))
		_mat_ground_ring.set_shader_parameter("pulse_frequency", lerpf(1.6, 3.4, _prox_blend))
		_mat_ground_ring.set_shader_parameter("pulse_intensity", lerpf(0.18, 0.30, _prox_blend))

	if luz_runa != null:
		luz_runa.light_color = Color(1.0, 0.58, 0.14).lerp(Kit.COL_CYAN_ELECTRIC, _prox_blend)
		luz_runa.light_energy = lerpf(1.4, 2.2, _prox_blend)

func _actualizar_etiqueta() -> void:
	if etiqueta_altar == null:
		return
	if _modo_esencial:
		etiqueta_altar.text = "TERMINAL %02d" % id_altar
		etiqueta_altar.modulate = Kit.COL_CYAN_ELECTRIC if activo else Color(0.70, 0.76, 0.84, 0.85)
		return

	if activo:
		etiqueta_altar.text = "🏛️ TERMINAL %02d/03\n[✅ EN LÍNEA]" % id_altar
		etiqueta_altar.modulate = Kit.COL_CYAN_ELECTRIC
	elif _jugador_cerca:
		etiqueta_altar.text = "🏛️ TERMINAL RÚNICA %02d/03\n[PISA O HAZ CLIC]\n(Puzle: Activa las 3 para Cofre Secreto)" % id_altar
		etiqueta_altar.modulate = Kit.COL_HAZARD_YELLOW
	elif _mouse_hover:
		etiqueta_altar.text = "🏛️ TERMINAL RÚNICA %02d/03\n[ACÉRCATE <= 4.5m]\n(Puzle: Activa las 3)" % id_altar
		etiqueta_altar.modulate = Kit.COL_PLASMA_ORANGE
	else:
		etiqueta_altar.text = "🏛️ TERMINAL RÚNICA %02d/03\n[PUZLE ANCESTRAL]" % id_altar
		etiqueta_altar.modulate = Color(0.70, 0.76, 0.84, 0.85)

func _on_mouse_entered() -> void:
	_mouse_hover = true

func _on_mouse_exited() -> void:
	_mouse_hover = false

func establecer_sellado() -> void:
	desbloqueado = false
	activo = false
	visible = false
	input_ray_pickable = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func desbloquear_terminal() -> void:
	if desbloqueado:
		return
	desbloqueado = true
	visible = true
	input_ray_pickable = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	if pedestal != null:
		pedestal.scale = Vector3(0.1, 0.1, 0.1)
		var tw_desp := create_tween()
		tw_desp.tween_property(pedestal, "scale", Vector3.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var fx_parent: Node = get_parent() if get_parent() != null else self
	Kit.spawn_shockwave_ring(fx_parent, global_position, 0.65, 3.8, Kit.COL_PLASMA_ORANGE, 0.45)
	AudioManager.play("altar_activado", 1.15)
	var pool_dano = get_tree().get_first_node_in_group("damage_numbers") if get_tree() != null else null
	if pool_dano != null and pool_dano.has_method("mostrar_texto"):
		pool_dano.mostrar_texto(global_position + Vector3(0, 2.2, 0), "⚡ ¡TERMINAL %02d DESPLEGADA!" % id_altar, Kit.COL_PLASMA_ORANGE, 1.2)
	_actualizar_etiqueta()

func _on_body_entered(body: Node3D):
	if not desbloqueado or activo:
		return
	if body.is_in_group("player") or body.is_in_group("jugador"):
		_jugador_cerca = true
		activar_altar("Contacto con el custodio")

func _on_body_exited(body: Node3D):
	if body.is_in_group("player") or body.is_in_group("jugador"):
		_jugador_cerca = false

func _on_area_entered(area: Area3D):
	if not desbloqueado or activo:
		return
	if area.is_in_group("boton_movil"):
		activar_altar("Paso del Núcleo Móvil")

func _on_input_event(_cam: Camera3D, event: InputEvent, _pos: Vector3, _norm: Vector3, _shape: int):
	if not desbloqueado or activo:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not _jugador_cerca:
			_mostrar_aviso_lejos()
			return
		get_viewport().set_input_as_handled()
		activar_altar("Interacción mística directa")

func _mostrar_aviso_lejos():
	var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
	if pool_dano != null and pool_dano.has_method("mostrar_texto"):
		pool_dano.mostrar_texto(global_position + Vector3(0, 2.0, 0), "¡Acércate al Altar para activarlo!", Color(1.0, 0.4, 0.4), 1.1)

func activar_altar(_motivo: String = ""):
	if not desbloqueado or activo:
		return
	activo = true
	_actualizar_etiqueta()

	var hud = get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("mostrar_letrero_temporal"):
		hud.mostrar_letrero_temporal(
			"terminal_ancestral",
			"TERMINAL ANCESTRAL ACTIVADA",
			"Activa los 3 pedestales rúnicos (Oleadas 3, 5 y 7) para invocar el Cofre Dorado central.",
			Color(0.28, 0.85, 1.0)
		)

	AudioManager.play("altar_activado", 0.9 + id_altar * 0.15)

	# 1. Flash transitorio de luz (<= 5.5 por 0.08s) -> estabilizado cian (<= 2.8)
	if luz_runa != null:
		luz_runa.light_color = Kit.COL_CYAN_ELECTRIC
		var tw := create_tween()
		tw.tween_property(luz_runa, "light_energy", 5.2, 0.08)
		tw.tween_property(luz_runa, "light_energy", 2.8, 0.35)

	# 2. Onda de choque expansiva en el suelo
	var fx_parent: Node = get_parent() if get_parent() != null else self
	Kit.spawn_shockwave_ring(fx_parent, global_position, 0.85, 5.2, Kit.COL_CYAN_ELECTRIC, 0.55)

	# 3. Transición cromática de todos los emisivos y pantallas a cian eléctrico radiante
	if _mat_beacon != null:
		var tw_b := create_tween().set_parallel(true)
		tw_b.tween_property(_mat_beacon, "albedo_color", Kit.COL_CYAN_ELECTRIC, 0.25)
		tw_b.tween_property(_mat_beacon, "emission", Kit.COL_CYAN_ELECTRIC, 0.25)
		tw_b.tween_property(_mat_beacon, "emission_energy_multiplier", 2.6, 0.25)

	if _mat_cyan_pod != null:
		var tw_pod := create_tween()
		tw_pod.tween_property(_mat_cyan_pod, "emission_energy_multiplier", 4.6, 0.08)
		tw_pod.tween_property(_mat_cyan_pod, "emission_energy_multiplier", 2.8, 0.30)

	if _mat_screen != null:
		_mat_screen.set_shader_parameter("holo_color", Kit.COL_CYAN_ELECTRIC)
		_mat_screen.set_shader_parameter("rim_color", Color(0.85, 1.0, 1.0, 1.0))
		_mat_screen.set_shader_parameter("energy", 2.6)
		_mat_screen.set_shader_parameter("scanline_speed", 3.8)

	if _mat_holo_core != null:
		_mat_holo_core.set_shader_parameter("holo_color", Kit.COL_CYAN_ELECTRIC)
		_mat_holo_core.set_shader_parameter("rim_color", Color(0.88, 1.0, 1.0, 1.0))
		_mat_holo_core.set_shader_parameter("energy", 2.8)
		_mat_holo_core.set_shader_parameter("scanline_speed", 4.2)

	if _mat_ring_inner != null:
		var tw_ri := create_tween().set_parallel(true)
		tw_ri.tween_property(_mat_ring_inner, "emission", Kit.COL_CYAN_ELECTRIC, 0.25)
		tw_ri.tween_property(_mat_ring_inner, "emission_energy_multiplier", 2.6, 0.25)

	if _mat_ring_outer != null:
		var tw_ro := create_tween().set_parallel(true)
		tw_ro.tween_property(_mat_ring_outer, "emission", Kit.COL_CRYO_BLUE, 0.25)
		tw_ro.tween_property(_mat_ring_outer, "emission_energy_multiplier", 2.4, 0.25)

	if _mat_ground_ring != null:
		_mat_ground_ring.set_shader_parameter("progress", 1.0)
		_mat_ground_ring.set_shader_parameter("active_state", 1.0)
		_mat_ground_ring.set_shader_parameter("active_color", Kit.COL_CYAN_ELECTRIC)
		_mat_ground_ring.set_shader_parameter("rotation_speed", 1.45)
		_mat_ground_ring.set_shader_parameter("track_alpha", 0.78)
		_mat_ground_ring.set_shader_parameter("inner_fill_alpha", 0.16)
		_mat_ground_ring.set_shader_parameter("pulse_frequency", 2.2)
		_mat_ground_ring.set_shader_parameter("pulse_intensity", 0.22)

	var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
	if pool_dano != null and pool_dano.has_method("mostrar_texto"):
		pool_dano.mostrar_texto(global_position + Vector3(0, 2.2, 0), "⚡ TERMINAL %d/3 ACTIVADA" % id_altar, Color(0.3, 0.9, 1.0), 1.25)

	emit_signal("activado", id_altar)
