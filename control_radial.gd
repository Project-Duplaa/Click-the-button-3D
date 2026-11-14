@tool
extends Control
class_name ControlRadial

## ControlRadial - Réplica visual fiel del diseño In-World (Diseño 3)
## Dibuja 3 sectores circulares curvados independientes sobre el suelo con separación angular de 7°,
## texturas de iconos de armas limpias (Espada, Arco, Bastón),
## e iluminación / resplandor reactivo según el cursor del jugador.

signal clase_resaltada(nombre_clase: String)
signal clase_confirmada(nombre_clase: String)

const TAMANO_VIEWPORT: Vector2 = Vector2(768.0, 768.0)
const CENTRO: Vector2 = Vector2(384.0, 384.0)

const RADIO_INTERIOR: float = 135.0
const RADIO_EXTERIOR: float = 250.0
const RADIO_ICONOS: float = 192.5
const GAP_ANGULAR_DEG: float = 7.0 # Separación entre sectores

# Colores fieles a la imagen de referencia
const COLOR_GUERRERO: Color = Color(0.90, 0.22, 0.27, 1.0) # Rojo (#E63946)
const COLOR_CAZADOR: Color = Color(0.18, 0.77, 0.71, 1.0)  # Verde esmeralda (#2EC4B6)
const COLOR_MAGO: Color = Color(0.23, 0.53, 1.00, 1.0)     # Azul / Cian (#3A86FF)
const COLOR_BORDE_ORO: Color = Color(0.88, 0.72, 0.35, 1.0)

const TEX_ESPADA = preload("res://ui_assets/icono_espada.png")
const TEX_ARCO = preload("res://ui_assets/icono_arco.png")
const TEX_BASTON = preload("res://ui_assets/icono_baston.png")

const CONFIG_CLASES = {
	"Guerrero": {
		"color": COLOR_GUERRERO,
		"angulo_centro_deg": 150.0,
		"icono_tex": TEX_ESPADA,
		"titulo": "GUERRERO",
		"subtitulo": "Tanque / Alto Impacto",
		"stats_bbcode": "• Tanque / Alto Impacto\n• [color=#56E39F]+60% Salud[/color]\n• [color=#56E39F]+83% Daño Melee[/color]",
		"accion": "[Clic para evolucionar]"
	},
	"Cazador": {
		"color": COLOR_CAZADOR,
		"angulo_centro_deg": 30.0,
		"icono_tex": TEX_ARCO,
		"titulo": "CAZADOR",
		"subtitulo": "Ranger / Ráfaga Veloz",
		"stats_bbcode": "• Ranger / Ráfaga Veloz\n• [color=#56E39F]+16% Daño[/color]\n• [color=#56E39F]Vel. Carrera: 6.4 m/s[/color]",
		"accion": "[Clic para evolucionar]"
	},
	"Mago": {
		"color": COLOR_MAGO,
		"angulo_centro_deg": 270.0,
		"icono_tex": TEX_BASTON,
		"titulo": "MAGO",
		"subtitulo": "Arcanista / Alto Impacto",
		"stats_bbcode": "• Arcanista / Alto Impacto\n• [color=#56E39F]+133% Daño Mágico[/color]",
		"accion": "[Clic para evolucionar]"
	}
}

# Inicialmente vacía para no auto-seleccionar accidentalmente
var clase_seleccionada: String = ""
var _anim_pesos: Dictionary = {
	"Guerrero": 0.0,
	"Cazador": 0.0,
	"Mago": 0.0
}
var _tiempo_pulso: float = 0.0

func _ready():
	custom_minimum_size = TAMANO_VIEWPORT
	queue_redraw()

func _process(delta: float):
	_tiempo_pulso += delta * 4.0
	var necesita_redraw = false
	for k in _anim_pesos.keys():
		var destino = 1.0 if k == clase_seleccionada else 0.0
		var actual = _anim_pesos[k]
		if abs(actual - destino) > 0.01:
			_anim_pesos[k] = lerpf(actual, destino, delta * 12.0)
			necesita_redraw = true
		else:
			_anim_pesos[k] = destino
			
	if necesita_redraw or clase_seleccionada != "":
		queue_redraw()

func actualizar_por_angulo(angulo_deg: float):
	if angulo_deg < 0.0:
		return
	var ang = fposmod(angulo_deg, 360.0)
	var nueva_clase = "Cazador" if (ang >= 330.0 or ang < 90.0) else ("Guerrero" if (ang >= 90.0 and ang < 210.0) else "Mago")
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

