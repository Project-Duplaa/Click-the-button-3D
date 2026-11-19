extends Node3D

## OleadasSpawner — Orquestador de Hordas, Jefes y Modo Abismo Infinito
## Genera oleadas progresivas y progresión cronológica de Jefes.
## En Modo Abismo Infinito: escala la tasa de spawn, vida y daño cada minuto past 15:00
## e invoca 2 Jefes simultáneos cada 120s.

const AudioManager = preload("res://audio_manager.gd")
const ArenaColiseo = preload("res://arena_coliseo.gd")
const ParasitoCursorScript = preload("res://parasito_cursor.gd")
const CanalizadorVacioScript = preload("res://canalizador_vacio.gd")
const GolemTesoroScript = preload("res://golem_tesoro.gd")
const HeraldoClicScript = preload("res://heraldo_clic.gd")

@export var guardia_escena: PackedScene = preload("res://guardia.tscn")
@export var espectro_escena: PackedScene = preload("res://espectro.tscn")
@export var arquero_escena: PackedScene = preload("res://arquero.tscn")
@export var berserker_escena: PackedScene = preload("res://berserker.tscn")
@export var kamikaze_escena: PackedScene = preload("res://kamikaze.tscn")
@export var bruto_escena: PackedScene = preload("res://bruto.tscn")
@export var centurion_escena: PackedScene = preload("res://centurion_corrupto.tscn")
@export var mini_jefe_escena: PackedScene = preload("res://mini_jefe.tscn")
@export var maestra_escena: PackedScene = preload("res://maestra_sanguinaria.tscn")
@export var coloso_escena: PackedScene = preload("res://coloso_bronce.tscn")
@export var parca_roja_escena: PackedScene = preload("res://parca_roja.tscn")
@export var portal_spawn_escena: PackedScene = preload("res://portal_spawn.tscn")

@export var intervalo_oleada: float = 12.5
@export var radio_spawn: float = 26.0
@export var max_enemigos_concurrentes: int = 55

var _reloj_oleada: float = 13.0
var _reloj_goteo: float = 4.2
var _elite_temprano_spawned: bool = false
var _tiempo_transcurrido: float = 0.0
var oleada_actual: int = 1
var hud: Node = null

var _centurion_spawned: bool = false
var _mini_jefe_spawned: bool = false
var _maestra_spawned: bool = false
var _coloso_spawned: bool = false
var _parca_spawned: bool = false
var clicks_totales: int = 0
var partida_iniciada: bool = false

# Sistema de Protagonismo y Esbirros de Jefes
const TIEMPO_MINIMO_ENTRE_JEFES: float = 120.0
var _jefe_activo: Node3D = null
var _reloj_esbirros_jefe: float = 12.0
var _tiempo_ultimo_jefe: float = -999.0

# Modo Abismo Infinito
var modo_abismo: bool = false
var nivel_abismo: int = 0
var _reloj_abismo_minuto: float = 60.0
var _reloj_abismo_dupla_jefes: float = 120.0

func _ready():
	add_to_group("spawner")
	add_to_group("oleadas_spawner")
	hud = get_parent().get_node_or_null("ClickHUD")
	var boton = get_parent().get_node_or_null("BotonMovil")
	if boton != null:
		boton.click_presionado.connect(_on_click_boton_presionado)
	_precalentar_mallas_enemigos()
	print("⏳ [OleadasSpawner] Arena en calma. Esperando el primer clic al botón para iniciar la partida.")

func _precalentar_mallas_enemigos() -> void:
	for esc in [espectro_escena, guardia_escena, berserker_escena, mini_jefe_escena]:
		if esc != null:
			var inst: Node = esc.instantiate()
			var mod: Node3D = inst.get_node_or_null("Modelo") as Node3D
			if mod != null:
				AnimadorEntidad.optimizar_modelo_esqueletico(mod)
			inst.free()

