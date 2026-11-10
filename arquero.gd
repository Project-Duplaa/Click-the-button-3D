extends CharacterBody3D

# Arquero / Cultista de la Arena - Enemigo Táctico a Distancia
# Desarrollado para Clicklike 3D
# Mantiene distancia táctica (kiting inverso), apunta con rayo telegrafiado visible y dispara proyectiles esquivables.

enum Estado { ACERCAR, HUIR, APUNTAR, ESPERAR }

const AudioManager = preload("res://audio_manager.gd")
const ProyectilEnemigoEscena = preload("res://proyectil_enemigo.tscn")

@export var vida_maxima: float = 20.0
@export var dano_disparo: float = 5.0
@export var rapidez_caminar: float = 2.0
@export var rapidez_huir: float = 2.4
@export var cadencia_disparo: float = 3.6
@export var tiempo_apuntar: float = 0.85
@export var distancia_huida: float = 5.0
@export var distancia_maxima: float = 11.0

var vida: float = 20.0
var estado: Estado = Estado.ACERCAR
var jugador: Node3D = null
var _reloj_disparo: float = 0.0
var _reloj_apuntando: float = 0.0
var _escala_base: Vector3 = Vector3(-2.4, 2.4, -2.4)

@onready var modelo: Node3D = $Modelo
@onready var anim = $Modelo/AnimationPlayer if has_node("Modelo/AnimationPlayer") else null
@onready var laser_apuntado: MeshInstance3D = $LaserApuntado
@onready var luz_arco: OmniLight3D = $LuzArco

func _ready():
	add_to_group("enemigos")
	add_to_group("arqueros")
	vida = vida_maxima
	if modelo != null:
		_escala_base = modelo.scale
	jugador = get_tree().get_first_node_in_group("jugador")
	if laser_apuntado != null:
		laser_apuntado.visible = false
	_reloj_disparo = randf_range(0.5, 1.5)

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	_reloj_disparo = maxf(_reloj_disparo - delta, 0.0)
	
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			move_and_slide()
			return
			
	var pos_jugador = jugador.global_position
	var dif = pos_jugador - global_position
	dif.y = 0.0
	var dist = dif.length()
	
	# Mirar siempre al jugador
	if dif.length_squared() > 0.01:
		var dir_cara = dif.normalized()
		basis = Basis.looking_at(dir_cara)
		
	# FSM de Comportamiento Táctico
	match estado:
		Estado.ACERCAR:
			if laser_apuntado != null:
				laser_apuntado.visible = false
			if dist < distancia_huida:
				estado = Estado.HUIR
			elif dist <= distancia_maxima and _reloj_disparo <= 0.001:
				_comenzar_apuntado()
			else:
				var dir = dif.normalized()
				velocity.x = dir.x * rapidez_caminar
				velocity.z = dir.z * rapidez_caminar
				if anim != null and anim.has_animation("walk"):
					anim.play("walk")
					
		Estado.HUIR:
			# Kiting inverso: retrocede alejándose del héroe
			if laser_apuntado != null:
				laser_apuntado.visible = false
			if dist >= distancia_huida + 2.0:
				estado = Estado.ACERCAR
			else:
				var dir_huida = -dif.normalized()
				velocity.x = dir_huida.x * rapidez_huir
				velocity.z = dir_huida.z * rapidez_huir
				if anim != null and anim.has_animation("walk"):
					anim.play("walk")
					
		Estado.APUNTAR:
			# Quieto, cargando el disparo con el rayo de advertencia hacia el jugador
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			if anim != null and anim.has_animation("idle"):
				anim.play("idle")
				
			_actualizar_laser(pos_jugador)
			_reloj_apuntando -= delta
			if _reloj_apuntando <= 0.0:
				_disparar_flecha(pos_jugador)
				
		Estado.ESPERAR:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			if _reloj_disparo <= 0.001:
				estado = Estado.ACERCAR
				
	move_and_slide()

func _comenzar_apuntado():
	estado = Estado.APUNTAR
	_reloj_apuntando = tiempo_apuntar
	if laser_apuntado != null:
		laser_apuntado.visible = true
	if luz_arco != null:
		var tw = create_tween()
		tw.tween_property(luz_arco, "light_energy", 3.0, tiempo_apuntar * 0.7)

func _actualizar_laser(pos_objetivo: Vector3):
	if laser_apuntado == null:
		return
	var inicio = global_position + Vector3(0, 1.0, 0)
	var fin = pos_objetivo + Vector3(0, 0.9, 0)
	var largo = inicio.distance_to(fin)
	laser_apuntado.position = Vector3(0, 1.0, -largo * 0.5)
	laser_apuntado.scale = Vector3(0.04, 0.04, largo)

func _disparar_flecha(pos_objetivo: Vector3):
	if laser_apuntado != null:
		laser_apuntado.visible = false
	if luz_arco != null:
		luz_arco.light_energy = 0.5
		
	estado = Estado.ESPERAR
	_reloj_disparo = cadencia_disparo
	
	# Procedural recoil del arquero
	if modelo != null:
		var tw_recoil = create_tween()
		tw_recoil.tween_property(modelo, "position:z", 0.35, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_recoil.tween_property(modelo, "position:z", 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	AudioManager.play("disparo_arquero", randf_range(0.95, 1.1))
	
	# Instanciar proyectil enemigo
	var origen = global_position + Vector3(0, 1.0, 0)
	var destino = pos_objetivo + Vector3(0, 0.9, 0)
	var dir = (destino - origen).normalized()
	
	var p = ProyectilEnemigoEscena.instantiate()
	get_parent().add_child(p)
	p.iniciar(origen, dir, dano_disparo, 5.5)

func recibir_dano(cantidad: float, es_critico: bool = false):
	vida -= cantidad
	
	# Shudder visual
	if modelo != null:
		var tw = create_tween()
		tw.tween_property(modelo, "scale", _escala_base * 1.15, 0.05)
		tw.tween_property(modelo, "scale", _escala_base, 0.08)
		
	# Damage Number 3D
	var escena_num = load("res://damage_number_3d.tscn")
	if escena_num != null:
		var n = escena_num.instantiate()
		var pos_num = global_position + Vector3(randf_range(-0.25, 0.25), 1.8, randf_range(-0.25, 0.25))
		get_parent().add_child(n)
		n.global_position = pos_num
		n.iniciar(cantidad, es_critico, false)
		
	if vida <= 0.0:
		morir()

func morir():
	if laser_apuntado != null:
		laser_apuntado.visible = false
		
	# Soltar recompensas
	var drop_escena = load("res://drop_item.tscn")
	if drop_escena != null:
		var d = drop_escena.instantiate()
		get_parent().add_child(d)
		d.global_position = global_position + Vector3(0, 0.4, 0)
		if d.has_method("iniciar"):
			# El arquero arroja principalmente gemas de XP
			d.iniciar(1, randi_range(8, 14))
			
	if jugador != null and jugador.has_method("registrar_baja"):
		jugador.registrar_baja()
		
	queue_free()
