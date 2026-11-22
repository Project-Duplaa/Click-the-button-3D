extends "res://santuario_base.gd"
class_name FuenteDeseos

## FuenteDeseos - Santuario de apuesta multi-uso (hasta 5 deseos).
## Cada deseo incrementa el costo en Denarios un +50% (ceili).
## La Suerte efectiva reduce el peso del resultado vacío ("Nada").

const MAX_USOS: int = 5
const ESCENA_DROP = preload("res://drop_item.tscn")
const ArenaColiseo = preload("res://arena_coliseo.gd")

const STATS_DESEO := [
	{"id": "dano", "titulo": "⚔️ Filo Mortal"},
	{"id": "cadencia", "titulo": "⚡ Furia Veloz"},
	{"id": "vida", "titulo": "🛡️ Vitalidad"},
	{"id": "velocidad", "titulo": "👟 Agilidad"},
	{"id": "critico", "titulo": "🎯 Precisión Letal"},
	{"id": "iman", "titulo": "🧲 Imán Rúnico"},
	{"id": "fortuna", "titulo": "🍀 Fortuna del Coliseo"},
]

var _usos_actuales: int = 0
var _orbe_agua: MeshInstance3D = null
var _leds_carga: Array[MeshInstance3D] = []
var _anillo_suelo: MeshInstance3D = null

func _configurar_santuario() -> void:
	nombre_santuario = "Fuente de los Deseos"
	costo_denarios = 3
	radio_interaccion = 5.5
	un_solo_uso = false
	activacion_por_clic = true
	color_luz = BunkerVisualKit.COL_CRYO_BLUE
	altura_etiqueta = 3.25

