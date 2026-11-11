@tool
extends Control
class_name ControlRadial

## ControlRadial (UI 2D In-World para Menú Radial de Evolución)
## Renderiza proceduralmente un anillo rúnico de 3 sectores (120° c/u),
## detecta el sector apuntado por mouse o gamepad, gestiona animaciones
## de hover (Tween de escala y brillo) y despliega el tooltip flotante con estética dark fantasy.

signal clase_resaltada(nombre_clase: String)
signal clase_confirmada(nombre_clase: String)

const TAMANO_VIEWPORT: Vector2 = Vector2(768.0, 768.0)
const CENTRO: Vector2 = Vector2(384.0, 384.0)

const RADIO_INTERIOR: float = 85.0
const RADIO_EXTERIOR: float = 245.0
const RADIO_ICONOS: float = 165.0

# Colores vivos solicitados
const COLOR_GUERRERO: Color = Color("#E63946") # Rojo
const COLOR_CAZADOR: Color = Color("#2EC4B6")  # Verde
const COLOR_MAGO: Color = Color("#3A86FF")     # Azul
const COLOR_BORDE_ORO: Color = Color(0.85, 0.70, 0.35, 0.95)

# Datos de clases, ángulos y descripciones para Tooltip
const CONFIG_CLASES = {
	"Guerrero": {
		"color": COLOR_GUERRERO,
		"angulo_centro_deg": 150.0, # Izquierda / Atrás
		"icono": "⚔️",
		"titulo": "GUERRERO",
		"subtitulo": "Tanque / Alto Impacto",
		"stats": "[color=#52b788]+60% Salud Máxima[/color]\n[color=#52b788]+83% Daño Melee en Cono[/color]\n[color=#ffd166]Bloqueo Defensivo [F / Q / Clic Der][/color]",
		"accion": "[Clic Izq / Botón A para evolucionar]"
	},
	"Cazador": {
		"color": COLOR_CAZADOR,
		"angulo_centro_deg": 30.0,  # Derecha / Atrás
		"icono": "🏹",
		"titulo": "CAZADOR",
		"subtitulo": "Ranger / Ráfaga Veloz",
		"stats": "[color=#52b788]+16% Daño Base[/color]\n[color=#52b788]Vel. Carrera: 6.4 m/s[/color]\n[color=#ffd166]Proyectiles Rápidos a Distancia[/color]",
		"accion": "[Clic Izq / Botón A para evolucionar]"
	},
	"Mago": {
		"color": COLOR_MAGO,
		"angulo_centro_deg": 270.0, # Frente (hacia cámara)
		"icono": "🔮",
		"titulo": "MAGO",
		"subtitulo": "Arcanista / Alto Impacto",
		"stats": "[color=#52b788]+133% Daño Mágico Arcano[/color]\n[color=#52b788]Orbes de Energía Dirigidos[/color]\n[color=#ffd166]Ataques de Área Mágica[/color]",
		"accion": "[Clic Izq / Botón A para evolucionar]"
	}
}

var clase_seleccionada: String = ""
var _angulo_apuntado_deg: float = -1.0
var _anim_pesos: Dictionary = {
	"Guerrero": 0.0,
	"Cazador": 0.0,
	"Mago": 0.0
}

@onready var contenedor_iconos: Control = $ContenedorIconos
@onready var btn_guerrero: Button = $ContenedorIconos/BtnGuerrero
@onready var btn_cazador: Button = $ContenedorIconos/BtnCazador
@onready var btn_mago: Button = $ContenedorIconos/BtnMago

@onready var tooltip_flotante: PanelContainer = $TooltipFlotante
@onready var label_titulo: Label = $TooltipFlotante/Margin/VBox/LabelTitulo
@onready var label_subtitulo: Label = $TooltipFlotante/Margin/VBox/LabelSubtitulo
@onready var label_stats: RichTextLabel = $TooltipFlotante/Margin/VBox/LabelStats
@onready var label_accion: Label = $TooltipFlotante/Margin/VBox/LabelAccion

var _tiempo_pulso: float = 0.0

func _ready():
	custom_minimum_size = TAMANO_VIEWPORT
	
	if tooltip_flotante != null:
		tooltip_flotante.modulate.a = 0.0
		tooltip_flotante.visible = false
	
	_posicionar_botones()
	_conectar_senales_botones()

func _process(delta: float):
	_tiempo_pulso += delta * 4.0
	
	# Interpolación suave de los factores de brillo y escala para cada sector
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

func _posicionar_botones():
	for nombre_clase in CONFIG_CLASES.keys():
		var btn: Button = _obtener_boton(nombre_clase)
		if btn == null:
			continue
			
		var info = CONFIG_CLASES[nombre_clase]
		var ang_rad = deg_to_rad(info["angulo_centro_deg"])
		# En espacio de textura 2D: +X a la derecha, +Y hacia abajo
		# El ángulo estándar en GDScript: cos(a) es X, -sin(a) es Y para que 90° sea arriba
		var pos_local = CENTRO + Vector2(cos(ang_rad), -sin(ang_rad)) * RADIO_ICONOS
		
		btn.custom_minimum_size = Vector2(76.0, 76.0)
		btn.pivot_offset = Vector2(38.0, 38.0)
		btn.position = pos_local - btn.pivot_offset
		btn.text = "%s\n%s" % [info["icono"], info["titulo"]]
		btn.focus_mode = Control.FOCUS_NONE

