extends Node

# AudioManager Desacoplado - Clicklike 3D
# Identidad Sonora: Arcade Moderna (Vampire Survivors x Super Bonk x Click the Button)
# Síntesis procedural 16-bit / 44.1 kHz estéreo con variaciones aleatorias,
# control de saturación por prioridades, límite de polifonía y limitador maestro.

class_name AudioManager

const AudioDSP = preload("res://audio_dsp.gd")
const MusicManagerScript = preload("res://music_manager.gd")

static var instance: AudioManager = null
static var _cache_sonidos: Dictionary = {}
static var _cache_variantes: Dictionary = {}

var _sonidos: Dictionary = {} # Compatibilidad directa (variante principal por clave)
var _variantes: Dictionary = {} # String -> Array[AudioStreamWAV]
var _ultimo_indice_variante: Dictionary = {}

var _players: Array[AudioStreamPlayer] = []
var _player_meta: Array[Dictionary] = [] # { "sonido": String, "prioridad": int, "inicio_ms": int }
var _max_players: int = 22
var _ultimos_tiempos_ms: Dictionary = {}

# Cooldowns mínimos (ms) para evitar apilamiento en fase y saturación en hordas
const COOLDOWNS_MS := {
	"click": 24,
	"golpe_impacto": 38,
	"impacto_flecha": 40,
	"enemigo_muerte": 42,
	"corte_espada": 40,
	"corte_giratorio": 65,
	"orbe_explosion": 48,
	"orbe_lanzar": 40,
	"escudo_bloqueo": 50,
	"disparo_arco": 42,
	"disparo_arquero": 55,
	"danio_jugador": 75,
	"altar_activado": 45,
	"portal_emergencia": 60,
	"portal_spawn": 90,
	"alerta_oleada": 130,
	"jefe_alerta": 180,
	"rugido_jefe": 180,
}

# Prioridades para asegurar que las acciones del jugador y recompensas siempre destaquen
const PRIORIDADES := {
	"victoria": 100,
	"derrota": 100,
	"jackpot": 95,
	"legendario": 95,
	"puzzle_completo": 92,
	"jefe_alerta": 90,
	"rugido_jefe": 88,
	"danio_jugador": 88,
	"click": 85,
	"altar_activado": 82,
	"escudo_bloqueo": 72,
	"corte_giratorio": 68,
	"corte_espada": 65,
	"disparo_arco": 64,
	"orbe_lanzar": 62,
	"golpe_impacto": 58,
	"orbe_explosion": 55,
	"alerta_oleada": 45,
	"enemigo_muerte": 32,
	"impacto_flecha": 28,
	"disparo_arquero": 26,
	"portal_spawn": 24,
	"portal_emergencia": 22,
}

# Máximo de voces simultáneas por efecto (evita caos en formato bullet-heaven)
const MAX_VOCES_POR_SONIDO := {
	"enemigo_muerte": 2,
	"golpe_impacto": 2,
	"impacto_flecha": 2,
	"disparo_arquero": 2,
	"orbe_explosion": 2,
	"orbe_lanzar": 3,
	"corte_espada": 2,
	"disparo_arco": 2,
	"portal_emergencia": 2,
	"portal_spawn": 2,
	"alerta_oleada": 1,
	"click": 4,
}

# Balance relativo para priorizar feedback del jugador sobre la multitud enemiga
const TRIM_POR_SONIDO_DB := {
	"disparo_arquero": -2.8,
	"impacto_flecha": -2.2,
	"enemigo_muerte": -1.6,
	"portal_emergencia": -2.4,
	"portal_spawn": -1.8,
	"orbe_explosion": -0.8,
	"alerta_oleada": -1.0,
}

# Variación de tono aleatoria sutil en sonidos no melódicos para evitar fatiga
const JITTER_PITCH := {
	"golpe_impacto": 0.045,
	"corte_espada": 0.04,
	"corte_giratorio": 0.03,
	"disparo_arco": 0.035,
	"disparo_arquero": 0.045,
	"impacto_flecha": 0.05,
	"enemigo_muerte": 0.055,
	"orbe_lanzar": 0.035,
	"orbe_explosion": 0.04,
	"escudo_bloqueo": 0.03,
	"danio_jugador": 0.03,
	"portal_emergencia": 0.045,
	"portal_spawn": 0.03,
}

const HEADROOM_GLOBAL_DB: float = -3.8


func _enter_tree():
	instance = self


func _ready():
	add_to_group("audio_manager")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configurar_limitador_master()

	for i in range(_max_players):
		var p = AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_players.append(p)
		_player_meta.append({ "sonido": "", "prioridad": 0, "inicio_ms": 0 })

	if not _cache_variantes.is_empty():
		_variantes = _cache_variantes
		_sonidos = _cache_sonidos
	else:
		_generar_biblioteca_sonidos()
		_cache_variantes = _variantes
		_cache_sonidos = _sonidos

	if get_node_or_null("MusicManager") == null:
		var mm := MusicManagerScript.new()
		mm.name = "MusicManager"
		add_child(mm)


