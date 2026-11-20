extends Node

## Gestor de Anomalías del Núcleo Móvil — Spawner de Objetivos de Clic
## No inicia el conteo del temporizador de spawn hasta que la partida haya comenzado efectivamente.
## Conecta la XP ganada directamente con pj.ganar_xp() para asegurar la subida de nivel.

const AudioManager = preload("res://audio_manager.gd")
const AnomaliaEscena = preload("res://anomalia_click.tscn")

@export var intervalo_min: float = 12.0
@export var intervalo_max: float = 16.0
@export var max_anomalias_simultaneas: int = 2
@export var pausar_en_jefes: bool = true

var _reloj_spawn: float = 8.0

func _ready():
	_reloj_spawn = 6.0

func _hay_jefe_activo(spawner: Node) -> bool:
	if spawner != null and is_instance_valid(spawner) and spawner.has_method("hay_jefe_activo"):
		if bool(spawner.hay_jefe_activo()):
			return true
	var tree := get_tree()
	if tree == null:
		return false
	for grupo in ["jefes", "bosses"]:
		for n in tree.get_nodes_in_group(grupo):
			if is_instance_valid(n) and not n.is_queued_for_deletion():
				var esta_muerto := ("muerto" in n and bool(n.muerto))
				var tiene_vida := (not ("vida" in n) or float(n.vida) > 0.0)
				if not esta_muerto and tiene_vida:
					return true
	for p in tree.get_nodes_in_group("portal_spawn"):
		if is_instance_valid(p) and not p.is_queued_for_deletion() and ("es_jefe" in p and bool(p.es_jefe)):
			if not ("_spawneado" in p) or not bool(p._spawneado):
				return true
	return false

func _process(delta: float):
	var spawner = get_parent().get_node_or_null("OleadasSpawner")
	if spawner == null:
		spawner = get_tree().get_first_node_in_group("spawner")
		
	var en_partida = false
	if spawner != null:
		if "partida_iniciada" in spawner:
			en_partida = spawner.partida_iniciada
		elif "en_partida" in spawner:
			en_partida = spawner.en_partida
			
	if not en_partida:
		return

	if pausar_en_jefes and _hay_jefe_activo(spawner):
		return
		
	_reloj_spawn -= delta
	if _reloj_spawn <= 0.0:
		_reloj_spawn = randf_range(intervalo_min, intervalo_max)
		_intentar_spawn_anomalia()

func _intentar_spawn_anomalia():
	var activas = get_tree().get_nodes_in_group("anomalias_click").size()
	if activas >= max_anomalias_simultaneas:
		return
		
	var anomalia = AnomaliaEscena.instantiate()
	var rx = randf_range(-22.0, 22.0)
	var rz = randf_range(-22.0, 22.0)
	var pos = Vector3(rx, 0.0, rz)
	
	get_parent().add_child(anomalia)
	anomalia.global_position = pos
	
	AudioManager.play("altar_activado", 1.5, -4.0)

func _al_completar_anomalia(xp_ganada: int, oro_ganado: int):
	var pj = get_tree().get_first_node_in_group("player")
	if pj == null:
		pj = get_tree().get_first_node_in_group("jugador")
	if pj != null:
		if pj.has_method("ganar_xp"):
			pj.ganar_xp(xp_ganada)
		elif pj.has_method("recoger_drop"):
			pj.recoger_drop(1, xp_ganada)
			
		if pj.has_method("recoger_drop"):
			pj.recoger_drop(0, oro_ganado)
