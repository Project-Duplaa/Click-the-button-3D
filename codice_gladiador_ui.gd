class_name CodiceGladiadorUI
extends CanvasLayer

## CodiceGladiadorUI — Códice del Gladiador (Tomo de Sabiduría y Bestiario 3D)
## Modal interactivo Dark-Fantasy (#0b0e15 + #d4af37 oro viejo).
## 100% autocontenido por código (no requiere .tscn).
## Contiene 4 pestañas interactivas:
##  1) 📜 Cartas (24 Bendiciones + 6 Corruptas) con siluetas y requisitos de hazaña
##  2) 🔥 Sinergias (6 Fusiones Míticas) con pistas y recetas duales
##  3) 👹 Bestiario 3D (15 Entidades) con vista 3D rotatoria en SubViewport y Némesis
##  4) 🏆 Hazañas (32 Desafíos filtrables por categoría con barra de progreso)

signal codice_cerrado

const AudioManager = preload("res://audio_manager.gd")
const MetaprogresoManager = preload("res://metaprogreso_manager.gd")
const CatalogoBendiciones = preload("res://catalogo_bendiciones.gd")
const LogrosManager = preload("res://logros_manager.gd")

# Paleta Estética Dark Fantasy / Coliseo Neón
const COLOR_FONDO_MODAL = Color(0.043, 0.055, 0.082, 0.96) # #0b0e15
const COLOR_BORDE_ORO = Color(0.83, 0.69, 0.22, 1.0)       # #d4af37
const COLOR_ORO_TENUE = Color(0.55, 0.45, 0.15, 0.6)
const COLOR_TEXTO_TITULO = Color(1.0, 0.92, 0.65, 1.0)
const COLOR_PANEL_INTERNO = Color(0.07, 0.09, 0.13, 0.95)

var _tab_actual: int = 0
var _categoria_filtro_hazana: String = "todas"
var _tipo_enemigo_seleccionado: String = "guardia"

# Referencias UI Principales
var root_control: Control = null
var panel_fondo: PanelContainer = null
var tabs_btn_container: HBoxContainer = null
var contenedor_contenido: MarginContainer = null

# Pestañas
var vista_cartas: ScrollContainer = null
var vista_sinergias: ScrollContainer = null
var vista_bestiario: HBoxContainer = null
var vista_hazanas: VBoxContainer = null

# Elementos del Bestiario 3D
var subviewport_3d: SubViewport = null
var preview_nodo_padre: Node3D = null
var instancia_malla_actual: Node3D = null
var lbl_bestiario_nombre: Label = null
var lbl_bestiario_tipo: Label = null
var lbl_bestiario_bajas: Label = null
var lbl_bestiario_bono: Label = null
var lbl_bestiario_lore: Label = null
var panel_nemesis_status: PanelContainer = null
var lbl_nemesis_status: Label = null

