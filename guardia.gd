extends CharacterBody3D

enum Estado { PATRULLAR, ESPERAR, PERSEGUIR, ATACAR, BUSCAR }

@export var rapidez = 2.2
@export var espera = 1.0
@export var rango_vision = 18.0
@export var rango_ataque = 1.25
@export var rango_perder = 24.0
@export var tiempo_busqueda = 3.0
@export var ruta: Array[Vector3] = [Vector3.ZERO, Vector3(0, 0, -6)]

@export var vida_maxima: float = 24.0
@export var dano_ataque: float = 7.0
@export var cadencia_ataque: float = 1.1

var estado = Estado.PATRULLAR
var puntos: Array[Vector3] = []
var indice = 0
var reloj = 0.0
var jugador = null
var ultimo_visto = Vector3.ZERO
var busca = 0.0
var vida: float = 24.0
var _reloj_ataque: float = 0.0
var _escala_base: Vector3 = Vector3.ONE
var _muerto: bool = false
var _anim_ctrl: AnimadorEntidad = AnimadorEntidad.new()

var knockback_vel: Vector3 = Vector3.ZERO
var resistencia_knockback: float = 0.35
var _stun_timer: float = 0.0
var marca_conductiva_timer: float = 0.0

@onready var anim = $Modelo/AnimationPlayer if has_node("Modelo/AnimationPlayer") else null
@onready var vision = $Vision if has_node("Vision") else null

func _ready():
	add_to_group("enemies")
	add_to_group("enemigos")
	vida = vida_maxima
	if has_node("Modelo"):
		_escala_base = $Modelo.scale
		_anim_ctrl.vincular_modelo($Modelo)
	jugador = get_tree().get_first_node_in_group("player")
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
	for d in ruta:
		puntos.append(global_position + d)

func aplicar_knockback(impulso: Vector3, duracion_stun: float = 0.08) -> void:
	var factor: float = clampf(1.0 - resistencia_knockback, 0.1, 1.0)
	knockback_vel += Vector3(impulso.x, 0.0, impulso.z) * factor
	if knockback_vel.length() > 25.0:
		knockback_vel = knockback_vel.normalized() * 25.0
	_stun_timer = maxf(_stun_timer, duracion_stun * factor)

func aplicar_marca_conductiva(duracion: float = 2.5) -> void:
	marca_conductiva_timer = maxf(marca_conductiva_timer, duracion)

func _physics_process(delta):
	if _muerto:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	reloj = maxf(reloj - delta, 0.0)
	busca = maxf(busca - delta, 0.0)
	_reloj_ataque = maxf(_reloj_ataque - delta, 0.0)
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

	var d = distancia_a(jugador.global_position)
	var ve = lo_ve()
	if ve:
		ultimo_visto = jugador.global_position

	var nuevo = decidir(d, ve)
	if nuevo != estado:
		estado = nuevo

	match estado:
		Estado.PATRULLAR:
			patrullar()
		Estado.ESPERAR:
			frenar()
		Estado.PERSEGUIR:
			ir_a(jugador.global_position)
		Estado.ATACAR:
			frenar()
			if _stun_timer > 0.0:
				_anim_ctrl.reproducir_bucle("stunned", 0.10, 1.0, 1)
			elif _reloj_ataque <= 0.001 and d <= rango_ataque + 0.3:
				_reloj_ataque = cadencia_ataque
				_anim_ctrl.reproducir_accion("attack-melee-right", 2, 0.08, 1.0)
				if jugador != null:
					if jugador.has_method("recibir_dano"):
						jugador.recibir_dano(dano_ataque)
					elif jugador.has_node("Salud"):
						jugador.get_node("Salud").recibir_golpe(int(dano_ataque))
		Estado.BUSCAR:
			if distancia_a(ultimo_visto) > 0.1:
				ir_a(ultimo_visto)
			else:
				frenar()

	velocity.x += knockback_vel.x
	velocity.z += knockback_vel.z
	move_and_slide()

