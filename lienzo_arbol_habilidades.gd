class_name LienzoArbolHabilidades
extends Control

## LienzoArbolHabilidades - Lienzo Interactivo de Constelación con Pan, Zoom,
## Conduits Curvos/PCB, 6 Siluetas de Nodo, Iconos SVG y Telemetría de Reactor.

const MetaprogresoManager = preload("res://metaprogreso_manager.gd")
const IconosArbol = preload("res://iconos_arbol_habilidades.gd")
const SHADER_BACKDROP: Shader = preload("res://shaders/skill_tree_backdrop.gdshader")

signal nodo_seleccionado(nodo: SkillNodeData, estado: String)
signal nodo_hover(nodo: SkillNodeData)
signal nodo_compra_rapida(nodo: SkillNodeData)
signal camara_cambiada(zoom_actual: float)

const COLOR_HIERRO_BLOQUEADO := Color(0.16, 0.21, 0.28, 0.88)
const COLOR_DESBLOQUEABLE_PULSO := Color(0.20, 0.95, 0.55, 0.90)
const COLOR_ORO_IMPERIAL := Color(0.980, 0.800, 0.082, 1.0) # #FACC15

const COLORES_RAMA := {
	"azul": {
		"base": Color(0.06, 0.70, 0.88),     # Plasma Cherenkov #0ea5e9
		"brillo": Color(0.30, 0.90, 1.00),
		"oscuro": Color(0.03, 0.14, 0.22)
	},
	"verde": {
		"base": Color(0.10, 0.82, 0.40),     # Biohazard #10b981
		"brillo": Color(0.32, 1.00, 0.55),
		"oscuro": Color(0.03, 0.17, 0.08)
	},
	"dorada": {
		"base": Color(0.95, 0.65, 0.12),     # Ámbar #f59e0b
		"brillo": Color(1.00, 0.82, 0.28),
		"oscuro": Color(0.22, 0.13, 0.02)
	},
	"hibrido": {
		"base": Color(0.72, 0.35, 0.95),     # Fisión Cuántica #a855f7
		"brillo": Color(0.88, 0.55, 1.00),
		"oscuro": Color(0.19, 0.07, 0.25)
	},
	"cosmico": {
		"base": Color(0.78, 0.45, 1.00),     # Violeta Astral #c084fc
		"brillo": Color(0.95, 0.82, 1.00),
		"oscuro": Color(0.16, 0.05, 0.25)
	},
	"central": {
		"base": Color(0.15, 0.95, 0.55),     # Núcleo Primordial
		"brillo": Color(0.40, 1.00, 0.70),
		"oscuro": Color(0.03, 0.20, 0.11)
	},
	"boton": {
		"base": Color(1.00, 0.48, 0.14),     # Plasma Térmico / Núcleo Móvil
		"brillo": Color(1.00, 0.74, 0.34),
		"oscuro": Color(0.24, 0.10, 0.03)
	}
}

var nodos: Dictionary = {}
var zoom: float = 0.75
var min_zoom: float = 0.16
var max_zoom: float = 2.2
var pan_offset: Vector2 = Vector2.ZERO

var _arrastrando: bool = false
var _tiempo_acumulado: float = 0.0
var nodo_seleccionado_id: String = "nodo_origen"
var nodo_hover_id: String = ""

var _font: Font = null
var _backdrop_rect: ColorRect = null
var _cam_tween: Tween = null

var _bfs_dist_origen: Dictionary = {}
var _hover_ruta_nodos: Dictionary = {}
var _hover_ruta_aristas: Dictionary = {}
var _hover_vecinos: Dictionary = {}
var _tree_bounds: Rect2 = Rect2(-1100, -1500, 2000, 2500)
var _efectos_compra: Array[Dictionary] = []
var _ultima_pos_mouse: Vector2 = Vector2.ZERO

func _ready():
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	_font = ThemeDB.fallback_font
	_asegurar_backdrop_shader()
	if not resized.is_connected(_sync_backdrop_shader):
		resized.connect(_sync_backdrop_shader)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	call_deferred("_sync_backdrop_shader")
	call_deferred("_centrar_en_origen")

func _asegurar_backdrop_shader():
	_backdrop_rect = get_node_or_null("BackdropShader") as ColorRect
	if _backdrop_rect == null:
		_backdrop_rect = ColorRect.new()
		_backdrop_rect.name = "BackdropShader"
		_backdrop_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_backdrop_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_backdrop_rect.z_index = -1
		add_child(_backdrop_rect)
		move_child(_backdrop_rect, 0)
	var mat := _backdrop_rect.material as ShaderMaterial
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = SHADER_BACKDROP
		_backdrop_rect.material = mat
	elif mat.shader == null:
		mat.shader = SHADER_BACKDROP

func _sync_backdrop_shader():
	if _backdrop_rect == null or not (_backdrop_rect.material is ShaderMaterial):
		return
	var mat := _backdrop_rect.material as ShaderMaterial
	var vs := size if size.x > 1.0 and size.y > 1.0 else Vector2(1280.0, 720.0)
	mat.set_shader_parameter("view_size", vs)
	mat.set_shader_parameter("pan_offset", pan_offset)
	mat.set_shader_parameter("zoom", zoom)

func _on_mouse_exited():
	if nodo_hover_id != "" or _arrastrando:
		_arrastrando = false
		nodo_hover_id = ""
		_hover_ruta_nodos.clear()
		_hover_ruta_aristas.clear()
		_hover_vecinos.clear()
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		queue_redraw()

func _process(delta: float):
	if not is_visible_in_tree():
		return
	_tiempo_acumulado += delta
	if _efectos_compra.size() > 0:
		for i in range(_efectos_compra.size() - 1, -1, -1):
			_efectos_compra[i]["t"] = float(_efectos_compra[i]["t"]) + delta
			if float(_efectos_compra[i]["t"]) >= float(_efectos_compra[i]["dur"]):
				_efectos_compra.remove_at(i)
	queue_redraw()

func _cancelar_tween_camara():
	if _cam_tween != null and _cam_tween.is_valid():
		_cam_tween.kill()
	_cam_tween = null

func _centrar_en_origen():
	_cancelar_tween_camara()
	pan_offset = Vector2.ZERO
	zoom = 0.75
	emit_signal("camara_cambiada", zoom)
	queue_redraw()

func enfocar_posicion(pos_virtual: Vector2, target_zoom: float = -1.0):
	_cancelar_tween_camara()
	var z_final := clampf(target_zoom if target_zoom > 0.0 else zoom, min_zoom, max_zoom)
	var centro_libre := Vector2(0.0, 26.0)
	var pan_final := centro_libre - (pos_virtual * z_final)
	_cam_tween = create_tween()
	_cam_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_cam_tween.set_parallel(true)
	_cam_tween.set_trans(Tween.TRANS_CUBIC)
	_cam_tween.set_ease(Tween.EASE_OUT)
	_cam_tween.tween_property(self, "zoom", z_final, 0.32)
	_cam_tween.tween_property(self, "pan_offset", pan_final, 0.32)
	_cam_tween.chain().tween_callback(func():
		emit_signal("camara_cambiada", zoom)
		queue_redraw()
	)
	emit_signal("camara_cambiada", z_final)