func _configurar_limitador_master() -> void:
	var bus_idx := AudioServer.get_bus_index(&"Master")
	if bus_idx < 0:
		return
	var ya_tiene_limitador := false
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		if AudioServer.get_bus_effect(bus_idx, i) is AudioEffectLimiter:
			ya_tiene_limitador = true
			break
	if not ya_tiene_limitador:
		var limiter := AudioEffectLimiter.new()
		limiter.ceiling_db = -1.5
		limiter.threshold_db = -4.0
		limiter.soft_clip_db = 2.0
		limiter.soft_clip_ratio = 10.0
		AudioServer.add_bus_effect(bus_idx, limiter)


func _registrar_variantes(nombre: String, lista: Array[AudioStreamWAV]) -> void:
	_variantes[nombre] = lista
	if not lista.is_empty():
		_sonidos[nombre] = lista[0]


func _generar_biblioteca_sonidos():
	# 1. Pulsación inmediata estilo Click the Button + Arcade
	var clicks: Array[AudioStreamWAV] = []
	for v in range(4):
		clicks.append(_sintetizar_click(v))
	_registrar_variantes("click", clicks)

	# 2. Combate del jugador y proyectiles
	var cortes: Array[AudioStreamWAV] = []
	var giros: Array[AudioStreamWAV] = []
	var golpes: Array[AudioStreamWAV] = []
	var arcos: Array[AudioStreamWAV] = []
	var arqueros: Array[AudioStreamWAV] = []
	var flechas: Array[AudioStreamWAV] = []
	var orbes_in: Array[AudioStreamWAV] = []
	var orbes_ex: Array[AudioStreamWAV] = []
	var escudos: Array[AudioStreamWAV] = []
	var muertes: Array[AudioStreamWAV] = []
	for v in range(3):
		cortes.append(_sintetizar_corte_espada(v))
		giros.append(_sintetizar_corte_giratorio(v))
		golpes.append(_sintetizar_golpe_impacto(v))
		arcos.append(_sintetizar_disparo_arco(v))
		arqueros.append(_sintetizar_disparo_arquero(v))
		flechas.append(_sintetizar_impacto_flecha(v))
		orbes_in.append(_sintetizar_orbe_lanzar(v))
		orbes_ex.append(_sintetizar_orbe_explosion(v))
		escudos.append(_sintetizar_escudo_bloqueo(v))
		muertes.append(_sintetizar_pop_muerte(v))

	_registrar_variantes("corte_espada", cortes)
	_registrar_variantes("corte_giratorio", giros)
	_registrar_variantes("golpe_impacto", golpes)
	_registrar_variantes("disparo_arco", arcos)
	_registrar_variantes("disparo_arquero", arqueros)
	_registrar_variantes("impacto_flecha", flechas)
	_registrar_variantes("orbe_lanzar", orbes_in)
	_registrar_variantes("orbe_explosion", orbes_ex)
	_registrar_variantes("escudo_bloqueo", escudos)
	_registrar_variantes("enemigo_muerte", muertes)

	# 3. Variantes duales (daño, nivel/altar, portales)
	_registrar_variantes("danio_jugador", [_sintetizar_golpe_dano(0), _sintetizar_golpe_dano(1)])
	_registrar_variantes("altar_activado", [_sintetizar_campana_celestial(0), _sintetizar_campana_celestial(1)])
	_registrar_variantes("portal_spawn", [_sintetizar_portal_spawn(0), _sintetizar_portal_spawn(1)])
	_registrar_variantes("portal_emergencia", [_sintetizar_portal_emergencia(0), _sintetizar_portal_emergencia(1)])

	# 4. Eventos insignia únicos (recompensas, alertas, jefes, fin de partida)
	_registrar_variantes("puzzle_completo", [_sintetizar_fanfarria_puzzle()])
	_registrar_variantes("jackpot", [_sintetizar_jackpot()])
	_registrar_variantes("legendario", [_sintetizar_legendario()])
	_registrar_variantes("alerta_oleada", [_sintetizar_cuerno_oleada()])
	_registrar_variantes("jefe_alerta", [_sintetizar_jefe_alerta()])
	_registrar_variantes("rugido_jefe", [_sintetizar_rugido_jefe()])
	_registrar_variantes("victoria", [_sintetizar_fanfarria_victoria()])
	_registrar_variantes("derrota", [_sintetizar_descenso_derrota()])


func _elegir_variante(nombre: String) -> AudioStreamWAV:
	var lista: Array = _variantes.get(nombre, [])
	if lista.is_empty():
		return _sonidos.get(nombre, null)
	if lista.size() == 1:
		return lista[0]
	var ultimo: int = _ultimo_indice_variante.get(nombre, -1)
	var idx := randi() % lista.size()
	if idx == ultimo:
		idx = (idx + 1 + (randi() % (lista.size() - 1))) % lista.size()
	_ultimo_indice_variante[nombre] = idx
	return lista[idx]


func _contar_voces_activas(nombre_sonido: String) -> Dictionary:
	var total := 0
	var del_mismo := 0
	for i in range(_max_players):
		if _players[i].playing:
			total += 1
			if _player_meta[i]["sonido"] == nombre_sonido:
				del_mismo += 1
	return { "total": total, "mismo": del_mismo }


