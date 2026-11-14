class_name LienzoArbolHabilidades
extends Control

## LienzoArbolHabilidades - Lienzo Interactivo con Pan & Zoom y Renderizador de Grafo
## Implementa la estética madura Path of Exile / Nodebreaker con paleta acero/esmeralda/oro viejo.

signal nodo_seleccionado(nodo: SkillNodeData, estado: String)
signal nodo_hover(nodo: SkillNodeData)

# Estética Laboratorio Radiactivo / Reactor de Biocontención
const COLOR_FONDO_SLATE = Color(0.045, 0.055, 0.075, 1.0) # Acero oscuro de búnker #0b0e13
const COLOR_HIERRO_BLOQUEADO = Color(0.16, 0.20, 0.26, 0.85)
const COLOR_DESBLOQUEABLE_PULSO = Color(0.20, 0.95, 0.45, 0.90) # Verde radiactivo

const COLORES_RAMA = {
	"azul": {
		"base": Color(0.06, 0.70, 0.88),     # Plasma Cherenkov #0ea5e9
		"brillo": Color(0.30, 0.90, 1.00),   # Resplandor azul eléctrico
		"oscuro": Color(0.04, 0.16, 0.24)
	},
	"verde": {
		"base": Color(0.10, 0.82, 0.40),    # Uranio Enriquecido / Biohazard #10b981
		"brillo": Color(0.32, 1.00, 0.55),   # Resplandor verde tóxico
		"oscuro": Color(0.03, 0.20, 0.09)
	},
	"dorada": {
		"base": Color(0.95, 0.65, 0.12),    # Extracción de Isótopos / Ámbar #f59e0b
		"brillo": Color(1.00, 0.82, 0.28),   # Resplandor ámbar radioactivo
		"oscuro": Color(0.24, 0.14, 0.02)
	},
	"hibrido": {
		"base": Color(0.72, 0.35, 0.95),    # Fisión Cuántica / Mutación #a855f7
		"brillo": Color(0.88, 0.55, 1.00),
		"oscuro": Color(0.22, 0.08, 0.28)
	},
	"central": {
		"base": Color(0.15, 0.95, 0.45),    # Biocontenedor Primordial
		"brillo": Color(0.40, 1.00, 0.65),
		"oscuro": Color(0.04, 0.24, 0.11)
	}
}

var nodos: Dictionary = {}
var zoom: float = 0.75
var min_zoom: float = 0.30
var max_zoom: float = 2.2
var pan_offset: Vector2 = Vector2.ZERO

var _arrastrando: bool = false
var _tiempo_acumulado: float = 0.0
var nodo_seleccionado_id: String = "nodo_origen"
var nodo_hover_id: String = ""

var _font: Font = null

func _ready():
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	_font = ThemeDB.fallback_font
	
	# Centrar la vista en el origen (0, 0)
	call_deferred("_centrar_en_origen")

func _process(delta: float):
	if not is_visible_in_tree():
		return
	_tiempo_acumulado += delta
	# Si el lienzo está visible, animar suavemente el pulso
	queue_redraw()

func _centrar_en_origen():
	pan_offset = Vector2.ZERO
	zoom = 0.75
	queue_redraw()

func configurar_nodos(diccionario_nodos: Dictionary):
	nodos = diccionario_nodos
	if not nodos.has(nodo_seleccionado_id) and nodos.size() > 0:
		nodo_seleccionado_id = nodos.keys()[0]
	queue_redraw()

func to_screen_pos(pos_virtual: Vector2) -> Vector2:
	return (pos_virtual * zoom) + (size * 0.5) + pan_offset

func to_virtual_pos(pos_pantalla: Vector2) -> Vector2:
	return (pos_pantalla - (size * 0.5) - pan_offset) / zoom