func ajustar_vista_completa():
	if nodos.is_empty():
		_centrar_en_origen()
		return
	var vs := size if size.x > 100.0 and size.y > 100.0 else Vector2(1280.0, 720.0)
	var pad_top := 112.0
	var pad_bot := 58.0
	var pad_lat := 44.0
	var area_w := maxf(vs.x - pad_lat * 2.0, 260.0)
	var area_h := maxf(vs.y - pad_top - pad_bot, 220.0)
	var bounds := _tree_bounds.grow_individual(140.0, 175.0, 140.0, 145.0)
	var zx := area_w / maxf(bounds.size.x, 100.0)
	var zy := area_h / maxf(bounds.size.y, 100.0)
	var z_final := clampf(minf(zx, zy), min_zoom, 0.95)
	var centro_mundo := bounds.get_center()
	var centro_area := Vector2(vs.x * 0.5, pad_top + area_h * 0.5)
	var pan_final := (centro_area - vs * 0.5) - (centro_mundo * z_final)

	_cancelar_tween_camara()
	_cam_tween = create_tween()
	_cam_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_cam_tween.set_parallel(true)
	_cam_tween.set_trans(Tween.TRANS_CUBIC)
	_cam_tween.set_ease(Tween.EASE_OUT)
	_cam_tween.tween_property(self, "zoom", z_final, 0.34)
	_cam_tween.tween_property(self, "pan_offset", pan_final, 0.34)
	_cam_tween.chain().tween_callback(func():
		emit_signal("camara_cambiada", zoom)
		queue_redraw()
	)
	emit_signal("camara_cambiada", z_final)

func centrar_en_minimapa(pos_virtual: Vector2):
	_cancelar_tween_camara()
	pan_offset = -pos_virtual * zoom
	emit_signal("camara_cambiada", zoom)
	queue_redraw()

func configurar_nodos(diccionario_nodos: Dictionary):
	nodos = diccionario_nodos
	if not nodos.has(nodo_seleccionado_id) and nodos.size() > 0:
		nodo_seleccionado_id = str(nodos.keys()[0])
	_recalcular_bfs_origen()
	_recalcular_bounds()
	_recalcular_ruta_hover()
	queue_redraw()

func _recalcular_bounds():
	if nodos.is_empty():
		_tree_bounds = Rect2(-1000, -1500, 2000, 2500)
		return
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	for id in nodos.keys():
		var n: SkillNodeData = nodos[id]
		min_p.x = minf(min_p.x, n.posicion.x)
		min_p.y = minf(min_p.y, n.posicion.y)
		max_p.x = maxf(max_p.x, n.posicion.x)
		max_p.y = maxf(max_p.y, n.posicion.y)
	_tree_bounds = Rect2(min_p, max_p - min_p)

func _recalcular_bfs_origen():
	_bfs_dist_origen.clear()
	if not nodos.has("nodo_origen"):
		return
	var cola: Array[String] = ["nodo_origen"]
	_bfs_dist_origen["nodo_origen"] = 0
	var idx := 0
	while idx < cola.size():
		var act := cola[idx]
		idx += 1
		var dist_act := int(_bfs_dist_origen[act])
		var n: SkillNodeData = nodos[act]
		for vec in n.nodos_conectados:
			if nodos.has(vec) and not _bfs_dist_origen.has(vec):
				_bfs_dist_origen[vec] = dist_act + 1
				cola.append(vec)

func _recalcular_ruta_hover():
	_hover_ruta_nodos.clear()
	_hover_ruta_aristas.clear()
	_hover_vecinos.clear()
	if nodo_hover_id == "" or not nodos.has(nodo_hover_id) or not nodos.has("nodo_origen"):
		return
	var hovered: SkillNodeData = nodos[nodo_hover_id]
	for v in hovered.nodos_conectados:
		if nodos.has(v):
			_hover_vecinos[v] = true

	var padre: Dictionary = {"nodo_origen": ""}
	var cola: Array[String] = ["nodo_origen"]
	var idx := 0
	var encontrado := false
	while idx < cola.size():
		var act := cola[idx]
		idx += 1
		if act == nodo_hover_id:
			encontrado = true
			break
		var n: SkillNodeData = nodos[act]
		for vec in n.nodos_conectados:
			if nodos.has(vec) and not padre.has(vec):
				padre[vec] = act
				cola.append(vec)

	if not encontrado:
		return
	var cur := nodo_hover_id
	while cur != "":
		_hover_ruta_nodos[cur] = true
		var p: String = str(padre.get(cur, ""))
		if p != "":
			var par_id := cur + "_" + p if cur < p else p + "_" + cur
			_hover_ruta_aristas[par_id] = true
		cur = p

func to_screen_pos(pos_virtual: Vector2) -> Vector2:
	return (pos_virtual * zoom) + (size * 0.5) + pan_offset

func to_virtual_pos(pos_pantalla: Vector2) -> Vector2:
	return (pos_pantalla - (size * 0.5) - pan_offset) / maxf(zoom, 0.05)

func reproducir_efecto_compra(nodo: SkillNodeData):
	if nodo == null:
		return
	var paleta: Dictionary = COLORES_RAMA.get(nodo.rama, COLORES_RAMA["dorada"])
	var texto := "+Nv. %d" % nodo.nivel_actual
	if nodo.es_keystone:
		texto = "¡KEYSTONE!"
	elif nodo.esta_maxeado() and nodo.nivel_max < 999:
		texto = "¡MAX!"
	_efectos_compra.append({
		"pos": nodo.posicion,
		"color": COLOR_ORO_IMPERIAL if (nodo.es_keystone or (nodo.esta_maxeado() and nodo.nivel_max < 999)) else paleta["brillo"],
		"texto": texto,
		"keystone": nodo.es_keystone,
		"t": 0.0,
		"dur": 0.85 if nodo.es_keystone else 0.65
	})
	queue_redraw()

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		_ultima_pos_mouse = event.position
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_aplicar_zoom(1.14, event.position)
			accept_event()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_aplicar_zoom(0.88, event.position)
			accept_event()
			return
		elif event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			_arrastrando = event.pressed
			mouse_default_cursor_shape = Control.CURSOR_DRAG if _arrastrando else Control.CURSOR_ARROW
			accept_event()
			return
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var nodo_clicado := _obtener_nodo_en_posicion(event.position)
				if nodo_clicado != null:
					_seleccionar_nodo(nodo_clicado)
					if event.double_click:
						emit_signal("nodo_compra_rapida", nodo_clicado)
				else:
					_arrastrando = true
					mouse_default_cursor_shape = Control.CURSOR_DRAG
			else:
				_arrastrando = false
				mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if nodo_hover_id != "" else Control.CURSOR_ARROW
			accept_event()
			return

	if event is InputEventMouseMotion:
		_ultima_pos_mouse = event.position
		if _arrastrando:
			_cancelar_tween_camara()
			pan_offset += event.relative
			queue_redraw()
		else:
			var prev_hover := nodo_hover_id
			var nodo_debajo := _obtener_nodo_en_posicion(event.position)
			nodo_hover_id = nodo_debajo.id if nodo_debajo != null else ""
			if prev_hover != nodo_hover_id:
				_recalcular_ruta_hover()
				if nodo_debajo != null:
					mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
					emit_signal("nodo_hover", nodo_debajo)
				else:
					mouse_default_cursor_shape = Control.CURSOR_ARROW
				queue_redraw()

func _aplicar_zoom(factor: float, centro_mouse: Vector2):
	_cancelar_tween_camara()
	var pos_virt_antes := to_virtual_pos(centro_mouse)
	var nuevo_zoom := clampf(zoom * factor, min_zoom, max_zoom)
	if is_equal_approx(nuevo_zoom, zoom):
		return
	zoom = nuevo_zoom
	var pos_pant_despues := to_screen_pos(pos_virt_antes)
	pan_offset += (centro_mouse - pos_pant_despues)
	emit_signal("camara_cambiada", zoom)
	queue_redraw()