func _on_click_boton_presionado(total_clicks: int):
	clicks_totales = total_clicks

	if not partida_iniciada:
		partida_iniciada = true
		print("⚔️ [OleadasSpawner] ¡PRIMER CLIC AL BOTÓN RECIBIDO! ¡INICIANDO OLEADA 1! ⚔️")
		AudioManager.play("alerta_oleada", 1.25, 2.0)
		_generar_oleada(1)
		return

	_reloj_oleada = maxf(_reloj_oleada - 0.55, 2.0)

	if clicks_totales == 35 or (clicks_totales > 35 and clicks_totales % 45 == 0):
		_spawn_enemigo_especial("golem_tesoro")

	if clicks_totales >= 50 and clicks_totales % 50 == 0:
		invocar_heraldo_clic()

	if _hay_jefe_activo():
		return

	if clicks_totales % 12 == 0:
		_disparar_incursion_asalto(clicks_totales)

func invocar_heraldo_clic():
	print(">>> [OleadasSpawner] ⚡ ¡HERALDO DEL CLIC INVOCADO POR SOBRECARGA DE FIEBRE! ⚡ <<<")
	AudioManager.play("alerta_oleada", 1.45, 2.5)
	_spawn_enemigo_especial("heraldo_clic")

func _disparar_incursion_asalto(clicks: int):
	AudioManager.play("alerta_oleada", 1.35, 2.0)
	var extra_vida = minf(clicks * 1.1, 120.0)
	if clicks <= 12:
		for i in range(2): _spawn_enemigo(espectro_escena, extra_vida)
		_spawn_enemigo(guardia_escena, extra_vida)
	elif clicks <= 24:
		_spawn_enemigo_especial("parasito_cursor")
		for i in range(2): _spawn_enemigo(berserker_escena, extra_vida)
		for i in range(2): _spawn_enemigo(kamikaze_escena, extra_vida * 0.5)
	elif clicks <= 36:
		_spawn_enemigo_especial("canalizador_vacio")
		_spawn_enemigo(bruto_escena, extra_vida * 1.3)
		for i in range(2): _spawn_enemigo(arquero_escena, extra_vida * 0.8)
	else:
		_spawn_enemigo_especial("parasito_cursor")
		_spawn_enemigo_especial("canalizador_vacio")
		_spawn_enemigo(bruto_escena, extra_vida * 1.4)
		for i in range(2): _spawn_enemigo(berserker_escena, extra_vida)
		for i in range(3): _spawn_enemigo(espectro_escena, extra_vida)

func activar_modo_abismo() -> void:
	modo_abismo = true
	intervalo_oleada = 10.0
	_reloj_abismo_minuto = 60.0
	_reloj_abismo_dupla_jefes = 120.0
	print("🔥 [OleadasSpawner] Modo Abismo Infinito activado en OleadasSpawner.")

