class_name EvolucionManager
extends Node

## EvolucionManager (FSM de Evolución de Clases y Metamorfosis 3D)
## Administra la transición de estados de clase del jugador (Tier 1 y Ascensión Tier 2)
## y el despliegue de la rueda radial 3D in-world preservando bonos de run y árbol.

enum EstadoFSM {
	NOVATO,             # 0: Recluta del Coliseo (Base)
	DISPONIBLE,         # 1: Cumplió hito Tier 1 (listo para elegir clase)
	METAMORFOSIS,       # 2: Modal Tier 1 activo
	EVOLUCIONADO,       # 3: Clase Tier 1 seleccionada (Murmillo / Sagittario / Arúspice)
	ASCENSION_T2_LISTA, # 4: Cumplió hito Tier 2 (Mejora 1 lista)
	ASCENDIDO_TIER_2,   # 5: Mejora Tier 2 seleccionada
	ASCENSION_T3_LISTA, # 6: Cumplió hito Tier 3 (Mejora 2 / Ascensión Definitiva lista)
	ASCENDIDO_TIER_3    # 7: Ascensión Definitiva Tier 3 activa
}

signal metamorfosis_disponible()
signal mejora_tier2_disponible()
signal ascension_tier3_disponible()
signal hito_evolucion_disponible(tier: int, titulo: String, subtitulo: String)
signal progreso_evolucion_actualizado(tier_objetivo: int, texto_progreso: String, listo: bool)
signal clase_evolucionada(nombre_clase: String, stats: Dictionary)
signal mejora_tier2_completada(nombre_mejora: String, stats: Dictionary)
signal subclase_ascendida(nombre_subclase: String, stats: Dictionary)
signal evolucion_tier2_completada(nombre_subclase: String)
signal evolucion_tier3_completada(nombre_subclase: String)
signal evolucion_completada(nombre_subclase: String)
signal malla_cambiada(nuevo_modelo: Node3D)

# Requisitos de Metamorfosis Tier 1 (Minuto 1:30 - 2:00)
@export var hito_nivel: int = 5
@export var hito_clics: int = 30
@export var hito_bajas: int = 25
@export var requiere_todos_los_hitos: bool = true

# Requisitos de Mejora 1 - Tier 2 (Nv.10 + 70 clics)
@export var hito_nivel_tier2: int = 10
@export var hito_clics_tier2: int = 70

# Requisitos de Mejora 2 / Ascensión Definitiva - Tier 3 (Nv.15 + 120 clics)
@export var hito_nivel_tier3: int = 15
@export var hito_clics_tier3: int = 120

const HITO_NIVEL: int = 5
const HITO_CLICS: int = 30
const HITO_BAJAS: int = 25
const HITO_NIVEL_TIER2: int = 10
const HITO_CLICS_TIER2: int = 70
const HITO_NIVEL_TIER3: int = 15
const HITO_CLICS_TIER3: int = 120

const MALLAS_CLASE = {
	"Novato": "res://personaje/player_rookie.glb",
	"Recluta del Coliseo": "res://personaje/player_rookie.glb",
	"Guerrero": "res://personaje/player_warrior.glb",
	"Murmillo": "res://personaje/player_warrior.glb",
	"Cazador": "res://personaje/player_archer.glb",
	"Arquero": "res://personaje/player_archer.glb",
	"Sagittario": "res://personaje/player_archer.glb",
	"Mago": "res://personaje/player_mage.glb",
	"Arúspice": "res://personaje/player_mage.glb",

	# Tier 2 - Mejora 1
	"Secutor Radiante": "res://personaje/player_warrior.glb",
	"Provocator Sangriento": "res://personaje/player_warrior.glb",
	"Velites Balístico": "res://personaje/player_archer.glb",
	"Dimachaerus Espectral": "res://personaje/player_archer.glb",
	"Taumaturgo del Vacío": "res://personaje/player_mage.glb",
	"Flamen Volcánico": "res://personaje/player_mage.glb",
	"Custodio del Núcleo": "res://personaje/player_warrior.glb",

	# Tier 3 - Mejora 2 (Ascensión Suprema)
	"Paladín del Sol Invictus": "res://personaje/player_warrior.glb",
	"Campeón Augusto de Sangre": "res://personaje/player_warrior.glb",
	"Centurión Balístico Astral": "res://personaje/player_archer.glb",
	"Sombra del Anfiteatro": "res://personaje/player_archer.glb",
	"Pontífice del Vacío Estelar": "res://personaje/player_mage.glb",
	"Señor del Magma Imperial": "res://personaje/player_mage.glb",
	"Titán Supremo del Núcleo": "res://personaje/player_warrior.glb",

	# Compatibilidad con nombres anteriores
	"Paladín Solar": "res://personaje/player_warrior.glb",
	"Berserker Sangriento": "res://personaje/player_warrior.glb",
	"Francotirador Astral": "res://personaje/player_archer.glb",
	"Maestro de Sombras": "res://personaje/player_archer.glb",
	"Archimago del Vacío": "res://personaje/player_mage.glb",
	"Piromante Cataclísmico": "res://personaje/player_mage.glb",
	"Avatar del Núcleo": "res://personaje/player_warrior.glb"
}

const STATS_CLASE = {
	"Novato": {
		"nombre": "Recluta del Coliseo",
		"rol": "Condenado de la Arena",
		"descripcion": "Gladiador novato que recién ingresa a la arena monumental.",
		"vida_maxima": 100.0,
		"dano": 10.0,
		"rango_ataque": 2.6,
		"cadencia_ataque": 1.35,
		"speed_caminar": 3.4,
		"speed_correr": 5.4
	},
	"Recluta del Coliseo": {
		"nombre": "Recluta del Coliseo",
		"rol": "Condenado de la Arena",
		"descripcion": "Gladiador novato que recién ingresa a la arena monumental.",
		"vida_maxima": 100.0,
		"dano": 10.0,
		"rango_ataque": 2.6,
		"cadencia_ataque": 1.35,
		"speed_caminar": 3.4,
		"speed_correr": 5.4
	},
	"Murmillo": {
		"nombre": "Murmillo",
		"clase_base": "Guerrero",
		"rol": "Coloso de Acero / Baluarte Melee",
		"descripcion": "Gladiador pesado armado con gran espada y escudo real. Torbellino en 360° y bloqueo de hierro.",
		"vida_maxima": 160.0,
		"dano": 16.0,
		"rango_ataque": 3.2,
		"cadencia_ataque": 0.65,
		"speed_caminar": 3.2,
		"speed_correr": 5.6
	},
	"Guerrero": {
		"nombre": "Murmillo",
		"clase_base": "Guerrero",
		"rol": "Coloso de Acero / Baluarte Melee",
		"descripcion": "Gladiador pesado armado con gran espada y escudo real. Torbellino en 360° y bloqueo de hierro.",
		"vida_maxima": 160.0,
		"dano": 16.0,
		"rango_ataque": 3.2,
		"cadencia_ataque": 0.65,
		"speed_caminar": 3.2,
		"speed_correr": 5.6
	},
	"Sagittario": {
		"nombre": "Sagittario",
		"clase_base": "Cazador",
		"rol": "Arquero Imperial / Ráfaga Balística",
		"descripcion": "Tirador de élite del Coliseo. Dispara andanadas de saetas perforantes en abanico con velocidad extrema.",
		"vida_maxima": 100.0,
		"dano": 12.0,
		"rango_ataque": 7.5,
		"cadencia_ataque": 0.45,
		"speed_caminar": 3.8,
		"speed_correr": 6.4
	},
	"Cazador": {
		"nombre": "Sagittario",
		"clase_base": "Cazador",
		"rol": "Arquero Imperial / Ráfaga Balística",
		"descripcion": "Tirador de élite del Coliseo. Dispara andanadas de saetas perforantes en abanico con velocidad extrema.",
		"vida_maxima": 100.0,
		"dano": 12.0,
		"rango_ataque": 7.5,
		"cadencia_ataque": 0.45,
		"speed_caminar": 3.8,
		"speed_correr": 6.4
	},
	"Arúspice": {
		"nombre": "Arúspice",
		"clase_base": "Mago",
		"rol": "Místico Rúnico / Taumaturgo del Núcleo",
		"descripcion": "Canalizador del poder del Núcleo 3D. Lanza orbes arcanos teledirigidos con detonación en área.",
		"vida_maxima": 85.0,
		"dano": 17.0,
		"rango_ataque": 5.5,
		"cadencia_ataque": 0.70,
		"speed_caminar": 3.3,
		"speed_correr": 5.7
	},
	"Mago": {
		"nombre": "Arúspice",
		"clase_base": "Mago",
		"rol": "Místico Rúnico / Taumaturgo del Núcleo",
		"descripcion": "Canalizador del poder del Núcleo 3D. Lanza orbes arcanos teledirigidos con detonación en área.",
		"vida_maxima": 85.0,
		"dano": 17.0,
		"rango_ataque": 5.5,
		"cadencia_ataque": 0.70,
		"speed_caminar": 3.3,
		"speed_correr": 5.7
	}
}