func _radio_virtual_nodo(n: SkillNodeData) -> float:
	if n.id == "nodo_origen":
		return 36.0
	if n.id in ["apex_keystone_ascension", "cosm_keystone_genesis"]:
		return 40.0
	if n.es_keystone:
		return 33.0
	if n.nivel_max >= 999:
		return 25.0
	if n.rama == "hibrido":
		return 23.0
	return 21.0

func _obtener_nodo_en_posicion(pos_pantalla: Vector2) -> SkillNodeData:
	var mejor: SkillNodeData = null
	var mejor_dist := INF
	for id in nodos.keys():
		var n: SkillNodeData = nodos[id]
		var centro_pant := to_screen_pos(n.posicion)
		var radio := _radio_virtual_nodo(n) * zoom + 5.0
		var d := pos_pantalla.distance_to(centro_pant)
		if d <= radio and d < mejor_dist:
			mejor = n
			mejor_dist = d
	return mejor

func _seleccionar_nodo(n: SkillNodeData):
	nodo_seleccionado_id = n.id
	var estado := ArbolInterconectadoDatos.obtener_estado_nodo(n, nodos)
	emit_signal("nodo_seleccionado", n, estado)
	queue_redraw()

# ==============================================================================
# RENDERIZADO VISUAL DEL ÁRBOL (_draw)
# ==============================================================================
func _draw():
	_sync_backdrop_shader()
	MetaprogresoManager.asegurar_inicializado()
	var oro_banco: int = MetaprogresoManager.oro_banco
	var clics_banco: int = MetaprogresoManager.clics_banco

	_dibujar_atmosfera_y_rejilla()
	_dibujar_conexiones_grafo(oro_banco, clics_banco)
	_dibujar_nodos_grafo(oro_banco, clics_banco)
	_dibujar_efectos_compra()
	_dibujar_tooltip_hover(oro_banco, clics_banco)

func _dibujar_atmosfera_y_rejilla():
	# 1. Resplandores territoriales suaves por sector
	var halos_sector := [
		{"pos": Vector2(-500, -280), "r": 360.0, "col": Color(0.06, 0.55, 0.85, 0.045)},
		{"pos": Vector2(-620, 95), "r": 320.0, "col": Color(0.95, 0.45, 0.12, 0.040)},
		{"pos": Vector2(0, 560), "r": 380.0, "col": Color(0.10, 0.78, 0.40, 0.042)},
		{"pos": Vector2(490, -280), "r": 360.0, "col": Color(0.95, 0.65, 0.12, 0.042)},
		{"pos": Vector2(0, -1280), "r": 430.0, "col": Color(0.75, 0.42, 1.00, 0.055)}
	]
	for h in halos_sector:
		draw_circle(to_screen_pos(h["pos"]), float(h["r"]) * zoom, h["col"])

	# 2. Rejilla de telemetría dual (80u menor + 240u mayor con cruces '+')
	var paso_menor := 80.0 * zoom
	if zoom >= 0.45 and paso_menor >= 18.0:
		var alpha_menor := clampf((zoom - 0.45) / 0.25, 0.0, 1.0) * 0.24
		var col_menor := Color(0.12, 0.22, 0.30, alpha_menor)
		var ox := fmod((size.x * 0.5) + pan_offset.x, paso_menor)
		var oy := fmod((size.y * 0.5) + pan_offset.y, paso_menor)
		if ox < 0.0:
			ox += paso_menor
		if oy < 0.0:
			oy += paso_menor
		var gx := ox
		while gx < size.x:
			draw_line(Vector2(gx, 0.0), Vector2(gx, size.y), col_menor, 1.0)
			gx += paso_menor
		var gy := oy
		while gy < size.y:
			draw_line(Vector2(0.0, gy), Vector2(size.x, gy), col_menor, 1.0)
			gy += paso_menor

	var paso_mayor := 240.0 * zoom
	if paso_mayor >= 28.0:
		var col_mayor := Color(0.16, 0.32, 0.42, 0.34)
		var col_tick := Color(0.24, 0.54, 0.66, 0.52)
		var mox := fmod((size.x * 0.5) + pan_offset.x, paso_mayor)
		var moy := fmod((size.y * 0.5) + pan_offset.y, paso_mayor)
		if mox < 0.0:
			mox += paso_mayor
		if moy < 0.0:
			moy += paso_mayor
		var mx := mox
		while mx < size.x:
			draw_line(Vector2(mx, 0.0), Vector2(mx, size.y), col_mayor, 1.0)
			mx += paso_mayor
		var my := moy
		while my < size.y:
			draw_line(Vector2(0.0, my), Vector2(size.x, my), col_mayor, 1.0)
			my += paso_mayor
		if zoom >= 0.42:
			var tx := mox
			while tx < size.x:
				var ty := moy
				while ty < size.y:
					var pc := Vector2(tx, ty)
					draw_line(pc - Vector2(4.0, 0.0), pc + Vector2(4.0, 0.0), col_tick, 1.2)
					draw_line(pc - Vector2(0.0, 4.0), pc + Vector2(0.0, 4.0), col_tick, 1.2)
					ty += paso_mayor
				tx += paso_mayor

	# 3. Anillos orbitales del Reactor (160, 380, 680, 960u) + guías radiales + Halo Elíptico Cósmico
	var centro_pant := to_screen_pos(Vector2.ZERO)
	var anillos := [
		{"r": 160.0, "col": Color(0.18, 0.72, 0.56, 0.24), "w": 1.3},
		{"r": 380.0, "col": Color(0.16, 0.54, 0.78, 0.18), "w": 1.1},
		{"r": 680.0, "col": Color(0.75, 0.55, 0.18, 0.14), "w": 1.0},
		{"r": 960.0, "col": Color(0.62, 0.38, 0.88, 0.13), "w": 1.0}
	]
	for a in anillos:
		draw_arc(centro_pant, float(a["r"]) * zoom, 0.0, TAU, 96, a["col"], maxf(1.0, float(a["w"]) * zoom), true)

	var ang_rot := _tiempo_acumulado * 0.22
	draw_arc(centro_pant, 160.0 * zoom, ang_rot, ang_rot + 1.15, 24, Color(0.22, 0.96, 0.62, 0.42), maxf(1.5, 2.2 * zoom), true)
	draw_arc(centro_pant, 380.0 * zoom, -ang_rot * 0.65, -ang_rot * 0.65 + 1.35, 32, Color(0.24, 0.85, 1.0, 0.28), maxf(1.2, 1.8 * zoom), true)
	draw_arc(centro_pant, 680.0 * zoom, ang_rot * 0.40 + 2.2, ang_rot * 0.40 + 3.1, 32, Color(1.0, 0.78, 0.25, 0.22), maxf(1.0, 1.6 * zoom), true)

	# Guías radiales de sector
	var ejes := [
		Vector2(-0.84, -0.54), # NW Azul
		Vector2(-0.99, 0.12),  # W Botón
		Vector2(0.0, 1.0),     # S Verde
		Vector2(0.84, -0.54),  # NE Dorada
		Vector2(0.0, -1.0)     # N Cósmica
	]
	for dir_eje in ejes:
		var p_ini := to_screen_pos(dir_eje * 80.0)
		var p_fin := to_screen_pos(dir_eje * 1020.0)
		draw_line(p_ini, p_fin, Color(0.28, 0.50, 0.65, 0.14), 1.0, true)

	# Halo Elíptico de la Corona Cósmica (0, -1280), rx=460, ry=210
	var elipse_pts := PackedVector2Array()
	var centro_cos := Vector2(0.0, -1280.0)
	for i in range(65):
		var t := (float(i) / 64.0) * TAU
		var pv := centro_cos + Vector2(cos(t) * 460.0, sin(t) * 210.0)
		elipse_pts.append(to_screen_pos(pv))
	draw_polyline(elipse_pts, Color(0.78, 0.48, 1.0, 0.24), maxf(1.0, 1.6 * zoom), true)

	# 4. Marcas de agua tipográficas de sector (en español, libres de nodos)
	if _font != null:
		var sectores := [
			{"pos": Vector2(-720, -610), "tit": "SECTOR CINÉTICO", "sub": "PODER ACTIVO DE CLIC", "col": Color(0.32, 0.88, 1.0)},
			{"pos": Vector2(-740, 390), "tit": "INGENIERÍA DEL BOTÓN", "sub": "NÚCLEO MÓVIL & DISIPACIÓN", "col": Color(1.0, 0.64, 0.26)},
			{"pos": Vector2(0, 1020), "tit": "BASTIÓN VITAL", "sub": "BIOCONTENCIÓN & TANQUE", "col": Color(0.32, 0.96, 0.55)},
			{"pos": Vector2(720, -610), "tit": "ARSENAL ÁUREO", "sub": "ECONOMÍA & AUTOCLICK", "col": Color(1.0, 0.82, 0.28)},
			{"pos": Vector2(0, -1550), "tit": "CORONA CÓSMICA", "sub": "MAESTRÍAS & TRASCENDENCIA ASTRAL", "col": Color(0.90, 0.68, 1.0)}
		]
		var tam_tit := maxi(10, int(round(19.0 * clampf(zoom, 0.48, 1.15))))
		var tam_sub := maxi(8, int(round(11.0 * clampf(zoom, 0.55, 1.10))))
		var alpha_wm := clampf(0.28 + zoom * 0.35, 0.24, 0.58)
		for s in sectores:
			var p_wm := to_screen_pos(s["pos"])
			if p_wm.x < -280.0 or p_wm.x > size.x + 280.0 or p_wm.y < -120.0 or p_wm.y > size.y + 120.0:
				continue
			var c_base: Color = s["col"]
			var sz_t := _font.get_string_size(s["tit"], HORIZONTAL_ALIGNMENT_CENTER, -1, tam_tit)
			draw_string(_font, p_wm - Vector2(sz_t.x * 0.5, 0.0), s["tit"], HORIZONTAL_ALIGNMENT_LEFT, -1, tam_tit, Color(c_base.r, c_base.g, c_base.b, alpha_wm))
			if zoom >= 0.36:
				var sz_s := _font.get_string_size(s["sub"], HORIZONTAL_ALIGNMENT_CENTER, -1, tam_sub)
				draw_string(_font, p_wm - Vector2(sz_s.x * 0.5, -float(tam_sub) - 3.0), s["sub"], HORIZONTAL_ALIGNMENT_LEFT, -1, tam_sub, Color(c_base.r, c_base.g, c_base.b, alpha_wm * 0.72))

