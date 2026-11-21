class_name HiloResonancia
extends Node3D

const VfxCombate = preload("res://vfx_combate.gd")

## HiloResonancia — Haz de Resonancia Rúnica (Vínculo Cinemático entre Personaje y BotonMovil)
## Gestiona el rayo 3D de energía continua entre WASD y Clics.
## Aplica daño por tensión, marcas conductivas, imán forzado de drops y detonaciones de sobrecarga.

signal descarga_detonada(enemigos_alcanzados: int, dano_total: int)

@export var ancho_hilo_base: float = 1.25
@export var dano_tick_conductivo: float = 8.0
@export var intervalo_tick: float = 0.20
@export var colapso_vacio: bool = false
@export var bifurcado_faraday: bool = false

var jugador: CharacterBody3D = null
var boton: Area3D = null

var ancho_hilo_actual: float = 1.25
var _reloj_tick: float = 0.0
var _mult_dano_hilo: float = 1.0
var _jaula_faraday_activa: bool = false
var _color_haz_actual: Color = Color(0.2, 0.85, 1.0, 0.85)

# Elementos visuales 3D del rayo
var _mesh_haz: MeshInstance3D = null
var _mesh_funda: MeshInstance3D = null
var _cilindro: CylinderMesh = null
var _cilindro_funda: CylinderMesh = null
var _material_haz: ShaderMaterial = null
var _material_funda: ShaderMaterial = null
var _luz_haz: OmniLight3D = null

func _ready():
	add_to_group("hilo_resonancia")
	ancho_hilo_actual = ancho_hilo_base
	_crear_geometria_haz()
	call_deferred("_conectar_referencias")

func _conectar_referencias():
	jugador = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	boton = get_tree().get_first_node_in_group("boton_movil") as Area3D

func _crear_geometria_haz():
	_mesh_haz = MeshInstance3D.new()
	_mesh_haz.name = "HazVisual"
	_mesh_haz.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	_cilindro = CylinderMesh.new()
	_cilindro.top_radius = 0.055
	_cilindro.bottom_radius = 0.055
	_cilindro.height = 1.0
	_cilindro.radial_segments = 10
	_cilindro.cap_top = false
	_cilindro.cap_bottom = false
	_mesh_haz.mesh = _cilindro
	
	_material_haz = ShaderMaterial.new()
	_material_haz.shader = VfxCombate.SHADER_ENERGY_BEAM
	_material_haz.set_shader_parameter("beam_color", _color_haz_actual)
	_material_haz.set_shader_parameter("core_color", Color(0.95, 0.99, 1.0))
	_material_haz.set_shader_parameter("energy", 3.2)
	_material_haz.set_shader_parameter("scroll_speed", 4.5)
	_material_haz.set_shader_parameter("noise_freq", 10.0)
	_material_haz.set_shader_parameter("core_width", 0.42)
	_material_haz.set_shader_parameter("end_fade", 0.03)
	_mesh_haz.material_override = _material_haz
	add_child(_mesh_haz)

	_mesh_funda = MeshInstance3D.new()
	_mesh_funda.name = "FundaResonancia"
	_mesh_funda.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cilindro_funda = CylinderMesh.new()
	_cilindro_funda.top_radius = 0.14
	_cilindro_funda.bottom_radius = 0.14
	_cilindro_funda.height = 1.0
	_cilindro_funda.radial_segments = 10
	_cilindro_funda.cap_top = false
	_cilindro_funda.cap_bottom = false
	_mesh_funda.mesh = _cilindro_funda

	_material_funda = ShaderMaterial.new()
	_material_funda.shader = VfxCombate.SHADER_ENERGY_BEAM
	_material_funda.set_shader_parameter("beam_color", _color_haz_actual)
	_material_funda.set_shader_parameter("core_color", _color_haz_actual)
	_material_funda.set_shader_parameter("energy", 1.8)
	_material_funda.set_shader_parameter("alpha_mult", 0.58)
	_material_funda.set_shader_parameter("scroll_speed", 7.0)
	_material_funda.set_shader_parameter("noise_freq", 16.0)
	_material_funda.set_shader_parameter("core_width", 0.14)
	_material_funda.set_shader_parameter("end_fade", 0.04)
	_mesh_funda.material_override = _material_funda
	add_child(_mesh_funda)
	
	_luz_haz = OmniLight3D.new()
	_luz_haz.light_color = Color(0.2, 0.85, 1.0)
	_luz_haz.light_energy = 1.8
	_luz_haz.omni_range = 4.0
	add_child(_luz_haz)

