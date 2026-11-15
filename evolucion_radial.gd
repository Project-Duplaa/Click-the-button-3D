@tool
extends Node3D
class_name EvolucionRadial

## EvolucionRadial (Controlador 3D In-World de Gran Escala + Burbuja con Preview 3D en Vivo)
## Despliega un círculo arcano 3D bajo los pies del héroe con tótems 3D reactivos
## en cada sector (150° Izquierda, 30° Derecha, 270° Superior) y proyecta una burbuja
## emergente con el preview 3D en vivo del héroe con sus armas procedurales reales.

signal evolucion_seleccionada(nombre_clase: String)
signal clase_preview_cambiada(nombre_clase: String)

const MALLAS_CLASE_PREVIEW = {
	"Guerrero": preload("res://personaje/character-male-d.glb"),
	"Cazador": preload("res://personaje/character-female-e.glb"),
	"Mago": preload("res://personaje/character-female-b.glb"),
	"Paladín Solar": preload("res://personaje/character-male-d.glb"),
	"Berserker Sangriento": preload("res://personaje/character-male-d.glb"),
	"Francotirador Astral": preload("res://personaje/character-female-e.glb"),
	"Maestro de Sombras": preload("res://personaje/character-female-e.glb"),
	"Archimago del Vacío": preload("res://personaje/character-female-b.glb"),
	"Piromante Cataclísmico": preload("res://personaje/character-female-b.glb"),
	"Avatar del Núcleo": preload("res://personaje/character-male-d.glb")
}

@export var radio_activacion_min: float = 0.72
@export var radio_activacion_max: float = 2.30
@export var altura_suelo_offset: float = 0.03
@export var escala_abierto: Vector3 = Vector3(1.0, 1.0, 1.0)

const COOLDOWN_CONFIRMACION: float = 0.85
const REBOTE_SPAM_RADIAL: float = 0.35
const TOPE_COOLDOWN_RADIAL: float = 1.90

@onready var sprite_radial: Sprite3D = $Sprite3D
@onready var subviewport: SubViewport = $SubViewport
@onready var control_radial: ControlRadial = $SubViewport/ControlRadial
@onready var luz_flash: OmniLight3D = $LuzFlash
@onready var capa_ui: CanvasLayer = $CapaUI
@onready var dibujador_cola: Control = $CapaUI/DibujadorCola
@onready var tooltip_flotante: PanelContainer = $CapaUI/TooltipFlotante
@onready var panel_preview_3d: Panel = get_node_or_null("CapaUI/TooltipFlotante/Margin/HBox/PanelPreview3D")
@onready var camara_preview: Camera3D = get_node_or_null("CapaUI/TooltipFlotante/Margin/HBox/PanelPreview3D/SubViewportContainer/SubViewportHeroe/CamaraPreview")
@onready var luz_clase_preview: OmniLight3D = get_node_or_null("CapaUI/TooltipFlotante/Margin/HBox/PanelPreview3D/SubViewportContainer/SubViewportHeroe/LuzClase")
@onready var pivote_modelo_preview: Node3D = get_node_or_null("CapaUI/TooltipFlotante/Margin/HBox/PanelPreview3D/SubViewportContainer/SubViewportHeroe/PivoteModelo")
@onready var label_rol: Label = get_node_or_null("CapaUI/TooltipFlotante/Margin/HBox/VBox/LabelRol")
@onready var label_titulo: Label = get_node_or_null("CapaUI/TooltipFlotante/Margin/HBox/VBox/LabelTitulo")
@onready var rich_texto_stats: RichTextLabel = get_node_or_null("CapaUI/TooltipFlotante/Margin/HBox/VBox/RichTextoStats")
@onready var label_accion: Label = get_node_or_null("CapaUI/TooltipFlotante/Margin/HBox/VBox/LabelAccion")

var activo: bool = false
var personaje_padre: CharacterBody3D = null
var camara_3d: Camera3D = null

var tier_actual: int = 1
var clase_base_actual: String = "Guerrero"
var opciones_activas: Array[String] = ["Guerrero", "Cazador", "Mago"]

