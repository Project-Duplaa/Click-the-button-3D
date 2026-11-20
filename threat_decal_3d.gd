class_name ThreatDecal3D
extends MeshInstance3D

## ThreatDecal3D — Decal Proyectado de Amenaza en Suelo (GL Compatibility / OpenGL)
## Usa PlaneMesh con shaders/threat_decal.gdshader (unshaded, depth_draw_never, sin sombras)
## para dibujar borde de peligro fijo desde t=0 y llenado animado exacto (0.0 -> 1.0).

enum FormaAmenaza {
	CIRCULO = 0,
	CARRIL_EMBESTIDA = 1,
	ARCO_CONO = 2
}

const SHADER_THREAT_DECAL := preload("res://shaders/threat_decal.gdshader")

@export var altura_suelo: float = 0.05

var forma_actual: FormaAmenaza = FormaAmenaza.CIRCULO
var radio_actual: float = 3.0
var ancho_actual: float = 2.4
var largo_actual: float = 10.0
var angulo_actual_deg: float = 135.0
var progreso_actual: float = 0.0

var _mat_decal: ShaderMaterial = null
var _tween_activo: Tween = null

func _init() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false
	_asegurar_recursos()

func _exit_tree() -> void:
	cancelar()

func _asegurar_recursos() -> void:
	if not (mesh is PlaneMesh):
		var pm := PlaneMesh.new()
		pm.size = Vector2(2.0, 2.0)
		mesh = pm
	if _mat_decal == null or not is_instance_valid(_mat_decal):
		_mat_decal = ShaderMaterial.new()
		_mat_decal.shader = SHADER_THREAT_DECAL
		material_override = _mat_decal

func configurar_circulo(
	radio: float,
	col_base: Color = Color(0.95, 0.16, 0.14, 1.0),
	col_llenado: Color = Color(1.0, 0.42, 0.12, 1.0),
	col_borde: Color = Color(-1.0, 0.0, 0.0, 1.0)
) -> void:
	_asegurar_recursos()
	forma_actual = FormaAmenaza.CIRCULO
	radio_actual = maxf(radio, 0.25)

	var pm := mesh as PlaneMesh
	pm.size = Vector2(radio_actual * 2.0, radio_actual * 2.0)
	if not top_level:
		position = Vector3(0.0, altura_suelo, 0.0)
	scale = Vector3.ONE

	var edge := col_llenado.lightened(0.45) if col_borde.r < 0.0 else col_borde
	_mat_decal.set_shader_parameter("shape_type", int(FormaAmenaza.CIRCULO))
	_mat_decal.set_shader_parameter("base_color", col_base)
	_mat_decal.set_shader_parameter("fill_color", col_llenado)
	_mat_decal.set_shader_parameter("edge_color", edge)
	_mat_decal.set_shader_parameter("aspect_ratio", 1.0)
	_mat_decal.set_shader_parameter("progress", 0.0)
	_mat_decal.set_shader_parameter("warning_pulse", 0.0)
	progreso_actual = 0.0

func configurar_carril(
	ancho: float,
	largo: float,
	col_base: Color = Color(0.92, 0.10, 0.18, 1.0),
	col_llenado: Color = Color(1.0, 0.28, 0.18, 1.0),
	col_borde: Color = Color(-1.0, 0.0, 0.0, 1.0)
) -> void:
	_asegurar_recursos()
	forma_actual = FormaAmenaza.CARRIL_EMBESTIDA
	ancho_actual = maxf(ancho, 0.4)
	largo_actual = maxf(largo, 0.8)

	var pm := mesh as PlaneMesh
	pm.size = Vector2(ancho_actual, largo_actual)
	# Alinear para que inicie en z=0 (jefe) y se proyecte hacia -Z hasta -largo_actual
	if not top_level:
		position = Vector3(0.0, altura_suelo, -largo_actual * 0.5)
	scale = Vector3.ONE

	var edge := col_llenado.lightened(0.45) if col_borde.r < 0.0 else col_borde
	_mat_decal.set_shader_parameter("shape_type", int(FormaAmenaza.CARRIL_EMBESTIDA))
	_mat_decal.set_shader_parameter("base_color", col_base)
	_mat_decal.set_shader_parameter("fill_color", col_llenado)
	_mat_decal.set_shader_parameter("edge_color", edge)
	_mat_decal.set_shader_parameter("aspect_ratio", largo_actual / maxf(ancho_actual, 0.1))
	_mat_decal.set_shader_parameter("progress", 0.0)
	_mat_decal.set_shader_parameter("warning_pulse", 0.0)
	progreso_actual = 0.0

