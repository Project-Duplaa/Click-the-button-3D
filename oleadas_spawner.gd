extends Node3D

## OleadasSpawner — Orquestador de Hordas, Jefes y Enemigos Interactivos con el Cursor
## Elimina el castigo injusto de invocar la Parca Roja a los 70 clics (reemplazado por el Heraldo del Clic
## en Overdrive x5 con botín legendario) e integra los 4 nuevos arquetipos interactivos con el ratón.

const AudioManager = preload("res://audio_manager.gd")
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

@export var intervalo_oleada: float = 16.0
@export var radio_spawn: float = 26.0
@export var max_enemigos_concurrentes: int = 55

var _reloj_oleada: float = 22.0
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

func _ready():
	add_to_group("spawner")
	add_to_group("oleadas_spawner")
	hud = get_parent().get_node_or_null("ClickHUD")
	var boton = get_parent().get_node_or_null("BotonMovil")
	if boton != null:
		boton.click_presionado.connect(_on_click_boton_presionado)
	print("⏳ [OleadasSpawner] Arena en calma. Esperando el primer clic al botón para iniciar la partida.")

func _on_click_boton_presionado(total_clicks: int):
	clicks_totales = total_clicks

	if not partida_iniciada:
		partida_iniciada = true
		print("⚔️ [OleadasSpawner] ¡PRIMER CLIC AL BOTÓN RECIBIDO! ¡INICIANDO OLEADA 1! ⚔️")
		AudioManager.play("alerta_oleada", 1.25, 2.0)
		_generar_oleada(1)
		return

	# 1. Acelerar el reloj de la próxima oleada de forma controlada
	_reloj_oleada = maxf(_reloj_oleada - 0.55, 2.0)

	# 2. A los 35 clics: invocar un Gólem de Tesoro como premio de riesgo/recompensa
	if clicks_totales == 35 or (clicks_totales > 35 and clicks_totales % 45 == 0):
		_spawn_enemigo_especial("golem_tesoro")

	# 3. Cada 50 clics: invocar al Heraldo del Clic (Élite de Fiebre con botín masivo, NO la Parca Roja)
	if clicks_totales >= 50 and clicks_totales % 50 == 0:
		invocar_heraldo_clic()

	# 4. Incursión de Asalto Inmediata cada 12 clics
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

func _process(delta):
	if not partida_iniciada:
		return

	_tiempo_transcurrido += delta
	_reloj_oleada -= delta

	# Progresión cronológica de Jefes (Cada 3 minutos / 180s)
	if _tiempo_transcurrido >= 180.0 and not _centurion_spawned:
		spawn_centurion()
	if _tiempo_transcurrido >= 360.0 and not _mini_jefe_spawned:
		spawn_mini_jefe()
	if _tiempo_transcurrido >= 540.0 and not _maestra_spawned:
		spawn_maestra_sanguinaria()
	if _tiempo_transcurrido >= 720.0 and not _coloso_spawned:
		spawn_coloso_bronce()
	if _tiempo_transcurrido >= 900.0 and not _parca_spawned:
		spawn_parca_roja()

	if _reloj_oleada <= 0.0:
		_reloj_oleada = intervalo_oleada
		oleada_actual += 1
		if hud != null:
			hud.oleada = oleada_actual
		_generar_oleada(oleada_actual)

func spawn_centurion():
	if _centurion_spawned:
		return
	_centurion_spawned = true
	print(">>> [OleadasSpawner] ¡JEFE 1: CENTURIÓN CORRUPTO INVOCADO (W3)! <<<")
	_spawn_enemigo(centurion_escena, 0.0, 0.0, true)

func spawn_mini_jefe():
	if _mini_jefe_spawned:
		return
	_mini_jefe_spawned = true
	print(">>> [OleadasSpawner] ¡JEFE 2: GLADIADOR DE ÉLITE INVOCADO (W6)! <<<")
	_spawn_enemigo(mini_jefe_escena, 0.0, 0.0, true)

func spawn_maestra_sanguinaria():
	if _maestra_spawned:
		return
	_maestra_spawned = true
	print(">>> [OleadasSpawner] ¡JEFE 3: MAESTRA SANGUINARIA INVOCADA (W9)! <<<")
	_spawn_enemigo(maestra_escena, 0.0, 0.0, true)

func spawn_coloso_bronce():
	if _coloso_spawned:
		return
	_coloso_spawned = true
	print(">>> [OleadasSpawner] ¡JEFE 4: COLOSO DE BRONCE INVOCADO (W12)! <<<")
	_spawn_enemigo(coloso_escena, 0.0, 0.0, true)

func spawn_parca_roja():
	if _parca_spawned:
		return
	_parca_spawned = true
	print(">>> [OleadasSpawner] ¡JEFE FINAL: LA PARCA ROJA HA SIDO INVOCADA (W15)! <<<")
	_spawn_enemigo(parca_roja_escena, 0.0, 0.0, true)