func _process(delta):
	if not partida_iniciada:
		return

	_tiempo_transcurrido += delta

	# Si hay un combate de jefe activo, gestionar la reaparición gradual de esbirros y pausar oleadas estándar
	if _hay_jefe_activo():
		_procesar_esbirros_jefe(delta)
	else:
		_reloj_oleada -= delta
		if _reloj_oleada <= 0.0:
			_reloj_oleada = intervalo_oleada
			oleada_actual += 1
			if hud != null and "oleada" in hud:
				hud.oleada = oleada_actual
			_generar_oleada(oleada_actual)

		# Goteo continuo de presión entre oleadas
		_reloj_goteo -= delta
		if _reloj_goteo <= 0.0:
			_reloj_goteo = maxf(2.4, 4.4 - float(oleada_actual) * 0.25)
			var enemigos_activos := get_tree().get_nodes_in_group("enemigos").size()
			if enemigos_activos < max_enemigos_concurrentes:
				var extra_goteo := float(maxi(0, oleada_actual - 1)) * 2.5
				var esc_goteo: PackedScene = espectro_escena
				if oleada_actual >= 3 and randf() < 0.35:
					esc_goteo = arquero_escena
				elif oleada_actual >= 2 and randf() < 0.40:
					esc_goteo = guardia_escena
				var cant_goteo := 2 if oleada_actual >= 3 else 1
				for _g in range(cant_goteo):
					_spawn_enemigo(esc_goteo, extra_goteo, 0.0, false)

	if modo_abismo:
		_reloj_abismo_minuto -= delta
		if _reloj_abismo_minuto <= 0.0:
			_reloj_abismo_minuto = 60.0
			nivel_abismo += 1
			intervalo_oleada = maxf(6.0, intervalo_oleada - 0.5)
			print("🔥 [OleadasSpawner] Abismo Nivel %d: Incremento de dificultad." % nivel_abismo)

		_reloj_abismo_dupla_jefes -= delta
		if _reloj_abismo_dupla_jefes <= 0.0:
			_reloj_abismo_dupla_jefes = 120.0
			_spawn_dupla_jefes_abismo()
	else:
		# Progresión cronológica espaciada de Jefes (incluye Campeón Élite a los 90s)
		if not _hay_jefe_activo():
			var tiempo_desde_ultimo = _tiempo_transcurrido - _tiempo_ultimo_jefe
			if _tiempo_transcurrido >= 90.0 and not _elite_temprano_spawned:
				_spawn_campeon_temprano()
			elif _tiempo_transcurrido >= 180.0 and not _centurion_spawned:
				spawn_centurion()
			elif _tiempo_transcurrido >= 405.0 and not _mini_jefe_spawned and tiempo_desde_ultimo >= TIEMPO_MINIMO_ENTRE_JEFES:
				spawn_mini_jefe()
			elif _tiempo_transcurrido >= 630.0 and not _maestra_spawned and tiempo_desde_ultimo >= TIEMPO_MINIMO_ENTRE_JEFES:
				spawn_maestra_sanguinaria()
			elif _tiempo_transcurrido >= 810.0 and not _coloso_spawned and tiempo_desde_ultimo >= 90.0:
				spawn_coloso_bronce()
			elif _tiempo_transcurrido >= 900.0 and not _parca_spawned:
				spawn_parca_roja()

func _spawn_campeon_temprano() -> void:
	if _elite_temprano_spawned:
		return
	_elite_temprano_spawned = true
	AudioManager.play("alerta_oleada", 1.35, 2.5)
	_spawn_enemigo(bruto_escena, 85.0, 0.0, false)
	for i in range(2):
		_spawn_enemigo(berserker_escena, 10.0, 0.35 + float(i) * 0.20, false)
	var pool = get_tree().get_first_node_in_group("damage_numbers")
	var pj = get_tree().get_first_node_in_group("jugador")
	if pj == null:
		pj = get_tree().get_first_node_in_group("player")
	if pool != null and pj != null and pool.has_method("mostrar_texto"):
		pool.mostrar_texto(pj.global_position + Vector3(0, 3.0, 0), "⚔️ ¡CAMPEÓN DE LA ARENA HA INGRESADO!", Color(1.0, 0.42, 0.18), 1.5)

func _spawn_dupla_jefes_abismo() -> void:
	AudioManager.play("jefe_alerta", 1.25, 4.0)
	var pool_jefes := [centurion_escena, mini_jefe_escena, maestra_escena, coloso_escena, parca_roja_escena]
	pool_jefes.shuffle()
	var j1 = pool_jefes[0]
	var j2 = pool_jefes[1]
	var extra_hp = float(nivel_abismo) * 85.0
	_spawn_enemigo(j1, extra_hp, 0.0, true)
	_spawn_enemigo(j2, extra_hp, 0.45, true)

	var pool = get_tree().get_first_node_in_group("damage_numbers")
	var pj = get_tree().get_first_node_in_group("jugador")
	if pool != null and pj != null:
		pool.mostrar_texto(pj.global_position + Vector3(0, 3.0, 0), "💀💀 ¡DUPLA DE JEFES DEL ABISMO! 💀💀", Color(1.0, 0.15, 0.2), 1.6)

