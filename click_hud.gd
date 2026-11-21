extends CanvasLayer

# ClickHUD - HUD esencial de combate (Personaje, Nivel, Vidas, Vida, XP, Oleada, Oro)
# y selector de Cartas Tarot al subir de nivel.

const MALLAS_AVATAR := {
	"Novato": preload("res://personaje/player_rookie.glb"),
	"Recluta del Coliseo": preload("res://personaje/player_rookie.glb"),
	"Guerrero": preload("res://personaje/player_warrior.glb"),
	"Murmillo": preload("res://personaje/player_warrior.glb"),
	"Cazador": preload("res://personaje/player_archer.glb"),
	"Arquero": preload("res://personaje/player_archer.glb"),
	"Sagittario": preload("res://personaje/player_archer.glb"),
	"Mago": preload("res://personaje/player_mage.glb"),
	"Arúspice": preload("res://personaje/player_mage.glb"),

	# Tier 2 - Mejora 1
	"Secutor Radiante": preload("res://personaje/player_warrior.glb"),
	"Provocator Sangriento": preload("res://personaje/player_warrior.glb"),
	"Velites Balístico": preload("res://personaje/player_archer.glb"),
	"Dimachaerus Espectral": preload("res://personaje/player_archer.glb"),
	"Taumaturgo del Vacío": preload("res://personaje/player_mage.glb"),
	"Flamen Volcánico": preload("res://personaje/player_mage.glb"),
	"Custodio del Núcleo": preload("res://personaje/player_warrior.glb"),

	# Tier 3 - Mejora 2
	"Paladín del Sol Invictus": preload("res://personaje/player_warrior.glb"),
	"Campeón Augusto de Sangre": preload("res://personaje/player_warrior.glb"),
	"Centurión Balístico Astral": preload("res://personaje/player_archer.glb"),
	"Sombra del Anfiteatro": preload("res://personaje/player_archer.glb"),
	"Pontífice del Vacío Estelar": preload("res://personaje/player_mage.glb"),
	"Señor del Magma Imperial": preload("res://personaje/player_mage.glb"),
	"Titán Supremo del Núcleo": preload("res://personaje/player_warrior.glb"),

	# Retrocompatibilidad
	"Paladín Solar": preload("res://personaje/player_warrior.glb"),
	"Berserker Sangriento": preload("res://personaje/player_warrior.glb"),
	"Francotirador Astral": preload("res://personaje/player_archer.glb"),
	"Maestro de Sombras": preload("res://personaje/player_archer.glb"),
	"Archimago del Vacío": preload("res://personaje/player_mage.glb"),
	"Piromante Cataclísmico": preload("res://personaje/player_mage.glb"),
	"Avatar del Núcleo": preload("res://personaje/player_warrior.glb"),
}

const WEAPON_KEYS := {
	"Novato": "Novato",
	"Recluta del Coliseo": "Novato",
	"Guerrero": "Guerrero",
	"Murmillo": "Guerrero",
	"Cazador": "Cazador",
	"Arquero": "Cazador",
	"Sagittario": "Cazador",
	"Mago": "Mago",
	"Arúspice": "Mago",
	"Secutor Radiante": "Guerrero",
	"Provocator Sangriento": "Guerrero",
	"Velites Balístico": "Cazador",
	"Dimachaerus Espectral": "Cazador",
	"Taumaturgo del Vacío": "Mago",
	"Flamen Volcánico": "Mago",
	"Custodio del Núcleo": "Novato",
	"Paladín del Sol Invictus": "Guerrero",
	"Campeón Augusto de Sangre": "Guerrero",
	"Centurión Balístico Astral": "Cazador",
	"Sombra del Anfiteatro": "Cazador",
	"Pontífice del Vacío Estelar": "Mago",
	"Señor del Magma Imperial": "Mago",
	"Titán Supremo del Núcleo": "Novato",
	"Paladín Solar": "Guerrero",
	"Berserker Sangriento": "Guerrero",
	"Francotirador Astral": "Cazador",
	"Maestro de Sombras": "Cazador",
	"Archimago del Vacío": "Mago",
	"Piromante Cataclísmico": "Mago",
	"Avatar del Núcleo": "Novato",
}

const CLASS_ACCENTS := {
	"Novato": Color(0.231, 0.902, 0.463),
	"Recluta del Coliseo": Color(0.231, 0.902, 0.463),
	"Guerrero": Color(0.95, 0.25, 0.22),
	"Murmillo": Color(0.95, 0.25, 0.22),
	"Cazador": Color(0.95, 0.44, 0.08),
	"Arquero": Color(0.95, 0.44, 0.08),
	"Sagittario": Color(0.18, 0.88, 0.76),
	"Mago": Color(0.55, 0.35, 1.00),
	"Arúspice": Color(0.28, 0.58, 1.00),
	"Secutor Radiante": Color(1.00, 0.82, 0.20),
	"Provocator Sangriento": Color(0.92, 0.12, 0.18),
	"Velites Balístico": Color(0.15, 0.92, 1.00),
	"Dimachaerus Espectral": Color(0.72, 0.25, 1.00),
	"Taumaturgo del Vacío": Color(0.55, 0.18, 0.95),
	"Flamen Volcánico": Color(1.00, 0.45, 0.10),
	"Custodio del Núcleo": Color(0.22, 0.95, 0.85),
	"Paladín del Sol Invictus": Color(1.00, 0.88, 0.25),
	"Campeón Augusto de Sangre": Color(0.95, 0.10, 0.15),
	"Centurión Balístico Astral": Color(0.20, 0.95, 1.00),
	"Sombra del Anfiteatro": Color(0.78, 0.25, 1.00),
	"Pontífice del Vacío Estelar": Color(0.60, 0.20, 1.00),
	"Señor del Magma Imperial": Color(1.00, 0.40, 0.05),
	"Titán Supremo del Núcleo": Color(0.25, 0.98, 0.90),
	"Paladín Solar": Color(1.00, 0.82, 0.20),
	"Berserker Sangriento": Color(0.95, 0.15, 0.15),
	"Francotirador Astral": Color(0.22, 0.78, 1.00),
	"Maestro de Sombras": Color(0.48, 0.20, 0.75),
	"Archimago del Vacío": Color(0.95, 0.20, 0.70),
	"Piromante Cataclísmico": Color(1.00, 0.42, 0.10),
	"Avatar del Núcleo": Color(0.25, 0.95, 1.00),
}

const TEX_CORAZON_LLENO := preload("res://ui_assets/hud_gem_heart.png")
const TEX_CORAZON_VACIO := preload("res://ui_assets/hud_gem_heart_empty.png")
const TEX_CORNER_GOTHIC := preload("res://ui_assets/hud_corner_gothic.png")
const TEX_ICO_CLASS := preload("res://ui_assets/icon_class_hades.svg")
const TEX_ICO_CLICKS := preload("res://ui_assets/icon_clicks_hades.svg")
const TEX_ICO_FEVER := preload("res://ui_assets/icon_fever_hades.svg")
const TEX_ICO_GOLD := preload("res://ui_assets/icon_gold_hades.svg")
const TEX_ICO_LUCK := preload("res://ui_assets/icon_luck_hades.svg")
const TEX_ICO_PACTO := preload("res://ui_assets/icon_pacto_hades.svg")
const TEX_ICO_SHIELD := preload("res://ui_assets/icon_shield_hades.svg")
const TEX_ICO_BOLT := preload("res://ui_assets/icon_bolt_hades.svg")
const TEX_ICO_DAGGERS := preload("res://ui_assets/icon_daggers_hades.svg")
const TEX_ICO_FROST := preload("res://ui_assets/icon_frost_hades.svg")
const TEX_ICO_BLOOD := preload("res://ui_assets/icon_blood_hades.svg")
const TEX_ICO_PRISM := preload("res://ui_assets/icon_prism_hades.svg")
const TEX_ICO_SYNERGY := preload("res://ui_assets/icon_synergy_hades.svg")

const SELLO_GRACIA_INICIAL_MS: int = 850
const SELLO_REBOTE_SPAM_MS: int = 380
const SELLO_MAX_TOTAL_MS: int = 2200

const CatalogoBendiciones := preload("res://catalogo_bendiciones.gd")
const AnimadorEntidad := preload("res://animador_entidad.gd")
const MetaprogresoManager := preload("res://metaprogreso_manager.gd")

# --- Referencias Top Bar ---
@onready var overlay_colapso: ColorRect = $Control/OverlayColapso
@onready var barra_superior: Panel = $Control/BarraSuperior
@onready var wing_left: ColorRect = $Control/BarraSuperior/WingsBackdrop/WingLeft
@onready var wing_center: ColorRect = $Control/BarraSuperior/WingsBackdrop/WingCenter
@onready var wing_right: ColorRect = $Control/BarraSuperior/WingsBackdrop/WingRight
@onready var cluster_heroe: HBoxContainer = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe
@onready var spacer_izq: Control = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/SpacerIzq
@onready var contenedor_centro: VBoxContainer = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorCentro
@onready var spacer_der: Control = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/SpacerDer
@onready var contenedor_economia: VBoxContainer = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorEconomia

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

@onready var bar_vida: ProgressBar = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HBoxVidaRow/BarVida
@onready var bar_vida_shader: ColorRect = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HBoxVidaRow/BarVida/BarVidaShader
@onready var label_vida: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HBoxVidaRow/BarVida/HBoxVidaTexto/LabelVida
@onready var badge_escudo_hp: PanelContainer = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HBoxVidaRow/BadgeEscudoHP
@onready var icono_escudo_hp: TextureRect = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HBoxVidaRow/BadgeEscudoHP/HBoxEscudo/IconoEscudoHP
@onready var label_escudo_hp: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HBoxVidaRow/BadgeEscudoHP/HBoxEscudo/LabelEscudoHP
@onready var bar_xp: ProgressBar = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HBoxXPHeroe/BarXP
@onready var label_xp: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ClusterHeroe/ContenedorHeroe/HBoxXPHeroe/LabelXP

@onready var icono_oleada: TextureRect = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorCentro/HBoxWaveHeader/IconoOleada
@onready var label_oleada: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorCentro/HBoxWaveHeader/LabelOleada

@onready var label_oro: Label = $Control/BarraSuperior/MarginSuperior/HBoxSuperior/ContenedorEconomia/HBoxOro/LabelOro

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

