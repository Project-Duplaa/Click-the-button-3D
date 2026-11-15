extends Node

## MusicManager Adaptativo (5 Etapas Verticales Sincronizadas)
## Identidad Musical: Dark Arcade Fantasy x Retro Synthwave (132.3 BPM, Re menor)
## Mantiene los 5 stems sincronizados al sample exacto y realiza mezclas progresivas
## continuas sin cortes ni silencios bruscos.

class_name MusicManager

static var instance: MusicManager = null

const RUTAS_STEMS := [
	"res://audio/music/music_stage_1.wav",
	"res://audio/music/music_stage_2.wav",
	"res://audio/music/music_stage_3.wav",
	"res://audio/music/music_stage_4.wav",
	"res://audio/music/music_stage_5.wav",
]

const BUS_MUSICA: StringName = &"Music"
const VOLUMEN_BASE_BUS_DB: float = -7.5

# Ganancias en dB de cada stem [S1, S2, S3, S4, S5] según etapa (1..5)
const MATRIZ_ETAPAS_DB := {
	1: [0.0, -60.0, -60.0, -60.0, -60.0],
	2: [-1.5, 0.0, -60.0, -60.0, -60.0],
	3: [-4.0, -3.5, 0.0, -60.0, -60.0],
	4: [-5.5, -5.0, -1.5, 0.0, -60.0],
	5: [-7.0, -6.5, -2.0, -1.5, 0.0],
}

var _stems: Array[AudioStreamWAV] = []
var _players: Array[AudioStreamPlayer] = []
var _amps_actuales: Array[float] = [0.001, 0.0005, 0.0005, 0.0005, 0.0005]
var _etapa_actual: int = 1
var _etapa_forzada: int = 0 # 0 = automático según combate

var _lpf_bus: AudioEffectLowPassFilter = null
var _cutoff_actual: float = 19500.0
var _duck_fanfarria_seg: float = 0.0
var _duck_db_actual: float = 0.0
var _reloj_sync: float = 0.0
var _reloj_evaluacion: float = 0.0
var _min_etapa_partida: int = 1


func _enter_tree():
	instance = self


func _ready():
	add_to_group("music_manager")
	process_mode = Node.PROCESS_MODE_ALWAYS
	tree_exiting.connect(_detener_stems)
	_configurar_bus_musica()
	_cargar_stems()
	_crear_reproductores()
	_iniciar_sincronizado()


func _detener_stems() -> void:
	for p in _players:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	_players.clear()
	_stems.clear()
	_lpf_bus = null


func _exit_tree():
	_detener_stems()
	if instance == self:
		instance = null


func _configurar_bus_musica() -> void:
	var idx := AudioServer.get_bus_index(BUS_MUSICA)
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, BUS_MUSICA)
		AudioServer.set_bus_send(idx, &"Master")

	AudioServer.set_bus_volume_db(idx, VOLUMEN_BASE_BUS_DB)

	# Buscar o crear filtro pasabajos para pausa / menús de mejora
	_lpf_bus = null
	var tiene_limiter := false
	for i in range(AudioServer.get_bus_effect_count(idx)):
		var ef := AudioServer.get_bus_effect(idx, i)
		if ef is AudioEffectLowPassFilter:
			_lpf_bus = ef
		elif ef is AudioEffectLimiter:
			tiene_limiter = true

	if _lpf_bus == null:
		_lpf_bus = AudioEffectLowPassFilter.new()
		_lpf_bus.cutoff_hz = 19500.0
		_lpf_bus.resonance = 0.5
		AudioServer.add_bus_effect(idx, _lpf_bus)

	if not tiene_limiter:
		var lim := AudioEffectLimiter.new()
		lim.ceiling_db = -2.0
		lim.threshold_db = -5.0
		lim.soft_clip_db = 2.0
		lim.soft_clip_ratio = 8.0
		AudioServer.add_bus_effect(idx, lim)


func _cargar_stems() -> void:
	_stems.clear()
	for ruta in RUTAS_STEMS:
		var ruta_s: String = str(ruta)
		var wav: AudioStreamWAV = null
		if ResourceLoader.exists(ruta_s):
			var res: Resource = load(ruta_s)
			if res is AudioStreamWAV:
				wav = res
		if wav == null and FileAccess.file_exists(ruta_s):
			var bytes: PackedByteArray = FileAccess.get_file_as_bytes(ruta_s)
			if not bytes.is_empty():
				wav = AudioStreamWAV.load_from_buffer(bytes)
		if wav != null:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			var frames := int(roundf(wav.get_length() * float(wav.mix_rate)))
			if frames <= 0:
				frames = maxi(1, wav.data.size() / (4 if wav.stereo else 2))
			wav.loop_end = frames
		_stems.append(wav)


func _crear_reproductores() -> void:
	_players.clear()
	for i in range(RUTAS_STEMS.size()):
		var p := AudioStreamPlayer.new()
		p.bus = BUS_MUSICA
		p.volume_db = -60.0
		if i < _stems.size() and _stems[i] != null:
			p.stream = _stems[i]
		add_child(p)
		_players.append(p)


func _iniciar_sincronizado() -> void:
	for i in range(_players.size()):
		var p := _players[i]
		if p.stream != null:
			p.play(0.0)


func set_etapa(etapa: int) -> void:
	_etapa_forzada = clampi(etapa, 0, 5)


