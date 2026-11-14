class_name Rareza
extends RefCounted

## Rareza - Sistema de Calidades y Rarezas (Clicklike 3D)
## Define los niveles de rareza, colores temáticos y multiplicadores de efecto.

enum Tipo {
	COMUN = 0,
	RARO = 1,
	EPICO = 2,
	LEGENDARIO = 3
}

const COMUN: int = 0
const RARO: int = 1
const EPICO: int = 2
const LEGENDARIO: int = 3

const NOMBRES: Dictionary = {
	0: "Común",
	1: "Raro",
	2: "Épico",
	3: "Legendario"
}

const COLORES: Dictionary = {
	0: Color(0.65, 0.65, 0.65, 1.0),   # Gris
	1: Color(0.20, 0.60, 1.0, 1.0),    # Azul
	2: Color(0.70, 0.25, 0.95, 1.0),   # Morado
	3: Color(1.0, 0.82, 0.10, 1.0)     # Dorado
}

const MULTIPLICADORES: Dictionary = {
	0: 1.0,
	1: 1.5,
	2: 2.0,
	3: 3.0
}

static func obtener_nombre(rareza: int) -> String:
	return NOMBRES.get(rareza, "Común")

static func obtener_color(rareza: int) -> Color:
	return COLORES.get(rareza, Color(0.65, 0.65, 0.65, 1.0))

static func obtener_multiplicador(rareza: int) -> float:
	return MULTIPLICADORES.get(rareza, 1.0)
