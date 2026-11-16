extends Node
class_name EventosColiseoManager

## EventosColiseoManager — Orquestador de Climas, Mercader del Vacío, Némesis y Jefe Secreto
## 1. Tres Mutadores de Clima del Coliseo:
##    - "escarcha": Cristales de refracción interactivos; al ser golpeados estallan en 4 proyectiles helados.
##    - "fragua": Géiseres solares periódicos telegrafiados; si el Botón Móvil los cruza entra en Frenesí.
##    - "eclipse": Niebla cósmica y penumbra; duplica la ganancia de Favor y acelera anomalías.
##    - Activación a los 3:00 (180s), 7:00 (420s), 11:00 (660s) o desde 0s con Tormento >= 3.
## 2. Mercader del Vacío: Altar púrpura interactivo [E] con 3 Bendiciones Corruptas.
## 3. Monolito del Campeón Caído (600 HP) -> Invoca al Jefe Secreto "El Espejo Sombrío".
## 4. Sistema Némesis: Recompensa de venganza por el enemigo que eliminó al jugador en la run previa.

const AudioManager = preload("res://audio_manager.gd")
const BunkerVisualKit = preload("res://bunker_visual_kit.gd")
const MetaprogresoManager = preload("res://metaprogreso_manager.gd")
const CatalogoBendiciones = preload("res://catalogo_bendiciones.gd")

signal mutador_cambiado(id_mutador: String)
signal mercader_vacio_disponible(opciones: Array, restante: float)
signal mercader_vacio_cerrado()
signal monolito_destruido()
signal jefe_espejo_derrotado()
signal nemesis_derrotado()

@export var mutador_actual: String = ""

var _tiempo_transcurrido: float = 0.0
var _partida_iniciada: bool = false
var _tormento_inicial_aplicado: bool = false
var _mutador_180_activado: bool = false
var _mutador_420_activado: bool = false
var _mutador_660_activado: bool = false

# Mercader del Vacío
var _mercader_spawned: bool = false
var _nodo_mercader: Node3D = null
var _tiempo_restante_mercader: float = 45.0

# Monolito del Campeón Caído
var _monolito_spawned: bool = false
var _nodo_monolito: Node3D = null

# Sistema Némesis
var _nemesis_spawned: bool = false

# Elementos ambientales de mutadores
var _cristales_escarcha: Array[Node3D] = []
var _reloj_geyser_fragua: float = 0.0

# Referencias de iluminación y entorno
var _world_env: WorldEnvironment = null
var _luz_dir: DirectionalLight3D = null
var _env_base_bg: Color = Color(0.015, 0.018, 0.025, 1.0)
var _env_base_ambient: Color = Color(0.24, 0.28, 0.36, 1.0)
var _luz_base_color: Color = Color(0.65, 0.75, 0.9, 1.0)
var _luz_base_energy: float = 0.65

func _ready() -> void:
	add_to_group("eventos_coliseo_manager")
	call_deferred("_capturar_referencias_escena")
	call_deferred("_verificar_tormento_inicial")

func _capturar_referencias_escena() -> void:
	var arena = get_parent()
	if arena != null:
		_world_env = arena.get_node_or_null("WorldEnvironment") as WorldEnvironment
		_luz_dir = arena.get_node_or_null("LuzLunaDirectional") as DirectionalLight3D
		if _luz_dir == null:
			_luz_dir = arena.get_node_or_null("DirectionalLight3D") as DirectionalLight3D

	if _world_env != null and _world_env.environment != null:
		_env_base_bg = _world_env.environment.background_color
		_env_base_ambient = _world_env.environment.ambient_light_color
	if _luz_dir != null:
		_luz_base_color = _luz_dir.light_color
		_luz_base_energy = _luz_dir.light_energy

	# Spawnea el Monolito secreto al norte de la arena
	_crear_monolito_campeon_caido()