var _ultimo_txt_oleada: String = ""
var _avatar_reloj_idle: float = 0.0
var _avatar_reloj_redraw: float = 0.06
var _reloj_jefe_sync: float = 0.0
var _ultimo_escudo_txt: String = ""
var _ultimo_escudo_vis: int = -1

var _modal_apertura_msec: int = 0
var _modal_bloqueado_hasta_msec: int = 0
var _modal_duracion_sello_actual_ms: int = SELLO_GRACIA_INICIAL_MS
var _modal_sello_desbloqueado_visual: bool = false
var _modal_clic_bloqueado_flash_hasta_msec: int = 0
var _banner_sello_tarot: PanelContainer = null
var _sello_fill_rect: ColorRect = null
var _lbl_sello_tarot: Label = null
var _sb_banner_sello: StyleBoxFlat = null

var _sb_panel_jefe: StyleBoxFlat = null
var _pill_estado_jefe: PanelContainer = null
var _sb_pill_estado_jefe: StyleBoxFlat = null
var _lbl_estado_jefe: Label = null
var _jefe_estado_actual: String = "NORMAL"
var _tw_panel_jefe_pulso: Tween = null
var _contenedor_stagger_jefe: PanelContainer = null
var bar_stagger_jefe: ProgressBar = null
var _lbl_stagger_jefe: Label = null


func _obtener_fortuna_manager() -> Node:
	return get_node_or_null("/root/FortunaManager")


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
	_conectar_sync_alas()

	if btn_opc1 != null:
		btn_opc1.pressed.connect(func(): _seleccionar_carta_bendicion(0))
	if btn_opc2 != null:
		btn_opc2.pressed.connect(func(): _seleccionar_carta_bendicion(1))
	if btn_opc3 != null:
		btn_opc3.pressed.connect(func(): _seleccionar_carta_bendicion(2))

	_crear_banner_y_chip_evolucion()
	_crear_modales_dominio4()
	_conectar_jugador()
	_conectar_boton_movil()
	call_deferred("_conectar_boton_movil")
	call_deferred("_conectar_evolucion_manager")
	call_deferred("_bootstrap_domain4_managers")
	call_deferred("_ajustar_layout_resolucion")
	call_deferred("_sync_wings_geometry")


func _conectar_sync_alas() -> void:
	for nodo in [barra_superior, cluster_heroe, contenedor_centro, contenedor_economia, bar_vida, bar_vida_jefe]:
		if nodo != null and not nodo.resized.is_connected(_sync_wings_geometry):
			nodo.resized.connect(_sync_wings_geometry)


func _sync_wings_geometry() -> void:
	if barra_superior != null and cluster_heroe != null and contenedor_centro != null and contenedor_economia != null:
		var bar_w := barra_superior.size.x
		var bar_h := barra_superior.size.y
		if bar_w > 100.0 and bar_h > 20.0:
			# Centrar exactamente ContenedorCentro respecto al centro de BarraSuperior
			if spacer_izq != null and spacer_der != null:
				var h_izq := cluster_heroe.size.x + 8.0
				var e_der := contenedor_economia.size.x + 14.0
				var c_w := contenedor_centro.size.x
				var gap_l := maxf(8.0, (bar_w - c_w) * 0.5 - h_izq)
				var gap_r := maxf(8.0, (bar_w - c_w) * 0.5 - e_der)
				var tot_gap := maxf(gap_l + gap_r, 1.0)
				var r_izq := clampf(gap_l / tot_gap, 0.05, 0.95)
				var r_der := clampf(gap_r / tot_gap, 0.05, 0.95)
				if absf(spacer_izq.size_flags_stretch_ratio - r_izq) > 0.01 or absf(spacer_der.size_flags_stretch_ratio - r_der) > 0.01:
					spacer_izq.size_flags_stretch_ratio = r_izq
					spacer_der.size_flags_stretch_ratio = r_der
					call_deferred("_sync_wings_geometry")

			var bx := barra_superior.global_position.x

			var hero_left := cluster_heroe.global_position.x - bx
			var hero_right := hero_left + cluster_heroe.size.x
			var cen_left := contenedor_centro.global_position.x - bx
			var cen_right := cen_left + contenedor_centro.size.x
			var econ_left := contenedor_economia.global_position.x - bx

			# Ala izquierda abraza estrictamente ClusterHeroe
			var wl_x := hero_left + 40.0
			var wl_r := hero_right + 28.0
			if wing_left != null:
				wing_left.position = Vector2(wl_x, -6.0)
				wing_left.size = Vector2(maxf(wl_r - wl_x, 180.0), bar_h + 12.0)
				if wing_left.material is ShaderMaterial:
					(wing_left.material as ShaderMaterial).set_shader_parameter("panel_size", wing_left.size)

			# Placa superior central compacta para la oleada
			var wc_x := cen_left - 26.0
			var wc_r := cen_right + 26.0
			if wing_center != null:
				wing_center.position = Vector2(wc_x, -4.0)
				wing_center.size = Vector2(maxf(wc_r - wc_x, 160.0), 58.0)
				if wing_center.material is ShaderMaterial:
					(wing_center.material as ShaderMaterial).set_shader_parameter("panel_size", wing_center.size)

			# Placa superior derecha compacta para el oro
			var wr_x := econ_left - 28.0
			var wr_r := bar_w + 6.0
			if wing_right != null:
				wing_right.position = Vector2(wr_x, -4.0)
				wing_right.size = Vector2(maxf(wr_r - wr_x, 120.0), 58.0)
				if wing_right.material is ShaderMaterial:
					(wing_right.material as ShaderMaterial).set_shader_parameter("panel_size", wing_right.size)

	if bar_vida != null and bar_vida_shader != null and bar_vida_shader.material is ShaderMaterial:
		if bar_vida.size.x > 10.0 and bar_vida.size.y > 4.0:
			(bar_vida_shader.material as ShaderMaterial).set_shader_parameter("bar_size", bar_vida.size)

	if bar_vida_jefe != null and bar_jefe_shader != null and bar_jefe_shader.material is ShaderMaterial:
		if bar_vida_jefe.size.x > 10.0 and bar_vida_jefe.size.y > 4.0:
			(bar_jefe_shader.material as ShaderMaterial).set_shader_parameter("bar_size", bar_vida_jefe.size)


func _inicializar_estilos_dinamicos() -> void:
	pass

	_inicializar_estilo_panel_jefe()


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
	if jugador.has_signal("bendicion_adquirida") and not jugador.bendicion_adquirida.is_connected(_on_bendicion_adquirida):
		jugador.bendicion_adquirida.connect(_on_bendicion_adquirida)

	_on_stats_actualizadas(jugador.vida, jugador.vida_maxima, jugador.xp, jugador.xp_siguiente_nivel, jugador.nivel, jugador.oro, jugador.bajas)
	if "clics_disponibles" in jugador:
		_on_economia_actualizada(int(jugador.oro), int(jugador.clics_disponibles), int(jugador.clics_totales))
	_conectar_evolucion_manager()


func _calibrar_avatar() -> void:
	if camara_avatar != null:
		camara_avatar.fov = 26.0
		camara_avatar.look_at_from_position(Vector3(0.050, 0.595, 0.560), Vector3(0.0, 0.575, 0.005), Vector3.UP)
	if modelo_avatar_nodo != null:
		_clase_actual_avatar = "Novato"
		modelo_avatar_nodo.rotation_degrees.y = 20.0
		_preparar_modelo_retrato(modelo_avatar_nodo, "Novato")


func _preparar_modelo_retrato(modelo: Node3D, nombre_clase: String) -> void:
	if modelo == null:
		return
	var weapon_key: String = String(WEAPON_KEYS.get(nombre_clase, "Novato"))
	AnimadorEntidad.equipar_armas_en_esqueleto(modelo, weapon_key, false)
	AnimadorEntidad.estilizar_entidad_visual(modelo, true)
	AnimadorEntidad.aplicar_identidad_visual_clase(modelo, nombre_clase, false)
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
		luz_contorno.light_energy = 1.65 if not (nombre_clase in ["Novato", "Recluta del Coliseo"]) else 1.45
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

	_actualizar_oleada_ui()
	_actualizar_overlays_shader(delta)
	_sincronizar_escudo_live()
	_animar_retrato_sutil(delta)
	_reloj_jefe_sync += delta
	if _reloj_jefe_sync >= 0.1:
		_reloj_jefe_sync = 0.0
		_sincronizar_jefe_prioritario()


func _actualizar_oleada_ui() -> void:
	if label_oleada != null:
		var txt_o := "EN ESPERA" if clicks_boton == 0 else ("OLEADA %d" % oleada)
		if txt_o != _ultimo_txt_oleada:
			_ultimo_txt_oleada = txt_o
			label_oleada.text = txt_o
			if icono_oleada != null:
				icono_oleada.visible = clicks_boton > 0
				icono_oleada.modulate = Color(0.969, 0.808, 0.408, 1.0)


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
		m.set_shader_parameter("shield_ratio", 0.0 if badge_escudo_hp != null else _shield_ratio_actual)

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


func _sincronizar_escudo_live() -> void:
	if jugador == null or not is_instance_valid(jugador):
		return
	# Sync escudo live (p. ej. recarga pasiva o golpe sin re-emitir señal instantánea)
	if "escudo_almas" in jugador and "vida_maxima" in jugador and float(jugador.vida_maxima) > 0.0:
		var esc := float(jugador.escudo_almas)
		_shield_ratio_actual = clampf(esc / float(jugador.vida_maxima), 0.0, 1.0)
		var esc_vis: int = 1 if esc > 0.5 else 0
		if esc_vis != _ultimo_escudo_vis:
			_ultimo_escudo_vis = esc_vis
			if badge_escudo_hp != null:
				badge_escudo_hp.visible = esc_vis == 1
			if icono_escudo_hp != null:
				icono_escudo_hp.visible = esc_vis == 1
			if label_escudo_hp != null:
				label_escudo_hp.visible = esc_vis == 1
		if esc_vis == 1 and label_escudo_hp != null:
			var esc_txt := "+%d" % int(round(esc))
			if esc_txt != _ultimo_escudo_txt:
				_ultimo_escudo_txt = esc_txt
				label_escudo_hp.text = esc_txt