func _asignar_slot_por_prioridad(prioridad: int) -> int:
	# 1. Buscar un reproductor completamente libre
	for i in range(_max_players):
		if not _players[i].playing:
			return i

	# 2. Si todos están ocupados, robar el de menor prioridad (y más antiguo en empate)
	var mejor_idx := -1
	var menor_prio := prioridad + 1
	var mas_viejo := 999999999
	for i in range(_max_players):
		var meta: Dictionary = _player_meta[i]
		var p_i: int = meta["prioridad"]
		var t_i: int = meta["inicio_ms"]
		if p_i < menor_prio or (p_i == menor_prio and t_i < mas_viejo):
			menor_prio = p_i
			mas_viejo = t_i
			mejor_idx = i

	# Nunca robar una voz más importante que la entrante
	if mejor_idx >= 0 and int(_player_meta[mejor_idx]["prioridad"]) <= prioridad:
		return mejor_idx
	return -1


func reproducir(nombre_sonido: String, tono: float = 1.0, volumen_db: float = 0.0):
	if not _variantes.has(nombre_sonido) or not is_inside_tree():
		return

	var ahora_ms := Time.get_ticks_msec()
	var cd_ms: int = COOLDOWNS_MS.get(nombre_sonido, 0)
	if cd_ms > 0:
		var ultimo: int = _ultimos_tiempos_ms.get(nombre_sonido, -999999)
		if (ahora_ms - ultimo) < cd_ms:
			return

	var prio: int = PRIORIDADES.get(nombre_sonido, 50)
	var conteo := _contar_voces_activas(nombre_sonido)
	var max_mismo: int = MAX_VOCES_POR_SONIDO.get(nombre_sonido, 4)
	if conteo["mismo"] >= max_mismo:
		return

	var slot := _asignar_slot_por_prioridad(prio)
	if slot < 0:
		return

	_ultimos_tiempos_ms[nombre_sonido] = ahora_ms

	var stream := _elegir_variante(nombre_sonido)
	if stream == null:
		return

	var jitter: float = JITTER_PITCH.get(nombre_sonido, 0.0)
	var tono_final := tono * (1.0 + randf_range(-jitter, jitter) if jitter > 0.0 else 1.0)

	# Atenuación dinámica en multitudes (bullet-heaven): evita bola de ruido
	var extras: int = maxi(0, int(conteo["total"]) - 3)
	var duck_multitud := 0.0
	if prio >= 80:
		duck_multitud = -minf(float(extras) * 0.35, 2.0)
	else:
		duck_multitud = -minf(float(extras) * 1.1, 6.0)

	var trim_cat: float = TRIM_POR_SONIDO_DB.get(nombre_sonido, 0.0)
	var vol_final := clampf(volumen_db, -24.0, 1.5) + HEADROOM_GLOBAL_DB + trim_cat + duck_multitud

	var p := _players[slot]
	p.stream = stream
	p.pitch_scale = clampf(tono_final, 0.45, 2.3)
	p.volume_db = clampf(vol_final, -36.0, -0.5)
	_player_meta[slot] = { "sonido": nombre_sonido, "prioridad": prio, "inicio_ms": ahora_ms }
	p.play()

	if MusicManagerScript.instance != null:
		if nombre_sonido in ["victoria", "derrota"]:
			MusicManagerScript.instance.duck_fanfarria(1.8)
		elif nombre_sonido in ["legendario", "jackpot", "puzzle_completo"]:
			MusicManagerScript.instance.duck_fanfarria(0.95)


static func play(sonido: String, tono: float = 1.0, volumen_db: float = 0.0):
	if instance != null:
		instance.reproducir(sonido, tono, volumen_db)


# ==============================================================================
# IDENTIDAD SONORA ARCADE MODERNA (Vampire Survivors x Super Bonk x Clicker)
# Escala unificada: Do Mayor / Mi Pentatónica / Re Lidio (armónica en simultáneo)
# ==============================================================================

func _sintetizar_click(variante: int) -> AudioStreamWAV:
	# Pulsación adictiva tipo Click the Button + rebote plástico arcade (nunca molesta)
	var buf := AudioDSP.crear_buffer(0.068)
	var anchos := [0.24, 0.32, 0.40, 0.48]
	var f_bases := [329.63, 349.23, 329.63, 370.00]
	var pw: float = anchos[variante % anchos.size()]
	var fb: float = f_bases[variante % f_bases.size()]

	# Pop elástico central + toque digital suave
	AudioDSP.agregar_rebote_cartoon(buf, 0.0, 0.056, fb * 1.45, fb * 1.72, fb * 0.92, 0.22, 0.62, 0.18, 0.0)
	AudioDSP.agregar_synth_arcade(buf, 0.0, 0.042, 0, fb * 2.0, fb * 1.5, 0.008, 2200.0, 750.0, 0.9, 0.24, 0.001, 0.012, pw, 0.0)
	AudioDSP.agregar_fm_arcade(buf, 0.004, 0.036, fb * 2.0, fb * 2.5, 0.015, 2.0, 0.7, 0.012, 0.14, 0.001, 0.010, 0.08)
	return AudioDSP.masterizar_wav_16bit(buf, 0.44)


