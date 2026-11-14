extends "res://santuario_base.gd"
class_name CofreGladiador

## CofreGladiador - Cofre reforzado del Coliseo (estilo Vampire Survivors / Megabonk).
## Cuesta Denarios crecientes por cofre abierto en la run (base 4, +50% cada apertura).
## Puede otorgar 1, 3 o 5 recompensas ("¡JACKPOT x5!" al 3% base escalado por suerte).

const ESCENA_DROP = preload("res://drop_item.tscn")

const STATS_COFRE := [
	{"id": "dano", "titulo": "⚔️ Filo Mortal"},
	{"id": "cadencia", "titulo": "⚡ Furia Veloz"},
	{"id": "vida", "titulo": "🛡️ Vitalidad"},
	{"id": "velocidad", "titulo": "👟 Agilidad"},
	{"id": "critico", "titulo": "🎯 Precisión Letal"},
	{"id": "iman", "titulo": "🧲 Imán Rúnico"},
	{"id": "fortuna", "titulo": "🍀 Fortuna del Coliseo"},
]

var _tapa: MeshInstance3D = null
var _emblema: MeshInstance3D = null

func _configurar_santuario() -> void:
	nombre_santuario = "Cofre del Gladiador"
	costo_denarios = _calcular_costo_actual()
	radio_interaccion = 5.5
	un_solo_uso = true
	activacion_por_clic = true
	color_luz = Color(1.0, 0.72, 0.18)
	altura_etiqueta = 2.85

func _construir_visual() -> void:
	var mat_madera := _crear_material(Color(0.45, 0.16, 0.12), Color(0.25, 0.04, 0.02), 0.15, 0.15, 0.6)
	var mat_oro := _crear_material(Color(0.98, 0.78, 0.22), Color(1.0, 0.75, 0.18), 0.9, 0.85, 0.22)

	# Base inferior del cofre
	var cuerpo := MeshInstance3D.new()
	var m_cuerpo := BoxMesh.new()
	m_cuerpo.size = Vector3(1.5, 0.78, 1.05)
	m_cuerpo.material = mat_madera
	cuerpo.mesh = m_cuerpo
	cuerpo.position = Vector3(0.0, 0.42, 0.0)
	visual_root.add_child(cuerpo)

	# Banda dorada de refuerzo
	var banda := MeshInstance3D.new()
	var m_banda := BoxMesh.new()
	m_banda.size = Vector3(1.56, 0.16, 1.11)
	m_banda.material = mat_oro
	banda.mesh = m_banda
	banda.position = Vector3(0.0, 0.78, 0.0)
	visual_root.add_child(banda)

	# Tapa abombada / prismática
	_tapa = MeshInstance3D.new()
	var m_tapa := CylinderMesh.new()
	m_tapa.top_radius = 0.50
	m_tapa.bottom_radius = 0.52
	m_tapa.height = 1.48
	m_tapa.radial_segments = 10
	m_tapa.material = mat_madera
	_tapa.mesh = m_tapa
	_tapa.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	_tapa.position = Vector3(0.0, 0.86, 0.0)
	visual_root.add_child(_tapa)

	# Cerradura / emblema brillante flotante para lectura top-down
	_emblema = MeshInstance3D.new()
	var m_emblema := BoxMesh.new()
	m_emblema.size = Vector3(0.32, 0.42, 0.32)
	m_emblema.material = _crear_material(Color(1.0, 0.88, 0.28), Color(1.0, 0.82, 0.22), 1.8, 0.9, 0.15)
	_emblema.mesh = m_emblema
	_emblema.position = Vector3(0.0, 1.55, 0.0)
	visual_root.add_child(_emblema)

	_actualizar_etiqueta("1 / 3 / 5 Recompensas")

func _process(delta: float) -> void:
	if _consumido:
		return
	var costo_actual: int = _calcular_costo_actual()
	if costo_actual != costo_denarios:
		costo_denarios = costo_actual
		_actualizar_etiqueta("1 / 3 / 5 Recompensas")
	if _emblema != null:
		_emblema.rotate_y(delta * 1.5)
		_emblema.position.y = 1.55 + sin(Time.get_ticks_msec() * 0.0045) * 0.08

func _calcular_costo_actual() -> int:
	var c: float = 4.0
	for _i in range(FortunaManager.cofres_gladiador_abiertos):
		c = float(ceili(c * 1.5))
	return int(c)