func _verificar_tormento_inicial() -> void:
	var nivel_tormento: int = 0
	var logros = get_tree().get_first_node_in_group("logros_manager")
	if logros != null and logros.has_method("obtener_tormento"):
		nivel_tormento = int(logros.obtener_tormento())
	elif logros != null and "nivel_tormento" in logros:
		nivel_tormento = int(logros.nivel_tormento)

	if nivel_tormento >= 3 and mutador_actual == "":
		_tormento_inicial_aplicado = true
		establecer_mutador("escarcha")

func _process(delta: float) -> void:
	if not _partida_iniciada:
		var spawner = get_tree().get_first_node_in_group("oleadas_spawner")
		if spawner != null and "partida_iniciada" in spawner and spawner.partida_iniciada:
			_partida_iniciada = true
			if not _tormento_inicial_aplicado:
				_tormento_inicial_aplicado = true
				_verificar_tormento_inicial()
		else:
			return

	_tiempo_transcurrido += delta

	# 1. Progresión cronológica de Mutadores
	if _tiempo_transcurrido >= 180.0 and not _mutador_180_activado:
		_mutador_180_activado = true
		establecer_mutador("escarcha")
	elif _tiempo_transcurrido >= 420.0 and not _mutador_420_activado:
		_mutador_420_activado = true
		establecer_mutador("fragua")
	elif _tiempo_transcurrido >= 660.0 and not _mutador_660_activado:
		_mutador_660_activado = true
		establecer_mutador("eclipse")

	# 2. Mecánicas de Mutadores en tiempo real
	if mutador_actual == "fragua":
		_reloj_geyser_fragua += delta
		if _reloj_geyser_fragua >= 5.5:
			_reloj_geyser_fragua = 0.0
			_erupcionar_geyser_solar()

	# 3. Invocar al Mercader del Vacío a los ~210s o si jugador.oro >= 200 tras 60s
	if not _mercader_spawned:
		var pj = get_tree().get_first_node_in_group("jugador")
		if pj == null:
			pj = get_tree().get_first_node_in_group("player")
		var tiene_oro = (pj != null and "oro" in pj and pj.oro >= 200 and _tiempo_transcurrido >= 60.0)
		if _tiempo_transcurrido >= 210.0 or tiene_oro:
			invocar_mercader_vacio()

	# Procesar duración del Mercader activo
	if _nodo_mercader != null and is_instance_valid(_nodo_mercader):
		_tiempo_restante_mercader -= delta
		var lbl = _nodo_mercader.get_node_or_null("Label3D") as Label3D
		if lbl != null:
			lbl.text = "🏛️ MERCADER DEL VACÍO [E]\n[%ds para partir]" % int(ceil(_tiempo_restante_mercader))
		if _tiempo_restante_mercader <= 0.0:
			_despawn_mercader_vacio()

	# 4. Spawneo del Némesis Vengativo a los 150s si hay registro activo
	if not _nemesis_spawned and _tiempo_transcurrido >= 150.0:
		_comprobar_y_spawnear_nemesis()

# ==============================================================================
# MUTADORES DE CLIMA DEL COLISEO
# ==============================================================================

func forzar_mutador_diario(semilla: int) -> void:
	var mutadores := ["escarcha", "fragua", "eclipse"]
	var elegido: String = mutadores[absi(semilla) % mutadores.size()]
	_mutador_180_activado = true
	establecer_mutador(elegido)

func cambiar_clima_aleatorio() -> void:
	var mutadores := ["escarcha", "fragua", "eclipse"]
	var candidatos: Array[String] = []
	for m in mutadores:
		if m != mutador_actual:
			candidatos.append(m)
	if candidatos.is_empty():
		candidatos = ["escarcha", "fragua", "eclipse"]
	var elegido: String = candidatos[randi() % candidatos.size()]
	establecer_mutador(elegido)

