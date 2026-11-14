extends Area3D

## DropItem — Orbes de Botín Optimizados (Sin OmniLight3D dinámico para 60 FPS estables)

enum TipoDrop { ORO, EXP, CORAZON, TREBOL, IMAN, BOMBA, DENARIO }

@export var tipo: TipoDrop = TipoDrop.ORO
@export var valor: int = 5
@export var velocidad_iman: float = 8.5
@export var radio_atraccion: float = 4.2

var jugador: Node3D = null
var recogido: bool = false

func _ready():
	add_to_group("drops")
	add_to_group("orbes_drop")
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

func iniciar(nuevo_tipo: int, nuevo_valor: int):
	tipo = nuevo_tipo as TipoDrop
	valor = nuevo_valor
	if not is_inside_tree():
		await ready
	_actualizar_aspecto()

func forzar_atraccion(objetivo: Node3D):
	jugador = objetivo
	radio_atraccion = 9999.0
	velocidad_iman = maxf(velocidad_iman * 2.2, 22.0)

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

	var bonus_radio = 0.0
	if jugador.has_method("obtener_radio_atraccion_extra"):
		bonus_radio = jugador.obtener_radio_atraccion_extra()
	var d = global_position.distance_to(jugador.global_position)
	if d < (radio_atraccion + bonus_radio):
		var dir = (jugador.global_position + Vector3(0, 0.8, 0) - global_position).normalized()
		var vel_actual = velocidad_iman + (bonus_radio * 0.85)
		global_position += dir * vel_actual * delta

func _on_body_entered(body):
	if recogido or body == null:
		return
	if body.is_in_group("jugador") or body.is_in_group("player"):
		recogido = true
		if body.has_method("recoger_drop"):
			body.recoger_drop(tipo, valor)
		queue_free()