func spawn_centurion():
	if _centurion_spawned: return
	_centurion_spawned = true
	_spawn_enemigo(centurion_escena, 0.0, 0.0, true)

func spawn_mini_jefe():
	if _mini_jefe_spawned: return
	_mini_jefe_spawned = true
	_spawn_enemigo(mini_jefe_escena, 0.0, 0.0, true)

func spawn_maestra_sanguinaria():
	if _maestra_spawned: return
	_maestra_spawned = true
	_spawn_enemigo(maestra_escena, 0.0, 0.0, true)

func spawn_coloso_bronce():
	if _coloso_spawned: return
	_coloso_spawned = true
	_spawn_enemigo(coloso_escena, 0.0, 0.0, true)

func spawn_parca_roja():
	if _parca_spawned: return
	_parca_spawned = true
	_spawn_enemigo(parca_roja_escena, 0.0, 0.0, true)

func _generar_oleada(num: int):
	AudioManager.play("alerta_oleada")

	if num > 1:
		var jugador = get_tree().get_first_node_in_group("jugador")
		if jugador != null and jugador.has_method("aplicar_interes_oleada"):
			jugador.aplicar_interes_oleada()

	if num >= 2 and num % 2 == 0: _spawn_enemigo_especial("parasito_cursor")
	if num >= 4 and num % 3 == 0: _spawn_enemigo_especial("canalizador_vacio")
	if num >= 5 and num % 4 == 0: _spawn_enemigo_especial("golem_tesoro")

	var extra_abismo = float(nivel_abismo) * 35.0 if modo_abismo else 0.0

	if num == 1:
		for i in range(6): _spawn_enemigo(espectro_escena, extra_abismo, i * 0.20)
		for i in range(2): _spawn_enemigo(guardia_escena, extra_abismo, 0.45 + i * 0.35)
	elif num == 2:
		for i in range(6): _spawn_enemigo(espectro_escena, extra_abismo, i * 0.18)
		for i in range(3): _spawn_enemigo(guardia_escena, extra_abismo, 0.40 + i * 0.25)
		_spawn_enemigo(arquero_escena, extra_abismo, 0.80)
	elif num == 3:
		for i in range(2): _spawn_enemigo(arquero_escena, extra_abismo, 0.20 + i * 0.20)
		for i in range(2): _spawn_enemigo(kamikaze_escena, extra_abismo, 0.40 + i * 0.20)
		for i in range(3): _spawn_enemigo(guardia_escena, 4.0 + extra_abismo, 0.60 + i * 0.18)
		for i in range(7): _spawn_enemigo(espectro_escena, 2.0 + extra_abismo, 0.80 + i * 0.12)
	elif num == 4:
		for i in range(2): _spawn_enemigo(berserker_escena, 4.0 + extra_abismo, i * 0.20)
		for i in range(3): _spawn_enemigo(arquero_escena, 6.0 + extra_abismo, 0.20 + i * 0.15)
		for i in range(2): _spawn_enemigo(kamikaze_escena, extra_abismo, 0.40 + i * 0.20)
		for i in range(4): _spawn_enemigo(guardia_escena, 8.0 + extra_abismo, 0.60 + i * 0.15)
		for i in range(8): _spawn_enemigo(espectro_escena, 5.0 + extra_abismo, 0.80 + i * 0.10)
	elif num == 5:
		for i in range(2): _spawn_enemigo(bruto_escena, 10.0 + extra_abismo, i * 0.25)
		for i in range(3): _spawn_enemigo(berserker_escena, 8.0 + extra_abismo, 0.20 + i * 0.18)
		for i in range(3): _spawn_enemigo(arquero_escena, 8.0 + extra_abismo, 0.40 + i * 0.18)
		for i in range(2): _spawn_enemigo(kamikaze_escena, extra_abismo, 0.55 + i * 0.20)
		for i in range(8): _spawn_enemigo(espectro_escena, 6.0 + extra_abismo, 0.65 + i * 0.10)
	else:
		var extra = (num - 5) * 6.0 + extra_abismo
		for i in range(2): _spawn_enemigo(bruto_escena, extra * 1.5, i * 0.2)
		for i in range(3): _spawn_enemigo(berserker_escena, extra, 0.2 + i * 0.15)
		for i in range(4): _spawn_enemigo(arquero_escena, extra * 0.8, 0.4 + i * 0.12)
		for i in range(4): _spawn_enemigo(kamikaze_escena, extra * 0.6, 0.5 + i * 0.12)
		for i in range(6): _spawn_enemigo(guardia_escena, extra, 0.65 + i * 0.1)
		for i in range(10): _spawn_enemigo(espectro_escena, extra * 0.4, 0.8 + i * 0.08)

