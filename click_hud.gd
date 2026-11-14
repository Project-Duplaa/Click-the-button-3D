extends CanvasLayer

# ClickHUD Modernizado - Dark Fantasy Colosseum Top Bar + Roguelike Blessing Draft & Multi-Boss HUD
# Preserva 100% los nodos de click_hud.tscn y conecta el catálogo de 24 Bendiciones + 6 Sinergias Duales,
# el medidor de Fiebre / Overdrive (x1..x5) y el soporte para múltiples Jefes simultáneos.

const MALLAS_AVATAR = {
	"Novato": preload("res://personaje/character-male-a.glb"),
	"Guerrero": preload("res://personaje/character-male-d.glb"),
	"Cazador": preload("res://personaje/character-female-e.glb"),
	"Mago": preload("res://personaje/character-female-b.glb"),
	"Paladín Solar": preload("res://personaje/character-male-d.glb"),
	"Francotirador Astral": preload("res://personaje/character-female-e.glb"),
	"Archimago del Vacío": preload("res://personaje/character-female-b.glb")
}

const TEX_CORAZON_LLENO = preload("res://ui_assets/hud_gem_heart.png")
const TEX_CORAZON_VACIO = preload("res://ui_assets/hud_gem_heart_empty.png")
const ArbolMejorasPoEEscena = preload("res://arbol_mejoras_poe.tscn")
const CatalogoBendiciones = preload("res://catalogo_bendiciones.gd")

# Referencias a la Barra Superior Continua
@onready var label_clase: Label = $Control/BarraSuperior/ContenedorHeroe/LabelClase
@onready var bar_vida: ProgressBar = $Control/BarraSuperior/ContenedorHeroe/BarVida
@onready var label_vida: Label = $Control/BarraSuperior/ContenedorHeroe/BarVida/LabelVida

@onready var avatar_frame: Panel = $Control/BarraSuperior/AvatarFrame
@onready var subviewport_avatar: SubViewport = $Control/BarraSuperior/AvatarFrame/SubViewportContainer/SubViewport
@onready var modelo_avatar_nodo: Node3D = $Control/BarraSuperior/AvatarFrame/SubViewportContainer/SubViewport/ModeloAvatar
@onready var camara_avatar: Camera3D = $Control/BarraSuperior/AvatarFrame/SubViewportContainer/SubViewport/CamaraAvatar

@onready var label_vidas: Label = $Control/BarraSuperior/ContenedorVidas/LabelVidas
@onready var hbox_corazones: HBoxContainer = $Control/BarraSuperior/ContenedorVidas/HBoxCorazones
@onready var corazon1: TextureRect = $Control/BarraSuperior/ContenedorVidas/HBoxCorazones/Corazon1
@onready var corazon2: TextureRect = $Control/BarraSuperior/ContenedorVidas/HBoxCorazones/Corazon2
@onready var corazon3: TextureRect = $Control/BarraSuperior/ContenedorVidas/HBoxCorazones/Corazon3

@onready var label_oleada: Label = $Control/BarraSuperior/ContenedorCentro/VBoxCentro/LabelOleada
@onready var label_tiempo: Label = $Control/BarraSuperior/ContenedorCentro/VBoxCentro/LabelTiempo
@onready var label_nucleo: Label = $Control/BarraSuperior/ContenedorCentro/VBoxCentro/LabelNucleo

@onready var label_oro: Label = $Control/BarraSuperior/ContenedorEconomia/HBoxOro/LabelOro
@onready var label_bajas: Label = $Control/BarraSuperior/ContenedorEconomia/HBoxBajas/LabelBajas

# XP y Barra
@onready var bar_xp: ProgressBar = $Control/BarXP
@onready var label_xp: Label = $Control/BarXP/LabelXP

# Modales y Paneles
@onready var modal_mejora: Panel = $Control/ModalMejora
@onready var btn_opc1: Button = $Control/ModalMejora/VBox/HBox/BtnOpc1
@onready var btn_opc2: Button = $Control/ModalMejora/VBox/HBox/BtnOpc2
@onready var btn_opc3: Button = $Control/ModalMejora/VBox/HBox/BtnOpc3

@onready var panel_jefe: Panel = $Control/PanelJefe
@onready var label_nombre_jefe: Label = $Control/PanelJefe/LabelNombreJefe
@onready var bar_vida_jefe: ProgressBar = $Control/PanelJefe/BarVidaJefe
@onready var label_vida_jefe: Label = $Control/PanelJefe/BarVidaJefe/LabelVidaJefe