# Diccionario de Datos de Enemigos para el Bestiario (15 Enemigos)
const DATOS_BESTIARIO: Dictionary = {
	"guardia": {
		"nombre": "Guardia Pretoriano",
		"tier": "Común · Cuerpo a cuerpo",
		"icono": "🛡️",
		"lore": "Autómata blindado de bronce que patrulla los límites de la arena. Ataca en formaciones cerradas.",
		"escena": "res://guardia.tscn",
		"color": Color(0.4, 0.7, 0.9)
	},
	"espectro": {
		"nombre": "Espectro del Foso",
		"tier": "Común · Rápido / Enjambre",
		"icono": "👻",
		"lore": "Almas errantes de gladiadores caídos en combate. Su velocidad supera la media y flanquean al objetivo.",
		"escena": "res://espectro.tscn",
		"color": Color(0.6, 0.9, 0.7)
	},
	"arquero": {
		"nombre": "Arquero Balístico",
		"tier": "A Distancia · Hostigador",
		"icono": "🏹",
		"lore": "Dispara flechas energéticas desde el perímetro mientras mantiene distancia táctica con el héroe.",
		"escena": "res://arquero.tscn",
		"color": Color(0.9, 0.7, 0.3)
	},
	"berserker": {
		"nombre": "Berserker Rabioso",
		"tier": "Élite · Embestida",
		"icono": "🪓",
		"lore": "Gladiador poseído por la fiebre de sangre. Se acelera agresivamente cuando sufre heridas.",
		"escena": "res://berserker.tscn",
		"color": Color(0.9, 0.25, 0.25)
	},
	"kamikaze": {
		"nombre": "Minero Inestable (Kamikaze)",
		"tier": "Volátil · Área de Choque",
		"icono": "💣",
		"lore": "Cargado con núcleos de fisión inestables. Detona con violencia al aproximarse al gladiador.",
		"escena": "res://kamikaze.tscn",
		"color": Color(1.0, 0.4, 0.1)
	},
	"bruto": {
		"nombre": "Bruto Aplastador",
		"tier": "Tanque Pesado",
		"icono": "🔨",
		"lore": "Coloso de piedra maciza y titanio. Resiste retrocesos y aturde con ondas terrestres sísmicas.",
		"escena": "res://bruto.tscn",
		"color": Color(0.7, 0.6, 0.5)
	},
	"centurion": {
		"nombre": "Centurión Corrupto",
		"tier": "Líder de Escuadra · Buff Pasivo",
		"icono": "⚔️👑",
		"lore": "Emana auras de resistencia a los enemigos circundantes y comanda las incursiones de asalto.",
		"escena": "res://centurion_corrupto.tscn",
		"color": Color(0.85, 0.3, 0.8)
	},
	"mini_jefe": {
		"nombre": "Heraldo de la Arena",
		"tier": "Mini-Jefe de Oleada",
		"icono": "💀⭐",
		"lore": "Comandante pretoriano invocado en las oleadas intermedias. Desata ráfagas de proyectiles en cruz.",
		"escena": "res://mini_jefe.tscn",
		"color": Color(1.0, 0.85, 0.2)
	},
	"maestra": {
		"nombre": "Maestra Sanguinaria",
		"tier": "Élite de Duelo",
		"icono": "🩸🗡️",
		"lore": "Duelista implacable que teletransporta su sombra y absorbe vitalidad en cada estocada certera.",
		"escena": "res://maestra_sanguinaria.tscn",
		"color": Color(0.9, 0.1, 0.35)
	},
	"coloso": {
		"nombre": "Coloso de Bronce",
		"tier": "Jefe Titánico",
		"icono": "🗿",
		"lore": "Monumento ancestral animado por la resonancia del Núcleo. Su piel deflecta impactos convencionales.",
		"escena": "res://coloso_bronce.tscn",
		"color": Color(0.85, 0.55, 0.15)
	},
	"parca": {
		"nombre": "La Parca Roja",
		"tier": "Sentencia Suprema",
		"icono": "☠️👑",
		"lore": "Encarnación del juicio inexorable del Coliseo. Su presencia extingue la luz y condena a los indignos.",
		"escena": "res://parca_roja.tscn",
		"color": Color(1.0, 0.05, 0.1)
	},
	"parasito_cursor": {
		"nombre": "Parásito del Cursor",
		"tier": "Interactivo · Anomalía",
		"icono": "🪲",
		"lore": "Se fija sobre el cursor táctico drenando la velocidad de clic hasta ser aplastado manualmente.",
		"escena": "res://parasito_cursor.tscn",
		"color": Color(0.4, 0.9, 0.2)
	},
	"canalizador_vacio": {
		"nombre": "Canalizador del Vacío",
		"tier": "Pilar de Invocación",
		"icono": "🔮",
		"lore": "Ancla gravitatoria que abre brechas de sombras y protege al resto de los combatientes.",
		"escena": "res://canalizador_vacio.tscn",
		"color": Color(0.7, 0.2, 0.9)
	},
	"golem_tesoro": {
		"nombre": "Gólem de Tesoro",
		"tier": "Presa Rara de Fortuna",
		"icono": "🪙💎",
		"lore": "Entidad esquiva invocada por clics continuos. Suelta denarios y orbes dorados al ser impactado.",
		"escena": "res://golem_tesoro.tscn",
		"color": Color(1.0, 0.85, 0.0)
	},
	"heraldo_clic": {
		"nombre": "Heraldo del Clic",
		"tier": "Élite de Fiebre (Overdrive)",
		"icono": "⚡👑",
		"lore": "Guardián atraído por las pulsaciones frenéticas del gladiador. Otorga cofres legendarios al caer.",
		"escena": "res://heraldo_clic.tscn",
		"color": Color(0.2, 0.85, 1.0)
	},
	"espejo_sombrio": {
		"nombre": "El Espejo Sombrío",
		"tier": "Jefe Secreto",
		"icono": "🪞💀",
		"lore": "Reflejo corrupto liberado al destruir el Monolito del Campeón Caído. Otorga Esquirla Astral.",
		"escena": "res://espejo_sombrio.tscn",
		"color": Color(0.75, 0.20, 0.95)
	},
	"centinela_fase": {
		"nombre": "Centinela de Fase",
		"tier": "Blindado de Fase · Solo Botón",
		"icono": "⚡🛡️",
		"lore": "Su escudo cuántico deflecta flechas, hechizos y filos. Solo las ondas e impactos del Botón Móvil atraviesan su fase.",
		"escena": "res://centinela_fase.tscn",
		"color": Color(0.15, 0.90, 1.0)
	},
	"anulador_nucleo": {
		"nombre": "Anulador de Núcleo",
		"tier": "Disruptor Térmico · Solo Botón",
		"icono": "⚡🔮",
		"lore": "Inmune a las armas del gladiador. Proyecta un sifón térmico sobre el Botón Móvil; destrúyelo con pulsaciones y suelta Esquirlas Astrales.",
		"escena": "res://anulador_nucleo.tscn",
		"color": Color(0.72, 0.35, 1.0)
	}
}

func _ready() -> void:
	layer = 24
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if tabs_btn_container == null:
		_construir_ui_completa()

func _process(delta: float) -> void:
	if not visible:
		return
	# Rotación continua y elegante del modelo 3D en el Bestiario
	if preview_nodo_padre != null and _tab_actual == 2:
		preview_nodo_padre.rotate_y(delta * 0.75)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if (event.keycode == KEY_ESCAPE or event.keycode == KEY_C or event.keycode == KEY_J) and visible:
			cerrar()
			get_viewport().set_input_as_handled()

func toggle() -> void:
	if visible:
		cerrar()
	else:
		abrir()

func abrir(tab_inicial: int = 0) -> void:
	visible = true
	if tabs_btn_container == null:
		_construir_ui_completa()
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = true
	AudioManager.play("click", 1.25)
	_cambiar_tab(tab_inicial)