func establecer_mutador(id_mutador: String) -> void:
	mutador_actual = id_mutador.to_lower()
	emit_signal("mutador_cambiado", mutador_actual)

	# Limpiar cristales de escarcha previos
	for c in _cristales_escarcha:
		if is_instance_valid(c):
			c.queue_free()
	_cristales_escarcha.clear()

	match mutador_actual:
		"escarcha":
			_aplicar_paleta_entorno(Color(0.01, 0.04, 0.08), Color(0.18, 0.38, 0.60), Color(0.40, 0.75, 1.0), 0.75)
			_spawnea_cristales_escarcha()
			_anunciar_mutador("❄️ CLIMA: ESCARCHA GLACIAL", "Cristales de refracción han emergido en la arena", Color(0.35, 0.85, 1.0))
			AudioManager.play("altar_activado", 1.25)
		"fragua":
			_aplicar_paleta_entorno(Color(0.08, 0.02, 0.01), Color(0.48, 0.22, 0.12), Color(1.0, 0.52, 0.20), 0.85)
			_anunciar_mutador("🔥 CLIMA: FRAGUA SOLAR", "Géiseres incandescentes activos (Cargan el Núcleo a Frenesí)", Color(1.0, 0.45, 0.15))
			AudioManager.play("alerta_oleada", 1.35)
		"eclipse":
			_aplicar_paleta_entorno(Color(0.01, 0.005, 0.02), Color(0.15, 0.08, 0.28), Color(0.35, 0.15, 0.55), 0.55)
			_anunciar_mutador("🌑 CLIMA: ECLIPSE DE PLUTÓN", "Gravedad alterada · Doble Favor Imperial y más anomalías", Color(0.75, 0.35, 1.0))
			AudioManager.play("jefe_alerta", 1.2)
		_:
			_aplicar_paleta_entorno(_env_base_bg, _env_base_ambient, _luz_base_color, _luz_base_energy)

func _aplicar_paleta_entorno(bg: Color, ambient: Color, dir_light: Color, dir_energy: float) -> void:
	if _world_env != null and _world_env.environment != null:
		var env = _world_env.environment
		var tw = create_tween().set_parallel(true)
		tw.tween_property(env, "background_color", bg, 2.0)
		tw.tween_property(env, "ambient_light_color", ambient, 2.0)
	if _luz_dir != null:
		var tw_l = create_tween().set_parallel(true)
		tw_l.tween_property(_luz_dir, "light_color", dir_light, 2.0)
		tw_l.tween_property(_luz_dir, "light_energy", dir_energy, 2.0)

func _spawnea_cristales_escarcha() -> void:
	var posiciones := [
		Vector3(-12.0, 0.0, -8.0),
		Vector3(12.0, 0.0, -8.0),
		Vector3(0.0, 0.0, 10.0)
	]
	for pos in posiciones:
		var cristal = _crear_cristal_refraccion(pos)
		_cristales_escarcha.append(cristal)

func _crear_cristal_refraccion(pos: Vector3) -> Node3D:
	var cristal := Area3D.new()
	cristal.name = "CristalEscarcha"
	var scr_cristal = load("res://cristal_escarcha_interactivo.gd")
	if scr_cristal != null:
		cristal.set_script(scr_cristal)
		if cristal.has_method("configurar_cristal"):
			cristal.configurar_cristal(self, 35.0)
	get_parent().add_child(cristal)
	cristal.add_to_group("rompibles")
	cristal.global_position = pos

	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.85
	cyl.height = 2.4
	col.shape = cyl
	col.position = Vector3(0, 1.2, 0)
	cristal.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(1.1, 2.3, 1.1)
	mesh_inst.mesh = prism
	mesh_inst.position = Vector3(0, 1.15, 0)

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.35, 0.85, 1.0, 0.75)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.75, 1.0)
	mat.emission_energy_multiplier = 2.5
	mat.roughness = 0.1
	mesh_inst.material_override = mat
	cristal.add_child(mesh_inst)

	cristal.set_meta("vida", 35.0)

	return cristal

func _on_cristal_recibir_dano(dano: float, cristal: Node3D) -> void:
	if not is_instance_valid(cristal):
		return
	var v: float = cristal.get_meta("vida", 35.0) - dano
	cristal.set_meta("vida", v)
	if v <= 0.0:
		_detonar_cristal_escarcha(cristal.global_position)
		cristal.queue_free()

