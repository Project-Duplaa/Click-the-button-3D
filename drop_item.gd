extends Area3D

## DropItem — Orbes de Botín Optimizados (Sin OmniLight3D dinámico para 60 FPS estables)

enum TipoDrop { ORO, EXP, CORAZON, TREBOL, IMAN, BOMBA, DENARIO }

@export var tipo: TipoDrop = TipoDrop.ORO
@export var valor: int = 5
@export var velocidad_iman: float = 8.5
@export var radio_atraccion: float = 4.2

var jugador: Node3D = null
var recogido: bool = false
var _radio_extra_cache: float = 0.0
var _reloj_radio_cache: float = 0.0

func _ready():
	add_to_group("drops")
	add_to_group("orbes_drop")
	monitorable = false
	_reloj_radio_cache = float(get_instance_id() & 15) * 0.016
	body_entered.connect(_on_body_entered)
	jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("player")
	# Desactivar cualquier OmniLight3D heredada en escena para proteger el presupuesto de sombras
	for child in get_children():
		if child is OmniLight3D:
			child.visible = false
			child.queue_free()
	_actualizar_aspecto()

func iniciar(nuevo_tipo: int, nuevo_valor: int) -> void:
	tipo = nuevo_tipo as TipoDrop
	valor = nuevo_valor
	if is_inside_tree():
		_actualizar_aspecto()

static var _mat_destello_iman: StandardMaterial3D = null

func forzar_atraccion(objetivo: Node3D):
	if recogido or objetivo == null or not is_instance_valid(objetivo):
		return
	jugador = objetivo
	radio_atraccion = 9999.0
	velocidad_iman = maxf(velocidad_iman * 2.2, 24.0)

func animar_destello_iman() -> void:
	if recogido or not is_inside_tree():
		return
	var mesh_inst := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_inst != null:
		if _mat_destello_iman == null:
			_mat_destello_iman = StandardMaterial3D.new()
			_mat_destello_iman.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_mat_destello_iman.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_mat_destello_iman.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			_mat_destello_iman.albedo_color = Color(1.0, 0.90, 0.35, 0.65)
		mesh_inst.material_overlay = _mat_destello_iman
	var esc_base := scale
	var tw := create_tween()
	tw.tween_property(self, "scale", esc_base * 1.48, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", esc_base, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		if is_instance_valid(mesh_inst):
			mesh_inst.material_overlay = null
	)

static var _mats_aspecto: Dictionary = {}


func _actualizar_aspecto():
	var mesh_inst = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_inst == null:
		return
	mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var clave := int(tipo)
	var mat := _mats_aspecto.get(clave, null) as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		match tipo:
			TipoDrop.EXP:
				mat.albedo_color = Color(0.2, 0.85, 1.0, 1.0)
			TipoDrop.CORAZON:
				mat.albedo_color = Color(1.0, 0.22, 0.35, 1.0)
			TipoDrop.TREBOL:
				mat.albedo_color = Color(0.2, 0.98, 0.38, 1.0)
			TipoDrop.IMAN:
				mat.albedo_color = Color(0.15, 0.92, 1.0, 1.0)
			TipoDrop.BOMBA:
				mat.albedo_color = Color(1.0, 0.35, 0.08, 1.0)
			TipoDrop.DENARIO:
				mat.albedo_color = Color(0.88, 0.95, 1.0, 1.0)
			_:
				mat.albedo_color = Color(1.0, 0.86, 0.15, 1.0)
		_mats_aspecto[clave] = mat
	mesh_inst.set_surface_override_material(0, mat)

func _process(delta):
	rotate_y(2.5 * delta)

	if recogido:
		return

	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			return

	_reloj_radio_cache -= delta
	if _reloj_radio_cache <= 0.0:
		_reloj_radio_cache = 0.25
		if jugador.has_method("obtener_radio_atraccion_extra"):
			_radio_extra_cache = jugador.obtener_radio_atraccion_extra()
	var radio_total := radio_atraccion + _radio_extra_cache
	var pos_pj := jugador.global_position
	if global_position.distance_squared_to(pos_pj) < radio_total * radio_total:
		var dir = (pos_pj + Vector3(0, 0.8, 0) - global_position).normalized()
		var vel_actual = velocidad_iman + (_radio_extra_cache * 0.85)
		global_position += dir * vel_actual * delta

func _on_body_entered(body):
	if recogido or body == null:
		return
	if body.is_in_group("jugador") or body.is_in_group("player"):
		recogido = true
		if body.has_method("recoger_drop"):
			body.recoger_drop(tipo, valor)
		queue_free()
