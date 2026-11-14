extends Node

enum Estado { JUGANDO, GANO, PERDIO }

@export var tiempo_limite = 30.0
# false: al acabarse el tiempo se pierde. true: sobrevivir gana.
@export var gana_con_tiempo = false
# Cuántas metas hay que cumplir para ganar. 0 = no se cuentan.
@export var metas = 3
@export var espera_reinicio = 2.0

# static: es del script, no del nodo. Sobrevive a recargar la escena.
static var intentos = 1
static var mejor = 0.0

var estado = Estado.JUGANDO
var tiempo = 0.0
var hechas = 0
var reloj = 0.0
var partida_iniciada: bool = false

func _ready():
	# Always: este nodo sigue vivo aunque el juego quede en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("partida")
	tiempo = tiempo_limite
	print("intento ", intentos, " · mejor tiempo ", snappedf(mejor, 0.01))
	var boton = get_parent().get_node_or_null("BotonMovil")
	if boton != null and boton.has_signal("click_presionado"):
		boton.click_presionado.connect(_on_click_boton)

func _on_click_boton(_clicks: int):
	partida_iniciada = true

func _physics_process(delta):
	if not partida_iniciada:
		return
		
	if estado != Estado.JUGANDO:
		# Si hay pantalla de fin de partida abierta, esperar interacción del usuario
		var pantalla_fin = get_tree().get_first_node_in_group("pantalla_fin_partida")
		if pantalla_fin != null and pantalla_fin.visible:
			return
		if reloj > 0.001:
			reloj -= delta
			if reloj <= 0.001:
				reiniciar()
		return
	tiempo = maxf(tiempo - delta, 0.0)
	if tiempo <= 0.001:
		if gana_con_tiempo:
			ganar()
		else:
			perder("se acabó el tiempo")

# La llaman los objetivos del juego: no saben qué pasa después.
func avisar_meta():
	if estado != Estado.JUGANDO:
		return
	hechas += 1
	print("meta ", hechas, " de ", metas)
	if metas > 0 and hechas >= metas:
		ganar()

func ganar():
	terminar(Estado.GANO, "¡Has sobrevivido a la prueba del Coliseo!")

func perder(motivo):
	terminar(Estado.PERDIO, motivo)

# La guarda: la partida termina una sola vez.
func terminar(nuevo, motivo):
	if estado != Estado.JUGANDO:
		return
	estado = nuevo
	print("fin: ", Estado.keys()[estado], " cuadro ",
		Engine.get_physics_frames(), " (", motivo, ")")
	get_tree().paused = true
	var usado = tiempo_limite - tiempo
	if estado == Estado.GANO and (mejor == 0.0 or usado < mejor):
		mejor = usado
		
	# Desplegar pantalla analítica de fin de partida
	var pantalla_fin = get_tree().get_first_node_in_group("pantalla_fin_partida")
	if pantalla_fin == null:
		var escena_fin = load("res://pantalla_fin_partida.tscn")
		if escena_fin != null:
			pantalla_fin = escena_fin.instantiate()
			get_tree().root.add_child(pantalla_fin)
	if pantalla_fin != null and pantalla_fin.has_method("mostrar"):
		pantalla_fin.mostrar(estado == Estado.GANO, motivo)

func reiniciar():
	intentos += 1
	# Primero quitar la pausa: si no, la escena nueva nace congelada.
	get_tree().paused = false
	get_tree().reload_current_scene()