func decidir(d, ve):
	var alerta = estado == Estado.PERSEGUIR or estado == Estado.ATACAR
	var limite = rango_perder if alerta else rango_vision

	if ve and d <= rango_ataque:
		return Estado.ATACAR
	if ve and d <= limite:
		return Estado.PERSEGUIR
	if alerta:
		busca = tiempo_busqueda
		return Estado.BUSCAR
	if busca > 0.001:
		return Estado.BUSCAR
	if reloj > 0.001:
		return Estado.ESPERAR
	return Estado.PATRULLAR

func lo_ve():
	if vision == null or jugador == null:
		return true
	var pecho = jugador.global_position + Vector3(0, 0.9, 0)
	vision.target_position = vision.to_local(pecho)
	vision.force_raycast_update()
	if vision.is_colliding():
		return vision.get_collider() == jugador
	return true

func patrullar():
	if puntos.size() == 0:
		frenar()
		return
	var destino = puntos[indice]
	if distancia_a(destino) < 0.1:
		indice = (indice + 1) % puntos.size()
		reloj = espera
		frenar()
		return
	ir_a(destino)

func ir_a(destino):
	var hacia = destino - global_position
	hacia.y = 0.0
	var dir = hacia.normalized()
	var mult_stun = 0.15 if _stun_timer > 0.0 else 1.0
	velocity.x = dir.x * rapidez * mult_stun
	velocity.z = dir.z * rapidez * mult_stun
	if dir.length_squared() > 0.01:
		basis = Basis.looking_at(dir)
	if _stun_timer > 0.0:
		_anim_ctrl.reproducir_bucle("stunned", 0.10, 1.0, 1)
	else:
		_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), false, is_on_floor(), rapidez)

func frenar():
	velocity.x = 0.0
	velocity.z = 0.0
	if _stun_timer > 0.0:
		_anim_ctrl.reproducir_bucle("stunned", 0.10, 1.0, 1)
	elif estado != Estado.ATACAR or not _anim_ctrl.esta_bloqueado():
		_anim_ctrl.actualizar_locomocion(0.0, false, is_on_floor(), rapidez)

func distancia_a(p):
	var o = global_position
	return Vector2(p.x - o.x, p.z - o.z).length()

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false):
	if _muerto:
		return
	if typeof(fuente) == TYPE_BOOL:
		es_critico = fuente
		fuente = "normal"

	var cantidad_final: float = cantidad
	if marca_conductiva_timer > 0.0:
		cantidad_final *= 1.25

	vida -= cantidad_final
	_anim_ctrl.disparar_golpe()
	
	if has_node("Modelo"):
		var tw = create_tween()
		tw.tween_property($Modelo, "scale", _escala_base * 1.15, 0.05)
		tw.tween_property($Modelo, "scale", _escala_base, 0.08)

	_notificar_dano(cantidad_final, es_critico, str(fuente))

	if vida <= 0:
		morir()

func _notificar_dano(cantidad: float, es_critico: bool, fuente: String):
	var dmg_pool = get_tree().get_first_node_in_group("damage_numbers")
	if dmg_pool != null and dmg_pool.has_method("mostrar_dano"):
		dmg_pool.mostrar_dano(global_position + Vector3(0, 1.8, 0), int(round(cantidad)), es_critico, fuente)
	else:
		var escena = load("res://damage_number_3d.tscn")
		if escena != null and is_inside_tree() and get_parent() != null:
			var num = escena.instantiate()
			var pos_num = global_position + Vector3(randf_range(-0.25, 0.25), 1.8, randf_range(-0.25, 0.25))
			get_parent().add_child(num)
			num.global_position = pos_num
			if num.has_method("iniciar"):
				num.iniciar(cantidad, es_critico, false)

func morir():
	if _muerto:
		return
	_muerto = true

	FortunaManager.soltar_drops(get_parent(), global_position, "guardia")
	if jugador != null and is_instance_valid(jugador) and jugador.has_method("registrar_baja"):
		jugador.registrar_baja()

	if has_node("Modelo"):
		var tw = create_tween().set_parallel(true)
		tw.tween_property($Modelo, "scale", _escala_base * 1.3, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "position:y", position.y + 0.35, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.chain().tween_callback(queue_free)
	else:
		queue_free()