func _conectar_senales_botones():
	for nombre_clase in CONFIG_CLASES.keys():
		var btn: Button = _obtener_boton(nombre_clase)
		if btn == null:
			continue
		var nc = nombre_clase
		btn.mouse_entered.connect(func(): seleccionar_clase(nc))
		btn.pressed.connect(func(): confirmar_clase(nc))

func _obtener_boton(nombre_clase: String) -> Button:
	match nombre_clase:
		"Guerrero": return btn_guerrero
		"Cazador": return btn_cazador
		"Mago": return btn_mago
	return null

## Actualiza la selección basándose en el ángulo del puntero / stick (0° a 360°)
func actualizar_por_angulo(angulo_deg: float):
	if angulo_deg < 0.0:
		return
	
	_angulo_apuntado_deg = fposmod(angulo_deg, 360.0)
	var nueva_clase = _determinar_clase_por_angulo(_angulo_apuntado_deg)
	if nueva_clase != clase_seleccionada:
		seleccionar_clase(nueva_clase)

func _determinar_clase_por_angulo(ang: float) -> String:
	# 3 sectores exactos de 120°:
	# Cazador: centrado en 30° -> de 330° a 90°
	# Guerrero: centrado en 150° -> de 90° a 210°
	# Mago: centrado en 270° -> de 210° a 330°
	if ang >= 330.0 or ang < 90.0:
		return "Cazador"
	elif ang >= 90.0 and ang < 210.0:
		return "Guerrero"
	else:
		return "Mago"

func seleccionar_clase(nombre_clase: String):
	if clase_seleccionada == nombre_clase:
		return
		
	clase_seleccionada = nombre_clase
	emit_signal("clase_resaltada", nombre_clase)
	
	_animar_botones_hover(nombre_clase)
	_actualizar_tooltip(nombre_clase)
	queue_redraw()

func _animar_botones_hover(clase_activa: String):
	for k in CONFIG_CLASES.keys():
		var btn = _obtener_boton(k)
		if btn == null:
			continue
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if k == clase_activa:
			tw.tween_property(btn, "scale", Vector2(1.22, 1.22), 0.20)
		else:
			tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)

func _actualizar_tooltip(nombre_clase: String):
	if tooltip_flotante == null or not CONFIG_CLASES.has(nombre_clase):
		return
		
	var info = CONFIG_CLASES[nombre_clase]
	label_titulo.text = info["titulo"]
	label_titulo.modulate = info["color"]
	label_subtitulo.text = info["subtitulo"]
	label_stats.text = info["stats"]
	label_accion.text = info["accion"]
	
	# Calcular posición óptima del tooltip para no tapar al personaje en el centro
	var pos_tooltip = Vector2.ZERO
	match nombre_clase:
		"Guerrero":
			# Cuadrante superior izquierdo
			pos_tooltip = Vector2(40.0, 110.0)
		"Cazador":
			# Cuadrante superior derecho
			pos_tooltip = Vector2(480.0, 110.0)
		"Mago":
			# Cuadrante inferior (hacia el lateral para despejar los pies)
			pos_tooltip = Vector2(480.0, 470.0)
			
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
# DIBUJADO PROCEDURAL DEL ANILLO Y SECTORES
# =========================================================================
func _draw():
	# 1. Fondo exterior / viñeta sutil
	draw_circle(CENTRO, RADIO_EXTERIOR + 12.0, Color(0.04, 0.05, 0.08, 0.55))
	
	# 2. Anillo base de piedra oscura
	_dibujar_anillo_vacio(CENTRO, RADIO_INTERIOR, RADIO_EXTERIOR, Color(0.08, 0.10, 0.14, 0.88))
	
	# 3. Dibujar los 3 sectores con sus colores y pesos de brillo
	# Rango de radianes (convirtiendo de polar con Y invertida):
	# Cazador (30° centro): de -30° (-PI/6) a 90° (PI/2)
	_dibujar_sector_anillo(CENTRO, RADIO_INTERIOR + 4.0, RADIO_EXTERIOR - 4.0, -PI / 6.0, PI / 2.0, "Cazador")
	# Guerrero (150° centro): de 90° (PI/2) a 210° (7*PI/6)
	_dibujar_sector_anillo(CENTRO, RADIO_INTERIOR + 4.0, RADIO_EXTERIOR - 4.0, PI / 2.0, 7.0 * PI / 6.0, "Guerrero")
	# Mago (270° centro): de 210° (7*PI/6) a 330° (11*PI/6)
	_dibujar_sector_anillo(CENTRO, RADIO_INTERIOR + 4.0, RADIO_EXTERIOR - 4.0, 7.0 * PI / 6.0, 11.0 * PI / 6.0, "Mago")
	
	# 4. Líneas divisorias ornamentales entre sectores (a 90°, 210° y 330°)
	_dibujar_divisor_radial(CENTRO, RADIO_INTERIOR - 6.0, RADIO_EXTERIOR + 8.0, PI / 2.0)
	_dibujar_divisor_radial(CENTRO, RADIO_INTERIOR - 6.0, RADIO_EXTERIOR + 8.0, 7.0 * PI / 6.0)
	_dibujar_divisor_radial(CENTRO, RADIO_INTERIOR - 6.0, RADIO_EXTERIOR + 8.0, 11.0 * PI / 6.0)
	
	# 5. Anillos dorados concéntricos de filigrana
	draw_arc(CENTRO, RADIO_EXTERIOR, 0, TAU, 64, COLOR_BORDE_ORO, 3.0, true)
	draw_arc(CENTRO, RADIO_EXTERIOR - 8.0, 0, TAU, 64, Color(COLOR_BORDE_ORO.r, COLOR_BORDE_ORO.g, COLOR_BORDE_ORO.b, 0.4), 1.5, true)
	draw_arc(CENTRO, RADIO_INTERIOR, 0, TAU, 48, COLOR_BORDE_ORO, 2.5, true)
	draw_arc(CENTRO, RADIO_INTERIOR + 6.0, 0, TAU, 48, Color(COLOR_BORDE_ORO.r, COLOR_BORDE_ORO.g, COLOR_BORDE_ORO.b, 0.4), 1.5, true)
	
	# 6. Dientes / Runas decorativas en el borde exterior
	for i in range(24):
		var ang = (TAU / 24.0) * i
		var p1 = CENTRO + Vector2(cos(ang), sin(ang)) * (RADIO_EXTERIOR - 2.0)
		var p2 = CENTRO + Vector2(cos(ang), sin(ang)) * (RADIO_EXTERIOR + 6.0)
		draw_line(p1, p2, COLOR_BORDE_ORO, 1.5, true)