var _tiempo_abierto: float = 0.0
var _tiempo_desbloqueo_confirmacion: float = COOLDOWN_CONFIRMACION
var _accion_base_tooltip: String = ""
var _cursor_sobre_anillo: bool = false
var _pos_pantalla_sector: Vector2 = Vector2.ZERO

var _contenedor_3d_rueda: Node3D = null
var _anillo_exterior_3d: MeshInstance3D = null
var _totems_sector: Dictionary = {}

var _clase_preview_actual: String = ""
var _modelo_preview_instancia: Node3D = null
var _pedestal_preview: MeshInstance3D = null
var _anim_preview_ctrl: AnimadorEntidad = null

func _ready():
	if Engine.is_editor_hint():
		return
	visible = false
	scale = Vector3.ZERO
	top_level = true

	if luz_flash != null:
		luz_flash.light_energy = 0.0

	if tooltip_flotante != null:
		tooltip_flotante.visible = false
		tooltip_flotante.modulate.a = 0.0
		if not tooltip_flotante.gui_input.is_connected(_on_tooltip_gui_input):
			tooltip_flotante.gui_input.connect(_on_tooltip_gui_input)

	if dibujador_cola != null and dibujador_cola.has_method("ocultar"):
		dibujador_cola.ocultar()

	if control_radial != null:
		if not control_radial.clase_resaltada.is_connected(_on_clase_resaltada):
			control_radial.clase_resaltada.connect(_on_clase_resaltada)
		if not control_radial.clase_confirmada.is_connected(confirmar_evolucion):
			control_radial.clase_confirmada.connect(confirmar_evolucion)

	_construir_decoracion_3d_rueda()
	_inicializar_escenario_preview_burbuja()
	_vincular_con_personaje()

func _vincular_con_personaje():
	if get_parent() is CharacterBody3D:
		personaje_padre = get_parent() as CharacterBody3D
	elif get_tree() != null:
		personaje_padre = get_tree().get_first_node_in_group("jugador") as CharacterBody3D
		if personaje_padre == null:
			personaje_padre = get_tree().get_first_node_in_group("player") as CharacterBody3D

	if get_viewport() != null:
		camara_3d = get_viewport().get_camera_3d()

	if sprite_radial != null and subviewport != null:
		sprite_radial.texture = subviewport.get_texture()

func configurar_modo_tier(tier: int, clase_base: String):
	tier_actual = tier
	clase_base_actual = clase_base
	if control_radial == null:
		control_radial = get_node_or_null("SubViewport/ControlRadial") as ControlRadial
	if control_radial != null:
		control_radial.establecer_modo_opciones(tier, clase_base)
		opciones_activas.assign(control_radial.opciones_activas)
	_construir_decoracion_3d_rueda()

func configurar_opciones(lista_3_opciones: Array, configs: Dictionary = {}):
	if control_radial == null:
		control_radial = get_node_or_null("SubViewport/ControlRadial") as ControlRadial
	if control_radial != null:
		control_radial.configurar_opciones(lista_3_opciones, configs)
		opciones_activas.assign(control_radial.opciones_activas)
	_construir_decoracion_3d_rueda()

