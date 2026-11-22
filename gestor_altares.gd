extends Node

# Gestor de Altares Rúnicos - Easter Egg / Evento CoD Zombies
# Desarrollado por: Juan Camilo Angulo Camelo
# Administra los 3 pedestales de la arena 60x60 e invoca la recompensa ancestral al completarse.

class_name GestorAltares

const AudioManager = preload("res://audio_manager.gd")
const ArenaColiseo = preload("res://arena_coliseo.gd")

signal evento_completado

@export var cofre_dorado_escena: PackedScene = preload("res://cofre_dorado.tscn")
@export var posicion_recompensa: Vector3 = Vector3(0.0, 0.5, 2.8)

var total_altares: int = 3
var altares_resueltos: int = 0
var completado: bool = false
var _altares_ordenados: Array = []
var _oleadas_desbloqueo: Array[int] = [3, 5, 7]
var _indice_siguiente_desbloqueo: int = 0

func _ready():
	add_to_group("gestor_altares")
	call_deferred("_conectar_altares")

func _conectar_altares():
	var tree = get_tree()
	if tree == null:
		return
	var altares = tree.get_nodes_in_group("altares_runicos")
	if altares.size() > 0:
		total_altares = altares.size()
	_altares_ordenados = altares.duplicate()
	_altares_ordenados.sort_custom(func(a, b):
		var ida: int = int(a.id_altar) if ("id_altar" in a) else 0
		var idb: int = int(b.id_altar) if ("id_altar" in b) else 0
		return ida < idb
	)
	_indice_siguiente_desbloqueo = 0
	for altar in _altares_ordenados:
		if altar.has_signal("activado") and not altar.activado.is_connected(_on_altar_activado):
			altar.activado.connect(_on_altar_activado)
		if altar.has_method("establecer_sellado"):
			altar.establecer_sellado()
	_reubicar_altares_aleatorios_run()
	print("[GestorAltares] Conectados %d altares rúnicos (sellados hasta Oleadas 3/5/7)." % total_altares)

func _process(_delta: float) -> void:
	if not is_inside_tree() or get_tree() == null:
		return
	if _indice_siguiente_desbloqueo >= _altares_ordenados.size():
		return
	var spawner = get_tree().get_first_node_in_group("spawner")
	if spawner == null or not bool(spawner.get("partida_iniciada")):
		return
	var oleada_ahora: int = int(spawner.get("oleada_actual"))
	while _indice_siguiente_desbloqueo < _altares_ordenados.size():
		var idx_ol: int = mini(_indice_siguiente_desbloqueo, _oleadas_desbloqueo.size() - 1)
		var oleada_req: int = _oleadas_desbloqueo[idx_ol]
		if oleada_ahora < oleada_req:
			break
		var altar = _altares_ordenados[_indice_siguiente_desbloqueo]
		if is_instance_valid(altar) and altar.has_method("desbloquear_terminal"):
			altar.desbloquear_terminal()
		_indice_siguiente_desbloqueo += 1

func _on_altar_activado(id_altar: int):
	altares_resueltos += 1
	print("[GestorAltares] Progreso del puzzle: %d de %d altares despertados." % [altares_resueltos, total_altares])
	
	if altares_resueltos >= total_altares and not completado:
		completado = true
		_desencadenar_evento_secreto()

func _desencadenar_evento_secreto():
	print("=====================================================")
	print("¡EVENTO SECRETO COD ZOMBIES DESPERTADO EN EL COLISEO!")
	print("=====================================================")
	
	AudioManager.play("puzzle_completo", 1.0)
	
	# Invocar Cofre Dorado Ancestral
	if cofre_dorado_escena != null and is_inside_tree() and get_parent() != null:
		var cofre = cofre_dorado_escena.instantiate()
		get_parent().add_child(cofre)
		cofre.global_position = ArenaColiseo.clamping_y_ajustar_a_suelo(posicion_recompensa, 1.8, 0.5)
		var pool_dano = get_tree().get_first_node_in_group("damage_numbers") if get_tree() != null else null
		if pool_dano != null and pool_dano.has_method("mostrar_texto"):
			pool_dano.mostrar_texto(cofre.global_position + Vector3(0, 2.5, 0), "👑 ¡PUZZLE RESUELTO! COFRE DORADO ANCESTRAL", Color(1.0, 0.85, 0.25), 2.2)