func _animar_retrato_sutil(delta: float) -> void:
	if modelo_avatar_nodo == null or not is_instance_valid(modelo_avatar_nodo):
		return
	_avatar_reloj_idle += delta
	_avatar_reloj_redraw += delta
	if _avatar_reloj_redraw >= 0.055:
		_avatar_reloj_redraw = 0.0
		modelo_avatar_nodo.rotation_degrees.y = 20.0 + sin(_avatar_reloj_idle * 0.9) * 3.0
		if subviewport_avatar != null:
			subviewport_avatar.render_target_update_mode = SubViewport.UPDATE_ONCE


# --- Señales del Jugador ---

func _on_stats_actualizadas(vida: float, max_vida: float, xp: int, xp_sig: int, nivel: int, oro: int, _bajas: int = 0) -> void:
	if jugador != null and "clase" in jugador:
		var nombre_clase := str(jugador.clase)
		if label_clase != null:
			label_clase.text = nombre_clase
		_actualizar_avatar_clase(nombre_clase)

	if label_nivel != null:
		var txt_nv := "Nv. %d" % nivel
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
		label_vida.text = "%s / %s HP" % [_formatear_numero(int(ceil(vida))), _formatear_numero(int(round(safe_max)))]

	var esc: float = float(jugador.escudo_almas) if (jugador != null and "escudo_almas" in jugador) else 0.0
	_shield_ratio_actual = clampf(esc / safe_max, 0.0, 1.0)
	if badge_escudo_hp != null:
		badge_escudo_hp.visible = esc > 0.5
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
		label_xp.text = "%s / %s XP" % [_formatear_numero(xp), _formatear_numero(xp_sig)]

	if label_oro != null:
		label_oro.text = _formatear_numero(oro)


func _on_economia_actualizada(oro_cnt: int, _clics_disp: int, _clics_tot: int) -> void:
	if label_oro != null:
		label_oro.text = _formatear_numero(oro_cnt)