func _construir_decoracion_3d_rueda():
	if _contenedor_3d_rueda != null and is_instance_valid(_contenedor_3d_rueda):
		_contenedor_3d_rueda.queue_free()

	_contenedor_3d_rueda = Node3D.new()
	_contenedor_3d_rueda.name = "Decoracion3DRueda"
	add_child(_contenedor_3d_rueda)

	_anillo_exterior_3d = MeshInstance3D.new()
	var torus_ext = TorusMesh.new()
	torus_ext.inner_radius = 2.18
	torus_ext.outer_radius = 2.26
	torus_ext.rings = 64
	torus_ext.ring_segments = 16
	var mat_oro = StandardMaterial3D.new()
	mat_oro.albedo_color = Color(0.95, 0.78, 0.32, 0.9)
	mat_oro.emission_enabled = true
	mat_oro.emission = Color(0.95, 0.75, 0.25)
	mat_oro.emission_energy_multiplier = 1.35
	mat_oro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	torus_ext.material = mat_oro
	_anillo_exterior_3d.mesh = torus_ext
	_anillo_exterior_3d.position = Vector3(0.0, 0.03, 0.0)
	_anillo_exterior_3d.scale = Vector3(1.0, 0.25, 1.0)
	_contenedor_3d_rueda.add_child(_anillo_exterior_3d)

	var angulos_sectores = [150.0, 30.0, 270.0]
	var radio_totem: float = 2.02
	_totems_sector.clear()

	for i in range(min(opciones_activas.size(), 3)):
		var nombre_opcion = opciones_activas[i]
		var ang_deg = angulos_sectores[i]
		var cfg = control_radial._obtener_config(nombre_opcion) if control_radial != null else {}
		var col: Color = cfg.get("color", Color(0.9, 0.8, 0.2))

		var ang_rad = deg_to_rad(ang_deg)
		var pos_sector = Vector3(cos(ang_rad) * radio_totem, 0.16, -sin(ang_rad) * radio_totem)

		var root_totem = Node3D.new()
		root_totem.name = "Totem_" + nombre_opcion.replace(" ", "_")
		root_totem.position = pos_sector
		_contenedor_3d_rueda.add_child(root_totem)

		var halo = MeshInstance3D.new()
		var torus_h = TorusMesh.new()
		torus_h.inner_radius = 0.22
		torus_h.outer_radius = 0.28
		var mat_h = StandardMaterial3D.new()
		mat_h.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat_h.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat_h.albedo_color = Color(col.r, col.g, col.b, 0.85)
		torus_h.material = mat_h
		halo.mesh = torus_h
		halo.scale = Vector3(1.0, 0.2, 1.0)
		root_totem.add_child(halo)

		var cristal = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.18, 0.28, 0.18)
		var mat_c = StandardMaterial3D.new()
		mat_c.albedo_color = col.lightened(0.25)
		mat_c.emission_enabled = true
		mat_c.emission = col
		mat_c.emission_energy_multiplier = 2.0
		mat_c.metallic = 0.6
		mat_c.roughness = 0.2
		box.material = mat_c
		cristal.mesh = box
		cristal.position = Vector3(0.0, 0.22, 0.0)
		cristal.rotation_degrees = Vector3(35.0, 45.0, 35.0)
		root_totem.add_child(cristal)

		var luz = OmniLight3D.new()
		luz.light_color = col
		luz.light_energy = 0.8
		luz.omni_range = 2.4
		luz.position = Vector3(0.0, 0.35, 0.0)
		root_totem.add_child(luz)

		_totems_sector[nombre_opcion] = {
			"root": root_totem,
			"cristal": cristal,
			"halo": halo,
			"luz": luz,
			"pos_base": pos_sector
		}

func _inicializar_escenario_preview_burbuja():
	if camara_preview != null:
		camara_preview.look_at_from_position(Vector3(0.0, 0.35, 0.96), Vector3(0.0, 0.28, 0.0), Vector3.UP)
		camara_preview.fov = 39.0

	if pivote_modelo_preview != null and _pedestal_preview == null:
		_pedestal_preview = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.25
		cyl.bottom_radius = 0.29
		cyl.height = 0.05
		var mat_ped = StandardMaterial3D.new()
		mat_ped.albedo_color = Color(0.16, 0.19, 0.28, 1.0)
		mat_ped.emission_enabled = true
		mat_ped.emission = Color(0.92, 0.74, 0.32)
		mat_ped.emission_energy_multiplier = 0.65
		mat_ped.metallic = 0.75
		mat_ped.roughness = 0.25
		cyl.material = mat_ped
		_pedestal_preview.mesh = cyl
		_pedestal_preview.position = Vector3(0.0, -0.025, 0.0)
		pivote_modelo_preview.add_child(_pedestal_preview)