func _es_nodo_pagable(n: SkillNodeData, oro_banco: int, clics_banco: int) -> bool:
	if n.id == "nodo_origen" or (n.esta_maxeado() and n.nivel_max < 999):
		return false
	var niveles_tot: int = ArbolInterconectadoDatos.contar_niveles_comprados(nodos)
	var costos := n.calcular_costo(niveles_tot)
	var esq_banco: int = MetaprogresoManager.esquirlas_astrales
	return oro_banco >= int(costos.get("oro", 0)) and clics_banco >= int(costos.get("clics", 0)) and esq_banco >= int(costos.get("esquirlas", 0))

func _construir_puntos_conduit(p_a: Vector2, p_b: Vector2, v_a: Vector2, v_b: Vector2, mismo_sector: bool) -> PackedVector2Array:
	var pts := PackedVector2Array()
	if mismo_sector:
		# Bezier cuadrática curvada hacia el exterior respecto a (0,0)
		var mid := (v_a + v_b) * 0.5
		var dir_ab := (v_b - v_a)
		var dist_v := dir_ab.length()
		var perp := Vector2(-dir_ab.y, dir_ab.x).normalized() if dist_v > 0.1 else Vector2.UP
		if mid.length() > 1.0 and perp.dot(mid) < 0.0:
			perp = -perp
		var curvatura := minf(dist_v * 0.16, 44.0)
		var ctrl := to_screen_pos(mid + perp * curvatura)
		var segs := 10
		for i in range(segs + 1):
			var t := float(i) / float(segs)
			var omt := 1.0 - t
			pts.append(omt * omt * p_a + 2.0 * omt * t * ctrl + t * t * p_b)
	else:
		# Traza PCB con chaflán de 45° para puentes híbridos y cruces entre ramas
		var dx := p_b.x - p_a.x
		var dy := p_b.y - p_a.y
		if absf(dx) < 8.0 or absf(dy) < 8.0:
			pts.append(p_a)
			pts.append(p_b)
		elif absf(dx) >= absf(dy):
			var diag := absf(dy) * 0.55
			var sx := signf(dx)
			var sy := signf(dy)
			var c1 := Vector2((p_a.x + p_b.x) * 0.5 - sx * diag, p_a.y)
			var c2 := Vector2((p_a.x + p_b.x) * 0.5 + sx * diag, p_b.y)
			if absf(c2.x - c1.x) > absf(dx) * 0.85:
				var m := (p_a + p_b) * 0.5
				c1 = Vector2(m.x - sx * 6.0, p_a.y + sy * 4.0)
				c2 = Vector2(m.x + sx * 6.0, p_b.y - sy * 4.0)
			pts.append(p_a)
			pts.append(c1)
			pts.append(c2)
			pts.append(p_b)
		else:
			var diag_y := absf(dx) * 0.55
			var sy2 := signf(dy)
			var c1y := Vector2(p_a.x, (p_a.y + p_b.y) * 0.5 - sy2 * diag_y)
			var c2y := Vector2(p_b.x, (p_a.y + p_b.y) * 0.5 + sy2 * diag_y)
			pts.append(p_a)
			pts.append(c1y)
			pts.append(c2y)
			pts.append(p_b)
	return pts

func _colores_polilinea_gradiente(pts: PackedVector2Array, col_a: Color, col_b: Color) -> PackedColorArray:
	var cols := PackedColorArray()
	var n := pts.size()
	if n <= 1:
		for _i in range(n):
			cols.append(col_a)
		return cols
	for i in range(n):
		var t := float(i) / float(n - 1)
		cols.append(col_a.lerp(col_b, t))
	return cols

func _punto_en_polilinea(pts: PackedVector2Array, frac: float) -> Vector2:
	if pts.is_empty():
		return Vector2.ZERO
	if pts.size() == 1:
		return pts[0]
	var total_len := 0.0
	for i in range(pts.size() - 1):
		total_len += pts[i].distance_to(pts[i + 1])
	if total_len <= 0.001:
		return pts[0]
	var target := clampf(frac, 0.0, 1.0) * total_len
	var acum := 0.0
	for i in range(pts.size() - 1):
		var seg_len := pts[i].distance_to(pts[i + 1])
		if acum + seg_len >= target:
			var local_t := (target - acum) / maxf(seg_len, 0.001)
			return pts[i].lerp(pts[i + 1], local_t)
		acum += seg_len
	return pts[pts.size() - 1]

