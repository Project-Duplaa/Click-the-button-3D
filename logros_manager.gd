class_name LogrosManager
extends Node

## LogrosManager — Gestor de Hitos, Hazañas (32) y Pacto de Tormento (0..10)
## Vincula directamente recompensas al MetaprogresoManager (Bendiciones, Chasis, Esquirlas).
## Persiste el progreso en `user://logros_clicklike.cfg`.

signal logro_desbloqueado(id_logro: String, datos: Dictionary)
signal hazana_desbloqueada(id_logro: String, datos: Dictionary)
signal tormento_cambiado(nuevo_nivel: int)

const RUTA_GUARDADO: String = "user://logros_clicklike.cfg"

# 32 Hazañas divididas equitativamente en 4 categorías: "clic", "combate", "clase", "tormento"
const DEFINICIONES_LOGROS: Dictionary = {
	# --- CATEGORÍA 1: CLIC (8 Hazañas) ---
	"primer_clic": {
		"id": "primer_clic",
		"titulo": "El Despertar Rúnico",
		"desc": "Activa el Núcleo Rúnico por primera vez pulsando el Botón Móvil.",
		"icono": "⚡",
		"categoria": "clic",
		"recompensa_tipo": "esquirlas",
		"recompensa_id": "5",
		"recompensa_texto": "+5 Esquirlas Astrales"
	},
	"clic_100": {
		"id": "clic_100",
		"titulo": "Cadencia Manual",
		"desc": "Efectúa 100 clics manuales en una misma partida.",
		"icono": "👆",
		"categoria": "clic",
		"recompensa_tipo": "bendicion",
		"recompensa_id": "sobrecarga_hilo",
		"recompensa_texto": "Desbloquea Sobrecarga del Núcleo"
	},
	"fiebre_maxima": {
		"id": "fiebre_maxima",
		"titulo": "Sobrecarga Absoluta",
		"desc": "Alcanza el estado de Fiebre Nivel 3 (Overdrive) mediante clics veloces.",
		"icono": "🔥",
		"categoria": "clic",
		"recompensa_tipo": "bendicion",
		"recompensa_id": "fiebre_perpetua",
		"recompensa_texto": "Desbloquea Fiebre Perpetua"
	},
	"fiebre_sostenida": {
		"id": "fiebre_sostenida",
		"titulo": "Furia Incandescente",
		"desc": "Mantén el estado de Fiebre Overdrive (x4 o x5) durante al menos 15 segundos continuos.",
		"icono": "☄️",
		"categoria": "clic",
		"recompensa_tipo": "chasis",
		"recompensa_id": "cometa",
		"recompensa_texto": "Desbloquea Chasis Cometa"
	},
	"combo_hilo": {
		"id": "combo_hilo",
		"titulo": "Conductor Supremo",
		"desc": "Alcanza a 25 enemigos simultáneos con las ondas de descarga del Núcleo.",
		"icono": "🔗",
		"categoria": "clic",
		"recompensa_tipo": "bendicion",
		"recompensa_id": "supernova_inestable",
		"recompensa_texto": "Desbloquea Supernova Inestable"
	},
	"clic_chasis_gravitatorio": {
		"id": "clic_chasis_gravitatorio",
		"titulo": "Atracción Masiva",
		"desc": "Alcanza 150 clics al Núcleo en una sola run.",
		"icono": "🧲",
		"categoria": "clic",
		"recompensa_tipo": "chasis",
		"recompensa_id": "gravitatorio",
		"recompensa_texto": "Desbloquea Chasis Gravitatorio"
	},
	"onda_congelante": {
		"id": "onda_congelante",
		"titulo": "Cero Absoluto",
		"desc": "Ralentiza o noquea a 50 enemigos con ondas expansivas de clic.",
		"icono": "❄️",
		"categoria": "clic",
		"recompensa_tipo": "bendicion",
		"recompensa_id": "nova_helada",
		"recompensa_texto": "Desbloquea Nova Helada"
	},
	"maestro_clicker_1000": {
		"id": "maestro_clicker_1000",
		"titulo": "Titán de la Fisión",
		"desc": "Acumula más de 1,000 clics históricos registrados en tu cuenta.",
		"icono": "⚡👑",
		"categoria": "clic",
		"recompensa_tipo": "esquirlas",
		"recompensa_id": "25",
		"recompensa_texto": "+25 Esquirlas Astrales"
	},

	# --- CATEGORÍA 2: COMBATE (8 Hazañas) ---
	"primer_nivel_5": {
		"id": "primer_nivel_5",
		"titulo": "Ascensión Rúnica",
		"desc": "Alcanza el Nivel 5 de personaje en una sola partida.",
		"icono": "⭐",
		"categoria": "combate",
		"recompensa_tipo": "bendicion",
		"recompensa_id": "escudo_espinas",
		"recompensa_texto": "Desbloquea Escudo de Espinas"
	},
	"cazador_heraldo": {
		"id": "cazador_heraldo",
		"titulo": "Cazador de Sombras",
		"desc": "Derrota a tu primer Mini-Jefe o Heraldo del Coliseo.",
		"icono": "💀",
		"categoria": "combate",
		"recompensa_tipo": "bendicion",
		"recompensa_id": "vampirismo_runico",
		"recompensa_texto": "Desbloquea Vampirismo Rúnico"
	},
	"vencedor_parca": {
		"id": "vencedor_parca",
		"titulo": "Trascendencia del Juicio",
		"desc": "Aniquila a La Parca Roja en la prueba final del Coliseo.",
		"icono": "👑",
		"categoria": "combate",
		"recompensa_tipo": "esquirlas",
		"recompensa_id": "50",
		"recompensa_texto": "+50 Esquirlas Astrales"
	},
	"aniquilador_500": {
		"id": "aniquilador_500",
		"titulo": "Segador de la Arena",
		"desc": "Abate a 500 enemigos en una sola run.",
		"icono": "⚔️",
		"categoria": "combate",
		"recompensa_tipo": "bendicion",
		"recompensa_id": "sed_de_sangre",
		"recompensa_texto": "Desbloquea Sed de Sangre"
	},
	"asesino_coloso": {
		"id": "asesino_coloso",
		"titulo": "Derribador de Titanes",
		"desc": "Derrota al Coloso de Bronce antes de la oleada 8.",
		"icono": "🗿",
		"categoria": "combate",
		"recompensa_tipo": "bendicion",
		"recompensa_id": "canon_mercenario",
		"recompensa_texto": "Desbloquea Cañón Mercenario"
	},
	"vencedor_espejo": {
		"id": "vencedor_espejo",
		"titulo": "Ruptura del Reflejo",
		"desc": "Destruye al Espejo Sombrío que emula tus propios ataques.",
		"icono": "🪞",
		"categoria": "combate",
		"recompensa_tipo": "bendicion",
		"recompensa_id": "pulso_estatico",
		"recompensa_texto": "Desbloquea Pulso Estático"
	},
	"cazador_nemesis": {
		"id": "cazador_nemesis",
		"titulo": "Venganza Cumplida",
		"desc": "Localiza y elimina al Némesis que te ejecutó en tu run anterior.",
		"icono": "🩸💀",
		"categoria": "combate",
		"recompensa_tipo": "esquirlas",
		"recompensa_id": "30",
		"recompensa_texto": "+30 Esquirlas Astrales"
	},
	"gladiador_intocable": {
		"id": "gladiador_intocable",
		"titulo": "Danza Espectral",
		"desc": "Supera una oleada completa sin recibir ni un solo impacto de daño.",
		"icono": "💨",
		"categoria": "combate",
		"recompensa_tipo": "bendicion",
		"recompensa_id": "paso_etereo",
		"recompensa_texto": "Desbloquea Paso Etéreo"
	},

	# --- CATEGORÍA 3: CLASE (8 Hazañas) ---
	"maestro_sinergia": {
		"id": "maestro_sinergia",
		"titulo": "Fusión Divina",
		"desc": "Desbloquea y activa tu primera Fusión Mítica Dual.",
		"icono": "✨",
		"categoria": "clase",
		"recompensa_tipo": "bendicion",
		"recompensa_id": "meteoro_orbital",
		"recompensa_texto": "Desbloquea Meteoro Orbital"
	},
	"maestro_guerrero": {
		"id": "maestro_guerrero",
		"titulo": "Muralla de Espartaco",
		"desc": "Alcanza el Nivel 10 jugando con la clase Guerrero.",
		"icono": "🛡️",
		"categoria": "clase",
		"recompensa_tipo": "subclase",
		"recompensa_id": "Paladín Solar",
		"recompensa_texto": "Pista Subclase: Paladín Solar"
	},
	"maestro_cazador": {
		"id": "maestro_cazador",
		"titulo": "Ojo de Halcón",
		"desc": "Alcanza el Nivel 10 jugando con la clase Cazador.",
		"icono": "🏹",
		"categoria": "clase",
		"recompensa_tipo": "bendicion",
		"recompensa_id": "prisma_multidisparo",
		"recompensa_texto": "Desbloquea Prisma Multidisparo"
	},
	"maestro_mago": {
		"id": "maestro_mago",
		"titulo": "Arconte del Vacío",
		"desc": "Alcanza el Nivel 10 jugando con la clase Mago.",
		"icono": "🔮",
		"categoria": "clase",
		"recompensa_tipo": "subclase",
		"recompensa_id": "Archimago del Vacío",
		"recompensa_texto": "Pista Subclase: Archimago del Vacío"
	},
	"todas_sinergias": {
		"id": "todas_sinergias",
		"titulo": "Enciclopedia del Caos",
		"desc": "Descubre las 6 Sinergias Duales Míticas en tu Códice.",
		"icono": "📖✨",
		"categoria": "clase",
		"recompensa_tipo": "esquirlas",
		"recompensa_id": "40",
		"recompensa_texto": "+40 Esquirlas Astrales"
	},
	"subclase_paladin": {
		"id": "subclase_paladin",
		"titulo": "Juramento de Hierro",
		"desc": "Consigue más de 80 armadura plana en combate.",
		"icono": "✝️",
		"categoria": "clase",
		"recompensa_tipo": "subclase",
		"recompensa_id": "Berserker Sangriento",
		"recompensa_texto": "Pista Subclase: Berserker Sangriento"
	},
	"subclase_asesino": {
		"id": "subclase_asesino",
		"titulo": "Corte de Medianoche",
		"desc": "Supera el 60% de probabilidad de golpe crítico en una run.",
		"icono": "🗡️",
		"categoria": "clase",
		"recompensa_tipo": "subclase",
		"recompensa_id": "Maestro de Sombras",
		"recompensa_texto": "Pista Subclase: Maestro de Sombras"
	},
	"subclase_nigromante": {
		"id": "subclase_nigromante",
		"titulo": "Señor de los Caídos",
		"desc": "Alcanza 100 de regeneración de vida o robo vital en una partida.",
		"icono": "☠️",
		"categoria": "clase",
		"recompensa_tipo": "subclase",
		"recompensa_id": "Avatar del Núcleo",
		"recompensa_texto": "Pista Subclase: Avatar del Núcleo"
	},

	# --- CATEGORÍA 4: TORMENTO (8 Hazañas) ---
	"acumulador_oro": {
		"id": "acumulador_oro",
		"titulo": "Tesoro del Gladiador",
		"desc": "Acumula más de 250 de Oro en tus arcas en una sola run.",
		"icono": "🪙",
		"categoria": "tormento",
		"recompensa_tipo": "bendicion",
		"recompensa_id": "moneda_maldita",
		"recompensa_texto": "Desbloquea Moneda Maldita"
	},
	"tormento_1": {
		"id": "tormento_1",
		"titulo": "Pacto Inicial",
		"desc": "Completa una partida victoriosa en Tormento Nivel 1 o superior.",
		"icono": "🩸",
		"categoria": "tormento",
		"recompensa_tipo": "esquirlas",
		"recompensa_id": "15",
		"recompensa_texto": "+15 Esquirlas Astrales"
	},
	"tormento_3": {
		"id": "tormento_3",
		"titulo": "Calvario del Coliseo",
		"desc": "Completa una partida victoriosa en Tormento Nivel 3 o superior.",
		"icono": "🔥💀",
		"categoria": "tormento",
		"recompensa_tipo": "esquirlas",
		"recompensa_id": "25",
		"recompensa_texto": "+25 Esquirlas Astrales"
	},
	"tormento_5": {
		"id": "tormento_5",
		"titulo": "Purgatorio de Sangre",
		"desc": "Sobrevive a la prueba de Tormento Nivel 5 con éxito.",
		"icono": "👑💀",
		"categoria": "tormento",
		"recompensa_tipo": "bendicion",
		"recompensa_id": "toque_de_midas",
		"recompensa_texto": "Desbloquea Toque de Midas"
	},
	"tormento_10": {
		"id": "tormento_10",
		"titulo": "Condenación Absoluta",
		"desc": "Conquista el Coliseo en el nivel máximo: Tormento 10 (+250% peligro, +250% botín).",
		"icono": "☠️🌟",
		"categoria": "tormento",
		"recompensa_tipo": "esquirlas",
		"recompensa_id": "100",
		"recompensa_texto": "+100 Esquirlas Astrales"
	},
	"contrato_sangre": {
		"id": "contrato_sangre",
		"titulo": "Pacto Corrupto",
		"desc": "Acepta y completa un Altar de Bendición Corrupta en combate.",
		"icono": "📜🩸",
		"categoria": "tormento",
		"recompensa_tipo": "esquirlas",
		"recompensa_id": "20",
		"recompensa_texto": "+20 Esquirlas Astrales"
	},
	"superviviente_pacto": {
		"id": "superviviente_pacto",
		"titulo": "Trascendencia del Martirio",
		"desc": "Sobrevive durante 3 minutos portando al menos 2 Bendiciones Corruptas.",
		"icono": "🔮💀",
		"categoria": "tormento",
		"recompensa_tipo": "esquirlas",
		"recompensa_id": "35",
		"recompensa_texto": "+35 Esquirlas Astrales"
	},
	"ascension_astral": {
		"id": "ascension_astral",
		"titulo": "Renacimiento Cósmico",
		"desc": "Ejecuta tu primer Renacimiento Astral en el Árbol de Habilidades.",
		"icono": "✨🌟",
		"categoria": "tormento",
		"recompensa_tipo": "esquirlas",
		"recompensa_id": "50",
		"recompensa_texto": "+50 Esquirlas Astrales"
	}
}