const SUBCLASES_TIER2 = {
	"Secutor Radiante": {
		"nombre": "Secutor Radiante",
		"clase_base": "Guerrero",
		"rol": "Escudo Solar / Contragolpe Radiante",
		"bonus_vida": 30.0,
		"mult_dano": 1.38,
		"mult_cadencia": 0.92,
		"bonus_armadura": 30.0,
		"descripcion": "Gladiador consagrado al Sol. Su bloqueo levanta una barrera ardiente que calcina y sana."
	},
	"Provocator Sangriento": {
		"nombre": "Provocator Sangriento",
		"clase_base": "Guerrero",
		"rol": "Furia de la Arena / Torbellino Voraz",
		"bonus_vida": 5.0,
		"mult_dano": 1.18,
		"mult_cadencia": 0.74,
		"bonus_armadura": 10.0,
		"descripcion": "Especialista en combate cuerpo a cuerpo feroz. Incrementa su daño y velocidad al perder salud con robo de vida."
	},
	"Velites Balístico": {
		"nombre": "Velites Balístico",
		"clase_base": "Cazador",
		"rol": "Hostigador Táctico / Saetas Perforantes",
		"bonus_vida": 20.0,
		"mult_dano": 1.33,
		"mult_cadencia": 0.84,
		"proyectiles_extra": 1,
		"descripcion": "Arquero táctico de alta precisión con saetas de impacto hipercinético que traspasan las defensas enemigas."
	},
	"Dimachaerus Espectral": {
		"nombre": "Dimachaerus Espectral",
		"clase_base": "Cazador",
		"rol": "Dagas Gemelas / Evasión de la Arena",
		"bonus_vida": 25.0,
		"mult_dano": 1.25,
		"mult_cadencia": 0.75,
		"proyectiles_extra": 1,
		"descripcion": "Gladiador de dos armas que danza entre las sombras con una espiral de dagas y alta agilidad evasiva."
	},
	"Taumaturgo del Vacío": {
		"nombre": "Taumaturgo del Vacío",
		"clase_base": "Mago",
		"rol": "Sifón Gravitacional / Control Cósmico",
		"bonus_vida": 25.0,
		"mult_dano": 1.29,
		"mult_cadencia": 0.97,
		"bonus_aoe": 1.4,
		"descripcion": "Hechicero del anfiteatro cuyos orbes arcanos generan micro-vórtices de atracción gravitatoria."
	},
	"Flamen Volcánico": {
		"nombre": "Flamen Volcánico",
		"clase_base": "Mago",
		"rol": "Sacerdote del Fuego / Magma de la Arena",
		"bonus_vida": 30.0,
		"mult_dano": 1.29,
		"mult_cadencia": 0.97,
		"bonus_aoe": 1.5,
		"descripcion": "Sacerdote ígneo que invoca meteoros sobre la arena, dejando charcos ardientes de lava persistente."
	},
	"Custodio del Núcleo": {
		"nombre": "Custodio del Núcleo",
		"clase_base": "Universal",
		"rol": "Sintonía Rúnica / Pulso del Botón",
		"bonus_vida": 45.0,
		"mult_dano": 1.66,
		"mult_cadencia": 0.61,
		"bonus_armadura": 20.0,
		"descripcion": "Guardián vinculado al Núcleo Móvil. Duplica las ondas expansivas de choque al pulsar el botón."
	},
	# Aliases retrocompatibles
	"Paladín Solar": {
		"nombre": "Secutor Radiante",
		"clase_base": "Guerrero",
		"rol": "Escudo Solar / Contragolpe Radiante",
		"bonus_vida": 50.0,
		"mult_dano": 1.25,
		"mult_cadencia": 0.90,
		"bonus_armadura": 30.0,
		"descripcion": "Gladiador consagrado al Sol. Su bloqueo levanta una barrera ardiente que calcina y sana."
	},
	"Berserker Sangriento": {
		"nombre": "Provocator Sangriento",
		"clase_base": "Guerrero",
		"rol": "Furia de la Arena / Torbellino Voraz",
		"bonus_vida": 35.0,
		"mult_dano": 1.35,
		"mult_cadencia": 0.78,
		"bonus_armadura": 10.0,
		"descripcion": "Especialista en combate cuerpo a cuerpo feroz. Incrementa su daño y velocidad al perder salud con robo de vida."
	},
	"Francotirador Astral": {
		"nombre": "Velites Balístico",
		"clase_base": "Cazador",
		"rol": "Hostigador Táctico / Saetas Perforantes",
		"bonus_vida": 30.0,
		"mult_dano": 1.35,
		"mult_cadencia": 0.88,
		"proyectiles_extra": 1,
		"descripcion": "Arquero táctico de alta precisión con saetas de impacto hipercinético que traspasan las defensas enemigas."
	},
	"Maestro de Sombras": {
		"nombre": "Dimachaerus Espectral",
		"clase_base": "Cazador",
		"rol": "Dagas Gemelas / Evasión de la Arena",
		"bonus_vida": 30.0,
		"mult_dano": 1.25,
		"mult_cadencia": 0.75,
		"proyectiles_extra": 1,
		"descripcion": "Gladiador de dos armas que danza entre las sombras con una espiral de dagas y alta agilidad evasiva."
	},
	"Archimago del Vacío": {
		"nombre": "Taumaturgo del Vacío",
		"clase_base": "Mago",
		"rol": "Sifón Gravitacional / Control Cósmico",
		"bonus_vida": 30.0,
		"mult_dano": 1.30,
		"mult_cadencia": 0.90,
		"bonus_aoe": 1.4,
		"descripcion": "Hechicero del anfiteatro cuyos orbes arcanos generan micro-vórtices de atracción gravitatoria."
	},
	"Piromante Cataclísmico": {
		"nombre": "Flamen Volcánico",
		"clase_base": "Mago",
		"rol": "Sacerdote del Fuego / Magma de la Arena",
		"bonus_vida": 35.0,
		"mult_dano": 1.40,
		"mult_cadencia": 0.90,
		"bonus_aoe": 1.5,
		"descripcion": "Sacerdote ígneo que invoca meteoros sobre la arena, dejando charcos ardientes de lava persistente."
	},
	"Avatar del Núcleo": {
		"nombre": "Custodio del Núcleo",
		"clase_base": "Universal",
		"rol": "Sintonía Rúnica / Pulso del Botón",
		"bonus_vida": 45.0,
		"mult_dano": 1.25,
		"mult_cadencia": 0.85,
		"bonus_armadura": 20.0,
		"descripcion": "Guardián vinculado al Núcleo Móvil. Duplica las ondas expansivas de choque al pulsar el botón."
	}
}