func _sintetizar_corte_espada(variante: int) -> AudioStreamWAV:
	# Tajo arcade energético: barrido de láser/hoja limpia + aire cortante sin estática
	var buf := AudioDSP.crear_buffer(0.165)
	var freqs := [780.0, 860.0, 720.0]
	var pans := [-0.15, 0.15, -0.05]
	var f0: float = freqs[variante % 3]
	var pan: float = pans[variante % 3]

	AudioDSP.agregar_ruido_filtrado(buf, 0.0, 0.145, "bandpass", 650.0, 2600.0, 1.7, 0.66, 0.22, pan, 0.0, 801 + variante * 17)
	AudioDSP.agregar_synth_arcade(buf, 0.0, 0.095, 1, f0, f0 * 0.36, 0.025, 2600.0, 620.0, 1.1, 0.34, 0.002, 0.026, 0.5, -pan * 0.5)
	AudioDSP.agregar_fm_arcade(buf, 0.008, 0.075, f0 * 1.5, f0 * 0.9, 0.025, 1.5, 1.2, 0.02, 0.16, 0.002, 0.020, pan)
	AudioDSP.aplicar_reverb_estereo(buf, 0.12, 0.18)
	return AudioDSP.masterizar_wav_16bit(buf, 0.48)


func _sintetizar_corte_giratorio(variante: int) -> AudioStreamWAV:
	# Torbellino arcade 360° con rotación estéreo y turbina energética
	var buf := AudioDSP.crear_buffer(0.37)
	var f_mod := 230.0 + float(variante) * 28.0
	AudioDSP.agregar_ruido_filtrado(buf, 0.0, 0.34, "bandpass", 420.0, 2100.0, 1.6, 0.62, 0.24, 0.0, 7.5, 901 + variante * 13)
	AudioDSP.agregar_ruido_filtrado(buf, 0.07, 0.27, "bandpass", 1700.0, 440.0, 1.6, 0.40, 0.36, 0.0, 7.5, 921 + variante * 13)
	AudioDSP.agregar_synth_arcade(buf, 0.0, 0.31, 0, f_mod, f_mod * 1.65, 0.11, 1400.0, 2200.0, 1.3, 0.30, 0.012, 0.12, 0.32, 0.0, 9.0, 0.04)
	AudioDSP.agregar_percusion_arcade(buf, 0.0, true, 0.32, 0.0, 940 + variante)
	AudioDSP.aplicar_reverb_estereo(buf, 0.18, 0.24)
	return AudioDSP.masterizar_wav_16bit(buf, 0.50)


func _sintetizar_golpe_impacto(variante: int) -> AudioStreamWAV:
	# Impacto estilo Super Bonk: pegada grave + "BONK!" elástico caricaturesco pero contundente
	var buf := AudioDSP.crear_buffer(0.155)
	var f_bonk := 260.0 + float(variante) * 32.0
	var pan := -0.10 if variante == 0 else (0.10 if variante == 1 else 0.0)

	AudioDSP.agregar_percusion_arcade(buf, 0.0, true, 0.72, pan, 1300 + variante)
	AudioDSP.agregar_rebote_cartoon(buf, 0.0, 0.10, f_bonk * 0.75, f_bonk * 1.55, f_bonk * 0.45, 0.28, 0.48, 0.22, -pan * 0.5)
	AudioDSP.agregar_ruido_filtrado(buf, 0.0, 0.06, "bandpass", 1450.0, 380.0, 1.3, 0.34, 0.12, pan, 0.0, 1320 + variante * 19)
	return AudioDSP.masterizar_wav_16bit(buf, 0.50)


func _sintetizar_disparo_arco(variante: int) -> AudioStreamWAV:
	# Arco arcade ágil: cuerda elástica sintetizada + silbido limpio neón
	var buf := AudioDSP.crear_buffer(0.19)
	var f_cuerda := 196.0 + float(variante) * 14.0
	AudioDSP.agregar_rebote_cartoon(buf, 0.0, 0.11, f_cuerda * 1.85, f_cuerda * 0.92, f_cuerda * 1.25, 0.35, 0.56, 0.28, -0.08)
	AudioDSP.agregar_synth_arcade(buf, 0.0, 0.12, 0, f_cuerda * 2.0, f_cuerda, 0.025, 2200.0, 680.0, 1.1, 0.26, 0.002, 0.036, 0.28, 0.08)
	AudioDSP.agregar_ruido_filtrado(buf, 0.006, 0.13, "bandpass", 1800.0, 720.0, 1.9, 0.28, 0.18, 0.12, 0.0, 1001 + variante * 11)
	return AudioDSP.masterizar_wav_16bit(buf, 0.46)


func _sintetizar_disparo_arquero(variante: int) -> AudioStreamWAV:
	# Disparo enemigo retro-synth bien diferenciado del jugador (pulso estrecho corto)
	var buf := AudioDSP.crear_buffer(0.175)
	var f0 := 520.0 + float(variante) * 45.0
	AudioDSP.agregar_synth_arcade(buf, 0.0, 0.14, 0, f0, f0 * 0.38, 0.028, 1900.0, 520.0, 1.2, 0.52, 0.002, 0.038, 0.20, 0.08)
	AudioDSP.agregar_ruido_filtrado(buf, 0.0, 0.08, "bandpass", 1350.0, 520.0, 1.8, 0.22, 0.18, -0.08, 0.0, 1101 + variante * 11)
	return AudioDSP.masterizar_wav_16bit(buf, 0.44)