var logros_obtenidos: Dictionary = {}
var nivel_tormento: int = 0
var _config: ConfigFile = ConfigFile.new()

func _ready() -> void:
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
	
	var datos: Dictionary = DEFINICIONES_LOGROS[id]
	_otorgar_recompensa_metaprogreso(datos)
	_mostrar_notificacion_logro(datos)
	
	var dopamina = get_tree().get_first_node_in_group("audio_dopamina")
	if dopamina != null and dopamina.has_method("play_level_up"):
		dopamina.play_level_up()
		
	logro_desbloqueado.emit(id, datos)
	hazana_desbloqueada.emit(id, datos)
	return true

func _otorgar_recompensa_metaprogreso(datos: Dictionary) -> void:
	MetaprogresoManager.asegurar_inicializado()
	var tipo: String = datos.get("recompensa_tipo", "")
	var id_rec: String = datos.get("recompensa_id", "")
	
	match tipo:
		"bendicion":
			MetaprogresoManager.desbloquear_bendicion(id_rec)
		"chasis":
			MetaprogresoManager.desbloquear_chasis(id_rec)
		"esquirlas":
			MetaprogresoManager.agregar_esquirlas(int(id_rec))
		"subclase":
			MetaprogresoManager.registrar_subclase_descubierta(id_rec)

