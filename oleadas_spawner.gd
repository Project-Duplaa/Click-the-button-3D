extends Node3D

const AudioManager = preload("res://audio_manager.gd")

@export var guardia_escena: PackedScene = preload("res://guardia.tscn")
@export var espectro_escena: PackedScene = preload("res://espectro.tscn")
@export var arquero_escena: PackedScene = preload("res://arquero.tscn")
@export var berserker_escena: PackedScene = preload("res://berserker.tscn")
@export var kamikaze_escena: PackedScene = preload("res://kamikaze.tscn")
@export var bruto_escena: PackedScene = preload("res://bruto.tscn")
@export var mini_jefe_escena: PackedScene = preload("res://mini_jefe.tscn")
@export var parca_roja_escena: PackedScene = preload("res://parca_roja.tscn")

@export var intervalo_oleada: float = 16.0
@export var radio_spawn: float = 26.0
@export var max_enemigos_concurrentes: int = 55

var _reloj_oleada: float = 22.0
var _tiempo_transcurrido: float = 0.0
var oleada_actual: int = 1
var hud: Node = null

var _mini_jefe_spawned: bool = false
var _parca_spawned: bool = false
var clicks_totales: int = 0
var partida_iniciada: bool = false

func _ready():
	hud = get_parent().get_node_or_null("ClickHUD")
	var boton = get_parent().get_node_or_null("BotonMovil")
	if boton != null:
		boton.click_presionado.connect(_on_click_boton_presionado)
	# NO se generan enemigos al iniciar hasta que el jugador pulse el botón móvil
	print("⏳ [OleadasSpawner] Arena en calma. Esperando el primer clic al botón para iniciar la partida.")

func _on_click_boton_presionado(total_clicks: int):
	clicks_totales = total_clicks
	
	# La partida no inicia ni spawnea enemigos hasta que le den al botón
	if not partida_iniciada:
		partida_iniciada = true
		print("⚔️ [OleadasSpawner] ¡PRIMER CLIC AL BOTÓN RECIBIDO! ¡INICIANDO OLEADA 1! ⚔️")
		AudioManager.play("alerta_oleada", 1.25, 2.0)
		_generar_oleada(1)
		return
	
	# 1. Acelerar el reloj de la próxima oleada (cada clic atrae antes a la horda)
	_reloj_oleada = maxf(_reloj_oleada - 0.65, 1.5)
	
	# 2. Despertar anticipado del Mini-Jefe Gladiador a los 25 clics
	if clicks_totales >= 25 and not _mini_jefe_spawned:
		print(">>> [OleadasSpawner] ¡SOBRECARGA DE 25 CLICS! DESPERTANDO MINI-JEFE ANTICIPADO <<<")
		spawn_mini_jefe()
		
	# 3. Despertar de la Parca Roja por sobrecarga masiva a los 70 clics
	if clicks_totales >= 70 and not _parca_spawned:
		print(">>> [OleadasSpawner] ¡MASA CRÍTICA DE CLICS (70)! LA PARCA ROJA HA SIDO INVOCADA <<<")
		spawn_parca_roja()
		
	# 4. Incursión de Asalto Inmediata cada 10 clics (pico táctico de dificultad)
	if clicks_totales % 10 == 0:
		_disparar_incursion_asalto(clicks_totales)
		
	# 5. Enfurecer gradualmente a los enemigos activos en la arena
	if clicks_totales % 4 == 0:
		var enemigos = get_tree().get_nodes_in_group("enemigos")
		for e in enemigos:
			if e != null and is_instance_valid(e) and "rapidez" in e:
				e.rapidez = minf(e.rapidez * 1.02, 7.2)

func _disparar_incursion_asalto(clicks: int):
	AudioManager.play("alerta_oleada", 1.35, 2.0)
	print("🚨 [OleadasSpawner] ¡INCURSIÓN DE ASALTO POR CLICS (%d)! 🚨" % clicks)
	
	var extra_vida = clicks * 1.5
	if clicks <= 10:
		for i in range(2): _spawn_enemigo(espectro_escena, extra_vida)
		_spawn_enemigo(guardia_escena, extra_vida)
	elif clicks <= 20:
		for i in range(2): _spawn_enemigo(berserker_escena, extra_vida)
		for i in range(2): _spawn_enemigo(kamikaze_escena, extra_vida * 0.5)
	elif clicks <= 30:
		_spawn_enemigo(bruto_escena, extra_vida * 1.4)
		for i in range(2): _spawn_enemigo(arquero_escena, extra_vida * 0.8)
		for i in range(3): _spawn_enemigo(espectro_escena, extra_vida)
	else:
		_spawn_enemigo(bruto_escena, extra_vida * 1.6)
		for i in range(2): _spawn_enemigo(berserker_escena, extra_vida)
		for i in range(3): _spawn_enemigo(kamikaze_escena, extra_vida * 0.6)
		for i in range(4): _spawn_enemigo(espectro_escena, extra_vida)

func _process(delta):
	if not partida_iniciada:
		return
		
	_tiempo_transcurrido += delta
	_reloj_oleada -= delta
	
	# Spawn Mini-Jefe al minuto 5 (300 s)
	if _tiempo_transcurrido >= 300.0 and not _mini_jefe_spawned:
		spawn_mini_jefe()
		
	# Spawn Parca Roja al minuto 15 (900 s)
	if _tiempo_transcurrido >= 900.0 and not _parca_spawned:
		spawn_parca_roja()
		
	if _reloj_oleada <= 0.0:
		_reloj_oleada = intervalo_oleada
		oleada_actual += 1
		if hud != null:
			hud.oleada = oleada_actual
		_generar_oleada(oleada_actual)

