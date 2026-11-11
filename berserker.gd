extends CharacterBody3D

# Gladiador Berserker - Enemigo de Choque y Carga Furiosa
# Desarrollado para Clicklike 3D
# Al detectar al jugador en un rango de 8.5 m, se prepara con un rugido y ejecuta una embestida frontal a alta velocidad.

enum Estado { PERSEGUIR, PREPARAR_CARGA, CARGAR, ATURDIDO }

const AudioManager = preload("res://audio_manager.gd")

@export var rapidez_caminar: float = 2.4
@export var rapidez_carga: float = 7.5
@export var vida_maxima: float = 55.0
@export var dano_carga: float = 16.0
@export var tiempo_telegraph_carga: float = 0.65
@export var duracion_carga: float = 1.1
@export var tiempo_aturdido: float = 1.2
@export var cadencia_carga: float = 4.5

var vida: float = 55.0
var estado: Estado = Estado.PERSEGUIR
var jugador: Node3D = null

var _reloj_cooldown_carga: float = 2.0
var _reloj_estado: float = 0.0
var _dir_carga: Vector3 = Vector3.FORWARD
var _escala_base: Vector3 = Vector3(-2.6, 2.6, -2.6)

@onready var modelo: Node3D = $Modelo
@onready var anim = $Modelo/AnimationPlayer if has_node("Modelo/AnimationPlayer") else null
@onready var luz_furia: OmniLight3D = $LuzFuria
@onready var linea_carga: MeshInstance3D = $LineaCarga

func _ready():
	add_to_group("enemigos")
	add_to_group("berserkers")
	vida = vida_maxima
	if modelo != null:
		_escala_base = modelo.scale
	jugador = get_tree().get_first_node_in_group("jugador")
	if linea_carga != null:
		linea_carga.visible = false
	if luz_furia != null:
		luz_furia.light_energy = 0.5

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	_reloj_cooldown_carga = maxf(_reloj_cooldown_carga - delta, 0.0)
	
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			move_and_slide()
			return
			
	var pos_jugador = jugador.global_position
	var dif = pos_jugador - global_position
	dif.y = 0.0
	var dist = dif.length()
	
	match estado:
		Estado.PERSEGUIR:
			if dist <= 8.5 and _reloj_cooldown_carga <= 0.001:
				_iniciar_preparacion_carga(dif.normalized())
			else:
				var dir = dif.normalized()
				velocity.x = dir.x * rapidez_caminar
				velocity.z = dir.z * rapidez_caminar
				if dif.length_squared() > 0.01:
					basis = Basis.looking_at(dir)
				if anim != null and anim.has_animation("walk"):
					anim.play("walk")
					
		Estado.PREPARAR_CARGA:
			# Frena y apunta con advertencia roja luminosa
			velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
			if anim != null and anim.has_animation("idle"):
				anim.play("idle")
				
			_reloj_estado -= delta
			if _reloj_estado <= 0.0:
				_ejecutar_carga()
				
		Estado.CARGAR:
			# Embestida a toda velocidad en línea recta
			velocity.x = _dir_carga.x * rapidez_carga
			velocity.z = _dir_carga.z * rapidez_carga
			if anim != null and anim.has_animation("sprint"):
				anim.play("sprint")
				
			_reloj_estado -= delta
			
			# Chequear impacto físico directo contra el jugador durante la carga
			if dist <= 1.4:
				_impactar_jugador_en_carga()
				
			if _reloj_estado <= 0.0:
				_finalizar_carga_aturdido()
				
		Estado.ATURDIDO:
			# Queda vulnerable y frenado tras embestir
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			if anim != null and anim.has_animation("idle"):
				anim.play("idle")
				
			_reloj_estado -= delta
			if _reloj_estado <= 0.0:
				estado = Estado.PERSEGUIR
				_reloj_cooldown_carga = cadencia_carga
				
	move_and_slide()

func _iniciar_preparacion_carga(dir_hacia_jugador: Vector3):
	estado = Estado.PREPARAR_CARGA
	_dir_carga = dir_hacia_jugador
	basis = Basis.looking_at(_dir_carga)
	_reloj_estado = tiempo_telegraph_carga
	
	AudioManager.play("alerta_oleada", 1.8, -4.0)
	
	if linea_carga != null:
		linea_carga.visible = true
	if luz_furia != null:
		var tw = create_tween()
		tw.tween_property(luz_furia, "light_energy", 3.5, tiempo_telegraph_carga)

func _ejecutar_carga():
	estado = Estado.CARGAR
	_reloj_estado = duracion_carga
	if linea_carga != null:
		linea_carga.visible = false
	AudioManager.play("golpe_impacto", 0.8)

func _impactar_jugador_en_carga():
	if jugador != null:
		if jugador.has_method("recibir_dano"):
			jugador.recibir_dano(dano_carga)
		elif jugador.has_node("Salud"):
			jugador.get_node("Salud").recibir_golpe(int(dano_carga))
			
	AudioManager.play("golpe_impacto", 1.25)
	_finalizar_carga_aturdido()

func _finalizar_carga_aturdido():
	estado = Estado.ATURDIDO
	_reloj_estado = tiempo_aturdido
	if luz_furia != null:
		luz_furia.light_energy = 0.5
	if linea_carga != null:
		linea_carga.visible = false

func recibir_dano(cantidad: float, es_critico: bool = false):
	vida -= cantidad
	
	# Shudder de golpe
	if modelo != null:
		var tw = create_tween()
		tw.tween_property(modelo, "scale", _escala_base * 1.15, 0.05)
		tw.tween_property(modelo, "scale", _escala_base, 0.08)
		
	# Damage number
	var escena_num = load("res://damage_number_3d.tscn")
	if escena_num != null:
		var n = escena_num.instantiate()
		var pos_num = global_position + Vector3(randf_range(-0.3, 0.3), 2.2, randf_range(-0.3, 0.3))
		get_parent().add_child(n)
		n.global_position = pos_num
		n.iniciar(cantidad, es_critico, false)
		
	if vida <= 0.0:
		morir()

func morir():
	if linea_carga != null:
		linea_carga.visible = false
		
	var drop_escena = load("res://drop_item.tscn")
	if drop_escena != null:
		var d = drop_escena.instantiate()
		get_parent().add_child(d)
		d.global_position = global_position + Vector3(0, 0.4, 0)
		if d.has_method("iniciar"):
			d.iniciar(0, randi_range(6, 12)) # Recompensa de oro
			
	if jugador != null and jugador.has_method("registrar_baja"):
		jugador.registrar_baja()
		
	queue_free()