func _on_bendicion_adquirida(_id_bendicion: String, _nivel_actual: int) -> void:
	if avatar_frame != null:
		var tw := create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(avatar_frame, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(avatar_frame, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_CUBIC)


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
				if modelo_avatar_nodo.get_parent() != null:
					modelo_avatar_nodo.get_parent().remove_child(modelo_avatar_nodo)
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
# API DE COMPATIBILIDAD PARA PACTO DE MARTE (NO-OP SIN UI EN HUD)
# ==============================================================================

func registrar_pacto_marte(_duracion: float = 60.0) -> void:
	pass


func actualizar_pacto_marte(_restante: float) -> void:
	pass


func ocultar_pacto_marte() -> void:
	pass


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
	var fm := _obtener_fortuna_manager()
	if fm != null and "suerte_total" in fm:
		suerte_actual = float(fm.suerte_total)

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
		var token: String = str((m as RegExMatch).get_string())
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
		if str(elegida.get("categoria", "")) == "corrupta" and jugador != null and jugador.has_method("aplicar_bendicion_corrupta") and id_bendicion != "":
			jugador.aplicar_bendicion_corrupta(id_bendicion)
		elif jugador != null and jugador.has_method("aplicar_bendicion_roguelike") and id_bendicion != "":
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


func _inicializar_estilo_panel_jefe() -> void:
	if panel_jefe == null:
		return
	var sb_j := panel_jefe.get_theme_stylebox("panel")
	if sb_j is StyleBoxFlat:
		_sb_panel_jefe = sb_j.duplicate() as StyleBoxFlat
		panel_jefe.add_theme_stylebox_override("panel", _sb_panel_jefe)
	if bar_jefe_shader != null and bar_jefe_shader.material is ShaderMaterial:
		bar_jefe_shader.material = (bar_jefe_shader.material as ShaderMaterial).duplicate()

	var vbox_jefe := panel_jefe.get_node_or_null("VBoxJefe")
	if vbox_jefe != null and _pill_estado_jefe == null:
		_pill_estado_jefe = PanelContainer.new()
		_pill_estado_jefe.name = "PillEstadoJefe"
		_pill_estado_jefe.visible = false
		_pill_estado_jefe.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_pill_estado_jefe.mouse_filter = Control.MOUSE_FILTER_IGNORE

		_sb_pill_estado_jefe = StyleBoxFlat.new()
		_sb_pill_estado_jefe.bg_color = Color(0.16, 0.10, 0.03, 0.94)
		_sb_pill_estado_jefe.set_border_width_all(1)
		_sb_pill_estado_jefe.border_color = Color(1.0, 0.84, 0.24, 0.96)
		_sb_pill_estado_jefe.set_corner_radius_all(5)
		_sb_pill_estado_jefe.content_margin_left = 10.0
		_sb_pill_estado_jefe.content_margin_right = 10.0
		_sb_pill_estado_jefe.content_margin_top = 1.0
		_sb_pill_estado_jefe.content_margin_bottom = 1.0
		_pill_estado_jefe.add_theme_stylebox_override("panel", _sb_pill_estado_jefe)

		_lbl_estado_jefe = Label.new()
		_lbl_estado_jefe.name = "LabelEstadoJefe"
		_lbl_estado_jefe.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lbl_estado_jefe.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_lbl_estado_jefe.add_theme_font_size_override("font_size", 10)
		_lbl_estado_jefe.add_theme_color_override("font_outline_color", Color(0.06, 0.03, 0.02, 1.0))
		_lbl_estado_jefe.add_theme_constant_override("outline_size", 2)
		_lbl_estado_jefe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pill_estado_jefe.add_child(_lbl_estado_jefe)

		vbox_jefe.add_child(_pill_estado_jefe)

	if vbox_jefe != null and _contenedor_stagger_jefe == null:
		_contenedor_stagger_jefe = PanelContainer.new()
		_contenedor_stagger_jefe.name = "ContenedorStaggerJefe"
		_contenedor_stagger_jefe.visible = false
		_contenedor_stagger_jefe.custom_minimum_size = Vector2(0.0, 20.0)
		_contenedor_stagger_jefe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_contenedor_stagger_jefe.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var sb_stag_box := StyleBoxFlat.new()
		sb_stag_box.bg_color = Color(0.11, 0.06, 0.02, 0.96)
		sb_stag_box.set_border_width_all(1)
		sb_stag_box.border_color = Color(1.0, 0.78, 0.22, 0.96)
		sb_stag_box.set_corner_radius_all(4)
		sb_stag_box.shadow_color = Color(1.0, 0.65, 0.12, 0.45)
		sb_stag_box.shadow_size = 6
		_contenedor_stagger_jefe.add_theme_stylebox_override("panel", sb_stag_box)

		bar_stagger_jefe = ProgressBar.new()
		bar_stagger_jefe.name = "BarStaggerJefe"
		bar_stagger_jefe.min_value = 0.0
		bar_stagger_jefe.max_value = 100.0
		bar_stagger_jefe.value = 0.0
		bar_stagger_jefe.show_percentage = false
		bar_stagger_jefe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar_stagger_jefe.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bar_stagger_jefe.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var sb_stag_bg := StyleBoxFlat.new()
		sb_stag_bg.bg_color = Color(0.14, 0.08, 0.03, 0.95)
		sb_stag_bg.set_corner_radius_all(3)
		var sb_stag_fill := StyleBoxFlat.new()
		sb_stag_fill.bg_color = Color(1.0, 0.74, 0.16, 0.96)
		sb_stag_fill.border_width_top = 1
		sb_stag_fill.border_color = Color(1.0, 0.95, 0.62, 0.98)
		sb_stag_fill.set_corner_radius_all(3)
		bar_stagger_jefe.add_theme_stylebox_override("background", sb_stag_bg)
		bar_stagger_jefe.add_theme_stylebox_override("fill", sb_stag_fill)
		_contenedor_stagger_jefe.add_child(bar_stagger_jefe)

		_lbl_stagger_jefe = Label.new()
		_lbl_stagger_jefe.name = "LabelStaggerJefe"
		_lbl_stagger_jefe.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lbl_stagger_jefe.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_lbl_stagger_jefe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_lbl_stagger_jefe.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_lbl_stagger_jefe.add_theme_font_size_override("font_size", 10)
		_lbl_stagger_jefe.add_theme_color_override("font_color", Color(1.0, 0.96, 0.80, 1.0))
		_lbl_stagger_jefe.add_theme_color_override("font_outline_color", Color(0.08, 0.03, 0.01, 1.0))
		_lbl_stagger_jefe.add_theme_constant_override("outline_size", 2)
		_lbl_stagger_jefe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_contenedor_stagger_jefe.add_child(_lbl_stagger_jefe)

		vbox_jefe.add_child(_contenedor_stagger_jefe)


func _extraer_nombre_y_subtitulo_jefe(texto: String) -> Dictionary:
	var limpio := _limpiar_prefijo_emoji_jefe(texto)
	var idx_ini := limpio.find("[")
	var idx_fin := limpio.rfind("]")
	if idx_ini >= 0 and idx_fin > idx_ini:
		var base := limpio.substr(0, idx_ini).strip_edges()
		var sub := limpio.substr(idx_ini + 1, idx_fin - idx_ini - 1).strip_edges()
		return {"nombre": base, "subtitulo": sub}
	return {"nombre": limpio, "subtitulo": ""}


func _detectar_estado_jefe(texto: String, estado_tag: String = "") -> String:
	var tag := estado_tag.strip_edges().to_upper()
	if not tag.is_empty():
		match tag:
			"VULNERABLE", "ATURDIDO":
				return "VULNERABLE"
			"ESCUDO", "CORAZA", "CRISTALES":
				return "ESCUDO"
			"CANALIZANDO", "INTERRUMPIR":
				return "CANALIZANDO"
			"ENRAGE", "FURIA":
				return "ENRAGE"
			"NORMAL":
				return "NORMAL"

	var upper := texto.to_upper()
	if upper.contains("VULNERABLE") or upper.contains("ATURDID") or upper.contains("DESTRUIDA") or upper.contains("DESARMADO") or upper.contains("DISIPADA") or upper.contains("PURIFICAR"):
		return "VULNERABLE"
	if upper.contains("ESCUDO") or upper.contains("CORAZA") or upper.contains("CRISTALES") or upper.contains("INVULNERABLE"):
		return "ESCUDO"
	if upper.contains("INTERRUMPIR") or upper.contains("CANALIZ") or upper.contains("TORMENTA") or upper.contains("CARGANDO"):
		return "CANALIZANDO"
	if upper.contains("ENRAGE") or upper.contains("FURIA") or upper.contains("FRENESÍ") or upper.contains("FRENESI"):
		return "ENRAGE"
	return "NORMAL"


func _aplicar_estado_visual_jefe(estado: String, subtitulo: String = "") -> void:
	if panel_jefe == null:
		return
	var cambio_estado := (estado != _jefe_estado_actual)
	_jefe_estado_actual = estado

	var sub_final := subtitulo.strip_edges()
	var mostrar_pill := (estado != "NORMAL") or not sub_final.is_empty()

	if cambio_estado and _tw_panel_jefe_pulso != null and _tw_panel_jefe_pulso.is_valid():
		_tw_panel_jefe_pulso.kill()
		_tw_panel_jefe_pulso = null

	var mj: ShaderMaterial = null
	if bar_jefe_shader != null and bar_jefe_shader.material is ShaderMaterial:
		mj = bar_jefe_shader.material as ShaderMaterial

	match estado:
		"VULNERABLE":
			if sub_final.is_empty():
				sub_final = "💥 ¡VULNERABLE — ATACA AHORA!"
			if _sb_panel_jefe != null:
				_sb_panel_jefe.bg_color = Color(0.14, 0.09, 0.02, 0.97)
				_sb_panel_jefe.border_color = Color(1.0, 0.84, 0.24, 1.0)
				_sb_panel_jefe.shadow_color = Color(1.0, 0.76, 0.16, 0.65)
				_sb_panel_jefe.shadow_size = 16
			if mj != null:
				mj.set_shader_parameter("shield_ratio", 0.0)
				mj.set_shader_parameter("color_hp_top", Color(1.0, 0.86, 0.28, 1.0))
				mj.set_shader_parameter("color_hp_bot", Color(0.86, 0.42, 0.06, 1.0))
				mj.set_shader_parameter("border_color", Color(1.0, 0.88, 0.36, 1.0))
			if _sb_pill_estado_jefe != null:
				_sb_pill_estado_jefe.bg_color = Color(0.24, 0.16, 0.03, 0.96)
				_sb_pill_estado_jefe.border_color = Color(1.0, 0.86, 0.28, 1.0)
			if _lbl_estado_jefe != null:
				_lbl_estado_jefe.add_theme_color_override("font_color", Color(1.0, 0.94, 0.56, 1.0))
			if cambio_estado and _sb_panel_jefe != null:
				_tw_panel_jefe_pulso = create_tween()
				_tw_panel_jefe_pulso.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				_tw_panel_jefe_pulso.set_loops()
				_tw_panel_jefe_pulso.tween_property(_sb_panel_jefe, "shadow_size", 24, 0.45).set_trans(Tween.TRANS_SINE)
				_tw_panel_jefe_pulso.parallel().tween_property(_sb_panel_jefe, "border_color", Color(1.0, 0.96, 0.62, 1.0), 0.45)
				_tw_panel_jefe_pulso.tween_property(_sb_panel_jefe, "shadow_size", 14, 0.45).set_trans(Tween.TRANS_SINE)
				_tw_panel_jefe_pulso.parallel().tween_property(_sb_panel_jefe, "border_color", Color(1.0, 0.80, 0.20, 1.0), 0.45)

		"ESCUDO":
			if sub_final.is_empty():
				sub_final = "🛡️ DEFENSA ACTIVA — PULSA EL NÚCLEO"
			if _sb_panel_jefe != null:
				_sb_panel_jefe.bg_color = Color(0.03, 0.07, 0.12, 0.97)
				_sb_panel_jefe.border_color = Color(0.32, 0.86, 1.0, 0.98)
				_sb_panel_jefe.shadow_color = Color(0.16, 0.68, 0.96, 0.56)
				_sb_panel_jefe.shadow_size = 15
			if mj != null:
				mj.set_shader_parameter("shield_ratio", 0.28)
				mj.set_shader_parameter("color_hp_top", Color(0.76, 0.34, 0.44, 1.0))
				mj.set_shader_parameter("color_hp_bot", Color(0.42, 0.12, 0.20, 1.0))
				mj.set_shader_parameter("border_color", Color(0.45, 0.88, 1.0, 0.98))
			if _sb_pill_estado_jefe != null:
				_sb_pill_estado_jefe.bg_color = Color(0.05, 0.14, 0.22, 0.96)
				_sb_pill_estado_jefe.border_color = Color(0.36, 0.88, 1.0, 0.98)
			if _lbl_estado_jefe != null:
				_lbl_estado_jefe.add_theme_color_override("font_color", Color(0.76, 0.96, 1.0, 1.0))

		"CANALIZANDO":
			if sub_final.is_empty():
				sub_final = "⚡ CANALIZANDO — ¡PULSA EL NÚCLEO PARA INTERRUMPIR!"
			if _sb_panel_jefe != null:
				_sb_panel_jefe.bg_color = Color(0.12, 0.04, 0.14, 0.97)
				_sb_panel_jefe.border_color = Color(1.0, 0.54, 0.18, 1.0)
				_sb_panel_jefe.shadow_color = Color(0.95, 0.36, 0.16, 0.62)
				_sb_panel_jefe.shadow_size = 16
			if mj != null:
				mj.set_shader_parameter("shield_ratio", 0.0)
				mj.set_shader_parameter("color_hp_top", Color(1.0, 0.46, 0.20, 1.0))
				mj.set_shader_parameter("color_hp_bot", Color(0.62, 0.12, 0.08, 1.0))
				mj.set_shader_parameter("border_color", Color(1.0, 0.64, 0.24, 1.0))
			if _sb_pill_estado_jefe != null:
				_sb_pill_estado_jefe.bg_color = Color(0.22, 0.08, 0.14, 0.96)
				_sb_pill_estado_jefe.border_color = Color(1.0, 0.56, 0.20, 1.0)
			if _lbl_estado_jefe != null:
				_lbl_estado_jefe.add_theme_color_override("font_color", Color(1.0, 0.86, 0.58, 1.0))
			if cambio_estado and _sb_panel_jefe != null:
				_tw_panel_jefe_pulso = create_tween()
				_tw_panel_jefe_pulso.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				_tw_panel_jefe_pulso.set_loops()
				_tw_panel_jefe_pulso.tween_property(_sb_panel_jefe, "shadow_size", 22, 0.38).set_trans(Tween.TRANS_SINE)
				_tw_panel_jefe_pulso.tween_property(_sb_panel_jefe, "shadow_size", 13, 0.38).set_trans(Tween.TRANS_SINE)

		"ENRAGE":
			if sub_final.is_empty():
				sub_final = "🔥 ¡ENRAGE ACTIVO!"
			if _sb_panel_jefe != null:
				_sb_panel_jefe.bg_color = Color(0.16, 0.02, 0.03, 0.98)
				_sb_panel_jefe.border_color = Color(1.0, 0.18, 0.24, 1.0)
				_sb_panel_jefe.shadow_color = Color(0.95, 0.08, 0.14, 0.72)
				_sb_panel_jefe.shadow_size = 18
			if mj != null:
				mj.set_shader_parameter("shield_ratio", 0.0)
				mj.set_shader_parameter("color_hp_top", Color(1.0, 0.20, 0.26, 1.0))
				mj.set_shader_parameter("color_hp_bot", Color(0.55, 0.02, 0.06, 1.0))
				mj.set_shader_parameter("border_color", Color(1.0, 0.30, 0.32, 1.0))
			if _sb_pill_estado_jefe != null:
				_sb_pill_estado_jefe.bg_color = Color(0.28, 0.03, 0.05, 0.96)
				_sb_pill_estado_jefe.border_color = Color(1.0, 0.24, 0.30, 1.0)
			if _lbl_estado_jefe != null:
				_lbl_estado_jefe.add_theme_color_override("font_color", Color(1.0, 0.78, 0.78, 1.0))
			if cambio_estado and _sb_panel_jefe != null:
				_tw_panel_jefe_pulso = create_tween()
				_tw_panel_jefe_pulso.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				_tw_panel_jefe_pulso.set_loops()
				_tw_panel_jefe_pulso.tween_property(_sb_panel_jefe, "shadow_size", 24, 0.32).set_trans(Tween.TRANS_SINE)
				_tw_panel_jefe_pulso.tween_property(_sb_panel_jefe, "shadow_size", 14, 0.32).set_trans(Tween.TRANS_SINE)

		_:
			if _sb_panel_jefe != null:
				_sb_panel_jefe.bg_color = Color(0.08, 0.03, 0.05, 0.96)
				_sb_panel_jefe.border_color = Color(0.82, 0.24, 0.30, 0.95)
				_sb_panel_jefe.shadow_color = Color(0.65, 0.05, 0.12, 0.55)
				_sb_panel_jefe.shadow_size = 14
			if mj != null:
				mj.set_shader_parameter("shield_ratio", 0.0)
				mj.set_shader_parameter("color_hp_top", Color(0.96, 0.26, 0.36, 1.0))
				mj.set_shader_parameter("color_hp_bot", Color(0.55, 0.04, 0.12, 1.0))
				mj.set_shader_parameter("border_color", Color(0.82, 0.65, 0.35, 0.95))

	if _pill_estado_jefe != null and _lbl_estado_jefe != null:
		_pill_estado_jefe.visible = mostrar_pill
		if mostrar_pill:
			_lbl_estado_jefe.text = sub_final
	_recalcular_altura_panel_jefe()


func _recalcular_altura_panel_jefe() -> void:
	if panel_jefe == null:
		return
	var altura := 190.0
	if _pill_estado_jefe != null and _pill_estado_jefe.visible:
		altura += 22.0
	if _contenedor_stagger_jefe != null and _contenedor_stagger_jefe.visible:
		altura += 24.0
	panel_jefe.offset_bottom = altura


func mostrar_barra_stagger(clics_restantes: int, clics_totales: int, tiempo_restante: float) -> void:
	if panel_jefe == null:
		return
	if _contenedor_stagger_jefe == null:
		_inicializar_estilo_panel_jefe()
	if _contenedor_stagger_jefe == null or bar_stagger_jefe == null or _lbl_stagger_jefe == null:
		return
	var totales := maxi(clics_totales, 1)
	var restantes := clampi(clics_restantes, 0, totales)
	var completados := totales - restantes
	_contenedor_stagger_jefe.visible = true
	bar_stagger_jefe.max_value = float(totales)
	bar_stagger_jefe.value = float(completados)
	_lbl_stagger_jefe.text = "⚡ CONMOCIÓN: %d / %d CLICS AL NÚCLEO · %.1fs" % [completados, totales, maxf(tiempo_restante, 0.0)]
	_recalcular_altura_panel_jefe()


func ocultar_barra_stagger() -> void:
	if _contenedor_stagger_jefe != null:
		_contenedor_stagger_jefe.visible = false
	_recalcular_altura_panel_jefe()


func mostrar_barra_jefe(nombre: String, max_hp: float, hp_actual: float) -> void:
	if panel_jefe == null:
		return
	var estaba_oculto := not panel_jefe.visible
	panel_jefe.visible = true
	ocultar_barra_stagger()
	if bar_jefe_shader != null and bar_jefe_shader.material is ShaderMaterial:
		var mj := bar_jefe_shader.material as ShaderMaterial
		mj.set_shader_parameter("segment_notches", 0)
		mj.set_shader_parameter("phase_mark_1", 0.60)
		mj.set_shader_parameter("phase_mark_2", 0.25)
	var partes := _extraer_nombre_y_subtitulo_jefe(nombre)
	var estado_ini := _detectar_estado_jefe(nombre, "")
	if label_nombre_jefe != null:
		var nom_str := str(partes["nombre"])
		label_nombre_jefe.text = (nom_str if not nom_str.is_empty() else _limpiar_prefijo_emoji_jefe(nombre)).to_upper()
	_aplicar_estado_visual_jefe(estado_ini, str(partes["subtitulo"]))

	var safe_max := maxf(max_hp, 1.0)
	_jefe_hp_ratio = clampf(hp_actual / safe_max, 0.0, 1.0)
	_jefe_trail_ratio = _jefe_hp_ratio
	_jefe_trail_hold = 0.0
	_jefe_hp_previa = hp_actual
	if bar_vida_jefe != null:
		bar_vida_jefe.max_value = safe_max
		bar_vida_jefe.value = hp_actual
	if label_vida_jefe != null:
		label_vida_jefe.text = "%s / %s HP" % [_formatear_numero(int(ceil(hp_actual))), _formatear_numero(int(round(safe_max)))]
	if estaba_oculto:
		panel_jefe.scale = Vector2(0.90, 0.90)
		panel_jefe.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(panel_jefe, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(panel_jefe, "modulate:a", 1.0, 0.22)


func actualizar_barra_jefe(hp_actual: float, texto_nombre: String = "", estado_tag: String = "") -> void:
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
		label_vida_jefe.text = "%s / %s HP" % [_formatear_numero(int(ceil(hp_actual))), _formatear_numero(int(round(safe_max)))]
	if texto_nombre != "" or estado_tag != "":
		var partes := _extraer_nombre_y_subtitulo_jefe(texto_nombre)
		var estado := _detectar_estado_jefe(texto_nombre, estado_tag)
		if texto_nombre != "" and label_nombre_jefe != null:
			var nom_str := str(partes["nombre"])
			if not nom_str.is_empty():
				label_nombre_jefe.text = nom_str.to_upper()
			else:
				label_nombre_jefe.text = _limpiar_prefijo_emoji_jefe(texto_nombre).to_upper()
		_aplicar_estado_visual_jefe(estado, str(partes["subtitulo"]))


func ocultar_barra_jefe() -> void:
	ocultar_barra_stagger()
	var jefes_vivos := _obtener_jefes_vivos()
	if jefes_vivos.size() > 0:
		var otro = jefes_vivos[0]
		var max_hp := float(otro.vida_maxima) if "vida_maxima" in otro else 500.0
		var hp := float(otro.vida) if "vida" in otro else max_hp
		_habia_jefe_en_grupo = true
		mostrar_barra_jefe(str(otro.name), max_hp, hp)
		return
	_habia_jefe_en_grupo = false
	_aplicar_estado_visual_jefe("NORMAL", "")
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
		if modal_mercader != null and modal_mercader.visible and event.keycode == KEY_ESCAPE:
			_cerrar_mercader_vacio()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F11:
			_toggle_pantalla_completa()
			get_viewport().set_input_as_handled()
			return
		if (modal_mejora == null or not modal_mejora.visible) and (modal_mercader == null or not modal_mercader.visible):
			if event.keycode == KEY_V or (event.keycode == KEY_TAB and _banner_evolucion_activo):
				if _solicitar_reabrir_evolucion():
					get_viewport().set_input_as_handled()
					return


# ==============================================================================
# ESCALADO MULTI-RESOLUCIÓN DE MODALES Y ALAS
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

	# Sincronizar geometría de las 3 alas biseladas y tamaño de barras cápsula
	call_deferred("_sync_wings_geometry")


func _toggle_pantalla_completa() -> void:
	var modo := DisplayServer.window_get_mode()
	if modo == DisplayServer.WINDOW_MODE_FULLSCREEN or modo == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	call_deferred("_ajustar_layout_resolucion")


# ==============================================================================
# BOOTSTRAP DE MANAGERS Y MODALES DE EVENTO DE ARENA
# ==============================================================================

var evolucion_manager_ref: Node = null
var banner_evolucion: PanelContainer = null
var _sb_banner_evolucion: StyleBoxFlat = null
var _sb_badge_tecla_evo: StyleBoxFlat = null
var icono_banner_evo: TextureRect = null
var lbl_banner_evo_titulo: Label = null
var lbl_banner_evo_subtitulo: Label = null
var lbl_banner_evo_tecla: Label = null
var _tw_banner_evo_transicion: Tween = null
var _tw_banner_evo_pulso: Tween = null
var _banner_evolucion_activo: bool = false
var _banner_evolucion_tier: int = 0

var chip_evolucion_rail: PanelContainer = null
var _sb_chip_evo_rail: StyleBoxFlat = null
var lbl_chip_evo_rail: Label = null
var _chip_evo_listo: bool = false
var _tw_chip_evo_pulso: Tween = null

var modal_mercader: ColorRect = null
var contenedor_cartas_mercader: HBoxContainer = null

var overlay_pulgar: ColorRect = null
var lbl_pulgar_titulo: Label = null
var lbl_pulgar_desc: Label = null
var icono_pulgar: Label = null

func _formatear_numero(val: Variant) -> String:
	return str(MetaprogresoManager.formatear_numero(val))

func _bootstrap_domain4_managers() -> void:
	var padre_escena: Node = get_tree().current_scene if (get_tree() != null and get_tree().current_scene != null) else get_tree().root

	# 1. Favor del Emperador Manager (añadir al nodo de escena actual para que get_parent() sea la Arena)
	var favor = get_tree().get_first_node_in_group("favor_emperador_manager")
	if favor == null and ResourceLoader.exists("res://favor_emperador_manager.gd"):
		var scr_favor = load("res://favor_emperador_manager.gd")
		if scr_favor != null:
			favor = scr_favor.new()
			favor.name = "FavorEmperadorManager"
			favor.add_to_group("favor_emperador_manager")
			if padre_escena != null:
				padre_escena.add_child(favor)

	# 2. Eventos Coliseo Manager (añadir al nodo de escena actual para acceso directo a WorldEnvironment/Arena)
	var eventos = get_tree().get_first_node_in_group("eventos_coliseo_manager")
	if eventos == null and ResourceLoader.exists("res://eventos_coliseo_manager.gd"):
		var scr_eventos = load("res://eventos_coliseo_manager.gd")
		if scr_eventos != null:
			eventos = scr_eventos.new()
			eventos.name = "EventosColiseoManager"
			eventos.add_to_group("eventos_coliseo_manager")
			if padre_escena != null:
				padre_escena.add_child(eventos)

	_conectar_senales_dominio4()

func _conectar_senales_dominio4() -> void:
	var favor = get_tree().get_first_node_in_group("favor_emperador_manager")
	if favor != null:
		if favor.has_signal("pulgar_emperador_iniciado") and not favor.pulgar_emperador_iniciado.is_connected(_on_pulgar_iniciado):
			favor.pulgar_emperador_iniciado.connect(_on_pulgar_iniciado)
		if favor.has_signal("pulgar_emperador_resuelto") and not favor.pulgar_emperador_resuelto.is_connected(_on_pulgar_resuelto):
			favor.pulgar_emperador_resuelto.connect(_on_pulgar_resuelto)

	var eventos = get_tree().get_first_node_in_group("eventos_coliseo_manager")
	if eventos != null:
		if eventos.has_signal("mercader_vacio_disponible") and not eventos.mercader_vacio_disponible.is_connected(_on_mercader_disponible):
			eventos.mercader_vacio_disponible.connect(_on_mercader_disponible)

func registrar_impacto_dano_telemetria(_cantidad: float = 0.0, _tipo: String = "arma") -> void:
	pass

func _crear_modales_dominio4() -> void:
	# Modal Mercader del Vacío
	modal_mercader = ColorRect.new()
	modal_mercader.name = "ModalMercaderVacio"
	modal_mercader.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_mercader.color = Color(0.04, 0.02, 0.07, 0.88)
	modal_mercader.visible = false
	modal_mercader.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_mercader.process_mode = Node.PROCESS_MODE_ALWAYS
	$Control.add_child(modal_mercader)

	var panel_mer := PanelContainer.new()
	panel_mer.anchor_left = 0.5
	panel_mer.anchor_right = 0.5
	panel_mer.anchor_top = 0.5
	panel_mer.anchor_bottom = 0.5
	panel_mer.offset_left = -335.0
	panel_mer.offset_right = 335.0
	panel_mer.offset_top = -195.0
	panel_mer.offset_bottom = 195.0

	var sb_mer := StyleBoxFlat.new()
	sb_mer.bg_color = Color(0.07, 0.04, 0.12, 0.96)
	sb_mer.border_width_left = 2
	sb_mer.border_width_top = 2
	sb_mer.border_width_right = 2
	sb_mer.border_width_bottom = 2
	sb_mer.border_color = Color(0.75, 0.35, 0.95, 0.95)
	sb_mer.corner_radius_top_left = 8
	sb_mer.corner_radius_top_right = 8
	sb_mer.corner_radius_bottom_right = 8
	sb_mer.corner_radius_bottom_left = 8
	sb_mer.content_margin_left = 14.0
	sb_mer.content_margin_right = 14.0
	sb_mer.content_margin_top = 12.0
	sb_mer.content_margin_bottom = 12.0
	panel_mer.add_theme_stylebox_override("panel", sb_mer)
	modal_mercader.add_child(panel_mer)

	var v_mer := VBoxContainer.new()
	v_mer.add_theme_constant_override("separation", 10)
	panel_mer.add_child(v_mer)

	var t_mer := Label.new()
	t_mer.text = "🔮 EL MERCADER DEL VACÍO (PACTOS CORRUPTOS)"
	t_mer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_mer.add_theme_font_size_override("font_size", 13)
	t_mer.add_theme_color_override("font_color", Color(0.92, 0.65, 1.0))
	v_mer.add_child(t_mer)

	contenedor_cartas_mercader = HBoxContainer.new()
	contenedor_cartas_mercader.add_theme_constant_override("separation", 12)
	contenedor_cartas_mercader.alignment = BoxContainer.ALIGNMENT_CENTER
	v_mer.add_child(contenedor_cartas_mercader)

	var btn_cerrar_mer := Button.new()
	btn_cerrar_mer.text = "❌ Rechazar Ofrenda del Vacío"
	btn_cerrar_mer.custom_minimum_size = Vector2(210, 30)
	btn_cerrar_mer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_cerrar_mer.focus_mode = Control.FOCUS_NONE
	btn_cerrar_mer.pressed.connect(_cerrar_mercader_vacio)
	v_mer.add_child(btn_cerrar_mer)

	# Overlay Pulgar del Emperador
	overlay_pulgar = ColorRect.new()
	overlay_pulgar.name = "OverlayPulgarEmperador"
	overlay_pulgar.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_pulgar.color = Color(0.0, 0.0, 0.0, 0.82)
	overlay_pulgar.visible = false
	overlay_pulgar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_pulgar.process_mode = Node.PROCESS_MODE_ALWAYS
	$Control.add_child(overlay_pulgar)

	var v_pulg := VBoxContainer.new()
	v_pulg.set_anchors_preset(Control.PRESET_CENTER)
	v_pulg.add_theme_constant_override("separation", 10)
	v_pulg.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay_pulgar.add_child(v_pulg)

	icono_pulgar = Label.new()
	icono_pulgar.text = "🏛️"
	icono_pulgar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icono_pulgar.add_theme_font_size_override("font_size", 48)
	v_pulg.add_child(icono_pulgar)

	lbl_pulgar_titulo = Label.new()
	lbl_pulgar_titulo.text = "EL JUICIO DEL EMPERADOR"
	lbl_pulgar_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_pulgar_titulo.add_theme_font_size_override("font_size", 18)
	lbl_pulgar_titulo.add_theme_color_override("font_color", Color(1.0, 0.84, 0.28))
	v_pulg.add_child(lbl_pulgar_titulo)

	lbl_pulgar_desc = Label.new()
	lbl_pulgar_desc.text = "El Coliseo ruge en silencio aguardando la sentencia..."
	lbl_pulgar_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_pulgar_desc.add_theme_font_size_override("font_size", 12)
	lbl_pulgar_desc.add_theme_color_override("font_color", Color(0.90, 0.90, 0.95))
	v_pulg.add_child(lbl_pulgar_desc)

func mostrar_toast_hazana(_titulo: String = "", _desc: String = "") -> void:
	pass

func _on_mercader_disponible(opciones: Array, _restante: float = 0.0) -> void:
	if modal_mercader == null or contenedor_cartas_mercader == null:
		return

	for child in contenedor_cartas_mercader.get_children():
		child.queue_free()

	for op in opciones:
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(195, 235)

		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.10, 0.06, 0.16, 0.95)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.70, 0.40, 0.95, 0.85)
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_right = 6
		sb.corner_radius_bottom_left = 6
		sb.content_margin_left = 10.0
		sb.content_margin_right = 10.0
		sb.content_margin_top = 10.0
		sb.content_margin_bottom = 10.0
		p.add_theme_stylebox_override("panel", sb)

		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		p.add_child(v)

		var l_tit := Label.new()
		l_tit.text = str(op.get("nombre", "Pacto Corrupto"))
		l_tit.autowrap_mode = TextServer.AUTOWRAP_WORD
		l_tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l_tit.add_theme_font_size_override("font_size", 11)
		l_tit.add_theme_color_override("font_color", Color(0.85, 0.70, 1.0))
		v.add_child(l_tit)

		var mal_txt: String = str(op.get("maldicion", op.get("desc", "")))
		var ben_txt: String = str(op.get("bendicion", op.get("descripcion", "")))

		var l_mal := Label.new()
		l_mal.text = "💀 Maldición:\n" + mal_txt
		l_mal.autowrap_mode = TextServer.AUTOWRAP_WORD
		l_mal.add_theme_font_size_override("font_size", 9)
		l_mal.add_theme_color_override("font_color", Color(1.0, 0.40, 0.40))
		v.add_child(l_mal)

		var l_ben := Label.new()
		l_ben.text = "✨ Bendición:\n" + ben_txt
		l_ben.autowrap_mode = TextServer.AUTOWRAP_WORD
		l_ben.add_theme_font_size_override("font_size", 9)
		l_ben.add_theme_color_override("font_color", Color(1.0, 0.88, 0.40))
		v.add_child(l_ben)

		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(spacer)

		var id_corrupta: String = str(op.get("id", ""))
		var btn_pactar := Button.new()
		btn_pactar.text = "PACTAR"
		btn_pactar.custom_minimum_size = Vector2(0, 26)
		btn_pactar.focus_mode = Control.FOCUS_NONE
		btn_pactar.pressed.connect(func(): _elegir_pacto_mercader(id_corrupta))
		v.add_child(btn_pactar)

		contenedor_cartas_mercader.add_child(p)

	modal_mercader.visible = true
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = true