const SUBCLASES_TIER3 = {
	"Paladín del Sol Invictus": {
		"nombre": "Paladín del Sol Invictus",
		"clase_base": "Guerrero",
		"rol": "Baluarte Supremo / Nova Solar Eterna",
		"bonus_vida": 90.0,
		"mult_dano": 2.00,
		"mult_cadencia": 0.80,
		"bonus_armadura": 60.0,
		"descripcion": "El campeón divino de la arena. Cada bloqueo desata una supernova solar devastadora que regenera vida y calcina a todo el coliseo."
	},
	"Campeón Augusto de Sangre": {
		"nombre": "Campeón Augusto de Sangre",
		"clase_base": "Guerrero",
		"rol": "Torbellino Voraz / Dios de la Arena",
		"bonus_vida": 30.0,
		"mult_dano": 1.75,
		"mult_cadencia": 0.61,
		"bonus_armadura": 20.0,
		"descripcion": "Frenesí sangriento absoluto con hachas dobles voraces. Daño sostenido por vida faltante y robo de vida descomunal."
	},
	"Centurión Balístico Astral": {
		"nombre": "Centurión Balístico Astral",
		"clase_base": "Cazador",
		"rol": "Riel Astral / Saetas de Hipervelocidad",
		"bonus_vida": 45.0,
		"mult_dano": 2.00,
		"mult_cadencia": 0.66,
		"proyectiles_extra": 2,
		"descripcion": "Dispara saetas de plasma cósmico a 32 m/s que perforan filas completas de enemigos con daño cataclísmico en línea recta."
	},
	"Sombra del Anfiteatro": {
		"nombre": "Sombra del Anfiteatro",
		"clase_base": "Cazador",
		"rol": "Asesino Espectral / Fantasma del Coliseo",
		"bonus_vida": 50.0,
		"mult_dano": 1.83,
		"mult_cadencia": 0.62,
		"proyectiles_extra": 3,
		"descripcion": "Espiral de 10 dagas espectrales continuas en 360°, +20% probabilidad de crítico y señuelo explosivo que detona con el dash."
	},
	"Pontífice del Vacío Estelar": {
		"nombre": "Pontífice del Vacío Estelar",
		"clase_base": "Mago",
		"rol": "Agujero Negro / Colapso Gravitacional",
		"bonus_vida": 55.0,
		"mult_dano": 1.88,
		"mult_cadencia": 0.88,
		"bonus_aoe": 2.2,
		"descripcion": "Abre singularidades gravitacionales persistentes de 3.0s que succionan implacablemente a las legiones enemigas hacia su destrucción."
	},
	"Señor del Magma Imperial": {
		"nombre": "Señor del Magma Imperial",
		"clase_base": "Mago",
		"rol": "Calamidad Volcánica / Fuego Perpetuo",
		"bonus_vida": 60.0,
		"mult_dano": 1.88,
		"mult_cadencia": 0.88,
		"bonus_aoe": 2.5,
		"descripcion": "Desata lluvias de meteoros titánicos que transforman la arena del Coliseo en un mar de magma ardiente de 3.5s de duración."
	},
	"Titán Supremo del Núcleo": {
		"nombre": "Titán Supremo del Núcleo",
		"clase_base": "Universal",
		"rol": "Avatar de la Resonancia / Clic Cataclísmico",
		"bonus_vida": 80.0,
		"mult_dano": 2.33,
		"mult_cadencia": 0.49,
		"bonus_armadura": 45.0,
		"descripcion": "Comunión absoluta con el Núcleo 3D. Hilos gemelos cuádruples, onda de choque sísmica masiva al hacer clic y daño universal potenciado."
	}
}

const OPCIONES_TIER1 = ["Murmillo", "Sagittario", "Arúspice"]

const OPCIONES_TIER2 = {
	"Guerrero": ["Secutor Radiante", "Provocator Sangriento", "Custodio del Núcleo"],
	"Murmillo": ["Secutor Radiante", "Provocator Sangriento", "Custodio del Núcleo"],
	"Cazador": ["Velites Balístico", "Dimachaerus Espectral", "Custodio del Núcleo"],
	"Sagittario": ["Velites Balístico", "Dimachaerus Espectral", "Custodio del Núcleo"],
	"Mago": ["Taumaturgo del Vacío", "Flamen Volcánico", "Custodio del Núcleo"],
	"Arúspice": ["Taumaturgo del Vacío", "Flamen Volcánico", "Custodio del Núcleo"]
}

const OPCIONES_TIER3 = {
	"Guerrero": ["Paladín del Sol Invictus", "Campeón Augusto de Sangre", "Titán Supremo del Núcleo"],
	"Murmillo": ["Paladín del Sol Invictus", "Campeón Augusto de Sangre", "Titán Supremo del Núcleo"],
	"Cazador": ["Centurión Balístico Astral", "Sombra del Anfiteatro", "Titán Supremo del Núcleo"],
	"Sagittario": ["Centurión Balístico Astral", "Sombra del Anfiteatro", "Titán Supremo del Núcleo"],
	"Mago": ["Pontífice del Vacío Estelar", "Señor del Magma Imperial", "Titán Supremo del Núcleo"],
	"Arúspice": ["Pontífice del Vacío Estelar", "Señor del Magma Imperial", "Titán Supremo del Núcleo"]
}

@export var forzar_modal_2d_fallback: bool = false

var estado_actual: EstadoFSM = EstadoFSM.NOVATO
var total_clics_acumulados: int = 0
var subclase_activa: String = ""
var mejora_tier2_activa: String = ""
var personaje_ref: CharacterBody3D = null
var modal_instancia: Node = null
var tier_menu_activo: int = 1
var _ultimo_progreso_tier: int = -1
var _ultimo_progreso_texto: String = ""
var _ultimo_progreso_listo: bool = false

func _ready():
	add_to_group("evolucion_manager")
	process_mode = Node.PROCESS_MODE_ALWAYS
	if get_parent() is CharacterBody3D:
		configurar_con_personaje(get_parent() as CharacterBody3D)

func _exit_tree():
	_limpiar_modal_actual(true)

func configurar_con_personaje(personaje: CharacterBody3D):
	personaje_ref = personaje
	call_deferred("_vincular_eventos_externos")
	call_deferred("emitir_progreso_evolucion", true)

func _obtener_tree() -> SceneTree:
	if is_inside_tree():
		return get_tree()
	return Engine.get_main_loop() as SceneTree

func _vincular_eventos_externos():
	var tree = _obtener_tree()
	if tree == null:
		return
	var boton = tree.get_first_node_in_group("boton_movil")
	if boton != null and boton.has_signal("click_presionado"):
		if not boton.click_presionado.is_connected(_on_boton_movil_click):
			boton.click_presionado.connect(_on_boton_movil_click)

func _on_boton_movil_click(total_clicks: int):
	total_clics_acumulados = max(total_clics_acumulados, total_clicks)
	_evaluar_hito_evolucion()

func registrar_click():
	var tree = _obtener_tree()
	if tree != null:
		var b = tree.get_first_node_in_group("boton_movil")
		if b != null and "total_clicks" in b and b.total_clicks > total_clics_acumulados:
			total_clics_acumulados = b.total_clicks
		else:
			total_clics_acumulados += 1
	else:
		total_clics_acumulados += 1
	_evaluar_hito_evolucion()

func notificar_nivel(_nuevo_nivel: int):
	_evaluar_hito_evolucion()

func notificar_baja():
	_evaluar_hito_evolucion()

func puede_evolucionar() -> bool:
	if estado_actual != EstadoFSM.NOVATO:
		return false
	var nivel_actual = personaje_ref.nivel if personaje_ref != null else 1
	var bajas_actuales = personaje_ref.bajas if personaje_ref != null else 0
	var clics_reales = max(total_clics_acumulados, personaje_ref.clics_totales if personaje_ref != null else 0)
	
	if requiere_todos_los_hitos:
		return (nivel_actual >= hito_nivel 
			and clics_reales >= hito_clics 
			and bajas_actuales >= hito_bajas)
	else:
		return (nivel_actual >= hito_nivel or clics_reales >= hito_clics)

func puede_ascender_tier2() -> bool:
	if estado_actual != EstadoFSM.EVOLUCIONADO:
		return false
	var nivel_actual = personaje_ref.nivel if personaje_ref != null else 1
	var clics_reales = max(total_clics_acumulados, personaje_ref.clics_totales if personaje_ref != null else 0)
	return nivel_actual >= hito_nivel_tier2 and clics_reales >= hito_clics_tier2

