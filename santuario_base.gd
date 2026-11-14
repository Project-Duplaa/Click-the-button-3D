extends Area3D
class_name SantuarioBase

## SantuarioBase - Clase base interactuable del Sistema de Fortuna en la arena 3D.
## Soporta clic directo (input_event + raycast _unhandled_input), verificación de rango,
## cobro de Denarios, etiqueta 3D billboard, luz atmosférica, texto flotante y consumo seguro.

signal activado(santuario)

const AudioManager = preload("res://audio_manager.gd")
const ESCENA_TEXTO_3D = preload("res://damage_number_3d.tscn")

@export var nombre_santuario: String = "Santuario"
@export var costo_denarios: int = 0
@export var radio_interaccion: float = 5.5
@export var un_solo_uso: bool = true
@export var activacion_por_clic: bool = true
@export var color_luz: Color = Color(1.0, 0.85, 0.35)
@export var altura_etiqueta: float = 2.9

var visual_root: Node3D = null
var colision: CollisionShape3D = null
var luz: OmniLight3D = null
var etiqueta: Label3D = null

var _consumido: bool = false
var _ultimo_click_ms: int = -1000
var _hover: bool = false

func _ready() -> void:
	add_to_group("santuarios")
	input_ray_pickable = true
	monitoring = true
	monitorable = true

	_configurar_santuario()

	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)

	colision = CollisionShape3D.new()
	colision.name = "CollisionShape3D"
	var forma := CylinderShape3D.new()
	forma.radius = 1.25
	forma.height = 2.5
	colision.shape = forma
	colision.position = Vector3(0.0, 1.25, 0.0)
	add_child(colision)

	luz = OmniLight3D.new()
	luz.name = "OmniLight3D"
	luz.light_color = color_luz
	luz.light_energy = 2.4
	luz.omni_range = 7.5
	luz.position = Vector3(0.0, 1.9, 0.0)
	add_child(luz)

	etiqueta = Label3D.new()
	etiqueta.name = "EtiquetaSantuario"
	etiqueta.position = Vector3(0.0, altura_etiqueta, 0.0)
	BunkerVisualKit.apply_tactical_label_style(etiqueta, 36, color_luz.lerp(Color.WHITE, 0.55))
	add_child(etiqueta)

	_construir_visual()
	_actualizar_etiqueta()

	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Animación pop-in al aparecer en la arena
	scale = Vector3(0.05, 0.05, 0.05)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Hook virtual para sobrescribir exports y propiedades antes de construir nodos
func _configurar_santuario() -> void:
	pass

## Hook virtual para construir la geometría procedural 3D del santuario
func _construir_visual() -> void:
	BunkerVisualKit.make_cylinder(
		visual_root,
		"ZocaloConcreto",
		0.92,
		1.05,
		0.28,
		BunkerVisualKit.get_concrete_base_mat(),
		Vector3(0.0, 0.14, 0.0),
		8
	)
	BunkerVisualKit.make_cylinder(
		visual_root,
		"PedestalAcero",
		0.68,
		0.78,
		0.84,
		BunkerVisualKit.get_chassis_mat(),
		Vector3(0.0, 0.70, 0.0),
		8
	)
	BunkerVisualKit.make_torus(
		visual_root,
		"AnilloEmisor",
		0.58,
		0.72,
		BunkerVisualKit.make_emissive_mat(color_luz, 1.8),
		Vector3(0.0, 1.12, 0.0)
	)

## Hook virtual que ejecuta la lógica del santuario. Debe devolver true si debe consumirse.
func _activar(_pj: Node3D) -> bool:
	return true

## Hook virtual cuando se hace clic en un santuario cuya activación es por proximidad
func _al_hacer_clic_pasivo(_pj: Node3D) -> void:
	pass

func _actualizar_etiqueta(linea_extra: String = "") -> void:
	if etiqueta == null:
		return
	var partes: PackedStringArray = [nombre_santuario]
	if costo_denarios > 0:
		partes.append("🪙 %d Denarios" % costo_denarios)
	elif linea_extra == "":
		partes.append("Gratis · Clic")
	if linea_extra != "":
		partes.append(linea_extra)
	etiqueta.text = "\n".join(partes)

func _crear_material(color: Color, emision: Color = Color.BLACK, energia_emision: float = 0.0, metalico: float = 0.25, rugosidad: float = 0.45) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metalico
	mat.roughness = rugosidad
	if energia_emision > 0.0:
		mat.emission_enabled = true
		mat.emission = emision
		mat.emission_energy_multiplier = energia_emision
	return mat

func _on_mouse_entered() -> void:
	if _consumido:
		return
	_hover = true
	if luz != null:
		luz.light_energy = 3.6
	if visual_root != null:
		visual_root.scale = Vector3(1.06, 1.06, 1.06)

func _on_mouse_exited() -> void:
	_hover = false
	if luz != null and not _consumido:
		luz.light_energy = 2.4
	if visual_root != null:
		visual_root.scale = Vector3.ONE

func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_intentar_interactuar()

func _unhandled_input(event: InputEvent) -> void:
	if _consumido or not visible or not input_ray_pickable:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _puede_procesar_interaccion():
			return
		var vp := get_viewport()
		if vp == null:
			return
		var cam := vp.get_camera_3d()
		if cam == null:
			return
		var origen := cam.project_ray_origin(event.position)
		var fin := origen + cam.project_ray_normal(event.position) * 180.0
		var query := PhysicsRayQueryParameters3D.create(origen, fin)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var space := get_world_3d().direct_space_state
		if space == null:
			return
		var hit := space.intersect_ray(query)
		if not hit.is_empty() and hit.get("collider") == self:
			vp.set_input_as_handled()
			_intentar_interactuar()

