extends CharacterBody3D

enum Estado { ACERCAR, HUIR, APUNTAR, ESPERAR }

const AudioManager = preload("res://audio_manager.gd")
const ProyectilEnemigoEscena = preload("res://proyectil_enemigo.tscn")

@export var vida_maxima: float = 18.0
@export var dano_disparo: float = 5.0
@export var rapidez_caminar: float = 2.0
@export var rapidez_huir: float = 2.4
@export var cadencia_disparo: float = 3.8
@export var tiempo_apuntar: float = 0.85
@export var distancia_huida: float = 5.0
@export var distancia_maxima: float = 11.0

var vida: float = 18.0
var estado: Estado = Estado.ACERCAR
var jugador: Node3D = null
var _reloj_disparo: float = 0.0
var _reloj_apuntando: float = 0.0
var _escala_base: Vector3 = Vector3.ONE
var _muerto: bool = false
var _anim_ctrl: AnimadorEntidad = AnimadorEntidad.new()

var knockback_vel: Vector3 = Vector3.ZERO
var resistencia_knockback: float = 0.0
var _stun_timer: float = 0.0
var marca_conductiva_timer: float = 0.0

@onready var modelo: Node3D = $Modelo if has_node("Modelo") else null
@onready var anim = $Modelo/AnimationPlayer if has_node("Modelo/AnimationPlayer") else null
@onready var laser_apuntado: MeshInstance3D = $LaserApuntado if has_node("LaserApuntado") else null
@onready var luz_arco: OmniLight3D = $LuzArco if has_node("LuzArco") else null

func _ready():
	add_to_group("enemies")
	add_to_group("enemigos")
	add_to_group("arqueros")
	vida = vida_maxima
	if modelo != null:
		_escala_base = modelo.scale
		_anim_ctrl.vincular_modelo(modelo)
	jugador = get_tree().get_first_node_in_group("player")
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
	if laser_apuntado != null:
		laser_apuntado.visible = false
	_reloj_disparo = randf_range(0.5, 1.5)

func aplicar_knockback(impulso: Vector3, duracion_stun: float = 0.08) -> void:
	var factor: float = clampf(1.0 - resistencia_knockback, 0.1, 1.0)
	knockback_vel += Vector3(impulso.x, 0.0, impulso.z) * factor
	if knockback_vel.length() > 25.0:
		knockback_vel = knockback_vel.normalized() * 25.0
	_stun_timer = maxf(_stun_timer, duracion_stun * factor)
	if estado == Estado.APUNTAR and laser_apuntado != null:
		laser_apuntado.visible = false

func aplicar_marca_conductiva(duracion: float = 2.5) -> void:
	marca_conductiva_timer = maxf(marca_conductiva_timer, duracion)