func cerrar() -> void:
	visible = false
	if is_inside_tree() and get_tree() != null:
		var pantalla_fin = get_tree().get_first_node_in_group("pantalla_fin_partida")
		if pantalla_fin == null or not pantalla_fin.visible:
			get_tree().paused = false
	AudioManager.play("click", 0.95)
	codice_cerrado.emit()

# ==============================================================================
# CONSTRUCCIÓN PROGRAMÁTICA DE LA INTERFAZ
# ==============================================================================
func _construir_ui_completa() -> void:
	root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root_control)
	
	# Telón oscuro semitransparente con viñeta
	var telon = ColorRect.new()
	telon.set_anchors_preset(Control.PRESET_FULL_RECT)
	telon.color = Color(0.02, 0.03, 0.05, 0.75)
	root_control.add_child(telon)
	
	# Ventana Central Estilo Códice Rúnico
	panel_fondo = PanelContainer.new()
	panel_fondo.custom_minimum_size = Vector2(980, 580)
	panel_fondo.set_anchors_preset(Control.PRESET_CENTER)
	panel_fondo.offset_left = -490
	panel_fondo.offset_top = -290
	panel_fondo.offset_right = 490
	panel_fondo.offset_bottom = 290
	
	var sb_modal = StyleBoxFlat.new()
	sb_modal.bg_color = COLOR_FONDO_MODAL
	sb_modal.border_color = COLOR_BORDE_ORO
	sb_modal.set_border_width_all(2)
	sb_modal.set_corner_radius_all(10)
	sb_modal.shadow_color = Color(0, 0, 0, 0.85)
	sb_modal.shadow_size = 20
	panel_fondo.add_theme_stylebox_override("panel", sb_modal)
	root_control.add_child(panel_fondo)
	
	var vbox_modal = VBoxContainer.new()
	vbox_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_fondo.add_child(vbox_modal)
	
	# Encabezado con Título y Botón Cerrar
	var header = MarginContainer.new()
	header.add_theme_constant_override("margin_left", 20)
	header.add_theme_constant_override("margin_right", 20)
	header.add_theme_constant_override("margin_top", 14)
	header.add_theme_constant_override("margin_bottom", 8)
	vbox_modal.add_child(header)
	
	var hbox_header = HBoxContainer.new()
	header.add_child(hbox_header)
	
	var lbl_titulo = Label.new()
	lbl_titulo.text = "📜 CÓDICE DEL GLADIADOR & BESTIARIO"
	lbl_titulo.add_theme_color_override("font_color", COLOR_TEXTO_TITULO)
	lbl_titulo.add_theme_font_size_override("font_size", 20)
	lbl_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_header.add_child(lbl_titulo)
	
	var btn_cerrar = Button.new()
	btn_cerrar.text = "✖ CERRAR"
	btn_cerrar.pressed.connect(cerrar)
	hbox_header.add_child(btn_cerrar)
	
	# Barra de Pestañas
	var nav_margin = MarginContainer.new()
	nav_margin.add_theme_constant_override("margin_left", 20)
	nav_margin.add_theme_constant_override("margin_right", 20)
	nav_margin.add_theme_constant_override("margin_bottom", 10)
	vbox_modal.add_child(nav_margin)
	
	tabs_btn_container = HBoxContainer.new()
	tabs_btn_container.add_theme_constant_override("separation", 10)
	nav_margin.add_child(tabs_btn_container)
	
	var nombres_tabs = ["📜 Cartas", "🔥 Sinergias Duales", "👹 Bestiario 3D", "🏆 Hazañas"]
	for i in range(nombres_tabs.size()):
		var b = Button.new()
		b.text = nombres_tabs[i]
		b.custom_minimum_size = Vector2(170, 36)
		b.pressed.connect(_cambiar_tab.bind(i))
		tabs_btn_container.add_child(b)
		
	# Separador dorado
	var sep = HSeparator.new()
	vbox_modal.add_child(sep)
	
	# Contenedor dinámico de contenido
	contenedor_contenido = MarginContainer.new()
	contenedor_contenido.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contenedor_contenido.add_theme_constant_override("margin_left", 20)
	contenedor_contenido.add_theme_constant_override("margin_right", 20)
	contenedor_contenido.add_theme_constant_override("margin_top", 10)
	contenedor_contenido.add_theme_constant_override("margin_bottom", 16)
	vbox_modal.add_child(contenedor_contenido)

func _cambiar_tab(indice: int) -> void:
	_tab_actual = indice
	AudioManager.play("click", 1.1)
	
	# Actualizar estilos de botones de pestañas
	for i in range(tabs_btn_container.get_child_count()):
		var btn = tabs_btn_container.get_child(i) as Button
		if btn != null:
			if i == indice:
				btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
			else:
				btn.remove_theme_color_override("font_color")
				
	# Limpiar contenido anterior
	for c in contenedor_contenido.get_children():
		c.queue_free()
		
	match indice:
		0: _renderizar_tab_cartas()
		1: _renderizar_tab_sinergias()
		2: _renderizar_tab_bestiario()
		3: _renderizar_tab_hazanas()