func _detonar_cristal_escarcha(pos: Vector3) -> void:
	AudioManager.play("orbe_explosion", 1.45)
	BunkerVisualKit.spawn_shockwave_ring(get_parent(), pos, 0.6, 7.5, Color(0.35, 0.85, 1.0, 0.7), 0.35)

	# Ralentizar y dañar a enemigos circundantes
	var radio: float = 8.0
	for e in get_tree().get_nodes_in_group("enemigos"):
		if e is Node3D and is_instance_valid(e) and pos.distance_to(e.global_position) <= radio:
			if e.has_method("recibir_dano"):
				e.recibir_dano(28.0, true)
			if "rapidez" in e:
				e.rapidez = maxf(e.rapidez * 0.50, 0.8)
				get_tree().create_timer(3.5).timeout.connect(func():
					if is_instance_valid(e) and "rapidez" in e:
						e.rapidez = e.rapidez * 2.0
				)

func _erupcionar_geyser_solar() -> void:
	var arena = get_parent()
	if arena == null:
		return

	var pj = get_tree().get_first_node_in_group("jugador")
	if pj == null:
		pj = get_tree().get_first_node_in_group("player")
	var centro = pj.global_position if (pj != null and is_instance_valid(pj)) else Vector3.ZERO
	var pos = centro + Vector3(randf_range(-8.0, 8.0), 0.05, randf_range(-8.0, 8.0))
	pos.x = clampf(pos.x, -22.0, 22.0)
	pos.z = clampf(pos.z, -22.0, 22.0)

	# 1. Anillo de advertencia telegrafiada
	var anillo_aviso = BunkerVisualKit.create_hazard_ground_ring(2.2, Color(1.0, 0.45, 0.1), Color(1.0, 0.15, 0.1), 0.75, 0.95, 0.4)
	arena.add_child(anillo_aviso)
	anillo_aviso.global_position = pos

	await get_tree().create_timer(1.3).timeout
	if not is_instance_valid(anillo_aviso):
		return
	anillo_aviso.queue_free()

	# 2. Erupción activa de fuego
	AudioManager.play("alerta_oleada", 1.6, 2.0)
	BunkerVisualKit.spawn_shockwave_ring(arena, pos, 0.5, 3.2, Color(1.0, 0.55, 0.15), 0.45)

	# Comprobar si el Botón Móvil cruza el géiser -> Entra inmediatamente en Frenesí
	var boton = get_tree().get_first_node_in_group("boton_movil")
	if boton != null and is_instance_valid(boton) and pos.distance_to(boton.global_position) <= 2.5:
		if boton.has_method("_iniciar_frenesi_sobrecarga"):
			boton._iniciar_frenesi_sobrecarga()
			_anunciar_mutador("⚡ ¡NÚCLEO CATALIZADO POR EL GÉISER!", "Sobrecarga de Frenesí activada instantáneamente", Color(1.0, 0.85, 0.2))

	# Dañar a enemigos y jugador
	for e in get_tree().get_nodes_in_group("enemigos"):
		if e is Node3D and is_instance_valid(e) and pos.distance_to(e.global_position) <= 2.5:
			if e.has_method("recibir_dano"):
				e.recibir_dano(42.0, true)
	if pj != null and is_instance_valid(pj) and pos.distance_to(pj.global_position) <= 2.4:
		if pj.has_method("recibir_dano"):
			pj.recibir_dano(12.0)

# ==============================================================================
# MERCADER DEL VACÍO (CORRUPT BLESSINGS)
# ==============================================================================