func _physics_process(delta):
	if _muerto:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	_reloj_disparo = maxf(_reloj_disparo - delta, 0.0)
	_stun_timer = maxf(_stun_timer - delta, 0.0)
	marca_conductiva_timer = maxf(marca_conductiva_timer - delta, 0.0)
	_anim_ctrl.actualizar(delta)
	knockback_vel = knockback_vel.move_toward(Vector3.ZERO, 28.0 * delta)

	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("player")
		if jugador == null:
			jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			velocity.x = knockback_vel.x
			velocity.z = knockback_vel.z
			move_and_slide()
			return

	var pos_jugador = jugador.global_position
	var dif = pos_jugador - global_position
	dif.y = 0.0
	var dist = dif.length()

	if dif.length_squared() > 0.01:
		var dir_cara = dif.normalized()
		basis = Basis.looking_at(dir_cara)

	var mult_stun = 0.15 if _stun_timer > 0.0 else 1.0

	match estado:
		Estado.ACERCAR:
			if laser_apuntado != null:
				laser_apuntado.visible = false
			if dist < distancia_huida:
				estado = Estado.HUIR
			elif dist <= distancia_maxima and _reloj_disparo <= 0.001 and _stun_timer <= 0.0:
				_comenzar_apuntado()
			else:
				var dir = dif.normalized()
				velocity.x = dir.x * rapidez_caminar * mult_stun
				velocity.z = dir.z * rapidez_caminar * mult_stun
				if _stun_timer > 0.0:
					_anim_ctrl.reproducir_bucle("stunned", 0.10, 1.0, 1)
				else:
					_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), false, is_on_floor(), rapidez_caminar)
					
		Estado.HUIR:
			if laser_apuntado != null:
				laser_apuntado.visible = false
			if dist >= distancia_huida + 2.0:
				estado = Estado.ACERCAR
			else:
				var dir_huida = -dif.normalized()
				velocity.x = dir_huida.x * rapidez_huir * mult_stun
				velocity.z = dir_huida.z * rapidez_huir * mult_stun
				if _stun_timer > 0.0:
					_anim_ctrl.reproducir_bucle("stunned", 0.10, 1.0, 1)
				else:
					_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), false, is_on_floor(), rapidez_huir)
					
		Estado.APUNTAR:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			if _stun_timer > 0.0:
				_anim_ctrl.reproducir_bucle("stunned", 0.10, 1.0, 1)
			else:
				_anim_ctrl.reproducir_bucle("telegraph", 0.12, 1.0, 1)

			if _stun_timer <= 0.0:
				_actualizar_laser(pos_jugador)
				_reloj_apuntando -= delta
				if _reloj_apuntando <= 0.0:
					_disparar_flecha(pos_jugador)
			else:
				if laser_apuntado != null:
					laser_apuntado.visible = false

		Estado.ESPERAR:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			if _stun_timer > 0.0:
				_anim_ctrl.reproducir_bucle("stunned", 0.10, 1.0, 1)
			else:
				_anim_ctrl.actualizar_locomocion(0.0, false, is_on_floor(), rapidez_caminar)
			if _reloj_disparo <= 0.001 and _stun_timer <= 0.0:
				estado = Estado.ACERCAR

	velocity.x += knockback_vel.x
	velocity.z += knockback_vel.z
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
	_anim_ctrl.reproducir_accion("attack-ranged", 2, 0.06, 1.1)
	
	if modelo != null:
		var tw_recoil = create_tween()
		tw_recoil.tween_property(modelo, "position:z", 0.35, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_recoil.tween_property(modelo, "position:z", 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	AudioManager.play("disparo_arquero", randf_range(0.95, 1.1))

	var origen = global_position + Vector3(0, 1.0, 0)
	var destino = pos_objetivo + Vector3(0, 0.9, 0)
	var dir = (destino - origen).normalized()

	if ProyectilEnemigoEscena != null:
		var p = ProyectilEnemigoEscena.instantiate()
		get_parent().add_child(p)
		p.iniciar(origen, dir, dano_disparo, 5.5)

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false):
	if _muerto:
		return
	if typeof(fuente) == TYPE_BOOL:
		es_critico = fuente
		fuente = "normal"

	var cantidad_final: float = cantidad * (1.0 + MetaprogresoManager.obtener_bono_bestiario("arquero"))
	if marca_conductiva_timer > 0.0:
		cantidad_final *= 1.25

	vida -= cantidad_final
	_anim_ctrl.disparar_golpe()
	
	if modelo != null:
		var tw = create_tween()
		tw.tween_property(modelo, "scale", _escala_base * 1.15, 0.05)
		tw.tween_property(modelo, "scale", _escala_base, 0.08)

	_notificar_dano(cantidad_final, es_critico, str(fuente))

	if vida <= 0.0:
		morir()

func _notificar_dano(cantidad: float, es_critico: bool, fuente: String):
	var dmg_pool = get_tree().get_first_node_in_group("damage_numbers")
	if dmg_pool != null and dmg_pool.has_method("mostrar_dano"):
		dmg_pool.mostrar_dano(global_position + Vector3(0, 1.8, 0), int(round(cantidad)), es_critico, fuente)
	else:
		var escena_num = load("res://damage_number_3d.tscn")
		if escena_num != null and is_inside_tree() and get_parent() != null:
			var n = escena_num.instantiate()
			var pos_num = global_position + Vector3(randf_range(-0.25, 0.25), 1.8, randf_range(-0.25, 0.25))
			get_parent().add_child(n)
			n.global_position = pos_num
			if n.has_method("iniciar"):
				n.iniciar(cantidad, es_critico, false)

func morir():
	if _muerto:
		return
	_muerto = true

	if laser_apuntado != null:
		laser_apuntado.visible = false

	FortunaManager.soltar_drops(get_parent(), global_position, "arquero")

	MetaprogresoManager.procesar_baja_completa(self, jugador, "arquero", false)

	if modelo != null:
		var tw = create_tween().set_parallel(true)
		tw.tween_property(modelo, "scale", _escala_base * 1.35, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "position:y", position.y + 0.35, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.chain().tween_callback(queue_free)
	else:
		queue_free()