func puede_ascender_tier3() -> bool:
	if estado_actual != EstadoFSM.ASCENDIDO_TIER_2:
		return false
	var nivel_actual = personaje_ref.nivel if personaje_ref != null else 1
	var clics_reales = max(total_clics_acumulados, personaje_ref.clics_totales if personaje_ref != null else 0)
	return nivel_actual >= hito_nivel_tier3 and clics_reales >= hito_clics_tier3

func obtener_texto_progreso_evolucion() -> String:
	var nivel_actual = personaje_ref.nivel if personaje_ref != null else 1
	var bajas_actuales = personaje_ref.bajas if personaje_ref != null else 0
	var clics_reales = max(total_clics_acumulados, personaje_ref.clics_totales if personaje_ref != null else 0)
	
	if estado_actual == EstadoFSM.NOVATO:
		if puede_evolucionar():
			return "¡METAMORFOSIS DISPONIBLE!"
		return "Metamorfosis T1: Nv.%d/%d · Clics:%d/%d · Bajas:%d/%d" % [
			nivel_actual, hito_nivel,
			clics_reales, hito_clics,
			bajas_actuales, hito_bajas
		]
	elif estado_actual == EstadoFSM.EVOLUCIONADO:
		if puede_ascender_tier2():
			return "¡MEJORA T2 DISPONIBLE!"
		return "Mejora T2: Nv.%d/%d · Clics:%d/%d" % [
			nivel_actual, hito_nivel_tier2,
			clics_reales, hito_clics_tier2
		]
	elif estado_actual == EstadoFSM.ASCENDIDO_TIER_2:
		if puede_ascender_tier3():
			return "¡ASCENSIÓN T3 DEFINITIVA!"
		return "Ascensión T3: Nv.%d/%d · Clics:%d/%d" % [
			nivel_actual, hito_nivel_tier3,
			clics_reales, hito_clics_tier3
		]
	elif estado_actual == EstadoFSM.ASCENDIDO_TIER_3:
		return "👑 " + subclase_activa
	return ""

func obtener_estado_progreso_compacto() -> Dictionary:
	var nivel_actual: int = int(personaje_ref.nivel) if personaje_ref != null else 1
	var bajas_actuales: int = int(personaje_ref.bajas) if personaje_ref != null else 0
	var clics_reales: int = maxi(total_clics_acumulados, int(personaje_ref.clics_totales) if personaje_ref != null else 0)

	match estado_actual:
		EstadoFSM.NOVATO:
			var listo_t1: bool = puede_evolucionar()
			var txt_t1: String = "✨ T1 LISTA [V]" if listo_t1 else "T1: Nv.%d/%d · %d/%d⚡ · %d/%d💀" % [
				nivel_actual, hito_nivel, clics_reales, hito_clics, bajas_actuales, hito_bajas
			]
			return {"tier_objetivo": 1, "texto": txt_t1, "listo": listo_t1}
		EstadoFSM.DISPONIBLE, EstadoFSM.METAMORFOSIS:
			return {"tier_objetivo": 1, "texto": "✨ T1 LISTA [V]", "listo": true}
		EstadoFSM.EVOLUCIONADO:
			var listo_t2: bool = puede_ascender_tier2()
			var txt_t2: String = "👑 T2 LISTA [V]" if listo_t2 else "T2: Nv.%d/%d · %d/%d⚡" % [
				nivel_actual, hito_nivel_tier2, clics_reales, hito_clics_tier2
			]
			return {"tier_objetivo": 2, "texto": txt_t2, "listo": listo_t2}
		EstadoFSM.ASCENSION_T2_LISTA:
			return {"tier_objetivo": 2, "texto": "👑 T2 LISTA [V]", "listo": true}
		EstadoFSM.ASCENDIDO_TIER_2:
			var listo_t3: bool = puede_ascender_tier3()
			var txt_t3: String = "🌟 T3 LISTA [V]" if listo_t3 else "T3: Nv.%d/%d · %d/%d⚡" % [
				nivel_actual, hito_nivel_tier3, clics_reales, hito_clics_tier3
			]
			return {"tier_objetivo": 3, "texto": txt_t3, "listo": listo_t3}
		EstadoFSM.ASCENSION_T3_LISTA:
			return {"tier_objetivo": 3, "texto": "🌟 T3 LISTA [V]", "listo": true}
		_:
			return {"tier_objetivo": 0, "texto": "", "listo": false}

func emitir_progreso_evolucion(forzar: bool = false) -> void:
	var info: Dictionary = obtener_estado_progreso_compacto()
	var tier_obj: int = int(info.get("tier_objetivo", 0))
	var texto: String = str(info.get("texto", ""))
	var listo: bool = bool(info.get("listo", false))
	if not forzar and tier_obj == _ultimo_progreso_tier and texto == _ultimo_progreso_texto and listo == _ultimo_progreso_listo:
		return
	_ultimo_progreso_tier = tier_obj
	_ultimo_progreso_texto = texto
	_ultimo_progreso_listo = listo
	emit_signal("progreso_evolucion_actualizado", tier_obj, texto, listo)

func tiene_evolucion_pendiente() -> int:
	if estado_actual == EstadoFSM.DISPONIBLE or estado_actual == EstadoFSM.METAMORFOSIS or (estado_actual == EstadoFSM.NOVATO and puede_evolucionar()):
		return 1
	if estado_actual == EstadoFSM.ASCENSION_T2_LISTA or (estado_actual == EstadoFSM.EVOLUCIONADO and puede_ascender_tier2()):
		return 2
	if estado_actual == EstadoFSM.ASCENSION_T3_LISTA or (estado_actual == EstadoFSM.ASCENDIDO_TIER_2 and puede_ascender_tier3()):
		return 3
	return 0

## Reabre la rueda 3D o modal 2D si el jugador tiene una evolución disponible o pendiente
func reabrir_evolucion_pendiente() -> bool:
	if estado_actual == EstadoFSM.NOVATO and puede_evolucionar():
		disparar_metamorfosis()
		return true
	if estado_actual == EstadoFSM.DISPONIBLE or estado_actual == EstadoFSM.METAMORFOSIS:
		abrir_modal_evolucion(1)
		return true
	if estado_actual == EstadoFSM.EVOLUCIONADO and puede_ascender_tier2():
		disparar_ascension_tier2()
		return true
	if estado_actual == EstadoFSM.ASCENSION_T2_LISTA:
		abrir_modal_evolucion(2)
		return true
	if estado_actual == EstadoFSM.ASCENDIDO_TIER_2 and puede_ascender_tier3():
		disparar_ascension_tier3()
		return true
	if estado_actual == EstadoFSM.ASCENSION_T3_LISTA:
		abrir_modal_evolucion(3)
		return true
	return false

func _evaluar_hito_evolucion():
	if estado_actual == EstadoFSM.NOVATO and puede_evolucionar():
		disparar_metamorfosis()
	elif estado_actual == EstadoFSM.EVOLUCIONADO and puede_ascender_tier2():
		disparar_ascension_tier2()
	elif estado_actual == EstadoFSM.ASCENDIDO_TIER_2 and puede_ascender_tier3():
		disparar_ascension_tier3()
	emitir_progreso_evolucion()

func disparar_metamorfosis():
	if estado_actual != EstadoFSM.NOVATO:
		return
	
	estado_actual = EstadoFSM.DISPONIBLE
	tier_menu_activo = 1
	emit_signal("metamorfosis_disponible")
	emit_signal("hito_evolucion_disponible", 1, "✨ METAMORFOSIS TIER 1 DISPONIBLE", "Elige tu clase de la Arena · Clic o [V]")
	emitir_progreso_evolucion()
	
	AudioManager.play("altar_activado", 1.25, 2.0)
	if personaje_ref != null and personaje_ref.has_method("_spawn_texto_3d"):
		personaje_ref._spawn_texto_3d("✨ ¡METAMORFOSIS HEROICA TIER 1!", Color(1.0, 0.85, 0.2))
		
	abrir_modal_evolucion(1)