func invocar_mercader_vacio(forzar_debug: bool = false) -> void:
	if _mercader_spawned and not forzar_debug:
		return
	if _nodo_mercader != null and is_instance_valid(_nodo_mercader):
		_nodo_mercader.queue_free()
		_nodo_mercader = null
	_mercader_spawned = true
	_tiempo_restante_mercader = 45.0

	var arena = get_parent()
	if arena == null:
		return

	_nodo_mercader = Node3D.new()
	_nodo_mercader.name = "MercaderDelVacio"
	arena.add_child(_nodo_mercader)
	_nodo_mercader.global_position = Vector3(0.0, 0.0, -6.0)

	var altar_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.6, 1.4, 1.6)
	altar_mesh.mesh = box
	altar_mesh.position = Vector3(0, 0.7, 0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.06, 0.22)
	mat.emission_enabled = true
	mat.emission = Color(0.75, 0.20, 0.95)
	mat.emission_energy_multiplier = 3.5
	altar_mesh.material_override = mat
	_nodo_mercader.add_child(altar_mesh)

	var luz = OmniLight3D.new()
	luz.light_color = Color(0.75, 0.25, 1.0)
	luz.light_energy = 4.5
	luz.omni_range = 7.0
	luz.position = Vector3(0, 1.8, 0)
	_nodo_mercader.add_child(luz)

	var lbl = Label3D.new()
	lbl.name = "Label3D"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.outline_size = 10
	lbl.font_size = 36
	lbl.position = Vector3(0, 2.2, 0)
	lbl.modulate = Color(0.9, 0.5, 1.0)
	lbl.text = "🏛️ MERCADER DEL VACÍO [E]\n[45s para partir]"
	_nodo_mercader.add_child(lbl)

	var area = Area3D.new()
	area.input_ray_pickable = true
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 2.8
	cyl.height = 2.0
	col.shape = cyl
	area.add_child(col)
	_nodo_mercader.add_child(area)

	area.input_event.connect(func(_cam, ev, _p, _n, _s):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_abrir_menu_mercader()
	)

	AudioManager.play("legendario", 1.25)
	_anunciar_mutador("👁️ EL MERCADER DEL VACÍO HA APARECIDO", "Ofrece Bendiciones Corruptas prohibidas [E]", Color(0.85, 0.35, 1.0))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E and _nodo_mercader != null and is_instance_valid(_nodo_mercader):
			var pj = get_tree().get_first_node_in_group("jugador")
			if pj == null:
				pj = get_tree().get_first_node_in_group("player")
			if pj != null and pj.global_position.distance_to(_nodo_mercader.global_position) <= 5.0:
				_abrir_menu_mercader()

func _abrir_menu_mercader() -> void:
	if _nodo_mercader == null or not is_instance_valid(_nodo_mercader):
		return

	var corruptas := _obtener_opciones_corruptas_catalogo()
	emit_signal("mercader_vacio_disponible", corruptas, _tiempo_restante_mercader)

	# Presentar modal mediante ClickHUD solo como fallback si HUD no escucha la señal dedicada
	var hud = get_tree().get_first_node_in_group("hud")
	if hud == null:
		hud = get_parent().get_node_or_null("ClickHUD")
	if hud != null and not hud.has_method("_on_mercader_disponible") and hud.has_method("mostrar_selector_bendiciones"):
		hud.mostrar_selector_bendiciones(0, corruptas)

	_despawn_mercader_vacio()

func _obtener_opciones_corruptas_catalogo() -> Array:
	var pj = get_tree().get_first_node_in_group("jugador")
	if pj == null:
		pj = get_tree().get_first_node_in_group("player")
	var poseidas: Array = []
	if pj != null and "bendiciones_corruptas" in pj:
		if pj.bendiciones_corruptas is Array:
			poseidas = pj.bendiciones_corruptas.duplicate()
		elif pj.bendiciones_corruptas is Dictionary:
			poseidas = pj.bendiciones_corruptas.keys()
	var corruptas_cat := CatalogoBendiciones.obtener_opciones_corruptas(poseidas, 3)
	if not corruptas_cat.is_empty():
		return corruptas_cat

	# Fallback curado de alta fidelidad
	return [
		{
			"id": "corrupta_sobrecarga_sin_freno",
			"nombre": "Sobrecarga Sin Freno",
			"desc": "El Núcleo se encadena cada 12 clics, pero Frenesí dura 24s y otorga recompensas x5.",
			"rareza": "MITICA",
			"es_sinergia": true,
			"categoria": "corrupta",
			"color": Color(0.85, 0.15, 0.95),
			"nivel_actual": 0,
			"max_nivel": 1
		},
		{
			"id": "corrupta_hilo_corto",
			"nombre": "Hilo Corto de Arena",
			"desc": "x2.5 Daño Onda/Hilo y +35% Cadencia, pero la órbita del Botón queda limitada a <= 5.5m.",
			"rareza": "MITICA",
			"es_sinergia": true,
			"categoria": "corrupta",
			"color": Color(0.95, 0.35, 0.45),
			"nivel_actual": 0,
			"max_nivel": 1
		},
		{
			"id": "corrupta_pacto_cristal",
			"nombre": "Pacto del Cristal Frágil",
			"desc": "x2.2 Daño de Clic, +40% Daño Global y +25% Crítico, pero pierdes 40% de Vida Máxima.",
			"rareza": "MITICA",
			"es_sinergia": true,
			"categoria": "corrupta",
			"color": Color(0.65, 0.05, 0.15),
			"nivel_actual": 0,
			"max_nivel": 1
		}
	]

