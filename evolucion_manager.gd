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
signal clase_evolucionada(nombre_clase: String, stats: Dictionary)
signal mejora_tier2_completada(nombre_mejora: String, stats: Dictionary)
signal subclase_ascendida(nombre_subclase: String, stats: Dictionary)
signal evolucion_tier2_completada(nombre_subclase: String)
signal evolucion_tier3_completada(nombre_subclase: String)
signal evolucion_completada(nombre_subclase: String)
signal malla_cambiada(nuevo_modelo: Node3D)

# Requisitos de Metamorfosis Tier 1 (Minuto 1:15 - 1:30)
@export var hito_nivel: int = 3
@export var hito_clics: int = 15
@export var hito_bajas: int = 8
@export var requiere_todos_los_hitos: bool = true

# Requisitos de Mejora 1 - Tier 2 (Nv.7 + 40 clics)
@export var hito_nivel_tier2: int = 7
@export var hito_clics_tier2: int = 40

# Requisitos de Mejora 2 / Ascensión Definitiva - Tier 3 (Nv.11 + 75 clics)
@export var hito_nivel_tier3: int = 11
@export var hito_clics_tier3: int = 75

const HITO_NIVEL: int = 3
const HITO_CLICS: int = 15
const HITO_BAJAS: int = 8
const HITO_NIVEL_TIER2: int = 7
const HITO_CLICS_TIER2: int = 40
const HITO_NIVEL_TIER3: int = 11
const HITO_CLICS_TIER3: int = 75

const MALLAS_CLASE = {
	"Novato": "res://personaje/character-male-a.glb",
	"Recluta del Coliseo": "res://personaje/character-male-a.glb",
	"Guerrero": "res://personaje/character-male-d.glb",
	"Murmillo": "res://personaje/character-male-d.glb",
	"Cazador": "res://personaje/character-female-e.glb",
	"Sagittario": "res://personaje/character-female-e.glb",
	"Mago": "res://personaje/character-female-b.glb",
	"Arúspice": "res://personaje/character-female-b.glb",

	# Tier 2 - Mejora 1
	"Secutor Radiante": "res://personaje/character-male-d.glb",
	"Provocator Sangriento": "res://personaje/character-male-d.glb",
	"Velites Balístico": "res://personaje/character-female-e.glb",
	"Dimachaerus Espectral": "res://personaje/character-female-e.glb",
	"Taumaturgo del Vacío": "res://personaje/character-female-b.glb",
	"Flamen Volcánico": "res://personaje/character-female-b.glb",
	"Custodio del Núcleo": "res://personaje/character-male-d.glb",

	# Tier 3 - Mejora 2 (Ascensión Suprema)
	"Paladín del Sol Invictus": "res://personaje/character-male-d.glb",
	"Campeón Augusto de Sangre": "res://personaje/character-male-d.glb",
	"Centurión Balístico Astral": "res://personaje/character-female-e.glb",
	"Sombra del Anfiteatro": "res://personaje/character-female-e.glb",
	"Pontífice del Vacío Estelar": "res://personaje/character-female-b.glb",
	"Señor del Magma Imperial": "res://personaje/character-female-b.glb",
	"Titán Supremo del Núcleo": "res://personaje/character-male-d.glb",

	# Compatibilidad con nombres anteriores
	"Paladín Solar": "res://personaje/character-male-d.glb",
	"Berserker Sangriento": "res://personaje/character-male-d.glb",
	"Francotirador Astral": "res://personaje/character-female-e.glb",
	"Maestro de Sombras": "res://personaje/character-female-e.glb",
	"Archimago del Vacío": "res://personaje/character-female-b.glb",
	"Piromante Cataclísmico": "res://personaje/character-female-b.glb",
	"Avatar del Núcleo": "res://personaje/character-male-d.glb"
}