func _actualizar_modelo_3d_en_burbuja(nombre_clase: String, col_clase: Color):
	if pivote_modelo_preview == null:
		return

	if luz_clase_preview != null:
		luz_clase_preview.light_color = col_clase.lightened(0.15)
		luz_clase_preview.light_energy = 3.2

	if panel_preview_3d != null:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(col_clase.r * 0.14 + 0.05, col_clase.g * 0.14 + 0.06, col_clase.b * 0.14 + 0.10, 1.0)
		sb.border_color = col_clase.lightened(0.2)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		sb.shadow_color = Color(col_clase.r, col_clase.g, col_clase.b, 0.45)
		sb.shadow_size = 8
		panel_preview_3d.add_theme_stylebox_override("panel", sb)

	if _clase_preview_actual == nombre_clase and is_instance_valid(_modelo_preview_instancia):
		return
	_clase_preview_actual = nombre_clase

	if is_instance_valid(_modelo_preview_instancia):
		if _modelo_preview_instancia.get_parent() != null:
			_modelo_preview_instancia.get_parent().remove_child(_modelo_preview_instancia)
		_modelo_preview_instancia.queue_free()
		_modelo_preview_instancia = null

	var escena_malla: PackedScene = MALLAS_CLASE_PREVIEW.get(nombre_clase, MALLAS_CLASE_PREVIEW.get("Guerrero", null))
	if escena_malla == null:
		return

	_modelo_preview_instancia = escena_malla.instantiate()
	_modelo_preview_instancia.name = "HeroePreview3D"
	_modelo_preview_instancia.rotation_degrees = Vector3(0.0, 165.0, 0.0)
	pivote_modelo_preview.add_child(_modelo_preview_instancia)

	AnimadorEntidad.equipar_armas_en_esqueleto(_modelo_preview_instancia, nombre_clase, true)

	_anim_preview_ctrl = AnimadorEntidad.new(_modelo_preview_instancia)
	if _anim_preview_ctrl != null and _anim_preview_ctrl.esta_listo():
		match nombre_clase:
			"Guerrero", "Paladín Solar":
				_anim_preview_ctrl.reproducir_bucle("idle", 0.1, 1.0)
				_anim_preview_ctrl.reproducir_accion("attack-melee-right", 2, 0.08, 0.9)
			"Berserker Sangriento":
				_anim_preview_ctrl.reproducir_bucle("idle", 0.1, 1.0)
				_anim_preview_ctrl.reproducir_accion("whirlwind", 2, 0.08, 1.1)
			"Cazador", "Francotirador Astral":
				_anim_preview_ctrl.reproducir_bucle("idle", 0.1, 1.0)
				_anim_preview_ctrl.reproducir_accion("shoot-bow", 2, 0.08, 0.9)
			"Maestro de Sombras":
				_anim_preview_ctrl.reproducir_bucle("idle", 0.1, 1.0)
				_anim_preview_ctrl.reproducir_accion("attack-melee-left", 2, 0.08, 1.1)
			"Mago", "Archimago del Vacío", "Piromante Cataclísmico":
				_anim_preview_ctrl.reproducir_bucle("idle", 0.1, 1.0)
				_anim_preview_ctrl.reproducir_accion("cast-magic", 2, 0.08, 0.9)
			"Avatar del Núcleo":
				_anim_preview_ctrl.reproducir_bucle("idle", 0.1, 1.0)
				_anim_preview_ctrl.reproducir_accion("cast-magic", 2, 0.08, 1.1)

func abrir():
	if activo:
		return
	activo = true
	visible = true
	scale = Vector3.ZERO
	_tiempo_abierto = 0.0
	_tiempo_desbloqueo_confirmacion = COOLDOWN_CONFIRMACION
	_cursor_sobre_anillo = false

	if personaje_padre == null or not is_instance_valid(personaje_padre):
		_vincular_con_personaje()

	if control_radial != null:
		control_radial.deseleccionar()
	_ocultar_tooltip()

	if personaje_padre != null and is_instance_valid(personaje_padre):
		global_position = personaje_padre.global_position + Vector3(0, altura_suelo_offset, 0)
		global_rotation = Vector3.ZERO
	else:
		position.y = altura_suelo_offset
		rotation = Vector3.ZERO

	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", escala_abierto, 0.38)

	if (camara_3d == null or not is_instance_valid(camara_3d)) and get_viewport() != null:
		camara_3d = get_viewport().get_camera_3d()

func cerrar():
	if not activo:
		return
	activo = false
	_cursor_sobre_anillo = false

	if control_radial != null:
		control_radial.deseleccionar()
	_ocultar_tooltip()

	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector3.ZERO, 0.18)
	tw.tween_callback(func():
		visible = false
		scale = Vector3.ZERO
	)