var jugador: Node = null
var tiempo_total: float = 0.0
var oleada: int = 1
var clicks_boton: int = 0
var vel_boton: float = 2.8
var _clase_actual_avatar: String = ""

var est_actual: float = 14.0
var est_max: float = 14.0
var est_en_colapso: bool = false
var _overlay_colapso: ColorRect = null
var arbol_poe_instancia: CanvasLayer = null

var _opciones_bendicion_actuales: Array = []
var _niveles_pendientes: int = 0

func _ready():
	add_to_group("hud")
	process_mode = Node.PROCESS_MODE_ALWAYS
	if modal_mejora != null:
		modal_mejora.process_mode = Node.PROCESS_MODE_ALWAYS
		modal_mejora.visible = false
	if panel_jefe != null:
		panel_jefe.visible = false

	_overlay_colapso = ColorRect.new()
	_overlay_colapso.name = "OverlayColapso"
	_overlay_colapso.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_colapso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_colapso.color = Color(0.85, 0.05, 0.1, 0.0)
	add_child(_overlay_colapso)

	_calibrar_avatar()

	jugador = get_tree().get_first_node_in_group("jugador")
	if jugador != null:
		jugador.stats_actualizadas.connect(_on_stats_actualizadas)
		jugador.nivel_subido.connect(_on_nivel_subido)
		if jugador.has_signal("economia_actualizada"):
			jugador.economia_actualizada.connect(_on_economia_actualizada)
		_on_stats_actualizadas(jugador.vida, jugador.vida_maxima, jugador.xp, jugador.xp_siguiente_nivel, jugador.nivel, jugador.oro, jugador.bajas)
	else:
		_actualizar_corazones_dinamicos(1, 1)

	if btn_opc1 != null:
		btn_opc1.pressed.connect(func(): _seleccionar_carta_bendicion(0))
	if btn_opc2 != null:
		btn_opc2.pressed.connect(func(): _seleccionar_carta_bendicion(1))
	if btn_opc3 != null:
		btn_opc3.pressed.connect(func(): _seleccionar_carta_bendicion(2))

	_conectar_boton_movil()
	call_deferred("_conectar_boton_movil")
	_crear_boton_test_parca()

func _calibrar_avatar():
	if camara_avatar != null:
		camara_avatar.position = Vector3(0.0, 0.44, 0.56)
		camara_avatar.look_at_from_position(Vector3(0.0, 0.44, 0.56), Vector3(0.0, 0.41, 0.0), Vector3.UP)
		camara_avatar.fov = 40.0
	if modelo_avatar_nodo != null:
		modelo_avatar_nodo.rotation_degrees.y = 165.0

func _conectar_boton_movil():
	var b = get_tree().get_first_node_in_group("boton_movil")
	if b != null:
		if not b.click_presionado.is_connected(_on_click_boton_presionado):
			b.click_presionado.connect(_on_click_boton_presionado)
		if b.has_signal("estabilidad_actualizada"):
			if not b.estabilidad_actualizada.is_connected(_on_estabilidad_boton_actualizada):
				b.estabilidad_actualizada.connect(_on_estabilidad_boton_actualizada)
		if "rapidez_movimiento" in b:
			vel_boton = b.rapidez_movimiento
		if "tiempo_estabilidad_actual" in b:
			est_actual = b.tiempo_estabilidad_actual
			est_max = b.tiempo_estabilidad_max
			est_en_colapso = b.en_colapso

func _on_estabilidad_boton_actualizada(actual: float, maximo: float, en_colapso: bool):
	est_actual = actual
	est_max = maximo
	est_en_colapso = en_colapso

func _on_click_boton_presionado(total: int):
	clicks_boton = total
	var b = get_tree().get_first_node_in_group("boton_movil")
	if b != null and "rapidez_movimiento" in b:
		vel_boton = b.rapidez_movimiento