func establecer_tormento(nivel: int) -> void:
	nivel_tormento = clampi(nivel, 0, 10)
	guardar_datos()
	tormento_cambiado.emit(nivel_tormento)
	print("[LogrosManager] Nivel de Tormento establecido en %d/10." % nivel_tormento)

func obtener_tormento() -> int:
	return nivel_tormento

func obtener_multiplicadores_tormento() -> Dictionary:
	return {
		"dano_enemigos": 1.0 + float(nivel_tormento) * 0.25,
		"vida_enemigos": 1.0 + float(nivel_tormento) * 0.35,
		"velocidad_enemigos": 1.0 + float(nivel_tormento) * 0.08,
		"bono_oro_pct": float(nivel_tormento) * 0.25,
		"bono_clics_pct": float(nivel_tormento) * 0.25,
		"bono_suerte": float(nivel_tormento) * 0.20
	}

func cargar_datos() -> void:
	var err = _config.load(RUTA_GUARDADO)
	if err == OK:
		nivel_tormento = clampi(_config.get_value("progresion", "pacto_tormento", 0), 0, 10)
		for id in DEFINICIONES_LOGROS.keys():
			logros_obtenidos[id] = _config.get_value("logros", id, false)
	else:
		nivel_tormento = 0
		for id in DEFINICIONES_LOGROS.keys():
			logros_obtenidos[id] = false

