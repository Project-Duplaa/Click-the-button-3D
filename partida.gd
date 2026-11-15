extends Node

## Partida — Orquestador de Reglas de Juego, Juicio Final y Modo Abismo Infinito
## 1. Conteo de tiempo y modo Juicio Final al agotar los 15 minutos (900s).
## 2. Modo Abismo Infinito: tiempo límite ilimitado (999999s), multiplicador x4 de Oro/Clics,
##    y asegura cómputo de victoria roguelike permanente aunque el héroe caiga en el abismo.
## 3. Inicialización autónoma de FavorEmperadorManager y EventosColiseoManager.

enum Estado { JUGANDO, GANO, PERDIO }

signal abismo_activado()

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

# Modo Abismo Infinito
var modo_abismo: bool = false
var nivel_abismo: int = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("partida")
	gana_con_tiempo = false
	metas = 0
	tiempo = tiempo_limite
	FortunaManager.iniciar_run()

	call_deferred("_asegurar_managers_coliseo")

	var boton = get_parent().get_node_or_null("BotonMovil")
	if boton != null and boton.has_signal("click_presionado"):
		boton.click_presionado.connect(_on_click_boton)

func _asegurar_managers_coliseo() -> void:
	if not is_inside_tree():
		return
	var arena = get_parent()
	if arena == null:
		return

	if get_tree().get_first_node_in_group("favor_emperador_manager") == null:
		var fav_script = load("res://favor_emperador_manager.gd")
		if fav_script != null:
			var fav_mgr = Node.new()
			fav_mgr.name = "FavorEmperadorManager"
			fav_mgr.set_script(fav_script)
			arena.add_child(fav_mgr)

	if get_tree().get_first_node_in_group("eventos_coliseo_manager") == null:
		var evt_script = load("res://eventos_coliseo_manager.gd")
		if evt_script != null:
			var evt_mgr = Node.new()
			evt_mgr.name = "EventosColiseoManager"
			evt_mgr.set_script(evt_script)
			arena.add_child(evt_mgr)

func _on_click_boton(_clicks: int):
	partida_iniciada = true

func activar_modo_abismo() -> void:
	if modo_abismo:
		return
	modo_abismo = true
	tiempo_limite = 999999.0
	tiempo = 999999.0
	gana_con_tiempo = false

	emit_signal("abismo_activado")

	var spawner = get_tree().get_first_node_in_group("oleadas_spawner")
	if spawner != null and spawner.has_method("activar_modo_abismo"):
		spawner.activar_modo_abismo()

	var pj = get_tree().get_first_node_in_group("jugador")
	if pj == null:
		pj = get_tree().get_first_node_in_group("player")
	if pj != null and is_instance_valid(pj):
		if "multiplicador_fiebre_actual" in pj:
			pj.multiplicador_fiebre_actual = maxi(pj.multiplicador_fiebre_actual, 4)
		if pj.has_method("activar_multiplicador_abismo"):
			pj.activar_multiplicador_abismo(4.0)

	# Asegurar conteo de victoria para Metaprogreso incluso si cae después en Abismo
	MetaprogresoManager.asegurar_inicializado()
	MetaprogresoManager.victorias += 1
	MetaprogresoManager.guardar()

	AudioManager.play("legendario", 1.25)
	var pool = get_tree().get_first_node_in_group("damage_numbers")
	if pool != null and pj != null:
		pool.mostrar_texto(pj.global_position + Vector3(0, 3.2, 0), "🔥 ¡MODO ABISMO INFINITO ACTIVADO! (x4 Recompensas) 🔥", Color(1.0, 0.25, 0.2), 1.8)

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

	if not modo_juicio_final and not modo_abismo:
		tiempo = maxf(tiempo - delta, 0.0)
		if tiempo <= 0.001:
			_activar_modo_juicio_final()
	elif modo_juicio_final and not modo_abismo:
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
	# Consulta el Pulgar del Emperador antes de dar por perdida la run
	var favor_mgr = get_tree().get_first_node_in_group("favor_emperador_manager")
	var pj = get_tree().get_first_node_in_group("jugador")
	if pj == null:
		pj = get_tree().get_first_node_in_group("player")

	if favor_mgr != null and not favor_mgr.juicio_usado and pj != null:
		favor_mgr.intentar_juicio_emperador_al_morir(pj)
		return

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