func disparar_ascension_tier2():
	if estado_actual != EstadoFSM.EVOLUCIONADO:
		return
	
	estado_actual = EstadoFSM.ASCENSION_T2_LISTA
	tier_menu_activo = 2
	emit_signal("mejora_tier2_disponible")
	emit_signal("hito_evolucion_disponible", 2, "👑 ASCENSIÓN TIER 2 DISPONIBLE", "Especializa %s en la Arena · Clic o [V]" % _obtener_arquetipo_base_personaje())
	emitir_progreso_evolucion()
	
	AudioManager.play("altar_activado", 1.35, 2.0)
	if personaje_ref != null and personaje_ref.has_method("_spawn_texto_3d"):
		personaje_ref._spawn_texto_3d("⚔️ ¡MEJORA DE CLASE TIER 2 DISPONIBLE!", Color(1.0, 0.85, 0.2))
		
	abrir_modal_evolucion(2)

func disparar_ascension_tier3():
	if estado_actual != EstadoFSM.ASCENDIDO_TIER_2:
		return
		
	estado_actual = EstadoFSM.ASCENSION_T3_LISTA
	tier_menu_activo = 3
	emit_signal("ascension_tier3_disponible")
	emit_signal("hito_evolucion_disponible", 3, "🌟 ASCENSIÓN DEFINITIVA TIER 3 DISPONIBLE", "Desata la forma suprema de %s · Clic o [V]" % _obtener_arquetipo_base_personaje())
	emitir_progreso_evolucion()
	
	AudioManager.play("altar_activado", 1.45, 2.5)
	if personaje_ref != null and personaje_ref.has_method("_spawn_texto_3d"):
		personaje_ref._spawn_texto_3d("👑 ¡ASCENSIÓN DEFINITIVA TIER 3 DISPONIBLE!", Color(1.0, 0.85, 0.2))
		
	abrir_modal_evolucion(3)

## Métodos públicos para el panel de depuración F3
func forzar_rueda_tier2():
	if personaje_ref == null:
		return
	if estado_actual == EstadoFSM.NOVATO or estado_actual == EstadoFSM.DISPONIBLE or estado_actual == EstadoFSM.METAMORFOSIS:
		if modal_instancia != null and is_instance_valid(modal_instancia) and modal_instancia.has_method("cerrar"):
			modal_instancia.cerrar()
		estado_actual = EstadoFSM.NOVATO
		evolucionar_a("Murmillo")
	elif estado_actual == EstadoFSM.ASCENDIDO_TIER_2 or estado_actual == EstadoFSM.ASCENDIDO_TIER_3:
		estado_actual = EstadoFSM.EVOLUCIONADO
	if estado_actual == EstadoFSM.EVOLUCIONADO:
		disparar_ascension_tier2()

func forzar_rueda_tier3():
	if personaje_ref == null:
		return
	if estado_actual == EstadoFSM.NOVATO or estado_actual == EstadoFSM.DISPONIBLE or estado_actual == EstadoFSM.METAMORFOSIS:
		if modal_instancia != null and is_instance_valid(modal_instancia) and modal_instancia.has_method("cerrar"):
			modal_instancia.cerrar()
		estado_actual = EstadoFSM.NOVATO
		evolucionar_a("Murmillo")
	if estado_actual == EstadoFSM.EVOLUCIONADO or estado_actual == EstadoFSM.ASCENSION_T2_LISTA:
		ascender_a_subclase_tier2("Secutor Radiante")
	if estado_actual == EstadoFSM.ASCENDIDO_TIER_2 or estado_actual == EstadoFSM.ASCENDIDO_TIER_3:
		estado_actual = EstadoFSM.ASCENDIDO_TIER_2
		disparar_ascension_tier3()

## Método público de depuración para probar el modal 2D de respaldo en Tier 1, Tier 2 o Tier 3
func forzar_modal_2d_evolucion(tier: int = 1, clase_base_override: String = ""):
	if tier <= 1:
		estado_actual = EstadoFSM.NOVATO
	else:
		if personaje_ref != null and is_instance_valid(personaje_ref) and clase_base_override != "":
			if "clase_base" in personaje_ref:
				personaje_ref.clase_base = clase_base_override
			if "clase" in personaje_ref:
				personaje_ref.clase = clase_base_override
		estado_actual = EstadoFSM.EVOLUCIONADO if tier == 2 else EstadoFSM.ASCENDIDO_TIER_2
	abrir_modal_evolucion(tier, true)

func abrir_modal_evolucion(tier: int = 1, forzar_2d: bool = false):
	tier_menu_activo = tier
	if tier == 1:
		estado_actual = EstadoFSM.METAMORFOSIS
	elif tier == 2:
		estado_actual = EstadoFSM.ASCENSION_T2_LISTA
	else:
		estado_actual = EstadoFSM.ASCENSION_T3_LISTA

	var usar_solo_2d: bool = forzar_2d or forzar_modal_2d_fallback
	var base_clase: String = _obtener_arquetipo_base_personaje()

	if modal_instancia != null and is_instance_valid(modal_instancia):
		if usar_solo_2d and not (modal_instancia is CanvasLayer):
			if modal_instancia.has_method("cerrar"):
				modal_instancia.cerrar()
			modal_instancia = null
		else:
			if modal_instancia.has_signal("evolucion_seleccionada") and not modal_instancia.evolucion_seleccionada.is_connected(_on_clase_elegida_en_modal):
				modal_instancia.evolucion_seleccionada.connect(_on_clase_elegida_en_modal)
			elif modal_instancia.has_signal("clase_seleccionada") and not modal_instancia.clase_seleccionada.is_connected(_on_clase_elegida_en_modal):
				modal_instancia.clase_seleccionada.connect(_on_clase_elegida_en_modal)
			if modal_instancia.has_method("configurar_modo_tier"):
				modal_instancia.configurar_modo_tier(tier, base_clase)
			if modal_instancia.has_method("abrir"):
				modal_instancia.abrir()
			return

	if not usar_solo_2d and personaje_ref != null and is_instance_valid(personaje_ref):
		var radial = personaje_ref.get_node_or_null("EvolucionRadial")
		if radial == null:
			var escena_radial = load("res://evolucion_radial.tscn")
			if escena_radial != null:
				radial = escena_radial.instantiate()
				radial.name = "EvolucionRadial"
				personaje_ref.add_child(radial)
				radial.personaje_padre = personaje_ref
		if radial != null:
			modal_instancia = radial
			if radial.has_method("configurar_modo_tier"):
				radial.configurar_modo_tier(tier, base_clase)
			if not radial.evolucion_seleccionada.is_connected(_on_clase_elegida_en_modal):
				radial.evolucion_seleccionada.connect(_on_clase_elegida_en_modal)
			radial.abrir()
			return

	var tree = _obtener_tree()
	if tree == null or tree.root == null:
		return

	var modal_existente = tree.root.get_node_or_null("ModalEvolucionFallback")
	if modal_existente != null and is_instance_valid(modal_existente):
		modal_instancia = modal_existente
	else:
		var escena_modal = load("res://modal_evolucion.tscn")
		if escena_modal == null:
			return
		modal_instancia = escena_modal.instantiate()
		modal_instancia.name = "ModalEvolucionFallback"
		tree.root.add_child(modal_instancia)

	if modal_instancia.has_signal("clase_seleccionada"):
		if not modal_instancia.clase_seleccionada.is_connected(_on_clase_elegida_en_modal):
			modal_instancia.clase_seleccionada.connect(_on_clase_elegida_en_modal)
	if modal_instancia.has_method("configurar_modo_tier"):
		modal_instancia.configurar_modo_tier(tier, base_clase)
	if modal_instancia.has_method("abrir"):
		modal_instancia.abrir()
	return

func _limpiar_modal_actual(diferir_remocion: bool = false):
	if modal_instancia == null or not is_instance_valid(modal_instancia):
		modal_instancia = null
		return
	if modal_instancia.has_method("cerrar"):
		modal_instancia.cerrar()
	if modal_instancia is CanvasLayer:
		if modal_instancia.has_signal("clase_seleccionada") and modal_instancia.clase_seleccionada.is_connected(_on_clase_elegida_en_modal):
			modal_instancia.clase_seleccionada.disconnect(_on_clase_elegida_en_modal)
		if not diferir_remocion and modal_instancia.get_parent() != null:
			modal_instancia.get_parent().remove_child(modal_instancia)
		modal_instancia.queue_free()
	modal_instancia = null

