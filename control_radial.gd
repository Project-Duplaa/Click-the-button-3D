@tool
extends Control
class_name ControlRadial

## ControlRadial - Rueda Arcana 3D In-World de Gran Escala
## Dibuja un círculo rúnico multicapa de 1024x1024 con anillos astrales giratorios,
## 3 sectores angulares grandes (Izquierda 150°, Derecha 30°, Superior/Frontal 270°),
## soporte dinámico para Tier 1 y todas las 7 Subclases Tier 2 con emblemas y stats BBCode.

signal clase_resaltada(nombre_clase: String)
signal clase_confirmada(nombre_clase: String)

const TAMANO_VIEWPORT: Vector2 = Vector2(1024.0, 1024.0)
const CENTRO: Vector2 = Vector2(512.0, 512.0)

const RADIO_INTERIOR: float = 155.0
const RADIO_EXTERIOR: float = 385.0
const RADIO_ICONOS: float = 270.0
const GAP_ANGULAR_DEG: float = 6.5

const COLOR_BORDE_ORO: Color = Color(0.95, 0.78, 0.36, 1.0)

const TEX_ESPADA = preload("res://ui_assets/icono_espada.png")
const TEX_ARCO = preload("res://ui_assets/icono_arco.png")
const TEX_BASTON = preload("res://ui_assets/icono_baston.png")

