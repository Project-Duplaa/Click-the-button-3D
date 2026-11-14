@tool
extends Control
class_name ControlRadial

## ControlRadial - Rueda Arcana 3D In-World de Gran Escala
## Dibuja un círculo rúnico multicapa de 1024x1024 con anillos astrales giratorios,
## 3 sectores grandes con relleno de energía, doble borde dorado/neón, emblemas de armas
## de gran tamaño y etiquetas de clase integradas.

signal clase_resaltada(nombre_clase: String)
signal clase_confirmada(nombre_clase: String)

const TAMANO_VIEWPORT: Vector2 = Vector2(1024.0, 1024.0)
const CENTRO: Vector2 = Vector2(512.0, 512.0)

const RADIO_INTERIOR: float = 155.0
const RADIO_EXTERIOR: float = 385.0
const RADIO_ICONOS: float = 270.0
const GAP_ANGULAR_DEG: float = 6.5

const COLOR_GUERRERO: Color = Color(0.95, 0.24, 0.28, 1.0) # Carmesí (#F23D47)
const COLOR_CAZADOR: Color = Color(0.18, 0.88, 0.76, 1.0)  # Esmeralda (#2EE0C2)
const COLOR_MAGO: Color = Color(0.28, 0.58, 1.00, 1.0)     # Azul Arcano (#4794FF)
const COLOR_BORDE_ORO: Color = Color(0.95, 0.78, 0.36, 1.0)

const TEX_ESPADA = preload("res://ui_assets/icono_espada.png")
const TEX_ARCO = preload("res://ui_assets/icono_arco.png")
const TEX_BASTON = preload("res://ui_assets/icono_baston.png")

