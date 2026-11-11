extends Node

# AudioManager Desacoplado - Clicklike 3D
# Desarrollado por: Juan Camilo Angulo Camelo
# Genera proceduralmente efectos de sonido sintetizados en memoria (AudioStreamWAV).

class_name AudioManager

static var instance: AudioManager = null

var _sonidos: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _max_players: int = 12
var _player_index: int = 0

func _enter_tree():
	instance = self

func _ready():
	add_to_group("audio_manager")
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Crear pool de reproductores para permitir sonidos simultáneos
	for i in range(_max_players):
		var p = AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_players.append(p)
		
	_generar_biblioteca_sonidos()

func _generar_biblioteca_sonidos():
	_sonidos["click"] = _sintetizar_click()
	_sonidos["orbe_lanzar"] = _sintetizar_orbe_lanzar()
	_sonidos["orbe_explosion"] = _sintetizar_orbe_explosion()
	_sonidos["altar_activado"] = _sintetizar_campana_celestial()
	_sonidos["puzzle_completo"] = _sintetizar_fanfarria_puzzle()
	_sonidos["alerta_oleada"] = _sintetizar_cuerno_oleada()
	_sonidos["jefe_alerta"] = _sintetizar_rugido_jefe()
	_sonidos["danio_jugador"] = _sintetizar_golpe_dano()
	_sonidos["enemigo_muerte"] = _sintetizar_pop_muerte()
	_sonidos["corte_giratorio"] = _sintetizar_corte_giratorio()
	_sonidos["escudo_bloqueo"] = _sintetizar_escudo_bloqueo()
	_sonidos["victoria"] = _sintetizar_fanfarria_victoria()
	_sonidos["derrota"] = _sintetizar_descenso_derrota()
	_sonidos["corte_espada"] = _sintetizar_corte_espada()
	_sonidos["disparo_arco"] = _sintetizar_disparo_arco()
	_sonidos["impacto_flecha"] = _sintetizar_impacto_flecha()
	_sonidos["disparo_arquero"] = _sintetizar_disparo_arquero()
	_sonidos["golpe_impacto"] = _sintetizar_golpe_impacto()

func reproducir(nombre_sonido: String, tono: float = 1.0, volumen_db: float = 0.0):
	if not _sonidos.has(nombre_sonido) or not is_inside_tree():
		return
	var stream: AudioStreamWAV = _sonidos[nombre_sonido]
	var p: AudioStreamPlayer = _players[_player_index]
	_player_index = (_player_index + 1) % _max_players
	
	p.stream = stream
	p.pitch_scale = clampf(tono, 0.4, 2.5)
	p.volume_db = volumen_db
	p.play()

# Accesos directos convenientes
static func play(sonido: String, tono: float = 1.0, volumen_db: float = 0.0):
	if instance != null:
		instance.reproducir(sonido, tono, volumen_db)

# ==============================================================================
# SINTETIZADORES PROCEDURALES DE AUDIO (Matemática pura de síntesis de ondas)
# ==============================================================================

func _crear_wav_8bit(total_muestras: int, tasa_muestreo: int, generador: Callable) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = tasa_muestreo
	wav.stereo = false
	var bytes = PackedByteArray()
	bytes.resize(total_muestras)
	
	for i in range(total_muestras):
		var t = float(i) / float(tasa_muestreo)
		var val_normalizado = generador.call(t, i, total_muestras)
		var muestra = int(clampf(val_normalizado, -1.0, 1.0) * 126.0 + 128.0)
		bytes[i] = muestra
		
	wav.data = bytes
	return wav

func _sintetizar_click() -> AudioStreamWAV:
	var sr = 22050
	var dur = 0.08
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var env = 1.0 - (float(i) / total)
		var freq = 880.0 - 500.0 * (float(i) / total)
		return sin(TAU * freq * t) * env * 0.95
	)

func _sintetizar_orbe_lanzar() -> AudioStreamWAV:
	var sr = 22050
	var dur = 0.22
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var frac = float(i) / total
		var env = sin(frac * PI)
		var freq = 420.0 + 380.0 * sin(frac * PI * 2.0)
		return (sin(TAU * freq * t) * 0.7 + sin(TAU * (freq * 1.5) * t) * 0.3) * env
	)

func _sintetizar_orbe_explosion() -> AudioStreamWAV:
	var sr = 22050
	var dur = 0.38
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var env = exp(-float(i) / (total * 0.28))
		var freq = 160.0 * exp(-float(i) / (total * 0.35)) + 45.0
		var sub = sin(TAU * freq * t) * 0.65
		var ruido = (randf() * 2.0 - 1.0) * 0.35
		return (sub + ruido) * env
	)

func _sintetizar_campana_celestial() -> AudioStreamWAV:
	var sr = 22050
	var dur = 0.60
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var env = exp(-float(i) / (total * 0.35))
		var a = sin(TAU * 659.25 * t) * 0.5   # Mi5
		var b = sin(TAU * 987.77 * t) * 0.35  # Si5
		var c = sin(TAU * 1318.51 * t) * 0.15 # Mi6
		return (a + b + c) * env
	)

func _sintetizar_fanfarria_puzzle() -> AudioStreamWAV:
	var sr = 22050
	var dur = 0.85
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var frac = float(i) / total
		var freq = 523.25 # Do5
		if frac > 0.66:
			freq = 1046.50 # Do6
		elif frac > 0.33:
			freq = 783.99  # Sol5
		var env = 1.0 - fmod(frac * 3.0, 1.0) * 0.35
		return sin(TAU * freq * t) * env * 0.8
	)