# =========================================================================
# DIBUJADO PROCEDURAL DEL ANILLO Y LOS ICONOS
# =========================================================================
func _draw():
	var gap_rad = deg_to_rad(GAP_ANGULAR_DEG)
	
	# Cazador: centrado en 30°
	var a_caz_ini = -PI / 6.0 + gap_rad
	var a_caz_fin = PI / 2.0 - gap_rad
	
	# Guerrero: centrado en 150°
	var a_gue_ini = PI / 2.0 + gap_rad
	var a_gue_fin = (7.0 * PI / 6.0) - gap_rad
	
	# Mago: centrado en 270°
	var a_mag_ini = (7.0 * PI / 6.0) + gap_rad
	var a_mag_fin = (11.0 * PI / 6.0) - gap_rad
	
	# 1. Dibujar los 3 segmentos con bordes curvos
	_dibujar_segmento(CENTRO, RADIO_INTERIOR, RADIO_EXTERIOR, a_gue_ini, a_gue_fin, "Guerrero")
	_dibujar_segmento(CENTRO, RADIO_INTERIOR, RADIO_EXTERIOR, a_caz_ini, a_caz_fin, "Cazador")
	_dibujar_segmento(CENTRO, RADIO_INTERIOR, RADIO_EXTERIOR, a_mag_ini, a_mag_fin, "Mago")
	
	# 2. Dibujar los iconos de armas en el centro de cada sector
	_dibujar_icono_arma("Guerrero", a_gue_ini, a_gue_fin)
	_dibujar_icono_arma("Cazador", a_caz_ini, a_caz_fin)
	_dibujar_icono_arma("Mago", a_mag_ini, a_mag_fin)

func _dibujar_segmento(centro: Vector2, r_in: float, r_out: float, a_ini: float, a_fin: float, nombre_clase: String):
	var peso = _anim_pesos.get(nombre_clase, 0.0)
	var col_base = CONFIG_CLASES[nombre_clase]["color"]
	
	# Escala suave del radio exterior al seleccionarse
	var r_out_efectivo = lerpf(r_out, r_out + 12.0, peso)
	
	# Relleno translúcido
	var alpha_fill = lerpf(0.40, 0.70, peso)
	var col_fill = Color(col_base.r, col_base.g, col_base.b, alpha_fill)
	
	# Borde luminoso
	var col_borde = col_base if peso < 0.1 else col_base.lerp(Color.WHITE, 0.40)
	var grosor_borde = lerpf(3.0, 5.5, peso)
	
	var segmentos = 36
	var puntos_exterior = PackedVector2Array()
	var puntos_interior = PackedVector2Array()
	
	for i in range(segmentos + 1):
		var t = float(i) / float(segmentos)
		var a = lerpf(a_ini, a_fin, t)
		puntos_exterior.append(centro + Vector2(cos(a), -sin(a)) * r_out_efectivo)
		puntos_interior.append(centro + Vector2(cos(a), -sin(a)) * r_in)
		
	# Polígono cerrado de relleno
	var poly = PackedVector2Array()
	for p in puntos_exterior:
		poly.append(p)
	for i in range(puntos_interior.size() - 1, -1, -1):
		poly.append(puntos_interior[i])
		
	draw_polygon(poly, PackedColorArray([col_fill]))
	
	# Resplandor exterior si está seleccionado
	if peso > 0.08:
		var glow_col = Color(col_base.r, col_base.g, col_base.b, 0.38 * peso)
		draw_polyline(puntos_exterior, glow_col, grosor_borde + 4.5, true)
		draw_polyline(puntos_interior, glow_col, grosor_borde + 3.0, true)
		
	# Contorno del sector
	var borde_completo = PackedVector2Array()
	for p in puntos_exterior:
		borde_completo.append(p)
	for i in range(puntos_interior.size() - 1, -1, -1):
		borde_completo.append(puntos_interior[i])
	borde_completo.append(puntos_exterior[0])
	
	draw_polyline(borde_completo, col_borde, grosor_borde, true)

func _dibujar_icono_arma(nombre_clase: String, a_ini: float, a_fin: float):
	var tex: Texture2D = CONFIG_CLASES[nombre_clase]["icono_tex"]
	if tex == null:
		return
		
	var a_medio = (a_ini + a_fin) * 0.5
	var pos_centro_sector = CENTRO + Vector2(cos(a_medio), -sin(a_medio)) * RADIO_ICONOS
	
	var peso = _anim_pesos.get(nombre_clase, 0.0)
	var escala = lerpf(1.0, 1.25, peso)
	var tam_icono = Vector2(62.0, 62.0) * escala
	
	var rect_dest = Rect2(pos_centro_sector - tam_icono * 0.5, tam_icono)
	draw_texture_rect(tex, rect_dest, false)