func spawn_mini_jefe():
	if _mini_jefe_spawned:
		return
	_mini_jefe_spawned = true
	print(">>> [OleadasSpawner] ¡MINI-JEFE GLADIADOR INVOCADO! <<<")
	_spawn_enemigo(mini_jefe_escena, 0.0)

func spawn_parca_roja():
	if _parca_spawned:
		return
	_parca_spawned = true
	print(">>> [OleadasSpawner] ¡LA PARCA ROJA HA SIDO INVOCADA! <<<")
	_spawn_enemigo(parca_roja_escena, 0.0)

func _generar_oleada(num: int):
	print("--- INICIANDO OLEADA ", num, " EN ARENA 60x60 ---")
	AudioManager.play("alerta_oleada")
	
	# Al finalizar la oleada previa y comenzar una nueva (num > 1), otorgar interés si está desbloqueado
	if num > 1:
		var jugador = get_tree().get_first_node_in_group("jugador")
		if jugador != null and jugador.has_method("aplicar_interes_oleada"):
			jugador.aplicar_interes_oleada()
	
	if num == 5 and not _mini_jefe_spawned:
		spawn_mini_jefe()
	elif num >= 15 and not _parca_spawned:
		spawn_parca_roja()
	
	if num == 1:
		# Fase 1: Arranque lento e íntimo (2 espectros) para forzar farmeo con el botón móvil
		for i in range(2):
			_spawn_enemigo(espectro_escena, 0.0)
	elif num == 2:
		# Fase 1b: Primer desafío táctico (3 espectros + 1 guardia)
		for i in range(3):
			_spawn_enemigo(espectro_escena, 0.0)
		_spawn_enemigo(guardia_escena, 0.0)
	elif num == 3:
		# Fase 2: Introducción táctica (Evolución in-world desbloqueada)
		for i in range(1):
			_spawn_enemigo(arquero_escena, 0.0)
		for i in range(1):
			_spawn_enemigo(kamikaze_escena, 0.0)
		for i in range(2):
			_spawn_enemigo(guardia_escena, 2.0)
		for i in range(4):
			_spawn_enemigo(espectro_escena, 0.0)
	elif num == 4:
		# Fase 2b: Entrada del temible Berserker con carga furiosa
		_spawn_enemigo(berserker_escena, 0.0)
		for i in range(3):
			_spawn_enemigo(arquero_escena, 4.0)
		for i in range(2):
			_spawn_enemigo(kamikaze_escena, 0.0)
		for i in range(4):
			_spawn_enemigo(guardia_escena, 6.0)
		for i in range(6):
			_spawn_enemigo(espectro_escena, 4.0)
	elif num == 5:
		# Fase 3: Mini-Jefe Gladiador de Élite + Horda táctica
		_spawn_enemigo(bruto_escena, 0.0)
		for i in range(2):
			_spawn_enemigo(berserker_escena, 5.0)
		for i in range(2):
			_spawn_enemigo(arquero_escena, 5.0)
		for i in range(6):
			_spawn_enemigo(espectro_escena, 5.0)
	elif num <= 9:
		# Fase 4: Hordas masivas mixtas estilo Vampire Survivors
		var extra = (num - 5) * 5.0
		_spawn_enemigo(bruto_escena, extra * 1.5)
		for i in range(2):
			_spawn_enemigo(berserker_escena, extra)
		for i in range(3):
			_spawn_enemigo(arquero_escena, extra * 0.7)
		for i in range(3):
			_spawn_enemigo(kamikaze_escena, extra * 0.5)
		for i in range(5):
			_spawn_enemigo(guardia_escena, extra)
		for i in range(8):
			_spawn_enemigo(espectro_escena, extra * 0.4)
	else:
		# Fase 5: Hordas de asedio pre-Parca Roja
		var extra = (num - 9) * 8.0
		for i in range(2):
			_spawn_enemigo(bruto_escena, extra * 1.8)
		for i in range(3):
			_spawn_enemigo(berserker_escena, extra)
		for i in range(4):
			_spawn_enemigo(arquero_escena, extra * 0.8)
		for i in range(4):
			_spawn_enemigo(kamikaze_escena, extra * 0.6)
		for i in range(6):
			_spawn_enemigo(guardia_escena, extra)
		for i in range(10):
			_spawn_enemigo(espectro_escena, extra * 0.4)

func _spawn_enemigo(escena: PackedScene, vida_extra: float):
	if escena == null:
		return
		
	# Respetar límite estricto de concurrencia para proteger el framerate a 60 fps
	var enemigos_activos = get_tree().get_nodes_in_group("enemigos").size()
	if enemigos_activos >= max_enemigos_concurrentes:
		return
		
	var angulo = randf() * TAU
	var pos = Vector3(cos(angulo) * radio_spawn, 0.0, sin(angulo) * radio_spawn)
	# Mantener dentro de los muros de la arena 60x60
	pos.x = clampf(pos.x, -27.0, 27.0)
	pos.z = clampf(pos.z, -27.0, 27.0)
	
	var enemigo = escena.instantiate()
	get_parent().add_child(enemigo)
	enemigo.global_position = pos
	
	# Escalado incremental de dificultad por clics
	var extra_por_clicks = float(clicks_totales) * 1.25
	if "vida_maxima" in enemigo:
		enemigo.vida_maxima += (vida_extra + extra_por_clicks)
		enemigo.vida = enemigo.vida_maxima
		
	if "dano_ataque" in enemigo:
		enemigo.dano_ataque *= (1.0 + float(clicks_totales) * 0.012) # +1.2% por clic acumulado
		
	if "rapidez" in enemigo:
		var mult_vel = clampf(1.0 + (float(clicks_totales) * 0.005), 1.0, 1.40) # hasta +40% de velocidad
		enemigo.rapidez *= mult_vel