func _process(_delta: float):
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("player") as CharacterBody3D
		if jugador == null:
			jugador = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
	if boton == null or not is_instance_valid(boton):
		boton = get_tree().get_first_node_in_group("boton_movil") as Area3D
		
	if jugador == null or boton == null:
		if _mesh_haz != null:
			_mesh_haz.visible = false
		if _mesh_funda != null:
			_mesh_funda.visible = false
		return
		
	_mesh_haz.visible = true
	if _mesh_funda != null:
		_mesh_funda.visible = true
	
	var pos_a = jugador.global_position + Vector3(0.0, 0.9, 0.0)
	var pos_b = boton.global_position + Vector3(0.0, 0.5, 0.0)
	
	_actualizar_geometria_haz(pos_a, pos_b)
	_actualizar_color_por_fiebre()

func _physics_process(delta: float):
	if jugador == null or boton == null:
		return
		
	_reloj_tick -= delta
	if _reloj_tick <= 0.0:
		_reloj_tick = intervalo_tick
		_procesar_contacto_hilo()

func _actualizar_geometria_haz(pos_a: Vector3, pos_b: Vector3):
	var vec = pos_b - pos_a
	var dist = vec.length()
	if dist < 0.05:
		_mesh_haz.visible = false
		if _mesh_funda != null:
			_mesh_funda.visible = false
		return
		
	var punto_medio = (pos_a + pos_b) * 0.5
	_mesh_haz.global_position = punto_medio
	
	var dir = vec.normalized()
	var up_ref = Vector3.UP if abs(dir.y) < 0.99 else Vector3.FORWARD
	var right = dir.cross(up_ref).normalized()
	var fwd = right.cross(dir).normalized()
	var b := Basis(right, dir, fwd)
	_mesh_haz.global_transform.basis = b
	_cilindro.height = dist

	if _mesh_funda != null and _cilindro_funda != null:
		_mesh_funda.global_position = punto_medio
		_mesh_funda.global_transform.basis = b
		_cilindro_funda.height = dist
	
	if _luz_haz != null:
		_luz_haz.global_position = punto_medio

func _actualizar_color_por_fiebre():
	var nivel_fiebre = 0
	if jugador != null and "nivel_fiebre" in jugador:
		nivel_fiebre = int(jugador.nivel_fiebre)
		
	match nivel_fiebre:
		0, 1:
			_color_haz_actual = Color(0.18, 0.88, 1.0, 0.90)
		2:
			_color_haz_actual = Color(0.32, 0.62, 1.0, 0.95)
		3, 4:
			_color_haz_actual = Color(0.82, 0.28, 1.0, 0.98)
		_:
			_color_haz_actual = Color(1.0, 0.42, 0.14, 1.0)
			
	var vel_flujo: float = 4.5 + float(nivel_fiebre) * 1.4
	if _material_haz != null:
		_material_haz.set_shader_parameter("beam_color", _color_haz_actual)
		_material_haz.set_shader_parameter("scroll_speed", vel_flujo)
	if _material_funda != null:
		_material_funda.set_shader_parameter("beam_color", _color_haz_actual)
		_material_funda.set_shader_parameter("core_color", _color_haz_actual)
		_material_funda.set_shader_parameter("scroll_speed", vel_flujo * 1.4)
	if _luz_haz != null:
		_luz_haz.light_color = _color_haz_actual

func _distancia_a_segmento_xz(p: Vector3, a: Vector3, b: Vector3) -> float:
	var p2 = Vector2(p.x, p.z)
	var a2 = Vector2(a.x, a.z)
	var b2 = Vector2(b.x, b.z)
	var v = b2 - a2
	var w = p2 - a2
	var c1 = w.dot(v)
	if c1 <= 0.0:
		return w.length()
	var c2 = v.dot(v)
	if c2 <= c1:
		return (p2 - b2).length()
	var b_factor = c1 / c2
	var proy = a2 + b_factor * v
	return (p2 - proy).length()