# ==============================================================================
# TAB 1: 📜 CARTAS (24 BENDICIONES + 6 CORRUPTAS)
# ==============================================================================
func _renderizar_tab_cartas() -> void:
	MetaprogresoManager.asegurar_inicializado()
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	contenedor_contenido.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(vbox)
	
	var todas = CatalogoBendiciones.obtener_todas()
	var desbloqueadas_cnt = 0
	for id in todas.keys():
		if MetaprogresoManager.esta_bendicion_desbloqueada(id):
			desbloqueadas_cnt += 1
			
	var lbl_stats = Label.new()
	lbl_stats.text = "Colección de Bendiciones: %d / %d Desbloqueadas (+ 6 Corruptas)" % [desbloqueadas_cnt, todas.size()]
	lbl_stats.add_theme_color_override("font_color", COLOR_TEXTO_TITULO)
	vbox.add_child(lbl_stats)
	
	# Grid de Cartas Estándar
	var grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	vbox.add_child(grid)
	
	for id in todas.keys():
		var info = todas[id]
		var desbloqueada = MetaprogresoManager.esta_bendicion_desbloqueada(id)
		var card = _crear_tarjeta_bendicion(info, desbloqueada)
		grid.add_child(card)
		
	# Sección de Bendiciones Corruptas
	var lbl_corruptas = Label.new()
	lbl_corruptas.text = "\n🩸 BENDICIONES CORRUPTAS (Pactadas en Altares Oscuros)"
	lbl_corruptas.add_theme_color_override("font_color", Color(0.95, 0.25, 0.35))
	lbl_corruptas.add_theme_font_size_override("font_size", 16)
	vbox.add_child(lbl_corruptas)
	
	var grid_corr = GridContainer.new()
	grid_corr.columns = 3
	grid_corr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_corr.add_theme_constant_override("h_separation", 12)
	grid_corr.add_theme_constant_override("v_separation", 12)
	vbox.add_child(grid_corr)
	
	for id_c in CatalogoBendiciones.BENDICIONES_CORRUPTAS.keys():
		var card_c = _crear_tarjeta_corrupta(CatalogoBendiciones.BENDICIONES_CORRUPTAS[id_c])
		grid_corr.add_child(card_c)

func _crear_tarjeta_bendicion(info: Dictionary, desbloqueada: bool) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(290, 110)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = COLOR_PANEL_INTERNO if desbloqueada else Color(0.04, 0.05, 0.07, 0.95)
	sb.border_color = info["color"] if desbloqueada else Color(0.2, 0.25, 0.35)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var hbox_top = HBoxContainer.new()
	vbox.add_child(hbox_top)
	
	var lbl_ico = Label.new()
	lbl_ico.text = info["icono"] if desbloqueada else "🔒"
	lbl_ico.add_theme_font_size_override("font_size", 18)
	hbox_top.add_child(lbl_ico)
	
	var lbl_nom = Label.new()
	lbl_nom.text = info["nombre"] if desbloqueada else "??? (Bloqueada)"
	lbl_nom.add_theme_color_override("font_color", info["color"] if desbloqueada else Color(0.5, 0.55, 0.65))
	lbl_nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_top.add_child(lbl_nom)
	
	var lbl_rz = Label.new()
	lbl_rz.text = "[%s]" % info["rareza"]
	lbl_rz.add_theme_color_override("font_color", info["color"] if desbloqueada else Color(0.4, 0.45, 0.55))
	lbl_rz.add_theme_font_size_override("font_size", 11)
	hbox_top.add_child(lbl_rz)
	
	var lbl_desc = Label.new()
	if desbloqueada:
		lbl_desc.text = info["descripcion"]
	else:
		lbl_desc.text = "Supera la hazaña correspondiente en el Códice para desbloquear esta bendición en tus runs."
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9) if desbloqueada else Color(0.45, 0.5, 0.55))
	lbl_desc.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl_desc)
	
	return panel

func _crear_tarjeta_corrupta(info: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(290, 120)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.04, 0.06, 0.95)
	sb.border_color = Color(0.95, 0.15, 0.25)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var hbox_top = HBoxContainer.new()
	vbox.add_child(hbox_top)
	
	var lbl_ico = Label.new()
	lbl_ico.text = info["icono"]
	hbox_top.add_child(lbl_ico)
	
	var lbl_nom = Label.new()
	lbl_nom.text = info["nombre"]
	lbl_nom.add_theme_color_override("font_color", Color(1.0, 0.35, 0.45))
	lbl_nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_top.add_child(lbl_nom)
	
	var lbl_ben = Label.new()
	lbl_ben.text = "✨ " + info["bendicion"]
	lbl_ben.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_ben.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	lbl_ben.add_theme_font_size_override("font_size", 11)
	vbox.add_child(lbl_ben)
	
	var lbl_mal = Label.new()
	lbl_mal.text = "💀 " + info["maldicion"]
	lbl_mal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_mal.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	lbl_mal.add_theme_font_size_override("font_size", 11)
	vbox.add_child(lbl_mal)
	
	return panel