const STATS_CLASE = {
	"Novato": {
		"nombre": "Recluta del Coliseo",
		"rol": "Condenado de la Arena",
		"descripcion": "Gladiador novato que recién ingresa a la arena monumental.",
		"vida_maxima": 100.0,
		"dano": 12.0,
		"rango_ataque": 2.6,
		"cadencia_ataque": 1.25,
		"speed_caminar": 3.4,
		"speed_correr": 5.4
	},
	"Recluta del Coliseo": {
		"nombre": "Recluta del Coliseo",
		"rol": "Condenado de la Arena",
		"descripcion": "Gladiador novato que recién ingresa a la arena monumental.",
		"vida_maxima": 100.0,
		"dano": 12.0,
		"rango_ataque": 2.6,
		"cadencia_ataque": 1.25,
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

var estado_actual: EstadoFSM = EstadoFSM.NOVATO
var total_clics_acumulados: int = 0
var subclase_activa: String = ""
var mejora_tier2_activa: String = ""
var personaje_ref: CharacterBody3D = null
var modal_instancia: Node = null
var tier_menu_activo: int = 1

func _ready():
	add_to_group("evolucion_manager")
	process_mode = Node.PROCESS_MODE_ALWAYS
	if get_parent() is CharacterBody3D:
		configurar_con_personaje(get_parent() as CharacterBody3D)

func configurar_con_personaje(personaje: CharacterBody3D):
	personaje_ref = personaje
	call_deferred("_vincular_eventos_externos")

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

func _evaluar_hito_evolucion():
	if estado_actual == EstadoFSM.NOVATO and puede_evolucionar():
		disparar_metamorfosis()
	elif estado_actual == EstadoFSM.EVOLUCIONADO and puede_ascender_tier2():
		disparar_ascension_tier2()
	elif estado_actual == EstadoFSM.ASCENDIDO_TIER_2 and puede_ascender_tier3():
		disparar_ascension_tier3()

func disparar_metamorfosis():
	if estado_actual != EstadoFSM.NOVATO:
		return
	
	estado_actual = EstadoFSM.DISPONIBLE
	tier_menu_activo = 1
	emit_signal("metamorfosis_disponible")
	
	AudioManager.play("altar_activado", 1.25, 2.0)
	if personaje_ref != null and personaje_ref.has_method("_spawn_texto_3d"):
		personaje_ref._spawn_texto_3d("✨ ¡METAMORFOSIS HEROICA TIER 1!", Color(1.0, 0.85, 0.2))
		
	abrir_modal_evolucion(1)

func disparar_ascension_tier2():
	if estado_actual != EstadoFSM.EVOLUCIONADO:
		return
	
	estado_actual = EstadoFSM.ASCENSION_T2_LISTA
	tier_menu_activo = 2
	
	AudioManager.play("altar_activado", 1.35, 2.0)
	if personaje_ref != null and personaje_ref.has_method("_spawn_texto_3d"):
		personaje_ref._spawn_texto_3d("⚔️ ¡MEJORA DE CLASE TIER 2 DISPONIBLE!", Color(1.0, 0.85, 0.2))
		
	abrir_modal_evolucion(2)

func disparar_ascension_tier3():
	if estado_actual != EstadoFSM.ASCENDIDO_TIER_2:
		return
		
	estado_actual = EstadoFSM.ASCENSION_T3_LISTA
	tier_menu_activo = 3
	
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

func abrir_modal_evolucion(tier: int = 1):
	tier_menu_activo = tier
	if modal_instancia != null and is_instance_valid(modal_instancia):
		if modal_instancia.has_method("configurar_modo_tier"):
			var base_clase = _obtener_arquetipo_base_personaje()
			modal_instancia.configurar_modo_tier(tier, base_clase)
		if modal_instancia.has_method("abrir"):
			modal_instancia.abrir()
		return
	
	if tier == 1:
		estado_actual = EstadoFSM.METAMORFOSIS
	elif tier == 2:
		estado_actual = EstadoFSM.ASCENSION_T2_LISTA
	else:
		estado_actual = EstadoFSM.ASCENSION_T3_LISTA
	
	if personaje_ref != null and is_instance_valid(personaje_ref):
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
			var base_clase = _obtener_arquetipo_base_personaje()
			if radial.has_method("configurar_modo_tier"):
				radial.configurar_modo_tier(tier, base_clase)
			if not radial.evolucion_seleccionada.is_connected(_on_clase_elegida_en_modal):
				radial.evolucion_seleccionada.connect(_on_clase_elegida_en_modal)
			radial.abrir()
			return

	var escena_modal = load("res://modal_evolucion.tscn")
	if escena_modal != null:
		modal_instancia = escena_modal.instantiate()
		var tree = _obtener_tree()
		if tree != null and tree.root != null:
			tree.root.add_child(modal_instancia)
			if modal_instancia.has_signal("clase_seleccionada"):
				modal_instancia.clase_seleccionada.connect(_on_clase_elegida_en_modal)

func _obtener_arquetipo_base_personaje() -> String:
	if personaje_ref == null:
		return "Murmillo"
	if "clase_base" in personaje_ref and personaje_ref.clase_base != "Novato" and personaje_ref.clase_base != "":
		return personaje_ref.clase_base
	if personaje_ref.clase != "Novato" and personaje_ref.clase != "":
		return personaje_ref.clase
	return "Murmillo"

func _on_clase_elegida_en_modal(nombre_opcion: String):
	if modal_instancia != null and is_instance_valid(modal_instancia):
		if modal_instancia.has_method("cerrar"):
			modal_instancia.cerrar()
		elif modal_instancia is CanvasLayer:
			modal_instancia.queue_free()
		modal_instancia = null
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

func cambiar_malla_3d(personaje: CharacterBody3D, ruta_malla: String) -> AnimationPlayer:
	if not ResourceLoader.exists(ruta_malla):
		push_error("No se encontró recurso de malla: " + ruta_malla)
		return null
	
	var escena_glb = load(ruta_malla)
	if escena_glb == null:
		push_error("Fallo al instanciar modelo .glb: " + ruta_malla)
		return null
	
	var modelo_actual = personaje.get_node_or_null("Modelo")
	var transform_base = Transform3D(Basis(Vector3(-2.6, 0.0, 0.0), Vector3(0.0, 2.6, 0.0), Vector3(0.0, 0.0, -2.6)), Vector3.ZERO)
	
	if modelo_actual != null:
		transform_base = modelo_actual.transform
		modelo_actual.name = "Modelo_Antiguo"
		personaje.remove_child(modelo_actual)
		modelo_actual.queue_free()
	
	var nuevo_modelo = escena_glb.instantiate()
	nuevo_modelo.name = "Modelo"
	nuevo_modelo.transform = transform_base
	personaje.add_child(nuevo_modelo)
	
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