func _procesar_contacto_hilo():
	var pos_a = jugador.global_position + Vector3(0.0, 0.9, 0.0)
	var pos_b = boton.global_position + Vector3(0.0, 0.5, 0.0)
	var ancho_efectivo = ancho_hilo_actual
	
	var enemigos = get_tree().get_nodes_in_group("enemies")
	if enemigos.is_empty():
		enemigos = get_tree().get_nodes_in_group("enemigos")
		
	for e in enemigos:
		if is_instance_valid(e) and e is Node3D:
			var dist = _distancia_a_segmento_xz(e.global_position, pos_a, pos_b)
			if dist <= ancho_efectivo:
				if e.has_method("aplicar_marca_conductiva"):
					e.aplicar_marca_conductiva(2.5)
					
				if (_jaula_faraday_activa or bifurcado_faraday) and e.has_method("recibir_dano"):
					var dmg = int(maxf(1.0, dano_tick_conductivo * _mult_dano_hilo))
					e.recibir_dano(dmg)
					if jugador != null and is_instance_valid(jugador) and jugador.has_method("registrar_dano_telemetria"):
						jugador.registrar_dano_telemetria("hilo", float(dmg))
	
	var drops = get_tree().get_nodes_in_group("drops")
	for d in drops:
		if is_instance_valid(d) and d is Node3D:
			var dist_drop = _distancia_a_segmento_xz(d.global_position, pos_a, pos_b)
			if dist_drop <= ancho_efectivo + 0.6:
				if d.has_method("activar_iman_forzado"):
					d.activar_iman_forzado()