func _spawn_enemigo_especial(tipo: String):
	var enemigos_activos = get_tree().get_nodes_in_group("enemigos").size()
	if enemigos_activos >= max_enemigos_concurrentes:
		return

	var nodo: CharacterBody3D = CharacterBody3D.new()
	match tipo:
		"parasito_cursor": nodo.set_script(ParasitoCursorScript)
		"canalizador_vacio": nodo.set_script(CanalizadorVacioScript)
		"golem_tesoro": nodo.set_script(GolemTesoroScript)
		"heraldo_clic": nodo.set_script(HeraldoClicScript)
		_:
			nodo.queue_free()
			return

	var pos: Vector3 = _obtener_pos_spawn_cerca_jugador(14.0, 26.0)
	get_parent().add_child(nodo)
	nodo.global_position = pos
	_aplicar_escalado_dificultad(nodo, float(nivel_abismo) * 25.0 if modo_abismo else 0.0)

func _obtener_pos_spawn_cerca_jugador(r_min: float, r_max: float) -> Vector3:
	var pj: Node3D = get_tree().get_first_node_in_group("jugador") as Node3D if is_inside_tree() else null
	if pj == null and is_inside_tree():
		pj = get_tree().get_first_node_in_group("player") as Node3D
	if pj != null and is_instance_valid(pj):
		var centro: Vector3 = pj.global_position
		var rng: RandomNumberGenerator = ArenaColiseo._obtener_rng_run(self)
		for _i in range(18):
			var ang: float = rng.randf() * TAU
			var dist: float = rng.randf_range(r_min, r_max)
			var raw := Vector3(centro.x + cos(ang) * dist, 0.0, centro.z + sin(ang) * dist)
			var cand := ArenaColiseo.clamping_y_ajustar_a_suelo(raw, 2.4, 0.0)
			if Vector2(cand.x - centro.x, cand.z - centro.z).length() < 10.0:
				continue
			if ArenaColiseo.esta_en_pendiente(cand.x, cand.z, 0.7):
				continue
			if not ArenaColiseo.punto_libre_de_obstaculos(cand, 2.2):
				continue
			var m_c: float = ArenaColiseo.apotema_en_pos(cand.x, cand.z)
			if m_c >= (ArenaColiseo.APOTEMA_FOSO - 1.1) and m_c <= (ArenaColiseo.APOTEMA_FOSO + 0.9):
				continue
			return cand
	return ArenaColiseo.punto_aleatorio(16.0, ArenaColiseo.APOTEMA_EXTERIOR - 2.4, null, 0.0)

