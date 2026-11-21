extends CharacterBody3D

const ArenaColiseo = preload("res://arena_coliseo.gd")
const VfxCombate = preload("res://vfx_combate.gd")

@export var rapidez: float = 1.5
@export var vida_maxima: float = 220.0
@export var dano_ataque: float = 36.0
@export var cadencia_ataque: float = 1.8
@export var rango_ataque: float = 1.8

var vida: float = 220.0
var jugador: Node3D = null
var _reloj_ataque: float = 0.0
var _escala_base: Vector3 = Vector3.ONE
var _muerto: bool = false
var _anim_ctrl: AnimadorEntidad = AnimadorEntidad.new()

var tiene_escudo_runico: bool = true
var _reloj_escudo_roto: float = 0.0

var knockback_vel: Vector3 = Vector3.ZERO
var resistencia_knockback: float = 0.60
var _stun_timer: float = 0.0
var marca_conductiva_timer: float = 0.0
var _nav_estado: Dictionary = {}

@onready var anim = $Modelo/AnimationPlayer if has_node("Modelo/AnimationPlayer") else null
@onready var modelo = $Modelo if has_node("Modelo") else null

func _ready():
	add_to_group("enemies")
	add_to_group("enemigos")
	ArenaColiseo.configurar_cuerpo_terreno(self, false, true)
	vida = vida_maxima
	if modelo != null:
		_escala_base = modelo.scale
		_anim_ctrl.vincular_modelo(modelo)
	jugador = get_tree().get_first_node_in_group("player")
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")

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

	_reloj_ataque = maxf(_reloj_ataque - delta, 0.0)
	_stun_timer = maxf(_stun_timer - delta, 0.0)
	marca_conductiva_timer = maxf(marca_conductiva_timer - delta, 0.0)
	_anim_ctrl.actualizar(delta)
	knockback_vel = knockback_vel.move_toward(Vector3.ZERO, 28.0 * delta)

	if _reloj_escudo_roto > 0.0:
		_reloj_escudo_roto -= delta

	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("player")
		if jugador == null:
			jugador = get_tree().get_first_node_in_group("jugador")
		velocity.x = knockback_vel.x
		velocity.z = knockback_vel.z
		move_and_slide()
		return

	var d = distancia_a(jugador.global_position)
	var diff_y = absf(jugador.global_position.y - global_position.y)
	if d <= rango_ataque and diff_y <= 0.45:
		frenar()
		if _stun_timer > 0.0:
			_anim_ctrl.reproducir_bucle("stunned", 0.10, 1.0, 1)
		elif _reloj_ataque <= 0.001:
			_reloj_ataque = cadencia_ataque
			_anim_ctrl.reproducir_accion("attack-melee-right", 2, 0.08, 0.9)
			_golpe_contundente()
	else:
		ir_a(jugador.global_position, delta)

	velocity.x += knockback_vel.x
	velocity.z += knockback_vel.z
	if is_on_floor():
		velocity.y = minf(velocity.y, 0.0)
	move_and_slide()

func ir_a(destino: Vector3, delta: float = 0.016):
	var dir = ArenaColiseo.calcular_direccion_persecucion(self, destino, _nav_estado, delta)
	if dir.length_squared() > 0.0025:
		var mult_colapso = 1.0
		var b_movil = get_tree().get_first_node_in_group("boton_movil")
		if b_movil != null and "en_colapso" in b_movil and b_movil.en_colapso:
			mult_colapso = 1.30
		var mult_stun = 0.15 if _stun_timer > 0.0 else 1.0
		velocity.x = dir.x * rapidez * mult_colapso * mult_stun
		velocity.z = dir.z * rapidez * mult_colapso * mult_stun
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
	elif not _anim_ctrl.esta_bloqueado():
		_anim_ctrl.actualizar_locomocion(0.0, false, is_on_floor(), rapidez)

func distancia_a(p: Vector3) -> float:
	var o = global_position
	return Vector2(p.x - o.x, p.z - o.z).length()

func _golpe_contundente():
	VfxCombate.spawn_explosion_nova(get_parent(), global_position + Vector3(0, 0.4, 0), rango_ataque * 1.15, Color(1.0, 0.36, 0.10), Color(1.0, 0.90, 0.55), 0.28, true, true)
	if jugador != null and is_instance_valid(jugador):
		if jugador.has_method("recibir_dano"):
			jugador.recibir_dano(dano_ataque)
		elif jugador.has_node("Salud"):
			jugador.get_node("Salud").recibir_golpe(int(dano_ataque))

func desactivar_escudo_runico(duracion: float = 7.0):
	_reloj_escudo_roto = duracion
	_spawn_damage_number(0, true, "¡ESCUDO ROTO! ⚡")

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false):
	if _muerto:
		return
	if typeof(fuente) == TYPE_BOOL:
		es_critico = fuente
		fuente = "normal"

	if tiene_escudo_runico and _reloj_escudo_roto <= 0.0:
		cantidad *= 0.20
		_spawn_damage_number(0, false, "🛡️ ESCUDO RÚNICO")

	var cantidad_final: float = cantidad * (1.0 + MetaprogresoManager.obtener_bono_bestiario("bruto"))
	if marca_conductiva_timer > 0.0:
		cantidad_final *= 1.25

	vida -= cantidad_final
	_anim_ctrl.disparar_golpe()
	
	if modelo != null:
		var tw = create_tween()
		tw.tween_property(modelo, "scale", _escala_base * 1.1, 0.05)
		tw.tween_property(modelo, "scale", _escala_base, 0.08)

	_notificar_dano(cantidad_final, es_critico, str(fuente))

	if vida <= 0.0:
		morir()

func _notificar_dano(cantidad: float, es_critico: bool, fuente: String):
	var dmg_pool = get_tree().get_first_node_in_group("damage_numbers")
	if dmg_pool != null and dmg_pool.has_method("mostrar_dano"):
		dmg_pool.mostrar_dano(global_position + Vector3(0, 2.8, 0), int(round(cantidad)), es_critico, fuente)
	else:
		_spawn_damage_number(cantidad, es_critico)

func _spawn_damage_number(cantidad: float, es_critico: bool, texto_custom: String = ""):
	var escena = load("res://damage_number_3d.tscn")
	if escena != null and is_inside_tree() and get_parent() != null:
		var num = escena.instantiate()
		var pos_num = global_position + Vector3(randf_range(-0.3, 0.3), 2.8, randf_range(-0.3, 0.3))
		get_parent().add_child(num)
		num.global_position = pos_num
		if num.has_method("iniciar"):
			num.iniciar(cantidad, es_critico, false, texto_custom)

func morir():
	if _muerto:
		return
	_muerto = true

	FortunaManager.soltar_drops(get_parent(), global_position, "bruto")
	MetaprogresoManager.procesar_baja_completa(self, jugador, "bruto", false)

	if modelo != null:
		var tw = create_tween().set_parallel(true)
		tw.tween_property(modelo, "scale", _escala_base * 1.25, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "position:y", position.y + 0.45, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.chain().tween_callback(queue_free)
	else:
		queue_free()