func _obtener_arquetipo_base_personaje() -> String:
	if personaje_ref == null:
		return "Murmillo"
	if "clase_base" in personaje_ref and personaje_ref.clase_base != "Novato" and personaje_ref.clase_base != "":
		return personaje_ref.clase_base
	if personaje_ref.clase != "Novato" and personaje_ref.clase != "":
		return personaje_ref.clase
	return "Murmillo"

func _on_clase_elegida_en_modal(nombre_opcion: String):
	_limpiar_modal_actual()
	var tree = _obtener_tree()
	if tree != null:
		tree.paused = false
		
	if tier_menu_activo == 3 or SUBCLASES_TIER3.has(nombre_opcion):
		ascender_a_tier3(nombre_opcion)
	elif tier_menu_activo == 2 or SUBCLASES_TIER2.has(nombre_opcion):
		ascender_a_subclase_tier2(nombre_opcion)
	else:
		evolucionar_a(nombre_opcion)

func evolucionar_a(nombre_clase: String):
	if estado_actual == EstadoFSM.EVOLUCIONADO or estado_actual == EstadoFSM.ASCENDIDO_TIER_2 or estado_actual == EstadoFSM.ASCENDIDO_TIER_3:
		return
	if not STATS_CLASE.has(nombre_clase):
		push_error("Clase desconocida para evolución: " + nombre_clase)
		return
	
	estado_actual = EstadoFSM.EVOLUCIONADO
	var stats = STATS_CLASE[nombre_clase]
	
	if personaje_ref != null:
		if personaje_ref.has_method("aplicar_clase"):
			personaje_ref.aplicar_clase(nombre_clase)
		
		var nodo_salud = personaje_ref.get_node_or_null("Salud")
		if nodo_salud != null:
			if "vida" in nodo_salud:
				nodo_salud.vida = int(personaje_ref.vida)
			if "vida_inicial" in nodo_salud:
				nodo_salud.vida_inicial = int(personaje_ref.vida_maxima)
		
		var ruta_malla = MALLAS_CLASE.get(nombre_clase, "")
		if ruta_malla != "":
			var nuevo_anim = cambiar_malla_3d(personaje_ref, ruta_malla)
			if nuevo_anim != null:
				personaje_ref.anim = nuevo_anim
				personaje_ref.animar()
		_aplicar_visual_tier(personaje_ref, nombre_clase, 1)
		
		_emitir_feedback_metamorfosis(nombre_clase)
		
		personaje_ref.emit_signal("stats_actualizadas",
			personaje_ref.vida,
			personaje_ref.vida_maxima,
			personaje_ref.xp,
			personaje_ref.xp_siguiente_nivel,
			personaje_ref.nivel,
			personaje_ref.oro,
			personaje_ref.bajas
		)
	
	emit_signal("clase_evolucionada", nombre_clase, stats)
	emit_signal("evolucion_completada", nombre_clase)
	_evaluar_hito_evolucion()

func ascender_a_subclase_tier2(nombre_subclase: String):
	if estado_actual == EstadoFSM.ASCENDIDO_TIER_2 or estado_actual == EstadoFSM.ASCENDIDO_TIER_3 or personaje_ref == null:
		return
	var datos_t2 = SUBCLASES_TIER2.get(nombre_subclase, null)
	if datos_t2 == null:
		push_error("Subclase desconocida para Tier 2: " + nombre_subclase)
		return
		
	estado_actual = EstadoFSM.ASCENDIDO_TIER_2
	mejora_tier2_activa = nombre_subclase
	subclase_activa = nombre_subclase
	
	if personaje_ref.has_method("aplicar_mejora_tier2"):
		personaje_ref.aplicar_mejora_tier2(nombre_subclase)
	elif personaje_ref.has_method("aplicar_subclase_tier2"):
		personaje_ref.aplicar_subclase_tier2(nombre_subclase)
	elif personaje_ref.has_method("aplicar_clase"):
		personaje_ref.aplicar_clase(nombre_subclase)
		
	if "bono_run_vida_plana" in personaje_ref:
		personaje_ref.bono_run_vida_plana += float(datos_t2.get("bonus_vida", 40.0))
	if "bono_run_dano_mult" in personaje_ref:
		personaje_ref.bono_run_dano_mult *= float(datos_t2.get("mult_dano", 1.25))
	if "bono_run_cadencia_mult" in personaje_ref:
		personaje_ref.bono_run_cadencia_mult *= float(datos_t2.get("mult_cadencia", 0.90))
	if "bono_run_armadura_plana" in personaje_ref and datos_t2.has("bonus_armadura"):
		personaje_ref.bono_run_armadura_plana += float(datos_t2["bonus_armadura"])
	if "bono_run_proyectiles_extra" in personaje_ref and datos_t2.has("proyectiles_extra"):
		personaje_ref.bono_run_proyectiles_extra += int(datos_t2["proyectiles_extra"])
		
	if personaje_ref.has_method("recalcular_stats_incrementales"):
		personaje_ref.recalcular_stats_incrementales()
	personaje_ref.vida = personaje_ref.vida_maxima
	
	if personaje_ref.has_method("equipar_armas_clase"):
		personaje_ref.equipar_armas_clase(nombre_subclase)
	_aplicar_visual_tier(personaje_ref, nombre_subclase, 2)
	
	MetaprogresoManager.registrar_subclase_descubierta(nombre_subclase)
		
	var tree = _obtener_tree()
	if tree != null:
		var lm = tree.get_first_node_in_group("logros_manager")
		if lm != null and lm.has_method("notificar_subclase"):
			lm.notificar_subclase(nombre_subclase)
	
	AudioManager.play("victoria", 1.25)
	if personaje_ref.has_method("_spawn_texto_3d"):
		personaje_ref._spawn_texto_3d("⚔️ ¡MEJORA TIER 2: %s!" % subclase_activa.to_upper(), Color(1.0, 0.85, 0.2))
		
	emit_signal("subclase_ascendida", subclase_activa, datos_t2)
	emit_signal("mejora_tier2_completada", subclase_activa, datos_t2)
	emit_signal("evolucion_tier2_completada", subclase_activa)
	emit_signal("evolucion_completada", subclase_activa)
	_evaluar_hito_evolucion()

func ascender_a_tier3(nombre_subclase: String):
	if estado_actual == EstadoFSM.ASCENDIDO_TIER_3 or personaje_ref == null:
		return
	var datos_t3 = SUBCLASES_TIER3.get(nombre_subclase, null)
	if datos_t3 == null:
		datos_t3 = SUBCLASES_TIER2.get(nombre_subclase, null)
	if datos_t3 == null:
		push_error("Subclase desconocida para Tier 3: " + nombre_subclase)
		return

	estado_actual = EstadoFSM.ASCENDIDO_TIER_3
	subclase_activa = nombre_subclase

	if personaje_ref.has_method("aplicar_subclase_tier3"):
		personaje_ref.aplicar_subclase_tier3(nombre_subclase)
	elif personaje_ref.has_method("aplicar_subclase_tier2"):
		personaje_ref.aplicar_subclase_tier2(nombre_subclase)
	elif personaje_ref.has_method("aplicar_clase"):
		personaje_ref.aplicar_clase(nombre_subclase)

	if "bono_run_vida_plana" in personaje_ref:
		personaje_ref.bono_run_vida_plana += float(datos_t3.get("bonus_vida", 75.0))
	if "bono_run_dano_mult" in personaje_ref:
		personaje_ref.bono_run_dano_mult *= float(datos_t3.get("mult_dano", 1.45))
	if "bono_run_cadencia_mult" in personaje_ref:
		personaje_ref.bono_run_cadencia_mult *= float(datos_t3.get("mult_cadencia", 0.80))
	if "bono_run_armadura_plana" in personaje_ref and datos_t3.has("bonus_armadura"):
		personaje_ref.bono_run_armadura_plana += float(datos_t3["bonus_armadura"])
	if "bono_run_proyectiles_extra" in personaje_ref and datos_t3.has("proyectiles_extra"):
		personaje_ref.bono_run_proyectiles_extra += int(datos_t3["proyectiles_extra"])

	if personaje_ref.has_method("recalcular_stats_incrementales"):
		personaje_ref.recalcular_stats_incrementales()
	personaje_ref.vida = personaje_ref.vida_maxima

	if personaje_ref.has_method("equipar_armas_clase"):
		personaje_ref.equipar_armas_clase(nombre_subclase)
	_aplicar_visual_tier(personaje_ref, nombre_subclase, 3)

	MetaprogresoManager.registrar_subclase_descubierta(nombre_subclase)

	var tree = _obtener_tree()
	if tree != null:
		var lm = tree.get_first_node_in_group("logros_manager")
		if lm != null and lm.has_method("notificar_subclase"):
			lm.notificar_subclase(nombre_subclase)

	AudioManager.play("victoria", 1.40)
	if personaje_ref.has_method("_spawn_texto_3d"):
		personaje_ref._spawn_texto_3d("👑 ¡ASCENSIÓN TIER 3 DEFINITIVA: %s!" % subclase_activa.to_upper(), Color(1.0, 0.85, 0.2))

	emit_signal("subclase_ascendida", subclase_activa, datos_t3)
	emit_signal("evolucion_tier3_completada", subclase_activa)
	emit_signal("evolucion_completada", subclase_activa)
	emitir_progreso_evolucion()

