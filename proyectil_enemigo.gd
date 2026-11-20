extends Area3D

const AudioManager = preload("res://audio_manager.gd")

@export var rapidez: float = 5.5
@export var dano: float = 11.0
@export var tiempo_vida: float = 4.0

var direccion: Vector3 = Vector3.FORWARD
var _tiempo: float = 0.0
var _impactado: bool = false

@onready var mesh_flecha: MeshInstance3D = $MeshInstance3D
@onready var luz: OmniLight3D = get_node_or_null("OmniLight3D")

func _ready():
	add_to_group("proyectiles_enemigos")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func iniciar(origen: Vector3, dir: Vector3, dano_in: float = 11.0, vel_in: float = 5.5):
	global_position = origen
	direccion = dir.normalized()
	dano = dano_in
	rapidez = vel_in
	_mirar_hacia(direccion)

func _mirar_hacia(dir: Vector3):
	if dir.length_squared() > 0.001 and absf(dir.dot(Vector3.UP)) < 0.999:
		look_at(global_position + dir, Vector3.UP)

func _physics_process(delta):
	if _impactado:
		return
	global_position += direccion * rapidez * delta
	_tiempo += delta
	if _tiempo >= tiempo_vida:
		queue_free()

func _on_body_entered(body):
	if _impactado:
		return
	if body.is_in_group("enemigos"):
		return
		
	if body.is_in_group("jugador"):
		_impactar_jugador(body)
	elif body is StaticBody3D:
		_impactar_obstaculo()

func _on_area_entered(area):
	if _impactado:
		return
	if area.is_in_group("boton_movil"):
		# El botón móvil absorbe o desvía el proyectil con una onda
		_impactar_obstaculo()

func _impactar_jugador(jugador: Node):
	_impactado = true
	AudioManager.play("impacto_flecha", 0.95)
	
	if jugador.has_method("recibir_dano"):
		jugador.recibir_dano(dano)
	elif jugador.has_node("Salud"):
		jugador.get_node("Salud").recibir_golpe(int(dano))
		
	_desaparecer_con_efecto()

func _impactar_obstaculo():
	_impactado = true
	AudioManager.play("impacto_flecha", 1.25)
	_desaparecer_con_efecto()

func disipar_inmediatamente() -> void:
	if _impactado:
		return
	_impactado = true
	monitoring = false
	monitorable = false
	set_physics_process(false)
	if is_in_group("proyectiles_enemigos"):
		remove_from_group("proyectiles_enemigos")

	var tw := create_tween()
	tw.set_parallel(true)
	if luz != null:
		tw.tween_property(luz, "light_energy", 0.0, 0.14)
	if mesh_flecha != null:
		tw.tween_property(mesh_flecha, "scale", Vector3.ZERO, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	else:
		tw.tween_property(self, "scale", Vector3.ZERO, 0.14)
	tw.chain().tween_callback(queue_free)

static var _mat_chispa_dorada: StandardMaterial3D = null

static func _obtener_mat_chispa_dorada() -> StandardMaterial3D:
	if _mat_chispa_dorada == null:
		_mat_chispa_dorada = StandardMaterial3D.new()
		_mat_chispa_dorada.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat_chispa_dorada.albedo_color = Color(1.0, 0.92, 0.38, 1.0)
		_mat_chispa_dorada.emission_enabled = true
		_mat_chispa_dorada.emission = Color(1.0, 0.84, 0.16, 1.0)
		_mat_chispa_dorada.emission_energy_multiplier = 2.6
	return _mat_chispa_dorada

func disipar_por_onda_dorada(retraso: float = 0.0) -> void:
	if _impactado:
		return
	# Neutralización inmediata de colisión y física en t = 0 (cero daño fantasma)
	_impactado = true
	monitoring = false
	monitorable = false
	set_physics_process(false)
	if is_in_group("proyectiles_enemigos"):
		remove_from_group("proyectiles_enemigos")

	if not is_inside_tree():
		queue_free()
		return

	var delay_seguro := clampf(retraso, 0.0, 0.45)
	var tw := create_tween()
	if delay_seguro > 0.015:
		tw.tween_interval(delay_seguro)
	tw.tween_callback(_iniciar_disolucion_dorada)

func _iniciar_disolucion_dorada() -> void:
	if not is_instance_valid(self) or not is_inside_tree():
		return
	if mesh_flecha != null:
		mesh_flecha.material_override = _obtener_mat_chispa_dorada()
	if luz != null:
		luz.light_color = Color(1.0, 0.88, 0.30, 1.0)

	var tw := create_tween()
	if mesh_flecha != null:
		var esc_orig := mesh_flecha.scale
		tw.tween_property(mesh_flecha, "scale", esc_orig * 1.42, 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(mesh_flecha, "scale", Vector3.ZERO, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		tw.tween_property(self, "scale", Vector3.ZERO, 0.12)
	if luz != null:
		tw.parallel().tween_property(luz, "light_energy", 0.0, 0.14)
	tw.chain().tween_callback(queue_free)

func _desaparecer_con_efecto():
	monitoring = false
	monitorable = false
	set_physics_process(false)
	if is_in_group("proyectiles_enemigos"):
		remove_from_group("proyectiles_enemigos")
	# Destello final y remoción
	if luz != null:
		var tw = create_tween()
		tw.tween_property(luz, "light_energy", 0.0, 0.12)
	if mesh_flecha != null:
		var tw_m = create_tween()
		tw_m.tween_property(mesh_flecha, "scale", Vector3.ZERO, 0.12)
		tw_m.chain().tween_callback(queue_free)
	else:
		queue_free()