func _reubicar_altares_aleatorios_run() -> void:
	if _altares_ordenados.is_empty():
		return
	var rng: RandomNumberGenerator = ArenaColiseo._obtener_rng_run(self)
	var parent_node: Node = get_parent()
	var deco: Node = parent_node.get_node_or_null("DecoracionesArena") if parent_node != null else null

	# Vincular cada grupo de props decorativos de altar por proximidad inicial antes de moverlos
	var pares_props: Dictionary = {}
	if deco != null:
		var grupos: Array = [
			["AltarNW_Barrera", "AltarNW_Caja"],
			["AltarNE_Barrera", "AltarNE_Caja"],
			["AltarSW_Barrera", "AltarSW_Tanque"],
		]
		for g in grupos:
			var n0: Node3D = deco.get_node_or_null(str(g[0])) as Node3D
			var n1: Node3D = deco.get_node_or_null(str(g[1])) as Node3D
			if n0 == null:
				continue
			var mejor_altar: Node3D = null
			var mejor_d: float = 999999.0
			for a in _altares_ordenados:
				var a3: Node3D = a as Node3D
				if a3 == null or pares_props.has(a3):
					continue
				var d: float = Vector2(a3.global_position.x - n0.global_position.x, a3.global_position.z - n0.global_position.z).length()
				if d < mejor_d:
					mejor_d = d
					mejor_altar = a3
			if mejor_altar != null:
				pares_props[mejor_altar] = [n0, n1]

	var titulos: Array[String] = ["Altar Rúnico I", "Altar Rúnico II", "Altar Rúnico III"]
	var exclusiones: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.0, 5.25)]
	var ang_base: float = rng.randf() * TAU
	var primer_pasarela: int = int(rng.randi() % 2)

	for i in range(_altares_ordenados.size()):
		var altar: Node3D = _altares_ordenados[i] as Node3D
		if altar == null:
			continue
		var en_pasarela: bool = ((i + primer_pasarela) % 2) == 1
		if i >= 2:
			en_pasarela = rng.randf() < 0.5
		var r_min: float = 42.5 if en_pasarela else 23.0
		var r_max: float = 48.0 if en_pasarela else 35.0

		var elegido := Vector3.ZERO
		var ang_centro: float = ang_base + float(i) * (TAU / 3.0)
		for _intento in range(48):
			var ang: float = ang_centro + rng.randf_range(-0.42, 0.42)
			var r: float = rng.randf_range(r_min, r_max)
			var cand := Vector3(sin(ang) * r, 0.0, -cos(ang) * r)
			if not ArenaColiseo.esta_dentro(cand, 2.8):
				continue
			if ArenaColiseo.esta_en_pendiente(cand.x, cand.z, 1.0):
				continue
			if not ArenaColiseo.punto_libre_de_obstaculos(cand, 3.6):
				continue
			var m_c: float = ArenaColiseo.apotema_en_pos(cand.x, cand.z)
			if m_c >= (ArenaColiseo.APOTEMA_FOSO - 1.6) and m_c <= (ArenaColiseo.APOTEMA_FOSO + 1.6):
				continue
			var h_c: float = ArenaColiseo.obtener_altura_suelo(cand.x, cand.z)
			if en_pasarela and h_c < (ArenaColiseo.ALTURA_PASARELA - 0.05):
				continue
			if not en_pasarela and h_c > 0.08:
				continue
			var p2 := Vector2(cand.x, cand.z)
			var separado := true
			for ex in exclusiones:
				if p2.distance_to(ex) < 24.0:
					separado = false
					break
			if separado:
				elegido = ArenaColiseo.clamping_y_ajustar_a_suelo(cand, 2.8, 0.0)
				break

		if elegido == Vector3.ZERO:
			elegido = ArenaColiseo.punto_seguro_con_exclusiones(r_min, r_max, exclusiones, 18.0, rng, 0.0, false, false)

		altar.global_position = elegido
		altar.rotation.y = atan2(-elegido.x, -elegido.z)
		exclusiones.append(Vector2(elegido.x, elegido.z))

		if i < titulos.size() and "nombre_altar" in altar:
			altar.nombre_altar = titulos[i]
			if altar.has_method("_actualizar_etiqueta"):
				altar.call("_actualizar_etiqueta")

		if pares_props.has(altar):
			var par: Array = pares_props[altar]
			var rad: Vector3 = Vector3(elegido.x, 0.0, elegido.z).normalized()
			if rad.length_squared() < 0.01:
				rad = Vector3.FORWARD
			var tang: Vector3 = Vector3(-rad.z, 0.0, rad.x)
			var p_bar: Node3D = par[0] as Node3D
			var p_obj: Node3D = par[1] as Node3D
			if p_bar != null:
				var pb := ArenaColiseo.clamping_y_ajustar_a_suelo(elegido + tang * 2.1 - rad * 1.1, 2.0, 0.0)
				p_bar.global_position = pb
				p_bar.rotation.y = atan2(-pb.x, -pb.z) + 0.35
			if p_obj != null:
				var po := ArenaColiseo.clamping_y_ajustar_a_suelo(elegido - tang * 1.9 - rad * 0.9, 2.0, 0.0)
				p_obj.global_position = po
				p_obj.rotation.y = atan2(-po.x, -po.z) - 0.25

	posicion_recompensa = ArenaColiseo.punto_seguro_con_exclusiones(8.0, 18.5, exclusiones, 6.0, rng, 0.0, false, false)
		
	emit_signal("evento_completado")
