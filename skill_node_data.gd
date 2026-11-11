class_name SkillNodeData
extends Resource

## SkillNodeData - Recurso de Datos para Nodos del Árbol Interconectado
## Estilo Path of Exile / Nodebreaker con conexiones tipo grafo (DAG).

@export var id: String = ""
@export var nombre: String = ""
@export_multiline var descripcion: String = ""
@export var rama: String = "azul" # "azul" (Clics Activo), "verde" (Supervivencia), "dorada" (Economía/Idle), "central"
@export var posicion: Vector2 = Vector2.ZERO # Coordenadas en el plano virtual 2D
@export var nivel_actual: int = 0
@export var nivel_max: int = 5
@export var tipo_moneda: String = "clics" # "oro", "clics", "ambas"
@export var costo_base_monedas: int = 0
@export var costo_base_clicks: int = 0
@export var multiplicador_costo: float = 1.45
@export var estadistica_afectada: String = ""
@export var valor_por_nivel: float = 1.0
@export var nodos_conectados: Array[String] = [] # IDs de nodos vecinos en la red
@export var es_keystone: bool = false # Nodo Mayor / Keystone de alto impacto
@export var icono: String = "⭐"

func esta_comprado() -> bool:
	return nivel_actual > 0

func esta_maxeado() -> bool:
	return nivel_actual >= nivel_max

func calcular_costo() -> Dictionary:
	var c_oro = 0
	var c_clk = 0
	var factor = pow(multiplicador_costo, nivel_actual)
	
	if tipo_moneda == "oro" or tipo_moneda == "ambas":
		c_oro = int(round(costo_base_monedas * factor))
	if tipo_moneda == "clics" or tipo_moneda == "ambas":
		c_clk = int(round(costo_base_clicks * factor))
		
	return {"oro": c_oro, "clics": c_clk}

func obtener_texto_bono() -> String:
	var val_act = valor_por_nivel * nivel_actual
	var val_sig = valor_por_nivel * (nivel_actual + 1)
	if esta_maxeado():
		return "Efecto Actual: +%.1f (¡MAX!)" % val_act
	elif nivel_actual == 0:
		return "Siguiente Nivel: +%.1f" % val_sig
	else:
		return "Actual: +%.1f  ➔  Siguiente: +%.1f" % [val_act, val_sig]
