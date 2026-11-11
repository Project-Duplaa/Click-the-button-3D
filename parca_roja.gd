extends CharacterBody3D

# La Parca Roja - Jefe Final Colosal de Clicklike 3D
# Desarrollado por: Juan Camilo Angulo Camelo
# 5000 HP, velocidad implacable superior al héroe, guadaña de sombra y marcas rojas telegrafiadas en el suelo.

signal parca_derrotada

const AudioManager = preload("res://audio_manager.gd")

@export var rapidez: float = 5.6
@export var vida_maxima: float = 5000.0
@export var dano_guadana: float = 55.0
@export var radio_golpe: float = 4.2
@export var tiempo_telegraph: float = 0.85

var vida: float = 5000.0
var jugador: Node3D = null
var hud: Node = null

var _reloj_ataque: float = 0.0
var _esta_telegrafando: bool = false
var _en_enrage: bool = false

@onready var telegraph_marca: MeshInstance3D = $TelegraphMarca
@onready var luz_roja: OmniLight3D = $LuzParca
@onready var aura_roja: MeshInstance3D = $AuraParca

func _ready():
	add_to_group("enemigos")
	add_to_group("jefes")
	vida = vida_maxima
	jugador = get_tree().get_first_node_in_group("jugador")
	hud = get_tree().get_first_node_in_group("hud")
	if hud == null:
		hud = get_parent().get_node_or_null("ClickHUD")
		
	if telegraph_marca != null:
		telegraph_marca.visible = false
		
	# Invocación dramática
	print("=====================================================")
	print("¡LA PARCA ROJA HA DESCENDIDO AL COLISEO! (5000 HP)")
	print("=====================================================")
	AudioManager.play("jefe_alerta", 0.65, 3.0)
	
	if hud != null and hud.has_method("mostrar_barra_jefe"):
		hud.mostrar_barra_jefe("💀 LA PARCA ROJA - SEÑOR DE LAS SOMBRAS", vida_maxima, vida)

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# Efecto de ondulación del aura sombría
	if aura_roja != null:
		aura_roja.rotate_y(delta * 2.5)
		
	if _esta_telegrafando:
		velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
		move_and_slide()
		return
		
	_reloj_ataque = maxf(_reloj_ataque - delta, 0.0)
	
	if is_instance_valid(jugador) and jugador is Node3D:
		var dir = (jugador.global_position - global_position)
		dir.y = 0.0
		var dist = dir.length()
		
		if dist > 0.1:
			look_at(global_position + dir.normalized(), Vector3.UP)
			
		# Enrage por debajo del 30% de vida
		var vel_actual = rapidez * (1.18 if _en_enrage else 1.0)
		
		if dist <= radio_golpe and _reloj_ataque <= 0.001:
			_iniciar_corte_guadana()
		else:
			var dir_mov = dir.normalized()
			velocity.x = dir_mov.x * vel_actual
			velocity.z = dir_mov.z * vel_actual
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		
	move_and_slide()

func _iniciar_corte_guadana():
	_esta_telegrafando = true
	
	# Desplegar la marca roja de advertencia en el suelo (R3: Mitigación de frustración)
	if telegraph_marca != null:
		telegraph_marca.visible = true
		telegraph_marca.scale = Vector3(0.1, 1.0, 0.1)
		var tw = create_tween()
		tw.tween_property(telegraph_marca, "scale", Vector3(1.0, 1.0, 1.0), tiempo_telegraph).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	get_tree().create_timer(tiempo_telegraph).timeout.connect(_ejecutar_corte_guadana)

func _ejecutar_corte_guadana():
	if telegraph_marca != null:
		telegraph_marca.visible = false
	_esta_telegrafando = false
	_reloj_ataque = 1.15
	
	AudioManager.play("danio_jugador", 0.65, 2.0)
	
	if is_instance_valid(jugador) and jugador is Node3D:
		var dist = global_position.distance_to(jugador.global_position)
		if dist <= radio_golpe + 1.0:
			if jugador.has_method("recibir_dano"):
				jugador.recibir_dano(dano_guadana)
			elif jugador.has_node("Salud"):
				jugador.get_node("Salud").recibir_golpe(int(dano_guadana))

func recibir_dano(cantidad: float, es_critico: bool = false):
	vida = maxf(vida - cantidad, 0.0)
	
	if not _en_enrage and vida <= (vida_maxima * 0.3):
		_en_enrage = true
		print("¡LA PARCA ROJA ENTRA EN FRENESÍ (ENRAGE)!")
		if luz_roja != null:
			luz_roja.light_energy = 5.0
			
	# Feedback de daño numérico
	var escena_num = load("res://damage_number_3d.tscn")
	if escena_num != null:
		var n = escena_num.instantiate()
		var pos_num = global_position + Vector3(randf_range(-0.5, 0.5), 3.2, randf_range(-0.5, 0.5))
		get_parent().add_child(n)
		n.global_position = pos_num
		n.iniciar(cantidad, es_critico, false)
		
	if hud != null and hud.has_method("actualizar_barra_jefe"):
		hud.actualizar_barra_jefe(vida)
		
	if vida <= 0.0:
		morir()

func morir():
	print("*****************************************************")
	print("¡LA PARCA ROJA HA SIDO ANIQUILADA! ¡VICTORIA ABSOLUTA!")
	print("*****************************************************")
	
	if hud != null and hud.has_method("ocultar_barra_jefe"):
		hud.ocultar_barra_jefe()
		
	AudioManager.play("victoria", 1.0, 4.0)
	
	var pj = get_tree().get_first_node_in_group("jugador")
	if pj != null and pj.has_method("registrar_baja"):
		pj.registrar_baja()
		
	emit_signal("parca_derrotada")
	
	# Declarar victoria definitiva en la partida
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null and partida.has_method("ganar"):
		partida.ganar()
		
	queue_free()