func guardar_datos() -> void:
	_config.set_value("progresion", "pacto_tormento", nivel_tormento)
	for id in logros_obtenidos.keys():
		_config.set_value("logros", id, logros_obtenidos[id])
	_config.save(RUTA_GUARDADO)

func _mostrar_notificacion_logro(datos: Dictionary) -> void:
	var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
	var jugador = get_tree().get_first_node_in_group("player")
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
	if pool_dano != null and jugador != null:
		var txt = "%s ¡HAZAÑA: %s!\n(%s)" % [datos["icono"], datos["titulo"].to_upper(), datos["recompensa_texto"]]
		pool_dano.mostrar_texto(jugador.global_position + Vector3(0, 2.8, 0), txt, Color(1.0, 0.85, 0.2), 1.6)

func obtener_todos_los_logros() -> Dictionary:
	var resultado = {}
	for id in DEFINICIONES_LOGROS.keys():
		var info = DEFINICIONES_LOGROS[id].duplicate()
		info["desbloqueado"] = tiene_logro(id)
		resultado[id] = info
	return resultado

# ==============================================================================
# DISPARADORES DE EVENTOS EN COMBATE & FIN DE PARTIDA
# ==============================================================================
func registrar_fin_partida(es_victoria: bool, bajas_cnt: int, clicks_cnt: int, nivel_num: int) -> void:
	if clicks_cnt > 0:
		desbloquear_logro("primer_clic")
	if clicks_cnt >= 100:
		desbloquear_logro("clic_100")
	if clicks_cnt >= 150:
		desbloquear_logro("clic_chasis_gravitatorio")
	if nivel_num >= 5:
		desbloquear_logro("primer_nivel_5")
	if bajas_cnt >= 500:
		desbloquear_logro("aniquilador_500")
		
	if es_victoria:
		if nivel_tormento >= 1:
			desbloquear_logro("tormento_1")
		if nivel_tormento >= 3:
			desbloquear_logro("tormento_3")
		if nivel_tormento >= 5:
			desbloquear_logro("tormento_5")
		if nivel_tormento >= 10:
			desbloquear_logro("tormento_10")
			
	MetaprogresoManager.asegurar_inicializado()
	if MetaprogresoManager.clics_banco >= 1000:
		desbloquear_logro("maestro_clicker_1000")