func _sintetizar_impacto_flecha(variante: int) -> AudioStreamWAV:
	# "Pock!" seco y ágil de proyectil arcade
	var buf := AudioDSP.crear_buffer(0.12)
	var f0 := 380.0 + float(variante) * 35.0
	AudioDSP.agregar_tono_modal(buf, 0.0, 0.075, f0, f0 * 0.36, 0.014, 0.62, 0.001, 0.020, 0.0)
	AudioDSP.agregar_fm_arcade(buf, 0.0, 0.055, f0 * 1.4, f0 * 0.8, 0.015, 1.5, 1.1, 0.015, 0.26, 0.001, 0.015, 0.08)
	AudioDSP.agregar_ruido_filtrado(buf, 0.0, 0.045, "bandpass", 1450.0, 550.0, 1.4, 0.22, 0.14, -0.06, 0.0, 1201 + variante * 11)
	return AudioDSP.masterizar_wav_16bit(buf, 0.44)


func _sintetizar_orbe_lanzar(variante: int) -> AudioStreamWAV:
	# Lanzamiento mágico estilo Vampire Survivors (chime cristalino + aire sintetizado)
	var buf := AudioDSP.crear_buffer(0.24)
	var notas := [523.25, 587.33, 659.25]
	var f_base: float = notas[variante % 3]
	AudioDSP.agregar_fm_arcade(buf, 0.0, 0.20, f_base * 0.75, f_base * 1.25, 0.06, 2.0, 1.6, 0.07, 0.45, 0.004, 0.075, -0.1)
	AudioDSP.agregar_synth_arcade(buf, 0.01, 0.19, 1, f_base, f_base * 1.5, 0.08, 700.0, 2600.0, 1.5, 0.24, 0.008, 0.065, 0.5, 0.12)
	AudioDSP.agregar_ruido_filtrado(buf, 0.0, 0.18, "bandpass", 550.0, 1900.0, 1.8, 0.26, 0.25, 0.0, 0.0, 201 + variante * 13)
	AudioDSP.aplicar_reverb_estereo(buf, 0.22, 0.28)
	return AudioDSP.masterizar_wav_16bit(buf, 0.46)


func _sintetizar_orbe_explosion(variante: int) -> AudioStreamWAV:
	# Detonación mágica arcade: pegada sub + explosión filtrada + destello de cristal
	var buf := AudioDSP.crear_buffer(0.38)
	var f_spark := 783.99 if variante == 0 else (880.0 if variante == 1 else 659.25)
	AudioDSP.agregar_percusion_arcade(buf, 0.0, true, 0.80, 0.0, 301 + variante * 19)
	AudioDSP.agregar_ruido_filtrado(buf, 0.0, 0.30, "lowpass", 1850.0, 150.0, 0.9, 0.62, 0.09, 0.0, 0.0, 311 + variante * 19)
	AudioDSP.agregar_nota_campana(buf, 0.0, 0.26, f_spark, 0.18, 0.42, 0.08, -0.22)
	AudioDSP.agregar_nota_campana(buf, 0.028, 0.26, f_spark * 1.5, 0.14, 0.35, 0.08, 0.22)
	AudioDSP.aplicar_reverb_estereo(buf, 0.20, 0.26)
	return AudioDSP.masterizar_wav_16bit(buf, 0.52)


func _sintetizar_pop_muerte(variante: int) -> AudioStreamWAV:
	# "Bloop-pop" estilo Super Bonk + micro-cristal de XP (cero fatiga al matar hordas)
	var buf := AudioDSP.crear_buffer(0.185)
	var f_pop := 293.66 if variante == 0 else (329.63 if variante == 1 else 261.63)
	AudioDSP.agregar_rebote_cartoon(buf, 0.0, 0.11, f_pop * 1.25, f_pop * 0.52, f_pop * 1.65, 0.42, 0.56, 0.15, -0.06)
	AudioDSP.agregar_ruido_filtrado(buf, 0.015, 0.11, "bandpass", 700.0, 1750.0, 1.5, 0.22, 0.22, 0.10, 0.0, 701 + variante * 17)
	AudioDSP.agregar_nota_campana(buf, 0.025, 0.14, f_pop * 2.0, 0.15, 0.25, 0.05, 0.12)
	return AudioDSP.masterizar_wav_16bit(buf, 0.43)