func _process(delta: float):
	if Engine.is_editor_hint() or not activo:
		return

	_tiempo_abierto += delta

	if personaje_padre != null and is_instance_valid(personaje_padre):
		global_position = personaje_padre.global_position + Vector3(0, altura_suelo_offset, 0)
		global_rotation = Vector3.ZERO

	_animar_elementos_3d_rueda_y_burbuja(delta)
	_procesar_input_mouse()
	_actualizar_posicion_tooltip_2d()
	if label_accion != null and tooltip_flotante != null and tooltip_flotante.visible:
		if _tiempo_abierto < _tiempo_desbloqueo_confirmacion:
			label_accion.text = "🛡 PROTECCIÓN ANTI-CLIC · %.1fs" % maxf(0.1, _tiempo_desbloqueo_confirmacion - _tiempo_abierto)
		elif _accion_base_tooltip != "":
			label_accion.text = _accion_base_tooltip

func _animar_elementos_3d_rueda_y_burbuja(delta: float):
	var clase_sel = control_radial.clase_seleccionada if control_radial != null else ""

	for nombre_clase in _totems_sector.keys():
		var t_data: Dictionary = _totems_sector[nombre_clase]
		var root_t: Node3D = t_data["root"]
		var cristal: MeshInstance3D = t_data["cristal"]
		var halo: MeshInstance3D = t_data["halo"]
		var luz: OmniLight3D = t_data["luz"]
		var pos_base: Vector3 = t_data["pos_base"]
		if not is_instance_valid(root_t):
			continue

		var seleccionado = (nombre_clase == clase_sel)
		var vel_giro = 3.6 if seleccionado else 1.2
		cristal.rotate_y(delta * vel_giro)
		halo.rotate_y(-delta * vel_giro * 0.8)

		var altura_obj = pos_base.y + (0.24 if seleccionado else 0.0) + sin(_tiempo_abierto * 3.2) * 0.05
		root_t.position.y = lerpf(root_t.position.y, altura_obj, delta * 10.0)
		var escala_obj = Vector3.ONE * (1.42 if seleccionado else 1.0)
		root_t.scale = root_t.scale.lerp(escala_obj, delta * 10.0)
		luz.light_energy = lerpf(luz.light_energy, 2.8 if seleccionado else 0.7, delta * 10.0)

	if is_instance_valid(_modelo_preview_instancia) and tooltip_flotante != null and tooltip_flotante.visible:
		_modelo_preview_instancia.rotate_y(delta * 0.95)
		if _anim_preview_ctrl != null:
			_anim_preview_ctrl.actualizar(delta)
			if not _anim_preview_ctrl.esta_bloqueado():
				_anim_preview_ctrl.reproducir_bucle("idle", 0.15, 1.0)

func _input(event: InputEvent):
	if Engine.is_editor_hint() or not activo:
		return
	if _tiempo_abierto < _tiempo_desbloqueo_confirmacion:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if _tiempo_abierto >= 0.14:
				_tiempo_desbloqueo_confirmacion = minf(TOPE_COOLDOWN_RADIAL, maxf(_tiempo_desbloqueo_confirmacion, _tiempo_abierto + REBOTE_SPAM_RADIAL))
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _cursor_sobre_anillo and control_radial != null and control_radial.clase_seleccionada != "":
			confirmar_evolucion(control_radial.clase_seleccionada)
			get_viewport().set_input_as_handled()

func _on_tooltip_gui_input(event: InputEvent):
	if not activo or _tiempo_abierto < _tiempo_desbloqueo_confirmacion:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if _tiempo_abierto >= 0.14:
				_tiempo_desbloqueo_confirmacion = minf(TOPE_COOLDOWN_RADIAL, maxf(_tiempo_desbloqueo_confirmacion, _tiempo_abierto + REBOTE_SPAM_RADIAL))
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if control_radial != null and control_radial.clase_seleccionada != "":
			confirmar_evolucion(control_radial.clase_seleccionada)
			get_viewport().set_input_as_handled()