func _dibujar_conexiones_grafo(oro_banco: int, clics_banco: int):
	var lineas_dibujadas: Dictionary = {}
	var view_cull := Rect2(Vector2(-160, -160), size + Vector2(320, 320))
	var hay_hover := (nodo_hover_id != "")

	for id_a in nodos.keys():
		var nodo_a: SkillNodeData = nodos[id_a]
		var pos_a := to_screen_pos(nodo_a.posicion)

		for id_b in nodo_a.nodos_conectados:
			if not nodos.has(id_b):
				continue
			var s_a: String = str(id_a)
			var s_b: String = str(id_b)
			var par_id: String = (s_a + "_" + s_b) if s_a < s_b else (s_b + "_" + s_a)
			if lineas_dibujadas.has(par_id):
				continue
			lineas_dibujadas[par_id] = true

			var nodo_b: SkillNodeData = nodos[id_b]
			var pos_b := to_screen_pos(nodo_b.posicion)
			if not view_cull.has_point(pos_a) and not view_cull.has_point(pos_b):
				var seg_rect := Rect2(pos_a, pos_b - pos_a).abs()
				if not view_cull.intersects(seg_rect):
					continue

			var est_a := ArbolInterconectadoDatos.obtener_estado_nodo(nodo_a, nodos)
			var est_b := ArbolInterconectadoDatos.obtener_estado_nodo(nodo_b, nodos)
			var en_ruta_hover := _hover_ruta_aristas.has(par_id)
			var es_ady_hover: bool = (s_a == nodo_hover_id or s_b == nodo_hover_id)

			# Orientar flujo desde el nodo más cercano al nodo_origen hacia el más lejano
			var dist_a := int(_bfs_dist_origen.get(id_a, 999))
			var dist_b := int(_bfs_dist_origen.get(id_b, 999))
			var n_src := nodo_a if dist_a <= dist_b else nodo_b
			var n_dst := nodo_b if dist_a <= dist_b else nodo_a
			var p_src := to_screen_pos(n_src.posicion)
			var p_dst := to_screen_pos(n_dst.posicion)
			var e_src := est_a if n_src == nodo_a else est_b
			var e_dst := est_b if n_src == nodo_a else est_a

			_dibujar_conduit(p_src, p_dst, n_src, n_dst, e_src, e_dst, en_ruta_hover, es_ady_hover, hay_hover, oro_banco, clics_banco)

func _dibujar_conduit(p_a: Vector2, p_b: Vector2, n_a: SkillNodeData, n_b: SkillNodeData, est_a: String, est_b: String, en_ruta_hover: bool, es_ady_hover: bool, hay_hover: bool, oro_banco: int, clics_banco: int):
	var mismo_sector := (n_a.rama == n_b.rama) or (n_a.rama == "central") or (n_b.rama == "central")
	var pts := _construir_puntos_conduit(p_a, p_b, n_a.posicion, n_b.posicion, mismo_sector)

	var pal_a: Dictionary = COLORES_RAMA.get(n_a.rama if n_a.rama != "central" else n_b.rama, COLORES_RAMA["dorada"])
	var pal_b: Dictionary = COLORES_RAMA.get(n_b.rama if n_b.rama != "central" else n_a.rama, COLORES_RAMA["dorada"])
	var col_a_base: Color = pal_a["base"]
	var col_b_base: Color = pal_b["base"]
	var col_a_brillo: Color = pal_a["brillo"]
	var col_b_brillo: Color = pal_b["brillo"]

	var activa := (est_a in ["comprado", "maxeado"]) and (est_b in ["comprado", "maxeado"])
	var desbloqueable := ((est_a in ["comprado", "maxeado"]) and est_b == "desbloqueable") or \
						 ((est_b in ["comprado", "maxeado"]) and est_a == "desbloqueable")
	var desbloq_pagable := false
	if desbloqueable:
		var nodo_desb := n_b if est_b == "desbloqueable" else n_a
		desbloq_pagable = _es_nodo_pagable(nodo_desb, oro_banco, clics_banco)

	var w_scale := maxf(zoom, 0.45)

	if activa:
		var bloom_cols := _colores_polilinea_gradiente(pts, Color(col_a_brillo.r, col_a_brillo.g, col_a_brillo.b, 0.28), Color(col_b_brillo.r, col_b_brillo.g, col_b_brillo.b, 0.28))
		draw_polyline_colors(pts, bloom_cols, 7.6 * w_scale, true)
		draw_polyline(pts, Color(0.05, 0.08, 0.12, 0.95), 4.0 * w_scale, true)
		var core_cols := _colores_polilinea_gradiente(pts, col_a_base.lightened(0.18), col_b_base.lightened(0.18))
		draw_polyline_colors(pts, core_cols, 2.3 * w_scale, true)

		# Pulsos direccionales saliendo desde el origen
		var speed := 0.55 if not en_ruta_hover else 0.90
		for k in range(2):
			var frac := fmod(_tiempo_acumulado * speed + float(k) * 0.5, 1.0)
			var pos_p := _punto_en_polilinea(pts, frac)
			draw_circle(pos_p, 2.1 * w_scale, Color(1.0, 1.0, 1.0, 0.90))
			draw_circle(pos_p, 3.6 * w_scale, Color(col_b_brillo.r, col_b_brillo.g, col_b_brillo.b, 0.35))
	elif desbloqueable:
		var pulso := 0.52 + sin(_tiempo_acumulado * (5.2 if desbloq_pagable else 3.4)) * 0.38
		var c_p1 := Color(col_b_brillo.r, col_b_brillo.g, col_b_brillo.b, pulso) if desbloq_pagable else Color(COLOR_DESBLOQUEABLE_PULSO.r, COLOR_DESBLOQUEABLE_PULSO.g, COLOR_DESBLOQUEABLE_PULSO.b, pulso * 0.8)
		var c_p2 := c_p1.lightened(0.25)
		draw_polyline(pts, Color(0.06, 0.10, 0.14, 0.85), 3.6 * w_scale, true)
		draw_polyline_colors(pts, _colores_polilinea_gradiente(pts, c_p1, c_p2), (2.7 if desbloq_pagable else 2.1) * w_scale, true)
	else:
		var alpha_lock := 0.36 if (hay_hover and not en_ruta_hover and not es_ady_hover) else 0.78
		var c_lock := Color(COLOR_HIERRO_BLOQUEADO.r, COLOR_HIERRO_BLOQUEADO.g, COLOR_HIERRO_BLOQUEADO.b, alpha_lock)
		draw_polyline(pts, c_lock, 1.8 * w_scale, true)
		if zoom >= 0.45:
			var p_mid := _punto_en_polilinea(pts, 0.5)
			draw_circle(p_mid, 2.0 * w_scale, Color(0.10, 0.14, 0.20, alpha_lock))

	# Iluminación de ruta BFS al hacer hover
	if en_ruta_hover or es_ady_hover:
		var col_ruta := col_b_brillo if en_ruta_hover else Color(0.85, 0.94, 1.0, 0.75)
		col_ruta.a = 0.88 if en_ruta_hover else 0.55
		draw_polyline(pts, col_ruta, (3.4 if en_ruta_hover else 2.4) * w_scale, true)

func _dibujar_nodos_grafo(oro_banco: int, clics_banco: int):
	var view_cull := Rect2(Vector2(-90, -90), size + Vector2(180, 180))
	var lista_diferidos: Array[SkillNodeData] = []
	for id in nodos.keys():
		var n: SkillNodeData = nodos[id]
		var centro := to_screen_pos(n.posicion)
		if not view_cull.has_point(centro):
			continue
		if id == nodo_hover_id or id == nodo_seleccionado_id:
			lista_diferidos.append(n)
			continue
		var estado := ArbolInterconectadoDatos.obtener_estado_nodo(n, nodos)
		_renderizar_nodo_silueta(n, centro, estado, false, false, oro_banco, clics_banco)

	for n_dif in lista_diferidos:
		var centro_d := to_screen_pos(n_dif.posicion)
		var est_d := ArbolInterconectadoDatos.obtener_estado_nodo(n_dif, nodos)
		_renderizar_nodo_silueta(n_dif, centro_d, est_d, n_dif.id == nodo_hover_id, n_dif.id == nodo_seleccionado_id, oro_banco, clics_banco)