func _gui_input(event: InputEvent):
	# 1. Zoom con la rueda del ratón centrado en el cursor
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_aplicar_zoom(1.12, event.position)
			accept_event()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_aplicar_zoom(0.88, event.position)
			accept_event()
			return
		elif event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			_arrastrando = event.pressed
			accept_event()
			return
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var nodo_clicado = _obtener_nodo_en_posicion(event.position)
				if nodo_clicado != null:
					_seleccionar_nodo(nodo_clicado)
				else:
					_arrastrando = true
			else:
				_arrastrando = false
			accept_event()
			return

	# 2. Arrastre Pan
	if event is InputEventMouseMotion:
		if _arrastrando:
			pan_offset += event.relative
			queue_redraw()
		else:
			var prev_hover = nodo_hover_id
			var nodo_debajo = _obtener_nodo_en_posicion(event.position)
			nodo_hover_id = nodo_debajo.id if nodo_debajo != null else ""
			if prev_hover != nodo_hover_id:
				if nodo_debajo != null:
					mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
					emit_signal("nodo_hover", nodo_debajo)
				else:
					mouse_default_cursor_shape = Control.CURSOR_ARROW
				queue_redraw()

func _aplicar_zoom(factor: float, centro_mouse: Vector2):
	var pos_virt_antes = to_virtual_pos(centro_mouse)
	var nuevo_zoom = clampf(zoom * factor, min_zoom, max_zoom)
	if nuevo_zoom == zoom:
		return
	zoom = nuevo_zoom
	var pos_pant_despues = to_screen_pos(pos_virt_antes)
	pan_offset += (centro_mouse - pos_pant_despues)
	queue_redraw()

func _obtener_nodo_en_posicion(pos_pantalla: Vector2) -> SkillNodeData:
	for id in nodos.keys():
		var n: SkillNodeData = nodos[id]
		var centro_pant = to_screen_pos(n.posicion)
		var radio = (32.0 if n.es_keystone else 22.0) * zoom
		if pos_pantalla.distance_to(centro_pant) <= radio + 4.0:
			return n
	return null

func _seleccionar_nodo(n: SkillNodeData):
	nodo_seleccionado_id = n.id
	var estado = ArbolInterconectadoDatos.obtener_estado_nodo(n, nodos)
	emit_signal("nodo_seleccionado", n, estado)
	queue_redraw()

# ==============================================================================
# RENDERIZADO VISUAL DEL ÁRBOL (_draw)
# ==============================================================================

func _draw():
	# 1. Fondo sólido matte slate
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_FONDO_SLATE)
	
	# Cuadrícula rúnica sutil de fondo
	_dibujar_rejilla_fondo()
	
	# 2. Dibujar líneas de conexión entre nodos (Grafo Web)
	_dibujar_conexiones_grafo()
	
	# 3. Dibujar nodos circulares con biseles metálicos
	_dibujar_nodos_grafo()

func _dibujar_rejilla_fondo():
	var paso_cuadricula = 80.0 * zoom
	if paso_cuadricula < 25.0:
		return
	
	# 1. Cuadrícula de telemetría de laboratorio
	var col_linea = Color(0.08, 0.12, 0.16, 0.45)
	var col_punto = Color(0.12, 0.22, 0.26, 0.65)
	var offset_x = fmod((size.x * 0.5) + pan_offset.x, paso_cuadricula)
	var offset_y = fmod((size.y * 0.5) + pan_offset.y, paso_cuadricula)
	
	var x = offset_x
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), col_linea, 1.0)
		x += paso_cuadricula
		
	var y = offset_y
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), col_linea, 1.0)
		y += paso_cuadricula
		
	# 2. Retículas tácticas en las intersecciones
	if zoom >= 0.55:
		var ix = offset_x
		while ix < size.x:
			var iy = offset_y
			while iy < size.y:
				var p_cruz = Vector2(ix, iy)
				draw_line(p_cruz - Vector2(3, 0), p_cruz + Vector2(3, 0), col_punto, 1.0)
				draw_line(p_cruz - Vector2(0, 3), p_cruz + Vector2(0, 3), col_punto, 1.0)
				iy += paso_cuadricula
			ix += paso_cuadricula

	# 3. Anillos de dispersión y radiación del Biocontenedor Central (0, 0)
	var centro_pant = to_screen_pos(Vector2.ZERO)
	var r1 = 120.0 * zoom
	var r2 = 220.0 * zoom
	var r3 = 340.0 * zoom
	draw_arc(centro_pant, r1, 0, TAU, 48, Color(0.08, 0.45, 0.30, 0.22), 1.5 * zoom, false)
	draw_arc(centro_pant, r2, 0, TAU, 64, Color(0.06, 0.35, 0.45, 0.18), 1.2 * zoom, false)
	draw_arc(centro_pant, r3, 0, TAU, 64, Color(0.55, 0.38, 0.08, 0.14), 1.0 * zoom, false)
	
	# Muescas giratorias de telemetría de radiación
	var ang_rot = _tiempo_acumulado * 0.25
	draw_arc(centro_pant, r1, ang_rot, ang_rot + 1.2, 16, Color(0.15, 0.95, 0.50, 0.45), 2.5 * zoom, false)
	draw_arc(centro_pant, r2, -ang_rot * 0.7, -ang_rot * 0.7 + 1.5, 24, Color(0.20, 0.85, 1.0, 0.35), 2.0 * zoom, false)