func _process(delta: float):
	if not get_tree().paused and clicks_boton > 0:
		tiempo_total += delta
	var minutos = int(tiempo_total) / 60
	var segundos = int(tiempo_total) % 60

	var partida = get_tree().get_first_node_in_group("partida")
	if label_tiempo != null:
		if partida != null and "modo_juicio_final" in partida and partida.modo_juicio_final:
			label_tiempo.text = "💀 JUICIO FINAL (%02d:%02d)" % [minutos, segundos]
			label_tiempo.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		else:
			label_tiempo.text = "⏱ %02d:%02d" % [minutos, segundos]

	if _overlay_colapso != null:
		if est_en_colapso:
			var alpha_colapso = 0.14 + sin(tiempo_total * 8.0) * 0.10
			_overlay_colapso.color = Color(0.85, 0.05, 0.1, alpha_colapso)
		else:
			_overlay_colapso.color = Color(0.85, 0.05, 0.1, 0.0)

	if label_nucleo != null:
		var boton = get_tree().get_first_node_in_group("boton_movil")
		var fever_mult: int = 1
		var en_overdrive: bool = false
		if jugador != null:
			if "multiplicador_fiebre" in jugador:
				fever_mult = jugador.multiplicador_fiebre
			if "en_overdrive" in jugador:
				en_overdrive = jugador.en_overdrive

		if clicks_boton == 0:
			label_nucleo.text = "⚡ ¡PULSA EL BOTÓN EN EL CENTRO PARA INICIAR! ⚡"
			var pulso = 0.65 + sin(tiempo_total * 4.5) * 0.35
			label_nucleo.add_theme_color_override("font_color", Color(0.18, 0.95, 1.0, pulso))
		elif boton != null and "estado_actual" in boton:
			match boton.estado_actual:
				1: # ENCADENADO
					var parpadeo = int(tiempo_total * 4.0) % 2 == 0
					if parpadeo:
						label_nucleo.text = "🔒 ¡NÚCLEO ENCADENADO! Activa las 3 palancas en la arena 🔒"
						label_nucleo.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
					else:
						label_nucleo.text = "⚡ Cadenas restantes: %d / 3" % boton.cadenas_activas
						label_nucleo.add_theme_color_override("font_color", Color(1.0, 0.8, 0.25))
				2: # SOBRECARGA_FRENESI
					label_nucleo.text = "🔥 ¡FRENESÍ DE SOBRECARGA! x3 CLICS Y ORO (%.1fs) | Fiebre x%d 🔥" % [boton._tiempo_frenesi, fever_mult]
					label_nucleo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
				_: # ACTIVO
					var clk_bloq = boton.clics_para_bloqueo if "clics_para_bloqueo" in boton else 20
					var prox = clk_bloq - (clicks_boton % clk_bloq)
					var tag_fiebre = ("🔥 OVERDRIVE x5" if en_overdrive else ("⚡ Fiebre x%d" % fever_mult))
					label_nucleo.text = "⚡ %d Clics | %s | ⛓️ Cadenas: %d" % [clicks_boton, tag_fiebre, prox]
					var col_amenaza = Color(0.25, 0.88, 1.0)
					if en_overdrive or fever_mult >= 4:
						col_amenaza = Color(1.0, 0.35, 0.9)
					elif fever_mult >= 2:
						col_amenaza = Color(1.0, 0.82, 0.2)
					label_nucleo.add_theme_color_override("font_color", col_amenaza)
		else:
			label_nucleo.text = "⚡ %d Clics (Vel: %.1f m/s)" % [clicks_boton, vel_boton]
			label_nucleo.add_theme_color_override("font_color", Color(0.25, 0.88, 1.0))

	if label_oleada != null:
		if clicks_boton == 0:
			label_oleada.text = "⚔️ EN ESPERA"
		else:
			label_oleada.text = "⚔️ OLEADA %d" % oleada

	_sincronizar_jefe_prioritario()

func _on_stats_actualizadas(vida, max_vida, xp, xp_sig, nivel, oro, bajas):
	if jugador != null and "clase" in jugador:
		var nombre_clase = str(jugador.clase)
		if label_clase != null:
			label_clase.text = "Clase: %s (Nv. %d)" % [nombre_clase, nivel]
		_actualizar_avatar_clase(nombre_clase)

	if jugador != null and "reapariciones" in jugador:
		var vidas_max = 1
		if jugador.has_method("obtener_vidas_maximas"):
			vidas_max = jugador.obtener_vidas_maximas()
		var vidas_restantes = clampi(jugador.reapariciones + 1, 0, vidas_max)
		_actualizar_corazones_dinamicos(vidas_restantes, vidas_max)

	if bar_vida != null:
		bar_vida.max_value = max_vida
		bar_vida.value = vida
		if label_vida != null:
			if jugador != null and "escudo_almas" in jugador and jugador.escudo_almas > 0.0:
				label_vida.text = "%d / %d HP (+%d 🛡️)" % [int(vida), int(max_vida), int(jugador.escudo_almas)]
			else:
				label_vida.text = "%d / %d HP" % [int(vida), int(max_vida)]

	if bar_xp != null:
		bar_xp.max_value = max(xp_sig, 1)
		bar_xp.value = xp
		if label_xp != null:
			label_xp.text = "XP: %d / %d" % [xp, xp_sig]

	if label_oro != null:
		label_oro.text = "%d" % oro

	if label_bajas != null:
		label_bajas.text = "%d Bajas" % bajas

