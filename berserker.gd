extends CharacterBody3D

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

var tiene_escudo_runico: bool = true
var _reloj_escudo_roto: float = 0.0

var _reloj_cooldown_carga: float = 2.0
var _reloj_estado: float = 0.0
var _dir_carga: Vector3 = Vector3.FORWARD
var _escala_base: Vector3 = Vector3.ONE
var _muerto: bool = false
var _anim_ctrl: AnimadorEntidad = AnimadorEntidad.new()

var knockback_vel: Vector3 = Vector3.ZERO
var resistencia_knockback: float = 0.35
var _stun_timer: float = 0.0
var marca_conductiva_timer: float = 0.0

@onready var modelo: Node3D = $Modelo if has_node("Modelo") else null
@onready var anim = $Modelo/AnimationPlayer if has_node("Modelo/AnimationPlayer") else null
@onready var luz_furia: OmniLight3D = $LuzFuria if has_node("LuzFuria") else null
@onready var linea_carga: MeshInstance3D = $LineaCarga if has_node("LineaCarga") else null

func _ready():
	add_to_group("enemies")
	add_to_group("enemigos")
	add_to_group("berserkers")
	vida = vida_maxima
	if modelo != null:
		_escala_base = modelo.scale
		_anim_ctrl.vincular_modelo(modelo)
	jugador = get_tree().get_first_node_in_group("player")
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
	if linea_carga != null:
		linea_carga.visible = false
	if luz_furia != null:
		luz_furia.light_energy = 0.5

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

	if _reloj_escudo_roto > 0.0:
		_reloj_escudo_roto -= delta

	_reloj_cooldown_carga = maxf(_reloj_cooldown_carga - delta, 0.0)
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
	var mult_stun = 0.15 if _stun_timer > 0.0 else 1.0

	match estado:
		Estado.PERSEGUIR:
			if dist <= 8.5 and _reloj_cooldown_carga <= 0.001 and _stun_timer <= 0.0:
				_iniciar_preparacion_carga(dif.normalized())
			else:
				var dir = dif.normalized()
				velocity.x = dir.x * rapidez_caminar * mult_stun
				velocity.z = dir.z * rapidez_caminar * mult_stun
				if dif.length_squared() > 0.01:
					basis = Basis.looking_at(dir)
				if _stun_timer > 0.0:
					_anim_ctrl.reproducir_bucle("stunned", 0.10, 1.0, 1)
				else:
					_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), false, is_on_floor(), rapidez_caminar)
					
		Estado.PREPARAR_CARGA:
			velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
			_anim_ctrl.reproducir_bucle("telegraph", 0.12, 1.0, 1)
				
			_reloj_estado -= delta
			if _reloj_estado <= 0.0:
				_ejecutar_carga()
				
		Estado.CARGAR:
			velocity.x = _dir_carga.x * rapidez_carga
			velocity.z = _dir_carga.z * rapidez_carga
			_anim_ctrl.reproducir_bucle("sprint", 0.08, 1.4, 1)
				
			_reloj_estado -= delta
			if dist <= 1.4:
				_impactar_jugador_en_carga()
				
			if _reloj_estado <= 0.0:
				_finalizar_carga_aturdido()
				
		Estado.ATURDIDO:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			_anim_ctrl.reproducir_bucle("stunned", 0.12, 1.0, 1)

			_reloj_estado -= delta
			if _reloj_estado <= 0.0:
				estado = Estado.PERSEGUIR
				_reloj_cooldown_carga = cadencia_carga

	velocity.x += knockback_vel.x
	velocity.z += knockback_vel.z
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
	_anim_ctrl.reproducir_accion("attack-melee-right", 2, 0.06, 1.15)
	if jugador != null and is_instance_valid(jugador):
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

func desactivar_escudo_runico(duracion: float = 7.0):
	_reloj_escudo_roto = duracion
	var escena_num = load("res://damage_number_3d.tscn")
	if escena_num != null and is_inside_tree() and get_parent() != null:
		var n = escena_num.instantiate()
		var pos_num = global_position + Vector3(0, 2.4, 0)
		get_parent().add_child(n)
		n.global_position = pos_num
		if n.has_method("iniciar"):
			n.iniciar(0, true, false, "¡ESCUDO ROTO! ⚡")

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false):
	if _muerto:
		return
	if typeof(fuente) == TYPE_BOOL:
		es_critico = fuente
		fuente = "normal"

	if tiene_escudo_runico and _reloj_escudo_roto <= 0.0:
		cantidad *= 0.40
		var escena_esc = load("res://damage_number_3d.tscn")
		if escena_esc != null and is_inside_tree() and get_parent() != null:
			var n = escena_esc.instantiate()
			var pos_num = global_position + Vector3(0, 2.4, 0)
			get_parent().add_child(n)
			n.global_position = pos_num
			if n.has_method("iniciar"):
				n.iniciar(0, false, false, "🛡️ ESCUDO RÚNICO")

	var cantidad_final: float = cantidad
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
		dmg_pool.mostrar_dano(global_position + Vector3(0, 2.2, 0), int(round(cantidad)), es_critico, fuente)
	else:
		var escena_num = load("res://damage_number_3d.tscn")
		if escena_num != null and is_inside_tree() and get_parent() != null:
			var n = escena_num.instantiate()
			var pos_num = global_position + Vector3(randf_range(-0.3, 0.3), 2.2, randf_range(-0.3, 0.3))
			get_parent().add_child(n)
			n.global_position = pos_num
			if n.has_method("iniciar"):
				n.iniciar(cantidad, es_critico, false)

func morir():
	if _muerto:
		return
	_muerto = true

	if linea_carga != null:
		linea_carga.visible = false

	FortunaManager.soltar_drops(get_parent(), global_position, "berserker")

	if jugador != null and is_instance_valid(jugador) and jugador.has_method("registrar_baja"):
		jugador.registrar_baja()

	if modelo != null:
		var tw = create_tween().set_parallel(true)
		tw.tween_property(modelo, "scale", _escala_base * 1.35, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "position:y", position.y + 0.35, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.chain().tween_callback(queue_free)
	else:
		queue_free()