func _dibujar_conexiones_grafo():
	var lineas_dibujadas: Dictionary = {}
	
	for id_a in nodos.keys():
		var nodo_a: SkillNodeData = nodos[id_a]
		var pos_a = to_screen_pos(nodo_a.posicion)
		
		for id_b in nodo_a.nodos_conectados:
			if not nodos.has(id_b):
				continue
			
			# Clave única para evitar dibujar la misma línea dos veces
			var par_id = id_a + "_" + id_b if id_a < id_b else id_b + "_" + id_a
			if lineas_dibujadas.has(par_id):
				continue
			lineas_dibujadas[par_id] = true
			
			var nodo_b: SkillNodeData = nodos[id_b]
			var pos_b = to_screen_pos(nodo_b.posicion)
			
			# Descartar si ambos puntos están fuera de la pantalla
			if not Rect2(Vector2(-100, -100), size + Vector2(200, 200)).encloses(Rect2(pos_a, Vector2.ZERO)) and \
			   not Rect2(Vector2(-100, -100), size + Vector2(200, 200)).encloses(Rect2(pos_b, Vector2.ZERO)):
				continue
				
			var est_a = ArbolInterconectadoDatos.obtener_estado_nodo(nodo_a, nodos)
			var est_b = ArbolInterconectadoDatos.obtener_estado_nodo(nodo_b, nodos)
			
			_dibujar_linea_conexion(pos_a, pos_b, nodo_a, nodo_b, est_a, est_b)

func _dibujar_linea_conexion(p_a: Vector2, p_b: Vector2, n_a: SkillNodeData, n_b: SkillNodeData, est_a: String, est_b: String):
	var activa = (est_a in ["comprado", "maxeado"]) and (est_b in ["comprado", "maxeado"])
	var desbloqueable = ((est_a in ["comprado", "maxeado"]) and est_b == "desbloqueable") or \
						((est_b in ["comprado", "maxeado"]) and est_a == "desbloqueable")
	
	if activa:
		# Tubería de refrigerante radiactivo activa con fluido y resplandor Cherenkov/Biohazard
		var rama_color = n_a.rama if n_a.rama != "central" else n_b.rama
		var paleta = COLORES_RAMA.get(rama_color, COLORES_RAMA["dorada"])
		var color_brillo: Color = paleta["brillo"]
		var color_base: Color = paleta["base"]
		
		# 1. Aura exterior de radiación / gas disperso (Glow)
		draw_line(p_a, p_b, Color(color_brillo.r, color_brillo.g, color_brillo.b, 0.28), 8.5 * zoom, true)
		# 2. Conducto blindado de aleación de titanio
		draw_line(p_a, p_b, Color(0.08, 0.12, 0.16), 4.5 * zoom, true)
		# 3. Núcleo de fluido de plasma brillante
		draw_line(p_a, p_b, color_base, 2.6 * zoom, true)
		# 4. Flujo de corriente líquida / burbujas de radiación en movimiento continuo
		var dist = p_a.distance_to(p_b)
		if dist > 14.0 * zoom:
			var dir = (p_b - p_a).normalized()
			var intervalo = 28.0 * zoom
			var offset_flujo = fmod(_tiempo_acumulado * (45.0 * zoom), intervalo)
			var d = offset_flujo
			while d < dist:
				var pos_burbuja = p_a + dir * d
				draw_circle(pos_burbuja, 1.6 * zoom, Color(1, 1, 1, 0.85))
				d += intervalo
	elif desbloqueable:
		# Conducto presurizado listo para inyección con pulso verde radiactivo
		var pulso = 0.45 + sin(_tiempo_acumulado * 4.0) * 0.40
		var col_pulso = COLOR_DESBLOQUEABLE_PULSO
		col_pulso.a = pulso
		draw_line(p_a, p_b, col_pulso, 2.8 * zoom, true)
	else:
		# Conducto sellado por cuarentena / sin corriente de plasma
		draw_line(p_a, p_b, COLOR_HIERRO_BLOQUEADO, 2.0 * zoom, false)
		
		# Juntas de válvula de bloqueo a lo largo del segmento
		var dist = p_a.distance_to(p_b)
		var pasos = int(dist / (26.0 * zoom))
		if pasos > 1:
			var dir = (p_b - p_a).normalized()
			for i in range(1, pasos):
				var pos_valvula = p_a + dir * (i * 26.0 * zoom)
				draw_circle(pos_valvula, 2.0 * zoom, Color(0.12, 0.15, 0.20, 0.95))