# ==============================================================================
# TAB 2: 🔥 SINERGIAS DUALES MÍTICAS
# ==============================================================================
func _renderizar_tab_sinergias() -> void:
	MetaprogresoManager.asegurar_inicializado()
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	contenedor_contenido.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 14)
	scroll.add_child(vbox)
	
	var sinergias = CatalogoBendiciones.obtener_sinergias()
	var descubiertas_cnt = 0
	for s_id in sinergias.keys():
		if MetaprogresoManager.sinergias_descubiertas.has(s_id):
			descubiertas_cnt += 1
			
	var lbl_header = Label.new()
	lbl_header.text = "Fusiones Duales Míticas: %d / %d Descubiertas" % [descubiertas_cnt, sinergias.size()]
	lbl_header.add_theme_color_override("font_color", COLOR_TEXTO_TITULO)
	vbox.add_child(lbl_header)
	
	for s_id in sinergias.keys():
		var datos = sinergias[s_id]
		var descubierta = MetaprogresoManager.sinergias_descubiertas.has(s_id)
		
		var panel = PanelContainer.new()
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.14, 0.05, 0.16, 0.95) if descubierta else Color(0.06, 0.07, 0.10, 0.95)
		sb.border_color = Color(1.0, 0.25, 0.65) if descubierta else Color(0.3, 0.35, 0.45)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 12
		sb.content_margin_bottom = 12
		panel.add_theme_stylebox_override("panel", sb)
		vbox.add_child(panel)
		
		var v_sin = VBoxContainer.new()
		panel.add_child(v_sin)
		
		var reqs: Array = datos["requisitos"]
		var req1_nombre = CatalogoBendiciones.BENDICIONES.get(reqs[0], {}).get("nombre", reqs[0])
		var req2_nombre = CatalogoBendiciones.BENDICIONES.get(reqs[1], {}).get("nombre", reqs[1])
		
		var h_tit = HBoxContainer.new()
		v_sin.add_child(h_tit)
		
		var l_ico = Label.new()
		l_ico.text = datos["icono"] if descubierta else "❓"
		l_ico.add_theme_font_size_override("font_size", 20)
		h_tit.add_child(l_ico)
		
		var l_nom = Label.new()
		l_nom.text = datos["nombre"] if descubierta else "??? (Fusión Oculta)"
		l_nom.add_theme_color_override("font_color", Color(1.0, 0.5, 0.8) if descubierta else Color(0.6, 0.65, 0.75))
		l_nom.add_theme_font_size_override("font_size", 16)
		l_nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h_tit.add_child(l_nom)
		
		var l_receta = Label.new()
		if descubierta:
			l_receta.text = "Receta: [%s] + [%s]" % [req1_nombre, req2_nombre]
			l_receta.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		else:
			l_receta.text = "Pista: Combina [%s] con un artefacto complementario en combate" % req1_nombre
			l_receta.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
		v_sin.add_child(l_receta)
		
		var l_desc = Label.new()
		l_desc.text = datos["descripcion"] if descubierta else "Desbloquea ambas cartas en una misma run para activar la fusión cósmica."
		l_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l_desc.add_theme_color_override("font_color", Color(0.9, 0.92, 0.96) if descubierta else Color(0.45, 0.5, 0.55))
		v_sin.add_child(l_desc)

# ==============================================================================
# TAB 3: 👹 BESTIARIO 3D (15 ENTIDADES CON SUBVIEWPORT)
# ==============================================================================
func _renderizar_tab_bestiario() -> void:
	MetaprogresoManager.asegurar_inicializado()
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 16)
	contenedor_contenido.add_child(hbox)
	
	# Columna Izquierda: Lista de Enemigos
	var scroll_lista = ScrollContainer.new()
	scroll_lista.custom_minimum_size = Vector2(280, 0)
	scroll_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(scroll_lista)
	
	var vbox_lista = VBoxContainer.new()
	vbox_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_lista.add_theme_constant_override("separation", 6)
	scroll_lista.add_child(vbox_lista)
	
	for id_tipo in DATOS_BESTIARIO.keys():
		var info = DATOS_BESTIARIO[id_tipo]
		var bajas = int(MetaprogresoManager.bestiario_bajas.get(id_tipo, 0))
		var btn = Button.new()
		btn.text = "%s %s (%d)" % [info["icono"], info["nombre"], bajas]
		btn.custom_minimum_size = Vector2(0, 36)
		btn.pressed.connect(_seleccionar_enemigo_bestiario.bind(id_tipo))
		vbox_lista.add_child(btn)
		
	# Columna Central: Visor 3D en Vivo (SubViewport)
	var panel_3d = PanelContainer.new()
	panel_3d.custom_minimum_size = Vector2(340, 500)
	panel_3d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb_3d = StyleBoxFlat.new()
	sb_3d.bg_color = Color(0.02, 0.03, 0.05, 1.0)
	sb_3d.border_color = COLOR_BORDE_ORO
	sb_3d.set_border_width_all(1)
	sb_3d.set_corner_radius_all(8)
	panel_3d.add_theme_stylebox_override("panel", sb_3d)
	hbox.add_child(panel_3d)
	
	var vp_container = SubViewportContainer.new()
	vp_container.stretch = true
	vp_container.custom_minimum_size = Vector2(340, 500)
	vp_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_3d.add_child(vp_container)
	
	subviewport_3d = SubViewport.new()
	subviewport_3d.own_world_3d = true
	subviewport_3d.transparent_bg = false
	subviewport_3d.size = Vector2i(380, 540)
	subviewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp_container.add_child(subviewport_3d)
	
	_configurar_escena_3d_bestiario()
	
	# Columna Derecha: Detalles, Telemetría de Bajas y Némesis
	var vbox_detalle = VBoxContainer.new()
	vbox_detalle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_detalle.add_theme_constant_override("separation", 12)
	hbox.add_child(vbox_detalle)
	
	lbl_bestiario_nombre = Label.new()
	lbl_bestiario_nombre.text = "Nombre Enemigo"
	lbl_bestiario_nombre.add_theme_color_override("font_color", COLOR_TEXTO_TITULO)
	lbl_bestiario_nombre.add_theme_font_size_override("font_size", 20)
	vbox_detalle.add_child(lbl_bestiario_nombre)
	
	lbl_bestiario_tipo = Label.new()
	lbl_bestiario_tipo.text = "Tier / Comportamiento"
	lbl_bestiario_tipo.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vbox_detalle.add_child(lbl_bestiario_tipo)
	
	var h_stats = HBoxContainer.new()
	vbox_detalle.add_child(h_stats)
	
	lbl_bestiario_bajas = Label.new()
	lbl_bestiario_bajas.text = "Bajas: 0"
	lbl_bestiario_bajas.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	lbl_bestiario_bajas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_stats.add_child(lbl_bestiario_bajas)
	
	lbl_bestiario_bono = Label.new()
	lbl_bestiario_bono.text = "Bono Daño: +0.0%"
	lbl_bestiario_bono.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5))
	h_stats.add_child(lbl_bestiario_bono)
	
	lbl_bestiario_lore = Label.new()
	lbl_bestiario_lore.text = "Descripción de lore..."
	lbl_bestiario_lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_bestiario_lore.add_theme_color_override("font_color", Color(0.85, 0.88, 0.94))
	vbox_detalle.add_child(lbl_bestiario_lore)
	
	# Indicador de Némesis Vengativo
	panel_nemesis_status = PanelContainer.new()
	var sb_nem = StyleBoxFlat.new()
	sb_nem.bg_color = Color(0.20, 0.05, 0.08, 0.9)
	sb_nem.border_color = Color(0.9, 0.2, 0.25)
	sb_nem.set_border_width_all(1)
	sb_nem.set_corner_radius_all(6)
	sb_nem.content_margin_left = 12
	sb_nem.content_margin_right = 12
	sb_nem.content_margin_top = 8
	sb_nem.content_margin_bottom = 8
	panel_nemesis_status.add_theme_stylebox_override("panel", sb_nem)
	vbox_detalle.add_child(panel_nemesis_status)
	
	lbl_nemesis_status = Label.new()
	lbl_nemesis_status.text = "Némesis Activo"
	lbl_nemesis_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_nemesis_status.add_theme_color_override("font_color", Color(1.0, 0.45, 0.5))
	panel_nemesis_status.add_child(lbl_nemesis_status)
	
	_seleccionar_enemigo_bestiario(_tipo_enemigo_seleccionado)

