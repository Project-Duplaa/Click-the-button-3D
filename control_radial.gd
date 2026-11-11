@tool
extends Control
class_name ControlRadial

## ControlRadial - Réplica visual fiel del diseño In-World
## Dibuja 3 segmentos circulares curvados independientes con separación angular,
## texturas de iconos de armas limpias (Espada, Arco, Bastón),
## bocadillo tooltip flotante con cola triangular apuntando al sector activo,
## y resplandor cian eléctrico cuando se sobrevuela Mago (o el color correspondiente).

signal clase_resaltada(nombre_clase: String)
signal clase_confirmada(nombre_clase: String)

const TAMANO_VIEWPORT: Vector2 = Vector2(768.0, 768.0)
const CENTRO: Vector2 = Vector2(384.0, 384.0)

const RADIO_INTERIOR: float = 110.0
const RADIO_EXTERIOR: float = 230.0
const RADIO_ICONOS: float = 170.0
const GAP_ANGULAR_DEG: float = 7.0 # Separación entre sectores

# Colores fieles a la imagen de referencia
const COLOR_GUERRERO: Color = Color(0.88, 0.24, 0.22, 1.0) # Rojo
const COLOR_CAZADOR: Color = Color(0.24, 0.78, 0.38, 1.0)  # Verde
const COLOR_MAGO: Color = Color(0.22, 0.58, 0.95, 1.0)     # Azul / Cian
const COLOR_BORDE_ORO: Color = Color(0.88, 0.72, 0.35, 1.0) # Oro HUD

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
		"linea1": "• Tanque / Alto Impacto",
		"linea2": "• +60% Salud\n• +83% Daño Melee",
		"accion": "[Clic para evolucionar]"
	},
	"Cazador": {
		"color": COLOR_CAZADOR,
		"angulo_centro_deg": 30.0,
		"icono_tex": TEX_ARCO,
		"titulo": "CAZADOR",
		"subtitulo": "Ranger / Ráfaga Veloz",
		"linea1": "• Ranger / Ráfaga Veloz",
		"linea2": "• +16% Daño\n• Vel. Carrera: 6.4 m/s",
		"accion": "[Clic para evolucionar]"
	},
	"Mago": {
		"color": COLOR_MAGO,
		"angulo_centro_deg": 270.0,
		"icono_tex": TEX_BASTON,
		"titulo": "MAGO",
		"subtitulo": "Arcanista / Alto Impacto",
		"linea1": "• Arcanista / Alto Impacto",
		"linea2": "• +133% Daño Mágico",
		"accion": "[Clic para evolucionar]"
	}
}

var clase_seleccionada: String = "Mago" # Inicia en Mago o vacía
var _anim_pesos: Dictionary = {
	"Guerrero": 0.0,
	"Cazador": 0.0,
	"Mago": 1.0
}
var _tiempo_pulso: float = 0.0

@onready var tooltip_flotante: PanelContainer = $TooltipFlotante
@onready var label_titulo: Label = $TooltipFlotante/Margin/VBox/LabelTitulo
@onready var label_linea1: Label = $TooltipFlotante/Margin/VBox/LabelLinea1
@onready var label_linea2: Label = $TooltipFlotante/Margin/VBox/LabelLinea2
@onready var label_accion: Label = $TooltipFlotante/Margin/VBox/LabelAccion

func _ready():
	custom_minimum_size = TAMANO_VIEWPORT
	_actualizar_tooltip(clase_seleccionada)
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
	_actualizar_tooltip(nombre_clase)
	queue_redraw()

