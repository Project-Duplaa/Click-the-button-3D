extends CanvasLayer

# ClickHUD - Dark-Fantasy Colosseum HUD (Hades II / Path of Exile II inspired)
# Arquitectura sin solapamientos (1152x648 a 1920x1080), retrato 3D circular con rim-light,
# barra HP con delayed-damage trail y Escudo de Almas por shader, medidor Fiebre/Overdrive (x1..x5),
# dock contextual (Presagio, Reliquias, Pacto de Marte, [U] Ascensión) y Cartas Tarot de Bendición.

const MALLAS_AVATAR := {
	"Novato": preload("res://personaje/character-male-a.glb"),
	"Guerrero": preload("res://personaje/character-male-d.glb"),
	"Cazador": preload("res://personaje/character-female-e.glb"),
	"Mago": preload("res://personaje/character-female-b.glb"),
	"Paladín Solar": preload("res://personaje/character-male-d.glb"),
	"Francotirador Astral": preload("res://personaje/character-female-e.glb"),
	"Archimago del Vacío": preload("res://personaje/character-female-b.glb"),
}

const WEAPON_KEYS := {
	"Novato": "Novato",
	"Guerrero": "Guerrero",
	"Cazador": "Cazador",
	"Mago": "Mago",
	"Paladín Solar": "Guerrero",
	"Francotirador Astral": "Cazador",
	"Archimago del Vacío": "Mago",
}

const CLASS_ACCENTS := {
	"Novato": Color(0.88, 0.74, 0.38),
	"Guerrero": Color(0.95, 0.25, 0.22),
	"Cazador": Color(0.20, 0.85, 0.50),
	"Mago": Color(0.55, 0.35, 1.00),
	"Paladín Solar": Color(1.00, 0.82, 0.20),
	"Francotirador Astral": Color(0.22, 0.78, 1.00),
	"Archimago del Vacío": Color(0.95, 0.20, 0.70),
}

const TEX_CORAZON_LLENO := preload("res://ui_assets/hud_gem_heart.png")
const TEX_CORAZON_VACIO := preload("res://ui_assets/hud_gem_heart_empty.png")
const TEX_CORNER_GOTHIC := preload("res://ui_assets/hud_corner_gothic.png")
const TEX_ICO_CLASS := preload("res://ui_assets/icon_class_hades.svg")
const TEX_ICO_CLICKS := preload("res://ui_assets/icon_clicks_hades.svg")
const TEX_ICO_FEVER := preload("res://ui_assets/icon_fever_hades.svg")
const TEX_ICO_GOLD := preload("res://ui_assets/icon_gold_hades.svg")
const TEX_ICO_KILLS := preload("res://ui_assets/icon_kills_hades.svg")
const TEX_ICO_LUCK := preload("res://ui_assets/icon_luck_hades.svg")
const TEX_ICO_PACTO := preload("res://ui_assets/icon_pacto_hades.svg")
const TEX_ICO_SHIELD := preload("res://ui_assets/icon_shield_hades.svg")
const TEX_ICO_SKULL := preload("res://ui_assets/icon_skull_hades.svg")
const TEX_ICO_TIME := preload("res://ui_assets/icon_time_hades.svg")
const TEX_ICO_VAULT := preload("res://ui_assets/icon_vault_hades.svg")
const TEX_ICO_VICTORY := preload("res://ui_assets/icon_victory_hades.svg")
const TEX_ICO_BOLT := preload("res://ui_assets/icon_bolt_hades.svg")
const TEX_ICO_DAGGERS := preload("res://ui_assets/icon_daggers_hades.svg")
const TEX_ICO_FROST := preload("res://ui_assets/icon_frost_hades.svg")
const TEX_ICO_BLOOD := preload("res://ui_assets/icon_blood_hades.svg")
const TEX_ICO_PRISM := preload("res://ui_assets/icon_prism_hades.svg")
const TEX_ICO_SYNERGY := preload("res://ui_assets/icon_synergy_hades.svg")

const RESOLUCIONES_DISPONIBLES := [
	{"label": "1152 × 648 (Base 16:9)", "size": Vector2i(1152, 648)},
	{"label": "1280 × 720 (HD 720p)", "size": Vector2i(1280, 720)},
	{"label": "1366 × 768 (WXGA)", "size": Vector2i(1366, 768)},
	{"label": "1600 × 900 (HD+ 900p)", "size": Vector2i(1600, 900)},
	{"label": "1920 × 1080 (Full HD)", "size": Vector2i(1920, 1080)},
	{"label": "2560 × 1440 (QHD 2K)", "size": Vector2i(2560, 1440)},
]

const SELLO_GRACIA_INICIAL_MS: int = 850
const SELLO_REBOTE_SPAM_MS: int = 380
const SELLO_MAX_TOTAL_MS: int = 2200

const ArbolMejorasPoEEscena := preload("res://arbol_mejoras_poe.tscn")
const CatalogoBendiciones := preload("res://catalogo_bendiciones.gd")
const AnimadorEntidad := preload("res://animador_entidad.gd")

# --- Referencias Top Bar ---
@onready var overlay_colapso: ColorRect = $Control/OverlayColapso
@onready var barra_superior: Panel = $Control/BarraSuperior

@onready var avatar_frame: Panel = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/AvatarSocket/AvatarFrame
@onready var subviewport_container: SubViewportContainer = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/AvatarSocket/AvatarFrame/SubViewportContainer
@onready var subviewport_avatar: SubViewport = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/AvatarSocket/AvatarFrame/SubViewportContainer/SubViewport
@onready var modelo_avatar_nodo: Node3D = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/AvatarSocket/AvatarFrame/SubViewportContainer/SubViewport/ModeloAvatar
@onready var camara_avatar: Camera3D = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/AvatarSocket/AvatarFrame/SubViewportContainer/SubViewport/CamaraAvatar
@onready var luz_contorno: DirectionalLight3D = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/AvatarSocket/AvatarFrame/SubViewportContainer/SubViewport/LuzContorno
@onready var badge_nivel: PanelContainer = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/AvatarSocket/BadgeNivel
@onready var label_nivel: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/AvatarSocket/BadgeNivel/LabelNivel

@onready var icono_clase: TextureRect = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HeaderHeroe/IconoClase
@onready var label_clase: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HeaderHeroe/LabelClase
@onready var label_vidas: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HeaderHeroe/ContenedorVidas/LabelVidas
@onready var hbox_corazones: HBoxContainer = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HeaderHeroe/ContenedorVidas/HBoxCorazones
@onready var corazon1: TextureRect = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HeaderHeroe/ContenedorVidas/HBoxCorazones/Corazon1
@onready var corazon2: TextureRect = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HeaderHeroe/ContenedorVidas/HBoxCorazones/Corazon2
@onready var corazon3: TextureRect = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HeaderHeroe/ContenedorVidas/HBoxCorazones/Corazon3

@onready var bar_vida: ProgressBar = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/BarVida
@onready var bar_vida_shader: ColorRect = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/BarVida/BarVidaShader
@onready var label_vida: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/BarVida/HBoxVidaTexto/LabelVida
@onready var icono_escudo_hp: TextureRect = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/BarVida/HBoxVidaTexto/IconoEscudoHP
@onready var label_escudo_hp: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/BarVida/HBoxVidaTexto/LabelEscudoHP
@onready var bar_xp: ProgressBar = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HBoxXPHeroe/BarXP
@onready var label_xp: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HBoxXPHeroe/LabelXP

@onready var icono_oleada: TextureRect = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorCentro/HBoxWaveHeader/IconoOleada
@onready var label_oleada: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorCentro/HBoxWaveHeader/LabelOleada
@onready var icono_tiempo: TextureRect = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorCentro/HBoxWaveHeader/IconoTiempo
@onready var label_tiempo: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorCentro/HBoxWaveHeader/LabelTiempo
@onready var icono_nucleo: TextureRect = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorCentro/HBoxNucleoLine/IconoNucleo
@onready var label_nucleo: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorCentro/HBoxNucleoLine/LabelNucleo
@onready var icono_fiebre: TextureRect = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorCentro/HBoxFiebreBar/IconoFiebre
@onready var bar_fiebre: ProgressBar = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorCentro/HBoxFiebreBar/BarFiebre
@onready var badge_fiebre: PanelContainer = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorCentro/HBoxFiebreBar/BadgeFiebre
@onready var label_fiebre: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorCentro/HBoxFiebreBar/BadgeFiebre/LabelFiebre

@onready var label_oro: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorEconomia/HBoxEconomiaTop/HBoxOro/LabelOro
@onready var label_denarios: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorEconomia/HBoxEconomiaTop/HBoxDenarios/LabelDenarios
@onready var label_bajas: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorEconomia/HBoxEconomiaBot/HBoxBajas/LabelBajas
@onready var label_suerte: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorEconomia/HBoxEconomiaBot/HBoxSuerte/LabelSuerte

# --- Referencias Status Rail ---
@onready var chip_presagio: PanelContainer = $Control/StatusRail/HBoxStatusRail/ChipPresagio
@onready var icono_presagio: TextureRect = $Control/StatusRail/HBoxStatusRail/ChipPresagio/HBox/IconoPresagio
@onready var label_presagio: Label = $Control/StatusRail/HBoxStatusRail/ChipPresagio/HBox/LabelPresagio
@onready var chip_reliquias: PanelContainer = $Control/StatusRail/HBoxStatusRail/ChipReliquias
@onready var label_reliquias: Label = $Control/StatusRail/HBoxStatusRail/ChipReliquias/HBox/LabelReliquias
@onready var chip_pacto_marte: PanelContainer = $Control/StatusRail/HBoxStatusRail/ChipPactoMarte
@onready var label_pacto: Label = $Control/StatusRail/HBoxStatusRail/ChipPactoMarte/VBox/HBox/LabelPacto
@onready var bar_pacto: ProgressBar = $Control/StatusRail/HBoxStatusRail/ChipPactoMarte/VBox/BarPacto
@onready var btn_arbol_poe: Button = $Control/StatusRail/HBoxStatusRail/BtnArbolPoE
@onready var label_arbol: Label = $Control/StatusRail/HBoxStatusRail/BtnArbolPoE/HBoxArbol/LabelArbol

# --- Modales & Jefe ---
@onready var panel_jefe: Panel = $Control/PanelJefe
@onready var label_nombre_jefe: Label = $Control/PanelJefe/VBoxJefe/HBoxHeaderJefe/LabelNombreJefe
@onready var bar_vida_jefe: ProgressBar = $Control/PanelJefe/VBoxJefe/BarVidaJefe
@onready var bar_jefe_shader: ColorRect = $Control/PanelJefe/VBoxJefe/BarVidaJefe/BarJefeShader
@onready var label_vida_jefe: Label = $Control/PanelJefe/VBoxJefe/BarVidaJefe/LabelVidaJefe

@onready var modal_dimmer: ColorRect = $Control/ModalDimmer
@onready var modal_mejora: Panel = $Control/ModalMejora
@onready var btn_opc1: Button = $Control/ModalMejora/VBox/HBox/BtnOpc1
@onready var btn_opc2: Button = $Control/ModalMejora/VBox/HBox/BtnOpc2
@onready var btn_opc3: Button = $Control/ModalMejora/VBox/HBox/BtnOpc3

# --- Estado Público (Preservado 100% para callers externos) ---
var jugador: Node = null
var tiempo_total: float = 0.0
var oleada: int = 1
var clicks_boton: int = 0
var vel_boton: float = 2.8
var est_actual: float = 14.0
var est_max: float = 14.0
var est_en_colapso: bool = false
var arbol_poe_instancia: CanvasLayer = null

# --- Estado Interno de UI & Animación ---
var _clase_actual_avatar: String = ""
var _opciones_bendicion_actuales: Array = []
var _niveles_pendientes: int = 0
var _ultimo_nivel_procesado: int = 1

var _hp_ratio_actual: float = 1.0
var _hp_trail_ratio: float = 1.0
var _hp_trail_hold: float = 0.0
var _shield_ratio_actual: float = 0.0
var _hp_previa: float = -1.0

var _jefe_hp_ratio: float = 1.0
var _jefe_trail_ratio: float = 1.0
var _jefe_trail_hold: float = 0.0
var _jefe_hp_previa: float = -1.0
var _habia_jefe_en_grupo: bool = false

var _fever_valor_visual: float = 0.0
var _fever_tier_prev: int = -1
var _overdrive_glow: float = 0.0
var _pacto_duracion: float = 60.0
var _sb_barra_superior_base: StyleBoxFlat = null
var _sb_fiebre_fill: StyleBoxFlat = null
var _sb_badge_fiebre: StyleBoxFlat = null
var _sb_btn_arbol_normal: StyleBoxFlat = null