func _elegir_pacto_mercader(id: String) -> void:
	var eventos = get_tree().get_first_node_in_group("eventos_coliseo_manager")
	if eventos != null and eventos.has_method("aplicar_corrupta_elegida"):
		eventos.aplicar_corrupta_elegida(id)
	_cerrar_mercader_vacio()

func _cerrar_mercader_vacio() -> void:
	if modal_mercader != null:
		modal_mercader.visible = false
	if is_inside_tree() and get_tree() != null:
		get_tree().paused = false

func _on_pulgar_iniciado(_prob: float = 0.5) -> void:
	if overlay_pulgar == null:
		return
	overlay_pulgar.modulate.a = 1.0
	overlay_pulgar.visible = true
	if icono_pulgar != null:
		icono_pulgar.text = "🏛️"
	if lbl_pulgar_titulo != null:
		lbl_pulgar_titulo.text = "EL JUICIO DEL EMPERADOR"
		lbl_pulgar_titulo.add_theme_color_override("font_color", Color(1.0, 0.85, 0.30))
	if lbl_pulgar_desc != null:
		lbl_pulgar_desc.text = "El Coliseo contiene el aliento... ¿Misericordia o Muerte?"

func _on_pulgar_resuelto(salvado: bool, _prob: float = 0.5) -> void:
	if overlay_pulgar == null:
		return
	overlay_pulgar.modulate.a = 1.0
	overlay_pulgar.visible = true
	if salvado:
		if icono_pulgar != null:
			icono_pulgar.text = "👍"
		if lbl_pulgar_titulo != null:
			lbl_pulgar_titulo.text = "¡EL EMPERADOR TE CONCEDE LA GLORIA!"
			lbl_pulgar_titulo.add_theme_color_override("font_color", Color(1.0, 0.90, 0.35))
		if lbl_pulgar_desc != null:
			lbl_pulgar_desc.text = "El rugido del Coliseo te devuelve al combate con vigor renovado."
	else:
		if icono_pulgar != null:
			icono_pulgar.text = "👎"
		if lbl_pulgar_titulo != null:
			lbl_pulgar_titulo.text = "SENTENCIA IMPERIAL"
			lbl_pulgar_titulo.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
		if lbl_pulgar_desc != null:
			lbl_pulgar_desc.text = "El pulgar desciende. La Parca reclama tu alma."

	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(2.2)
	tw.tween_property(overlay_pulgar, "modulate:a", 0.0, 0.40)
	tw.finished.connect(func():
		overlay_pulgar.visible = false
		overlay_pulgar.modulate.a = 1.0
	)


