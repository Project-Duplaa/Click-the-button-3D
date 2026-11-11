extends Area3D

enum TipoDrop { ORO, EXP, CORAZON }

@export var tipo: TipoDrop = TipoDrop.ORO
@export var valor: int = 5
@export var velocidad_iman: float = 7.0
@export var radio_atraccion: float = 3.5

var jugador: Node3D = null
var recogido = false

func _ready():
	body_entered.connect(_on_body_entered)
	jugador = get_tree().get_first_node_in_group("jugador")
	_actualizar_aspecto()

func iniciar(nuevo_tipo: int, nuevo_valor: int):
	tipo = nuevo_tipo as TipoDrop
	valor = nuevo_valor
	if not is_inside_tree():
		await ready
	_actualizar_aspecto()

func _actualizar_aspecto():
	var mesh_inst = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_inst == null:
		return
	var mat = StandardMaterial3D.new()
	mat.metallic = 0.8
	mat.roughness = 0.2
	mat.emission_enabled = true
	match tipo:
		TipoDrop.EXP:
			mat.albedo_color = Color(0.15, 0.75, 1.0, 1.0)
			mat.emission = Color(0.1, 0.6, 1.0, 1.0)
			mat.emission_energy_multiplier = 0.8
		TipoDrop.CORAZON:
			mat.albedo_color = Color(1.0, 0.2, 0.3, 1.0)
			mat.emission = Color(1.0, 0.15, 0.25, 1.0)
			mat.emission_energy_multiplier = 0.8
		_:
			mat.albedo_color = Color(1.0, 0.84, 0.0, 1.0)
			mat.emission = Color(1.0, 0.8, 0.1, 1.0)
			mat.emission_energy_multiplier = 0.5
	mesh_inst.set_surface_override_material(0, mat)

func _process(delta):
	# Rotación continua
	rotate_y(2.5 * delta)
	
	if recogido:
		return
		
	if jugador != null:
		var bonus_radio = 0.0
		if jugador.has_method("obtener_radio_atraccion_extra"):
			bonus_radio = jugador.obtener_radio_atraccion_extra()
		var d = global_position.distance_to(jugador.global_position)
		if d < (radio_atraccion + bonus_radio):
			var dir = (jugador.global_position + Vector3(0, 0.8, 0) - global_position).normalized()
			var vel_actual = velocidad_iman + (bonus_radio * 0.75)
			global_position += dir * vel_actual * delta

func _on_body_entered(body):
	if recogido:
		return
	if body.is_in_group("jugador"):
		recogido = true
		if body.has_method("recoger_drop"):
			body.recoger_drop(tipo, valor)
		queue_free()