func cambiar_malla_3d(personaje: CharacterBody3D, ruta_malla: String) -> AnimationPlayer:
	if not ResourceLoader.exists(ruta_malla):
		push_error("No se encontró recurso de malla: " + ruta_malla)
		return null
	
	var escena_glb = load(ruta_malla)
	if escena_glb == null:
		push_error("Fallo al instanciar modelo .glb: " + ruta_malla)
		return null
	
	var modelo_actual = personaje.get_node_or_null("Modelo")
	var transform_base = Transform3D(Basis(Vector3(-5.5, 0.0, 0.0), Vector3(0.0, 5.5, 0.0), Vector3(0.0, 0.0, -5.5)), Vector3.ZERO)
	
	if modelo_actual != null:
		transform_base = modelo_actual.transform
		modelo_actual.name = "Modelo_Antiguo"
		personaje.remove_child(modelo_actual)
		modelo_actual.queue_free()
	
	var nuevo_modelo = escena_glb.instantiate()
	nuevo_modelo.name = "Modelo"
	nuevo_modelo.transform = transform_base
	personaje.add_child(nuevo_modelo)
	AnimadorEntidad.estilizar_entidad_visual(nuevo_modelo, true)
	
	var nuevo_anim = AnimadorEntidad.buscar_animation_player(nuevo_modelo)
	if nuevo_anim == null:
		push_warning("El modelo nuevo %s no contiene nodo AnimationPlayer" % ruta_malla)
	emit_signal("malla_cambiada", nuevo_modelo)
	return nuevo_anim

func _emitir_feedback_metamorfosis(nombre_clase: String):
	if personaje_ref == null or not personaje_ref.is_inside_tree():
		return
	if personaje_ref.has_method("_spawn_texto_3d"):
		personaje_ref._spawn_texto_3d("¡EVOLUCIÓN A %s!" % nombre_clase.to_upper(), Color(1.0, 0.9, 0.3))
	
	var luz = OmniLight3D.new()
	luz.light_color = Color(1.0, 0.9, 0.4)
	luz.light_energy = 3.5
	luz.omni_range = 8.0
	personaje_ref.add_child(luz)
	luz.position = Vector3(0, 1.2, 0)
	
	var tween = personaje_ref.create_tween()
	if tween != null:
		tween.tween_property(luz, "light_energy", 0.0, 0.65)
		tween.tween_callback(luz.queue_free)
	else:
		luz.queue_free()


const PALETA_VISUAL_TIER := {
	"Secutor Radiante": {"accent": Color(0.95, 0.72, 0.16), "core": Color(1.00, 0.86, 0.30)},
	"Paladín Solar": {"accent": Color(0.95, 0.72, 0.16), "core": Color(1.00, 0.86, 0.30)},
	"Paladín del Sol Invictus": {"accent": Color(1.00, 0.82, 0.24), "core": Color(1.00, 0.94, 0.45)},
	"Provocator Sangriento": {"accent": Color(0.88, 0.18, 0.16), "core": Color(1.00, 0.32, 0.24)},
	"Berserker Sangriento": {"accent": Color(0.88, 0.18, 0.16), "core": Color(1.00, 0.32, 0.24)},
	"Campeón Augusto de Sangre": {"accent": Color(0.96, 0.14, 0.18), "core": Color(1.00, 0.28, 0.32)},
	"Velites Balístico": {"accent": Color(0.18, 0.76, 0.96), "core": Color(0.32, 0.92, 1.00)},
	"Francotirador Astral": {"accent": Color(0.18, 0.76, 0.96), "core": Color(0.32, 0.92, 1.00)},
	"Centurión Balístico Astral": {"accent": Color(0.36, 0.88, 1.00), "core": Color(0.62, 0.98, 1.00)},
	"Dimachaerus Espectral": {"accent": Color(0.16, 0.86, 0.56), "core": Color(0.28, 0.96, 0.68)},
	"Asesino Espectral": {"accent": Color(0.16, 0.86, 0.56), "core": Color(0.28, 0.96, 0.68)},
	"Sombra del Anfiteatro": {"accent": Color(0.22, 0.95, 0.64), "core": Color(0.45, 1.00, 0.80)},
	"Taumaturgo del Vacío": {"accent": Color(0.58, 0.28, 0.96), "core": Color(0.76, 0.45, 1.00)},
	"Pontífice del Vacío Estelar": {"accent": Color(0.68, 0.32, 1.00), "core": Color(0.86, 0.58, 1.00)},
	"Flamen Volcánico": {"accent": Color(0.96, 0.42, 0.12), "core": Color(1.00, 0.65, 0.22)},
	"Señor del Magma Imperial": {"accent": Color(1.00, 0.38, 0.08), "core": Color(1.00, 0.72, 0.18)},
	"Custodio del Núcleo": {"accent": Color(0.22, 0.88, 0.86), "core": Color(0.45, 1.00, 0.95)},
	"Titán Supremo del Núcleo": {"accent": Color(0.98, 0.86, 0.34), "core": Color(0.38, 1.00, 0.96)},
}


class OrnamentoTierRotator:
	extends Node3D

	var anillo_exterior: MeshInstance3D = null
	var anillo_interior: MeshInstance3D = null
	var orbita_cristales: Node3D = null
	var cristales: Array[MeshInstance3D] = []
	var _t: float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		if anillo_exterior != null:
			anillo_exterior.rotation.y += delta * 0.42
		if anillo_interior != null:
			anillo_interior.rotation.y -= delta * 0.75
		if orbita_cristales != null:
			orbita_cristales.rotation.y += delta * 0.95
		for i in range(cristales.size()):
			var c: MeshInstance3D = cristales[i]
			if c != null:
				c.position.y = sin(_t * 2.4 + float(i) * (TAU / 3.0)) * 0.09
				c.rotation.y += delta * 1.4
				c.rotation.x += delta * 0.6