var _ultimo_txt_tiempo: String = ""
var _ultimo_txt_oleada: String = ""
var _ultimo_txt_nucleo: String = ""
var _panel_test_jefes: VBoxContainer = null
var _panel_resoluciones: VBoxContainer = null
var _btn_resolucion_ref: Button = null
var _avatar_reloj_idle: float = 0.0
var _avatar_reloj_redraw: float = 0.06
var _reloj_jefe_sync: float = 0.0
var _partida_ref: Node = null
var _boton_ref: Node = null
var _ultimo_juicio_ui: int = -1
var _ultimo_col_nucleo: Color = Color(-1.0, -1.0, -1.0)
var _ultimo_ico_nucleo: Texture2D = null
var _ultimo_col_fiebre: Color = Color(-1.0, -1.0, -1.0)
var _ultimo_border_barra: Color = Color(-1.0, -1.0, -1.0)
var _ultimo_overdrive_shader: float = -1.0
var _ultimo_hash_reliquias: int = -999999
var _ultimo_escudo_txt: String = ""
var _ultimo_escudo_vis: int = -1
var _ultimo_ready_gl: int = -1

var _modal_apertura_msec: int = 0
var _modal_bloqueado_hasta_msec: int = 0
var _modal_duracion_sello_actual_ms: int = SELLO_GRACIA_INICIAL_MS
var _modal_sello_desbloqueado_visual: bool = false
var _modal_clic_bloqueado_flash_hasta_msec: int = 0
var _banner_sello_tarot: PanelContainer = null
var _sello_fill_rect: ColorRect = null
var _lbl_sello_tarot: Label = null
var _sb_banner_sello: StyleBoxFlat = null


func _ready() -> void:
	add_to_group("hud")
	process_mode = Node.PROCESS_MODE_ALWAYS

	if modal_mejora != null:
		modal_mejora.process_mode = Node.PROCESS_MODE_ALWAYS
		modal_mejora.visible = false
	if modal_dimmer != null:
		modal_dimmer.process_mode = Node.PROCESS_MODE_ALWAYS
		modal_dimmer.visible = false
	if panel_jefe != null:
		panel_jefe.visible = false
	if overlay_colapso != null:
		overlay_colapso.color = Color(0.85, 0.05, 0.10, 0.0)

	_inicializar_estilos_dinamicos()
	_calibrar_avatar()
	_configurar_tarot_hover()
	_conectar_escalado_resolucion()

	if btn_arbol_poe != null:
		btn_arbol_poe.pressed.connect(_toggle_arbol_poe)

	if btn_opc1 != null:
		btn_opc1.pressed.connect(func(): _seleccionar_carta_bendicion(0))
	if btn_opc2 != null:
		btn_opc2.pressed.connect(func(): _seleccionar_carta_bendicion(1))
	if btn_opc3 != null:
		btn_opc3.pressed.connect(func(): _seleccionar_carta_bendicion(2))

	_conectar_jugador()
	_conectar_fortuna()
	_conectar_boton_movil()
	call_deferred("_conectar_boton_movil")
	_crear_boton_test_parca()
	call_deferred("_ajustar_layout_resolucion")


func _inicializar_estilos_dinamicos() -> void:
	if barra_superior != null:
		var sb := barra_superior.get_theme_stylebox("panel")
		if sb is StyleBoxFlat:
			_sb_barra_superior_base = sb.duplicate() as StyleBoxFlat
			barra_superior.add_theme_stylebox_override("panel", _sb_barra_superior_base)

	if bar_fiebre != null:
		var sf := bar_fiebre.get_theme_stylebox("fill")
		if sf is StyleBoxFlat:
			_sb_fiebre_fill = sf.duplicate() as StyleBoxFlat
			bar_fiebre.add_theme_stylebox_override("fill", _sb_fiebre_fill)

	if badge_fiebre != null:
		var sbf := badge_fiebre.get_theme_stylebox("panel")
		if sbf is StyleBoxFlat:
			_sb_badge_fiebre = sbf.duplicate() as StyleBoxFlat
			badge_fiebre.add_theme_stylebox_override("panel", _sb_badge_fiebre)

	if btn_arbol_poe != null:
		var sba := btn_arbol_poe.get_theme_stylebox("normal")
		if sba is StyleBoxFlat:
			_sb_btn_arbol_normal = sba.duplicate() as StyleBoxFlat
			btn_arbol_poe.add_theme_stylebox_override("normal", _sb_btn_arbol_normal)


func _conectar_jugador() -> void:
	jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return

	if jugador.has_signal("stats_actualizadas") and not jugador.stats_actualizadas.is_connected(_on_stats_actualizadas):
		jugador.stats_actualizadas.connect(_on_stats_actualizadas)
	if jugador.has_signal("nivel_subido") and not jugador.nivel_subido.is_connected(_on_nivel_subido):
		jugador.nivel_subido.connect(_on_nivel_subido)
	if jugador.has_signal("economia_actualizada") and not jugador.economia_actualizada.is_connected(_on_economia_actualizada):
		jugador.economia_actualizada.connect(_on_economia_actualizada)
	if jugador.has_signal("denarios_actualizados") and not jugador.denarios_actualizados.is_connected(_on_denarios_actualizados):
		jugador.denarios_actualizados.connect(_on_denarios_actualizados)
	if jugador.has_signal("suerte_cambiada") and not jugador.suerte_cambiada.is_connected(_on_suerte_cambiada):
		jugador.suerte_cambiada.connect(_on_suerte_cambiada)
	if jugador.has_signal("fiebre_actualizada") and not jugador.fiebre_actualizada.is_connected(_on_fiebre_actualizada):
		jugador.fiebre_actualizada.connect(_on_fiebre_actualizada)
	if jugador.has_signal("bendicion_adquirida") and not jugador.bendicion_adquirida.is_connected(_on_bendicion_adquirida):
		jugador.bendicion_adquirida.connect(_on_bendicion_adquirida)

	_on_stats_actualizadas(jugador.vida, jugador.vida_maxima, jugador.xp, jugador.xp_siguiente_nivel, jugador.nivel, jugador.oro, jugador.bajas)
	if "denarios" in jugador:
		_on_denarios_actualizados(int(jugador.denarios))
	if "clics_disponibles" in jugador:
		_on_economia_actualizada(int(jugador.oro), int(jugador.clics_disponibles), int(jugador.clics_totales))


func _conectar_fortuna() -> void:
	if FortunaManager == null:
		return
	if FortunaManager.has_signal("presagio_sorteado") and not FortunaManager.presagio_sorteado.is_connected(_on_presagio_sorteado):
		FortunaManager.presagio_sorteado.connect(_on_presagio_sorteado)
	if FortunaManager.has_signal("suerte_cambiada") and not FortunaManager.suerte_cambiada.is_connected(_on_suerte_cambiada):
		FortunaManager.suerte_cambiada.connect(_on_suerte_cambiada)

	if "presagio_nombre" in FortunaManager and String(FortunaManager.presagio_nombre) != "":
		_actualizar_chip_presagio(String(FortunaManager.presagio_nombre), String(FortunaManager.presagio_desc), Color(0.86, 0.72, 0.36))
	if FortunaManager.has_method("obtener_suerte_efectiva"):
		_on_suerte_cambiada(FortunaManager.obtener_suerte_efectiva())


func _calibrar_avatar() -> void:
	if camara_avatar != null:
		camara_avatar.fov = 30.0
		camara_avatar.look_at_from_position(Vector3(0.04, 0.52, 1.10), Vector3(0.0, 0.48, 0.0), Vector3.UP)
	if modelo_avatar_nodo != null:
		_clase_actual_avatar = "Novato"
		modelo_avatar_nodo.rotation_degrees.y = 20.0
		_preparar_modelo_retrato(modelo_avatar_nodo, "Novato")


func _preparar_modelo_retrato(modelo: Node3D, nombre_clase: String) -> void:
	if modelo == null:
		return
	var weapon_key: String = String(WEAPON_KEYS.get(nombre_clase, "Novato"))
	AnimadorEntidad.equipar_armas_en_esqueleto(modelo, weapon_key, false)
	var ap := AnimadorEntidad.buscar_animation_player(modelo)
	if ap != null:
		var clip := "idle" if ap.has_animation("idle") else ""
		if clip == "" and ap.has_animation("static"):
			clip = "static"
		if clip != "":
			var anim_res := ap.get_animation(clip)
			if anim_res != null:
				anim_res.loop_mode = Animation.LOOP_LINEAR
			ap.play(clip)
			ap.speed_scale = 0.85

	var accent: Color = CLASS_ACCENTS.get(nombre_clase, Color(0.88, 0.74, 0.38))
	if luz_contorno != null:
		luz_contorno.light_color = accent
		luz_contorno.light_energy = 2.6 if nombre_clase != "Novato" else 2.2
	if subviewport_container != null and subviewport_container.material is ShaderMaterial:
		var mat := subviewport_container.material as ShaderMaterial
		mat.set_shader_parameter("class_aura", accent)
	if icono_clase != null:
		icono_clase.modulate = accent


func _conectar_boton_movil() -> void:
	var b = get_tree().get_first_node_in_group("boton_movil")
	if b != null:
		if not b.click_presionado.is_connected(_on_click_boton_presionado):
			b.click_presionado.connect(_on_click_boton_presionado)
		if b.has_signal("estabilidad_actualizada") and not b.estabilidad_actualizada.is_connected(_on_estabilidad_boton_actualizada):
			b.estabilidad_actualizada.connect(_on_estabilidad_boton_actualizada)
		if "rapidez_movimiento" in b:
			vel_boton = b.rapidez_movimiento
		if "tiempo_estabilidad_actual" in b:
			est_actual = b.tiempo_estabilidad_actual
			est_max = b.tiempo_estabilidad_max
			est_en_colapso = b.en_colapso


func _on_estabilidad_boton_actualizada(actual: float, maximo: float, en_colapso: bool) -> void:
	est_actual = actual
	est_max = maximo
	est_en_colapso = en_colapso


func _on_click_boton_presionado(total: int) -> void:
	clicks_boton = total
	var b = get_tree().get_first_node_in_group("boton_movil")
	if b != null and "rapidez_movimiento" in b:
		vel_boton = b.rapidez_movimiento


func _process(delta: float) -> void:
	if not get_tree().paused and clicks_boton > 0:
		tiempo_total += delta

	if modal_mejora != null and modal_mejora.visible:
		_actualizar_visual_sello_tarot()

	_actualizar_timer_y_oleada()
	_actualizar_telemetria_nucleo_y_fiebre(delta)
	_actualizar_overlays_shader(delta)
	_actualizar_chips_estado(delta)
	_animar_retrato_sutil(delta)
	_reloj_jefe_sync += delta
	if _reloj_jefe_sync >= 0.1:
		_reloj_jefe_sync = 0.0
		_sincronizar_jefe_prioritario()


func _actualizar_timer_y_oleada() -> void:
	var minutos := int(tiempo_total) / 60
	var segundos := int(tiempo_total) % 60
	if _partida_ref == null or not is_instance_valid(_partida_ref):
		_partida_ref = get_tree().get_first_node_in_group("partida")
	var juicio := _partida_ref != null and "modo_juicio_final" in _partida_ref and bool(_partida_ref.modo_juicio_final)

	if label_tiempo != null:
		var txt_t := ("JUICIO %02d:%02d" % [minutos, segundos]) if juicio else ("%02d:%02d" % [minutos, segundos])
		if txt_t != _ultimo_txt_tiempo:
			_ultimo_txt_tiempo = txt_t
			label_tiempo.text = txt_t
		if juicio:
			_ultimo_juicio_ui = 1
			var flicker := 0.72 + 0.28 * sin(Time.get_ticks_msec() * 0.012)
			label_tiempo.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, flicker))
			if icono_tiempo != null:
				if icono_tiempo.texture != TEX_ICO_SKULL:
					icono_tiempo.texture = TEX_ICO_SKULL
				icono_tiempo.modulate = Color(1.0, 0.30, 0.35, flicker)
		elif _ultimo_juicio_ui != 0:
			_ultimo_juicio_ui = 0
			label_tiempo.add_theme_color_override("font_color", Color(0.89, 0.91, 0.96))
			if icono_tiempo != null:
				icono_tiempo.texture = TEX_ICO_TIME
				icono_tiempo.modulate = Color(1.0, 1.0, 1.0)

	if label_oleada != null:
		var txt_o := "EN ESPERA" if clicks_boton == 0 else ("OLEADA %d" % oleada)
		if txt_o != _ultimo_txt_oleada:
			_ultimo_txt_oleada = txt_o
			label_oleada.text = txt_o
			if icono_oleada != null:
				icono_oleada.modulate = Color(0.85, 0.72, 0.42, 0.7) if clicks_boton == 0 else Color(1.0, 0.89, 0.60, 1.0)