func _spawn_enemigo(escena: PackedScene, vida_extra: float, retraso: float = 0.0, es_jefe: bool = false):
	if escena == null:
		return

	var enemigos_activos = get_tree().get_nodes_in_group("enemigos").size()
	if enemigos_activos >= max_enemigos_concurrentes and not es_jefe:
		return

	if retraso > 0.0:
		await get_tree().create_timer(retraso).timeout
		if not is_inside_tree():
			return
		enemigos_activos = get_tree().get_nodes_in_group("enemigos").size()
		if enemigos_activos >= max_enemigos_concurrentes and not es_jefe:
			return

	var pos: Vector3
	if es_jefe:
		pos = _obtener_pos_spawn_cerca_jugador(14.0, 22.0)
	else:
		pos = _obtener_pos_spawn_cerca_jugador(14.0, 26.0)

	var extra_por_clicks = minf(float(clicks_totales) * 0.85, 160.0)
	var vida_total = vida_extra + (0.0 if es_jefe else extra_por_clicks)

	if es_jefe:
		_despejar_arena_para_jefe()

	if portal_spawn_escena != null:
		var portal = portal_spawn_escena.instantiate()
		get_parent().add_child(portal)
		portal.global_position = pos
		if es_jefe:
			portal.enemigo_spawneado.connect(func(enemigo_creado):
				_registrar_jefe_activo(enemigo_creado)
			)
		portal.preparar_spawn(escena, vida_total, es_jefe)
	else:
		var enemigo = escena.instantiate()
		get_parent().add_child(enemigo)
		enemigo.global_position = pos
		_aplicar_escalado_dificultad(enemigo, vida_total)
		if es_jefe:
			_registrar_jefe_activo(enemigo)

## Calcula el escalado continuo de daño según la oleada alcanzada y los minutos transcurridos
func calcular_multiplicador_dano_incremental() -> float:
	var factor_oleada = 1.0 + float(maxi(0, oleada_actual - 1)) * 0.10
	var factor_tiempo = 1.0 + (_tiempo_transcurrido / 60.0) * 0.10
	return factor_oleada * factor_tiempo

func aplicar_escalado_dificultad(enemigo: Node, vida_extra_base: float = 0.0) -> void:
	_aplicar_escalado_dificultad(enemigo, vida_extra_base)

func _aplicar_escalado_dificultad(enemigo: Node, vida_extra_base: float = 0.0) -> void:
	if enemigo == null or not is_instance_valid(enemigo):
		return
	var mult_hp := 1.0
	var mult_dmg := 1.0 * calcular_multiplicador_dano_incremental()
	var mult_vel := 1.0
	var lm = get_tree().get_first_node_in_group("logros_manager")
	if lm != null and lm.has_method("obtener_multiplicadores_tormento"):
		var m = lm.obtener_multiplicadores_tormento()
		mult_hp = float(m.get("vida_enemigos", 1.0))
		mult_dmg *= float(m.get("dano_enemigos", 1.0))
		mult_vel = float(m.get("velocidad_enemigos", 1.0))
	if modo_abismo:
		mult_dmg *= (1.0 + float(nivel_abismo) * 0.12)
		mult_vel *= minf(1.85, 1.0 + float(nivel_abismo) * 0.04)
	if "vida_maxima" in enemigo:
		enemigo.vida_maxima = (float(enemigo.vida_maxima) + vida_extra_base) * mult_hp
		enemigo.vida = enemigo.vida_maxima
	for prop in ["dano_ataque", "dano_contacto", "dano_disparo", "dano_guadana", "dano_carga", "dano_golpe", "dano_pisada", "dano_a_jugador", "dano_flecha", "dano_lluvia", "dano_sentencia"]:
		if prop in enemigo:
			enemigo.set(prop, float(enemigo.get(prop)) * mult_dmg)
	for vprop in ["rapidez", "rapidez_caminar", "rapidez_huir"]:
		if vprop in enemigo:
			enemigo.set(vprop, float(enemigo.get(vprop)) * mult_vel)

# ==============================================================================
# GESTIÓN DE PROTAGONISMO, DESPEJE Y ESBIRROS DINÁMICOS DE JEFES
# ==============================================================================