func _sintetizar_golpe_dano(variante: int) -> AudioStreamWAV:
	# Alerta inmediata de daño: "BONK-ZAP" caricaturesco + impacto sordo claro
	var buf := AudioDSP.crear_buffer(0.24)
	var f0 := 240.0 if variante == 0 else 215.0
	AudioDSP.agregar_percusion_arcade(buf, 0.0, true, 0.72, 0.0, 601 + variante)
	AudioDSP.agregar_synth_arcade(buf, 0.0, 0.20, 1, f0, f0 * 0.44, 0.065, 1350.0, 380.0, 1.2, 0.48, 0.002, 0.072, 0.5, 0.0, 26.0, 0.05)
	AudioDSP.agregar_ruido_filtrado(buf, 0.0, 0.11, "bandpass", 780.0, 220.0, 1.2, 0.30, 0.12, 0.0, 0.0, 621 + variante)
	return AudioDSP.masterizar_wav_16bit(buf, 0.50)


func _sintetizar_escudo_bloqueo(variante: int) -> AudioStreamWAV:
	# Parry / Escudo energético: rebote ascendente + campana metálica arcade
	var buf := AudioDSP.crear_buffer(0.31)
	var f_base := 440.0 + float(variante) * 35.0
	AudioDSP.agregar_rebote_cartoon(buf, 0.0, 0.07, f_base * 0.6, f_base * 1.25, f_base * 0.95, 0.45, 0.36, 0.20, 0.0)
	AudioDSP.agregar_metal_modal(buf, 0.0, 0.28, f_base, 0.54, 0.0)
	AudioDSP.agregar_fm_arcade(buf, 0.005, 0.18, f_base * 1.5, f_base * 2.0, 0.03, 1.5, 1.0, 0.05, 0.20, 0.002, 0.06, 0.12)
	AudioDSP.aplicar_reverb_estereo(buf, 0.20, 0.28)
	return AudioDSP.masterizar_wav_16bit(buf, 0.47)


func _sintetizar_campana_celestial(variante: int) -> AudioStreamWAV:
	# Subida de nivel / Altar / Buff: acorde brillante arcade (seguro hasta pitch 1.8x)
	var buf := AudioDSP.crear_buffer(0.60)
	var acorde := [392.00, 587.33, 783.99] if variante == 0 else [440.00, 659.25, 880.00]
	AudioDSP.agregar_synth_arcade(buf, 0.0, 0.42, 2, acorde[0] * 0.5, acorde[0] * 0.5, 0.01, 900.0, 1400.0, 0.9, 0.24, 0.005, 0.18, 0.5, 0.0)
	AudioDSP.agregar_nota_campana(buf, 0.00, 0.52, acorde[0], 0.44, 0.36, 0.18, -0.20)
	AudioDSP.agregar_nota_campana(buf, 0.04, 0.50, acorde[1], 0.40, 0.38, 0.17, 0.18)
	AudioDSP.agregar_nota_campana(buf, 0.08, 0.48, acorde[2], 0.34, 0.35, 0.16, 0.0)
	AudioDSP.aplicar_reverb_estereo(buf, 0.26, 0.32)
	return AudioDSP.masterizar_wav_16bit(buf, 0.46)


func _sintetizar_fanfarria_puzzle() -> AudioStreamWAV:
	# Cofre dorado / Altar completo: arpegio rápido arcade con golpe rítmico limpio
	var buf := AudioDSP.crear_buffer(0.84)
	var notas := [523.25, 659.25, 783.99, 987.77, 1046.50, 1318.51]
	var pans := [-0.30, -0.15, 0.0, 0.15, 0.25, 0.0]
	AudioDSP.agregar_percusion_arcade(buf, 0.0, true, 0.40, 0.0, 1601)
	for i in range(notas.size()):
		var t_ini := float(i) * 0.055
		var dur := 0.32 if i < notas.size() - 1 else 0.48
		AudioDSP.agregar_nota_campana(buf, t_ini, dur, float(notas[i]), 0.40, 0.42, 0.15 if i < notas.size() - 1 else 0.20, float(pans[i]))
	AudioDSP.agregar_synth_arcade(buf, 0.26, 0.52, 0, 261.63, 261.63, 0.01, 1200.0, 650.0, 0.9, 0.22, 0.01, 0.22, 0.35, 0.0)
	AudioDSP.aplicar_reverb_estereo(buf, 0.26, 0.34)
	return AudioDSP.masterizar_wav_16bit(buf, 0.48)


func _sintetizar_jackpot() -> AudioStreamWAV:
	# Trébol / Duplicación en Forja: cascada brillante estilo máquina arcade + palma limpia
	var buf := AudioDSP.crear_buffer(0.86)
	var monedas := [783.99, 987.77, 1174.66, 1318.51, 1567.98]
	for i in range(monedas.size()):
		var t_ini := float(i) * 0.048
		var f: float = monedas[i]
		var pan := -0.35 + float(i) * 0.175
		AudioDSP.agregar_fm_arcade(buf, t_ini, 0.28, f, f * 1.01, 0.01, 2.0, 1.8, 0.08, 0.38, 0.002, 0.11, pan)
	AudioDSP.agregar_percusion_arcade(buf, 0.20, false, 0.36, 0.0, 1701)
	AudioDSP.agregar_synth_arcade(buf, 0.20, 0.55, 0, 392.00, 392.00, 0.01, 1600.0, 800.0, 1.0, 0.26, 0.008, 0.22, 0.28, 0.0)
	AudioDSP.aplicar_reverb_estereo(buf, 0.28, 0.35)
	return AudioDSP.masterizar_wav_16bit(buf, 0.48)