func _dibujar_nodos_grafo():
	for id in nodos.keys():
		var n: SkillNodeData = nodos[id]
		var centro = to_screen_pos(n.posicion)
		
		# Culling básico de pantalla
		if centro.x < -60 or centro.x > size.x + 60 or centro.y < -60 or centro.y > size.y + 60:
			continue
			
		var estado = ArbolInterconectadoDatos.obtener_estado_nodo(n, nodos)
		var es_hover = (id == nodo_hover_id)
		var es_sel = (id == nodo_seleccionado_id)
		
		_renderizar_nodo_circular(n, centro, estado, es_hover, es_sel)

func _renderizar_nodo_circular(n: SkillNodeData, centro: Vector2, estado: String, hover: bool, seleccionado: bool):
	var radio_base = (30.0 if n.es_keystone else 20.0) * zoom
	var paleta = COLORES_RAMA.get(n.rama, COLORES_RAMA["dorada"])
	
	# 1. Halo de selección o hover
	if seleccionado:
		var radio_sel = radio_base + 7.0 * zoom
		draw_arc(centro, radio_sel, 0, TAU, 32, Color(1.0, 0.9, 0.4, 0.95), 2.5 * zoom, true)
		draw_arc(centro, radio_sel + 3.0 * zoom, 0, TAU, 32, Color(1.0, 0.9, 0.4, 0.35), 1.5 * zoom, true)
	elif hover:
		var radio_hov = radio_base + 5.0 * zoom
		draw_arc(centro, radio_hov, 0, TAU, 32, Color(0.8, 0.85, 1.0, 0.75), 2.0 * zoom, true)
		
	# 2. Resplandor exterior si está maxeado o es keystone comprado
	if estado == "maxeado":
		draw_circle(centro, radio_base + 4.0 * zoom, Color(1.0, 0.85, 0.3, 0.25))
	elif estado == "comprado":
		var c_brillo: Color = paleta["brillo"]
		draw_circle(centro, radio_base + 3.0 * zoom, Color(c_brillo.r, c_brillo.g, c_brillo.b, 0.20))
	elif estado == "desbloqueable":
		var pulso = 0.20 + sin(_tiempo_acumulado * 4.0) * 0.15
		draw_circle(centro, radio_base + 4.0 * zoom, Color(0.9, 0.95, 1.0, pulso))

	# 3. Bisel Metálico Industrial Blindado (Aleación de Titanio)
	var col_borde: Color = Color(0.24, 0.28, 0.35) # Titanio oscuro base
	if estado in ["comprado", "maxeado"]:
		col_borde = paleta["brillo"] if estado == "comprado" else Color(0.35, 1.0, 0.6)
	elif estado == "desbloqueable":
		col_borde = Color(0.30, 0.95, 0.55) # Verde tóxico desbloqueable
		
	draw_circle(centro, radio_base, col_borde)
	
	# Pernos industriales de contención en el perímetro
	if zoom >= 0.50:
		var num_pernos = 8 if n.es_keystone else 4
		for i in range(num_pernos):
			var ang_p = (TAU / num_pernos) * i + (PI * 0.25)
			var pos_p = centro + Vector2(cos(ang_p), sin(ang_p)) * (radio_base - 1.6 * zoom)
			draw_circle(pos_p, 1.15 * zoom, Color(0.85, 0.92, 0.98, 0.85))
	
	# 4. Relleno Interior (Cámara de Plasma / Biocontenedor)
	var radio_interior = radio_base - (4.0 * zoom if n.es_keystone else 2.8 * zoom)
	var col_fondo: Color = Color(0.08, 0.10, 0.14) # Búnker interior
	if estado in ["comprado", "maxeado"]:
		col_fondo = paleta["oscuro"]
	elif estado == "desbloqueable":
		col_fondo = Color(0.06, 0.18, 0.12)
		
	draw_circle(centro, radio_interior, col_fondo)
	
	# 5. Reflejo especular en media luna superior (Cristal de Biocontención 3D)
	if estado in ["comprado", "maxeado", "desbloqueable"]:
		draw_arc(centro, radio_interior * 0.72, -PI * 0.82, -PI * 0.18, 16, Color(1.0, 1.0, 1.0, 0.40), 1.6 * zoom, false)
	
	# 6. Adornos de Keystone (Reactor colosal con respiraderos de fisión)
	if n.es_keystone:
		draw_arc(centro, radio_interior - 3.2 * zoom, 0, TAU, 32, col_borde * 0.75, 1.6 * zoom, false)
		var pulso_key = 0.5 + sin(_tiempo_acumulado * 3.0) * 0.5
		draw_arc(centro, radio_base + 6.0 * zoom, 0, TAU, 32, Color(col_borde.r, col_borde.g, col_borde.b, pulso_key * 0.6), 1.4 * zoom, false)
		
	# 6. Icono Central (Emoji / Símbolo)
	if _font != null:
		var tam_fuente = int((20 if n.es_keystone else 14) * zoom)
		if tam_fuente >= 8:
			var txt = n.icono
			var tam_txt = _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, tam_fuente)
			var pos_txt = centro - Vector2(tam_txt.x * 0.5, -tam_txt.y * 0.35)
			var col_txt = Color(1, 1, 1, 1) if estado != "bloqueado" else Color(0.5, 0.5, 0.5, 0.8)
			draw_string(_font, pos_txt, txt, HORIZONTAL_ALIGNMENT_CENTER, -1, tam_fuente, col_txt)
			
	# 7. Pastilla de Nivel (Badge inferior)
	if not n.es_keystone and n.nivel_max > 1:
		var pos_badge = centro + Vector2(0, radio_base - 1.0 * zoom)
		var txt_lvl = "%d/%d" % [n.nivel_actual, n.nivel_max]
		var tam_lvl_fnt = int(9 * zoom)
		if tam_lvl_fnt >= 7:
			var tam_badge_txt = _font.get_string_size(txt_lvl, HORIZONTAL_ALIGNMENT_CENTER, -1, tam_lvl_fnt)
			var rect_badge = Rect2(pos_badge - Vector2(tam_badge_txt.x * 0.5 + 3, tam_badge_txt.y * 0.75), tam_badge_txt + Vector2(6, 2))
			draw_rect(rect_badge, Color(0.08, 0.09, 0.12, 0.95), true)
			draw_rect(rect_badge, col_borde * 0.8, false, 1.0)
			draw_string(_font, pos_badge - Vector2(tam_badge_txt.x * 0.5, -tam_badge_txt.y * 0.15), txt_lvl, HORIZONTAL_ALIGNMENT_CENTER, -1, tam_lvl_fnt, Color(0.9, 0.9, 0.9))