func _pts_poligono_regular(centro: Vector2, radio: float, lados: int, rot_rad: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(lados):
		var a := rot_rad + (TAU * float(i)) / float(lados)
		pts.append(centro + Vector2(cos(a), sin(a)) * radio)
	return pts

func _pts_estrella(centro: Vector2, r_ext: float, r_int: float, puntas: int, rot_rad: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var total := puntas * 2
	for i in range(total):
		var a := rot_rad + (TAU * float(i)) / float(total)
		var r := r_ext if (i % 2 == 0) else r_int
		pts.append(centro + Vector2(cos(a), sin(a)) * r)
	return pts

func _dibujar_borde_cerrado(pts: PackedVector2Array, color: Color, grosor: float):
	if pts.size() < 2:
		return
	var loop := PackedVector2Array(pts)
	loop.append(pts[0])
	draw_polyline(loop, color, grosor, true)

func _renderizar_nodo_silueta(n: SkillNodeData, centro: Vector2, estado: String, hover: bool, seleccionado: bool, oro_banco: int, clics_banco: int):
	var radio := _radio_virtual_nodo(n) * zoom
	var paleta: Dictionary = COLORES_RAMA.get(n.rama, COLORES_RAMA["dorada"])
	var col_brillo: Color = paleta["brillo"]
	var col_base: Color = paleta["base"]
	var col_oscuro: Color = paleta["oscuro"]
	var pagable := (estado in ["desbloqueable", "comprado"]) and _es_nodo_pagable(n, oro_banco, clics_banco)
	var en_ruta_hover := _hover_ruta_nodos.has(n.id)
	var es_max_finito := (estado == "maxeado" and n.nivel_max < 999)

	# 1. Anillo de selección / hover / beacon pagable
	if seleccionado:
		var r_sel := radio + 7.0 * zoom
		draw_arc(centro, r_sel, 0.0, TAU, 36, COLOR_ORO_IMPERIAL, maxf(1.6, 2.4 * zoom), true)
		draw_arc(centro, r_sel + 3.5 * zoom, _tiempo_acumulado * 1.4, _tiempo_acumulado * 1.4 + PI * 1.3, 24, Color(col_brillo.r, col_brillo.g, col_brillo.b, 0.72), maxf(1.1, 1.5 * zoom), true)
	elif hover:
		draw_arc(centro, radio + 5.5 * zoom, 0.0, TAU, 32, Color(0.90, 0.96, 1.0, 0.88), maxf(1.4, 2.0 * zoom), true)
	elif en_ruta_hover and nodo_hover_id != "":
		draw_arc(centro, radio + 4.5 * zoom, 0.0, TAU, 28, Color(col_brillo.r, col_brillo.g, col_brillo.b, 0.65), maxf(1.2, 1.6 * zoom), true)

	# 2. Resplandor exterior / Beacon de asequibilidad
	if es_max_finito:
		draw_circle(centro, radio + 7.0 * zoom, Color(col_brillo.r, col_brillo.g, col_brillo.b, 0.16))
		draw_circle(centro, radio + 4.5 * zoom, Color(COLOR_ORO_IMPERIAL.r, COLOR_ORO_IMPERIAL.g, COLOR_ORO_IMPERIAL.b, 0.22))
	elif estado == "comprado":
		draw_circle(centro, radio + 4.5 * zoom, Color(col_brillo.r, col_brillo.g, col_brillo.b, 0.20))
	elif pagable:
		var p_beacon := 0.22 + (0.5 + 0.5 * sin(_tiempo_acumulado * 5.2)) * 0.26
		draw_circle(centro, radio + 6.5 * zoom, Color(col_brillo.r, col_brillo.g, col_brillo.b, p_beacon))
		draw_arc(centro, radio + 4.5 * zoom, 0.0, TAU, 28, Color(col_brillo.r, col_brillo.g, col_brillo.b, 0.45 + p_beacon), maxf(1.2, 1.7 * zoom), true)
	elif estado == "desbloqueable":
		var p_desb := 0.10 + (0.5 + 0.5 * sin(_tiempo_acumulado * 3.0)) * 0.12
		draw_circle(centro, radio + 3.5 * zoom, Color(0.30, 0.90, 0.55, p_desb))

	# 3. Colores de bisel e interior (PRESERVANDO el color de rama en maxeados!)
	var col_borde := Color(0.24, 0.29, 0.37)
	var col_fill := Color(0.06, 0.08, 0.11, 0.96)
	if estado in ["comprado", "maxeado"]:
		col_borde = col_brillo
		col_fill = col_oscuro
	elif estado == "desbloqueable":
		col_borde = col_base.lightened(0.18) if pagable else Color(0.26, 0.72, 0.50)
		col_fill = Color(0.05, 0.14, 0.12, 0.96)

	var es_origen := (n.id == "nodo_origen")
	var es_apex := (n.id in ["apex_keystone_ascension", "cosm_keystone_genesis"])
	var es_infinito := (n.nivel_max >= 999)
	var es_hibrido := (n.rama == "hibrido" and not n.es_keystone)

	# 4. Dibujo de una de las 6 siluetas
	if es_origen:
		var rot1 := _tiempo_acumulado * 0.28
		var hex_ext := _pts_poligono_regular(centro, radio, 6, rot1)
		var hex_int := _pts_poligono_regular(centro, radio * 0.78, 6, -rot1 * 1.4)
		draw_colored_polygon(hex_ext, col_fill)
		_dibujar_borde_cerrado(hex_ext, col_borde, maxf(1.6, 2.6 * zoom))
		draw_colored_polygon(hex_int, Color(0.04, 0.28, 0.18, 0.96))
		_dibujar_borde_cerrado(hex_int, Color(0.55, 1.0, 0.80, 0.90), maxf(1.2, 1.8 * zoom))
		for f_i in range(6):
			var fa := rot1 + (TAU * float(f_i)) / 6.0
			var p1 := centro + Vector2(cos(fa), sin(fa)) * (radio * 0.85)
			var p2 := centro + Vector2(cos(fa), sin(fa)) * (radio + 5.0 * zoom)
			draw_line(p1, p2, col_borde, maxf(1.4, 2.0 * zoom), true)
	elif es_apex:
		var rot_a := _tiempo_acumulado * 0.18
		var star8 := _pts_estrella(centro, radio, radio * 0.76, 8, rot_a)
		draw_colored_polygon(star8, col_fill)
		_dibujar_borde_cerrado(star8, col_borde, maxf(1.6, 2.4 * zoom))
		draw_arc(centro, radio * 0.68, -rot_a * 1.6, -rot_a * 1.6 + PI * 1.4, 24, COLOR_ORO_IMPERIAL, maxf(1.2, 1.8 * zoom), true)
		draw_arc(centro, radio + 4.5 * zoom, rot_a * 1.2, rot_a * 1.2 + PI * 1.2, 24, Color(col_brillo.r, col_brillo.g, col_brillo.b, 0.75), maxf(1.2, 1.6 * zoom), true)
		draw_circle(centro, radio * 0.62, col_fill.darkened(0.25))
	elif n.es_keystone:
		var gear12 := _pts_estrella(centro, radio, radio * 0.85, 12, 0.0)
		draw_colored_polygon(gear12, col_fill)
		_dibujar_borde_cerrado(gear12, col_borde, maxf(1.5, 2.2 * zoom))
		draw_circle(centro, radio * 0.74, col_fill.darkened(0.20))
		draw_arc(centro, radio * 0.74, 0.0, TAU, 32, Color(col_borde.r, col_borde.g, col_borde.b, 0.70), maxf(1.0, 1.4 * zoom), true)
		draw_arc(centro, radio + 4.0 * zoom, _tiempo_acumulado * 0.65, _tiempo_acumulado * 0.65 + 2.1, 20, Color(col_borde.r, col_borde.g, col_borde.b, 0.68), maxf(1.1, 1.5 * zoom), true)
		# 4 puntas de diamante cardinales
		for d_i in range(4):
			var da := (PI * 0.5) * float(d_i)
			var p_tip := centro + Vector2(cos(da), sin(da)) * (radio + 3.0 * zoom)
			draw_circle(p_tip, maxf(1.6, 2.4 * zoom), COLOR_ORO_IMPERIAL if estado in ["comprado", "maxeado"] else col_borde)
	elif es_infinito:
		var hex_inf := _pts_poligono_regular(centro, radio, 6, PI / 6.0)
		draw_colored_polygon(hex_inf, col_fill)
		_dibujar_borde_cerrado(hex_inf, col_borde, maxf(1.4, 2.2 * zoom))
		var r_orb := radio + 5.0 * zoom
		draw_arc(centro, r_orb, 0.0, TAU, 28, Color(col_brillo.r, col_brillo.g, col_brillo.b, 0.50), maxf(1.0, 1.3 * zoom), true)
		var orb_ang := _tiempo_acumulado * 1.4
		for b_i in range(2):
			var ba := orb_ang + PI * float(b_i)
			draw_circle(centro + Vector2(cos(ba), sin(ba)) * r_orb, maxf(1.8, 2.6 * zoom), Color(0.95, 0.85, 1.0, 0.95))
	elif es_hibrido:
		var diam := _pts_poligono_regular(centro, radio * 1.04, 4, 0.0)
		draw_colored_polygon(diam, col_fill)
		# Mitades de borde bicolor según puente
		var c_izq := COLORES_RAMA["azul"]["brillo"]
		var c_der := COLORES_RAMA["dorada"]["brillo"]
		if "azul_verde" in n.id:
			c_izq = COLORES_RAMA["azul"]["brillo"]
			c_der = COLORES_RAMA["verde"]["brillo"]
		elif "verde_dorada" in n.id:
			c_izq = COLORES_RAMA["verde"]["brillo"]
			c_der = COLORES_RAMA["dorada"]["brillo"]
		if estado == "bloqueado":
			c_izq = col_borde
			c_der = col_borde
		var gw := maxf(1.4, 2.2 * zoom)
		draw_line(diam[0], diam[1], c_der, gw, true)
		draw_line(diam[1], diam[2], c_izq, gw, true)
		draw_line(diam[2], diam[3], c_izq, gw, true)
		draw_line(diam[3], diam[0], c_der, gw, true)
		draw_circle(centro, radio * 0.66, col_fill.darkened(0.15))
	else:
		# Estándar: bisel octogonal achaflanado + núcleo circular + arco segmentado de niveles
		var oct := _pts_poligono_regular(centro, radio, 8, PI / 8.0)
		draw_colored_polygon(oct, col_fill)
		_dibujar_borde_cerrado(oct, col_borde, maxf(1.4, 2.1 * zoom))
		draw_circle(centro, radio * 0.72, col_fill.darkened(0.22))
		if n.nivel_max > 1 and n.nivel_max < 999 and zoom >= 0.42:
			var seg_r := radio * 0.84
			var paso_ang := TAU / float(n.nivel_max)
			var gap := minf(0.16, paso_ang * 0.22)
			for s_i in range(n.nivel_max):
				var a0 := -PI * 0.5 + float(s_i) * paso_ang + gap * 0.5
				var a1 := -PI * 0.5 + float(s_i + 1) * paso_ang - gap * 0.5
				var c_seg := col_brillo if s_i < n.nivel_actual else Color(0.22, 0.27, 0.34, 0.65)
				draw_arc(centro, seg_r, a0, a1, 6, c_seg, maxf(1.3, 2.0 * zoom), true)

	# 5. Corona de Oro Imperial para nodos maxeados (preservando el bisel interior de rama!)
	if es_max_finito:
		var r_oro := radio + 2.8 * zoom
		draw_arc(centro, r_oro, 0.0, TAU, 32, COLOR_ORO_IMPERIAL, maxf(1.6, 2.2 * zoom), true)
		for p_i in range(4):
			var pa := PI * 0.25 + (PI * 0.5) * float(p_i)
			var p_corn := centro + Vector2(cos(pa), sin(pa)) * r_oro
			draw_circle(p_corn, maxf(1.6, 2.4 * zoom), COLOR_ORO_IMPERIAL)

	# 6. Reflejo especular superior sutil
	if estado in ["comprado", "maxeado", "desbloqueable"]:
		draw_arc(centro, radio * 0.56, -PI * 0.82, -PI * 0.18, 12, Color(1.0, 1.0, 1.0, 0.26), maxf(1.0, 1.3 * zoom), true)

	# 7. Icono SVG Central (cero emojis en canvas)
	var tex_icon: Texture2D = IconosArbol.obtener_icono(n.id, n.rama)
	if tex_icon != null:
		var icon_sz := radio * (1.12 if (n.es_keystone or es_origen) else 1.08)
		if icon_sz >= 7.0:
			var rect_ico := Rect2(centro - Vector2(icon_sz * 0.5, icon_sz * 0.5), Vector2(icon_sz, icon_sz))
			var col_ico := IconosArbol.obtener_color_icono(n.id, col_brillo, estado, n.rama)
			draw_texture_rect(tex_icon, rect_ico, false, col_ico)

	# 8. Indicador '+' en nodos asequibles
	if pagable and zoom >= 0.42:
		var p_pip := centro + Vector2(radio * 0.72, -radio * 0.72)
		var r_pip := maxf(4.5, 5.5 * clampf(zoom, 0.75, 1.25))
		draw_circle(p_pip, r_pip, Color(0.04, 0.14, 0.12, 0.96))
		draw_arc(p_pip, r_pip, 0.0, TAU, 16, col_brillo, 1.4, true)
		var cr := r_pip * 0.48
		draw_line(p_pip - Vector2(cr, 0.0), p_pip + Vector2(cr, 0.0), Color.WHITE, 1.6)
		draw_line(p_pip - Vector2(0.0, cr), p_pip + Vector2(0.0, cr), Color.WHITE, 1.6)

	# 9. Insignia de Nivel siempre legible para zoom >= 0.48
	if _font != null and zoom >= 0.48 and not es_origen:
		var mostrar_badge := (n.nivel_max > 1) or es_max_finito or n.es_keystone
		if mostrar_badge:
			var txt_lvl := ""
			if es_infinito:
				txt_lvl = "∞ %d" % n.nivel_actual
			elif es_max_finito:
				txt_lvl = "MAX"
			elif n.es_keystone:
				txt_lvl = "KEY" if n.nivel_actual == 0 else "MAX"
			else:
				txt_lvl = "%d/%d" % [n.nivel_actual, n.nivel_max]

			var tam_lvl_fnt := maxi(10, int(round(11.0 * clampf(zoom, 0.75, 1.35))))
			var tam_txt := _font.get_string_size(txt_lvl, HORIZONTAL_ALIGNMENT_CENTER, -1, tam_lvl_fnt)
			var pos_badge := centro + Vector2(0.0, radio + 8.0 * clampf(zoom, 0.75, 1.2))
			var pad_w := 10.0
			var pad_h := 4.0
			var rect_b := Rect2(pos_badge - Vector2(tam_txt.x * 0.5 + pad_w * 0.5, tam_txt.y * 0.72 + pad_h * 0.5), Vector2(tam_txt.x + pad_w, tam_txt.y + pad_h))
			draw_rect(rect_b, Color(0.03, 0.05, 0.08, 0.94), true)
			var c_rim_b := COLOR_ORO_IMPERIAL if es_max_finito else col_borde
			draw_rect(rect_b, Color(c_rim_b.r, c_rim_b.g, c_rim_b.b, 0.85), false, 1.1)
			var c_txt_b := COLOR_ORO_IMPERIAL if es_max_finito else (Color(0.95, 0.98, 1.0) if estado != "bloqueado" else Color(0.65, 0.72, 0.80))
			draw_string(_font, Vector2(rect_b.position.x + pad_w * 0.5, rect_b.position.y + rect_b.size.y - pad_h * 0.5 - 2.0), txt_lvl, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_lvl_fnt, c_txt_b)

func _dibujar_efectos_compra():
	for ef in _efectos_compra:
		var t := float(ef["t"])
		var dur := maxf(float(ef["dur"]), 0.01)
		var p := clampf(t / dur, 0.0, 1.0)
		var ease_out := 1.0 - pow(1.0 - p, 3.0)
		var centro := to_screen_pos(ef["pos"])
		var col: Color = ef["color"]
		var r1 := (18.0 + ease_out * (95.0 if bool(ef["keystone"]) else 68.0)) * zoom
		var a1 := (1.0 - p) * 0.92
		draw_arc(centro, r1, 0.0, TAU, 40, Color(col.r, col.g, col.b, a1), maxf(1.8, 3.2 * (1.0 - p) * zoom), true)
		if bool(ef["keystone"]):
			var r2 := (10.0 + ease_out * 52.0) * zoom
			draw_arc(centro, r2, 0.0, TAU, 32, Color(1.0, 1.0, 1.0, a1 * 0.85), maxf(1.4, 2.2 * zoom), true)
		if _font != null:
			var txt: String = str(ef["texto"])
			var fsz := maxi(13, int(round(16.0 * clampf(zoom, 0.8, 1.3))))
			var sz_t := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fsz)
			var p_txt := centro + Vector2(-sz_t.x * 0.5, -24.0 * zoom - ease_out * 34.0)
			draw_string(_font, p_txt + Vector2(1, 1), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(0, 0, 0, a1))
			draw_string(_font, p_txt, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(col.r, col.g, col.b, a1))

func _dibujar_tooltip_hover(oro_banco: int, clics_banco: int):
	if _arrastrando or nodo_hover_id == "" or not nodos.has(nodo_hover_id) or _font == null:
		return
	var n: SkillNodeData = nodos[nodo_hover_id]
	var estado := ArbolInterconectadoDatos.obtener_estado_nodo(n, nodos)
	var paleta: Dictionary = COLORES_RAMA.get(n.rama, COLORES_RAMA["dorada"])
	var col_rama: Color = paleta["brillo"]
	if n.es_keystone or (estado == "maxeado" and n.nivel_max < 999):
		col_rama = COLOR_ORO_IMPERIAL

	var titulo := n.nombre
	var sub_estado := "NÚCLEO OPERATIVO"
	if n.id != "nodo_origen":
		match estado:
			"maxeado":
				sub_estado = "MAXEADO" if n.nivel_max < 999 else ("MAESTRÍA ∞ · Nv. %d" % n.nivel_actual)
			"comprado":
				sub_estado = "ACTIVO · Nv. %d/%d" % [n.nivel_actual, n.nivel_max] if n.nivel_max < 999 else "MAESTRÍA ∞ · Nv. %d" % n.nivel_actual
			"desbloqueable":
				sub_estado = "LISTO PARA INYECTAR" if _es_nodo_pagable(n, oro_banco, clics_banco) else "ENLAZADO · FALTAN RECURSOS"
			_:
				sub_estado = "BLOQUEADO (MÁX. VECINO)" if n.es_keystone else "BLOQUEADO (60% VECINO)"

	var linea_bono := n.obtener_texto_bono()
	var linea_costo := ""
	if n.id != "nodo_origen" and not (estado == "maxeado" and n.nivel_max < 999):
		var niveles_tot: int = ArbolInterconectadoDatos.contar_niveles_comprados(nodos)
		var c := n.calcular_costo(niveles_tot)
		var partes: Array[String] = []
		if int(c.get("oro", 0)) > 0:
			partes.append("%s Oro" % MetaprogresoManager.formatear_numero(float(c["oro"])))
		if int(c.get("clics", 0)) > 0:
			partes.append("%s Clics" % MetaprogresoManager.formatear_numero(float(c["clics"])))
		if int(c.get("esquirlas", 0)) > 0:
			partes.append("%d Esq" % int(c["esquirlas"]))
		if partes.size() > 0:
			linea_costo = "Costo: " + " + ".join(partes)

	var f_tit := 13
	var f_sub := 10
	var f_bod := 11
	var w_t := _font.get_string_size(titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, f_tit).x
	var w_s := _font.get_string_size(sub_estado, HORIZONTAL_ALIGNMENT_LEFT, -1, f_sub).x
	var w_b := _font.get_string_size(linea_bono, HORIZONTAL_ALIGNMENT_LEFT, -1, f_bod).x
	var w_c := _font.get_string_size(linea_costo, HORIZONTAL_ALIGNMENT_LEFT, -1, f_bod).x if linea_costo != "" else 0.0
	var card_w := clampf(maxf(maxf(w_t, w_s), maxf(w_b, w_c)) + 26.0, 210.0, 340.0)
	var card_h := 72.0 if linea_costo == "" else 90.0

	var centro_n := to_screen_pos(n.posicion)
	var radio_n := _radio_virtual_nodo(n) * zoom
	var pos_card := centro_n + Vector2(radio_n + 16.0, -card_h * 0.5)
	if pos_card.x + card_w > size.x - 16.0:
		pos_card.x = centro_n.x - radio_n - card_w - 16.0
	pos_card.x = clampf(pos_card.x, 16.0, maxf(16.0, size.x - card_w - 16.0))
	pos_card.y = clampf(pos_card.y, 102.0, maxf(102.0, size.y - card_h - 18.0))

	var rect_card := Rect2(pos_card, Vector2(card_w, card_h))
	draw_rect(rect_card, Color(0.025, 0.045, 0.082, 0.95), true)
	draw_rect(rect_card, Color(col_rama.r, col_rama.g, col_rama.b, 0.88), false, 1.5)
	draw_line(pos_card + Vector2(1.0, 1.0), pos_card + Vector2(card_w - 1.0, 1.0), Color(col_rama.r, col_rama.g, col_rama.b, 0.95), 2.5)

	draw_string(_font, pos_card + Vector2(12.0, 18.0), sub_estado, HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 24.0), f_sub, col_rama)
	draw_string(_font, pos_card + Vector2(12.0, 36.0), titulo, HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 24.0), f_tit, Color(0.96, 0.98, 1.0))
	draw_string(_font, pos_card + Vector2(12.0, 56.0), linea_bono, HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 24.0), f_bod, Color(0.45, 0.95, 0.68))
	if linea_costo != "":
		var col_c := Color(0.95, 0.85, 0.42) if _es_nodo_pagable(n, oro_banco, clics_banco) else Color(0.95, 0.45, 0.45)
		draw_string(_font, pos_card + Vector2(12.0, 76.0), linea_costo, HORIZONTAL_ALIGNMENT_LEFT, int(card_w - 24.0), f_bod, col_c)