func _hay_jefe_activo() -> bool:
	if _jefe_activo != null and is_instance_valid(_jefe_activo) and not ("muerto" in _jefe_activo and _jefe_activo.muerto):
		return true
	for j in get_tree().get_nodes_in_group("jefes"):
		if is_instance_valid(j) and not ("muerto" in j and j.muerto) and ("vida" in j and float(j.vida) > 0.0):
			_jefe_activo = j
			return true
	for b in get_tree().get_nodes_in_group("bosses"):
		if is_instance_valid(b) and not ("muerto" in b and b.muerto) and ("vida" in b and float(b.vida) > 0.0):
			_jefe_activo = b
			return true
	return false

func _despejar_arena_para_jefe() -> void:
	# 1. Cancelar portales de spawn normales pendientes
	for p in get_tree().get_nodes_in_group("portal_spawn"):
		if is_instance_valid(p) and ("es_jefe" in p and not p.es_jefe):
			p.queue_free()
	if get_parent() != null:
		for child in get_parent().get_children():
			if child is PortalSpawn and not child.es_jefe:
				child.queue_free()

	# 2. Desvanecer y retirar inmediatamente todos los enemigos comunes
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if is_instance_valid(e) and not e.is_in_group("jefes") and not e.is_in_group("bosses"):
			_desvanecer_enemigo(e)

	# 3. Alerta audiovisual e impacto cinematográfico
	AudioManager.play("jefe_alerta", 1.2, 3.5)
	AudioManager.play("rugido_jefe", 1.25, 2.5)
	_sacudir_camara(0.45)

	var pool = get_tree().get_first_node_in_group("damage_numbers")
	var pj = get_tree().get_first_node_in_group("jugador")
	if pool != null and pj != null:
		pool.mostrar_texto(pj.global_position + Vector3(0, 3.2, 0), "👑 ¡DESAFÍO DE JEFE! ¡LA ARENA SE DESPEJA! 👑", Color(1.0, 0.85, 0.2), 2.2)