# ==============================================================================
# BANNER PULSANTE DE EVOLUCIÓN Y CHIP DE PROGRESO EN STATUS RAIL
# ==============================================================================

const EVO_BANNER_PALETAS := {
	1: {
		"titulo": "✨ METAMORFOSIS TIER 1 DISPONIBLE",
		"subtitulo": "Elige tu clase de la Arena · Clic o [V]",
		"bg": Color(0.11, 0.08, 0.03, 0.96),
		"borde": Color(1.0, 0.84, 0.30, 1.0),
		"sombra": Color(1.0, 0.78, 0.22, 0.56),
		"titulo_color": Color(1.0, 0.92, 0.52, 1.0),
		"sub_color": Color(0.95, 0.90, 0.78, 0.95),
		"badge_bg": Color(0.24, 0.17, 0.05, 0.95)
	},
	2: {
		"titulo": "👑 ASCENSIÓN TIER 2 DISPONIBLE",
		"subtitulo": "Especializa tu arquetipo · Clic o [V]",
		"bg": Color(0.15, 0.04, 0.05, 0.96),
		"borde": Color(0.98, 0.44, 0.20, 1.0),
		"sombra": Color(0.95, 0.26, 0.18, 0.60),
		"titulo_color": Color(1.0, 0.80, 0.44, 1.0),
		"sub_color": Color(0.98, 0.86, 0.80, 0.95),
		"badge_bg": Color(0.30, 0.09, 0.08, 0.95)
	},
	3: {
		"titulo": "🌟 ASCENSIÓN DEFINITIVA TIER 3 DISPONIBLE",
		"subtitulo": "Desata tu forma suprema · Clic o [V]",
		"bg": Color(0.10, 0.04, 0.16, 0.97),
		"borde": Color(0.76, 0.44, 1.0, 1.0),
		"sombra": Color(0.68, 0.32, 1.0, 0.64),
		"titulo_color": Color(0.94, 0.84, 1.0, 1.0),
		"sub_color": Color(0.92, 0.88, 0.98, 0.95),
		"badge_bg": Color(0.22, 0.09, 0.32, 0.95)
	}
}