func _on_economia_actualizada(oro_cnt: int, _clics_disp: int, _clics_tot: int):
	if label_oro != null:
		label_oro.text = "%d" % oro_cnt

func _actualizar_corazones_dinamicos(vidas_restantes: int, vidas_maximas: int):
	if label_vidas != null:
		label_vidas.text = "Vidas: %d/%d" % [vidas_restantes, vidas_maximas]

	if hbox_corazones == null:
		return

	var hijos = hbox_corazones.get_children()
	while hijos.size() < vidas_maximas:
		var extra = TextureRect.new()
		extra.custom_minimum_size = Vector2(24, 24)
		extra.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		extra.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox_corazones.add_child(extra)
		hijos.append(extra)

	for i in range(hijos.size()):
		var c = hijos[i] as TextureRect
		if c == null:
			continue
		if i < vidas_maximas:
			c.visible = true
			c.texture = TEX_CORAZON_LLENO if i < vidas_restantes else TEX_CORAZON_VACIO
		else:
			c.visible = false

func _actualizar_avatar_clase(nombre_clase: String):
	if _clase_actual_avatar == nombre_clase or subviewport_avatar == null:
		return
	_clase_actual_avatar = nombre_clase

	if MALLAS_AVATAR.has(nombre_clase):
		var escena_malla: PackedScene = MALLAS_AVATAR[nombre_clase]
		if escena_malla != null:
			if is_instance_valid(modelo_avatar_nodo):
				modelo_avatar_nodo.queue_free()
			var nuevo_modelo = escena_malla.instantiate()
			nuevo_modelo.name = "ModeloAvatar"
			nuevo_modelo.rotation_degrees.y = 165.0
			subviewport_avatar.add_child(nuevo_modelo)
			modelo_avatar_nodo = nuevo_modelo

# ==============================================================================
# SELECTOR DE 3 CARTAS DE BENDICIONES ROGUELIKE Y SINERGIAS DUALES
# ==============================================================================

func _on_nivel_subido(nuevo_nivel: int):
	mostrar_selector_bendiciones(nuevo_nivel)

func mostrar_selector_bendiciones(_nivel: int = 1):
	if modal_mejora == null:
		return
	if modal_mejora.visible:
		_niveles_pendientes += 1
		return

	var actuales: Dictionary = {}
	if jugador != null and "bendiciones_run" in jugador:
		actuales = jugador.bendiciones_run

	_opciones_bendicion_actuales = CatalogoBendiciones.obtener_3_opciones(actuales)
	var botones = [btn_opc1, btn_opc2, btn_opc3]
	for i in range(botones.size()):
		var btn = botones[i]
		if btn == null:
			continue
		if i < _opciones_bendicion_actuales.size():
			var b: Dictionary = _opciones_bendicion_actuales[i]
			var niv_act = int(b.get("nivel_actual", 0))
			var niv_max = int(b.get("max_nivel", 5))
			var icono = str(b.get("icono", "✨"))
			var nombre = str(b.get("nombre", "Bendición"))
			var desc = str(b.get("desc", ""))
			btn.text = "%s %s (Nv.%d/%d)\n%s" % [icono, nombre, niv_act + 1, niv_max, desc]
			btn.visible = true
		else:
			btn.visible = false

	modal_mejora.visible = true
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = true

func _seleccionar_carta_bendicion(indice: int):
	if modal_mejora != null:
		modal_mejora.visible = false

	if indice >= 0 and indice < _opciones_bendicion_actuales.size():
		var elegida: Dictionary = _opciones_bendicion_actuales[indice]
		var id_bendicion = str(elegida.get("id", ""))
		if jugador != null and jugador.has_method("aplicar_bendicion_roguelike") and id_bendicion != "":
			jugador.aplicar_bendicion_roguelike(id_bendicion)
		elif jugador != null and jugador.has_method("aplicar_mejora"):
			jugador.aplicar_mejora("dano")
	else:
		var tipos = ["dano", "velocidad", "vida"]
		if jugador != null and jugador.has_method("aplicar_mejora"):
			jugador.aplicar_mejora(tipos[clampi(indice, 0, 2)])

	if _niveles_pendientes > 0:
		_niveles_pendientes -= 1
		mostrar_selector_bendiciones()
	else:
		if is_inside_tree() and get_tree() != null:
			var pantalla_fin = get_tree().get_first_node_in_group("pantalla_fin_partida")
			if pantalla_fin == null or not pantalla_fin.visible:
				get_tree().paused = false