func configurar_arco(
	radio: float,
	angulo_deg: float,
	col_base: Color = Color(0.95, 0.14, 0.18, 1.0),
	col_llenado: Color = Color(1.0, 0.46, 0.14, 1.0),
	col_borde: Color = Color(-1.0, 0.0, 0.0, 1.0),
	corte_interno: float = 0.12
) -> void:
	_asegurar_recursos()
	forma_actual = FormaAmenaza.ARCO_CONO
	radio_actual = maxf(radio, 0.3)
	angulo_actual_deg = clampf(angulo_deg, 15.0, 360.0)

	var pm := mesh as PlaneMesh
	pm.size = Vector2(radio_actual * 2.0, radio_actual * 2.0)
	if not top_level:
		position = Vector3(0.0, altura_suelo, 0.0)
	scale = Vector3.ONE

	var edge := col_llenado.lightened(0.45) if col_borde.r < 0.0 else col_borde
	_mat_decal.set_shader_parameter("shape_type", int(FormaAmenaza.ARCO_CONO))
	_mat_decal.set_shader_parameter("base_color", col_base)
	_mat_decal.set_shader_parameter("fill_color", col_llenado)
	_mat_decal.set_shader_parameter("edge_color", edge)
	_mat_decal.set_shader_parameter("arc_angle_deg", angulo_actual_deg)
	_mat_decal.set_shader_parameter("inner_cutoff", clampf(corte_interno, 0.0, 0.78))
	_mat_decal.set_shader_parameter("aspect_ratio", 1.0)
	_mat_decal.set_shader_parameter("progress", 0.0)
	_mat_decal.set_shader_parameter("warning_pulse", 0.0)
	progreso_actual = 0.0

func establecer_progreso(valor: float) -> void:
	progreso_actual = clampf(valor, 0.0, 1.0)
	if _mat_decal != null and is_instance_valid(_mat_decal):
		_mat_decal.set_shader_parameter("progress", progreso_actual)
		var pulso := clampf((progreso_actual - 0.75) / 0.25, 0.0, 1.0)
		_mat_decal.set_shader_parameter("warning_pulse", pulso)

func iniciar_cuenta_regresiva(duracion: float, auto_ocultar: bool = true) -> Tween:
	_asegurar_recursos()
	_detener_tween()
	establecer_progreso(0.0)
	visible = true

	if not is_inside_tree():
		return null

	var safe_dur := maxf(duracion, 0.05)
	_tween_activo = create_tween()
	_tween_activo.tween_method(establecer_progreso, 0.0, 1.0, safe_dur).set_trans(Tween.TRANS_LINEAR)
	if auto_ocultar:
		_tween_activo.tween_callback(func():
			if is_instance_valid(self):
				visible = false
		)
	return _tween_activo

func cancelar() -> void:
	_detener_tween()
	progreso_actual = 0.0
	if _mat_decal != null and is_instance_valid(_mat_decal):
		_mat_decal.set_shader_parameter("progress", 0.0)
		_mat_decal.set_shader_parameter("warning_pulse", 0.0)
	visible = false

func _detener_tween() -> void:
	if _tween_activo != null and _tween_activo.is_valid():
		_tween_activo.kill()
	_tween_activo = null

## Comprueba si una posición global cae exactamente dentro del área proyectada por este decal
func punto_en_area(pos_global: Vector3, margen_extra: float = 0.0) -> bool:
	if not is_inside_tree():
		return false
	var origen := global_position
	var local_pos := to_local(pos_global)
	match forma_actual:
		FormaAmenaza.CIRCULO:
			var d := Vector2(pos_global.x - origen.x, pos_global.z - origen.z).length()
			return d <= (radio_actual + margen_extra)
		FormaAmenaza.CARRIL_EMBESTIDA:
			# En espacio local del decal, el plano está centrado en (0, 0, 0) con X in [-ancho/2, ancho/2], Z in [-largo/2, largo/2]
			var half_w := ancho_actual * 0.5 + margen_extra
			var half_l := largo_actual * 0.5 + margen_extra
			return absf(local_pos.x) <= half_w and absf(local_pos.z) <= half_l
		FormaAmenaza.ARCO_CONO:
			var flat := Vector2(local_pos.x, local_pos.z)
			var dist := flat.length()
			if dist > (radio_actual + margen_extra):
				return false
			if angulo_actual_deg >= 359.0 or dist <= 1.2:
				return true
			var ang := absf(atan2(flat.x, -flat.y))
			return ang <= deg_to_rad(angulo_actual_deg * 0.5)
	return false