func _procesar_input_mouse():
	if get_viewport() == null:
		return
	if camara_3d == null or not is_instance_valid(camara_3d):
		camara_3d = get_viewport().get_camera_3d()
		if camara_3d == null:
			return

	var pj_pos = personaje_padre.global_position if (personaje_padre != null and is_instance_valid(personaje_padre)) else global_position
	var plano_y = pj_pos.y

	var mouse_screen = get_viewport().get_mouse_position()
	var ray_orig = camara_3d.project_ray_origin(mouse_screen)
	var ray_norm = camara_3d.project_ray_normal(mouse_screen)

	if abs(ray_norm.y) > 0.0001:
		var d = (plano_y - ray_orig.y) / ray_norm.y
		if d > 0.0:
			var hit_world = ray_orig + ray_norm * d
			var offset_local = hit_world - pj_pos
			var dist_suelo = Vector2(offset_local.x, offset_local.z).length()

			if dist_suelo >= radio_activacion_min and dist_suelo <= radio_activacion_max:
				_cursor_sobre_anillo = true
				var ang_rad = atan2(-offset_local.z, offset_local.x)
				var ang_deg = fposmod(rad_to_deg(ang_rad), 360.0)
				if control_radial != null:
					control_radial.actualizar_por_angulo(ang_deg)
			else:
				_cursor_sobre_anillo = false
				if control_radial != null and control_radial.clase_seleccionada != "":
					control_radial.deseleccionar()

func _on_clase_resaltada(nombre_clase: String):
	emit_signal("clase_preview_cambiada", nombre_clase)

	if personaje_padre != null and personaje_padre.has_method("mostrar_preview_clase"):
		personaje_padre.mostrar_preview_clase(nombre_clase)

	if nombre_clase == "":
		_ocultar_tooltip()
	else:
		_mostrar_tooltip_para_clase(nombre_clase)

func _mostrar_tooltip_para_clase(nombre_clase: String):
	if tooltip_flotante == null or control_radial == null:
		return
	var config = control_radial._obtener_config(nombre_clase)
	if config.is_empty():
		return

	var col_clase: Color = config.get("color", Color.WHITE)
	if label_rol != null:
		label_rol.text = str(config.get("rol_badge", ""))
		label_rol.add_theme_color_override("font_color", col_clase.lightened(0.35))
	if label_titulo != null:
		label_titulo.text = str(config.get("titulo", nombre_clase.to_upper()))
		label_titulo.add_theme_color_override("font_color", col_clase.lerp(Color.WHITE, 0.28))
	if rich_texto_stats != null:
		rich_texto_stats.text = str(config.get("stats_bbcode", ""))
	_accion_base_tooltip = str(config.get("accion", "[Clic para evolucionar]"))
	if label_accion != null:
		if _tiempo_abierto < _tiempo_desbloqueo_confirmacion:
			label_accion.text = "🛡 PROTECCIÓN ANTI-CLIC · %.1fs" % maxf(0.1, _tiempo_desbloqueo_confirmacion - _tiempo_abierto)
		else:
			label_accion.text = _accion_base_tooltip

	var sb_tip = StyleBoxFlat.new()
	sb_tip.bg_color = Color(0.06, 0.08, 0.14, 0.97)
	sb_tip.border_color = col_clase.lerp(Color(0.95, 0.78, 0.36), 0.35)
	sb_tip.set_border_width_all(2)
	sb_tip.set_corner_radius_all(14)
	sb_tip.content_margin_left = 14.0
	sb_tip.content_margin_right = 16.0
	sb_tip.content_margin_top = 12.0
	sb_tip.content_margin_bottom = 12.0
	sb_tip.shadow_color = Color(col_clase.r, col_clase.g, col_clase.b, 0.35)
	sb_tip.shadow_size = 16
	tooltip_flotante.add_theme_stylebox_override("panel", sb_tip)

	_actualizar_modelo_3d_en_burbuja(nombre_clase, col_clase)

	tooltip_flotante.visible = true
	var tw = create_tween()
	tw.tween_property(tooltip_flotante, "modulate:a", 1.0, 0.16)

func _ocultar_tooltip():
	if tooltip_flotante != null and tooltip_flotante.visible:
		var tw = create_tween()
		tw.tween_property(tooltip_flotante, "modulate:a", 0.0, 0.12)
		tw.tween_callback(func(): tooltip_flotante.visible = false)
	if dibujador_cola != null and dibujador_cola.has_method("ocultar"):
		dibujador_cola.ocultar()