func duck_fanfarria(duracion_seg: float = 1.6) -> void:
	_duck_fanfarria_seg = maxf(_duck_fanfarria_seg, duracion_seg)


func _evaluar_etapa_combate() -> int:
	if _etapa_forzada > 0:
		return _etapa_forzada

	var tree := get_tree()
	if tree == null:
		return 1

	var fin_partida := tree.get_first_node_in_group("pantalla_fin_partida")
	if fin_partida != null and fin_partida.get("visible") == true:
		return 1

	var spawner := tree.get_first_node_in_group("spawner")
	if spawner == null:
		return 1

	var iniciada: bool = bool(spawner.get("partida_iniciada"))
	if not iniciada:
		_min_etapa_partida = 1
		return 1

	# Una vez iniciada la batalla, la música no regresa a calma total
	_min_etapa_partida = maxi(_min_etapa_partida, 2)

	var oleada: int = int(spawner.get("oleada_actual"))
	var parca_activa: bool = bool(spawner.get("_parca_spawned"))
	var jefe_medio_activo: bool = (
		bool(spawner.get("_mini_jefe_spawned"))
		or bool(spawner.get("_maestra_spawned"))
		or bool(spawner.get("_coloso_spawned"))
	)

	var enemigos := tree.get_nodes_in_group("enemigos").size()
	var jefes := tree.get_nodes_in_group("jefes").size()

	var en_frenesi := false
	var boton := tree.get_first_node_in_group("boton_movil")
	if boton != null and int(boton.get("estado_actual")) == 2: # EstadoBoton.SOBRECARGA_FRENESI
		en_frenesi = true

	# ETAPA 5 — CAOS TOTAL
	if oleada >= 11 or parca_activa or (enemigos >= 30 and (jefes > 0 or en_frenesi)):
		return 5

	# ETAPA 4 — FRENESÍ INTENSO
	if oleada >= 6 or en_frenesi or enemigos >= 22 or (jefes > 0 and jefe_medio_activo):
		return 4

	# ETAPA 3 — COMBATE ACTIVO
	if oleada >= 3 or enemigos >= 11 or jefes > 0:
		return 3

	# ETAPA 2 — CONSTRUYENDO ENERGÍA
	return _min_etapa_partida


func _process(delta: float) -> void:
	if _players.is_empty():
		return

	_reloj_evaluacion += delta
	if _reloj_evaluacion >= 0.20:
		_reloj_evaluacion = 0.0
		_etapa_actual = _evaluar_etapa_combate()

	var tree := get_tree()
	var pausado := tree != null and tree.paused
	var fin_visible := false
	if tree != null:
		var fin := tree.get_first_node_in_group("pantalla_fin_partida")
		fin_visible = (fin != null and fin.get("visible") == true)

	if _duck_fanfarria_seg > 0.0:
		_duck_fanfarria_seg = maxf(0.0, _duck_fanfarria_seg - delta)

	# 1. Crossfade lineal de amplitudes entre los 5 stems (transiciones naturales sin cortes)
	var objetivos_db: Array = MATRIZ_ETAPAS_DB[_etapa_actual]
	for i in range(_players.size()):
		var db_obj: float = float(objetivos_db[i])
		var amp_obj := 0.0 if db_obj <= -58.0 else db_to_linear(db_obj)
		var amp_act := _amps_actuales[i]
		# Subida suave (~1.4s), bajada más gradual (~3.4s) para fluidez musical
		var velocidad := 0.90 if amp_obj > amp_act else 0.34
		amp_act = lerpf(amp_act, amp_obj, minf(1.0, delta * velocidad))
		_amps_actuales[i] = amp_act
		_players[i].volume_db = -72.0 if amp_act <= 0.0006 else linear_to_db(amp_act)

	# 2. Filtro pasabajos y ducking suave en pausa, árbol de mejoras, fin de partida o fanfarrias
	var target_cutoff := 19500.0
	var target_duck := 0.0
	if fin_visible:
		target_cutoff = 980.0
		target_duck = -9.5
	elif pausado:
		target_cutoff = 1350.0
		target_duck = -4.2

	if _duck_fanfarria_seg > 0.0:
		target_duck = minf(target_duck, -6.5)

	_cutoff_actual = lerpf(_cutoff_actual, target_cutoff, minf(1.0, delta * 3.8))
	_duck_db_actual = lerpf(_duck_db_actual, target_duck, minf(1.0, delta * 4.5))

	if _lpf_bus != null:
		_lpf_bus.cutoff_hz = clampf(_cutoff_actual, 400.0, 20000.0)
	var bus_idx := AudioServer.get_bus_index(BUS_MUSICA)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, VOLUMEN_BASE_BUS_DB + _duck_db_actual)

	# 3. Verificación periódica de sincronía entre stems
	_reloj_sync += delta
	if _reloj_sync >= 2.0:
		_reloj_sync = 0.0
		_sincronizar_stems()


func _sincronizar_stems() -> void:
	if _players.is_empty() or not _players[0].playing:
		return
	var pos_ref := _players[0].get_playback_position()
	for i in range(1, _players.size()):
		var p := _players[i]
		if p.stream == null:
			continue
		if not p.playing:
			p.play(pos_ref)
		elif absf(p.get_playback_position() - pos_ref) > 0.035:
			p.seek(pos_ref)