func _sintetizar_legendario() -> AudioStreamWAV:
	# Reliquia Legendaria: fanfarria heroica en Re Lidio con synth-brass y destello cristalino
	var buf := AudioDSP.crear_buffer(1.08)
	AudioDSP.agregar_percusion_arcade(buf, 0.0, true, 0.48, 0.0, 1801)
	AudioDSP.agregar_synth_arcade(buf, 0.0, 0.92, 1, 293.66, 293.66, 0.01, 550.0, 2200.0, 1.1, 0.32, 0.025, 0.38, 0.5, -0.18)
	AudioDSP.agregar_synth_arcade(buf, 0.0, 0.92, 1, 440.00, 440.00, 0.01, 650.0, 2400.0, 1.1, 0.24, 0.030, 0.38, 0.5, 0.18)
	var notas := [587.33, 739.99, 880.00, 1108.73, 1174.66]
	for i in range(notas.size()):
		var t_ini := 0.04 + float(i) * 0.068
		var dur := 0.38 if i < notas.size() - 1 else 0.65
		AudioDSP.agregar_nota_campana(buf, t_ini, dur, float(notas[i]), 0.40, 0.45, 0.16 if i < notas.size() - 1 else 0.26, -0.25 + float(i) * 0.12)
	AudioDSP.aplicar_reverb_estereo(buf, 0.30, 0.38)
	return AudioDSP.masterizar_wav_16bit(buf, 0.50)


func _sintetizar_cuerno_oleada() -> AudioStreamWAV:
	# Llamado de oleada/frenesí arcade: doble pulso energético (seguro hasta pitch 2.2x)
	var buf := AudioDSP.crear_buffer(0.56)
	AudioDSP.agregar_synth_arcade(buf, 0.00, 0.14, 0, 146.83, 146.83, 0.01, 450.0, 820.0, 1.1, 0.48, 0.006, 0.065, 0.30, -0.12)
	AudioDSP.agregar_synth_arcade(buf, 0.14, 0.38, 0, 220.00, 220.00, 0.01, 520.0, 920.0, 1.1, 0.52, 0.008, 0.16, 0.32, 0.12, 6.0, 0.008)
	AudioDSP.agregar_synth_arcade(buf, 0.14, 0.38, 2, 146.83, 146.83, 0.01, 600.0, 750.0, 0.8, 0.28, 0.01, 0.17, 0.5, 0.0)
	AudioDSP.aplicar_reverb_estereo(buf, 0.22, 0.28)
	return AudioDSP.masterizar_wav_16bit(buf, 0.47)


func _sintetizar_jefe_alerta() -> AudioStreamWAV:
	# Sirena grave arcade de Jefe entrante + impacto sub sísmico
	var buf := AudioDSP.crear_buffer(0.98)
	AudioDSP.agregar_percusion_arcade(buf, 0.0, true, 0.62, 0.0, 501)
	AudioDSP.agregar_synth_arcade(buf, 0.00, 0.34, 1, 146.83, 110.00, 0.12, 360.0, 950.0, 1.4, 0.46, 0.015, 0.18, 0.5, -0.15)
	AudioDSP.agregar_synth_arcade(buf, 0.30, 0.62, 1, 110.00, 73.42, 0.18, 320.0, 820.0, 1.4, 0.54, 0.015, 0.28, 0.5, 0.15)
	AudioDSP.agregar_ruido_filtrado(buf, 0.0, 0.72, "lowpass", 340.0, 95.0, 1.0, 0.32, 0.20, 0.0, 0.0, 505)
	AudioDSP.aplicar_reverb_estereo(buf, 0.28, 0.36)
	return AudioDSP.masterizar_wav_16bit(buf, 0.52)


func _sintetizar_rugido_jefe() -> AudioStreamWAV:
	# Rugido sintetizado arcade para combates de jefe (agresivo pero limpio y cálido)
	var buf := AudioDSP.crear_buffer(0.84)
	AudioDSP.agregar_fm_arcade(buf, 0.0, 0.74, 125.0, 68.0, 0.28, 0.5, 2.4, 0.36, 0.52, 0.015, 0.26, 0.0)
	AudioDSP.agregar_synth_arcade(buf, 0.0, 0.68, 1, 110.0, 74.0, 0.24, 520.0, 190.0, 1.5, 0.40, 0.02, 0.24, 0.5, 0.0, 18.0, 0.04)
	AudioDSP.agregar_ruido_filtrado(buf, 0.0, 0.64, "bandpass", 480.0, 140.0, 1.4, 0.34, 0.18, 0.0, 0.0, 515)
	AudioDSP.aplicar_reverb_estereo(buf, 0.24, 0.32)
	return AudioDSP.masterizar_wav_16bit(buf, 0.52)