func _dibujar_anillo_vacio(centro: Vector2, r_in: float, r_out: float, col: Color):
	var segmentos = 64
	var puntos = PackedVector2Array()
	for i in range(segmentos + 1):
		var a = (TAU / segmentos) * i
		puntos.append(centro + Vector2(cos(a), sin(a)) * r_out)
	for i in range(segmentos, -1, -1):
		var a = (TAU / segmentos) * i
		puntos.append(centro + Vector2(cos(a), sin(a)) * r_in)
	draw_polygon(puntos, PackedColorArray([col]))

func _dibujar_sector_anillo(centro: Vector2, r_in: float, r_out: float, ang_ini: float, ang_fin: float, nombre_clase: String):
	var peso = _anim_pesos.get(nombre_clase, 0.0)
	var col_base = CONFIG_CLASES[nombre_clase]["color"]
	
	# Color desaturado atenuado cuando está inactivo
	var col_inactivo = Color(col_base.r * 0.35, col_base.g * 0.35, col_base.b * 0.35, 0.22)
	# Color brillante activo con pulso sutil
	var brillo_pulso = 1.0 + sin(_tiempo_pulso) * 0.08
	var col_activo = Color(col_base.r * brillo_pulso, col_base.g * brillo_pulso, col_base.b * brillo_pulso, 0.72)
	
	var col_final = col_inactivo.lerp(col_activo, peso)
	
	var segmentos = 24
	var puntos = PackedVector2Array()
	# En Godot 2D dibujamos el arco en sentido horario
	for i in range(segmentos + 1):
		var a = lerpf(ang_ini, ang_fin, float(i) / segmentos)
		puntos.append(centro + Vector2(cos(a), -sin(a)) * r_out)
	for i in range(segmentos, -1, -1):
		var a = lerpf(ang_ini, ang_fin, float(i) / segmentos)
		puntos.append(centro + Vector2(cos(a), -sin(a)) * r_in)
		
	draw_polygon(puntos, PackedColorArray([col_final]))
	
	# Si está activo, resaltar los bordes del sector con luz
	if peso > 0.05:
		var col_linea = Color(col_base.r, col_base.g, col_base.b, 0.85 * peso)
		for i in range(segmentos):
			var a1 = lerpf(ang_ini, ang_fin, float(i) / segmentos)
			var a2 = lerpf(ang_ini, ang_fin, float(i + 1) / segmentos)
			var p1 = centro + Vector2(cos(a1), -sin(a1)) * r_out
			var p2 = centro + Vector2(cos(a2), -sin(a2)) * r_out
			draw_line(p1, p2, col_linea, 3.5 * peso, true)

func _dibujar_divisor_radial(centro: Vector2, r_in: float, r_out: float, ang_rad: float):
	var dir = Vector2(cos(ang_rad), -sin(ang_rad))
	var p_in = centro + dir * r_in
	var p_out = centro + dir * r_out
	draw_line(p_in, p_out, COLOR_BORDE_ORO, 2.5, true)
	draw_circle(p_out, 4.0, COLOR_BORDE_ORO)