func aplicar_corrupta_elegida(id_corrupta: String) -> void:
	var pj = get_tree().get_first_node_in_group("jugador")
	if pj == null:
		pj = get_tree().get_first_node_in_group("player")
	if pj != null and is_instance_valid(pj):
		if pj.has_method("aplicar_bendicion_corrupta"):
			pj.aplicar_bendicion_corrupta(id_corrupta)
		elif "bendiciones_run" in pj:
			pj.bendiciones_run[id_corrupta] = 1
			if pj.has_method("recalcular_stats_incrementales"):
				pj.recalcular_stats_incrementales()

	emit_signal("mercader_vacio_cerrado")
	AudioManager.play("legendario", 1.35)

func _despawn_mercader_vacio() -> void:
	if _nodo_mercader != null and is_instance_valid(_nodo_mercader):
		BunkerVisualKit.spawn_shockwave_ring(get_parent(), _nodo_mercader.global_position, 0.5, 3.5, Color(0.75, 0.25, 1.0), 0.4)
		_nodo_mercader.queue_free()
		_nodo_mercader = null

# ==============================================================================
# MONOLITO DEL CAMPEÓN CAÍDO -> JEFE SECRETO "EL ESPEJO SOMBRÍO"
# ==============================================================================

func activar_monolito_evento() -> void:
	if _nodo_monolito == null or not is_instance_valid(_nodo_monolito):
		_monolito_spawned = false
		_crear_monolito_campeon_caido()
	if _nodo_monolito != null and is_instance_valid(_nodo_monolito):
		var pj = get_tree().get_first_node_in_group("jugador")
		if pj == null:
			pj = get_tree().get_first_node_in_group("player")
		if pj != null and is_instance_valid(pj):
			var destino: Vector3 = pj.global_position + Vector3(0.0, 0.0, -6.5)
			destino.x = clampf(destino.x, -20.0, 20.0)
			destino.z = clampf(destino.z, -20.0, 20.0)
			_nodo_monolito.global_position = destino
		BunkerVisualKit.spawn_shockwave_ring(get_parent(), _nodo_monolito.global_position, 0.8, 5.0, Color(0.75, 0.25, 1.0), 0.45)
		_anunciar_mutador("🗿 MONOLITO DEL CAMPEÓN CAÍDO INVOCADO", "Destrúyelo para liberar al Espejo Sombrío", Color(0.85, 0.45, 1.0))