func _actualizar_tooltip(nombre_clase: String):
	if tooltip_flotante == null or not CONFIG_CLASES.has(nombre_clase):
		return
	var info = CONFIG_CLASES[nombre_clase]
	label_titulo.text = info["titulo"]
	label_linea1.text = info["linea1"]
	label_linea2.text = info["linea2"]
	label_accion.text = info["accion"]
	
	# Posición del bocadillo idéntica a la captura de referencia:
	# En la captura, con Mago activo, el Tooltip flota a la derecha del personaje,
	# sobre el sector verde/azul, sin tapar al héroe
	var pos_tooltip = Vector2.ZERO
	match nombre_clase:
		"Mago":
			pos_tooltip = Vector2(460.0, 230.0) # Al lado derecho de la cabeza
		"Guerrero":
			pos_tooltip = Vector2(50.0, 200.0)
		"Cazador":
			pos_tooltip = Vector2(470.0, 160.0)
			
	tooltip_flotante.visible = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(tooltip_flotante, "position", pos_tooltip, 0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(tooltip_flotante, "modulate:a", 1.0, 0.20)

func ocultar_tooltip():
	if tooltip_flotante != null and tooltip_flotante.visible:
		var tw = create_tween()
		tw.tween_property(tooltip_flotante, "modulate:a", 0.0, 0.15)
		tw.tween_callback(func(): tooltip_flotante.visible = false)

func confirmar_clase(nombre_clase: String):
	if nombre_clase != "":
		emit_signal("clase_confirmada", nombre_clase)

func confirmar_seleccion_actual():
	if clase_seleccionada != "":
		confirmar_clase(clase_seleccionada)

# =========================================================================
# DIBUJADO PROCEDURAL FIEL A LA REFERENCIA
# =========================================================================
func _draw():
	var gap_rad = deg_to_rad(GAP_ANGULAR_DEG)
	
	# Límites angulares con separación:
	# Cazador: centrado en 30° (desde -30° + gap hasta 90° - gap)
	var a_caz_ini = -PI / 6.0 + gap_rad
	var a_caz_fin = PI / 2.0 - gap_rad
	
	# Guerrero: centrado en 150° (desde 90° + gap hasta 210° - gap)
	var a_gue_ini = PI / 2.0 + gap_rad
	var a_gue_fin = (7.0 * PI / 6.0) - gap_rad
	
	# Mago: centrado en 270° (desde 210° + gap hasta 330° - gap)
	var a_mag_ini = (7.0 * PI / 6.0) + gap_rad
	var a_mag_fin = (11.0 * PI / 6.0) - gap_rad
	
	# Dibujar los 3 segmentos
	_dibujar_segmento(CENTRO, RADIO_INTERIOR, RADIO_EXTERIOR, a_gue_ini, a_gue_fin, "Guerrero")
	_dibujar_segmento(CENTRO, RADIO_INTERIOR, RADIO_EXTERIOR, a_caz_ini, a_caz_fin, "Cazador")
	_dibujar_segmento(CENTRO, RADIO_INTERIOR, RADIO_EXTERIOR, a_mag_ini, a_mag_fin, "Mago")
	
	# Dibujar los iconos de armas en el centro de cada sector
	_dibujar_icono_arma("Guerrero", a_gue_ini, a_gue_fin)
	_dibujar_icono_arma("Cazador", a_caz_ini, a_caz_fin)
	_dibujar_icono_arma("Mago", a_mag_ini, a_mag_fin)
	
	# Dibujar la cola de bocadillo del Tooltip apuntando al sector seleccionado
	_dibujar_cola_tooltip()

func _dibujar_segmento(centro: Vector2, r_in: float, r_out: float, a_ini: float, a_fin: float, nombre_clase: String):
	var peso = _anim_pesos.get(nombre_clase, 0.0)
	var col_base = CONFIG_CLASES[nombre_clase]["color"]
	
	# Relleno translúcido
	var alpha_fill = lerpf(0.42, 0.65, peso)
	var col_fill = Color(col_base.r, col_base.g, col_base.b, alpha_fill)
	
	# Borde: cuando está activo, brillo más intenso y mayor grosor
	var col_borde = col_base if peso < 0.1 else col_base.lerp(Color.WHITE, 0.35)
	var grosor_borde = lerpf(3.0, 5.0, peso)
	
	var segmentos = 32
	var puntos_exterior = PackedVector2Array()
	var puntos_interior = PackedVector2Array()
	
	for i in range(segmentos + 1):
		var t = float(i) / segmentos
		var a = lerpf(a_ini, a_fin, t)
		puntos_exterior.append(centro + Vector2(cos(a), -sin(a)) * r_out)
		puntos_interior.append(centro + Vector2(cos(a), -sin(a)) * r_in)
		
	# Polígono cerrado para relleno
	var poly = PackedVector2Array()
	for p in puntos_exterior:
		poly.append(p)
	for i in range(puntos_interior.size() - 1, -1, -1):
		poly.append(puntos_interior[i])
		
	draw_polygon(poly, PackedColorArray([col_fill]))
	
	# Si está activo, resplandor exterior suave
	if peso > 0.1:
		var glow_col = Color(col_base.r, col_base.g, col_base.b, 0.35 * peso)
		draw_polyline(puntos_exterior, glow_col, grosor_borde + 4.0, true)
		draw_polyline(puntos_interior, glow_col, grosor_borde + 3.0, true)
		
	# Contorno del sector
	var borde_completo = PackedVector2Array()
	for p in puntos_exterior:
		borde_completo.append(p)
	for i in range(puntos_interior.size() - 1, -1, -1):
		borde_completo.append(puntos_interior[i])
	borde_completo.append(puntos_exterior[0]) # Cerrar loop
	
	draw_polyline(borde_completo, col_borde, grosor_borde, true)

func _dibujar_icono_arma(nombre_clase: String, a_ini: float, a_fin: float):
	var tex: Texture2D = CONFIG_CLASES[nombre_clase]["icono_tex"]
	if tex == null:
		return
		
	var a_medio = (a_ini + a_fin) * 0.5
	var pos_centro_sector = CENTRO + Vector2(cos(a_medio), -sin(a_medio)) * RADIO_ICONOS
	
	var peso = _anim_pesos.get(nombre_clase, 0.0)
	var escala = lerpf(1.0, 1.20, peso)
	var tam_icono = Vector2(60.0, 60.0) * escala
	
	var rect_dest = Rect2(pos_centro_sector - tam_icono * 0.5, tam_icono)
	draw_texture_rect(tex, rect_dest, false)

func _dibujar_cola_tooltip():
	if tooltip_flotante == null or not tooltip_flotante.visible:
		return
		
	# Dibuja la cola triangular que une el tooltip con el sector activo (idéntica a la referencia)
	var rect_tip = tooltip_flotante.get_rect()
	var p_origen1 = Vector2(rect_tip.position.x, rect_tip.position.y + rect_tip.size.y - 12.0)
	var p_origen2 = Vector2(rect_tip.position.x + 14.0, rect_tip.position.y + rect_tip.size.y)
	
	# Punto hacia el que apunta la cola (el sector azul de Mago u otro)
	var p_destino = CENTRO + Vector2(cos(deg_to_rad(270.0)), -sin(deg_to_rad(270.0))) * (RADIO_EXTERIOR - 10.0)
	if clase_seleccionada == "Guerrero":
		p_destino = CENTRO + Vector2(cos(deg_to_rad(150.0)), -sin(deg_to_rad(150.0))) * (RADIO_EXTERIOR - 10.0)
		p_origen1 = Vector2(rect_tip.position.x + rect_tip.size.x, rect_tip.position.y + rect_tip.size.y - 12.0)
		p_origen2 = Vector2(rect_tip.position.x + rect_tip.size.x - 14.0, rect_tip.position.y + rect_tip.size.y)
	elif clase_seleccionada == "Cazador":
		p_destino = CENTRO + Vector2(cos(deg_to_rad(30.0)), -sin(deg_to_rad(30.0))) * (RADIO_EXTERIOR - 10.0)
		
	var triangulo = PackedVector2Array([p_origen1, p_origen2, p_destino])
	draw_polygon(triangulo, PackedColorArray([Color(0.08, 0.10, 0.14, 0.95)]))
	draw_line(p_origen1, p_destino, COLOR_BORDE_ORO, 1.5, true)
	draw_line(p_origen2, p_destino, COLOR_BORDE_ORO, 1.5, true)