func _generar_oleada(num: int):
	print("--- INICIANDO OLEADA ", num, " EN ARENA 60x60 ---")
	AudioManager.play("alerta_oleada")

	if num > 1:
		var jugador = get_tree().get_first_node_in_group("jugador")
		if jugador != null and jugador.has_method("aplicar_interes_oleada"):
			jugador.aplicar_interes_oleada()

	# Generación de Jefes por número de oleada
	if num == 3 and not _centurion_spawned:
		spawn_centurion()
	elif num == 6 and not _mini_jefe_spawned:
		spawn_mini_jefe()
	elif num == 9 and not _maestra_spawned:
		spawn_maestra_sanguinaria()
	elif num == 12 and not _coloso_spawned:
		spawn_coloso_bronce()
	elif num >= 15 and not _parca_spawned:
		spawn_parca_roja()

	# Enemigos interactivos con el cursor a partir de la oleada 2
	if num >= 2 and num % 2 == 0:
		_spawn_enemigo_especial("parasito_cursor")
	if num >= 4 and num % 3 == 0:
		_spawn_enemigo_especial("canalizador_vacio")
	if num >= 5 and num % 4 == 0:
		_spawn_enemigo_especial("golem_tesoro")

	if num == 1:
		for i in range(2):
			_spawn_enemigo(espectro_escena, 0.0, i * 0.25)
	elif num == 2:
		for i in range(3):
			_spawn_enemigo(espectro_escena, 0.0, i * 0.2)
		_spawn_enemigo(guardia_escena, 0.0, 0.6)
	elif num == 3:
		_spawn_enemigo(arquero_escena, 0.0, 0.2)
		_spawn_enemigo(kamikaze_escena, 0.0, 0.4)
		for i in range(2):
			_spawn_enemigo(guardia_escena, 2.0, 0.6)
		for i in range(4):
			_spawn_enemigo(espectro_escena, 0.0, 0.8)
	elif num == 4:
		_spawn_enemigo(berserker_escena, 0.0, 0.0)
		for i in range(3):
			_spawn_enemigo(arquero_escena, 4.0, 0.2 + i * 0.15)
		for i in range(2):
			_spawn_enemigo(kamikaze_escena, 0.0, 0.4 + i * 0.2)
		for i in range(4):
			_spawn_enemigo(guardia_escena, 6.0, 0.6 + i * 0.15)
		for i in range(6):
			_spawn_enemigo(espectro_escena, 4.0, 0.8 + i * 0.12)
	elif num == 5:
		_spawn_enemigo(bruto_escena, 0.0, 0.0)
		for i in range(2):
			_spawn_enemigo(berserker_escena, 5.0, 0.2 + i * 0.2)
		for i in range(2):
			_spawn_enemigo(arquero_escena, 5.0, 0.4 + i * 0.2)
		for i in range(6):
			_spawn_enemigo(espectro_escena, 5.0, 0.6 + i * 0.12)
	elif num <= 9:
		var extra = (num - 5) * 5.0
		_spawn_enemigo(bruto_escena, extra * 1.5, 0.0)
		for i in range(2):
			_spawn_enemigo(berserker_escena, extra, 0.15 + i * 0.15)
		for i in range(3):
			_spawn_enemigo(arquero_escena, extra * 0.7, 0.3 + i * 0.15)
		for i in range(3):
			_spawn_enemigo(kamikaze_escena, extra * 0.5, 0.45 + i * 0.15)
		for i in range(5):
			_spawn_enemigo(guardia_escena, extra, 0.6 + i * 0.12)
		for i in range(8):
			_spawn_enemigo(espectro_escena, extra * 0.4, 0.8 + i * 0.1)
	else:
		var extra = (num - 9) * 8.0
		for i in range(2):
			_spawn_enemigo(bruto_escena, extra * 1.8, i * 0.2)
		for i in range(3):
			_spawn_enemigo(berserker_escena, extra, 0.2 + i * 0.15)
		for i in range(4):
			_spawn_enemigo(arquero_escena, extra * 0.8, 0.4 + i * 0.12)
		for i in range(4):
			_spawn_enemigo(kamikaze_escena, extra * 0.6, 0.5 + i * 0.12)
		for i in range(6):
			_spawn_enemigo(guardia_escena, extra, 0.65 + i * 0.1)
		for i in range(10):
			_spawn_enemigo(espectro_escena, extra * 0.4, 0.8 + i * 0.08)

func _spawn_enemigo_especial(tipo: String):
	var enemigos_activos = get_tree().get_nodes_in_group("enemigos").size()
	if enemigos_activos >= max_enemigos_concurrentes:
		return

	var nodo: CharacterBody3D = CharacterBody3D.new()
	match tipo:
		"parasito_cursor":
			nodo.set_script(ParasitoCursorScript)
		"canalizador_vacio":
			nodo.set_script(CanalizadorVacioScript)
		"golem_tesoro":
			nodo.set_script(GolemTesoroScript)
		"heraldo_clic":
			nodo.set_script(HeraldoClicScript)
		_:
			nodo.queue_free()
			return

	var angulo = randf() * TAU
	var pos = Vector3(cos(angulo) * (radio_spawn * 0.78), 0.0, sin(angulo) * (radio_spawn * 0.78))
	pos.x = clampf(pos.x, -24.0, 24.0)
	pos.z = clampf(pos.z, -24.0, 24.0)
	get_parent().add_child(nodo)
	nodo.global_position = pos

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

	var angulo = randf() * TAU
	var pos = Vector3(cos(angulo) * radio_spawn, 0.0, sin(angulo) * radio_spawn)
	pos.x = clampf(pos.x, -26.0, 26.0)
	pos.z = clampf(pos.z, -26.0, 26.0)

	var extra_por_clicks = minf(float(clicks_totales) * 0.85, 160.0)
	var vida_total = vida_extra + extra_por_clicks
	if portal_spawn_escena != null:
		var portal = portal_spawn_escena.instantiate()
		get_parent().add_child(portal)
		portal.global_position = pos
		portal.preparar_spawn(escena, vida_total, es_jefe)
	else:
		var enemigo = escena.instantiate()
		get_parent().add_child(enemigo)
		enemigo.global_position = pos
		if "vida_maxima" in enemigo:
			enemigo.vida_maxima += vida_total
			enemigo.vida = enemigo.vida_maxima
