class_name AudioDopamina
extends Node

## AudioDopamina — Sintetizador Procedural de Recompensas Acústicas
## Diseñado para Clicklike 3D (Godot 4.6).
## Emplea un pool de 6 AudioStreamPlayer con AudioStreamGenerator para generar
## en tiempo real envolventes limpias de retro-modern sine/triangle chimes sin dependencias externas .wav.
## Escala Pentatónica Mayor para subidas rítmicas de XP, campanadas de oro y chasquidos de clics.

const NUM_CANALES: int = 6
const SAMPLE_RATE: float = 22050.0
const BUFFER_DURACION: float = 0.25

const ESCALA_PENTATONICA = [1.0, 1.12246, 1.25992, 1.49831, 1.68179, 2.0, 2.24492, 2.51984]
const FREQ_BASE_C5: float = 523.25

var _players: Array[AudioStreamPlayer] = []
var _playbacks: Array[AudioStreamGeneratorPlayback] = []
var _canal_actual: int = 0

var _racha_xp: int = 0
var _reloj_reset_xp: float = 0.0

func _ready():
	add_to_group("audio_dopamina")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_inicializar_sintetizador()

func _inicializar_sintetizador():
	for i in range(NUM_CANALES):
		var player = AudioStreamPlayer.new()
		player.name = "CanalSintetizador_%d" % i
		player.bus = "Master"
		
		var gen = AudioStreamGenerator.new()
		gen.mix_rate = SAMPLE_RATE
		gen.buffer_length = BUFFER_DURACION
		player.stream = gen
		
		add_child(player)
		player.play()
		
		var pb = player.get_stream_playback() as AudioStreamGeneratorPlayback
		_players.append(player)
		_playbacks.append(pb)

func _process(delta: float):
	if _reloj_reset_xp > 0.0:
		_reloj_reset_xp -= delta
		if _reloj_reset_xp <= 0.0:
			_racha_xp = 0

func _obtener_siguiente_playback() -> AudioStreamGeneratorPlayback:
	var pb = _playbacks[_canal_actual]
	_canal_actual = (_canal_actual + 1) % NUM_CANALES
	return pb

func _sintetizar_tono(freq: float, duracion: float, decay_rate: float = 22.0, volumen: float = 0.22, forma_onda: String = "sine"):
	var pb = _obtener_siguiente_playback()
	if pb == null:
		return
		
	var frames = int(SAMPLE_RATE * duracion)
	var available = pb.get_frames_available()
	frames = mini(frames, available)
	
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var env = exp(-t * decay_rate) * volumen
		var val = 0.0
		
		if forma_onda == "sine":
			val = sin(TAU * freq * t) * 0.85 + sin(TAU * freq * 2.0 * t) * 0.15
		elif forma_onda == "triangle":
			val = (abs(fmod(t * freq, 1.0) - 0.5) * 4.0 - 1.0)
		elif forma_onda == "chime":
			val = sin(TAU * freq * t) * 0.65 + sin(TAU * freq * 2.76 * t) * 0.25 + sin(TAU * freq * 5.4 * t) * 0.10
			
		val *= env
		pb.push_frame(Vector2(val, val))

func play_xp_pickup():
	_reloj_reset_xp = 0.70
	var idx = _racha_xp % ESCALA_PENTATONICA.size()
	var ratio = ESCALA_PENTATONICA[idx]
	_racha_xp += 1
	
	var freq = FREQ_BASE_C5 * ratio
	_sintetizar_tono(freq, 0.11, 26.0, 0.18, "chime")

func play_gold_pickup():
	var freq1 = 1046.50
	var freq2 = 1318.51
	_sintetizar_tono(freq1, 0.09, 28.0, 0.16, "chime")
	if is_inside_tree():
		get_tree().create_timer(0.045, false).timeout.connect(func():
			if is_instance_valid(self) and is_inside_tree():
				_sintetizar_tono(freq2, 0.12, 22.0, 0.20, "chime")
		)

func play_click(es_perfecto: bool = false, nivel_fiebre: int = 0):
	var base_freq = 320.0 + (nivel_fiebre * 65.0)
	_sintetizar_tono(base_freq, 0.08, 45.0, 0.24, "triangle")
	
	if es_perfecto:
		var chime_freq = 1567.98
		_sintetizar_tono(chime_freq, 0.18, 16.0, 0.28, "chime")

func play_level_up():
	var notas = [523.25, 659.25, 783.99, 1046.50]
	if is_inside_tree():
		for i in range(notas.size()):
			var nota: float = notas[i]
			get_tree().create_timer(i * 0.07, false).timeout.connect(func():
				if is_instance_valid(self) and is_inside_tree():
					_sintetizar_tono(nota, 0.22, 12.0, 0.25, "chime")
			)

func play_boss_stagger():
	_sintetizar_tono(85.0, 0.25, 10.0, 0.35, "sine")
	if is_inside_tree():
		get_tree().create_timer(0.03, false).timeout.connect(func():
			if is_instance_valid(self) and is_inside_tree():
				_sintetizar_tono(440.0, 0.30, 8.0, 0.22, "chime")
		)