const CONFIG_CLASES = {
	"Guerrero": {
		"color": COLOR_GUERRERO,
		"angulo_centro_deg": 150.0,
		"icono_tex": TEX_ESPADA,
		"titulo": "⚔️ GUERRERO",
		"rol_badge": "🛡️ TANQUE / TORBELLINO MELEE",
		"subtitulo": "Coloso de Acero",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Gran Espada + Escudo Real\n• [color=#56E39F]+60% Salud Máxima (160 HP)[/color]\n• [color=#56E39F]+83% Daño Corte 360°[/color]\n• [color=#72EFDD]Clic Derecho:[/color] Bloqueo (-75% Daño)",
		"accion": "⚡ [ CLIC PARA EVOLUCIONAR ] ⚡"
	},
	"Cazador": {
		"color": COLOR_CAZADOR,
		"angulo_centro_deg": 30.0,
		"icono_tex": TEX_ARCO,
		"titulo": "🏹 CAZADOR",
		"rol_badge": "🎯 RANGER / LLUVIA DE FLECHAS",
		"subtitulo": "Tirador Silvestre",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Arco Élfico Multidisparo\n• [color=#56E39F]Ráfaga en Abanico Perforante[/color]\n• [color=#56E39F]Alcance: 7.5m (Máximo)[/color]\n• [color=#72EFDD]Velocidad Carrera:[/color] 6.4 m/s",
		"accion": "⚡ [ CLIC PARA EVOLUCIONAR ] ⚡"
	},
	"Mago": {
		"color": COLOR_MAGO,
		"angulo_centro_deg": 270.0,
		"icono_tex": TEX_BASTON,
		"titulo": "🔮 MAGO",
		"rol_badge": "✨ ARCANISTA / ORBES TELEDIRIGIDOS",
		"subtitulo": "Señor del Éter",
		"stats_bbcode": "• [color=#FFD166]Arma:[/color] Bastón y Orbe Astral\n• [color=#56E39F]+133% Daño Mágico en Área[/color]\n• [color=#56E39F]Proyectiles Teledirigidos AOE[/color]\n• [color=#72EFDD]Escala con:[/color] Poder de Clic y Crítico",
		"accion": "⚡ [ CLIC PARA EVOLUCIONAR ] ⚡"
	}
}

var clase_seleccionada: String = ""
var _anim_pesos: Dictionary = {
	"Guerrero": 0.0,
	"Cazador": 0.0,
	"Mago": 0.0
}
var _tiempo_pulso: float = 0.0
var _rotacion_runas: float = 0.0

func _ready():
	custom_minimum_size = TAMANO_VIEWPORT
	queue_redraw()

func _process(delta: float):
	_tiempo_pulso += delta * 4.2
	_rotacion_runas += delta * 0.38
	for k in _anim_pesos.keys():
		var destino = 1.0 if k == clase_seleccionada else 0.0
		var actual = _anim_pesos[k]
		_anim_pesos[k] = lerpf(actual, destino, minf(1.0, delta * 14.0))
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
# DIBUJADO PROCEDURAL DEL ANILLO ARCANO MULTICAPA Y EMBLEMAS
# =========================================================================
func _draw():
	var gap_rad = deg_to_rad(GAP_ANGULAR_DEG)

	# 0. Anillos arcanos concéntricos de fondo y marcas astrales giratorias
	_dibujar_geometria_sagrada_fondo()

	# Cazador: centrado en 30°
	var a_caz_ini = -PI / 6.0 + gap_rad
	var a_caz_fin = PI / 2.0 - gap_rad

	# Guerrero: centrado en 150°
	var a_gue_ini = PI / 2.0 + gap_rad
	var a_gue_fin = (7.0 * PI / 6.0) - gap_rad

	# Mago: centrado en 270°
	var a_mag_ini = (7.0 * PI / 6.0) + gap_rad
	var a_mag_fin = (11.0 * PI / 6.0) - gap_rad

	# 1. Dibujar los 3 segmentos con relleno multicapa y bordes curvos
	_dibujar_segmento(CENTRO, RADIO_INTERIOR, RADIO_EXTERIOR, a_gue_ini, a_gue_fin, "Guerrero")
	_dibujar_segmento(CENTRO, RADIO_INTERIOR, RADIO_EXTERIOR, a_caz_ini, a_caz_fin, "Cazador")
	_dibujar_segmento(CENTRO, RADIO_INTERIOR, RADIO_EXTERIOR, a_mag_ini, a_mag_fin, "Mago")

	# 2. Dibujar los iconos de armas y etiquetas en cada sector
	_dibujar_icono_arma("Guerrero", a_gue_ini, a_gue_fin)
	_dibujar_icono_arma("Cazador", a_caz_ini, a_caz_fin)
	_dibujar_icono_arma("Mago", a_mag_ini, a_mag_fin)

func _dibujar_geometria_sagrada_fondo():
	var pulso = 0.5 + 0.5 * sin(_tiempo_pulso)
	var col_oro_suave = Color(0.95, 0.78, 0.36, 0.28 + 0.12 * pulso)
	var col_oro_fuerte = Color(0.98, 0.84, 0.42, 0.58)

	# Halo oscuro bajo el anillo para contraste nítido sobre el piso de la arena
	draw_arc(CENTRO, (RADIO_INTERIOR + RADIO_EXTERIOR) * 0.5, 0.0, TAU, 96, Color(0.03, 0.04, 0.08, 0.62), RADIO_EXTERIOR - RADIO_INTERIOR + 42.0, true)

	# Anillo interior rúnico (alrededor de los pies del héroe)
	draw_arc(CENTRO, RADIO_INTERIOR - 16.0, 0.0, TAU, 72, col_oro_fuerte, 3.0, true)
	draw_arc(CENTRO, RADIO_INTERIOR - 26.0, 0.0, TAU, 72, col_oro_suave, 1.5, true)

	# Anillo exterior astral
	draw_arc(CENTRO, RADIO_EXTERIOR + 26.0, 0.0, TAU, 96, col_oro_fuerte, 3.2, true)
	draw_arc(CENTRO, RADIO_EXTERIOR + 38.0, 0.0, TAU, 96, col_oro_suave, 1.8, true)

	# Marcas rúnicas giratorias en el anillo exterior e interior
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
	var peso = _anim_pesos.get(nombre_clase, 0.0)
	var col_base: Color = CONFIG_CLASES[nombre_clase]["color"]
	var pulso = 0.5 + 0.5 * sin(_tiempo_pulso * 1.5)

	# Expansión radial pronunciada al hacer hover
	var r_out_efectivo = lerpf(r_out, r_out + 24.0, peso)
	var r_in_efectivo = lerpf(r_in, r_in - 8.0, peso)

	# Relleno rico con mayor presencia cromática
	var alpha_fill = lerpf(0.52, 0.84, peso)
	var col_fill = Color(col_base.r * lerpf(0.65, 1.0, peso), col_base.g * lerpf(0.65, 1.0, peso), col_base.b * lerpf(0.65, 1.0, peso), alpha_fill)

	# Borde luminoso
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

	# Polígono principal de relleno
	var poly = PackedVector2Array()
	for p in puntos_exterior:
		poly.append(p)
	for i in range(puntos_interior.size() - 1, -1, -1):
		poly.append(puntos_interior[i])
	draw_polygon(poly, PackedColorArray([col_fill]))

	# Sub-arco interior brillante para sensación de relieve 3D
	var poly_brillo = PackedVector2Array()
	for p in puntos_exterior:
		poly_brillo.append(p)
	for i in range(puntos_medio.size() - 1, -1, -1):
		poly_brillo.append(puntos_medio[i])
	var col_brillo = Color(col_base.r, col_base.g, col_base.b, lerpf(0.18, 0.42, peso))
	draw_polygon(poly_brillo, PackedColorArray([col_brillo]))

	# Arco rúnico decorativo intermedio
	draw_polyline(puntos_medio, Color(1.0, 1.0, 1.0, lerpf(0.16, 0.45, peso)), 2.0, true)

	# Resplandor exterior multicapa si está seleccionado
	if peso > 0.05:
		var glow_col = Color(col_base.r, col_base.g, col_base.b, 0.45 * peso)
		draw_polyline(puntos_exterior, glow_col, grosor_borde + 10.0, true)
		draw_polyline(puntos_interior, glow_col, grosor_borde + 6.0, true)

	# Contorno completo cerrado
	var borde_completo = PackedVector2Array()
	for p in puntos_exterior:
		borde_completo.append(p)
	for i in range(puntos_interior.size() - 1, -1, -1):
		borde_completo.append(puntos_interior[i])
	borde_completo.append(puntos_exterior[0])

	draw_polyline(borde_completo, col_borde, grosor_borde, true)

func _dibujar_icono_arma(nombre_clase: String, a_ini: float, a_fin: float):
	var tex: Texture2D = CONFIG_CLASES[nombre_clase]["icono_tex"]
	var col_base: Color = CONFIG_CLASES[nombre_clase]["color"]
	var a_medio = (a_ini + a_fin) * 0.5
	var peso = _anim_pesos.get(nombre_clase, 0.0)
	var radio_dinamico = lerpf(RADIO_ICONOS, RADIO_ICONOS + 12.0, peso)
	var pos_centro_sector = CENTRO + Vector2(cos(a_medio), -sin(a_medio)) * radio_dinamico

	# Medallón circular detrás del icono del arma
	var radio_medallon = lerpf(54.0, 68.0, peso)
	draw_circle(pos_centro_sector, radio_medallon + 5.0, Color(0.04, 0.05, 0.09, 0.85))
	draw_circle(pos_centro_sector, radio_medallon, Color(col_base.r * 0.25, col_base.g * 0.25, col_base.b * 0.25, 0.92))
	draw_arc(pos_centro_sector, radio_medallon, 0.0, TAU, 48, col_base.lerp(Color.WHITE, 0.35 + 0.35 * peso), lerpf(3.0, 5.0, peso), true)

	if tex != null:
		var escala = lerpf(1.0, 1.32, peso)
		var tam_icono = Vector2(84.0, 84.0) * escala
		var rect_dest = Rect2(pos_centro_sector - tam_icono * 0.5, tam_icono)
		draw_texture_rect(tex, rect_dest, false)

	# Etiqueta del nombre de la clase bajo el medallón
	var font = ThemeDB.fallback_font
	if font != null:
		var texto_clase = nombre_clase.to_upper()
		var font_size = int(lerpf(18.0, 22.0, peso))
		var text_size = font.get_string_size(texto_clase, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var pos_texto = pos_centro_sector + Vector2(-text_size.x * 0.5, radio_medallon + 24.0)
		# Pastilla de fondo para legibilidad perfecta
		var rect_pill = Rect2(pos_texto.x - 10.0, pos_texto.y - font_size, text_size.x + 20.0, font_size + 8.0)
		draw_rect(rect_pill, Color(0.04, 0.05, 0.10, 0.88), true)
		draw_rect(rect_pill, col_base.lerp(COLOR_BORDE_ORO, 0.4), false, 1.8)
		draw_string(font, pos_texto, texto_clase, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.96, 0.84, 1.0))