func _crear_monolito_campeon_caido() -> void:
	if _monolito_spawned:
		return
	_monolito_spawned = true

	var arena = get_parent()
	if arena == null:
		return

	_nodo_monolito = StaticBody3D.new()
	_nodo_monolito.name = "MonolitoCampeonCaido"
	var scr_mono = load("res://monolito_secreto.gd")
	if scr_mono != null:
		_nodo_monolito.set_script(scr_mono)
		if _nodo_monolito.has_method("configurar_monolito"):
			_nodo_monolito.configurar_monolito(self, 600.0)
	arena.add_child(_nodo_monolito)
	_nodo_monolito.add_to_group("rompibles")
	_nodo_monolito.global_position = Vector3(0.0, 0.0, -17.0)

	var col = CollisionShape3D.new()
	var box_col = BoxShape3D.new()
	box_col.size = Vector3(2.4, 4.2, 2.4)
	col.shape = box_col
	col.position = Vector3(0, 2.1, 0)
	_nodo_monolito.add_child(col)

	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2.0, 4.0, 2.0)
	mesh_inst.mesh = box
	mesh_inst.position = Vector3(0, 2.0, 0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.05, 0.14)
	mat.metallic = 0.85
	mat.roughness = 0.25
	mat.emission_enabled = true
	mat.emission = Color(0.65, 0.15, 0.95)
	mat.emission_energy_multiplier = 2.4
	mesh_inst.material_override = mat
	_nodo_monolito.add_child(mesh_inst)

	var lbl = Label3D.new()
	lbl.name = "Label3D"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.font_size = 38
	lbl.position = Vector3(0, 4.6, 0)
	lbl.modulate = Color(0.85, 0.45, 1.0)
	lbl.text = "🗿 MONOLITO DEL CAMPEÓN CAÍDO\n[600 HP - ¡Destrúyelo para desafiar al Espejo!]"
	_nodo_monolito.add_child(lbl)

	_nodo_monolito.set_meta("vida_max", 600.0)
	_nodo_monolito.set_meta("vida", 600.0)



func _on_monolito_destruido_externo(pos: Vector3) -> void:
	_nodo_monolito = null
	emit_signal("monolito_destruido")
	_spawn_jefe_espejo_sombrio(pos)

func _on_monolito_recibir_dano(dano: float, _es_crit: bool = false) -> void:
	if _nodo_monolito == null or not is_instance_valid(_nodo_monolito):
		return

	var v: float = _nodo_monolito.get_meta("vida", 600.0) - dano
	_nodo_monolito.set_meta("vida", v)

	var lbl = _nodo_monolito.get_node_or_null("Label3D") as Label3D
	if lbl != null:
		lbl.text = "🗿 MONOLITO DEL CAMPEÓN CAÍDO\n[%d / 600 HP]" % maxi(0, int(ceil(v)))

	if v <= 0.0:
		var pos = _nodo_monolito.global_position
		_nodo_monolito.queue_free()
		_nodo_monolito = null
		emit_signal("monolito_destruido")
		_spawn_jefe_espejo_sombrio(pos)

func _spawn_jefe_espejo_sombrio(pos: Vector3) -> void:
	AudioManager.play("jefe_alerta", 1.1, 4.0)
	BunkerVisualKit.spawn_shockwave_ring(get_parent(), pos, 1.0, 8.5, Color(0.75, 0.20, 0.95), 0.5)

	var jefe = CharacterBody3D.new()
	jefe.name = "EspejoSombrio"
	var scr_esp = load("res://espejo_sombrio.gd")
	if scr_esp != null:
		jefe.set_script(scr_esp)
		if jefe.has_method("configurar_espejo"):
			jefe.configurar_espejo(self)
	get_parent().add_child(jefe)
	jefe.add_to_group("jefes")
	jefe.add_to_group("enemigos")
	jefe.global_position = pos

	jefe.set_meta("es_jefe", true)
	jefe.set_meta("tipo_enemigo_id", "espejo_sombrio")
	jefe.set_meta("vida_maxima", 850.0)
	jefe.set_meta("vida", 850.0)

	# Instanciar modelo .glb idéntico al jugador con sombreado de obsidiana
	var escena_modelo = load("res://personaje/player_rookie.glb")
	if escena_modelo != null:
		var mod = escena_modelo.instantiate() as Node3D
		jefe.add_child(mod)
		mod.scale = Vector3.ONE * 2.6
		var mat_sombra = StandardMaterial3D.new()
		mat_sombra.albedo_color = Color(0.06, 0.04, 0.12)
		mat_sombra.emission_enabled = true
		mat_sombra.emission = Color(0.68, 0.18, 0.95)
		mat_sombra.emission_energy_multiplier = 3.2
		for ch in mod.find_children("*", "MeshInstance3D", true, false):
			if ch is MeshInstance3D:
				ch.material_override = mat_sombra

	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.5
	cap.height = 2.0
	col.shape = cap
	col.position = Vector3(0, 1.0, 0)
	jefe.add_child(col)

	_anunciar_mutador("💀 ¡EL ESPEJO SOMBRÍO HA SIDO LIBERADO!", "El reflejo maldito del campeón imita tus habilidades", Color(0.85, 0.25, 1.0))