func _actualizar_telemetria_nucleo_y_fiebre(delta: float) -> void:
	var fever_val: float = 0.0
	var fever_mult: int = 1
	var en_overdrive: bool = false
	if jugador != null and is_instance_valid(jugador):
		if "medidor_fiebre" in jugador:
			fever_val = float(jugador.medidor_fiebre)
		if "multiplicador_fiebre_actual" in jugador:
			fever_mult = int(jugador.multiplicador_fiebre_actual)
		elif "multiplicador_fiebre" in jugador:
			fever_mult = int(jugador.multiplicador_fiebre)
		if "en_overdrive" in jugador:
			en_overdrive = bool(jugador.en_overdrive)

	if label_nucleo != null:
		if _boton_ref == null or not is_instance_valid(_boton_ref):
			_boton_ref = get_tree().get_first_node_in_group("boton_movil")
		var boton = _boton_ref
		var nuevo_txt := ""
		var nuevo_col := Color(0.32, 0.90, 0.98)
		var nuevo_ico: Texture2D = TEX_ICO_CLICKS

		if clicks_boton == 0:
			var pulso := 0.82 + sin(Time.get_ticks_msec() * 0.0045) * 0.18
			nuevo_txt = "Pulsa el Núcleo para iniciar"
			nuevo_col = Color(0.28, 0.94, 1.0, pulso)
		elif boton != null and "estado_actual" in boton:
			match int(boton.estado_actual):
				1: # ENCADENADO
					var cad_act := int(boton.cadenas_activas) if "cadenas_activas" in boton else 3
					nuevo_txt = "NÚCLEO ENCADENADO  ·  %d palancas" % cad_act
					nuevo_col = Color(1.0, 0.78, 0.25) if (int(Time.get_ticks_msec() * 0.004) % 2 == 0) else Color(1.0, 0.30, 0.32)
					nuevo_ico = TEX_ICO_PACTO
				2: # SOBRECARGA_FRENESI
					var t_fren := float(boton._tiempo_frenesi) if "_tiempo_frenesi" in boton else 0.0
					nuevo_txt = "FRENESÍ x3 · CLICS Y ORO (%.1fs)" % maxf(0.0, t_fren)
					nuevo_col = Color(1.0, 0.85, 0.22)
					nuevo_ico = TEX_ICO_FEVER
				_:
					var clk_bloq := int(boton.clics_para_bloqueo) if "clics_para_bloqueo" in boton else 20
					var prox := clk_bloq - (clicks_boton % maxi(clk_bloq, 1))
					nuevo_txt = "Clics: %d  ·  Bloqueo en %d" % [clicks_boton, prox]
					nuevo_col = Color(0.98, 0.42, 0.88) if en_overdrive else Color(0.36, 0.90, 0.98)
		else:
			nuevo_txt = "Clics: %d  ·  %.1f m/s" % [clicks_boton, vel_boton]

		if nuevo_txt != _ultimo_txt_nucleo:
			_ultimo_txt_nucleo = nuevo_txt
			label_nucleo.text = nuevo_txt
		if not nuevo_col.is_equal_approx(_ultimo_col_nucleo):
			_ultimo_col_nucleo = nuevo_col
			label_nucleo.add_theme_color_override("font_color", nuevo_col)
			if icono_nucleo != null:
				icono_nucleo.modulate = nuevo_col
		if icono_nucleo != null and nuevo_ico != _ultimo_ico_nucleo:
			_ultimo_ico_nucleo = nuevo_ico
			icono_nucleo.texture = nuevo_ico

	# Medidor Fiebre visual + paleta dinámica por escalón real (x1, x2, x3, x5 Overdrive)
	var obj_fever: float = clampf(fever_val, 0.0, 100.0)
	if absf(_fever_valor_visual - obj_fever) > 0.05:
		_fever_valor_visual = lerpf(_fever_valor_visual, obj_fever, minf(1.0, delta * 14.0))
		if bar_fiebre != null:
			bar_fiebre.value = _fever_valor_visual
	_aplicar_tema_fiebre(fever_mult, en_overdrive, delta)


func _aplicar_tema_fiebre(fever_mult: int, en_overdrive: bool, delta: float) -> void:
	var obj_glow: float = 1.0 if en_overdrive else 0.0
	if absf(_overdrive_glow - obj_glow) > 0.005:
		_overdrive_glow = lerpf(_overdrive_glow, obj_glow, minf(1.0, delta * 8.0))
	else:
		_overdrive_glow = obj_glow
	if absf(_overdrive_glow - _ultimo_overdrive_shader) > 0.005:
		_ultimo_overdrive_shader = _overdrive_glow
		if subviewport_container != null and subviewport_container.material is ShaderMaterial:
			(subviewport_container.material as ShaderMaterial).set_shader_parameter("overdrive_pulse", _overdrive_glow)

	var col_tier := Color(0.18, 0.78, 0.94)
	var txt_badge := "x%d" % max(fever_mult, 1)
	if en_overdrive or fever_mult >= 5:
		col_tier = Color(0.96, 0.28, 0.72)
		txt_badge = "OVER x5"
	elif fever_mult >= 3:
		col_tier = Color(0.98, 0.45, 0.12)
	elif fever_mult >= 2:
		col_tier = Color(0.96, 0.72, 0.14)

	if label_fiebre != null and label_fiebre.text != txt_badge:
		label_fiebre.text = txt_badge
	if not col_tier.is_equal_approx(_ultimo_col_fiebre):
		_ultimo_col_fiebre = col_tier
		if label_fiebre != null:
			label_fiebre.add_theme_color_override("font_color", col_tier.lightened(0.35))
		if _sb_fiebre_fill != null:
			_sb_fiebre_fill.bg_color = col_tier
			_sb_fiebre_fill.border_color = col_tier.lightened(0.45)
		if _sb_badge_fiebre != null:
			_sb_badge_fiebre.border_color = col_tier
			_sb_badge_fiebre.bg_color = Color(col_tier.r * 0.14 + 0.03, col_tier.g * 0.12 + 0.03, col_tier.b * 0.14 + 0.05, 0.95)
		if icono_fiebre != null:
			icono_fiebre.modulate = col_tier
	if _sb_barra_superior_base != null:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008) if en_overdrive else 0.0
		var nuevo_borde := Color(0.70, 0.54, 0.28, 0.95).lerp(Color(0.98, 0.35, 0.78, 1.0), _overdrive_glow * (0.45 + 0.45 * pulse))
		if not nuevo_borde.is_equal_approx(_ultimo_border_barra):
			_ultimo_border_barra = nuevo_borde
			_sb_barra_superior_base.border_color = nuevo_borde


func _actualizar_overlays_shader(delta: float) -> void:
	if overlay_colapso != null:
		if est_en_colapso:
			var alpha_colapso := 0.13 + sin(Time.get_ticks_msec() * 0.008) * 0.09
			overlay_colapso.color = Color(0.85, 0.05, 0.10, alpha_colapso)
		else:
			overlay_colapso.color.a = move_toward(overlay_colapso.color.a, 0.0, delta * 3.0)

	# Player HP Trail catch-up
	if _hp_trail_hold > 0.0:
		_hp_trail_hold = maxf(0.0, _hp_trail_hold - delta)
	elif _hp_trail_ratio > _hp_ratio_actual:
		_hp_trail_ratio = maxf(_hp_ratio_actual, _hp_trail_ratio - delta * 0.55)
	else:
		_hp_trail_ratio = _hp_ratio_actual

	if bar_vida_shader != null and bar_vida_shader.material is ShaderMaterial:
		var m := bar_vida_shader.material as ShaderMaterial
		m.set_shader_parameter("hp_ratio", _hp_ratio_actual)
		m.set_shader_parameter("trail_ratio", _hp_trail_ratio)
		m.set_shader_parameter("shield_ratio", _shield_ratio_actual)

	# Boss HP Trail catch-up
	if _jefe_trail_hold > 0.0:
		_jefe_trail_hold = maxf(0.0, _jefe_trail_hold - delta)
	elif _jefe_trail_ratio > _jefe_hp_ratio:
		_jefe_trail_ratio = maxf(_jefe_hp_ratio, _jefe_trail_ratio - delta * 0.48)
	else:
		_jefe_trail_ratio = _jefe_hp_ratio

	if bar_jefe_shader != null and bar_jefe_shader.material is ShaderMaterial:
		var mj := bar_jefe_shader.material as ShaderMaterial
		mj.set_shader_parameter("hp_ratio", _jefe_hp_ratio)
		mj.set_shader_parameter("trail_ratio", _jefe_trail_ratio)


func _actualizar_chips_estado(_delta: float) -> void:
	if jugador == null or not is_instance_valid(jugador):
		return

	# Sync reliquias y sinergias (solo reconstruir cadenas si cambia el conjunto/stacks)
	var n_sin: int = jugador.sinergias_activas.size() if ("sinergias_activas" in jugador and jugador.sinergias_activas is Array) else 0
	var hash_rel: int = n_sin * 131071
	var hay_reliquias: bool = "reliquias" in jugador and jugador.reliquias is Dictionary and not jugador.reliquias.is_empty()
	if hay_reliquias:
		for id_rel in jugador.reliquias:
			hash_rel = hash_rel * 31 + str(id_rel).hash() + int(jugador.reliquias[id_rel]) * 997
	if hash_rel != _ultimo_hash_reliquias:
		_ultimo_hash_reliquias = hash_rel
		var n_rel: int = 0
		var detalles: PackedStringArray = []
		if hay_reliquias:
			for id_rel in jugador.reliquias:
				var stacks := int(jugador.reliquias[id_rel])
				n_rel += stacks
				detalles.append("%s x%d" % [ReliquiaDatos.obtener_nombre(str(id_rel)), stacks])
		if chip_reliquias != null:
			if n_rel > 0 or n_sin > 0:
				chip_reliquias.visible = true
				if label_reliquias != null:
					if n_sin > 0:
						label_reliquias.text = "%d Rel. · %d Sinergia" % [n_rel, n_sin] if n_sin == 1 else ("%d Rel. · %d Sinergias" % [n_rel, n_sin])
					else:
						label_reliquias.text = "%d Reliquia" % n_rel if n_rel == 1 else ("%d Reliquias" % n_rel)
				chip_reliquias.tooltip_text = "Reliquias activas:\n" + "\n".join(detalles) if not detalles.is_empty() else "Sinergias activas: %d" % n_sin
			else:
				chip_reliquias.visible = false

	# Sync escudo live (p. ej. recarga pasiva o golpe sin re-emitir señal instantánea)
	if "escudo_almas" in jugador and "vida_maxima" in jugador and float(jugador.vida_maxima) > 0.0:
		var esc := float(jugador.escudo_almas)
		_shield_ratio_actual = clampf(esc / float(jugador.vida_maxima), 0.0, 1.0)
		var esc_vis: int = 1 if esc > 0.5 else 0
		if esc_vis != _ultimo_escudo_vis:
			_ultimo_escudo_vis = esc_vis
			if icono_escudo_hp != null:
				icono_escudo_hp.visible = esc_vis == 1
			if label_escudo_hp != null:
				label_escudo_hp.visible = esc_vis == 1
		if esc_vis == 1 and label_escudo_hp != null:
			var esc_txt := "+%d" % int(round(esc))
			if esc_txt != _ultimo_escudo_txt:
				_ultimo_escudo_txt = esc_txt
				label_escudo_hp.text = esc_txt

	# Actualizar botón [U] Ascensión
	if label_arbol != null and "clics_disponibles" in jugador:
		var pts := int(jugador.clics_disponibles)
		var nuevo_lbl := "[U] Ascensión (%d)" % pts if pts > 0 else "[U] Ascensión"
		if label_arbol.text != nuevo_lbl:
			label_arbol.text = nuevo_lbl
		var ready_gl: int = 1 if pts >= 10 else 0
		if _sb_btn_arbol_normal != null and ready_gl != _ultimo_ready_gl:
			_ultimo_ready_gl = ready_gl
			_sb_btn_arbol_normal.border_color = Color(1.0, 0.86, 0.35, 1.0) if ready_gl == 1 else Color(0.76, 0.60, 0.29, 0.92)


func _animar_retrato_sutil(delta: float) -> void:
	if modelo_avatar_nodo == null or not is_instance_valid(modelo_avatar_nodo):
		return
	_avatar_reloj_idle += delta
	_avatar_reloj_redraw += delta
	if _avatar_reloj_redraw >= 0.055:
		_avatar_reloj_redraw = 0.0
		modelo_avatar_nodo.rotation_degrees.y = 20.0 + sin(_avatar_reloj_idle * 1.1) * 5.0
		if subviewport_avatar != null:
			subviewport_avatar.render_target_update_mode = SubViewport.UPDATE_ONCE


