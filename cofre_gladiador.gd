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
var _leds_cierre: Array[MeshInstance3D] = []

func _configurar_santuario() -> void:
	nombre_santuario = "Cofre del Gladiador"
	costo_denarios = _calcular_costo_actual()
	radio_interaccion = 5.5
	un_solo_uso = true
	activacion_por_clic = true
	color_luz = BunkerVisualKit.COL_HAZARD_YELLOW
	altura_etiqueta = 2.85

func _construir_visual() -> void:
	_leds_cierre.clear()

	# Anillo de suelo hazard amarillo / dorado
	var ring := BunkerVisualKit.create_hazard_ground_ring(
		1.25,
		BunkerVisualKit.COL_HAZARD_YELLOW,
		BunkerVisualKit.COL_VAULT_GOLD,
		0.80,
		0.95,
		0.35
	)
	var ring_mat := ring.material_override as ShaderMaterial
	if ring_mat != null:
		ring_mat.set_shader_parameter("progress", 1.0)
	visual_root.add_child(ring)

	# Patines inferiores de acero carbono
	for sx in [-0.54, 0.54]:
		BunkerVisualKit.make_box(
			visual_root,
			"PatinAcero_%s" % ("L" if sx < 0.0 else "R"),
			Vector3(0.24, 0.12, 1.16),
			BunkerVisualKit.get_chassis_mat(),
			Vector3(sx, 0.06, 0.0)
		)

	# Chasis Pelican militar
	BunkerVisualKit.make_box(
		visual_root,
		"ChasisPelican",
		Vector3(1.55, 0.68, 1.05),
		BunkerVisualKit.get_armor_grey_mat(),
		Vector3(0.0, 0.44, 0.0)
	)

	# 4 esquineros verticales reforzados de polímero/caucho
	for sx in [-0.77, 0.77]:
		for sz in [-0.52, 0.52]:
			BunkerVisualKit.make_box(
				visual_root,
				"EsquineroReforzado_%s_%s" % [str(sx), str(sz)],
				Vector3(0.14, 0.72, 0.14),
				BunkerVisualKit.get_rubber_conduit_mat(),
				Vector3(sx, 0.45, sz)
			)

	# Banda central perimetral con franjas hazard amarillo/acero
	var mat_hazard := BunkerVisualKit.create_hazard_stripes_material(
		BunkerVisualKit.COL_HAZARD_YELLOW,
		BunkerVisualKit.COL_CARBON_STEEL,
		10.0
	)
	BunkerVisualKit.make_box(
		visual_root,
		"BandaPerimetralHazard",
		Vector3(1.60, 0.15, 1.10),
		mat_hazard,
		Vector3(0.0, 0.72, 0.0)
	)

	# 2 cierres neumáticos frontales con LEDs de estado en ámbar/dorado brillante
	var mat_led := BunkerVisualKit.make_emissive_mat(BunkerVisualKit.COL_HAZARD_YELLOW, 2.5)
	for sx in [-0.42, 0.42]:
		BunkerVisualKit.make_box(
			visual_root,
			"CierreNeumatico_%s" % ("L" if sx < 0.0 else "R"),
			Vector3(0.16, 0.34, 0.08),
			BunkerVisualKit.get_titanium_mat(),
			Vector3(sx, 0.62, 0.56)
		)
		var led := BunkerVisualKit.make_box(
			visual_root,
			"LedCierre_%s" % ("L" if sx < 0.0 else "R"),
			Vector3(0.10, 0.08, 0.04),
			mat_led,
			Vector3(sx, 0.72, 0.60)
		)
		_leds_cierre.append(led)

	# Tapa blindada superior biselada con rieles tácticos
	_tapa = BunkerVisualKit.make_box(
		visual_root,
		"TapaBlindada",
		Vector3(1.52, 0.22, 1.02),
		BunkerVisualKit.get_titanium_mat(),
		Vector3(0.0, 0.88, 0.0)
	)
	for sx in [-0.48, 0.48]:
		BunkerVisualKit.make_box(
			_tapa,
			"RielTactico_%s" % ("L" if sx < 0.0 else "R"),
			Vector3(0.12, 0.07, 0.92),
			BunkerVisualKit.get_chassis_mat(),
			Vector3(sx, 0.13, 0.0)
		)

	# Holoproyector táctico flotante sobre la tapa (Y = 1.48) + anillo toroidal
	_emblema = BunkerVisualKit.make_box(
		visual_root,
		"HoloproyectorTactico",
		Vector3(0.32, 0.38, 0.32),
		BunkerVisualKit.create_hologram_material(
			BunkerVisualKit.COL_HAZARD_YELLOW,
			Color(1.0, 0.95, 0.65),
			2.4
		),
		Vector3(0.0, 1.48, 0.0),
		Vector3(35.0, 45.0, 0.0)
	)
	BunkerVisualKit.make_torus(
		_emblema,
		"AnilloHoloproyector",
		0.26,
		0.32,
		BunkerVisualKit.make_emissive_mat(BunkerVisualKit.COL_VAULT_GOLD, 2.0),
		Vector3.ZERO
	)

	_actualizar_etiqueta("1 / 3 / 5 Recompensas")

func _process(delta: float) -> void:
	if _consumido:
		return
	var costo_actual: int = _calcular_costo_actual()
	if costo_actual != costo_denarios:
		costo_denarios = costo_actual
		_actualizar_etiqueta("1 / 3 / 5 Recompensas")
	if _emblema != null:
		_emblema.rotate_y(delta * 1.6)
		_emblema.position.y = 1.48 + sin(Time.get_ticks_msec() * 0.0045) * 0.07

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

	# Animación de apertura hidráulica instantánea de la tapa y salto del emblema
	if _tapa != null and is_instance_valid(_tapa):
		var tw_tapa := create_tween().set_parallel(true)
		tw_tapa.tween_property(_tapa, "rotation_degrees:x", -70.0, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_tapa.tween_property(_tapa, "position", Vector3(0.0, 1.12, -0.34), 0.08)
	if _emblema != null and is_instance_valid(_emblema):
		var tw_emb := create_tween()
		tw_emb.tween_property(_emblema, "position:y", 2.05, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

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