func _construir_visual() -> void:
	_leds_carga.clear()

	# Anillo táctico de suelo criogénico
	_anillo_suelo = BunkerVisualKit.create_hazard_ground_ring(
		1.5,
		BunkerVisualKit.COL_CRYO_BLUE,
		BunkerVisualKit.COL_CYAN_ELECTRIC,
		0.80,
		0.95,
		0.38
	)
	var ring_mat := _anillo_suelo.material_override as ShaderMaterial
	if ring_mat != null:
		ring_mat.set_shader_parameter("progress", 1.0)
		ring_mat.set_shader_parameter("active_state", 1.0)
	visual_root.add_child(_anillo_suelo)

	# Base de contención blindada (16 lados)
	BunkerVisualKit.make_cylinder(
		visual_root,
		"BaseContencionBlindada",
		1.15,
		1.32,
		0.36,
		BunkerVisualKit.get_armor_grey_mat(),
		Vector3(0.0, 0.18, 0.0),
		16
	)

	# Collarín de bloqueo criogénico
	BunkerVisualKit.make_cylinder(
		visual_root,
		"CollarinCriogenico",
		1.02,
		1.08,
		0.14,
		BunkerVisualKit.get_chassis_mat(),
		Vector3(0.0, 0.43, 0.0),
		16
	)

	# Fluido refrigerante interno luminiscente
	BunkerVisualKit.make_cylinder(
		visual_root,
		"FluidoRefrigerante",
		0.76,
		0.76,
		0.72,
		BunkerVisualKit.make_emissive_mat(
			BunkerVisualKit.COL_CRYO_BLUE,
			2.1,
			BunkerVisualKit.COL_CRYO_BLUE,
			0.2,
			0.15,
			0.88
		),
		Vector3(0.0, 0.86, 0.0),
		16
	)

	# Cilindro de cristal presurizado translúcido (alpha = 0.32, cian)
	var mat_cristal := BunkerVisualKit.make_emissive_mat(
		BunkerVisualKit.COL_CYAN_ELECTRIC,
		0.55,
		Color(0.55, 0.94, 1.0),
		0.1,
		0.08,
		0.32
	)
	BunkerVisualKit.make_cylinder(
		visual_root,
		"CristalPresurizado",
		0.86,
		0.86,
		0.88,
		mat_cristal,
		Vector3(0.0, 0.94, 0.0),
		16
	)

	# Anillo superior de sellado del tanque
	BunkerVisualKit.make_cylinder(
		visual_root,
		"AnilloSelladoSuperior",
		0.92,
		0.90,
		0.14,
		BunkerVisualKit.get_armor_grey_mat(),
		Vector3(0.0, 1.42, 0.0),
		16
	)

	# Columna inyectora central de titanio con boquilla superior
	BunkerVisualKit.make_cylinder(
		visual_root,
		"ColumnaInyectora",
		0.18,
		0.26,
		1.24,
		BunkerVisualKit.get_titanium_mat(),
		Vector3(0.0, 1.02, 0.0),
		12
	)
	BunkerVisualKit.make_cylinder(
		visual_root,
		"BoquillaSuperior",
		0.28,
		0.18,
		0.16,
		BunkerVisualKit.get_chrome_mat(),
		Vector3(0.0, 1.66, 0.0),
		12
	)

	# 4 tuberías laterales de goma
	for i in range(4):
		var ang: float = (TAU * 0.25) * float(i) + PI * 0.25
		var pos_tubo := Vector3(cos(ang) * 0.92, 0.90, sin(ang) * 0.92)
		BunkerVisualKit.make_cylinder(
			visual_root,
			"ConductoGoma_%d" % i,
			0.055,
			0.055,
			0.92,
			BunkerVisualKit.get_rubber_conduit_mat(),
			pos_tubo,
			8
		)

	# 5 Cápsulas LED de Carga alrededor del collarín superior
	for i in range(MAX_USOS):
		var frac_ang: float = float(i) / float(MAX_USOS)
		var ang_led: float = frac_ang * TAU
		var pos_led := Vector3(cos(ang_led) * 0.82, 1.54, sin(ang_led) * 0.82)
		var mat_led := BunkerVisualKit.make_emissive_mat(
			BunkerVisualKit.COL_CYAN_ELECTRIC,
			2.6
		)
		var led := BunkerVisualKit.make_cylinder(
			visual_root,
			"LedCarga_%d" % i,
			0.075,
			0.085,
			0.16,
			mat_led,
			pos_led,
			10
		)
		_leds_carga.append(led)

	# Celda esférica / cápsula de deuterio flotando en Y = 1.95
	_orbe_agua = MeshInstance3D.new()
	_orbe_agua.name = "CeldaDeuterio"
	var m_orbe := SphereMesh.new()
	m_orbe.radius = 0.30
	m_orbe.height = 0.60
	_orbe_agua.mesh = m_orbe
	_orbe_agua.material_override = BunkerVisualKit.create_hologram_material(
		BunkerVisualKit.COL_CYAN_ELECTRIC,
		Color.WHITE,
		2.4
	)
	_orbe_agua.position = Vector3(0.0, 1.95, 0.0)
	visual_root.add_child(_orbe_agua)

	_actualizar_etiqueta("Usos 0/%d" % MAX_USOS)

func _process(delta: float) -> void:
	if _consumido or _orbe_agua == null:
		return
	_orbe_agua.rotate_y(delta * 1.8)
	_orbe_agua.position.y = 1.95 + sin(Time.get_ticks_msec() * 0.0045) * 0.09