func verificar_fiebre_sostenida(segundos_x4: float) -> void:
	if segundos_x4 >= 15.0:
		desbloquear_logro("fiebre_sostenida")

func verificar_estado_combate(pj: Node) -> void:
	if pj == null:
		return
	if "oro" in pj and int(pj.oro) >= 250:
		desbloquear_logro("acumulador_oro")
	if "armadura_plana" in pj and float(pj.armadura_plana) >= 80.0:
		desbloquear_logro("subclase_paladin")
	if "prob_critico" in pj and float(pj.prob_critico) >= 0.60:
		desbloquear_logro("subclase_asesino")
	if MetaprogresoManager.sinergias_descubiertas.size() >= 6:
		desbloquear_logro("todas_sinergias")
	if "regen_vida_seg" in pj and "vida_por_baja" in pj:
		if float(pj.regen_vida_seg) >= 100.0 or (float(pj.regen_vida_seg) + float(pj.vida_por_baja) * 4.0) >= 100.0:
			desbloquear_logro("subclase_nigromante")
	if "nivel" in pj and "clase" in pj:
		var n = int(pj.nivel)
		var c = str(pj.clase)
		var c_base = str(pj.get("clase_base")) if "clase_base" in pj else c
		if n >= 10:
			if c == "Guerrero" or c_base == "Guerrero": desbloquear_logro("maestro_guerrero")
			elif c == "Cazador" or c_base == "Cazador": desbloquear_logro("maestro_cazador")
			elif c == "Mago" or c_base == "Mago": desbloquear_logro("maestro_mago")

func registrar_baja_nemesis() -> void:
	desbloquear_logro("cazador_nemesis")
	MetaprogresoManager.limpiar_nemesis_derrotado()

func registrar_baja_espejo() -> void:
	desbloquear_logro("vencedor_espejo")

func registrar_contrato_completado() -> void:
	desbloquear_logro("contrato_sangre")