const CONFIG_CLASES = {
	# ================= TIER 1: CLASES DE LA ARENA =================
	"Murmillo": {
		"color": Color(0.95, 0.24, 0.28, 1.0),
		"angulo_centro_deg": 150.0,
		"icono_tex": TEX_ESPADA,
		"titulo": "⚔️ MURMILLO",
		"rol_badge": "🛡️ COLOSO DE ACERO / BALUARTE MELEE",
		"subtitulo": "Gladiador Pesado de la Arena",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Gran Espada + Escudo Real\n• [color=#56E39F]160 HP (+60% Salud Máxima)[/color]\n• [color=#56E39F]Torbellino 360°: 16 DMG · Cadencia: 0.65s[/color]\n• [color=#72EFDD]Clic Derecho / F / Q:[/color] Bloqueo Activo (-75% Daño)",
		"accion": "⚡ [ CLIC PARA EVOLUCIONAR ] ⚡"
	},
	"Guerrero": {
		"color": Color(0.95, 0.24, 0.28, 1.0),
		"angulo_centro_deg": 150.0,
		"icono_tex": TEX_ESPADA,
		"titulo": "⚔️ MURMILLO",
		"rol_badge": "🛡️ COLOSO DE ACERO / BALUARTE MELEE",
		"subtitulo": "Gladiador Pesado de la Arena",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Gran Espada + Escudo Real\n• [color=#56E39F]160 HP (+60% Salud Máxima)[/color]\n• [color=#56E39F]Torbellino 360°: 16 DMG · Cadencia: 0.65s[/color]\n• [color=#72EFDD]Clic Derecho / F / Q:[/color] Bloqueo Activo (-75% Daño)",
		"accion": "⚡ [ CLIC PARA EVOLUCIONAR ] ⚡"
	},
	"Sagittario": {
		"color": Color(0.18, 0.88, 0.76, 1.0),
		"angulo_centro_deg": 30.0,
		"icono_tex": TEX_ARCO,
		"titulo": "🏹 SAGITTARIO",
		"rol_badge": "🎯 ARQUERO IMPERIAL / RÁFAGA BALÍSTICA",
		"subtitulo": "Tirador de Élite del Coliseo",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Arco Élfico Balístico\n• [color=#56E39F]Ráfaga 3 Saetas: 7.2 DMG/saeta[/color]\n• [color=#56E39F]Cadencia: 0.45s · Alcance: 7.5m[/color]\n• [color=#72EFDD]Velocidad Carrera:[/color] 6.4 m/s (Kiteo Ágil)",
		"accion": "⚡ [ CLIC PARA EVOLUCIONAR ] ⚡"
	},
	"Cazador": {
		"color": Color(0.18, 0.88, 0.76, 1.0),
		"angulo_centro_deg": 30.0,
		"icono_tex": TEX_ARCO,
		"titulo": "🏹 SAGITTARIO",
		"rol_badge": "🎯 ARQUERO IMPERIAL / RÁFAGA BALÍSTICA",
		"subtitulo": "Tirador de Élite del Coliseo",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Arco Élfico Balístico\n• [color=#56E39F]Ráfaga 3 Saetas: 7.2 DMG/saeta[/color]\n• [color=#56E39F]Cadencia: 0.45s · Alcance: 7.5m[/color]\n• [color=#72EFDD]Velocidad Carrera:[/color] 6.4 m/s (Kiteo Ágil)",
		"accion": "⚡ [ CLIC PARA EVOLUCIONAR ] ⚡"
	},
	"Arúspice": {
		"color": Color(0.28, 0.58, 1.00, 1.0),
		"angulo_centro_deg": 270.0,
		"icono_tex": TEX_BASTON,
		"titulo": "🔮 ARÚSPICE",
		"rol_badge": "✨ MÍSTICO RÚNICO / TAUMATURGO DEL NÚCLEO",
		"subtitulo": "Sacerdote del Núcleo Rúnico",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Báculo Imperial y Orbe Astral\n• [color=#56E39F]Orbe Teledirigido AOE: 17 DMG[/color]\n• [color=#56E39F]Cadencia: 0.70s · Rango: 5.5m[/color]\n• [color=#72EFDD]Detonación en Área:[/color] 3.2m de radio explosivo",
		"accion": "⚡ [ CLIC PARA EVOLUCIONAR ] ⚡"
	},
	"Mago": {
		"color": Color(0.28, 0.58, 1.00, 1.0),
		"angulo_centro_deg": 270.0,
		"icono_tex": TEX_BASTON,
		"titulo": "🔮 ARÚSPICE",
		"rol_badge": "✨ MÍSTICO RÚNICO / TAUMATURGO DEL NÚCLEO",
		"subtitulo": "Sacerdote del Núcleo Rúnico",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Báculo Imperial y Orbe Astral\n• [color=#56E39F]Orbe Teledirigido AOE: 17 DMG[/color]\n• [color=#56E39F]Cadencia: 0.70s · Rango: 5.5m[/color]\n• [color=#72EFDD]Detonación en Área:[/color] 3.2m de radio explosivo",
		"accion": "⚡ [ CLIC PARA EVOLUCIONAR ] ⚡"
	},

	# ================= TIER 2 (MEJORA 1): ESPECIALIZACIONES DE LA ARENA =================
	# --- Rama Murmillo ---
	"Secutor Radiante": {
		"color": Color(1.0, 0.84, 0.22, 1.0),
		"angulo_centro_deg": 150.0,
		"icono_tex": TEX_ESPADA,
		"titulo": "☀️ SECUTOR RADIANTE",
		"rol_badge": "🛡️ ESCUDO SOLAR / CONTRAGOLPE RADIANTE",
		"subtitulo": "Gladiador Consagrado al Sol",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Gran Espada Solar + Broquel Sagrado\n• [color=#56E39F]190 HP Máx · +30 Armadura · Onda: 22 DMG[/color]\n• [color=#72EFDD]Bloqueo Radiante:[/color] Nova solar que cura +4 HP y causa 16.5 DMG\n• [color=#FFD166]Cadencia:[/color] 0.60s en 360°",
		"accion": "⚔️ [ MEJORAR A SECUTOR ] ⚔️"
	},
	"Provocator Sangriento": {
		"color": Color(0.92, 0.12, 0.18, 1.0),
		"angulo_centro_deg": 30.0,
		"icono_tex": TEX_ESPADA,
		"titulo": "🪓 PROVOCATOR SANGRIENTO",
		"rol_badge": "🩸 FURIA DE LA ARENA / TORBELLINO VORAZ",
		"subtitulo": "Guerrero Feroz del Coliseo",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Hachas Dobles Voraces\n• [color=#56E39F]165 HP · Torbellino: 19 - 26.6 DMG (Furia)[/color]\n• [color=#72EFDD]Robo de Vida:[/color] +2.0 HP por golpe voraz\n• [color=#FFD166]Cadencia:[/color] 0.48s de tajo ultra rápido",
		"accion": "⚔️ [ MEJORAR A PROVOCATOR ] ⚔️"
	},

	# --- Rama Sagittario ---
	"Velites Balístico": {
		"color": Color(0.15, 0.92, 1.00, 1.0),
		"angulo_centro_deg": 150.0,
		"icono_tex": TEX_ARCO,
		"titulo": "⚡ VELITES BALÍSTICO",
		"rol_badge": "🎯 HOSTIGADOR TÁCTICO / SAETAS PERFORANTES",
		"subtitulo": "Francotirador de la Arena",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Riel Balístico de Alta Cadencia\n• [color=#56E39F]120 HP · Riel Astral: 18.4 DMG (13m)[/color]\n• [color=#72EFDD]Penetración en Línea:[/color] Atraviesa filas de enemigos\n• [color=#FFD166]Cadencia:[/color] 0.38s · Velocidad: 6.6 m/s",
		"accion": "🏹 [ MEJORAR A VELITES ] 🏹"
	},
	"Dimachaerus Espectral": {
		"color": Color(0.72, 0.25, 1.00, 1.0),
		"angulo_centro_deg": 30.0,
		"icono_tex": TEX_ESPADA,
		"titulo": "🗡️ DIMACHAERUS ESPECTRAL",
		"rol_badge": "👤 DAGAS GEMELAS / EVASIÓN DE LA ARENA",
		"subtitulo": "Gladiador de Dos Armas",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Dagas Espectrales Gemelas\n• [color=#56E39F]125 HP · +10% Crítico · Espiral 8 Dagas (6.3 DMG/daga)[/color]\n• [color=#72EFDD]Evasión Ágil:[/color] 6.8 m/s velocidad y señuelo en dash\n• [color=#FFD166]Cadencia:[/color] 0.34s de espiral continua",
		"accion": "🗡️ [ MEJORAR A DIMACHAERUS ] 🗡️"
	},

	# --- Rama Arúspice ---
	"Taumaturgo del Vacío": {
		"color": Color(0.55, 0.18, 0.95, 1.0),
		"angulo_centro_deg": 150.0,
		"icono_tex": TEX_BASTON,
		"titulo": "🌌 TAUMATURGO DEL VACÍO",
		"rol_badge": "🪐 SIFÓN GRAVITACIONAL / CONTROL CÓSMICO",
		"subtitulo": "Señor de la Gravedad de la Arena",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Báculo de Obsidiana Rúnica\n• [color=#56E39F]110 HP · Orbe: 22 DMG · Cadencia: 0.68s[/color]\n• [color=#72EFDD]Sifón Gravitacional:[/color] Vórtice 2.5s (3.5 DMG/tick)\n• [color=#FFD166]Control de Masas:[/color] Succiona enemigos hacia el vórtice",
		"accion": "🔮 [ MEJORAR A TAUMATURGO ] 🔮"
	},
	"Flamen Volcánico": {
		"color": Color(1.0, 0.45, 0.10, 1.0),
		"angulo_centro_deg": 30.0,
		"icono_tex": TEX_BASTON,
		"titulo": "🌋 FLAMEN VOLCÁNICO",
		"rol_badge": "🔥 SACERDOTE DEL FUEGO / MAGMA DE LA ARENA",
		"subtitulo": "Invocador del Fuego Sagrado",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Báculo Ígneo con Núcleo de Magma\n• [color=#56E39F]115 HP · Meteoro: 22 DMG · Cadencia: 0.68s[/color]\n• [color=#72EFDD]Charco de Magma:[/color] 2.8s de fuego continuo (4.2 DMG/tick)\n• [color=#FFD166]Negación de Área:[/color] Calcina hordas concentradas",
		"accion": "🔮 [ MEJORAR A FLAMEN ] 🔮"
	},

	# --- Mejora Universal Tier 2 ---
	"Custodio del Núcleo": {
		"color": Color(0.22, 0.95, 0.85, 1.0),
		"angulo_centro_deg": 270.0,
		"icono_tex": TEX_ESPADA,
		"titulo": "💎 CUSTODIO DEL NÚCLEO",
		"rol_badge": "⚡ SINTONÍA RÚNICA / PULSO DEL BOTÓN",
		"subtitulo": "Guardián de la Runa 3D",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Guantelete Cuchilla + Prisma de Resonancia\n• [color=#56E39F]145 HP · Golpe Resonante: 22 DMG · Cadencia: 0.52s[/color]\n• [color=#72EFDD]Onda de Choque x1.5:[/color] Amplifica onda del clic móvil\n• [color=#FFD166]Sintonía Rúnica:[/color] Daño universal balanceado",
		"accion": "💎 [ SINTONIZAR CON EL NÚCLEO ] 💎"
	},

	# ================= TIER 3 (MEJORA 2): ASCENSIÓN DEFINITIVA =================
	# --- Ascensión Murmillo ---
	"Paladín del Sol Invictus": {
		"color": Color(1.0, 0.88, 0.25, 1.0),
		"angulo_centro_deg": 150.0,
		"icono_tex": TEX_ESPADA,
		"titulo": "☀️ PALADÍN DEL SOL INVICTUS",
		"rol_badge": "🛡️ BALUARTE SUPREMO / NOVA SOLAR ETERNA",
		"subtitulo": "Campeón Divino de la Arena",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Gran Espada Divina + Baluarte de Oro\n• [color=#56E39F]250 HP Máx · +60 Armadura · Onda Solar: 32 DMG[/color]\n• [color=#72EFDD]Supernova Radiante:[/color] Al bloquear desata 27 DMG (7.5m) y cura +10 HP\n• [color=#FFD166]Cadencia:[/color] 0.52s en 360°",
		"accion": "👑 [ ASCENSIÓN DEFINITIVA TIER 3 ] 👑"
	},
	"Campeón Augusto de Sangre": {
		"color": Color(0.95, 0.10, 0.15, 1.0),
		"angulo_centro_deg": 30.0,
		"icono_tex": TEX_ESPADA,
		"titulo": "🪓 CAMPEÓN AUGUSTO DE SANGRE",
		"rol_badge": "🩸 TORBELLINO VORAZ / DIOS DE LA ARENA",
		"subtitulo": "El Terror Absoluto del Coliseo",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Hachas Dobles de Furia Imperial\n• [color=#56E39F]190 HP · Torbellino: 28 - 43.4 DMG (Furia Sostenida)[/color]\n• [color=#72EFDD]Vampirismo Supremo:[/color] +3.5 HP por golpe en torbellino\n• [color=#FFD166]Cadencia:[/color] 0.40s de tajo torbellino continuo",
		"accion": "👑 [ ASCENSIÓN DEFINITIVA TIER 3 ] 👑"
	},

	# --- Ascensión Sagittario ---
	"Centurión Balístico Astral": {
		"color": Color(0.20, 0.95, 1.00, 1.0),
		"angulo_centro_deg": 150.0,
		"icono_tex": TEX_ARCO,
		"titulo": "⚡ CENTURIÓN BALÍSTICO ASTRAL",
		"rol_badge": "🎯 RIEL ASTRAL / SAETAS DE HIPERVELOCIDAD",
		"subtitulo": "Vanguardia Cósmica del Coliseo",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Cañón de Saetas de Plasma Astral\n• [color=#56E39F]145 HP · Riel Hipercinético: 28.8 DMG (Atraviesa 5)[/color]\n• [color=#72EFDD]Penetración Total:[/color] Perfora filas a 32 m/s en 11.0m\n• [color=#FFD166]Cadencia:[/color] 0.30s · Velocidad: 7.0 m/s",
		"accion": "👑 [ ASCENSIÓN DEFINITIVA TIER 3 ] 👑"
	},
	"Sombra del Anfiteatro": {
		"color": Color(0.78, 0.25, 1.00, 1.0),
		"angulo_centro_deg": 30.0,
		"icono_tex": TEX_ESPADA,
		"titulo": "🗡️ SOMBRA DEL ANFITEATRO",
		"rol_badge": "👤 ASESINO ESPECTRAL / FANTASMA DEL COLISEO",
		"subtitulo": "Espectro Vengador de la Arena",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Dagas Espectrales de Vacío Imperial\n• [color=#56E39F]150 HP · +20% Crítico · Espiral 10 Dagas (7.7 DMG/daga)[/color]\n• [color=#72EFDD]Señuelo Inestable:[/color] Detona al dash con 24 DMG y retroceso\n• [color=#FFD166]Cadencia:[/color] 0.28s · Velocidad: 7.2 m/s",
		"accion": "👑 [ ASCENSIÓN DEFINITIVA TIER 3 ] 👑"
	},

	# --- Ascensión Arúspice ---
	"Pontífice del Vacío Estelar": {
		"color": Color(0.60, 0.20, 1.00, 1.0),
		"angulo_centro_deg": 150.0,
		"icono_tex": TEX_BASTON,
		"titulo": "🌌 PONTÍFICE DEL VACÍO ESTELAR",
		"rol_badge": "🪐 AGUJERO NEGRO / COLAPSO GRAVITACIONAL",
		"subtitulo": "Maestro Cósmico del Éter",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Báculo de Obsidiana con Núcleo Singular\n• [color=#56E39F]140 HP · Orbe: 32 DMG · Cadencia: 0.62s[/color]\n• [color=#72EFDD]Agujero Negro 3.0s:[/color] Succiona ejércitos (4.5 DMG/tick)\n• [color=#FFD166]Colapso Cósmico:[/color] Destrucción continua en área",
		"accion": "👑 [ ASCENSIÓN DEFINITIVA TIER 3 ] 👑"
	},
	"Señor del Magma Imperial": {
		"color": Color(1.0, 0.40, 0.05, 1.0),
		"angulo_centro_deg": 30.0,
		"icono_tex": TEX_BASTON,
		"titulo": "🌋 SEÑOR DEL MAGMA IMPERIAL",
		"rol_badge": "🔥 CALAMIDAD VOLCÁNICA / FUEGO PERPETUO",
		"subtitulo": "El Destructor Ígneo del Coliseo",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Cetro del Núcleo Volcánico Ancestral\n• [color=#56E39F]145 HP · Meteoro: 32 DMG · Cadencia: 0.62s[/color]\n• [color=#72EFDD]Mar de Magma 3.5s:[/color] Quema incesante (5.2 DMG/tick)\n• [color=#FFD166]Calamidad:[/color] Control y calcinación total de la arena",
		"accion": "👑 [ ASCENSIÓN DEFINITIVA TIER 3 ] 👑"
	},

	# --- Ascensión Universal Tier 3 ---
	"Titán Supremo del Núcleo": {
		"color": Color(0.25, 0.98, 0.90, 1.0),
		"angulo_centro_deg": 270.0,
		"icono_tex": TEX_ESPADA,
		"titulo": "💎 TITÁN SUPREMO DEL NÚCLEO",
		"rol_badge": "⚡ AVATAR DE LA RESONANCIA / CLIC CATACLÍSMICO",
		"subtitulo": "Fusión Divina con el Botón 3D",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Guantelete del Núcleo Rúnico Definitivo\n• [color=#56E39F]180 HP · +45 Armadura · Onda Sísmica: 32 DMG[/color]\n• [color=#72EFDD]Onda de Choque x2.2:[/color] Cada clic sacude el Coliseo entero\n• [color=#FFD166]Cadencia:[/color] 0.42s con resonancia rúnica continua",
		"accion": "👑 [ ASCENSIÓN DEFINITIVA TIER 3 ] 👑"
	},

	# ================= ALIASES RETROCOMPATIBLES =================
	"Paladín Solar": {
		"color": Color(1.0, 0.84, 0.22, 1.0),
		"angulo_centro_deg": 150.0,
		"icono_tex": TEX_ESPADA,
		"titulo": "☀️ SECUTOR RADIANTE",
		"rol_badge": "🛡️ ESCUDO SOLAR / CONTRAGOLPE RADIANTE",
		"subtitulo": "Gladiador Consagrado al Sol",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Gran Espada Solar + Broquel Sagrado\n• [color=#56E39F]+50 HP Máxima · +30 Armadura[/color]\n• [color=#72EFDD]Bloqueo Radiante:[/color] Nova solar que cura +4 HP y calcina\n• [color=#FFD166]Pasiva:[/color] Tajo imbuido con fuego solar",
		"accion": "👑 [ CLIC PARA MEJORAR ] 👑"
	},
	"Berserker Sangriento": {
		"color": Color(0.92, 0.12, 0.18, 1.0),
		"angulo_centro_deg": 30.0,
		"icono_tex": TEX_ESPADA,
		"titulo": "🪓 PROVOCATOR SANGRIENTO",
		"rol_badge": "🩸 FURIA DE LA ARENA / TORBELLINO VORAZ",
		"subtitulo": "Guerrero Feroz del Coliseo",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Hachas Dobles Voraces en ambas manos\n• [color=#56E39F]+1.5% Daño por cada 1% HP faltante[/color]\n• [color=#72EFDD]Robo de Vida:[/color] +3% HP Máx por golpe · Torbellino feroz\n• [color=#FFD166]Cadencia:[/color] +28% velocidad de tajo continuo",
		"accion": "👑 [ CLIC PARA MEJORAR ] 👑"
	},
	"Francotirador Astral": {
		"color": Color(0.15, 0.92, 1.00, 1.0),
		"angulo_centro_deg": 150.0,
		"icono_tex": TEX_ARCO,
		"titulo": "⚡ VELITES BALÍSTICO",
		"rol_badge": "🎯 HOSTIGADOR TÁCTICO / SAETAS PERFORANTES",
		"subtitulo": "Francotirador de la Arena",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Riel Balístico de Alta Cadencia\n• [color=#56E39F]+135% Daño con Saetas Perforantes[/color]\n• [color=#72EFDD]Penetración en Línea:[/color] Atraviesa filas de enemigos\n• [color=#FFD166]Rango:[/color] 9.0m con proyectiles a hipervelocidad",
		"accion": "👑 [ CLIC PARA MEJORAR ] 👑"
	},
	"Maestro de Sombras": {
		"color": Color(0.72, 0.25, 1.00, 1.0),
		"angulo_centro_deg": 30.0,
		"icono_tex": TEX_ESPADA,
		"titulo": "🗡️ DIMACHAERUS ESPECTRAL",
		"rol_badge": "👤 DAGAS GEMELAS / EVASIÓN DE LA ARENA",
		"subtitulo": "Gladiador de Dos Armas",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Dagas Espectrales Gemelas de Vacío\n• [color=#56E39F]+25% Evasión Pasiva Permanente[/color]\n• [color=#72EFDD]Espiral de Dagas:[/color] Ráfaga continua en 360°\n• [color=#FFD166]Dash Táctico:[/color] Deja un señuelo explosivo al evadir",
		"accion": "👑 [ CLIC PARA MEJORAR ] 👑"
	},
	"Archimago del Vacío": {
		"color": Color(0.55, 0.18, 0.95, 1.0),
		"angulo_centro_deg": 150.0,
		"icono_tex": TEX_BASTON,
		"titulo": "🌌 TAUMATURGO DEL VACÍO",
		"rol_badge": "🪐 SIFÓN GRAVITACIONAL / CONTROL CÓSMICO",
		"subtitulo": "Señor de la Gravedad de la Arena",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Báculo de Obsidiana Rúnica\n• [color=#56E39F]Vórtice Gravitacional:[/color] Colapso de 2.5s en impacto\n• [color=#72EFDD]Atracción y Daño:[/color] Succiona enemigos hacia el centro\n• [color=#FFD166]+40% Daño Mágico en Área[/color]",
		"accion": "👑 [ CLIC PARA MEJORAR ] 👑"
	},
	"Piromante Cataclísmico": {
		"color": Color(1.0, 0.45, 0.10, 1.0),
		"angulo_centro_deg": 30.0,
		"icono_tex": TEX_BASTON,
		"titulo": "🌋 FLAMEN VOLCÁNICO",
		"rol_badge": "🔥 SACERDOTE DEL FUEGO / MAGMA DE LA ARENA",
		"subtitulo": "Invocador del Fuego Sagrado",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Báculo Ígneo con Núcleo de Magma\n• [color=#56E39F]Meteoro Ígneo:[/color] Impacta y deja charcos de lava en la arena\n• [color=#72EFDD]Magma Solar:[/color] 2.8s de daño por fuego continuo\n• [color=#FFD166]+45% Daño Crítico Elemental[/color]",
		"accion": "👑 [ CLIC PARA MEJORAR ] 👑"
	},
	"Avatar del Núcleo": {
		"color": Color(0.22, 0.95, 0.85, 1.0),
		"angulo_centro_deg": 270.0,
		"icono_tex": TEX_ESPADA,
		"titulo": "💎 CUSTODIO DEL NÚCLEO",
		"rol_badge": "⚡ SINTONÍA RÚNICA / PULSO DEL BOTÓN",
		"subtitulo": "Guardián de la Runa 3D",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Guantelete Cuchilla + Prisma de Resonancia\n• [color=#56E39F]Onda de Choque x1.6:[/color] Amplía radio de onda del clic móvil\n• [color=#72EFDD]Hilos de Resonancia:[/color] Daño balanceado en 360°\n• [color=#FFD166]+25% Daño Global y Armadura aumentada[/color]",
		"accion": "👑 [ CLIC PARA MEJORAR ] 👑"
	}
}

var opciones_activas: Array[String] = ["Murmillo", "Sagittario", "Arúspice"]
var clase_seleccionada: String = ""
var _anim_pesos: Dictionary = {}
var _tiempo_pulso: float = 0.0
var _rotacion_runas: float = 0.0
var _custom_configs: Dictionary = {}

func _ready():
	custom_minimum_size = TAMANO_VIEWPORT
	_inicializar_pesos()
	queue_redraw()

func _inicializar_pesos():
	_anim_pesos.clear()
	for op in opciones_activas:
		_anim_pesos[op] = 0.0

func _obtener_config(nombre_clase: String) -> Dictionary:
	if _custom_configs.has(nombre_clase):
		return _custom_configs[nombre_clase]
	return CONFIG_CLASES.get(nombre_clase, {})

func establecer_modo_opciones(tier: int, clase_base: String):
	if tier == 1:
		opciones_activas = ["Murmillo", "Sagittario", "Arúspice"]
	elif tier == 2:
		match clase_base:
			"Cazador", "Sagittario":
				opciones_activas = ["Velites Balístico", "Dimachaerus Espectral", "Custodio del Núcleo"]
			"Mago", "Arúspice":
				opciones_activas = ["Taumaturgo del Vacío", "Flamen Volcánico", "Custodio del Núcleo"]
			_:
				opciones_activas = ["Secutor Radiante", "Provocator Sangriento", "Custodio del Núcleo"]
	else:
		match clase_base:
			"Cazador", "Sagittario":
				opciones_activas = ["Centurión Balístico Astral", "Sombra del Anfiteatro", "Titán Supremo del Núcleo"]
			"Mago", "Arúspice":
				opciones_activas = ["Pontífice del Vacío Estelar", "Señor del Magma Imperial", "Titán Supremo del Núcleo"]
			_:
				opciones_activas = ["Paladín del Sol Invictus", "Campeón Augusto de Sangre", "Titán Supremo del Núcleo"]
	_inicializar_pesos()
	clase_seleccionada = ""
	queue_redraw()

func configurar_opciones(lista_3_opciones: Array, configs: Dictionary = {}):
	if lista_3_opciones.size() >= 3:
		opciones_activas = [str(lista_3_opciones[0]), str(lista_3_opciones[1]), str(lista_3_opciones[2])]
	for k in configs.keys():
		_custom_configs[k] = configs[k]
	_inicializar_pesos()
	clase_seleccionada = ""
	queue_redraw()

func _process(delta: float):
	if Engine.is_editor_hint():
		return
	_tiempo_pulso += delta * 4.2
	_rotacion_runas += delta * 0.38
	for k in _anim_pesos.keys():
		var destino = 1.0 if k == clase_seleccionada else 0.0
		var actual = _anim_pesos[k]
		_anim_pesos[k] = lerpf(actual, destino, minf(1.0, delta * 14.0))
	queue_redraw()

func actualizar_por_angulo(angulo_deg: float):
	if angulo_deg < 0.0 or opciones_activas.size() < 3:
		return
	var ang = fposmod(angulo_deg, 360.0)
	var nueva_clase = ""
	if ang >= 330.0 or ang < 90.0:
		nueva_clase = opciones_activas[1] # Sector Derecho (30°)
	elif ang >= 90.0 and ang < 210.0:
		nueva_clase = opciones_activas[0] # Sector Izquierdo (150°)
	else:
		nueva_clase = opciones_activas[2] # Sector Superior/Frontal (270°)
		
	if nueva_clase != clase_seleccionada:
		seleccionar_clase(nueva_clase)

func seleccionar_clase(nombre_clase: String):
	if clase_seleccionada == nombre_clase:
		return
	clase_seleccionada = nombre_clase
	emit_signal("clase_resaltada", nombre_clase)
	queue_redraw()

func deseleccionar():
	if clase_seleccionada == "":
		return
	clase_seleccionada = ""
	emit_signal("clase_resaltada", "")
	queue_redraw()

func confirmar_clase(nombre_clase: String):
	if nombre_clase != "":
		emit_signal("clase_confirmada", nombre_clase)

func confirmar_seleccion_actual():
	if clase_seleccionada != "":
		confirmar_clase(clase_seleccionada)

func _draw():
	if opciones_activas.size() < 3:
		return
		
	var gap_rad = deg_to_rad(GAP_ANGULAR_DEG)
	_dibujar_geometria_sagrada_fondo()

	var a_der_ini = -PI / 6.0 + gap_rad
	var a_der_fin = PI / 2.0 - gap_rad

	var a_izq_ini = PI / 2.0 + gap_rad
	var a_izq_fin = (7.0 * PI / 6.0) - gap_rad

	var a_top_ini = (7.0 * PI / 6.0) + gap_rad
	var a_top_fin = (11.0 * PI / 6.0) - gap_rad

	_dibujar_segmento(CENTRO, RADIO_INTERIOR, RADIO_EXTERIOR, a_izq_ini, a_izq_fin, opciones_activas[0])
	_dibujar_segmento(CENTRO, RADIO_INTERIOR, RADIO_EXTERIOR, a_der_ini, a_der_fin, opciones_activas[1])
	_dibujar_segmento(CENTRO, RADIO_INTERIOR, RADIO_EXTERIOR, a_top_ini, a_top_fin, opciones_activas[2])

	_dibujar_icono_arma(opciones_activas[0], a_izq_ini, a_izq_fin)
	_dibujar_icono_arma(opciones_activas[1], a_der_ini, a_der_fin)
	_dibujar_icono_arma(opciones_activas[2], a_top_ini, a_top_fin)

func _dibujar_geometria_sagrada_fondo():
	var pulso = 0.5 + 0.5 * sin(_tiempo_pulso)
	var col_oro_suave = Color(0.95, 0.78, 0.36, 0.28 + 0.12 * pulso)
	var col_oro_fuerte = Color(0.98, 0.84, 0.42, 0.58)

	draw_arc(CENTRO, (RADIO_INTERIOR + RADIO_EXTERIOR) * 0.5, 0.0, TAU, 96, Color(0.03, 0.04, 0.08, 0.62), RADIO_EXTERIOR - RADIO_INTERIOR + 42.0, true)

	draw_arc(CENTRO, RADIO_INTERIOR - 16.0, 0.0, TAU, 72, col_oro_fuerte, 3.0, true)
	draw_arc(CENTRO, RADIO_INTERIOR - 26.0, 0.0, TAU, 72, col_oro_suave, 1.5, true)
	draw_arc(CENTRO, RADIO_EXTERIOR + 26.0, 0.0, TAU, 96, col_oro_fuerte, 3.2, true)
	draw_arc(CENTRO, RADIO_EXTERIOR + 38.0, 0.0, TAU, 96, col_oro_suave, 1.8, true)

	var num_marcas = 36
	for i in range(num_marcas):
		var ang_ext = (TAU * float(i) / float(num_marcas)) + _rotacion_runas
		var dir_ext = Vector2(cos(ang_ext), -sin(ang_ext))
		var largo = 12.0 if (i % 3 == 0) else 6.0
		var grosor = 3.0 if (i % 3 == 0) else 1.6
		draw_line(CENTRO + dir_ext * (RADIO_EXTERIOR + 26.0), CENTRO + dir_ext * (RADIO_EXTERIOR + 26.0 + largo), col_oro_fuerte, grosor, true)

		var ang_int = (TAU * float(i) / float(num_marcas)) - _rotacion_runas * 1.4
		var dir_int = Vector2(cos(ang_int), -sin(ang_int))
		if i % 2 == 0:
			draw_line(CENTRO + dir_int * (RADIO_INTERIOR - 26.0), CENTRO + dir_int * (RADIO_INTERIOR - 16.0), col_oro_fuerte, 2.0, true)

func _dibujar_segmento(centro: Vector2, r_in: float, r_out: float, a_ini: float, a_fin: float, nombre_clase: String):
	var config = _obtener_config(nombre_clase)
	var col_base: Color = config.get("color", Color(0.9, 0.8, 0.2))
	var peso = _anim_pesos.get(nombre_clase, 0.0)
	var pulso = 0.5 + 0.5 * sin(_tiempo_pulso * 1.5)

	var r_out_efectivo = lerpf(r_out, r_out + 24.0, peso)
	var r_in_efectivo = lerpf(r_in, r_in - 8.0, peso)

	var alpha_fill = lerpf(0.52, 0.84, peso)
	var col_fill = Color(col_base.r * lerpf(0.65, 1.0, peso), col_base.g * lerpf(0.65, 1.0, peso), col_base.b * lerpf(0.65, 1.0, peso), alpha_fill)
	var col_borde = col_base.lerp(COLOR_BORDE_ORO, 0.25) if peso < 0.1 else col_base.lerp(Color.WHITE, 0.55 + 0.15 * pulso)
	var grosor_borde = lerpf(4.0, 8.0, peso)

	var segmentos = 42
	var puntos_exterior = PackedVector2Array()
	var puntos_interior = PackedVector2Array()
	var puntos_medio = PackedVector2Array()
	var r_medio = (r_in_efectivo + r_out_efectivo) * 0.5

	for i in range(segmentos + 1):
		var t = float(i) / float(segmentos)
		var a = lerpf(a_ini, a_fin, t)
		var dir = Vector2(cos(a), -sin(a))
		puntos_exterior.append(centro + dir * r_out_efectivo)
		puntos_interior.append(centro + dir * r_in_efectivo)
		puntos_medio.append(centro + dir * r_medio)

	var poly = PackedVector2Array()
	for p in puntos_exterior:
		poly.append(p)
	for i in range(puntos_interior.size() - 1, -1, -1):
		poly.append(puntos_interior[i])
	draw_polygon(poly, PackedColorArray([col_fill]))

	var poly_brillo = PackedVector2Array()
	for p in puntos_exterior:
		poly_brillo.append(p)
	for i in range(puntos_medio.size() - 1, -1, -1):
		poly_brillo.append(puntos_medio[i])
	var col_brillo = Color(col_base.r, col_base.g, col_base.b, lerpf(0.18, 0.42, peso))
	draw_polygon(poly_brillo, PackedColorArray([col_brillo]))

	draw_polyline(puntos_medio, Color(1.0, 1.0, 1.0, lerpf(0.16, 0.45, peso)), 2.0, true)

	if peso > 0.05:
		var glow_col = Color(col_base.r, col_base.g, col_base.b, 0.45 * peso)
		draw_polyline(puntos_exterior, glow_col, grosor_borde + 10.0, true)
		draw_polyline(puntos_interior, glow_col, grosor_borde + 6.0, true)

	var borde_completo = PackedVector2Array()
	for p in puntos_exterior:
		borde_completo.append(p)
	for i in range(puntos_interior.size() - 1, -1, -1):
		borde_completo.append(puntos_interior[i])
	borde_completo.append(puntos_exterior[0])

	draw_polyline(borde_completo, col_borde, grosor_borde, true)

func _dibujar_icono_arma(nombre_clase: String, a_ini: float, a_fin: float):
	var config = _obtener_config(nombre_clase)
	var tex: Texture2D = config.get("icono_tex", TEX_ESPADA)
	var col_base: Color = config.get("color", Color.WHITE)
	var a_medio = (a_ini + a_fin) * 0.5
	var peso = _anim_pesos.get(nombre_clase, 0.0)
	var radio_dinamico = lerpf(RADIO_ICONOS, RADIO_ICONOS + 12.0, peso)
	var pos_centro_sector = CENTRO + Vector2(cos(a_medio), -sin(a_medio)) * radio_dinamico

	var radio_medallon = lerpf(54.0, 68.0, peso)
	draw_circle(pos_centro_sector, radio_medallon + 5.0, Color(0.04, 0.05, 0.09, 0.85))
	draw_circle(pos_centro_sector, radio_medallon, Color(col_base.r * 0.25, col_base.g * 0.25, col_base.b * 0.25, 0.92))
	draw_arc(pos_centro_sector, radio_medallon, 0.0, TAU, 48, col_base.lerp(Color.WHITE, 0.35 + 0.35 * peso), lerpf(3.0, 5.0, peso), true)

	if tex != null:
		var escala = lerpf(1.0, 1.32, peso)
		var tam_icono = Vector2(84.0, 84.0) * escala
		var rect_dest = Rect2(pos_centro_sector - tam_icono * 0.5, tam_icono)
		draw_texture_rect(tex, rect_dest, false, col_base.lerp(Color.WHITE, 0.45))

	var font = ThemeDB.fallback_font
	if font != null:
		var texto_clase = nombre_clase.to_upper()
		var font_size = int(lerpf(16.0, 19.0, peso))
		var text_size = font.get_string_size(texto_clase, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var pos_texto = pos_centro_sector + Vector2(-text_size.x * 0.5, radio_medallon + 24.0)
		var rect_pill = Rect2(pos_texto.x - 10.0, pos_texto.y - font_size, text_size.x + 20.0, font_size + 8.0)
		draw_rect(rect_pill, Color(0.04, 0.05, 0.10, 0.88), true)
		draw_rect(rect_pill, col_base.lerp(COLOR_BORDE_ORO, 0.4), false, 1.8)
		draw_string(font, pos_texto, texto_clase, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.96, 0.84, 1.0))
