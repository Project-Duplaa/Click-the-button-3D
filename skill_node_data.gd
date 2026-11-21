class_name SkillNodeData
extends Resource

## SkillNodeData - Recurso de Datos para Nodos del Árbol Interconectado
## Estilo Path of Exile / Nodebreaker con conexiones tipo grafo (DAG).

@export var id: String = ""
@export var nombre: String = ""
@export_multiline var descripcion: String = ""
@export var rama: String = "azul" # "azul", "verde", "dorada", "hibrido", "cosmico", "boton", "central"
@export var posicion: Vector2 = Vector2.ZERO # Coordenadas en el plano virtual 2D
@export var nivel_actual: int = 0
@export var nivel_max: int = 5
@export var tipo_moneda: String = "clics" # "oro", "clics", "ambas"
@export var costo_base_monedas: int = 0
@export var costo_base_clicks: int = 0
@export var costo_base_esquirlas: int = 0
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

func calcular_costo(niveles_totales_arbol: int = 0) -> Dictionary:
	var c_oro: int = 0
	var c_clk: int = 0
	var c_esq: int = 0
	var factor_lvl: float = pow(multiplicador_costo, nivel_actual)
	var factor_global: float = 1.0 + float(maxi(0, niveles_totales_arbol)) * 0.045
	var factor_total: float = factor_lvl * factor_global

	if tipo_moneda == "oro" or tipo_moneda == "ambas":
		c_oro = int(round(float(costo_base_monedas) * factor_total))
	if tipo_moneda == "clics" or tipo_moneda == "ambas":
		c_clk = int(round(float(costo_base_clicks) * factor_total))
	if costo_base_esquirlas > 0:
		c_esq = int(ceil(float(costo_base_esquirlas) * pow(1.35, nivel_actual)))

	return {"oro": c_oro, "clics": c_clk, "esquirlas": c_esq}

static func _fmt_num(val: float, max_decimales: int = 1) -> String:
	if absf(val - round(val)) < 0.001:
		return str(int(round(val)))
	if max_decimales >= 2:
		var s2 := "%.2f" % val
		if s2.ends_with("0"):
			s2 = s2.substr(0, s2.length() - 1)
		return s2
	return "%.1f" % val

func _formatear_valor_stat(val: float) -> String:
	var st := estadistica_afectada
	var signo := "-" if st in ["btn_calor_reduc_pct", "btn_control_orbita_pct"] else "+"
	if st == "suerte":
		return "%s%s Suerte" % [signo, _fmt_num(val, 2)]
	if st.ends_with("_pct") or st.ends_with("_prob") or st in ["penetracion_clic", "frenesi_velocidad_clic"]:
		return "%s%s%%" % [signo, _fmt_num(val, 1)]
	if st.begins_with("radio_") or st == "btn_alcance_palancas":
		return "%s%sm" % [signo, _fmt_num(val, 1)]
	if st == "oro_pasivo_seg":
		return "%s%s Oro/s" % [signo, _fmt_num(val, 1)]
	if st == "regen_vida_seg":
		return "%s%s HP/s" % [signo, _fmt_num(val, 1)]
	if st.ends_with("_seg") or st == "invulnerable_extra_seg":
		return "%s%ss" % [signo, _fmt_num(val, 1)]
	if st == "autoclick_tasa":
		return "%s%s/s" % [signo, _fmt_num(val, 2)]
	if st in ["salud_maxima", "escudo_almas", "clic_cura_escudo"]:
		return "%s%s HP" % [signo, _fmt_num(val, 1)]
	if st == "vida_por_baja":
		return "%s%s HP/baja" % [signo, _fmt_num(val, 1)]
	if st == "armadura_plana":
		return "%s%s Armadura" % [signo, _fmt_num(val, 1)]
	if st in ["clics_por_pulsacion", "btn_clics_bloqueo_extra", "bloqueo_genera_clics"]:
		return "%s%s Clics" % [signo, _fmt_num(val, 1)]
	if st == "vidas_extra":
		return "%s%s Vidas" % [signo, _fmt_num(val, 1)]
	if st == "proyectiles_extra":
		return "%s%s Proyectiles" % [signo, _fmt_num(val, 1)]
	if st == "perforacion_armas":
		return "%s%s Perforación" % [signo, _fmt_num(val, 1)]
	if st in ["dano_sobrecarga", "tempestad_oro_dmg"]:
		return "%s%s Daño" % [signo, _fmt_num(val, 1)]
	if st == "btn_calor_max_extra":
		return "%s%s Calor Máx" % [signo, _fmt_num(val, 1)]
	return "%s%s" % [signo, _fmt_num(val, 1)]

func obtener_texto_bono() -> String:
	var es_estado_binario: bool = es_keystone or estadistica_afectada.begins_with("keystone_") or estadistica_afectada in [
		"origen", "ascension_suprema", "cosm_keystone_genesis", "terremoto_clic_vida", "oro_salud_conversion"
	]
	if es_estado_binario:
		if id == "nodo_origen" or estadistica_afectada == "origen":
			return "ESTADO: ACTIVO (Núcleo Primordial)"
		if esta_comprado() or esta_maxeado():
			if nivel_max > 1 and not esta_maxeado():
				return "ESTADO: ACTIVO (Nv. %d / %d)" % [nivel_actual, nivel_max]
			return "ESTADO: ACTIVO"
		return "ESTADO: INACTIVO"

	var val_act: float = valor_por_nivel * float(nivel_actual)
	var val_sig: float = valor_por_nivel * float(nivel_actual + 1)
	if esta_maxeado() and nivel_max < 999:
		return "Efecto: %s (MAX)" % _formatear_valor_stat(val_act)
	elif nivel_actual == 0:
		return "Siguiente: %s" % _formatear_valor_stat(val_sig)
	else:
		return "Actual: %s  ➔  %s" % [_formatear_valor_stat(val_act), _formatear_valor_stat(val_sig)]