func _elegir_mejora(tipo: String):
	if modal_mejora != null:
		modal_mejora.visible = false
	if jugador != null and jugador.has_method("aplicar_mejora"):
		jugador.aplicar_mejora(tipo)
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = false

# ==============================================================================
# SISTEMA MULTI-JEFE (CONTEO Y BARRA PRIORITARIA)
# ==============================================================================

func mostrar_barra_jefe(nombre: String, max_hp: float, hp_actual: float):
	if panel_jefe != null:
		panel_jefe.visible = true
		if label_nombre_jefe != null:
			label_nombre_jefe.text = nombre
		if bar_vida_jefe != null:
			bar_vida_jefe.max_value = maxf(max_hp, 1.0)
			bar_vida_jefe.value = hp_actual
		if label_vida_jefe != null:
			label_vida_jefe.text = "%d / %d HP" % [int(hp_actual), int(max_hp)]

func actualizar_barra_jefe(hp_actual: float, texto_nombre: String = ""):
	if panel_jefe != null and bar_vida_jefe != null:
		panel_jefe.visible = true
		bar_vida_jefe.value = hp_actual
		if label_vida_jefe != null:
			label_vida_jefe.text = "%d / %d HP" % [int(hp_actual), int(bar_vida_jefe.max_value)]
		if texto_nombre != "" and label_nombre_jefe != null:
			label_nombre_jefe.text = texto_nombre

func ocultar_barra_jefe():
	# Antes de ocultar, verificar si queda algún otro jefe vivo en la arena
	var jefes_vivos = _obtener_jefes_vivos()
	if jefes_vivos.size() > 0:
		var otro = jefes_vivos[0]
		var max_hp = float(otro.vida_maxima) if "vida_maxima" in otro else 500.0
		var hp = float(otro.vida) if "vida" in otro else max_hp
		mostrar_barra_jefe("⚔️ " + str(otro.name), max_hp, hp)
		return
	if panel_jefe != null:
		panel_jefe.visible = false

func _obtener_jefes_vivos() -> Array:
	var vivos: Array = []
	for j in get_tree().get_nodes_in_group("jefes"):
		if is_instance_valid(j) and (not ("muerto" in j) or not j.muerto) and ("vida" in j and j.vida > 0.0):
			vivos.append(j)
	return vivos

func _sincronizar_jefe_prioritario():
	if panel_jefe == null:
		return
	var vivos = _obtener_jefes_vivos()
	if vivos.is_empty():
		if panel_jefe.visible:
			panel_jefe.visible = false
	elif not panel_jefe.visible:
		var j = vivos[0]
		var max_hp = float(j.vida_maxima) if "vida_maxima" in j else 500.0
		var hp = float(j.vida) if "vida" in j else max_hp
		mostrar_barra_jefe("⚔️ " + str(j.name), max_hp, hp)

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_U or event.keycode == KEY_B:
			_toggle_arbol_poe()
			get_viewport().set_input_as_handled()

func _toggle_arbol_poe():
	if arbol_poe_instancia == null or not is_instance_valid(arbol_poe_instancia):
		arbol_poe_instancia = ArbolMejorasPoEEscena.instantiate()
		var root = get_tree().root if get_tree() != null else get_parent()
		if root != null:
			root.add_child(arbol_poe_instancia)
		else:
			add_child(arbol_poe_instancia)
	arbol_poe_instancia.toggle()

var _panel_test_jefes: VBoxContainer = null