func _actualizar_posicion_tooltip_2d():
	if not activo or control_radial == null or control_radial.clase_seleccionada == "":
		if dibujador_cola != null and dibujador_cola.has_method("ocultar"):
			dibujador_cola.ocultar()
		return

	if camara_3d == null or not is_instance_valid(camara_3d):
		camara_3d = get_viewport().get_camera_3d()
		if camara_3d == null:
			return

	var pj_pos = personaje_padre.global_position if (personaje_padre != null and is_instance_valid(personaje_padre)) else global_position
	var clase_sel = control_radial.clase_seleccionada
	var col_clase: Color = control_radial._obtener_config(clase_sel).get("color", Color(0.92, 0.76, 0.36))

	var idx_sector = opciones_activas.find(clase_sel)
	if idx_sector == -1:
		idx_sector = 0

	var sector_offset_3d = Vector3.ZERO
	match idx_sector:
		0:
			sector_offset_3d = Vector3(-1.31, 0.0, -0.75)
		1:
			sector_offset_3d = Vector3(1.31, 0.0, -0.75)
		2:
			sector_offset_3d = Vector3(0.0, 0.0, 1.51)

	var pos_sector_3d = pj_pos + sector_offset_3d
	_pos_pantalla_sector = camara_3d.unproject_position(pos_sector_3d)

	var pos_pj_pantalla = camara_3d.unproject_position(pj_pos + Vector3(0, 1.25, 0))
	var tam_tip = tooltip_flotante.size if tooltip_flotante != null else Vector2(386, 186)
	var vp_size = get_viewport().get_visible_rect().size

	var pos_tip = Vector2.ZERO
	var p_origen1 = Vector2.ZERO
	var p_origen2 = Vector2.ZERO

	match idx_sector:
		2:
			pos_tip = pos_pj_pantalla + Vector2(85.0, -65.0)
			pos_tip.x = clampf(pos_tip.x, 20.0, vp_size.x - tam_tip.x - 20.0)
			pos_tip.y = clampf(pos_tip.y, 90.0, vp_size.y - tam_tip.y - 30.0)
			p_origen1 = pos_tip + Vector2(0.0, tam_tip.y - 16.0)
			p_origen2 = pos_tip + Vector2(24.0, tam_tip.y)
		0:
			pos_tip = pos_pj_pantalla + Vector2(-tam_tip.x - 85.0, -80.0)
			pos_tip.x = clampf(pos_tip.x, 20.0, vp_size.x - tam_tip.x - 20.0)
			pos_tip.y = clampf(pos_tip.y, 90.0, vp_size.y - tam_tip.y - 30.0)
			p_origen1 = pos_tip + Vector2(tam_tip.x, tam_tip.y - 16.0)
			p_origen2 = pos_tip + Vector2(tam_tip.x - 24.0, tam_tip.y)
		1:
			pos_tip = pos_pj_pantalla + Vector2(85.0, -110.0)
			pos_tip.x = clampf(pos_tip.x, 20.0, vp_size.x - tam_tip.x - 20.0)
			pos_tip.y = clampf(pos_tip.y, 90.0, vp_size.y - tam_tip.y - 30.0)
			p_origen1 = pos_tip + Vector2(0.0, tam_tip.y - 16.0)
			p_origen2 = pos_tip + Vector2(24.0, tam_tip.y)

	if tooltip_flotante != null:
		tooltip_flotante.global_position = tooltip_flotante.global_position.lerp(pos_tip, 0.35)

	if dibujador_cola != null and dibujador_cola.has_method("actualizar_cola"):
		dibujador_cola.actualizar_cola(p_origen1, p_origen2, _pos_pantalla_sector, true, col_clase.lightened(0.2))

func confirmar_evolucion(nombre_clase: String):
	if not activo:
		return

	activo = false
	_cursor_sobre_anillo = false
	_ocultar_tooltip()
	emit_signal("evolucion_seleccionada", nombre_clase)

	if luz_flash != null and control_radial != null:
		var info = control_radial._obtener_config(nombre_clase)
		luz_flash.light_color = info.get("color", Color.WHITE)
		luz_flash.light_energy = 4.2
		var tw_flash = create_tween()
		tw_flash.tween_property(luz_flash, "light_energy", 0.0, 0.40)

	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ZERO, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		visible = false
		scale = Vector3.ZERO
	)