static func _generar_textura_runa_tier(color_runa: Color, es_tier3: bool) -> ImageTexture:
	var sz: int = 256
	var img: Image = Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var center: float = float(sz - 1) * 0.5
	for y in range(sz):
		for x in range(sz):
			var dx: float = (float(x) - center) / center
			var dy: float = (float(y) - center) / center
			var r: float = sqrt(dx * dx + dy * dy)
			var ang: float = atan2(dy, dx)
			var alpha: float = 0.0
			# Anillo exterior sagrado
			if absf(r - 0.88) < 0.032:
				alpha = maxf(alpha, clampf(1.0 - absf(r - 0.88) / 0.032, 0.0, 1.0))
			# Segundo anillo o patrón octogonal Tier 3
			var r_inner: float = 0.68 if es_tier3 else 0.72
			if absf(r - r_inner) < 0.022:
				alpha = maxf(alpha, 0.75 * clampf(1.0 - absf(r - r_inner) / 0.022, 0.0, 1.0))
			# Muescas rúnicas radiales (8 u 12 según tier)
			var spokes: float = 12.0 if es_tier3 else 8.0
			if r > 0.69 and r < 0.92:
				var tooth: float = absf(sin(ang * spokes * 0.5))
				if tooth > 0.94:
					alpha = maxf(alpha, 0.90)
			# Cuadrado/rombo interior rotado
			if es_tier3:
				var diamond_d: float = absf(dx) + absf(dy)
				if absf(diamond_d - 0.84) < 0.026:
					alpha = maxf(alpha, 0.72)
			var col: Color = Color(color_runa.r, color_runa.g, color_runa.b, clampf(alpha, 0.0, 0.92))
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _construir_octaedro_cristal() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(0.0, 0.14, 0.0)
	var bot := Vector3(0.0, -0.14, 0.0)
	var ring: Array[Vector3] = [
		Vector3(0.08, 0.0, 0.0),
		Vector3(0.0, 0.0, 0.08),
		Vector3(-0.08, 0.0, 0.0),
		Vector3(0.0, 0.0, -0.08),
	]
	for i in range(4):
		var p0: Vector3 = ring[i]
		var p1: Vector3 = ring[(i + 1) % 4]
		st.add_vertex(top)
		st.add_vertex(p1)
		st.add_vertex(p0)
		st.add_vertex(bot)
		st.add_vertex(p0)
		st.add_vertex(p1)
	st.index()
	st.generate_normals()
	return st.commit()


static func _duplicar_material_tier(mat_orig: Material, accent_col: Color, core_col: Color, tier: int) -> StandardMaterial3D:
	if not (mat_orig is StandardMaterial3D):
		return null
	var sm := mat_orig as StandardMaterial3D
	var rname: String = sm.resource_name
	if not (rname.contains("TierAccent") or rname.contains("TierCore")):
		return null
	var dup := sm.duplicate() as StandardMaterial3D
	dup.resource_name = sm.resource_name
	dup.next_pass = sm.next_pass
	if rname.contains("TierAccent"):
		if dup.albedo_texture != null:
			dup.albedo_color = accent_col.lightened(0.22)
		else:
			dup.albedo_color = dup.albedo_color.lerp(accent_col, 0.72)
		if tier >= 3:
			dup.metallic = maxf(dup.metallic, 0.92)
			dup.roughness = minf(dup.roughness, 0.22)
			dup.clearcoat_enabled = true
			dup.clearcoat = 0.80
	else:
		dup.albedo_color = core_col
		dup.emission_enabled = true
		dup.emission = core_col
		dup.emission_energy_multiplier = minf(0.95 if tier >= 3 else 0.90, maxf(dup.emission_energy_multiplier, 0.82))
	return dup


static func _aplicar_tintado_tier_recursivo(nodo: Node, accent_col: Color, core_col: Color, tier: int) -> void:
	if nodo is MeshInstance3D:
		var mi := nodo as MeshInstance3D
		if mi.material_override != null:
			var dup_ovr := _duplicar_material_tier(mi.material_override, accent_col, core_col, tier)
			if dup_ovr != null:
				mi.material_override = dup_ovr
		elif mi.mesh != null:
			for s_idx in range(mi.mesh.get_surface_count()):
				var mat_s: Material = mi.get_active_material(s_idx)
				var dup_s := _duplicar_material_tier(mat_s, accent_col, core_col, tier)
				if dup_s != null:
					mi.set_surface_override_material(s_idx, dup_s)
	for ch: Node in nodo.get_children():
		_aplicar_tintado_tier_recursivo(ch, accent_col, core_col, tier)


static func _aplicar_visual_tier(pj: Node3D, nombre_subclase: String, tier: int) -> void:
	if pj == null:
		return
	var previo: Node = pj.get_node_or_null("OrnamentoTier")
	if previo != null:
		pj.remove_child(previo)
		previo.queue_free()

	if tier <= 1:
		return

	var paleta: Dictionary = PALETA_VISUAL_TIER.get(nombre_subclase, {
		"accent": Color(0.92, 0.72, 0.24),
		"core": Color(0.32, 0.88, 1.00),
	})
	var col_accent: Color = paleta["accent"]
	var col_core: Color = paleta["core"]

	var mod_scale: float = 5.5
	var modelo: Node = pj.get_node_or_null("Modelo")
	if modelo != null:
		if modelo is Node3D:
			mod_scale = maxf(absf((modelo as Node3D).scale.y), 1.0)
		_aplicar_tintado_tier_recursivo(modelo, col_accent, col_core, tier)

	# Ornamento no invasivo escalado proporcionalmente al Modelo (CERO OmniLight3D nuevas)
	var orn := OrnamentoTierRotator.new()
	orn.name = "OrnamentoTier"
	pj.add_child(orn)

	var sigilo_sz: float = mod_scale * (0.82 if tier >= 3 else 0.72)
	var sigilo_quad := QuadMesh.new()
	sigilo_quad.size = Vector2(sigilo_sz, sigilo_sz)
	var mat_sigilo := StandardMaterial3D.new()
	var tex_sigilo: ImageTexture = _generar_textura_runa_tier(col_core, tier >= 3)
	mat_sigilo.albedo_texture = tex_sigilo
	mat_sigilo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_sigilo.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_sigilo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_sigilo.albedo_color = Color(col_core.r, col_core.g, col_core.b, 0.85)
	mat_sigilo.emission_enabled = true
	mat_sigilo.emission = col_core
	mat_sigilo.emission_energy_multiplier = 0.84 if tier >= 3 else 0.72
	sigilo_quad.material = mat_sigilo

	var mi_ext := MeshInstance3D.new()
	mi_ext.name = "SigiloSuelo"
	mi_ext.mesh = sigilo_quad
	mi_ext.position = Vector3(0.0, 0.035, 0.0)
	mi_ext.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	mi_ext.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	orn.add_child(mi_ext)
	orn.anillo_exterior = mi_ext

	if tier >= 3:
		var sigilo_in := QuadMesh.new()
		var inner_sz: float = mod_scale * 0.50
		sigilo_in.size = Vector2(inner_sz, inner_sz)
		sigilo_in.material = mat_sigilo
		var mi_int := MeshInstance3D.new()
		mi_int.name = "SigiloInterior"
		mi_int.mesh = sigilo_in
		mi_int.position = Vector3(0.0, 0.042, 0.0)
		mi_int.rotation_degrees = Vector3(-90.0, 45.0, 0.0)
		mi_int.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		orn.add_child(mi_int)
		orn.anillo_interior = mi_int

		var orbita := Node3D.new()
		orbita.name = "OrbitaCristales"
		orbita.position = Vector3(0.0, mod_scale * 0.52, 0.0)
		orn.add_child(orbita)
		orn.orbita_cristales = orbita

		var mesh_cristal: ArrayMesh = _construir_octaedro_cristal()
		var mat_cristal := StandardMaterial3D.new()
		mat_cristal.albedo_color = col_accent
		mat_cristal.metallic = 0.85
		mat_cristal.roughness = 0.16
		mat_cristal.clearcoat_enabled = true
		mat_cristal.clearcoat = 0.9
		mat_cristal.emission_enabled = true
		mat_cristal.emission = col_core
		mat_cristal.emission_energy_multiplier = 0.88

		var r_orbita: float = mod_scale * 0.34
		var c_scale: float = mod_scale / 2.4
		for i in range(3):
			var ang: float = float(i) * (TAU / 3.0)
			var c_mi := MeshInstance3D.new()
			c_mi.name = "CristalTier3_%d" % i
			c_mi.mesh = mesh_cristal
			c_mi.material_override = mat_cristal
			c_mi.scale = Vector3(c_scale, c_scale, c_scale)
			c_mi.position = Vector3(cos(ang) * r_orbita, 0.0, sin(ang) * r_orbita)
			orbita.add_child(c_mi)
			orn.cristales.append(c_mi)