func _crear_boton_test_parca():
	var cont = VBoxContainer.new()
	cont.name = "ContenedorTestJefes"
	cont.anchor_left = 1.0
	cont.anchor_top = 1.0
	cont.anchor_right = 1.0
	cont.anchor_bottom = 1.0
	cont.offset_left = -230.0
	cont.offset_top = -240.0
	cont.offset_right = -15.0
	cont.offset_bottom = -15.0
	cont.alignment = BoxContainer.ALIGNMENT_END

	_panel_test_jefes = VBoxContainer.new()
	_panel_test_jefes.name = "ListaJefesTest"
	_panel_test_jefes.visible = false

	var jefes = [
		{"id": "centurion", "label": "⚔️ W3: Centurión (420 HP)", "color": Color(0.8, 0.45, 0.15)},
		{"id": "gladiador", "label": "🛡️ W6: Gladiador (950 HP)", "color": Color(0.9, 0.55, 0.2)},
		{"id": "maestra", "label": "🏹 W9: Maestra (1800 HP)", "color": Color(0.85, 0.2, 0.6)},
		{"id": "coloso", "label": "🌋 W12: Coloso (3200 HP)", "color": Color(0.95, 0.35, 0.1)}
	]

	for j in jefes:
		var b_jefe = Button.new()
		b_jefe.text = j["label"]
		_aplicar_estilo_boton(b_jefe, j["color"])
		var j_id = j["id"]
		b_jefe.pressed.connect(func(): _invocar_jefe_test(j_id))
		_panel_test_jefes.add_child(b_jefe)

	cont.add_child(_panel_test_jefes)

	var hbox_botones = HBoxContainer.new()
	hbox_botones.alignment = BoxContainer.ALIGNMENT_END

	var btn_toggle = Button.new()
	btn_toggle.text = "👑 JEFES (▲)"
	_aplicar_estilo_boton(btn_toggle, Color(0.7, 0.5, 0.2))
	btn_toggle.pressed.connect(func():
		_panel_test_jefes.visible = !_panel_test_jefes.visible
		btn_toggle.text = "👑 JEFES (▼)" if _panel_test_jefes.visible else "👑 JEFES (▲)"
	)
	hbox_botones.add_child(btn_toggle)

	var btn_parca = Button.new()
	btn_parca.name = "BtnTestParca"
	btn_parca.text = "💀 PROBAR PARCA ROJA"
	btn_parca.tooltip_text = "Invoca al Jefe Final (La Parca Roja) y otorga build de supervivencia"
	_aplicar_estilo_boton(btn_parca, Color(0.95, 0.2, 0.2))
	btn_parca.pressed.connect(func(): _invocar_jefe_test("parca"))
	hbox_botones.add_child(btn_parca)

	cont.add_child(hbox_botones)
	$Control.add_child(cont)

func _aplicar_estilo_boton(btn: Button, color_acento: Color):
	var s_normal = StyleBoxFlat.new()
	s_normal.bg_color = Color(0.12, 0.05, 0.07, 0.92)
	s_normal.border_color = color_acento
	s_normal.border_width_left = 1
	s_normal.border_width_top = 1
	s_normal.border_width_right = 1
	s_normal.border_width_bottom = 1
	s_normal.corner_radius_top_left = 5
	s_normal.corner_radius_top_right = 5
	s_normal.corner_radius_bottom_right = 5
	s_normal.corner_radius_bottom_left = 5

	var s_hover = s_normal.duplicate()
	s_hover.bg_color = Color(0.25, 0.08, 0.12, 0.95)
	s_hover.border_color = color_acento.lightened(0.25)

	btn.add_theme_stylebox_override("normal", s_normal)
	btn.add_theme_stylebox_override("hover", s_hover)
	btn.add_theme_stylebox_override("pressed", s_hover)
	btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.92))
	btn.add_theme_font_size_override("font_size", 11)

func _invocar_jefe_test(tipo: String):
	print(">>> [HUD] Invocando Jefe de Prueba: ", tipo, " <<<")

	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")

	if jugador != null and jugador.has_method("equipar_build_test_parca"):
		jugador.equipar_build_test_parca()

	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for e in enemigos:
		if is_instance_valid(e) and not e.is_in_group("jefes"):
			e.queue_free()

	var escena_path = ""
	match tipo:
		"centurion":
			escena_path = "res://centurion_corrupto.tscn"
		"gladiador":
			escena_path = "res://mini_jefe.tscn"
		"maestra":
			escena_path = "res://maestra_sanguinaria.tscn"
		"coloso":
			escena_path = "res://coloso_bronce.tscn"
		"parca":
			escena_path = "res://parca_roja.tscn"

	if escena_path != "":
		var escena = load(escena_path)
		if escena != null:
			var j = escena.instantiate()
			get_parent().add_child(j)
			j.global_position = Vector3(0, 0, -14)