func _configurar_escena_3d_bestiario() -> void:
	if subviewport_3d == null:
		return
		
	# Cámara de estudio profesional: encuadre heroico cercano
	var cam = Camera3D.new()
	cam.position = Vector3(0, 1.25, 2.65)
	cam.current = true
	subviewport_3d.add_child(cam)
	cam.look_at_from_position(Vector3(0, 1.25, 2.65), Vector3(0, 1.05, 0), Vector3.UP)
	
	# Iluminación de Estudio Tri-Punto (Key + Fill + Rim) con Ambiente Suave
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.07, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.65)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.glow_intensity = 0.30
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 1.25
	
	var we = WorldEnvironment.new()
	we.environment = env
	subviewport_3d.add_child(we)
	
	# 1. Luz Principal Frontal (Key Light)
	var luz_key = DirectionalLight3D.new()
	luz_key.position = Vector3(1.5, 2.8, 3.2)
	luz_key.rotation_degrees = Vector3(-35, 25, 0)
	luz_key.light_color = Color(1.0, 0.98, 0.94)
	luz_key.light_energy = 1.15
	subviewport_3d.add_child(luz_key)
	
	# 2. Luz de Relleno Lateral (Fill Light)
	var luz_fill = DirectionalLight3D.new()
	luz_fill.position = Vector3(-2.2, 1.6, 2.0)
	luz_fill.rotation_degrees = Vector3(-20, -45, 0)
	luz_fill.light_color = Color(0.65, 0.8, 1.0)
	luz_fill.light_energy = 0.55
	subviewport_3d.add_child(luz_fill)
	
	# 3. Luz de Contorno Trasera (Rim Light / Kicker) para separar del fondo
	var luz_rim = DirectionalLight3D.new()
	luz_rim.position = Vector3(0, 3.2, -2.8)
	luz_rim.rotation_degrees = Vector3(30, 180, 0)
	luz_rim.light_color = Color(1.0, 0.85, 0.6)
	luz_rim.light_energy = 0.65
	subviewport_3d.add_child(luz_rim)
	
	preview_nodo_padre = Node3D.new()
	subviewport_3d.add_child(preview_nodo_padre)

func _seleccionar_enemigo_bestiario(tipo: String) -> void:
	_tipo_enemigo_seleccionado = tipo
	if not DATOS_BESTIARIO.has(tipo):
		return
		
	var info = DATOS_BESTIARIO[tipo]
	lbl_bestiario_nombre.text = "%s %s" % [info["icono"], info["nombre"]]
	lbl_bestiario_tipo.text = info["tier"]
	
	var bajas = int(MetaprogresoManager.bestiario_bajas.get(tipo, 0))
	var bono_pct = MetaprogresoManager.obtener_bono_bestiario(tipo) * 100.0
	lbl_bestiario_bajas.text = "Bajas Registradas: %d" % bajas
	lbl_bestiario_bono.text = "Bono Daño: +%.1f%% (Máx +20%%)" % bono_pct
	lbl_bestiario_lore.text = info["lore"]
	
	# Comprobar si esta entidad es el Némesis actual
	var nem = MetaprogresoManager.nemesis_activo
	var es_nemesis = nem.get("activo", false) and nem.get("clase_enemigo", "") == tipo
	if es_nemesis:
		panel_nemesis_status.visible = true
		lbl_nemesis_status.text = "⚠️ ¡NÉMESIS ACTUAL EN CURSO!\n'%s' (Racha: %d). Ha devorado %d Oro y %d Clics. ¡Destrúyelo en la arena para recuperar el botín!" % [
			nem.get("nombre_titulo", "Verdugo"), nem.get("racha", 1), nem.get("oro_robado", 0), nem.get("clics_robados", 0)
		]
	else:
		panel_nemesis_status.visible = false
		
	# Actualizar la malla 3D de previsualización de forma segura
	_actualizar_malla_preview(info)

