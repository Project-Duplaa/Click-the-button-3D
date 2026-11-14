class_name LogrosManager
extends Node

## LogrosManager — Gestor de Hitos, Desafíos y Pacto de Tormento (0..5)
## Diseñado para Clicklike 3D (Godot 4.6).
## Registra el progreso persistente en `user://logros_clicklike.cfg`.

signal logro_desbloqueado(id_logro: String, datos: Dictionary)
signal tormento_cambiado(nuevo_nivel: int)

const RUTA_GUARDADO: String = "user://logros_clicklike.cfg"

const DEFINICIONES_LOGROS: Dictionary = {
	"primer_nivel_5": {
		"id": "primer_nivel_5",
		"titulo": "Ascensión Rúnica",
		"desc": "Alcanza el Nivel 5 de personaje en una sola partida.",
		"icono": "⭐"
	},
	"fiebre_maxima": {
		"id": "fiebre_maxima",
		"titulo": "Sobrecarga Absoluta",
		"desc": "Alcanza el estado de Fiebre Nivel 3 (Overdrive) mediante clics veloces.",
		"icono": "🔥"
	},
	"cazador_heraldo": {
		"id": "cazador_heraldo",
		"titulo": "Cazador de Sombras",
		"desc": "Derrota a tu primer Mini-Jefe o Heraldo del Coliseo.",
		"icono": "💀"
	},
	"maestro_sinergia": {
		"id": "maestro_sinergia",
		"titulo": "Fusión Divina",
		"desc": "Desbloquea y activa tu primera Fusión Mítica Dual.",
		"icono": "✨"
	},
	"vencedor_parca": {
		"id": "vencedor_parca",
		"titulo": "Trascendencia del Juicio",
		"desc": "Aniquila a La Parca Roja en la prueba final.",
		"icono": "👑"
	},
	"primer_clic": {
		"id": "primer_clic",
		"titulo": "El Despertar",
		"desc": "Activa el Núcleo Rúnico por primera vez.",
		"icono": "⚡"
	},
	"acumulador_oro": {
		"id": "acumulador_oro",
		"titulo": "Tesoro del Gladiador",
		"desc": "Acumula más de 250 de Oro en tus arcas en una sola run.",
		"icono": "🪙"
	},
	"combo_hilo": {
		"id": "combo_hilo",
		"titulo": "Conductor Supremo",
		"desc": "Alcanza a 25 enemigos simultáneos con las ondas de descarga del Núcleo.",
		"icono": "⚡"
	}
}

var logros_obtenidos: Dictionary = {}
var nivel_tormento: int = 0
var _config: ConfigFile = ConfigFile.new()

func _ready():
	add_to_group("logros_manager")
	process_mode = Node.PROCESS_MODE_ALWAYS
	cargar_datos()

func tiene_logro(id: String) -> bool:
	return logros_obtenidos.has(id) and logros_obtenidos[id] == true

func desbloquear_logro(id: String) -> bool:
	if not DEFINICIONES_LOGROS.has(id):
		return false
	if tiene_logro(id):
		return false
		
	logros_obtenidos[id] = true
	guardar_datos()
	
	var datos = DEFINICIONES_LOGROS[id]
	_mostrar_notificacion_logro(datos)
	
	var dopamina = get_tree().get_first_node_in_group("audio_dopamina")
	if dopamina != null and dopamina.has_method("play_level_up"):
		dopamina.play_level_up()
		
	logro_desbloqueado.emit(id, datos)
	return true

func establecer_tormento(nivel: int):
	nivel_tormento = clampi(nivel, 0, 5)
	guardar_datos()
	tormento_cambiado.emit(nivel_tormento)

func obtener_tormento() -> int:
	return nivel_tormento

func cargar_datos():
	var err = _config.load(RUTA_GUARDADO)
	if err == OK:
		nivel_tormento = _config.get_value("progresion", "pacto_tormento", 0)
		for id in DEFINICIONES_LOGROS.keys():
			logros_obtenidos[id] = _config.get_value("logros", id, false)
	else:
		nivel_tormento = 0
		for id in DEFINICIONES_LOGROS.keys():
			logros_obtenidos[id] = false

func guardar_datos():
	_config.set_value("progresion", "pacto_tormento", nivel_tormento)
	for id in logros_obtenidos.keys():
		_config.set_value("logros", id, logros_obtenidos[id])
	_config.save(RUTA_GUARDADO)

func _mostrar_notificacion_logro(datos: Dictionary):
	var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
	var jugador = get_tree().get_first_node_in_group("player")
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
	if pool_dano != null and jugador != null:
		var txt = "%s ¡LOGRO: %s!" % [datos["icono"], datos["titulo"].to_upper()]
		pool_dano.mostrar_texto(jugador.global_position + Vector3(0, 2.5, 0), txt, Color(1.0, 0.85, 0.2), 1.35)

func obtener_todos_los_logros() -> Dictionary:
	var resultado = {}
	for id in DEFINICIONES_LOGROS.keys():
		var info = DEFINICIONES_LOGROS[id].duplicate()
		info["desbloqueado"] = tiene_logro(id)
		resultado[id] = info
	return resultado