# --- Señales del Jugador & Fortuna ---

func _on_stats_actualizadas(vida: float, max_vida: float, xp: int, xp_sig: int, nivel: int, oro: int, bajas: int) -> void:
	if jugador != null and "clase" in jugador:
		var nombre_clase := str(jugador.clase)
		if label_clase != null:
			label_clase.text = nombre_clase
		_actualizar_avatar_clase(nombre_clase)

	if label_nivel != null:
		var txt_nv := "NV. %d" % nivel
		if label_nivel.text != txt_nv:
			label_nivel.text = txt_nv

	if jugador != null and "reapariciones" in jugador:
		var vidas_max := 1
		if jugador.has_method("obtener_vidas_maximas"):
			vidas_max = jugador.obtener_vidas_maximas()
		var vidas_restantes := clampi(int(jugador.reapariciones) + 1, 0, vidas_max)
		_actualizar_corazones_dinamicos(vidas_restantes, vidas_max)

	var safe_max := maxf(max_vida, 1.0)
	_hp_ratio_actual = clampf(vida / safe_max, 0.0, 1.0)
	if _hp_previa >= 0.0 and vida < _hp_previa - 0.5:
		_hp_trail_hold = 0.20
	elif _hp_previa < 0.0 or vida > _hp_previa:
		_hp_trail_ratio = maxf(_hp_trail_ratio, _hp_ratio_actual)
	_hp_previa = vida

	if bar_vida != null:
		bar_vida.max_value = safe_max
		bar_vida.value = vida
	if label_vida != null:
		label_vida.text = "%d / %d HP" % [int(ceil(vida)), int(round(safe_max))]

	var esc: float = float(jugador.escudo_almas) if (jugador != null and "escudo_almas" in jugador) else 0.0
	_shield_ratio_actual = clampf(esc / safe_max, 0.0, 1.0)
	if icono_escudo_hp != null:
		icono_escudo_hp.visible = esc > 0.5
	if label_escudo_hp != null:
		label_escudo_hp.visible = esc > 0.5
		if esc > 0.5:
			label_escudo_hp.text = "+%d" % int(round(esc))

	if bar_xp != null:
		bar_xp.max_value = max(xp_sig, 1)
		bar_xp.value = xp
	if label_xp != null:
		label_xp.text = "%d / %d XP" % [xp, xp_sig]

	if label_oro != null:
		label_oro.text = "%d" % oro
	if label_bajas != null:
		label_bajas.text = "%d Bajas" % bajas


func _on_economia_actualizada(oro_cnt: int, clics_disp: int, _clics_tot: int) -> void:
	if label_oro != null:
		label_oro.text = "%d" % oro_cnt
	if label_arbol != null:
		label_arbol.text = "[U] Ascensión (%d)" % clics_disp if clics_disp > 0 else "[U] Ascensión"


func _on_denarios_actualizados(denarios_actuales: int) -> void:
	if label_denarios != null:
		label_denarios.text = "%d" % denarios_actuales


func _on_suerte_cambiada(nueva_suerte: float) -> void:
	if label_suerte != null:
		var pct := int(round(nueva_suerte * 100.0))
		label_suerte.text = "+%d%%" % pct if pct >= 0 else "%d%%" % pct
		label_suerte.add_theme_color_override("font_color", Color(0.20, 0.85, 0.60) if pct >= 0 else Color(0.98, 0.55, 0.35))


func _on_fiebre_actualizada(valor_actual: float, multiplicador: int, en_overdrive: bool) -> void:
	_fever_valor_visual = clampf(valor_actual, 0.0, 100.0)
	if multiplicador > _fever_tier_prev and _fever_tier_prev >= 0 and badge_fiebre != null:
		badge_fiebre.pivot_offset = badge_fiebre.size * 0.5
		var tw := create_tween()
		tw.tween_property(badge_fiebre, "scale", Vector2(1.18, 1.18), 0.10).set_trans(Tween.TRANS_BACK)
		tw.tween_property(badge_fiebre, "scale", Vector2.ONE, 0.14)
	_fever_tier_prev = multiplicador
	_aplicar_tema_fiebre(multiplicador, en_overdrive, 0.1)


