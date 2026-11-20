extends CharacterBody3D

# Gólem Ígneo Kamikaze - Enemigo Explosivo Táctico
# Avanza rápidamente hacia el jugador. Al acercarse a menos de 2.2 m, activa su mecha durante 0.95 s y detona en un área masiva.
# Incluye física real de Knockback acumulativo (_knockback_velocity) para poder repelerlo con ondas de clic.

const AudioManager = preload("res://audio_manager.gd")
const ArenaColiseo = preload("res://arena_coliseo.gd")

@export var rapidez: float = 3.2
@export var vida_maxima: float = 16.0
@export var radio_explosion: float = 3.4
@export var dano_a_jugador: float = 38.0
@export var dano_a_enemigos: float = 55.0
@export var tiempo_mecha: float = 0.95

var vida: float = 16.0
var muerto: bool = false
var jugador: Node3D = null
var _armado: bool = false
var _detonado: bool = false
var _tiempo_restante_mecha: float = 0.95
var _reloj_efecto: float = 0.0
var _knockback_velocity: Vector3 = Vector3.ZERO

var _escala_base: Vector3 = Vector3.ONE
var _anim_ctrl: AnimadorEntidad = AnimadorEntidad.new()
var _nav_estado: Dictionary = {}

@onready var modelo: Node3D = $Modelo if has_node("Modelo") else null
@onready var nucleo_fuego: MeshInstance3D = $NucleoFuego
@onready var anillo_magma: MeshInstance3D = $AnilloMagma
@onready var luz_fuego: OmniLight3D = get_node_or_null("LuzFuego")

func _ready():
	add_to_group("enemigos")
	add_to_group("enemies")
	add_to_group("kamikazes")
	ArenaColiseo.configurar_cuerpo_terreno(self, true, true)
	vida = vida_maxima
	if modelo != null:
		_escala_base = modelo.scale
		_anim_ctrl.vincular_modelo(modelo)
	jugador = get_tree().get_first_node_in_group("jugador")

func aplicar_knockback(impulso: Vector3, _duracion_stun: float = 0.08):
	var kb = impulso
	kb.y = 0.0
	_knockback_velocity += kb
	if _knockback_velocity.length() > 18.0:
		_knockback_velocity = _knockback_velocity.normalized() * 18.0

func _physics_process(delta):
	if _detonado:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	_anim_ctrl.actualizar(delta)
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 18.0 * delta)

	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			velocity.x = _knockback_velocity.x
			velocity.z = _knockback_velocity.z
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
		velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta) + _knockback_velocity.x
		velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta) + _knockback_velocity.z
		_anim_ctrl.reproducir_bucle("telegraph", 0.12, 1.25, 1)

		_tiempo_restante_mecha -= delta

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
		if dist <= 2.2:
			_iniciar_mecha()
		else:
			var dir = ArenaColiseo.calcular_direccion_persecucion(self, pos_jugador, _nav_estado, delta)
			velocity.x = dir.x * rapidez + _knockback_velocity.x
			velocity.z = dir.z * rapidez + _knockback_velocity.z
			if dir.length_squared() > 0.01:
				basis = Basis.looking_at(dir)
			_anim_ctrl.actualizar_locomocion(Vector2(velocity.x, velocity.z).length(), true, is_on_floor(), rapidez)

	if is_on_floor():
		velocity.y = minf(velocity.y, 0.0)
	move_and_slide()

func _iniciar_mecha():
	if _armado:
		return
	_armado = true
	_tiempo_restante_mecha = tiempo_mecha
	AudioManager.play("alerta_oleada", 2.2, -3.0)

func recibir_dano(cantidad: float, fuente = "normal", es_critico: bool = false):
	if _detonado:
		return
	var fuente_str := "normal"
	if typeof(fuente) == TYPE_BOOL:
		es_critico = fuente
	else:
		fuente_str = str(fuente)
	var cantidad_final: float = cantidad * (1.0 + MetaprogresoManager.obtener_bono_bestiario("kamikaze"))
	vida -= cantidad_final
	_anim_ctrl.disparar_golpe()

	var pool = get_tree().get_first_node_in_group("damage_numbers")
	var pos_num = global_position + Vector3(randf_range(-0.2, 0.2), 1.5, randf_range(-0.2, 0.2))
	if pool != null and pool.has_method("mostrar_dano"):
		pool.mostrar_dano(pos_num, int(round(cantidad_final)), es_critico, fuente_str)
	else:
		var escena_num = load("res://damage_number_3d.tscn")
		if escena_num != null and get_parent() != null:
			var n = escena_num.instantiate()
			get_parent().add_child(n)
			n.global_position = pos_num
			n.iniciar(cantidad_final, es_critico, false)

	if vida <= 0.0:
		detonar(false)

func detonar(danar_jugador: bool = true):
	if _detonado:
		return
	_detonado = true
	muerto = true

	AudioManager.play("orbe_explosion", 0.9)

	if danar_jugador and jugador != null and is_instance_valid(jugador):
		var dist_j = global_position.distance_to(jugador.global_position)
		if dist_j <= radio_explosion:
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(dano_a_jugador)
			elif jugador.has_node("Salud"):
				jugador.get_node("Salud").recibir_golpe(int(dano_a_jugador))

	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if e != self and is_instance_valid(e) and e is Node3D:
			var dist_e = global_position.distance_to(e.global_position)
			if dist_e <= radio_explosion:
				if e.has_method("recibir_dano"):
					e.recibir_dano(dano_a_enemigos)
				var dir_empuje = (e.global_position - global_position).normalized()
				dir_empuje.y = 0.0
				if e.has_method("aplicar_knockback"):
					e.aplicar_knockback(dir_empuje * 11.0)
				elif "velocity" in e:
					e.velocity += dir_empuje * 10.0

	if not danar_jugador and is_inside_tree() and get_parent() != null:
		var drop_escena = load("res://drop_item.tscn")
		if drop_escena != null:
			var drop = drop_escena.instantiate()
			get_parent().add_child(drop)
			drop.global_position = global_position + Vector3(0, 0.4, 0)
			if drop.has_method("iniciar"):
				drop.iniciar(1, 14)

	if not danar_jugador:
		MetaprogresoManager.procesar_baja_completa(self, jugador, "kamikaze", false)
	elif jugador != null and is_instance_valid(jugador) and jugador.has_method("registrar_baja"):
		jugador.registrar_baja()

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
	if modelo != null:
		modelo.visible = false

	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(onda, "scale", Vector3.ONE * (radio_explosion * 2.0), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.22)
	if luz_fuego != null:
		tw.tween_property(luz_fuego, "light_energy", 0.0, 0.22)
	tw.chain().tween_callback(func():
		if is_instance_valid(onda):
			onda.queue_free()
		if is_instance_valid(self):
			queue_free()
	)