func _puede_procesar_interaccion() -> bool:
	if _consumido or not is_inside_tree() or get_tree() == null:
		return false
	if get_tree().paused:
		return false
	if _hay_otro_modal_pausa_abierto():
		return false
	return true

func _intentar_interactuar() -> void:
	if not _puede_procesar_interaccion():
		return
	var ahora_ms: int = Time.get_ticks_msec()
	if ahora_ms - _ultimo_click_ms < 120:
		return
	_ultimo_click_ms = ahora_ms

	var pj := _obtener_jugador()
	if pj == null:
		return

	if not activacion_por_clic:
		_al_hacer_clic_pasivo(pj)
		return

	var dist := _distancia_a_jugador(pj)
	if dist > radio_interaccion:
		_spawn_texto_3d("Acércate más", Color(1.0, 0.78, 0.25))
		AudioManager.play("click", 0.8)
		return

	if not _puede_pagar(pj):
		_spawn_texto_3d("Faltan Denarios (%d)" % costo_denarios, Color(1.0, 0.35, 0.35))
		AudioManager.play("escudo_bloqueo", 0.9)
		return

	if _activar(pj) and un_solo_uso:
		_consumir()

func _obtener_jugador() -> Node3D:
	if get_tree() == null:
		return null
	var pj := get_tree().get_first_node_in_group("jugador")
	if pj is Node3D and is_instance_valid(pj):
		return pj as Node3D
	return null

func _distancia_a_jugador(pj: Node3D) -> float:
	if pj == null or not is_instance_valid(pj):
		return INF
	var a := Vector2(global_position.x, global_position.z)
	var b := Vector2(pj.global_position.x, pj.global_position.z)
	return a.distance_to(b)

func _puede_pagar(pj: Node3D) -> bool:
	if costo_denarios <= 0:
		return true
	if pj == null or not ("denarios" in pj):
		return false
	return int(pj.denarios) >= costo_denarios

func _cobrar(pj: Node3D) -> bool:
	if costo_denarios <= 0:
		return true
	if pj != null and pj.has_method("gastar_denarios"):
		return bool(pj.gastar_denarios(costo_denarios))
	return false

func _consumir() -> void:
	if _consumido:
		return
	_consumido = true
	remove_from_group("santuarios")
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("input_ray_pickable", false)
	if colision != null:
		colision.set_deferred("disabled", true)
	BunkerVisualKit.spawn_shockwave_ring(get_parent(), global_position, 0.9, 3.2, color_luz, 0.36)
	activado.emit(self)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if luz != null:
		tw.tween_property(luz, "light_energy", 0.0, 0.28)
	tw.finished.connect(queue_free)

func _spawn_texto_3d(txt: String, color: Color = Color(1.0, 0.92, 0.3)) -> void:
	if get_parent() == null:
		return
	var dn := ESCENA_TEXTO_3D.instantiate()
	get_parent().add_child(dn)
	dn.global_position = global_position + Vector3(0.0, altura_etiqueta + 0.35, 0.0)
	if dn.has_method("iniciar"):
		dn.iniciar(0.0, true, false, txt)
	var lbl := dn.get_node_or_null("Label3D") as Label3D
	if lbl != null:
		lbl.modulate = color
		lbl.font_size = 46

func _hay_otro_modal_pausa_abierto() -> bool:
	if get_tree() == null:
		return false
	for m in get_tree().get_nodes_in_group("modales_santuario"):
		if is_instance_valid(m) and not m.is_queued_for_deletion() and m is CanvasLayer and m.visible:
			return true
	var p_fin := get_tree().get_first_node_in_group("pantalla_fin_partida")
	if p_fin != null and "visible" in p_fin and p_fin.visible:
		return true
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null:
		var m_mejora = hud.get("modal_mejora")
		if m_mejora != null and is_instance_valid(m_mejora) and m_mejora.visible:
			return true
		var arbol = hud.get("arbol_poe_instancia")
		if arbol != null and is_instance_valid(arbol) and arbol.visible:
			return true
	return false

func _pausar_por_modal() -> void:
	if get_tree() != null:
		get_tree().paused = true

func _restaurar_pausa_segura() -> void:
	if get_tree() == null:
		return
	if not _hay_otro_modal_pausa_abierto():
		get_tree().paused = false

func _crear_panel_style(borde: Color, fondo: Color = Color(0.06, 0.07, 0.11, 0.96), grosor: int = 3, radio: int = 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fondo
	sb.border_color = borde
	sb.set_border_width_all(grosor)
	sb.set_corner_radius_all(radio)
	return sb

func _aplicar_estilo_boton_modal(boton: Button, color_borde: Color) -> void:
	for estado in ["normal", "hover", "pressed", "focus"]:
		var fondo := Color(0.09, 0.11, 0.17, 0.96) if estado != "hover" else Color(0.16, 0.19, 0.28, 0.98)
		boton.add_theme_stylebox_override(estado, _crear_panel_style(color_borde, fondo, 3, 10))
	boton.add_theme_color_override("font_color", color_borde.lerp(Color.WHITE, 0.55))
	boton.add_theme_color_override("font_hover_color", Color.WHITE)

