extends CharacterBody3D
class_name EnemigoBase

# EnemigoBase - Clase base modular para enemigos en Clicklike 3D
# Gestiona física real de retroceso (knockback), aturdimiento, marcas conductivas,
# IA base para subclases interactivas con el cursor, shudder visual al recibir daño y pop de muerte.

const AudioManager = preload("res://audio_manager.gd")

@export var rapidez: float = 2.85
@export var vida_maxima: float = 14.0
@export var dano_ataque: float = 4.5
@export var cadencia_ataque: float = 1.0
@export var rango_ataque: float = 1.1

var dano_contacto: float = 6.0
var xp_otorgada: int = 10
var oro_otorgado: int = 5

var vida: float = 14.0
var jugador: Node3D = null
var _reloj_ataque: float = 0.0
var _escala_base: Vector3 = Vector3.ONE
var _muerto: bool = false
var muerto: bool:
	get: return _muerto
	set(v): _muerto = v

var knockback_vel: Vector3 = Vector3.ZERO
var resistencia_knockback: float = 0.0
var _stun_timer: float = 0.0
var marca_conductiva_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("enemigos")
	vida = vida_maxima
	_escala_base = scale
	jugador = get_tree().get_first_node_in_group("player")
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")

func _physics_process(delta: float) -> void:
	if _muerto:
		return
	var vel_ia: Vector3 = _calcular_velocidad_ia(delta)
	procesar_fisica_base(delta, vel_ia)

	if dano_contacto > 0.0 and jugador != null and is_instance_valid(jugador):
		_reloj_ataque = maxf(_reloj_ataque - delta, 0.0)
		if _reloj_ataque <= 0.0 and global_position.distance_to(jugador.global_position) <= maxf(rango_ataque, 1.35):
			_reloj_ataque = cadencia_ataque
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(dano_contacto)

func _calcular_velocidad_ia(_delta: float) -> Vector3:
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			return Vector3.ZERO
	var dif: Vector3 = jugador.global_position - global_position
	dif.y = 0.0
	if dif.length_squared() > 0.01:
		var dir_norm = dif.normalized()
		look_at(global_position + dir_norm, Vector3.UP)
		return dir_norm * rapidez
	return Vector3.ZERO

func aplicar_knockback(impulso: Vector3, duracion_stun: float = 0.08) -> void:
	var factor: float = clampf(1.0 - resistencia_knockback, 0.1, 1.0)
	knockback_vel += Vector3(impulso.x, 0.0, impulso.z) * factor
	if knockback_vel.length() > 25.0:
		knockback_vel = knockback_vel.normalized() * 25.0
	_stun_timer = maxf(_stun_timer, duracion_stun * factor)

func aplicar_marca_conductiva(duracion: float = 2.5) -> void:
	marca_conductiva_timer = maxf(marca_conductiva_timer, duracion)

func procesar_fisica_base(delta: float, vel_deseada: Vector3 = Vector3.ZERO) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	_stun_timer = maxf(_stun_timer - delta, 0.0)
	marca_conductiva_timer = maxf(marca_conductiva_timer - delta, 0.0)
	knockback_vel = knockback_vel.move_toward(Vector3.ZERO, 28.0 * delta)

	var mov: Vector3 = vel_deseada
	if _stun_timer > 0.0:
		mov *= 0.15

	velocity.x = mov.x + knockback_vel.x
	velocity.z = mov.z + knockback_vel.z
	move_and_slide()

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false) -> void:
	if _muerto:
		return
	if typeof(fuente) == TYPE_BOOL:
		es_critico = fuente
		fuente = "normal"

	var cantidad_final: float = cantidad
	if marca_conductiva_timer > 0.0:
		cantidad_final *= 1.25

	vida -= cantidad_final

	var tw = create_tween()
	tw.tween_property(self, "scale", _escala_base * 1.15, 0.05)
	tw.tween_property(self, "scale", _escala_base, 0.08)

	_notificar_dano(cantidad_final, es_critico, str(fuente))

	if vida <= 0.0:
		morir()

func _notificar_dano(cantidad: float, es_critico: bool, fuente: String) -> void:
	var dmg_pool = get_tree().get_first_node_in_group("damage_numbers")
	if dmg_pool != null and dmg_pool.has_method("mostrar_dano"):
		dmg_pool.mostrar_dano(global_position + Vector3(0, 1.4, 0), int(round(cantidad)), es_critico, fuente)
	else:
		var escena = load("res://damage_number_3d.tscn")
		if escena != null and is_inside_tree() and get_parent() != null:
			var num = escena.instantiate()
			var pos_num = global_position + Vector3(randf_range(-0.2, 0.2), 1.4, randf_range(-0.2, 0.2))
			get_parent().add_child(num)
			num.global_position = pos_num
			if num.has_method("iniciar"):
				num.iniciar(cantidad, es_critico, false)

func morir() -> void:
	if _muerto:
		return
	_muerto = true

	set_physics_process(false)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", _escala_base * 1.35, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", position.y + 0.4, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	FortunaManager.soltar_drops(get_parent(), global_position, "espectro")
	if jugador != null and is_instance_valid(jugador):
		if xp_otorgada > 10 and jugador.has_method("ganar_xp"):
			jugador.ganar_xp(xp_otorgada - 10)
		if oro_otorgado > 5 and jugador.has_method("recoger_drop"):
			jugador.recoger_drop(0, oro_otorgado - 5)
		if jugador.has_method("registrar_baja"):
			jugador.registrar_baja()

	tw.chain().tween_callback(queue_free)