func _sintetizar_portal_spawn(variante: int) -> AudioStreamWAV:
	# Apertura de portal dimensional arcade con modulación espacial
	var buf := AudioDSP.crear_buffer(0.48)
	var f0 := 220.0 if variante == 0 else 246.94
	AudioDSP.agregar_fm_arcade(buf, 0.0, 0.42, f0, f0 * 1.5, 0.18, 1.5, 1.6, 0.20, 0.38, 0.025, 0.16, -0.15)
	AudioDSP.agregar_synth_arcade(buf, 0.02, 0.40, 2, f0 * 1.5, f0 * 2.0, 0.16, 450.0, 1600.0, 1.4, 0.24, 0.03, 0.15, 0.5, 0.15)
	AudioDSP.agregar_ruido_filtrado(buf, 0.0, 0.40, "bandpass", 320.0, 1150.0, 1.6, 0.28, 0.35, 0.0, 5.0, 1401 + variante * 19)
	AudioDSP.aplicar_reverb_estereo(buf, 0.28, 0.36)
	return AudioDSP.masterizar_wav_16bit(buf, 0.45)


func _sintetizar_portal_emergencia(variante: int) -> AudioStreamWAV:
	# Aparición rápida estilo warp-pop arcade
	var buf := AudioDSP.crear_buffer(0.25)
	var f0 := 155.0 if variante == 0 else 175.0
	AudioDSP.agregar_rebote_cartoon(buf, 0.0, 0.18, f0, f0 * 2.1, f0 * 0.9, 0.38, 0.52, 0.18, 0.0)
	AudioDSP.agregar_ruido_filtrado(buf, 0.0, 0.19, "bandpass", 460.0, 1200.0, 1.6, 0.26, 0.30, 0.0, 0.0, 1501 + variante * 17)
	AudioDSP.aplicar_reverb_estereo(buf, 0.16, 0.22)
	return AudioDSP.masterizar_wav_16bit(buf, 0.44)


func _sintetizar_fanfarria_victoria() -> AudioStreamWAV:
	# Fanfarria arcade triunfal: ritmo animado + unísono synth-brass & campana en Do Mayor 9
	var buf := AudioDSP.crear_buffer(1.48)
	var notas := [
		[0.00, 523.25, 0.14, 0.36, -0.20],
		[0.11, 523.25, 0.14, 0.34, 0.20],
		[0.22, 659.25, 0.16, 0.38, -0.15],
		[0.34, 783.99, 0.20, 0.42, 0.15],
		[0.50, 1046.50, 0.85, 0.48, 0.0],
	]
	AudioDSP.agregar_percusion_arcade(buf, 0.00, true, 0.45, 0.0, 1901)
	AudioDSP.agregar_percusion_arcade(buf, 0.22, false, 0.34, 0.0, 1902)
	AudioDSP.agregar_percusion_arcade(buf, 0.50, true, 0.55, 0.0, 1903)

	for n in notas:
		var t_i: float = n[0]
		var f: float = n[1]
		var d: float = n[2]
		var a: float = n[3]
		var pan: float = n[4]
		AudioDSP.agregar_nota_campana(buf, t_i, d + 0.18, f, a, 0.42, 0.12 if t_i < 0.45 else 0.32, pan)
		AudioDSP.agregar_synth_arcade(buf, t_i, d, 0, f * 0.5, f * 0.5, 0.01, 900.0, 1800.0, 1.0, a * 0.42, 0.005, 0.08 if t_i < 0.45 else 0.34, 0.35, -pan * 0.5)

	AudioDSP.agregar_nota_campana(buf, 0.52, 0.88, 587.33, 0.22, 0.32, 0.34, -0.28)
	AudioDSP.agregar_nota_campana(buf, 0.54, 0.86, 659.25, 0.24, 0.32, 0.34, 0.28)
	AudioDSP.aplicar_reverb_estereo(buf, 0.30, 0.38)
	return AudioDSP.masterizar_wav_16bit(buf, 0.52)


func _sintetizar_descenso_derrota() -> AudioStreamWAV:
	# Game Over arcade expresivo: descenso cromático + caída caricaturesca final
	var buf := AudioDSP.crear_buffer(1.28)
	var notas := [
		[0.00, 392.00, 0.24, -0.15],
		[0.20, 369.99, 0.24, 0.15],
		[0.40, 349.23, 0.24, -0.10],
		[0.60, 329.63, 0.26, 0.10],
	]
	for n in notas:
		AudioDSP.agregar_synth_arcade(buf, float(n[0]), float(n[2]), 0, float(n[1]), float(n[1]), 0.01, 1100.0, 520.0, 1.0, 0.34, 0.008, 0.12, 0.35, float(n[3]))
		AudioDSP.agregar_nota_campana(buf, float(n[0]), float(n[2]) + 0.1, float(n[1]), 0.22, 0.22, 0.12, -float(n[3]))

	# Nota final descendente estilo Super Bonk ("wah-waaah")
	AudioDSP.agregar_synth_arcade(buf, 0.80, 0.44, 1, 261.63, 196.00, 0.22, 850.0, 280.0, 1.1, 0.38, 0.01, 0.22, 0.5, 0.0, 5.5, 0.018)
	AudioDSP.agregar_percusion_arcade(buf, 0.0, true, 0.34, 0.0, 2001)
	AudioDSP.aplicar_reverb_estereo(buf, 0.28, 0.34)
	return AudioDSP.masterizar_wav_16bit(buf, 0.48)