func _activar(pj: Node3D) -> bool:
	costo_denarios = _calcular_costo_actual()
	if not _puede_pagar(pj):
		_spawn_texto_3d("Faltan Denarios (%d)" % costo_denarios, Color(1.0, 0.35, 0.35))
		AudioManager.play("escudo_bloqueo", 0.9)
		_actualizar_etiqueta("1 / 3 / 5 Recompensas")
		return false

	if not _cobrar(pj):
		return false

	FortunaManager.cofres_gladiador_abiertos += 1

	var cantidad: int = 1
	var etiqueta_banner := "🎁 ¡Botín del Gladiador!"
	if FortunaManager.tirar(0.03):
		cantidad = 5
		etiqueta_banner = "🎰 ¡JACKPOT x5!"
		AudioManager.play("jackpot", 1.15)
		AudioManager.play("legendario", 1.05)
	elif FortunaManager.tirar(0.22):
		cantidad = 3
		etiqueta_banner = "🎉 ¡BOTÍN TRIPLE x3!"
		AudioManager.play("jackpot", 1.0)
	else:
		AudioManager.play("puzzle_completo", 1.08)

	var resumen_reliquia := ""
	for i in range(cantidad):
		if i == 0:
			if cantidad >= 3 or FortunaManager.rng.randf() < 0.55:
				resumen_reliquia = _otorgar_reliquia_aleatoria(pj)
			else:
				_otorgar_mejora_rara(pj, Rareza.RARO)
		elif i == 1:
			_otorgar_mejora_rara(pj, Rareza.RARO)
		elif i == 2:
			if pj.has_method("recoger_drop"):
				pj.recoger_drop(0, 40)
				pj.recoger_drop(1, 30)
				pj.recoger_drop(2, 25)
			if pj.has_method("ganar_denarios"):
				pj.ganar_denarios(2)
		elif i == 3:
			_otorgar_reliquia_aleatoria(pj)
		else:
			_otorgar_mejora_rara(pj, Rareza.EPICO)
			if pj.has_method("recoger_drop"):
				pj.recoger_drop(0, 60)

	_soltar_chorro_pickups(cantidad)

	var txt_final: String = etiqueta_banner
	if cantidad == 1 and resumen_reliquia != "":
		txt_final = resumen_reliquia
	_spawn_texto_3d(txt_final, Color(1.0, 0.88, 0.25))
	return true

func _otorgar_reliquia_aleatoria(pj: Node3D) -> String:
	var ids := ReliquiaDatos.obtener_todos_los_ids()
	if ids.is_empty():
		return ""
	var id_rel: String = String(ids[FortunaManager.rng.randi_range(0, ids.size() - 1)])
	if pj != null and pj.has_method("agregar_reliquia"):
		pj.agregar_reliquia(id_rel, 1)
	return "%s %s" % [ReliquiaDatos.obtener_icono(id_rel), ReliquiaDatos.obtener_nombre(id_rel)]

func _otorgar_mejora_rara(pj: Node3D, min_rareza: int) -> void:
	var r: int = FortunaManager.tirar_rareza(min_rareza)
	var mult: float = FortunaManager.obtener_multiplicador_rareza(r)
	var stat: Dictionary = STATS_COFRE[FortunaManager.rng.randi_range(0, STATS_COFRE.size() - 1)]
	if pj != null and pj.has_method("aplicar_mejora"):
		pj.aplicar_mejora(String(stat["id"]), mult)
	if r == Rareza.LEGENDARIO:
		AudioManager.play("legendario", 1.0)

func _soltar_chorro_pickups(cantidad: int) -> void:
	if get_parent() == null:
		return
	var total_items := 4 + cantidad * 2
	for i in range(total_items):
		var item := ESCENA_DROP.instantiate()
		var ang: float = FortunaManager.rng.randf() * TAU
		var dist: float = FortunaManager.rng.randf_range(0.8, 2.3)
		get_parent().add_child(item)
		item.global_position = global_position + Vector3(cos(ang) * dist, 0.5, sin(ang) * dist)
		if item.has_method("iniciar"):
			var tipo_drop: int = 0 if i % 3 != 0 else 1
			if i == total_items - 1 and cantidad >= 3:
				tipo_drop = 3 # Trébol extra en cofres triples/jackpot
			item.iniciar(tipo_drop, 12 if tipo_drop < 2 else 1)
