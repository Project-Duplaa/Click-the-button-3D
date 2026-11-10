extends CharacterBody3D

# Gólem Ígneo Kamikaze - Enemigo Explosivo Táctico
# Avanza rápidamente hacia el jugador. Al acercarse a menos de 2.2 m, activa su mecha durante 0.95 s y detona en un área masiva, dañando al jugador y a enemigos adyacentes.

const AudioManager = preload("res://audio_manager.gd")

@export var rapidez: float = 4.0
@export var vida_maxima: float = 18.0
@export var radio_explosion: float = 4.5
@export var dano_a_jugador: float = 18.0
@export var dano_a_enemigos: float = 35.0
@export var tiempo_mecha: float = 0.95

var vida: float = 18.0
var jugador: Node3D = null
var _armado: bool = false
var _detonado: bool = false
var _tiempo_restante_mecha: float = 0.95
var _reloj_efecto: float = 0.0

@onready var nucleo_fuego: MeshInstance3D = $NucleoFuego
@onready var anillo_magma: MeshInstance3D = $AnilloMagma
@onready var luz_fuego: OmniLight3D = $LuzFuego

func _ready():
	add_to_group("enemigos")
	add_to_group("kamikazes")
	vida = vida_maxima
	jugador = get_tree().get_first_node_in_group("jugador")

func _physics_process(delta):
	if _detonado:
		return
		
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			move_and_slide()
			return
			
	var pos_jugador = jugador.global_position
	var dif = pos_jugador - global_position
	dif.y = 0.0
	var dist = dif.length()
	
	_reloj_efecto += delta * 6.0
	if anillo_magma != null:
		anillo_magma.rotate_y(delta * 4.0)
		anillo_magma.rotate_x(delta * 2.5)
		
	if _armado:
		# Frenado y cuenta regresiva de explosión
		velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
		
		_tiempo_restante_mecha -= delta
		
		# Parpadeo rápido y expansión visual
		var pulso = sin(_reloj_efecto * 4.0) * 0.5 + 0.5
		if nucleo_fuego != null:
			var s = 1.0 + (1.0 - (_tiempo_restante_mecha / tiempo_mecha)) * 0.6 + pulso * 0.15
			nucleo_fuego.scale = Vector3(s, s, s)
		if luz_fuego != null:
			luz_fuego.light_energy = 3.0 + pulso * 3.0
			luz_fuego.light_color = Color(1.0, 0.2, 0.1).lerp(Color(1.0, 0.9, 0.2), pulso)
			
		if _tiempo_restante_mecha <= 0.0:
			detonar()
	else:
		# Persecución continua
		if dist <= 2.2:
			_iniciar_mecha()
		else:
			var dir = dif.normalized()
			velocity.x = dir.x * rapidez
			velocity.z = dir.z * rapidez
			if dif.length_squared() > 0.01:
				basis = Basis.looking_at(dir)
				
	move_and_slide()

func _iniciar_mecha():
	if _armado:
		return
	_armado = true
	_tiempo_restante_mecha = tiempo_mecha
	AudioManager.play("alerta_oleada", 2.2, -3.0)

func recibir_dano(cantidad: float, es_critico: bool = false):
	vida -= cantidad
	
	var escena_num = load("res://damage_number_3d.tscn")
	if escena_num != null:
		var n = escena_num.instantiate()
		var pos_num = global_position + Vector3(randf_range(-0.2, 0.2), 1.5, randf_range(-0.2, 0.2))
		get_parent().add_child(n)
		n.global_position = pos_num
		n.iniciar(cantidad, es_critico, false)
		
	if vida <= 0.0:
		# Al ser derrotado también detona inmediatamente
		detonar()

func detonar():
	if _detonado:
		return
	_detonado = true
	
	AudioManager.play("orbe_explosion", 0.9)
	
	# Daño al jugador si está en radio
	if jugador != null and is_instance_valid(jugador):
		var dist_j = global_position.distance_to(jugador.global_position)
		if dist_j <= radio_explosion:
			if jugador.has_node("Salud"):
				jugador.get_node("Salud").recibir_golpe(int(dano_a_jugador))
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(dano_a_jugador)
				
	# Daño a otros enemigos (Fuego amigo táctico)
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if e != self and is_instance_valid(e) and e is Node3D:
			var dist_e = global_position.distance_to(e.global_position)
			if dist_e <= radio_explosion:
				if e.has_method("recibir_dano"):
					e.recibir_dano(dano_a_enemigos)
				var dir_empuje = (e.global_position - global_position).normalized()
				dir_empuje.y = 0.0
				if "velocity" in e:
					e.velocity += dir_empuje * 10.0
					
	# Recompensa por baja
	if jugador != null and jugador.has_method("registrar_baja"):
		jugador.registrar_baja()
		
	# Efecto visual de onda explosiva de fuego
	_crear_onda_explosion()

func _crear_onda_explosion():
	if not is_inside_tree() or get_parent() == null:
		queue_free()
		return
		
	var onda = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.45, 0.1, 0.9)
	mesh.material = mat
	onda.mesh = mesh
	
	get_parent().add_child(onda)
	onda.global_position = global_position
	
	if nucleo_fuego != null:
		nucleo_fuego.visible = false
	if anillo_magma != null:
		anillo_magma.visible = false
		
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(onda, "scale", Vector3.ONE * (radio_explosion * 2.0), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.22)
	if luz_fuego != null:
		tw.tween_property(luz_fuego, "light_energy", 0.0, 0.22)
	tw.chain().tween_callback(func():
		onda.queue_free()
		queue_free()
	)