func _desvanecer_enemigo(e: Node) -> void:
	if not is_instance_valid(e):
		return
	if e is CollisionObject3D:
		e.collision_layer = 0
		e.collision_mask = 0
	e.set_physics_process(false)
	e.set_process(false)
	if "muerto" in e:
		e.muerto = true
	if e is Node3D:
		var nodo_vis: Node = e.get_node_or_null("Modelo")
		var objetivo_tw: Node = nodo_vis if nodo_vis != null else e
		var tw = e.create_tween()
		tw.set_parallel(true)
		tw.tween_property(objetivo_tw, "scale", Vector3(0.05, 1.5, 0.05), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(e.queue_free)
	else:
		e.queue_free()

func _sacudir_camara(intensidad: float = 0.35) -> void:
	var cam = get_viewport().get_camera_3d()
	if cam != null and cam.has_method("sacudir"):
		cam.sacudir(intensidad)
	else:
		var c = get_tree().get_first_node_in_group("camara")
		if c != null and c.has_method("sacudir"):
			c.sacudir(intensidad)

func _procesar_esbirros_jefe(delta: float) -> void:
	if _jefe_activo == null or not is_instance_valid(_jefe_activo) or ("muerto" in _jefe_activo and _jefe_activo.muerto):
		_on_jefe_derrotado()
		return

	var hp: float = float(_jefe_activo.vida) if "vida" in _jefe_activo else 100.0
	var max_hp: float = maxf(float(_jefe_activo.vida_maxima) if "vida_maxima" in _jefe_activo else 100.0, 1.0)
	var pct_hp: float = clampf(hp / max_hp, 0.0, 1.0)
	var pct_perdida: float = 1.0 - pct_hp

	# Entre 100% y 80% de vida: Duelo 1-vs-1 absoluto (0 esbirros en arena)
	if pct_perdida < 0.20:
		_reloj_esbirros_jefe = 10.0
		return

	# A partir del 80% de vida, los esbirros reaparecen poco a poco (cada vez más conforme baja la vida)
	var factor_perdida: float = clampf((pct_perdida - 0.20) / 0.80, 0.0, 1.0)
	var techo_esbirros: int = _obtener_techo_esbirros_jefe(_jefe_activo)
	var max_esbirros_actual: int = int(round(lerpf(1.0, float(techo_esbirros), factor_perdida)))
	var intervalo_spawn: float = lerpf(12.0, 4.5, factor_perdida)

	_reloj_esbirros_jefe -= delta
	if _reloj_esbirros_jefe <= 0.0:
		_reloj_esbirros_jefe = intervalo_spawn
		var esbirros_vivos: int = _contar_enemigos_comunes()
		if esbirros_vivos < max_esbirros_actual:
			var cantidad: int = 1
			if factor_perdida >= 0.55 and (max_esbirros_actual - esbirros_vivos) >= 2:
				cantidad = 2
			for i in range(cantidad):
				_spawn_esbirro_tematico(_jefe_activo)

func _obtener_techo_esbirros_jefe(jefe: Node) -> int:
	var j_nombre = jefe.name.to_lower()
	if "centurion" in j_nombre:
		return 4
	elif "mini_jefe" in j_nombre or "gladiador" in j_nombre:
		return 6
	elif "maestra" in j_nombre:
		return 8
	elif "coloso" in j_nombre:
		return 10
	elif "parca" in j_nombre:
		return 12
	return 6

func _contar_enemigos_comunes() -> int:
	var cuenta: int = 0
	for e in get_tree().get_nodes_in_group("enemigos"):
		if is_instance_valid(e) and not e.is_in_group("jefes") and not e.is_in_group("bosses") and not ("muerto" in e and e.muerto):
			cuenta += 1
	return cuenta

func _spawn_esbirro_tematico(jefe: Node) -> void:
	var j_nombre = jefe.name.to_lower()
	var esc: PackedScene = espectro_escena
	if "centurion" in j_nombre:
		esc = [espectro_escena, guardia_escena].pick_random()
	elif "mini_jefe" in j_nombre or "gladiador" in j_nombre:
		esc = [guardia_escena, berserker_escena].pick_random()
	elif "maestra" in j_nombre:
		esc = [arquero_escena, espectro_escena, kamikaze_escena].pick_random()
	elif "coloso" in j_nombre:
		esc = [bruto_escena, berserker_escena, kamikaze_escena].pick_random()
	elif "parca" in j_nombre:
		esc = [bruto_escena, arquero_escena, berserker_escena, kamikaze_escena].pick_random()

	var extra_hp = float(oleada_actual) * 4.0
	_spawn_enemigo(esc, extra_hp, 0.0, false)

func _registrar_jefe_activo(jefe: Node) -> void:
	if jefe == null or not is_instance_valid(jefe):
		return
	_jefe_activo = jefe as Node3D
	_reloj_esbirros_jefe = 12.0
	if not jefe.is_in_group("jefes"):
		jefe.add_to_group("jefes")
	if not jefe.is_in_group("bosses"):
		jefe.add_to_group("bosses")

	var on_derrota = func():
		_on_jefe_derrotado()
	if jefe.has_signal("jefe_derrotado"):
		if not jefe.jefe_derrotado.is_connected(on_derrota):
			jefe.jefe_derrotado.connect(on_derrota)
	if jefe.has_signal("parca_derrotada"):
		if not jefe.parca_derrotada.is_connected(on_derrota):
			jefe.parca_derrotada.connect(on_derrota)
	if not jefe.tree_exited.is_connected(on_derrota):
		jefe.tree_exited.connect(on_derrota)

func _on_jefe_derrotado() -> void:
	if _jefe_activo != null:
		_jefe_activo = null
		_tiempo_ultimo_jefe = _tiempo_transcurrido
		_reloj_oleada = 8.0 # Pausa de celebración antes de reanudar oleadas normales
		print("🏆 [OleadasSpawner] Combate de Jefe finalizado con éxito. Tiempo: %.1fs" % _tiempo_ultimo_jefe)