func _actualizar_malla_preview(info: Dictionary) -> void:
	if preview_nodo_padre == null:
		return
		
	if instancia_malla_actual != null and is_instance_valid(instancia_malla_actual):
		instancia_malla_actual.queue_free()
		instancia_malla_actual = null
		
	var ruta_escena: String = info.get("escena", "")
	var escena_cargada: PackedScene = null
	if ResourceLoader.exists(ruta_escena):
		escena_cargada = load(ruta_escena) as PackedScene
		
	if escena_cargada != null:
		preview_nodo_padre.process_mode = Node.PROCESS_MODE_ALWAYS
		var inst = escena_cargada.instantiate()
		inst.process_mode = Node.PROCESS_MODE_ALWAYS
		# Retirar scripts activos de IA para evitar errores en SubViewport aislado
		inst.set_script(null)

		# Ocultar telegraphs, auras, colisiones, luces y escudos/corazas de combate en el visor del bestiario
		_limpiar_nodos_combate_bestiario(inst)
		preview_nodo_padre.add_child(inst)
		_limpiar_nodos_combate_bestiario(inst)

		var mod_prev: Node3D = inst.get_node_or_null("Modelo") as Node3D
		if mod_prev == null:
			mod_prev = inst.get_node_or_null("ModeloVisual") as Node3D
		if mod_prev == null:
			mod_prev = inst as Node3D
		if mod_prev != null:
			var anim_prev := AnimadorEntidad.new(mod_prev)
			if anim_prev.esta_listo():
				var ap_prev := anim_prev.obtener_animation_player()
				if ap_prev != null:
					ap_prev.process_mode = Node.PROCESS_MODE_ALWAYS
				anim_prev.reproducir_bucle("idle", 0.0, 1.0, 0)

		preview_nodo_padre.rotation.y = PI + 0.48
		instancia_malla_actual = inst
		
		# Ajuste de encuadre según el tamaño del jefe/élite para encuadre áureo en SubViewport
		var esc_base: float = 0.72
		var off_y: float = 0.12
		var nom_low = info.get("nombre", "").to_lower()
		if "parca" in nom_low:
			esc_base = 0.48
			off_y = 0.04
		elif "coloso" in nom_low:
			esc_base = 0.42
			off_y = 0.02
		elif "centurión" in nom_low or "centurion" in nom_low:
			esc_base = 0.50
			off_y = 0.06
		elif "bruto" in nom_low:
			esc_base = 0.62
			off_y = 0.10
		elif "maestra" in nom_low:
			esc_base = 0.48
			off_y = 0.06
		elif "heraldo de la arena" in nom_low:
			esc_base = 0.50
			off_y = 0.06
		elif "heraldo" in nom_low:
			esc_base = 0.62
			off_y = 0.10
		elif "minero" in nom_low:
			esc_base = 0.78
			off_y = 0.18
		elif "arquero" in nom_low:
			esc_base = 0.80
			off_y = 0.15
		elif "berserker" in nom_low:
			esc_base = 0.70
			off_y = 0.10
		elif "guardia" in nom_low:
			esc_base = 0.76
			off_y = 0.12
		elif "espectro" in nom_low:
			esc_base = 0.80
			off_y = 0.15
		elif "parásito" in nom_low or "parasito" in nom_low:
			esc_base = 1.25
			off_y = 0.55
		elif "gólem" in nom_low or "golem" in nom_low:
			esc_base = 0.80
			off_y = 0.18
		elif "canalizador" in nom_low:
			esc_base = 0.74
			off_y = 0.12
		elif "espejo" in nom_low:
			esc_base = 0.48
			off_y = 0.06
		inst.scale = Vector3.ONE * esc_base
		inst.position = Vector3(0, off_y, 0)
	else:
		# Malla procedural de respaldo si la escena específica no existe
		var mesh_instance = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.9, 1.4, 0.9)
		mesh_instance.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = info.get("color", Color(0.7, 0.7, 0.7))
		mat.metallic = 0.5
		mat.roughness = 0.4
		mesh_instance.material_override = mat
		preview_nodo_padre.add_child(mesh_instance)
		instancia_malla_actual = mesh_instance
		mesh_instance.position = Vector3(0, 0.7, 0)

func _limpiar_nodos_combate_bestiario(n: Node) -> void:
	for hijo in n.get_children():
		if hijo is Light3D:
			hijo.visible = false
		var h_nom = hijo.name.to_lower()
		if "telegraph" in h_nom or "marca" in h_nom or "aura" in h_nom or "escudo" in h_nom or "coraza" in h_nom or "burbuja" in h_nom or "collision" in h_nom:
			hijo.visible = false
		_limpiar_nodos_combate_bestiario(hijo)