func _obtener_paleta_evolucion(tier: int) -> Dictionary:
	return EVO_BANNER_PALETAS.get(clampi(tier, 1, 3), EVO_BANNER_PALETAS[1])

func _crear_banner_y_chip_evolucion() -> void:
	# 1. Chip compacto en StatusRail (antes de SpacerRail para evitar solapamiento)
	var rail_box := get_node_or_null("Control/StatusRail/HBoxStatusRail")
	if rail_box != null and chip_evolucion_rail == null:
		chip_evolucion_rail = PanelContainer.new()
		chip_evolucion_rail.name = "ChipEvolucionRail"
		chip_evolucion_rail.visible = false
		chip_evolucion_rail.mouse_filter = Control.MOUSE_FILTER_STOP
		chip_evolucion_rail.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		chip_evolucion_rail.gui_input.connect(_on_chip_evo_gui_input)

		_sb_chip_evo_rail = StyleBoxFlat.new()
		_sb_chip_evo_rail.bg_color = Color(0.055, 0.068, 0.105, 0.92)
		_sb_chip_evo_rail.border_color = Color(0.55, 0.44, 0.24, 0.90)
		_sb_chip_evo_rail.set_border_width_all(1)
		_sb_chip_evo_rail.set_corner_radius_all(6)
		_sb_chip_evo_rail.content_margin_left = 8.0
		_sb_chip_evo_rail.content_margin_right = 8.0
		_sb_chip_evo_rail.content_margin_top = 3.0
		_sb_chip_evo_rail.content_margin_bottom = 3.0
		chip_evolucion_rail.add_theme_stylebox_override("panel", _sb_chip_evo_rail)

		lbl_chip_evo_rail = Label.new()
		lbl_chip_evo_rail.name = "LabelChipEvolucion"
		lbl_chip_evo_rail.add_theme_font_size_override("font_size", 10)
		lbl_chip_evo_rail.add_theme_color_override("font_color", Color(0.92, 0.88, 0.76, 1.0))
		lbl_chip_evo_rail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip_evolucion_rail.add_child(lbl_chip_evo_rail)

		rail_box.add_child(chip_evolucion_rail)
		var spacer := rail_box.get_node_or_null("SpacerRail")
		if spacer != null:
			rail_box.move_child(chip_evolucion_rail, spacer.get_index())

	# 2. Banner pulsante inferior-centrado (nunca solapa BarraSuperior, StatusRail ni PanelJefe)
	var ctrl_root := get_node_or_null("Control")
	if ctrl_root == null or banner_evolucion != null:
		return

	banner_evolucion = PanelContainer.new()
	banner_evolucion.name = "BannerEvolucionAlerta"
	banner_evolucion.z_index = 18
	banner_evolucion.visible = false
	banner_evolucion.process_mode = Node.PROCESS_MODE_ALWAYS
	banner_evolucion.anchor_left = 0.5
	banner_evolucion.anchor_right = 0.5
	banner_evolucion.anchor_top = 1.0
	banner_evolucion.anchor_bottom = 1.0
	banner_evolucion.offset_left = -225.0
	banner_evolucion.offset_right = 225.0
	banner_evolucion.offset_top = -80.0
	banner_evolucion.offset_bottom = -20.0
	banner_evolucion.pivot_offset = Vector2(225.0, 30.0)
	banner_evolucion.mouse_filter = Control.MOUSE_FILTER_STOP
	banner_evolucion.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	banner_evolucion.gui_input.connect(_on_banner_evolucion_gui_input)

	_sb_banner_evolucion = StyleBoxFlat.new()
	_sb_banner_evolucion.bg_color = Color(0.11, 0.08, 0.03, 0.96)
	_sb_banner_evolucion.set_border_width_all(2)
	_sb_banner_evolucion.border_color = Color(1.0, 0.84, 0.30, 1.0)
	_sb_banner_evolucion.set_corner_radius_all(9)
	_sb_banner_evolucion.content_margin_left = 14.0
	_sb_banner_evolucion.content_margin_right = 14.0
	_sb_banner_evolucion.content_margin_top = 8.0
	_sb_banner_evolucion.content_margin_bottom = 8.0
	_sb_banner_evolucion.shadow_color = Color(1.0, 0.78, 0.22, 0.56)
	_sb_banner_evolucion.shadow_size = 14
	banner_evolucion.add_theme_stylebox_override("panel", _sb_banner_evolucion)
	ctrl_root.add_child(banner_evolucion)

	var hbox := HBoxContainer.new()
	hbox.name = "HBoxBannerEvo"
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_evolucion.add_child(hbox)

	icono_banner_evo = TextureRect.new()
	icono_banner_evo.name = "IconoEvo"
	icono_banner_evo.texture = TEX_ICO_CLASS
	icono_banner_evo.custom_minimum_size = Vector2(22.0, 22.0)
	icono_banner_evo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icono_banner_evo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono_banner_evo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono_banner_evo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icono_banner_evo)

	var vbox_txt := VBoxContainer.new()
	vbox_txt.name = "VBoxTextos"
	vbox_txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_txt.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_txt.add_theme_constant_override("separation", 1)
	vbox_txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(vbox_txt)

	lbl_banner_evo_titulo = Label.new()
	lbl_banner_evo_titulo.name = "LabelTituloEvo"
	lbl_banner_evo_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_banner_evo_titulo.add_theme_font_size_override("font_size", 12)
	lbl_banner_evo_titulo.add_theme_color_override("font_outline_color", Color(0.06, 0.03, 0.02, 1.0))
	lbl_banner_evo_titulo.add_theme_constant_override("outline_size", 2)
	lbl_banner_evo_titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox_txt.add_child(lbl_banner_evo_titulo)

	lbl_banner_evo_subtitulo = Label.new()
	lbl_banner_evo_subtitulo.name = "LabelSubtituloEvo"
	lbl_banner_evo_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_banner_evo_subtitulo.add_theme_font_size_override("font_size", 10)
	lbl_banner_evo_subtitulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox_txt.add_child(lbl_banner_evo_subtitulo)

	var badge_tecla := PanelContainer.new()
	badge_tecla.name = "BadgeTeclaEvo"
	badge_tecla.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge_tecla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sb_badge_tecla_evo = StyleBoxFlat.new()
	_sb_badge_tecla_evo.bg_color = Color(0.24, 0.17, 0.05, 0.95)
	_sb_badge_tecla_evo.set_border_width_all(1)
	_sb_badge_tecla_evo.border_color = Color(1.0, 0.84, 0.30, 1.0)
	_sb_badge_tecla_evo.set_corner_radius_all(5)
	_sb_badge_tecla_evo.content_margin_left = 7.0
	_sb_badge_tecla_evo.content_margin_right = 7.0
	_sb_badge_tecla_evo.content_margin_top = 3.0
	_sb_badge_tecla_evo.content_margin_bottom = 3.0
	badge_tecla.add_theme_stylebox_override("panel", _sb_badge_tecla_evo)
	hbox.add_child(badge_tecla)

	lbl_banner_evo_tecla = Label.new()
	lbl_banner_evo_tecla.name = "LabelTeclaEvo"
	lbl_banner_evo_tecla.text = "[V]"
	lbl_banner_evo_tecla.add_theme_font_size_override("font_size", 11)
	lbl_banner_evo_tecla.add_theme_color_override("font_color", Color(1.0, 0.94, 0.70, 1.0))
	lbl_banner_evo_tecla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_tecla.add_child(lbl_banner_evo_tecla)

func _conectar_evolucion_manager() -> void:
	var ev: Node = null
	if jugador != null and is_instance_valid(jugador):
		ev = jugador.get_node_or_null("EvolucionManager")
		if ev == null:
			for child in jugador.get_children():
				if child is EvolucionManager:
					ev = child
					break
	if ev == null and get_tree() != null:
		ev = get_tree().get_first_node_in_group("evolucion_manager")
	if ev == null or not is_instance_valid(ev):
		return

	evolucion_manager_ref = ev

	if ev.has_signal("hito_evolucion_disponible"):
		if not ev.hito_evolucion_disponible.is_connected(_on_hito_evolucion_disponible):
			ev.hito_evolucion_disponible.connect(_on_hito_evolucion_disponible)
	else:
		if ev.has_signal("metamorfosis_disponible") and not ev.metamorfosis_disponible.is_connected(_on_metamorfosis_disponible_legacy):
			ev.metamorfosis_disponible.connect(_on_metamorfosis_disponible_legacy)
		if ev.has_signal("mejora_tier2_disponible") and not ev.mejora_tier2_disponible.is_connected(_on_mejora_tier2_disponible_legacy):
			ev.mejora_tier2_disponible.connect(_on_mejora_tier2_disponible_legacy)
		if ev.has_signal("ascension_tier3_disponible") and not ev.ascension_tier3_disponible.is_connected(_on_ascension_tier3_disponible_legacy):
			ev.ascension_tier3_disponible.connect(_on_ascension_tier3_disponible_legacy)

	if ev.has_signal("progreso_evolucion_actualizado") and not ev.progreso_evolucion_actualizado.is_connected(_on_progreso_evolucion_actualizado):
		ev.progreso_evolucion_actualizado.connect(_on_progreso_evolucion_actualizado)
	if ev.has_signal("clase_evolucionada") and not ev.clase_evolucionada.is_connected(_on_evolucion_resuelta_hud):
		ev.clase_evolucionada.connect(_on_evolucion_resuelta_hud)
	if ev.has_signal("subclase_ascendida") and not ev.subclase_ascendida.is_connected(_on_evolucion_resuelta_hud):
		ev.subclase_ascendida.connect(_on_evolucion_resuelta_hud)
	if ev.has_signal("evolucion_completada") and not ev.evolucion_completada.is_connected(_on_evolucion_resuelta_hud):
		ev.evolucion_completada.connect(_on_evolucion_resuelta_hud)

	if ev.has_method("obtener_estado_progreso_compacto"):
		var info: Dictionary = ev.obtener_estado_progreso_compacto()
		_on_progreso_evolucion_actualizado(
			int(info.get("tier_objetivo", 0)),
			str(info.get("texto", "")),
			bool(info.get("listo", false))
		)
	if ev.has_method("tiene_evolucion_pendiente"):
		var tier_pend: int = int(ev.tiene_evolucion_pendiente())
		if tier_pend > 0 and not _banner_evolucion_activo:
			var pal := _obtener_paleta_evolucion(tier_pend)
			mostrar_banner_evolucion(tier_pend, str(pal["titulo"]), str(pal["subtitulo"]))

