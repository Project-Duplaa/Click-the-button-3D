extends CharacterBody3D

# Mini-Jefe: Gladiador de Élite de la Arena
# Desarrollado por: Juan Camilo Angulo Camelo
# Mini-jefe colosal con barra de vida en pantalla y ataques de carga telegrafiados en el suelo.

signal jefe_derrotado

const AudioManager = preload("res://audio_manager.gd")

@export var rapidez: float = 3.2
@export var vida_maxima: float = 650.0
@export var dano_golpe: float = 30.0
@export var rango_ataque: float = 3.2
@export var tiempo_telegraph: float = 0.75

var vida: float = 650.0
var jugador: Node3D = null
var hud: Node = null

var _reloj_ataque: float = 0.0
var _esta_telegrafando: bool = false
var _posicion_ataque_telegraph: Vector3 = Vector3.ZERO

@onready var telegraph_mesh: MeshInstance3D = $TelegraphSuelo
@onready var modelo: Node3D = $Modelo

func _ready():
	add_to_group("enemigos")
	add_to_group("jefes")
	vida = vida_maxima
	jugador = get_tree().get_first_node_in_group("jugador")
	hud = get_tree().get_first_node_in_group("hud")
	if hud == null:
		hud = get_parent().get_node_or_null("ClickHUD")
		
	if telegraph_mesh != null:
		telegraph_mesh.visible = false
		
	AudioManager.play("jefe_alerta", 1.15)
	
	if hud != null and hud.has_method("mostrar_barra_jefe"):
		hud.mostrar_barra_jefe("⚔️ MINI-JEFE: GLADIADOR DE ÉLITE", vida_maxima, vida)

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if _esta_telegrafando:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
		move_and_slide()
		return
		
	_reloj_ataque = maxf(_reloj_ataque - delta, 0.0)
	
	if is_instance_valid(jugador) and jugador is Node3D:
		var dir = (jugador.global_position - global_position)
		dir.y = 0.0
		var dist = dir.length()
		
		if dist > 0.1:
			look_at(global_position + dir.normalized(), Vector3.UP)
			
		if dist <= rango_ataque and _reloj_ataque <= 0.001:
			_iniciar_ataque_telegrafiado()
		else:
			var dir_mov = dir.normalized()
			velocity.x = dir_mov.x * rapidez
			velocity.z = dir_mov.z * rapidez
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		
	move_and_slide()

func _iniciar_ataque_telegrafiado():
	_esta_telegrafando = true
	_posicion_ataque_telegraph = global_position
	
	# Mostrar marca roja visual en el suelo
	if telegraph_mesh != null:
		telegraph_mesh.visible = true
		telegraph_mesh.scale = Vector3(0.2, 1.0, 0.2)
		var tw = create_tween()
		tw.tween_property(telegraph_mesh, "scale", Vector3(1.0, 1.0, 1.0), tiempo_telegraph).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	get_tree().create_timer(tiempo_telegraph).timeout.connect(_ejecutar_golpe_telegrafiado)

func _ejecutar_golpe_telegrafiado():
	if telegraph_mesh != null:
		telegraph_mesh.visible = false
	_esta_telegrafando = false
	_reloj_ataque = 1.4
	
	AudioManager.play("danio_jugador", 0.8)
	
	# Verificar si el jugador está dentro del rango del telegraph
	if is_instance_valid(jugador) and jugador is Node3D:
		var dist = global_position.distance_to(jugador.global_position)
		if dist <= rango_ataque + 1.2:
			if jugador.has_node("Salud"):
				jugador.get_node("Salud").recibir_golpe(int(dano_golpe))
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(dano_golpe)

func recibir_dano(cantidad: float, es_critico: bool = false):
	vida = maxf(vida - cantidad, 0.0)
	
	# Feedback numérico
	var escena_num = load("res://damage_number_3d.tscn")
	if escena_num != null:
		var n = escena_num.instantiate()
		var pos_num = global_position + Vector3(randf_range(-0.4, 0.4), 2.8, randf_range(-0.4, 0.4))
		get_parent().add_child(n)
		n.global_position = pos_num
		n.iniciar(cantidad, es_critico, false)
		
	# Actualizar barra superior del HUD
	if hud != null and hud.has_method("actualizar_barra_jefe"):
		hud.actualizar_barra_jefe(vida)
		
	if vida <= 0.0:
		morir()

func morir():
	print("¡Mini-Jefe Gladiador de Élite DERROTADO!")
	if hud != null and hud.has_method("ocultar_barra_jefe"):
		hud.ocultar_barra_jefe()
		
	AudioManager.play("enemigo_muerte", 0.7)
	
	var pj = get_tree().get_first_node_in_group("jugador")
	if pj != null and pj.has_method("registrar_baja"):
		pj.registrar_baja()
		
	# Botín abundante
	var drop_escena = load("res://drop_item.tscn")
	if drop_escena != null:
		for i in range(8):
			var d = drop_escena.instantiate()
			get_parent().add_child(d)
			var ang = randf() * TAU
			var dist = randf_range(1.0, 3.5)
			d.global_position = global_position + Vector3(cos(ang) * dist, 0.5, sin(ang) * dist)
			if d.has_method("iniciar"):
				d.iniciar(randi() % 2, randi_range(20, 40))
				
	emit_signal("jefe_derrotado")
	queue_free()