# ==============================================================================
# SISTEMA NÉMESIS
# ==============================================================================

func _comprobar_y_spawnear_nemesis() -> void:
	if _nemesis_spawned:
		return

	MetaprogresoManager.asegurar_inicializado()
	var nemesis_activo: Dictionary = MetaprogresoManager.nemesis_activo if MetaprogresoManager.nemesis_activo is Dictionary else {}

	if not bool(nemesis_activo.get("activo", false)):
		return

	_nemesis_spawned = true
	var clase_nem = str(nemesis_activo.get("clase_enemigo", "espectro")).to_lower()
	var escena_mapa := {
		"centurion": "centurion_corrupto",
		"coloso": "coloso_bronce",
		"maestra": "maestra_sanguinaria",
		"parca": "parca_roja"
	}
	var archivo_escena: String = str(escena_mapa.get(clase_nem, clase_nem))
	var oro_rob = int(nemesis_activo.get("oro_robado", 60))
	var clics_rob = int(nemesis_activo.get("clics_robados", 30))

	var ruta_escena := "res://%s.tscn" % archivo_escena
	if not ResourceLoader.exists(ruta_escena):
		ruta_escena = "res://guardia.tscn"

	var escena = load(ruta_escena) as PackedScene
	if escena != null:
		var enemigo = escena.instantiate() as CharacterBody3D
		get_parent().add_child(enemigo)
		enemigo.global_position = Vector3(randf_range(-15.0, 15.0), 0.0, randf_range(-15.0, 15.0))
		enemigo.scale = Vector3.ONE * 1.55

		var oro_ex: int = int(ceil(float(oro_rob) * 0.50))
		var clics_ex: int = int(ceil(float(clics_rob) * 0.50))
		enemigo.set_meta("es_nemesis", true)
		enemigo.set_meta("oro_nemesis_extra", oro_ex)
		enemigo.set_meta("clics_nemesis_extra", clics_ex)
		if "es_nemesis" in enemigo:
			enemigo.es_nemesis = true
			enemigo.oro_nemesis_extra = oro_ex
			enemigo.clics_nemesis_extra = clics_ex
		if "vida_maxima" in enemigo:
			enemigo.vida_maxima *= 2.5
			enemigo.vida = enemigo.vida_maxima

		var lbl = Label3D.new()
		lbl.name = "Label3D"
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		lbl.font_size = 40
		lbl.position = Vector3(0, 2.6, 0)
		lbl.modulate = Color(1.0, 0.85, 0.2)
		lbl.text = "💀 NÉMESIS VENGATIVO\n[Recupera %d🪙 y %d⚡]" % [int(oro_rob * 0.5), int(clics_rob * 0.5)]
		enemigo.add_child(lbl)

		AudioManager.play("alerta_oleada", 1.45, 3.0)
		_anunciar_mutador("💀 ¡TU NÉMESIS HA ENTRADO AL COLISEO!", "Derrótalo para recuperar tu botín perdido", Color(1.0, 0.85, 0.2))

func _anunciar_mutador(tit: String, sub: String, col: Color) -> void:
	var pool = get_tree().get_first_node_in_group("damage_numbers")
	var pj = get_tree().get_first_node_in_group("jugador")
	if pj == null:
		pj = get_tree().get_first_node_in_group("player")
	if pool != null and pj != null and is_instance_valid(pj):
		pool.mostrar_texto(pj.global_position + Vector3(0, 2.8, 0), "%s\n%s" % [tit, sub], col, 1.5)