func _on_metamorfosis_disponible_legacy() -> void:
	var pal := _obtener_paleta_evolucion(1)
	mostrar_banner_evolucion(1, str(pal["titulo"]), str(pal["subtitulo"]))

func _on_mejora_tier2_disponible_legacy() -> void:
	var pal := _obtener_paleta_evolucion(2)
	mostrar_banner_evolucion(2, str(pal["titulo"]), str(pal["subtitulo"]))

func _on_ascension_tier3_disponible_legacy() -> void:
	var pal := _obtener_paleta_evolucion(3)
	mostrar_banner_evolucion(3, str(pal["titulo"]), str(pal["subtitulo"]))

func _on_hito_evolucion_disponible(tier: int, titulo: String, subtitulo: String) -> void:
	mostrar_banner_evolucion(tier, titulo, subtitulo)

func mostrar_banner_evolucion(tier: int, titulo: String = "", subtitulo: String = "") -> void:
	if banner_evolucion == null:
		return
	var tier_clamped := clampi(tier, 1, 3)
	var pal := _obtener_paleta_evolucion(tier_clamped)
	_banner_evolucion_tier = tier_clamped
	_banner_evolucion_activo = true

	var col_borde: Color = pal["borde"]
	var col_sombra: Color = pal["sombra"]
	if _sb_banner_evolucion != null:
		_sb_banner_evolucion.bg_color = pal["bg"]
		_sb_banner_evolucion.border_color = col_borde
		_sb_banner_evolucion.shadow_color = col_sombra
		_sb_banner_evolucion.shadow_size = 14
	if _sb_badge_tecla_evo != null:
		_sb_badge_tecla_evo.bg_color = pal["badge_bg"]
		_sb_badge_tecla_evo.border_color = col_borde
	if icono_banner_evo != null:
		icono_banner_evo.modulate = col_borde.lerp(Color.WHITE, 0.25)
	if lbl_banner_evo_titulo != null:
		lbl_banner_evo_titulo.text = titulo if not titulo.strip_edges().is_empty() else str(pal["titulo"])
		lbl_banner_evo_titulo.add_theme_color_override("font_color", pal["titulo_color"])
	if lbl_banner_evo_subtitulo != null:
		lbl_banner_evo_subtitulo.text = subtitulo if not subtitulo.strip_edges().is_empty() else str(pal["subtitulo"])
		lbl_banner_evo_subtitulo.add_theme_color_override("font_color", pal["sub_color"])
	if lbl_banner_evo_tecla != null:
		lbl_banner_evo_tecla.add_theme_color_override("font_color", pal["titulo_color"])

	if _tw_banner_evo_transicion != null and _tw_banner_evo_transicion.is_valid():
		_tw_banner_evo_transicion.kill()
	if _tw_banner_evo_pulso != null and _tw_banner_evo_pulso.is_valid():
		_tw_banner_evo_pulso.kill()

	banner_evolucion.visible = true
	banner_evolucion.pivot_offset = banner_evolucion.size * 0.5 if banner_evolucion.size.x > 10.0 else Vector2(225.0, 30.0)
	banner_evolucion.scale = Vector2(0.88, 0.88)
	banner_evolucion.modulate = Color(1.0, 1.0, 1.0, 0.0)

	_tw_banner_evo_transicion = create_tween()
	_tw_banner_evo_transicion.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tw_banner_evo_transicion.set_parallel(true)
	_tw_banner_evo_transicion.tween_property(banner_evolucion, "modulate:a", 1.0, 0.24)
	_tw_banner_evo_transicion.tween_property(banner_evolucion, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tw_banner_evo_transicion.finished.connect(_iniciar_pulso_banner_evolucion)

func _iniciar_pulso_banner_evolucion() -> void:
	if not _banner_evolucion_activo or banner_evolucion == null or not banner_evolucion.visible:
		return
	if _tw_banner_evo_pulso != null and _tw_banner_evo_pulso.is_valid():
		_tw_banner_evo_pulso.kill()
	_tw_banner_evo_pulso = create_tween()
	_tw_banner_evo_pulso.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tw_banner_evo_pulso.set_loops()
	_tw_banner_evo_pulso.tween_property(banner_evolucion, "scale", Vector2(1.035, 1.035), 0.78).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if _sb_banner_evolucion != null:
		_tw_banner_evo_pulso.parallel().tween_property(_sb_banner_evolucion, "shadow_size", 22, 0.78).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tw_banner_evo_pulso.tween_property(banner_evolucion, "scale", Vector2.ONE, 0.78).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if _sb_banner_evolucion != null:
		_tw_banner_evo_pulso.parallel().tween_property(_sb_banner_evolucion, "shadow_size", 12, 0.78).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func ocultar_banner_evolucion() -> void:
	_banner_evolucion_activo = false
	_banner_evolucion_tier = 0
	if _tw_banner_evo_pulso != null and _tw_banner_evo_pulso.is_valid():
		_tw_banner_evo_pulso.kill()
		_tw_banner_evo_pulso = null
	if _tw_banner_evo_transicion != null and _tw_banner_evo_transicion.is_valid():
		_tw_banner_evo_transicion.kill()
		_tw_banner_evo_transicion = null
	if banner_evolucion == null or not banner_evolucion.visible:
		return
	_tw_banner_evo_transicion = create_tween()
	_tw_banner_evo_transicion.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tw_banner_evo_transicion.set_parallel(true)
	_tw_banner_evo_transicion.tween_property(banner_evolucion, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tw_banner_evo_transicion.tween_property(banner_evolucion, "scale", Vector2(0.94, 0.94), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tw_banner_evo_transicion.finished.connect(func():
		if not _banner_evolucion_activo and banner_evolucion != null:
			banner_evolucion.visible = false
			banner_evolucion.scale = Vector2.ONE
			banner_evolucion.modulate = Color.WHITE
	)

func _on_evolucion_resuelta_hud(_nombre: String = "", _stats: Dictionary = {}) -> void:
	ocultar_banner_evolucion()
	if not _nombre.is_empty() and MALLAS_AVATAR.has(_nombre):
		_actualizar_avatar_clase(_nombre)

func _on_progreso_evolucion_actualizado(tier_objetivo: int, texto_progreso: String, listo: bool) -> void:
	if chip_evolucion_rail == null or lbl_chip_evo_rail == null:
		return
	if tier_objetivo <= 0 or texto_progreso.strip_edges().is_empty():
		_chip_evo_listo = false
		if _tw_chip_evo_pulso != null and _tw_chip_evo_pulso.is_valid():
			_tw_chip_evo_pulso.kill()
			_tw_chip_evo_pulso = null
		chip_evolucion_rail.modulate = Color.WHITE
		chip_evolucion_rail.visible = false
		return

	chip_evolucion_rail.visible = true
	lbl_chip_evo_rail.text = texto_progreso
	var pal := _obtener_paleta_evolucion(tier_objetivo)
	var col_borde: Color = pal["borde"]

	if listo:
		if _sb_chip_evo_rail != null:
			_sb_chip_evo_rail.bg_color = pal["bg"]
			_sb_chip_evo_rail.border_color = col_borde
			_sb_chip_evo_rail.shadow_color = pal["sombra"]
			_sb_chip_evo_rail.shadow_size = 8
		lbl_chip_evo_rail.add_theme_color_override("font_color", pal["titulo_color"])
		if not _chip_evo_listo:
			_chip_evo_listo = true
			if _tw_chip_evo_pulso != null and _tw_chip_evo_pulso.is_valid():
				_tw_chip_evo_pulso.kill()
			_tw_chip_evo_pulso = create_tween()
			_tw_chip_evo_pulso.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			_tw_chip_evo_pulso.set_loops()
			_tw_chip_evo_pulso.tween_property(chip_evolucion_rail, "modulate", Color(1.18, 1.15, 1.06, 1.0), 0.65).set_trans(Tween.TRANS_SINE)
			_tw_chip_evo_pulso.tween_property(chip_evolucion_rail, "modulate", Color.WHITE, 0.65).set_trans(Tween.TRANS_SINE)
	else:
		_chip_evo_listo = false
		if _tw_chip_evo_pulso != null and _tw_chip_evo_pulso.is_valid():
			_tw_chip_evo_pulso.kill()
			_tw_chip_evo_pulso = null
		chip_evolucion_rail.modulate = Color.WHITE
		if _sb_chip_evo_rail != null:
			_sb_chip_evo_rail.bg_color = Color(0.055, 0.068, 0.105, 0.92)
			_sb_chip_evo_rail.border_color = col_borde.darkened(0.42)
			_sb_chip_evo_rail.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
			_sb_chip_evo_rail.shadow_size = 4
		lbl_chip_evo_rail.add_theme_color_override("font_color", Color(0.90, 0.87, 0.78, 0.96))

func _on_banner_evolucion_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _solicitar_reabrir_evolucion():
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()

func _on_chip_evo_gui_input(event: InputEvent) -> void:
	if not _chip_evo_listo:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _solicitar_reabrir_evolucion():
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()

func _solicitar_reabrir_evolucion() -> bool:
	if evolucion_manager_ref == null or not is_instance_valid(evolucion_manager_ref):
		_conectar_evolucion_manager()
	if evolucion_manager_ref != null and is_instance_valid(evolucion_manager_ref) and evolucion_manager_ref.has_method("reabrir_evolucion_pendiente"):
		return bool(evolucion_manager_ref.reabrir_evolucion_pendiente())
	return false