func _on_bendicion_adquirida(_id_bendicion: String, _nivel_actual: int) -> void:
	if avatar_frame != null:
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(avatar_frame, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(avatar_frame, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_CUBIC)


func _on_presagio_sorteado(datos: Dictionary) -> void:
	var nom := String(datos.get("nombre", "Cielo Despejado"))
	var desc := String(datos.get("descripcion", ""))
	var col: Color = datos.get("color", Color(0.86, 0.72, 0.36))
	_actualizar_chip_presagio(nom, desc, col)


func _actualizar_chip_presagio(nombre: String, desc: String, color_acento: Color) -> void:
	if chip_presagio == null:
		return
	chip_presagio.visible = true
	if label_presagio != null:
		label_presagio.text = "Presagio: %s" % nombre
		label_presagio.add_theme_color_override("font_color", color_acento.lightened(0.32))
	if icono_presagio != null:
		icono_presagio.modulate = color_acento
	var sb := chip_presagio.get_theme_stylebox("panel")
	if sb is StyleBoxFlat:
		var sb_new := sb.duplicate() as StyleBoxFlat
		sb_new.border_color = Color(color_acento.r, color_acento.g, color_acento.b, 0.85)
		chip_presagio.add_theme_stylebox_override("panel", sb_new)
	chip_presagio.tooltip_text = desc


func _actualizar_corazones_dinamicos(vidas_restantes: int, vidas_maximas: int) -> void:
	if label_vidas != null:
		label_vidas.text = "%d/%d" % [vidas_restantes, vidas_maximas]
	if hbox_corazones == null:
		return

	var hijos := hbox_corazones.get_children()
	while hijos.size() < vidas_maximas:
		var extra := TextureRect.new()
		extra.custom_minimum_size = Vector2(15, 15)
		extra.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		extra.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		extra.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox_corazones.add_child(extra)
		hijos.append(extra)

	for i in range(hijos.size()):
		var c := hijos[i] as TextureRect
		if c == null:
			continue
		if i < vidas_maximas:
			c.visible = true
			c.texture = TEX_CORAZON_LLENO if i < vidas_restantes else TEX_CORAZON_VACIO
		else:
			c.visible = false


func _actualizar_avatar_clase(nombre_clase: String) -> void:
	if _clase_actual_avatar == nombre_clase or subviewport_avatar == null:
		return
	_clase_actual_avatar = nombre_clase

	if MALLAS_AVATAR.has(nombre_clase):
		var escena_malla: PackedScene = MALLAS_AVATAR[nombre_clase]
		if escena_malla != null:
			if is_instance_valid(modelo_avatar_nodo):
				modelo_avatar_nodo.queue_free()
			var nuevo_modelo := escena_malla.instantiate() as Node3D
			if nuevo_modelo != null:
				nuevo_modelo.name = "ModeloAvatar"
				nuevo_modelo.rotation_degrees.y = 20.0
				subviewport_avatar.add_child(nuevo_modelo)
				modelo_avatar_nodo = nuevo_modelo
				_preparar_modelo_retrato(nuevo_modelo, nombre_clase)

				if avatar_frame != null:
					var tw := create_tween()
					tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
					tw.tween_property(avatar_frame, "scale", Vector2(1.16, 1.16), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					tw.tween_property(avatar_frame, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_CUBIC)


# ==============================================================================
# API DE PACTO DE MARTE / BUFFS CONTEXTUALES EN STATUS RAIL
# ==============================================================================

func registrar_pacto_marte(duracion: float = 60.0) -> void:
	_pacto_duracion = maxf(duracion, 1.0)
	if chip_pacto_marte == null:
		return
	chip_pacto_marte.visible = true
	chip_pacto_marte.modulate = Color(1.0, 1.0, 1.0, 0.0)
	if bar_pacto != null:
		bar_pacto.max_value = _pacto_duracion
		bar_pacto.value = _pacto_duracion
	if label_pacto != null:
		label_pacto.text = "PACTO DE MARTE  %ds" % ceili(_pacto_duracion)
	var tw := create_tween()
	tw.tween_property(chip_pacto_marte, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC)


func actualizar_pacto_marte(restante: float) -> void:
	if chip_pacto_marte == null:
		return
	chip_pacto_marte.visible = true
	var secs := maxi(0, ceili(restante))
	if label_pacto != null:
		label_pacto.text = "PACTO DE MARTE  %ds" % secs
	if bar_pacto != null:
		bar_pacto.max_value = _pacto_duracion
		bar_pacto.value = clampf(restante, 0.0, _pacto_duracion)
	if restante <= 10.0:
		var pulse := 0.72 + 0.28 * sin(Time.get_ticks_msec() * 0.015)
		chip_pacto_marte.modulate = Color(1.0, pulse, pulse, 1.0)
	else:
		chip_pacto_marte.modulate = Color.WHITE


func ocultar_pacto_marte() -> void:
	if chip_pacto_marte != null:
		chip_pacto_marte.visible = false
		chip_pacto_marte.modulate = Color.WHITE


# ==============================================================================
# SELECTOR DE 3 CARTAS TAROT DE BENDICIONES ROGUELIKE Y SINERGIAS DUALES
# ==============================================================================

func _configurar_tarot_hover() -> void:
	for btn in [btn_opc1, btn_opc2, btn_opc3]:
		if btn == null:
			continue
		btn.mouse_entered.connect(func():
			if _esta_modal_bendiciones_sellado():
				return
			btn.pivot_offset = btn.size * 0.5
			var tw := create_tween()
			tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(btn, "scale", Vector2(1.035, 1.035), 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		)
		btn.mouse_exited.connect(func():
			btn.pivot_offset = btn.size * 0.5
			var tw := create_tween()
			tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(btn, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		)


func _on_nivel_subido(nuevo_nivel: int) -> void:
	if avatar_frame != null:
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(avatar_frame, "scale", Vector2(1.20, 1.20), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(avatar_frame, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_CUBIC)
	mostrar_selector_bendiciones(nuevo_nivel)


func _asegurar_banner_sello_tarot() -> void:
	if modal_mejora == null:
		return
	var vbox := modal_mejora.get_node_or_null("VBox") as VBoxContainer
	if vbox == null:
		return
	if _banner_sello_tarot != null and is_instance_valid(_banner_sello_tarot):
		return

	_banner_sello_tarot = PanelContainer.new()
	_banner_sello_tarot.name = "SelloAntiClicBar"
	_banner_sello_tarot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_sello_tarot.custom_minimum_size = Vector2(0.0, 24.0)

	_sb_banner_sello = StyleBoxFlat.new()
	_sb_banner_sello.bg_color = Color(0.05, 0.04, 0.08, 0.94)
	_sb_banner_sello.border_color = Color(0.95, 0.68, 0.22, 0.90)
	_sb_banner_sello.set_border_width_all(1)
	_sb_banner_sello.set_corner_radius_all(6)
	_sb_banner_sello.content_margin_left = 2.0
	_sb_banner_sello.content_margin_right = 2.0
	_sb_banner_sello.content_margin_top = 2.0
	_sb_banner_sello.content_margin_bottom = 2.0
	_banner_sello_tarot.add_theme_stylebox_override("panel", _sb_banner_sello)

	var track := Control.new()
	track.name = "SelloTrack"
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.clip_contents = true
	track.custom_minimum_size = Vector2(0.0, 20.0)
	_banner_sello_tarot.add_child(track)

	var bg_track := ColorRect.new()
	bg_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_track.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_track.color = Color(0.03, 0.03, 0.06, 0.72)
	track.add_child(bg_track)

	_sello_fill_rect = ColorRect.new()
	_sello_fill_rect.name = "SelloFill"
	_sello_fill_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sello_fill_rect.anchor_left = 0.0
	_sello_fill_rect.anchor_top = 0.0
	_sello_fill_rect.anchor_right = 0.0
	_sello_fill_rect.anchor_bottom = 1.0
	_sello_fill_rect.color = Color(0.94, 0.66, 0.18, 0.34)
	track.add_child(_sello_fill_rect)

	_lbl_sello_tarot = Label.new()
	_lbl_sello_tarot.name = "SelloLabel"
	_lbl_sello_tarot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_sello_tarot.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lbl_sello_tarot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_sello_tarot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_sello_tarot.add_theme_font_size_override("font_size", 11)
	_lbl_sello_tarot.add_theme_color_override("font_color", Color(1.0, 0.88, 0.48))
	track.add_child(_lbl_sello_tarot)

	vbox.add_child(_banner_sello_tarot)
	vbox.move_child(_banner_sello_tarot, 1)


func _esta_modal_bendiciones_sellado() -> bool:
	return modal_mejora != null and modal_mejora.visible and Time.get_ticks_msec() < _modal_bloqueado_hasta_msec


func _registrar_clic_durante_sello(con_feedback: bool = true) -> void:
	var ahora := Time.get_ticks_msec()
	if ahora >= _modal_apertura_msec + 140:
		var tope := _modal_apertura_msec + SELLO_MAX_TOTAL_MS
		_modal_bloqueado_hasta_msec = mini(tope, maxi(_modal_bloqueado_hasta_msec, ahora + SELLO_REBOTE_SPAM_MS))
		_modal_duracion_sello_actual_ms = maxi(SELLO_GRACIA_INICIAL_MS, _modal_bloqueado_hasta_msec - _modal_apertura_msec)
	if con_feedback:
		_modal_clic_bloqueado_flash_hasta_msec = ahora + 380
		_animar_pulso_sello_tarot()


func _animar_pulso_sello_tarot() -> void:
	if _banner_sello_tarot != null and is_instance_valid(_banner_sello_tarot):
		_banner_sello_tarot.pivot_offset = _banner_sello_tarot.size * 0.5
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(_banner_sello_tarot, "scale", Vector2(1.025, 1.08), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(_banner_sello_tarot, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_CUBIC)


func _animar_desbloqueo_tarot() -> void:
	if _banner_sello_tarot != null and is_instance_valid(_banner_sello_tarot):
		_banner_sello_tarot.pivot_offset = _banner_sello_tarot.size * 0.5
		var tw_b := create_tween()
		tw_b.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw_b.tween_property(_banner_sello_tarot, "scale", Vector2(1.015, 1.04), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_b.tween_property(_banner_sello_tarot, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_CUBIC)
	var botones_tarot: Array[Button] = [btn_opc1, btn_opc2, btn_opc3]
	for btn: Button in botones_tarot:
		if btn == null or not btn.visible:
			continue
		btn.pivot_offset = btn.size * 0.5
		var hovering: bool = btn.get_global_rect().has_point(btn.get_global_mouse_position())
		var objetivo: Vector2 = Vector2(1.035, 1.035) if hovering else Vector2.ONE
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(btn, "scale", objetivo * 1.02, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", objetivo, 0.14).set_trans(Tween.TRANS_CUBIC)


func _actualizar_visual_sello_tarot() -> void:
	if modal_mejora == null or not modal_mejora.visible:
		return
	var ahora := Time.get_ticks_msec()
	var restante_ms := maxi(0, _modal_bloqueado_hasta_msec - ahora)
	var sellado := restante_ms > 0
	var progreso := clampf(float(ahora - _modal_apertura_msec) / float(maxi(1, _modal_duracion_sello_actual_ms)), 0.0, 1.0)
	if not sellado:
		progreso = 1.0

	if _sello_fill_rect != null and is_instance_valid(_sello_fill_rect):
		_sello_fill_rect.anchor_right = progreso
		if sellado:
			if ahora < _modal_clic_bloqueado_flash_hasta_msec:
				_sello_fill_rect.color = Color(0.98, 0.42, 0.24, 0.46)
			else:
				_sello_fill_rect.color = Color(0.95, 0.68, 0.20, 0.34)
		else:
			_sello_fill_rect.color = Color(0.28, 0.80, 0.64, 0.22)

	if _sb_banner_sello != null:
		if sellado:
			_sb_banner_sello.border_color = Color(0.98, 0.48, 0.28, 0.96) if ahora < _modal_clic_bloqueado_flash_hasta_msec else Color(0.95, 0.70, 0.24, 0.88)
		else:
			_sb_banner_sello.border_color = Color(0.34, 0.88, 0.72, 0.78)

	if _lbl_sello_tarot != null and is_instance_valid(_lbl_sello_tarot):
		if sellado:
			var segs := float(restante_ms) * 0.001
			if ahora < _modal_clic_bloqueado_flash_hasta_msec:
				_lbl_sello_tarot.text = "⚡ CLIC BLOQUEADO POR SEGURIDAD · ESPERA %.2fs" % segs
				_lbl_sello_tarot.add_theme_color_override("font_color", Color(1.0, 0.76, 0.56))
			else:
				_lbl_sello_tarot.text = "🛡 PROTECCIÓN ANTI-CLIC ACTIVA · DESSELLANDO EN %.2fs" % segs
				_lbl_sello_tarot.add_theme_color_override("font_color", Color(1.0, 0.90, 0.55))
		else:
			_lbl_sello_tarot.text = "✦ LISTO — HAZ CLIC EN UNA CARTA O PULSA [1] [2] [3]"
			_lbl_sello_tarot.add_theme_color_override("font_color", Color(0.76, 0.98, 0.88))

	var botones_tarot: Array[Button] = [btn_opc1, btn_opc2, btn_opc3]
	for btn: Button in botones_tarot:
		if btn == null or not btn.visible:
			continue
		btn.mouse_default_cursor_shape = Control.CURSOR_WAIT if sellado else Control.CURSOR_POINTING_HAND
		var cta_bar := btn.find_child("TarotCTABar", true, false) as Control
		var cta_lbl := btn.find_child("TarotCTALabel", true, false) as Label
		if sellado:
			if cta_bar != null:
				cta_bar.modulate = Color(0.72, 0.68, 0.74, 0.76)
			if cta_lbl != null:
				cta_lbl.text = "PROTEGIDA · %.1fs" % (float(restante_ms) * 0.001)
		else:
			if cta_bar != null:
				cta_bar.modulate = Color.WHITE
			if cta_lbl != null and btn.has_meta("cta_texto_desbloqueado"):
				cta_lbl.text = String(btn.get_meta("cta_texto_desbloqueado"))

	if not sellado and not _modal_sello_desbloqueado_visual:
		_modal_sello_desbloqueado_visual = true
		_animar_desbloqueo_tarot()


func mostrar_selector_bendiciones(nivel_evento: int = 0, cartas_forzadas: Array = []) -> void:
	if modal_mejora == null:
		return
	if nivel_evento > 0:
		if nivel_evento <= _ultimo_nivel_procesado:
			return
		_ultimo_nivel_procesado = nivel_evento
	if modal_mejora.visible:
		_niveles_pendientes += 1
		return

	if _panel_resoluciones != null:
		_panel_resoluciones.visible = false
	if _panel_test_jefes != null:
		_panel_test_jefes.visible = false

	_asegurar_banner_sello_tarot()

	modal_mejora.offset_left = -468.0
	modal_mejora.offset_top = -238.0
	modal_mejora.offset_right = 468.0
	modal_mejora.offset_bottom = 238.0
	modal_mejora.pivot_offset = Vector2(468.0, 238.0)

	var lbl_tit := modal_mejora.get_node_or_null("VBox/HeaderModal/LabelTitulo") as Label
	if lbl_tit != null:
		var niv_mostrar := _ultimo_nivel_procesado
		if jugador != null and "nivel" in jugador:
			niv_mostrar = maxi(niv_mostrar, int(jugador.nivel))
		lbl_tit.text = "NIVEL %d ALCANZADO — CONSAGRA TU BENDICIÓN" % maxi(niv_mostrar, 2)

	var actuales: Dictionary = {}
	if jugador != null and "bendiciones_run" in jugador:
		actuales = jugador.bendiciones_run

	var suerte_actual: float = 0.0
	if FortunaManager != null and "suerte_total" in FortunaManager:
		suerte_actual = float(FortunaManager.suerte_total)

	if not cartas_forzadas.is_empty():
		_opciones_bendicion_actuales = cartas_forzadas
	else:
		_opciones_bendicion_actuales = CatalogoBendiciones.obtener_3_opciones(actuales, suerte_actual)

	_modal_apertura_msec = Time.get_ticks_msec()
	_modal_bloqueado_hasta_msec = _modal_apertura_msec + SELLO_GRACIA_INICIAL_MS
	_modal_duracion_sello_actual_ms = SELLO_GRACIA_INICIAL_MS
	_modal_sello_desbloqueado_visual = false
	_modal_clic_bloqueado_flash_hasta_msec = 0

	var botones := [btn_opc1, btn_opc2, btn_opc3]
	for i in range(botones.size()):
		var btn: Button = botones[i]
		if btn == null:
			continue
		if i < _opciones_bendicion_actuales.size():
			var b: Dictionary = _opciones_bendicion_actuales[i]
			btn.text = ""
			btn.scale = Vector2.ONE
			btn.custom_minimum_size = Vector2(280.0, 352.0)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_poblar_contenido_carta_tarot(btn, b, i)
			_aplicar_estilo_carta_bendicion(btn, b)
			btn.visible = true
		else:
			btn.visible = false

	if modal_dimmer != null:
		modal_dimmer.visible = true
		modal_dimmer.modulate.a = 0.0
		var tw_dim := create_tween()
		tw_dim.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw_dim.tween_property(modal_dimmer, "modulate:a", 1.0, 0.18)

	var escala_objetivo := _calcular_escala_modal_mejora()
	modal_mejora.visible = true
	_actualizar_visual_sello_tarot()
	modal_mejora.scale = escala_objetivo * 0.88
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(modal_mejora, "scale", escala_objetivo, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if is_inside_tree() and get_tree() != null:
		get_tree().paused = true


func _resolver_icono_bendicion(b: Dictionary) -> Texture2D:
	if bool(b.get("es_sinergia", false)):
		return TEX_ICO_SYNERGY
	var id_str := String(b.get("id", "")).to_lower()
	var cat_str := String(b.get("categoria", "")).to_lower()
	if id_str.contains("rayo") or id_str.contains("estatico") or id_str.contains("relampago") or id_str.contains("faraday"):
		return TEX_ICO_BOLT
	if id_str.contains("daga") or id_str.contains("perforante") or id_str.contains("sed_de_sangre") or id_str.contains("verdugo"):
		return TEX_ICO_DAGGERS
	if id_str.contains("helada") or id_str.contains("hielo") or id_str.contains("etereo"):
		return TEX_ICO_FROST
	if id_str.contains("sangre") or id_str.contains("vampirismo"):
		return TEX_ICO_BLOOD
	if id_str.contains("prisma") or id_str.contains("lentes") or id_str.contains("corazon_runico"):
		return TEX_ICO_PRISM
	if id_str.contains("escudo") or id_str.contains("vida") or id_str.contains("armadura") or id_str.contains("bastion"):
		return TEX_ICO_SHIELD
	if id_str.contains("fuego") or id_str.contains("fiebre") or id_str.contains("supernova") or id_str.contains("meteoro"):
		return TEX_ICO_FEVER
	if id_str.contains("moneda") or id_str.contains("midas") or id_str.contains("canon"):
		return TEX_ICO_GOLD
	if id_str.contains("iman") or id_str.contains("suerte") or id_str.contains("fortuna"):
		return TEX_ICO_LUCK
	if id_str.contains("hilo") or id_str.contains("clic") or cat_str.contains("clic") or cat_str.contains("hilo"):
		return TEX_ICO_CLICKS
	return TEX_ICO_PACTO


func _obtener_arquetipo_bendicion(b: Dictionary) -> String:
	if bool(b.get("es_sinergia", false)):
		return "✦ FUSIÓN DUAL"
	var cat := String(b.get("categoria", "")).to_lower()
	match cat:
		"ataque":
			return "⚔ ARSENAL"
		"defensa":
			return "🛡 BALUARTE"
		"clic":
			return "⚡ PULSO CLIC"
		"hilo":
			return "🔗 HILO RÚNICO"
		"movilidad":
			return "💨 AGILIDAD"
		"utilidad":
			return "🪙 FORTUNA"
		_:
			return "❖ ARCANO"


func _extraer_chips_estadisticas(desc: String, b: Dictionary) -> PackedStringArray:
	var chips := PackedStringArray()
	var regex := RegEx.new()
	regex.compile("(\\+[0-9]+(?:\\.[0-9]+)?(?:%|m|s| HP)?|x[0-9]+|[0-9]+%)")
	var matches := regex.search_all(desc)
	var palabras := desc.split(" ")
	for m in matches:
		var token := m.get_string()
		var etiqueta := token
		for idx in range(palabras.size()):
			if palabras[idx].contains(token):
				if idx + 1 < palabras.size():
					var sig := palabras[idx + 1].trim_suffix(",").trim_suffix(".").trim_suffix(")")
					if sig.length() >= 3 and sig.to_lower() not in ["de", "del", "en", "por", "al", "la", "el", "que", "con"]:
						etiqueta = "%s %s" % [token, sig.capitalize()]
					elif idx + 2 < palabras.size():
						var sig2 := palabras[idx + 2].trim_suffix(",").trim_suffix(".").trim_suffix(")")
						if sig2.length() >= 3:
							etiqueta = "%s %s" % [token, sig2.capitalize()]
				break
		if not chips.has(etiqueta):
			chips.append(etiqueta)
		if chips.size() >= 2:
			break
	if chips.is_empty():
		if bool(b.get("es_sinergia", false)):
			chips.append("✦ Poder Supremo")
			chips.append("Sinergia Permanente")
		else:
			chips.append("Efecto Pasivo")
	return chips


func _obtener_paleta_rareza(rareza: String, es_sinergia: bool, col_fallback: Color) -> Dictionary:
	if es_sinergia or rareza == "MITICA":
		return {
			"borde": Color(0.98, 0.28, 0.56, 0.98),
			"acento": Color(1.0, 0.42, 0.68, 1.0),
			"corona": Color(0.98, 0.30, 0.58, 0.95),
			"sombra": Color(0.92, 0.16, 0.46, 0.42),
			"badge_bg": Color(0.28, 0.06, 0.16, 0.96),
			"texto": Color(1.0, 0.78, 0.88, 1.0),
		}
	match rareza:
		"LEGENDARIA":
			return {
				"borde": Color(0.98, 0.76, 0.22, 0.98),
				"acento": Color(1.0, 0.86, 0.36, 1.0),
				"corona": Color(0.98, 0.74, 0.18, 0.95),
				"sombra": Color(0.95, 0.65, 0.12, 0.38),
				"badge_bg": Color(0.26, 0.18, 0.04, 0.96),
				"texto": Color(1.0, 0.91, 0.58, 1.0),
			}
		"EPICA":
			return {
				"borde": Color(0.74, 0.38, 0.98, 0.96),
				"acento": Color(0.84, 0.56, 1.0, 1.0),
				"corona": Color(0.70, 0.34, 0.96, 0.95),
				"sombra": Color(0.62, 0.22, 0.92, 0.34),
				"badge_bg": Color(0.18, 0.08, 0.28, 0.96),
				"texto": Color(0.90, 0.76, 1.0, 1.0),
			}
		"RARA":
			return {
				"borde": Color(0.24, 0.72, 0.98, 0.95),
				"acento": Color(0.42, 0.84, 1.0, 1.0),
				"corona": Color(0.20, 0.68, 0.96, 0.92),
				"sombra": Color(0.14, 0.56, 0.88, 0.30),
				"badge_bg": Color(0.06, 0.18, 0.28, 0.96),
				"texto": Color(0.72, 0.92, 1.0, 1.0),
			}
		_:
			var c := col_fallback.lightened(0.15)
			return {
				"borde": Color(0.58, 0.65, 0.76, 0.92),
				"acento": c,
				"corona": Color(0.52, 0.60, 0.72, 0.88),
				"sombra": Color(0.0, 0.0, 0.0, 0.65),
				"badge_bg": Color(0.11, 0.14, 0.20, 0.96),
				"texto": Color(0.86, 0.90, 0.96, 1.0),
			}


func _poblar_contenido_carta_tarot(btn: Button, b: Dictionary, indice_carta: int = 0) -> void:
	# CRÍTICO: Desvincular inmediatamente del árbol ANTES de queue_free() para evitar
	# colisión de nombres ("TarotLayout" -> "@MarginContainer@...") y solapamiento entre niveles.
	var hijos_previos := btn.get_children()
	for viejo in hijos_previos:
		btn.remove_child(viejo)
		viejo.queue_free()

	var rareza := str(b.get("rareza", "COMUN"))
	var es_sinergia := bool(b.get("es_sinergia", false))
	var col_base: Color = b.get("color", Color(0.45, 0.65, 0.95))
	var pal := _obtener_paleta_rareza(rareza, es_sinergia, col_base)
	var col_borde: Color = pal["borde"]
	var col_acento: Color = pal["acento"]
	var col_texto_rar: Color = pal["texto"]

	var niv_act := int(b.get("nivel_actual", 0))
	var niv_max := maxi(1, int(b.get("max_nivel", 5)))
	var nombre := str(b.get("nombre", "Bendición"))
	var desc := str(b.get("desc", b.get("descripcion", "")))
	var etiqueta_rareza := _obtener_etiqueta_rareza(rareza, es_sinergia)
	var arquetipo := _obtener_arquetipo_bendicion(b)

	# Capa decorativa de corona superior + filigranas góticas en las 4 esquinas
	var overlay_deco := Control.new()
	overlay_deco.name = "TarotDeco"
	overlay_deco.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(overlay_deco)

	var corona_top := ColorRect.new()
	corona_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corona_top.anchor_left = 0.08
	corona_top.anchor_right = 0.92
	corona_top.offset_top = 2.0
	corona_top.offset_bottom = 5.0
	corona_top.color = pal["corona"]
	overlay_deco.add_child(corona_top)

	var esquinas_cfg := [
		{"ax": 0.0, "ay": 0.0, "ox1": 3.0, "oy1": 3.0, "ox2": 19.0, "oy2": 19.0, "fh": false, "fv": false},
		{"ax": 1.0, "ay": 0.0, "ox1": -19.0, "oy1": 3.0, "ox2": -3.0, "oy2": 19.0, "fh": true, "fv": false},
		{"ax": 0.0, "ay": 1.0, "ox1": 3.0, "oy1": -19.0, "ox2": 19.0, "oy2": -3.0, "fh": false, "fv": true},
		{"ax": 1.0, "ay": 1.0, "ox1": -19.0, "oy1": -19.0, "ox2": -3.0, "oy2": -3.0, "fh": true, "fv": true},
	]
	for ec in esquinas_cfg:
		var tex_c := TextureRect.new()
		tex_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tex_c.texture = TEX_CORNER_GOTHIC
		tex_c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_c.anchor_left = float(ec["ax"])
		tex_c.anchor_right = float(ec["ax"])
		tex_c.anchor_top = float(ec["ay"])
		tex_c.anchor_bottom = float(ec["ay"])
		tex_c.offset_left = float(ec["ox1"])
		tex_c.offset_top = float(ec["oy1"])
		tex_c.offset_right = float(ec["ox2"])
		tex_c.offset_bottom = float(ec["oy2"])
		tex_c.flip_h = bool(ec["fh"])
		tex_c.flip_v = bool(ec["fv"])
		tex_c.modulate = Color(col_borde.r, col_borde.g, col_borde.b, 0.72)
		overlay_deco.add_child(tex_c)

	var margin := MarginContainer.new()
	margin.name = "TarotLayout"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	btn.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 7)
	margin.add_child(vbox)

	# 1. Fila superior: Insignia de Rareza + Píldora de Arquetipo
	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 6)
	vbox.add_child(top_row)

	var banner := PanelContainer.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_ban := StyleBoxFlat.new()
	sb_ban.bg_color = pal["badge_bg"]
	sb_ban.border_color = col_borde
	sb_ban.set_border_width_all(1)
	sb_ban.set_corner_radius_all(5)
	sb_ban.content_margin_left = 8.0
	sb_ban.content_margin_right = 8.0
	sb_ban.content_margin_top = 2.0
	sb_ban.content_margin_bottom = 2.0
	banner.add_theme_stylebox_override("panel", sb_ban)
	top_row.add_child(banner)

	var lbl_rar := Label.new()
	lbl_rar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_rar.text = ("◆ " if rareza != "COMUN" or es_sinergia else "◇ ") + etiqueta_rareza
	lbl_rar.add_theme_font_size_override("font_size", 10)
	lbl_rar.add_theme_color_override("font_color", col_texto_rar)
	banner.add_child(lbl_rar)

	var pill_cat := PanelContainer.new()
	pill_cat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_cat := StyleBoxFlat.new()
	sb_cat.bg_color = Color(0.08, 0.10, 0.16, 0.92)
	sb_cat.border_color = Color(0.45, 0.50, 0.62, 0.45)
	sb_cat.set_border_width_all(1)
	sb_cat.set_corner_radius_all(5)
	sb_cat.content_margin_left = 7.0
	sb_cat.content_margin_right = 7.0
	sb_cat.content_margin_top = 2.0
	sb_cat.content_margin_bottom = 2.0
	pill_cat.add_theme_stylebox_override("panel", sb_cat)
	top_row.add_child(pill_cat)

	var lbl_cat := Label.new()
	lbl_cat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_cat.text = arquetipo
	lbl_cat.add_theme_font_size_override("font_size", 9)
	lbl_cat.add_theme_color_override("font_color", Color(0.78, 0.83, 0.92, 0.92))
	pill_cat.add_child(lbl_cat)

	# 2. Medallón Arcano de Doble Anillo (60x60 exterior + 48x48 núcleo + icono 30x30)
	var crest_outer := PanelContainer.new()
	crest_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crest_outer.custom_minimum_size = Vector2(58, 58)
	crest_outer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb_outer := StyleBoxFlat.new()
	sb_outer.bg_color = Color(col_borde.r * 0.16, col_borde.g * 0.16, col_borde.b * 0.18, 0.45)
	sb_outer.border_color = Color(col_borde.r, col_borde.g, col_borde.b, 0.55)
	sb_outer.set_border_width_all(1)
	sb_outer.set_corner_radius_all(29)
	sb_outer.content_margin_left = 5.0
	sb_outer.content_margin_right = 5.0
	sb_outer.content_margin_top = 5.0
	sb_outer.content_margin_bottom = 5.0
	crest_outer.add_theme_stylebox_override("panel", sb_outer)
	vbox.add_child(crest_outer)

	var crest := PanelContainer.new()
	crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crest.custom_minimum_size = Vector2(48, 48)
	crest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	crest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb_crest := StyleBoxFlat.new()
	sb_crest.bg_color = Color(0.04, 0.05, 0.09, 0.98)
	sb_crest.border_color = col_acento
	sb_crest.set_border_width_all(2)
	sb_crest.set_corner_radius_all(24)
	sb_crest.shadow_color = Color(col_borde.r, col_borde.g, col_borde.b, 0.45)
	sb_crest.shadow_size = 8
	crest.add_theme_stylebox_override("panel", sb_crest)
	crest_outer.add_child(crest)

	var ico := TextureRect.new()
	ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ico.custom_minimum_size = Vector2(28, 28)
	ico.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ico.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ico.texture = _resolver_icono_bendicion(b)
	ico.modulate = col_acento.lightened(0.22)
	crest.add_child(ico)

	# 3. Título de la Bendición
	var lbl_nom := Label.new()
	lbl_nom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_nom.text = nombre
	lbl_nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_nom.add_theme_font_size_override("font_size", 15)
	lbl_nom.add_theme_color_override("font_color", Color(0.99, 0.96, 0.88))
	lbl_nom.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.06))
	lbl_nom.add_theme_constant_override("outline_size", 3)
	vbox.add_child(lbl_nom)

	# 4. Barra de Rango con Gemas Rúnicas (◆ ◆ ◇ ◇ ◇) o Receta de Fusión Mítica
	if es_sinergia:
		var req_nombres := PackedStringArray()
		if b.has("requisitos") and b["requisitos"] is Array:
			for req_id in b["requisitos"]:
				var d_req := CatalogoBendiciones.obtener_bendicion(str(req_id))
				req_nombres.append(str(d_req.get("nombre", req_id)))
		var pill_syn := PanelContainer.new()
		pill_syn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill_syn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var sb_syn := StyleBoxFlat.new()
		sb_syn.bg_color = Color(0.22, 0.05, 0.14, 0.92)
		sb_syn.border_color = Color(0.98, 0.68, 0.30, 0.85)
		sb_syn.set_border_width_all(1)
		sb_syn.set_corner_radius_all(4)
		sb_syn.content_margin_left = 8.0
		sb_syn.content_margin_right = 8.0
		sb_syn.content_margin_top = 2.0
		sb_syn.content_margin_bottom = 2.0
		pill_syn.add_theme_stylebox_override("panel", sb_syn)
		vbox.add_child(pill_syn)

		var lbl_syn := Label.new()
		lbl_syn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl_syn.text = ("✦ " + " + ".join(req_nombres)) if not req_nombres.is_empty() else "✦ FUSIÓN DUAL MÍTICA ✦"
		lbl_syn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_syn.add_theme_font_size_override("font_size", 9)
		lbl_syn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.56))
		pill_syn.add_child(lbl_syn)
	else:
		var fila_rango := HBoxContainer.new()
		fila_rango.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila_rango.alignment = BoxContainer.ALIGNMENT_CENTER
		fila_rango.add_theme_constant_override("separation", 5)
		vbox.add_child(fila_rango)

		for r_i in range(niv_max):
			var pip := Panel.new()
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pip.custom_minimum_size = Vector2(12, 6)
			pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var sb_pip := StyleBoxFlat.new()
			sb_pip.set_corner_radius_all(2)
			if r_i < niv_act:
				sb_pip.bg_color = Color(0.96, 0.78, 0.28, 0.98)
				sb_pip.border_color = Color(1.0, 0.92, 0.58, 1.0)
				sb_pip.set_border_width_all(1)
			elif r_i == niv_act:
				sb_pip.bg_color = col_acento
				sb_pip.border_color = Color.WHITE
				sb_pip.set_border_width_all(1)
			else:
				sb_pip.bg_color = Color(0.10, 0.13, 0.20, 0.90)
				sb_pip.border_color = Color(0.28, 0.34, 0.46, 0.65)
				sb_pip.set_border_width_all(1)
			pip.add_theme_stylebox_override("panel", sb_pip)
			fila_rango.add_child(pip)

		var lbl_niv := Label.new()
		lbl_niv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl_niv.text = ("NUEVO · Nv. 1/%d" % niv_max) if niv_act == 0 else ("Nv. %d → %d/%d" % [niv_act, niv_act + 1, niv_max])
		lbl_niv.add_theme_font_size_override("font_size", 10)
		lbl_niv.add_theme_color_override("font_color", col_texto_rar)
		fila_rango.add_child(lbl_niv)

	# 5. Chips de Estadísticas Clave extraídas automáticamente
	var chips_stats := _extraer_chips_estadisticas(desc, b)
	var fila_chips := HBoxContainer.new()
	fila_chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila_chips.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_chips.add_theme_constant_override("separation", 6)
	vbox.add_child(fila_chips)

	for st_txt in chips_stats:
		var chip_st := PanelContainer.new()
		chip_st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb_st := StyleBoxFlat.new()
		sb_st.bg_color = Color(0.08, 0.12, 0.20, 0.95)
		sb_st.border_color = Color(col_acento.r, col_acento.g, col_acento.b, 0.60)
		sb_st.set_border_width_all(1)
		sb_st.set_corner_radius_all(4)
		sb_st.content_margin_left = 7.0
		sb_st.content_margin_right = 7.0
		sb_st.content_margin_top = 1.0
		sb_st.content_margin_bottom = 1.0
		chip_st.add_theme_stylebox_override("panel", sb_st)
		fila_chips.add_child(chip_st)

		var lbl_st := Label.new()
		lbl_st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl_st.text = st_txt
		lbl_st.add_theme_font_size_override("font_size", 10)
		lbl_st.add_theme_color_override("font_color", Color(0.96, 0.94, 0.84))
		chip_st.add_child(lbl_st)

	# 6. Pozo de Pergamino / Obsidiana con la Descripción Completa
	var desc_well := PanelContainer.new()
	desc_well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_well.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb_well := StyleBoxFlat.new()
	sb_well.bg_color = Color(0.035, 0.045, 0.078, 0.92)
	sb_well.border_color = Color(col_borde.r, col_borde.g, col_borde.b, 0.24)
	sb_well.set_border_width_all(1)
	sb_well.set_corner_radius_all(7)
	sb_well.content_margin_left = 10.0
	sb_well.content_margin_right = 10.0
	sb_well.content_margin_top = 6.0
	sb_well.content_margin_bottom = 6.0
	desc_well.add_theme_stylebox_override("panel", sb_well)
	vbox.add_child(desc_well)

	var lbl_desc := Label.new()
	lbl_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_desc.text = desc
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.add_theme_font_size_override("font_size", 11)
	lbl_desc.add_theme_color_override("font_color", Color(0.86, 0.90, 0.96))
	desc_well.add_child(lbl_desc)

	# 7. Barra de Acción Forjada con Atajo de Teclado [1] [2] [3]
	var cta_bar := PanelContainer.new()
	cta_bar.name = "TarotCTABar"
	cta_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_cta := StyleBoxFlat.new()
	sb_cta.bg_color = Color(col_borde.r * 0.22 + 0.05, col_borde.g * 0.18 + 0.05, col_borde.b * 0.22 + 0.08, 0.96)
	sb_cta.border_color = Color(col_borde.r, col_borde.g, col_borde.b, 0.80)
	sb_cta.set_border_width_all(1)
	sb_cta.set_corner_radius_all(6)
	sb_cta.content_margin_left = 10.0
	sb_cta.content_margin_right = 10.0
	sb_cta.content_margin_top = 4.0
	sb_cta.content_margin_bottom = 4.0
	cta_bar.add_theme_stylebox_override("panel", sb_cta)
	vbox.add_child(cta_bar)

	var cta_row := HBoxContainer.new()
	cta_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cta_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cta_row.add_theme_constant_override("separation", 8)
	cta_bar.add_child(cta_row)

	var key_badge := PanelContainer.new()
	key_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_key := StyleBoxFlat.new()
	sb_key.bg_color = Color(0.04, 0.05, 0.09, 0.95)
	sb_key.border_color = Color(0.92, 0.78, 0.42, 0.90)
	sb_key.set_border_width_all(1)
	sb_key.set_corner_radius_all(4)
	sb_key.content_margin_left = 5.0
	sb_key.content_margin_right = 5.0
	sb_key.content_margin_top = 1.0
	sb_key.content_margin_bottom = 1.0
	key_badge.add_theme_stylebox_override("panel", sb_key)
	cta_row.add_child(key_badge)

	var lbl_key := Label.new()
	lbl_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_key.text = "[%d]" % (indice_carta + 1)
	lbl_key.add_theme_font_size_override("font_size", 10)
	lbl_key.add_theme_color_override("font_color", Color(1.0, 0.88, 0.50))
	key_badge.add_child(lbl_key)

	var texto_cta := "CONSAGRAR FUSIÓN" if es_sinergia else ("MEJORAR RANGO" if niv_act > 0 else "CONSAGRAR BENDICIÓN")
	btn.set_meta("cta_texto_desbloqueado", texto_cta)

	var lbl_cta := Label.new()
	lbl_cta.name = "TarotCTALabel"
	lbl_cta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_cta.text = texto_cta
	lbl_cta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_cta.add_theme_font_size_override("font_size", 11)
	lbl_cta.add_theme_color_override("font_color", Color(0.98, 0.92, 0.74))
	cta_row.add_child(lbl_cta)


func _obtener_etiqueta_rareza(rareza: String, es_sinergia: bool) -> String:
	if es_sinergia or rareza == "MITICA":
		return "SINERGIA MÍTICA"
	match rareza:
		"LEGENDARIA":
			return "LEGENDARIA"
		"EPICA":
			return "ÉPICA"
		"RARA":
			return "RARA"
		_:
			return "COMÚN"


func _aplicar_estilo_carta_bendicion(btn: Button, b: Dictionary) -> void:
	var col_base: Color = b.get("color", Color(0.35, 0.65, 0.95))
	var rareza := str(b.get("rareza", "COMUN"))
	var es_sinergia := bool(b.get("es_sinergia", false))
	var pal := _obtener_paleta_rareza(rareza, es_sinergia, col_base)
	var col_borde: Color = pal["borde"]
	var col_sombra: Color = pal["sombra"]

	var ancho_borde := 2
	var tam_sombra := 14
	if es_sinergia or rareza == "MITICA":
		ancho_borde = 2
		tam_sombra = 22
	elif rareza == "LEGENDARIA" or rareza == "EPICA":
		ancho_borde = 2
		tam_sombra = 18

	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.048, 0.060, 0.098, 0.985)
	sb_normal.border_color = col_borde
	sb_normal.set_border_width_all(ancho_borde)
	sb_normal.border_width_top = ancho_borde + 1
	sb_normal.set_corner_radius_all(12)
	sb_normal.shadow_color = col_sombra
	sb_normal.shadow_size = tam_sombra

	var sb_hover := sb_normal.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.082, 0.102, 0.162, 0.995)
	sb_hover.border_color = col_borde.lightened(0.28)
	sb_hover.shadow_color = Color(col_borde.r, col_borde.g, col_borde.b, 0.55)
	sb_hover.shadow_size = tam_sombra + 8

	var sb_pressed := sb_normal.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = Color(0.11, 0.13, 0.21, 1.0)
	sb_pressed.border_color = Color(1.0, 0.94, 0.72, 1.0)

	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", sb_hover)


func _seleccionar_carta_bendicion(indice: int) -> void:
	if _esta_modal_bendiciones_sellado():
		_registrar_clic_durante_sello(true)
		return
	if modal_mejora != null:
		modal_mejora.visible = false
	if modal_dimmer != null:
		modal_dimmer.visible = false

	if indice >= 0 and indice < _opciones_bendicion_actuales.size():
		var elegida: Dictionary = _opciones_bendicion_actuales[indice]
		var id_bendicion := str(elegida.get("id", ""))
		if jugador != null and jugador.has_method("aplicar_bendicion_roguelike") and id_bendicion != "":
			jugador.aplicar_bendicion_roguelike(id_bendicion)
		elif jugador != null and jugador.has_method("aplicar_mejora"):
			jugador.aplicar_mejora("dano")
	else:
		var tipos := ["dano", "velocidad", "vida"]
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


func _elegir_mejora(tipo: String) -> void:
	if modal_mejora != null:
		modal_mejora.visible = false
	if modal_dimmer != null:
		modal_dimmer.visible = false
	if jugador != null and jugador.has_method("aplicar_mejora"):
		jugador.aplicar_mejora(tipo)
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = false


# ==============================================================================
# SISTEMA MULTI-JEFE (CONTEO Y BARRA PRIORITARIA)
# ==============================================================================

func _limpiar_prefijo_emoji_jefe(nombre: String) -> String:
	var limpio := nombre.strip_edges()
	for pref in ["💀 ", "⚔️ ", "🛡️ ", "🏹 ", "🌋 ", "🔥 "]:
		if limpio.begins_with(pref):
			limpio = limpio.substr(pref.length()).strip_edges()
	return limpio


func mostrar_barra_jefe(nombre: String, max_hp: float, hp_actual: float) -> void:
	if panel_jefe == null:
		return
	var estaba_oculto := not panel_jefe.visible
	panel_jefe.visible = true
	if label_nombre_jefe != null:
		label_nombre_jefe.text = _limpiar_prefijo_emoji_jefe(nombre).to_upper()
	var safe_max := maxf(max_hp, 1.0)
	_jefe_hp_ratio = clampf(hp_actual / safe_max, 0.0, 1.0)
	_jefe_trail_ratio = _jefe_hp_ratio
	_jefe_trail_hold = 0.0
	_jefe_hp_previa = hp_actual
	if bar_vida_jefe != null:
		bar_vida_jefe.max_value = safe_max
		bar_vida_jefe.value = hp_actual
	if label_vida_jefe != null:
		label_vida_jefe.text = "%d / %d HP" % [int(ceil(hp_actual)), int(round(safe_max))]
	if estaba_oculto:
		panel_jefe.scale = Vector2(0.90, 0.90)
		panel_jefe.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(panel_jefe, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(panel_jefe, "modulate:a", 1.0, 0.22)


func actualizar_barra_jefe(hp_actual: float, texto_nombre: String = "") -> void:
	if panel_jefe == null or bar_vida_jefe == null:
		return
	panel_jefe.visible = true
	var safe_max := maxf(bar_vida_jefe.max_value, 1.0)
	_jefe_hp_ratio = clampf(hp_actual / safe_max, 0.0, 1.0)
	if _jefe_hp_previa >= 0.0 and hp_actual < _jefe_hp_previa - 0.5:
		_jefe_trail_hold = 0.18
	elif hp_actual > _jefe_hp_previa:
		_jefe_trail_ratio = maxf(_jefe_trail_ratio, _jefe_hp_ratio)
	_jefe_hp_previa = hp_actual

	bar_vida_jefe.value = hp_actual
	if label_vida_jefe != null:
		label_vida_jefe.text = "%d / %d HP" % [int(ceil(hp_actual)), int(round(safe_max))]
	if texto_nombre != "" and label_nombre_jefe != null:
		label_nombre_jefe.text = _limpiar_prefijo_emoji_jefe(texto_nombre)


func ocultar_barra_jefe() -> void:
	var jefes_vivos := _obtener_jefes_vivos()
	if jefes_vivos.size() > 0:
		var otro = jefes_vivos[0]
		var max_hp := float(otro.vida_maxima) if "vida_maxima" in otro else 500.0
		var hp := float(otro.vida) if "vida" in otro else max_hp
		_habia_jefe_en_grupo = true
		mostrar_barra_jefe(str(otro.name), max_hp, hp)
		return
	_habia_jefe_en_grupo = false
	if panel_jefe != null:
		panel_jefe.visible = false
		_jefe_hp_previa = -1.0


func _obtener_jefes_vivos() -> Array:
	var vivos: Array = []
	for j in get_tree().get_nodes_in_group("jefes"):
		if is_instance_valid(j) and (not ("muerto" in j) or not j.muerto) and ("vida" in j and j.vida > 0.0):
			vivos.append(j)
	return vivos


func _sincronizar_jefe_prioritario() -> void:
	if panel_jefe == null:
		return
	var vivos := _obtener_jefes_vivos()
	if vivos.is_empty():
		if _habia_jefe_en_grupo:
			_habia_jefe_en_grupo = false
			if panel_jefe.visible:
				panel_jefe.visible = false
	else:
		_habia_jefe_en_grupo = true
		if not panel_jefe.visible:
			var j = vivos[0]
			var max_hp := float(j.vida_maxima) if "vida_maxima" in j else 500.0
			var hp := float(j.vida) if "vida" in j else max_hp
			mostrar_barra_jefe(str(j.name), max_hp, hp)


func _input(event: InputEvent) -> void:
	if modal_mejora == null or not modal_mejora.visible:
		return
	if not _esta_modal_bendiciones_sellado():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_registrar_clic_durante_sello(true)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_1, KEY_KP_1, KEY_2, KEY_KP_2, KEY_3, KEY_KP_3, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_registrar_clic_durante_sello(true)
			get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if modal_mejora != null and modal_mejora.visible:
			if event.keycode == KEY_1 or event.keycode == KEY_KP_1:
				_seleccionar_carta_bendicion(0)
				get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
				_seleccionar_carta_bendicion(1)
				get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
				_seleccionar_carta_bendicion(2)
				get_viewport().set_input_as_handled()
				return
		if event.keycode == KEY_F11:
			_toggle_pantalla_completa()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_U or event.keycode == KEY_B:
			_toggle_arbol_poe()
			get_viewport().set_input_as_handled()


func _toggle_arbol_poe() -> void:
	if arbol_poe_instancia == null or not is_instance_valid(arbol_poe_instancia):
		arbol_poe_instancia = ArbolMejorasPoEEscena.instantiate()
		var root := get_tree().root if get_tree() != null else get_parent()
		if root != null:
			root.add_child(arbol_poe_instancia)
		else:
			add_child(arbol_poe_instancia)
	arbol_poe_instancia.toggle()


# ==============================================================================
# ESCALADO MULTI-RESOLUCIÓN Y SELECTOR DE PANTALLA (16:9 / 16:10 / 21:9 / 4:3)
# ==============================================================================

func _conectar_escalado_resolucion() -> void:
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_ajustar_layout_resolucion):
		vp.size_changed.connect(_ajustar_layout_resolucion)


func _calcular_escala_modal_mejora() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return Vector2.ONE
	var rect_vis := vp.get_visible_rect().size
	if rect_vis.x <= 1.0 or rect_vis.y <= 1.0:
		return Vector2.ONE
	var max_w := rect_vis.x - 44.0
	var max_h := rect_vis.y - 118.0
	var factor := minf(1.0, minf(max_w / 936.0, max_h / 476.0))
	factor = clampf(factor, 0.72, 1.08)
	return Vector2(factor, factor)


func _ajustar_layout_resolucion() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var vis_size := vp.get_visible_rect().size
	if vis_size.x <= 1.0 or vis_size.y <= 1.0:
		return

	# Ajustar escala y centrado de ModalMejora según el aspect ratio actual
	if modal_mejora != null:
		modal_mejora.pivot_offset = modal_mejora.size * 0.5
		if modal_mejora.visible:
			modal_mejora.scale = _calcular_escala_modal_mejora()

	# Ajustar barra superior en resoluciones estrechas o ultrawide
	var top_bar := get_node_or_null("Control/MarginTop") as Control
	if top_bar != null:
		var margen_lateral := clampf((vis_size.x - 1152.0) * 0.18, 12.0, 140.0)
		top_bar.offset_left = margen_lateral
		top_bar.offset_right = -margen_lateral

	_actualizar_texto_boton_resolucion()


func _aplicar_resolucion_ventana(tam: Vector2i) -> void:
	var modo_actual := DisplayServer.window_get_mode()
	if modo_actual == DisplayServer.WINDOW_MODE_FULLSCREEN or modo_actual == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(tam)
	var pantalla := DisplayServer.window_get_current_screen()
	var rect_usable := DisplayServer.screen_get_usable_rect(pantalla)
	if rect_usable.size.x >= tam.x and rect_usable.size.y >= tam.y:
		var pos_centrada := rect_usable.position + (rect_usable.size - tam) / 2
		DisplayServer.window_set_position(pos_centrada)
	if _panel_resoluciones != null:
		_panel_resoluciones.visible = false
	call_deferred("_ajustar_layout_resolucion")


func _toggle_pantalla_completa() -> void:
	var modo := DisplayServer.window_get_mode()
	if modo == DisplayServer.WINDOW_MODE_FULLSCREEN or modo == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if _panel_resoluciones != null:
		_panel_resoluciones.visible = false
	call_deferred("_ajustar_layout_resolucion")


func _actualizar_texto_boton_resolucion() -> void:
	if _btn_resolucion_ref == null or not is_instance_valid(_btn_resolucion_ref):
		return
	var modo := DisplayServer.window_get_mode()
	if modo == DisplayServer.WINDOW_MODE_FULLSCREEN or modo == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		_btn_resolucion_ref.text = "Pantalla: Full [F11]"
	else:
		var win_sz := DisplayServer.window_get_size()
		_btn_resolucion_ref.text = "%dx%d ▾" % [win_sz.x, win_sz.y]


# ==============================================================================
# DRAWER PLEGABLE DE JEFES DE PRUEBA Y SELECTOR DE RESOLUCIÓN
# ==============================================================================

func _crear_boton_test_parca() -> void:
	var cont := VBoxContainer.new()
	cont.name = "ContenedorTestJefes"
	cont.anchor_left = 1.0
	cont.anchor_top = 1.0
	cont.anchor_right = 1.0
	cont.anchor_bottom = 1.0
	cont.offset_left = -280.0
	cont.offset_top = -275.0
	cont.offset_right = -18.0
	cont.offset_bottom = -14.0
	cont.alignment = BoxContainer.ALIGNMENT_END
	cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cont.add_theme_constant_override("separation", 5)

	_panel_resoluciones = VBoxContainer.new()
	_panel_resoluciones.name = "ListaResoluciones"
	_panel_resoluciones.visible = false
	_panel_resoluciones.add_theme_constant_override("separation", 3)

	var btn_full := Button.new()
	btn_full.text = "⛶ Pantalla Completa / Ventana (F11)"
	btn_full.focus_mode = Control.FOCUS_NONE
	_aplicar_estilo_boton(btn_full, Color(0.92, 0.74, 0.30))
	btn_full.pressed.connect(func(): _toggle_pantalla_completa())
	_panel_resoluciones.add_child(btn_full)

	for res_entry in RESOLUCIONES_DISPONIBLES:
		var b_res := Button.new()
		var etiqueta_res: String = String(res_entry["label"])
		var tam_res: Vector2i = res_entry["size"]
		b_res.text = "◈ " + etiqueta_res
		b_res.focus_mode = Control.FOCUS_NONE
		_aplicar_estilo_boton(b_res, Color(0.45, 0.72, 0.94))
		b_res.pressed.connect(func(): _aplicar_resolucion_ventana(tam_res))
		_panel_resoluciones.add_child(b_res)

	cont.add_child(_panel_resoluciones)

	_panel_test_jefes = VBoxContainer.new()
	_panel_test_jefes.name = "ListaJefesTest"
	_panel_test_jefes.visible = false
	_panel_test_jefes.add_theme_constant_override("separation", 4)

	var jefes := [
		{"id": "centurion", "label": "W3 · Centurión (420 HP)", "color": Color(0.82, 0.52, 0.20)},
		{"id": "gladiador", "label": "W6 · Gladiador (950 HP)", "color": Color(0.90, 0.58, 0.22)},
		{"id": "maestra", "label": "W9 · Maestra (1800 HP)", "color": Color(0.85, 0.25, 0.62)},
		{"id": "coloso", "label": "W12 · Coloso (3200 HP)", "color": Color(0.95, 0.35, 0.14)},
		{"id": "parca", "label": "FINAL · La Parca Roja", "color": Color(0.92, 0.18, 0.26)},
	]

	for j in jefes:
		var b_jefe := Button.new()
		b_jefe.text = j["label"]
		b_jefe.focus_mode = Control.FOCUS_NONE
		_aplicar_estilo_boton(b_jefe, j["color"])
		var j_id: String = j["id"]
		b_jefe.pressed.connect(func(): _invocar_jefe_test(j_id))
		_panel_test_jefes.add_child(b_jefe)

	cont.add_child(_panel_test_jefes)

	var hbox_botones := HBoxContainer.new()
	hbox_botones.alignment = BoxContainer.ALIGNMENT_END
	hbox_botones.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox_botones.add_theme_constant_override("separation", 6)

	var btn_res := Button.new()
	btn_res.name = "BtnResolucion"
	btn_res.text = "1280x720 ▾"
	btn_res.tooltip_text = "Cambiar resolución de ventana o Pantalla Completa (F11)"
	btn_res.focus_mode = Control.FOCUS_NONE
	_aplicar_estilo_boton(btn_res, Color(0.45, 0.72, 0.94))
	btn_res.pressed.connect(func():
		_panel_resoluciones.visible = not _panel_resoluciones.visible
		if _panel_resoluciones.visible and _panel_test_jefes != null:
			_panel_test_jefes.visible = false
	)
	_btn_resolucion_ref = btn_res
	hbox_botones.add_child(btn_res)

	var btn_toggle := Button.new()
	btn_toggle.name = "BtnToggleJefes"
	btn_toggle.text = "Arena Sandbox +"
	btn_toggle.icon = TEX_ICO_SKULL
	btn_toggle.focus_mode = Control.FOCUS_NONE
	_aplicar_estilo_boton(btn_toggle, Color(0.75, 0.58, 0.28))
	btn_toggle.pressed.connect(func():
		_panel_test_jefes.visible = not _panel_test_jefes.visible
		if _panel_test_jefes.visible and _panel_resoluciones != null:
			_panel_resoluciones.visible = false
		btn_toggle.text = "Arena Sandbox -" if _panel_test_jefes.visible else "Arena Sandbox +"
	)
	hbox_botones.add_child(btn_toggle)

	cont.add_child(hbox_botones)
	$Control.add_child(cont)
	if modal_dimmer != null:
		$Control.move_child(cont, modal_dimmer.get_index())
	_actualizar_texto_boton_resolucion()


func _aplicar_estilo_boton(btn: Button, color_acento: Color) -> void:
	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = Color(0.055, 0.065, 0.098, 0.92)
	s_normal.border_color = color_acento
	s_normal.set_border_width_all(1)
	s_normal.set_corner_radius_all(6)
	s_normal.content_margin_left = 10.0
	s_normal.content_margin_right = 10.0
	s_normal.content_margin_top = 4.0
	s_normal.content_margin_bottom = 4.0

	var s_hover := s_normal.duplicate() as StyleBoxFlat
	s_hover.bg_color = Color(0.14, 0.08, 0.10, 0.96)
	s_hover.border_color = color_acento.lightened(0.28)

	btn.add_theme_stylebox_override("normal", s_normal)
	btn.add_theme_stylebox_override("hover", s_hover)
	btn.add_theme_stylebox_override("pressed", s_hover)
	btn.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	btn.add_theme_font_size_override("font_size", 11)


func _invocar_jefe_test(tipo: String) -> void:
	print(">>> [HUD] Invocando Jefe de Prueba: ", tipo, " <<<")

	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")

	if jugador != null and jugador.has_method("equipar_build_test_parca"):
		jugador.equipar_build_test_parca()

	for e in get_tree().get_nodes_in_group("enemigos"):
		if is_instance_valid(e) and not e.is_in_group("jefes"):
			e.queue_free()

	var escena_path := ""
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
		var scn := load(escena_path) as PackedScene
		if scn != null:
			var inst: Node = scn.instantiate()
			get_tree().current_scene.add_child(inst)
			if inst is Node3D and jugador != null:
				inst.global_position = jugador.global_position + Vector3(0.0, 0.0, -7.0)
				if inst.has_method("look_at"):
					inst.look_at(jugador.global_position, Vector3.UP)
			print(">>> [HUD] Jefe invocado con éxito en arena: ", tipo)
