extends Node

## Partida — Orquestador de Reglas de Juego y Modo Juicio Final
## Corrige la derrota o victoria prematura por tiempo: al llegar a 00:00 se activa el Juicio Final,
## manteniendo el cronómetro en alerta carmesí hasta que la Parca Roja sea abatida y el portal cruzado.

enum Estado { JUGANDO, GANO, PERDIO }

@export var tiempo_limite = 900.0
@export var gana_con_tiempo = false
@export var metas = 0
@export var espera_reinicio = 2.0

static var intentos = 1
static var mejor = 0.0

var estado = Estado.JUGANDO
var tiempo = 900.0
var tiempo_restante: float:
	get: return tiempo
var hechas = 0
var reloj = 0.0
var partida_iniciada: bool = false

var modo_juicio_final: bool = false
var parca_derrotada: bool = false
var _gracia_juicio_final: float = 45.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("partida")
	gana_con_tiempo = false
	metas = 0
	tiempo = tiempo_limite
	FortunaManager.iniciar_run()
	
	var boton = get_parent().get_node_or_null("BotonMovil")
	if boton != null and boton.has_signal("click_presionado"):
		boton.click_presionado.connect(_on_click_boton)

func _on_click_boton(_clicks: int):
	partida_iniciada = true

func _physics_process(delta: float):
	if not partida_iniciada:
		return
		
	if estado != Estado.JUGANDO:
		var pantalla_fin = get_tree().get_first_node_in_group("pantalla_fin_partida")
		if pantalla_fin != null and pantalla_fin.visible:
			return
		if reloj > 0.001:
			reloj -= delta
			if reloj <= 0.001:
				reiniciar()
		return
		
	if not modo_juicio_final:
		tiempo = maxf(tiempo - delta, 0.0)
		if tiempo <= 0.001:
			_activar_modo_juicio_final()
	else:
		_procesar_modo_juicio_final(delta)

func _activar_modo_juicio_final():
	modo_juicio_final = true
	tiempo = 0.0
	
	var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
	var pj = get_tree().get_first_node_in_group("player")
	if pj == null:
		pj = get_tree().get_first_node_in_group("jugador")
	if pool_dano != null and pj != null:
		pool_dano.mostrar_texto(pj.global_position + Vector3(0, 2.5, 0), "💀 ¡JUICIO FINAL! ¡Derrota a la Parca Roja!", Color(1.0, 0.15, 0.15), 1.5)

func _procesar_modo_juicio_final(delta: float):
	if parca_derrotada:
		var portal = get_tree().get_first_node_in_group("portal_ascension")
		if portal != null and portal.has_method("desbloquear_portal"):
			portal.desbloquear_portal()
		return
		
	var jefes = get_tree().get_nodes_in_group("jefes")
	if jefes.is_empty():
		jefes = get_tree().get_nodes_in_group("bosses")
	if jefes.is_empty():
		_gracia_juicio_final -= delta
		if _gracia_juicio_final <= 0.0:
			var portal = get_tree().get_first_node_in_group("portal_ascension")
			if portal != null and portal.has_method("desbloquear_portal"):
				portal.desbloquear_portal()

func notificar_parca_derrotada():
	parca_derrotada = true
	var portal = get_tree().get_first_node_in_group("portal_ascension")
	if portal != null and portal.has_method("desbloquear_portal"):
		portal.desbloquear_portal()

func avisar_meta():
	if estado != Estado.JUGANDO:
		return
	hechas += 1
	if metas > 0 and hechas >= metas:
		ganar()

func ganar():
	terminar(Estado.GANO, "¡Has trascendido la prueba del Coliseo y derrotado a la Oscuridad!")

func perder(motivo: String):
	terminar(Estado.PERDIO, motivo)

func terminar(nuevo: Estado, motivo: String):
	if estado != Estado.JUGANDO:
		return
	estado = nuevo
	get_tree().paused = true
	var usado = tiempo_limite - tiempo
	if estado == Estado.GANO and (mejor == 0.0 or usado < mejor):
		mejor = usado
		
	var pantalla_fin = get_tree().get_first_node_in_group("pantalla_fin_partida")
	if pantalla_fin == null:
		var escena_fin = load("res://pantalla_fin_partida.tscn")
		if escena_fin != null:
			pantalla_fin = escena_fin.instantiate()
			get_parent().add_child(pantalla_fin)
	if pantalla_fin != null and pantalla_fin.has_method("mostrar"):
		pantalla_fin.mostrar(estado == Estado.GANO, motivo)

func reiniciar():
	intentos += 1
	get_tree().paused = false
	get_tree().reload_current_scene()