func _sintetizar_cuerno_oleada() -> AudioStreamWAV:
	var sr = 22050
	var dur = 0.70
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var env = sin(float(i) / total * PI)
		var f1 = 220.0
		var f2 = 330.0
		return (sin(TAU * f1 * t) * 0.6 + sin(TAU * f2 * t) * 0.4) * env * 0.9
	)

func _sintetizar_rugido_jefe() -> AudioStreamWAV:
	var sr = 22050
	var dur = 0.95
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var env = sin(float(i) / total * PI)
		var f = 90.0 + 30.0 * sin(t * 14.0)
		var ruido = (randf() * 2.0 - 1.0) * 0.4
		return (sin(TAU * f * t) * 0.6 + ruido) * env * 0.95
	)

func _sintetizar_golpe_dano() -> AudioStreamWAV:
	var sr = 22050
	var dur = 0.15
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var env = 1.0 - (float(i) / total)
		var f = 240.0 - 160.0 * (float(i) / total)
		return (sin(TAU * f * t) * 0.7 + (randf() * 2.0 - 1.0) * 0.3) * env
	)

func _sintetizar_pop_muerte() -> AudioStreamWAV:
	var sr = 22050
	var dur = 0.12
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var env = 1.0 - (float(i) / total)
		var f = 350.0 + 400.0 * (1.0 - float(i) / total)
		return sin(TAU * f * t) * env * 0.8
	)

func _sintetizar_fanfarria_victoria() -> AudioStreamWAV:
	var sr = 22050
	var dur = 1.2
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var frac = float(i) / total
		var freq = 440.0
		if frac > 0.75: freq = 880.0
		elif frac > 0.50: freq = 659.25
		elif frac > 0.25: freq = 554.37
		var sub_env = 1.0 - fmod(frac * 4.0, 1.0) * 0.4
		return sin(TAU * freq * t) * sub_env * 0.85
	)

func _sintetizar_descenso_derrota() -> AudioStreamWAV:
	var sr = 22050
	var dur = 1.1
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var env = 1.0 - (float(i) / total)
		var f = 320.0 * (1.0 - (float(i) / total) * 0.7)
		return sin(TAU * f * t) * env * 0.85
	)

func _sintetizar_corte_espada() -> AudioStreamWAV:
	var sr = 22050
	var dur = 0.15
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var frac = float(i) / total
		var env = sin(frac * PI)
		var noise = (randf() * 2.0 - 1.0) * 0.65
		var sweep = sin(TAU * (850.0 - frac * 550.0) * t) * 0.35
		return (sweep + noise) * env
	)

func _sintetizar_corte_giratorio() -> AudioStreamWAV:
	var sr = 22050
	var dur = 0.28
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var frac = float(i) / total
		var env = sin(frac * PI)
		var freq = 110.0 + 380.0 * (1.0 - frac)
		var ruido = (randf() * 2.0 - 1.0) * 0.45
		var sweep = sin(TAU * freq * t) * 0.65
		return (sweep + ruido) * env * 0.95
	)

func _sintetizar_disparo_arco() -> AudioStreamWAV:
	var sr = 22050
	var dur = 0.18
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var frac = float(i) / total
		var env = pow(1.0 - frac, 1.8)
		# Tensión de cuerda liberada + silbido aerodinámico
		var snap = sin(TAU * 520.0 * t) * 0.4
		var whistle = sin(TAU * (1200.0 - frac * 600.0) * t) * 0.5
		var noise = (randf() * 2.0 - 1.0) * 0.2
		return (snap + whistle + noise) * env
	)

func _sintetizar_impacto_flecha() -> AudioStreamWAV:
	var sr = 22050
	var dur = 0.12
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var frac = float(i) / total
		var env = exp(-frac * 12.0)
		var thud = sin(TAU * (280.0 - frac * 180.0) * t) * 0.7
		var click = (randf() * 2.0 - 1.0) * 0.3
		return (thud + click) * env
	)

func _sintetizar_disparo_arquero() -> AudioStreamWAV:
	var sr = 22050
	var dur = 0.22
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var frac = float(i) / total
		var env = sin(frac * PI)
		var f = 380.0 + sin(frac * PI * 4.0) * 90.0
		var noise = (randf() * 2.0 - 1.0) * 0.25
		return (sin(TAU * f * t) * 0.75 + noise) * env
	)

func _sintetizar_golpe_impacto() -> AudioStreamWAV:
	var sr = 22050
	var dur = 0.14
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var frac = float(i) / total
		var env = 1.0 - frac
		var f = 160.0 - frac * 90.0
		return (sin(TAU * f * t) * 0.6 + (randf() * 2.0 - 1.0) * 0.4) * env
	)

func _sintetizar_escudo_bloqueo() -> AudioStreamWAV:
	var sr = 22050
	var dur = 0.26
	var n = int(sr * dur)
	return _crear_wav_8bit(n, sr, func(t: float, i: int, total: int):
		var frac = float(i) / total
		var env = exp(-frac * 6.5)
		var a = sin(TAU * 1250.0 * t) * 0.45
		var b = sin(TAU * 1875.0 * t) * 0.35
		var c = sin(TAU * 2500.0 * t) * 0.20
		return (a + b + c) * env
	)