# ==============================================================================
# TAB 4: 🏆 HAZAÑAS (32 DESAFÍOS FILTRABLES CON BARRA GLOBAL)
# ==============================================================================
func _renderizar_tab_hazanas() -> void:
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	contenedor_contenido.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 14)
	scroll.add_child(vbox)
	
	var todas_hazanas = LogrosManager.DEFINICIONES_LOGROS
	var completadas_cnt = 0
	for id in todas_hazanas.keys():
		var log_mgr = get_tree().get_first_node_in_group("logros_manager")
		if log_mgr != null and log_mgr.has_method("tiene_logro"):
			if log_mgr.tiene_logro(id):
				completadas_cnt += 1
				
	var pct = float(completadas_cnt) / float(max(1, todas_hazanas.size())) * 100.0
	
	# Barra de Progreso Global
	var hbox_barra = HBoxContainer.new()
	vbox.add_child(hbox_barra)
	
	var lbl_p = Label.new()
	lbl_p.text = "Progreso Global de Hazañas: %d / %d (%d%%)" % [completadas_cnt, todas_hazanas.size(), int(round(pct))]
	lbl_p.add_theme_color_override("font_color", COLOR_TEXTO_TITULO)
	lbl_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_barra.add_child(lbl_p)
	
	var pbar = ProgressBar.new()
	pbar.custom_minimum_size = Vector2(250, 18)
	pbar.max_value = todas_hazanas.size()
	pbar.value = completadas_cnt
	pbar.show_percentage = false
	hbox_barra.add_child(pbar)
	
	# Filtros por Categoría
	var h_filtros = HBoxContainer.new()
	h_filtros.add_theme_constant_override("separation", 8)
	vbox.add_child(h_filtros)
	
	var cats = [
		{"id": "todas", "nom": "Todas (32)"},
		{"id": "clic", "nom": "⚡ Clic (8)"},
		{"id": "combate", "nom": "⚔️ Combate (8)"},
		{"id": "clase", "nom": "🛡️ Clase (8)"},
		{"id": "tormento", "nom": "🩸 Tormento (8)"}
	]
	
	for c in cats:
		var btn_f = Button.new()
		btn_f.text = c["nom"]
		btn_f.pressed.connect(_filtrar_hazanas.bind(c["id"]))
		if _categoria_filtro_hazana == c["id"]:
			btn_f.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		h_filtros.add_child(btn_f)
		
	# Lista de Hazañas
	for id in todas_hazanas.keys():
		var datos = todas_hazanas[id]
		var cat_item = datos.get("categoria", "")
		if _categoria_filtro_hazana != "todas" and cat_item != _categoria_filtro_hazana:
			continue
			
		var desbloqueado = false
		var log_mgr = get_tree().get_first_node_in_group("logros_manager")
		if log_mgr != null and log_mgr.has_method("tiene_logro"):
			desbloqueado = log_mgr.tiene_logro(id)
			
		var panel = PanelContainer.new()
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.10, 0.12, 0.16, 0.95) if desbloqueado else Color(0.05, 0.06, 0.08, 0.95)
		sb.border_color = COLOR_BORDE_ORO if desbloqueado else Color(0.25, 0.3, 0.4)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		panel.add_theme_stylebox_override("panel", sb)
		vbox.add_child(panel)
		
		var h_haz = HBoxContainer.new()
		h_haz.add_theme_constant_override("separation", 14)
		panel.add_child(h_haz)
		
		var l_ico = Label.new()
		l_ico.text = datos["icono"] if desbloqueado else "🔒"
		l_ico.add_theme_font_size_override("font_size", 22)
		h_haz.add_child(l_ico)
		
		var v_info = VBoxContainer.new()
		v_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h_haz.add_child(v_info)
		
		var l_tit = Label.new()
		l_tit.text = datos["titulo"]
		l_tit.add_theme_color_override("font_color", COLOR_TEXTO_TITULO if desbloqueado else Color(0.65, 0.7, 0.8))
		l_tit.add_theme_font_size_override("font_size", 15)
		v_info.add_child(l_tit)
		
		var l_des = Label.new()
		l_des.text = datos["desc"]
		l_des.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l_des.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92) if desbloqueado else Color(0.45, 0.5, 0.55))
		l_des.add_theme_font_size_override("font_size", 12)
		v_info.add_child(l_des)
		
		# Pastilla de Recompensa
		var p_rec = PanelContainer.new()
		var sb_r = StyleBoxFlat.new()
		sb_r.bg_color = Color(0.18, 0.14, 0.05, 0.95) if desbloqueado else Color(0.08, 0.08, 0.12, 0.9)
		sb_r.border_color = COLOR_BORDE_ORO if desbloqueado else Color(0.3, 0.35, 0.45)
		sb_r.set_border_width_all(1)
		sb_r.set_corner_radius_all(6)
		sb_r.content_margin_left = 10
		sb_r.content_margin_right = 10
		sb_r.content_margin_top = 6
		sb_r.content_margin_bottom = 6
		p_rec.add_theme_stylebox_override("panel", sb_r)
		h_haz.add_child(p_rec)
		
		var l_rec = Label.new()
		l_rec.text = datos.get("recompensa_texto", "")
		l_rec.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4) if desbloqueado else Color(0.6, 0.65, 0.75))
		l_rec.add_theme_font_size_override("font_size", 12)
		p_rec.add_child(l_rec)

func _filtrar_hazanas(categoria: String) -> void:
	_categoria_filtro_hazana = categoria
	_cambiar_tab(3)