func _activar(pj: Node3D) -> bool:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("mostrar_letrero_temporal"):
		hud.mostrar_letrero_temporal("fuente_deseos", "⛲ FUENTE DE LOS DESEOS", "Lanza Denarios a la fuente. Tu Suerte determinará si obtienes oro, estadísticas o duplicados.", Color(0.35, 0.75, 1.0))

	if _usos_actuales >= MAX_USOS:
		return false
	if not _cobrar(pj):
		return false

	# La suerte efectiva reduce el peso de "Nada" y lo redistribuye hacia los premios
	var l_raw: float = FortunaManager.obtener_suerte_efectiva()
	var w_nada: float = 35.0
	if l_raw >= 0.0:
		w_nada = 35.0 / (1.0 + l_raw)
	else:
		w_nada = 35.0 * (1.0 + clampf(-l_raw, 0.0, 0.55))

	var bono_desplazado: float = 35.0 - w_nada
	var w_oro: float = maxf(5.0, 30.0 + bono_desplazado * 0.46)
	var w_stat: float = maxf(5.0, 25.0 + bono_desplazado * 0.38)
	var w_dup: float = maxf(3.0, 10.0 + bono_desplazado * 0.16)
	var total: float = w_nada + w_oro + w_stat + w_dup

	var r_deseo: float = FortunaManager.rng.randf_range(0.0, total)
	if r_deseo < w_nada:
		_spawn_texto_3d("💧 El agua guarda silencio...", Color(0.62, 0.78, 0.94))
		AudioManager.play("click", 0.72)
	elif r_deseo < w_nada + w_oro:
		_otorgar_lluvia_oro(pj)
	elif r_deseo < w_nada + w_oro + w_stat:
		var rareza: int = FortunaManager.tirar_rareza(Rareza.RARO)
		var mult: float = FortunaManager.obtener_multiplicador_rareza(rareza)
		var idx: int = FortunaManager.rng.randi_range(0, STATS_DESEO.size() - 1)
		var stat: Dictionary = STATS_DESEO[idx]
		if pj.has_method("aplicar_mejora"):
			pj.aplicar_mejora(String(stat["id"]), mult)
		AudioManager.play("legendario" if rareza == Rareza.LEGENDARIO else "puzzle_completo", 1.1)
		_spawn_texto_3d("✨ %s [%s]" % [String(stat["titulo"]), Rareza.obtener_nombre(rareza)], Rareza.obtener_color(rareza))
	else:
		if "duplicar_proxima_carta" in pj:
			pj.duplicar_proxima_carta = true
		AudioManager.play("legendario", 1.08)
		_spawn_texto_3d("🃏 ¡PRÓXIMA CARTA x2!", Color(0.86, 0.42, 1.0))

	_usos_actuales += 1
	costo_denarios = ceili(float(costo_denarios) * 1.5)

	var led_idx := _usos_actuales - 1
	if led_idx >= 0 and led_idx < _leds_carga.size():
		var led := _leds_carga[led_idx]
		if led != null and is_instance_valid(led):
			led.material_override = BunkerVisualKit.make_emissive_mat(
				Color(0.18, 0.06, 0.08),
				0.15,
				Color(0.18, 0.06, 0.08)
			)

	if _anillo_suelo != null and is_instance_valid(_anillo_suelo):
		var ring_mat := _anillo_suelo.material_override as ShaderMaterial
		if ring_mat != null:
			ring_mat.set_shader_parameter("progress", float(MAX_USOS - _usos_actuales) / float(MAX_USOS))

	if _usos_actuales >= MAX_USOS:
		_consumir()
	else:
		_actualizar_etiqueta("Usos %d/%d" % [_usos_actuales, MAX_USOS])

	return false

func _otorgar_lluvia_oro(pj: Node3D) -> void:
	if pj != null and pj.has_method("recoger_drop"):
		pj.recoger_drop(0, 40)
	if get_parent() != null:
		for i in range(8):
			var item := ESCENA_DROP.instantiate()
			var ang: float = (TAU / 8.0) * float(i) + FortunaManager.rng.randf_range(-0.2, 0.2)
			var dist: float = FortunaManager.rng.randf_range(1.3, 2.4)
			get_parent().add_child(item)
			item.global_position = ArenaColiseo.clamping_y_ajustar_a_suelo(global_position + Vector3(cos(ang) * dist, 0.0, sin(ang) * dist), 1.4, 0.45)
			if item.has_method("iniciar"):
				item.iniciar(0, 10)
	AudioManager.play("jackpot", 1.12)
	_spawn_texto_3d("🪙 ¡LLUVIA DE ORO!", Color(1.0, 0.88, 0.25))
