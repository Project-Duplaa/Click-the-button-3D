extends Area3D

const AudioManager = preload("res://audio_manager.gd")

# Orbe Arcano - Especialidad de la Clase Mago
# Desarrollado por: Juan Camilo Angulo Camelo
# Proyectil arcano teledirigido con detonación y daño en área (AOE).

@export var rapidez: float = 13.5
@export var dano: float = 28.0
@export var radio_aoe: float = 3.2
@export var tiempo_vida: float = 3.0
@export var fuerza_teledirigida: float = 4.5

var direccion: Vector3 = Vector3.FORWARD
var objetivo_enemigo: Node3D = null
var _tiempo: float = 0.0
var _ha_detonado: bool = false

@onready var mesh_orbe: MeshInstance3D = $MeshInstance3D
@onready var luz_magica: OmniLight3D = get_node_or_null("OmniLight3D")

func _ready():
	add_to_group("proyectiles_jugador")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	AudioManager.play("orbe_lanzar", randf_range(0.9, 1.1))

func _mirar_hacia(dir: Vector3):
	if dir.length_squared() > 0.001 and absf(dir.dot(Vector3.UP)) < 0.999:
		look_at(global_position + dir, Vector3.UP)

func iniciar(origen: Vector3, dir: Vector3, dano_in: float, objetivo: Node3D = null):
	global_position = origen
	direccion = dir.normalized()
	dano = dano_in
	objetivo_enemigo = objetivo
	_mirar_hacia(direccion)

func _physics_process(delta):
	if _ha_detonado:
		return
		
	# Seguimiento teledirigido suave si el objetivo sigue vivo
	if is_instance_valid(objetivo_enemigo) and objetivo_enemigo is Node3D:
		var dir_hacia = (objetivo_enemigo.global_position + Vector3(0, 0.9, 0) - global_position).normalized()
		direccion = direccion.lerp(dir_hacia, fuerza_teledirigida * delta).normalized()
		_mirar_hacia(direccion)
		
	global_position += direccion * rapidez * delta
	
	# Efecto pulsante de energía arcana
	_tiempo += delta
	if mesh_orbe != null:
		mesh_orbe.rotate_z(delta * 8.0)
		mesh_orbe.rotate_y(delta * 6.0)
		
	if _tiempo >= tiempo_vida:
		detonar_aoe()

func _on_body_entered(body):
	if _ha_detonado:
		return
	if body.is_in_group("jugador"):
		return
	if body.is_in_group("enemigos") or body is StaticBody3D or body is CSGBox3D:
		detonar_aoe()

func _on_area_entered(area):
	if _ha_detonado:
		return
	if area.is_in_group("enemigos") or area.is_in_group("rompibles"):
		detonar_aoe()

func detonar_aoe():
	if _ha_detonado:
		return
	_ha_detonado = true
	
	# 1. Reproducir sonido de detonación
	AudioManager.play("orbe_explosion", randf_range(0.9, 1.15))
	
	# 2. Daño en área (AOE) a todos los enemigos en el radio
	if is_inside_tree() and get_tree() != null:
		var objetivos: Array = []
		objetivos.append_array(get_tree().get_nodes_in_group("enemigos"))
		objetivos.append_array(get_tree().get_nodes_in_group("rompibles"))
		for e in objetivos:
			if is_instance_valid(e) and e is Node3D:
				var dist = global_position.distance_to(e.global_position)
				if dist <= radio_aoe:
					# Atenuación lineal según la distancia al centro de la explosión
					var factor_dist = clampf(1.0 - (dist / radio_aoe) * 0.4, 0.6, 1.0)
					var dano_final = dano * factor_dist
					if e.has_method("recibir_dano"):
						e.recibir_dano(dano_final)
					
	# 3. Efecto visual de onda expansiva mágica
	_generar_efecto_explosion()

func _generar_efecto_explosion():
	if not is_inside_tree() or get_parent() == null:
		queue_free()
		return
	var onda = MeshInstance3D.new()
	var esfera_mesh = SphereMesh.new()
	esfera_mesh.radius = 0.5
	esfera_mesh.height = 1.0
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.7, 0.3, 1.0, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.4, 1.0)
	mat.emission_energy_multiplier = 3.0
	esfera_mesh.material = mat
	
	onda.mesh = esfera_mesh
	get_parent().add_child(onda)
	onda.global_position = global_position
	
	if mesh_orbe != null:
		mesh_orbe.visible = false
	if luz_magica != null:
		luz_magica.light_energy = 4.0
		
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(onda, "scale", Vector3.ONE * (radio_aoe * 1.8), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.28)
	if luz_magica != null:
		tw.tween_property(luz_magica, "light_energy", 0.0, 0.28)
	tw.chain().tween_callback(func():
		onda.queue_free()
		queue_free()
	)