func disparar_descarga_clic(dano_base: int, es_critico_perfecto: bool = false, nivel_fiebre: int = 0) -> int:
	if jugador == null or boton == null:
		return 0
		
	var pos_a = jugador.global_position + Vector3(0.0, 0.9, 0.0)
	var pos_b = boton.global_position + Vector3(0.0, 0.5, 0.0)
	var distancia_tether = pos_a.distance_to(pos_b)
	
	var mult_tension = 1.0
	if distancia_tether >= 10.0 and distancia_tether <= 24.0:
		mult_tension = 1.50
	elif distancia_tether > 24.0:
		mult_tension = 1.65
	else:
		mult_tension = 1.0 + (distancia_tether / 10.0) * 0.40
		
	var mult_crit = 2.2 if es_critico_perfecto else 1.0
	var mult_fiebre = 1.0 + (nivel_fiebre * 0.30)
	var dano_descarga = int(ceil(dano_base * mult_tension * mult_crit * mult_fiebre * _mult_dano_hilo))
	
	var r_base: float = 0.055 * (ancho_hilo_actual / ancho_hilo_base)
	var r_funda_base: float = 0.14 * (ancho_hilo_actual / ancho_hilo_base)
	var color_flash: Color = Color(1.0, 0.9, 0.25) if es_critico_perfecto else _color_haz_actual
	if _material_haz != null:
		var pico_en := 5.8 if es_critico_perfecto else 4.6
		_material_haz.set_shader_parameter("energy", pico_en)
		if _material_funda != null:
			_material_funda.set_shader_parameter("energy", pico_en * 0.72)

	if _cilindro != null or _material_haz != null or _luz_haz != null:
		var tw = create_tween().set_parallel(true)
		var hay_fase_exp := _cilindro != null or _cilindro_funda != null or _luz_haz != null
		if _cilindro != null:
			tw.tween_property(_cilindro, "top_radius", r_base * 3.6, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(_cilindro, "bottom_radius", r_base * 3.6, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if _cilindro_funda != null:
			tw.tween_property(_cilindro_funda, "top_radius", r_funda_base * 2.9, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(_cilindro_funda, "bottom_radius", r_funda_base * 2.9, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if _luz_haz != null:
			tw.tween_property(_luz_haz, "light_energy", 6.0, 0.05)

		if hay_fase_exp:
			tw.chain()
		if _cilindro != null:
			tw.tween_property(_cilindro, "top_radius", r_base, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_property(_cilindro, "bottom_radius", r_base, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		if _cilindro_funda != null:
			tw.tween_property(_cilindro_funda, "top_radius", r_funda_base, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_property(_cilindro_funda, "bottom_radius", r_funda_base, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		if _material_haz != null:
			tw.tween_method(
				func(en: float):
					if is_instance_valid(_material_haz):
						_material_haz.set_shader_parameter("energy", en)
					if is_instance_valid(_material_funda):
						_material_funda.set_shader_parameter("energy", en * 0.72),
				5.8 if es_critico_perfecto else 4.6,
				3.2,
				0.16
			)
		if _luz_haz != null:
			tw.tween_property(_luz_haz, "light_energy", 1.8, 0.14)

	VfxCombate.spawn_rayo_segmento(get_parent(), pos_a, pos_b, color_flash, Color.WHITE, 0.14 if es_critico_perfecto else 0.10, 0.16, 0.28)
		
	var enemigos = get_tree().get_nodes_in_group("enemies")
	if enemigos.is_empty():
		enemigos = get_tree().get_nodes_in_group("enemigos")
		
	var radio_impacto = 1.65 * (ancho_hilo_actual / ancho_hilo_base)
	var punto_medio = (pos_a + pos_b) * 0.5
	var dir_segmento = (pos_b - pos_a).normalized()
	var dir_perpendicular = Vector3(-dir_segmento.z, 0.0, dir_segmento.x)
	
	var total_alcanzados = 0
	var dano_acumulado = 0
	
	for e in enemigos:
		if is_instance_valid(e) and e is Node3D:
			var dist = _distancia_a_segmento_xz(e.global_position, pos_a, pos_b)
			if dist <= radio_impacto:
				total_alcanzados += 1
				dano_acumulado += dano_descarga
				
				if e.has_method("recibir_dano"):
					e.recibir_dano(dano_descarga, "boton_hilo", es_critico_perfecto)
				VfxCombate.spawn_impacto(get_parent(), e.global_position + Vector3(0.0, 1.0, 0.0), color_flash, Color.WHITE, 0.95, es_critico_perfecto)
					
				var fuerza_empuje = 14.0 * mult_crit
				var dir_empuje: Vector3
				if colapso_vacio:
					dir_empuje = (punto_medio - e.global_position).normalized()
					dir_empuje.y = 0.0
				else:
					var a_enemigo = e.global_position - pos_a
					a_enemigo.y = 0.0
					var signo = 1.0 if dir_perpendicular.dot(a_enemigo) >= 0.0 else -1.0
					dir_empuje = dir_perpendicular * signo
					
				if e.has_method("aplicar_knockback"):
					e.aplicar_knockback(dir_empuje * fuerza_empuje)
					
	if dano_acumulado > 0 and jugador != null and is_instance_valid(jugador) and jugador.has_method("registrar_dano_telemetria"):
		jugador.registrar_dano_telemetria("hilo", float(dano_acumulado))
	if total_alcanzados > 0:
		var fav_mgr = get_tree().get_first_node_in_group("favor_emperador_manager")
		if fav_mgr != null and fav_mgr.has_method("notificar_electro_hilo"):
			fav_mgr.notificar_electro_hilo(total_alcanzados)
	descarga_detonada.emit(total_alcanzados, dano_acumulado)
	return total_alcanzados

func aplicar_mejora_hilo(id_bendicion: String, nivel: int):
	match id_bendicion:
		"sobrecarga_hilo":
			_mult_dano_hilo = 1.0 + (nivel * 0.35)
			ancho_hilo_actual = ancho_hilo_base * (1.0 + nivel * 0.20)
			if _cilindro != null:
				_cilindro.top_radius = 0.055 * (1.0 + nivel * 0.20)
				_cilindro.bottom_radius = 0.055 * (1.0 + nivel * 0.20)
			if _cilindro_funda != null:
				_cilindro_funda.top_radius = 0.14 * (1.0 + nivel * 0.20)
				_cilindro_funda.bottom_radius = 0.14 * (1.0 + nivel * 0.20)
		"sinergia_jaula_faraday":
			_jaula_faraday_activa = true
			bifurcado_faraday = true
			dano_tick_conductivo = 16.0
		"sinergia_singularidad_cursor":
			colapso_vacio = true
