extends Area3D

## Salida — Portal de Ascensión Místico
## Inicia completamente SELLADO en tonalidad violeta oscura.
## Se desbloquea únicamente al abatir al Jefe Final (La Parca Roja) o al superar la prueba de 15 minutos.
## Al desbloquearse transmuta en esmeralda radiante y permite al jugador ascender para ganar la partida.

@export var portal_abierto: bool = false

var _label_info: Label3D = null
var _luz_portal: OmniLight3D = null
var _mesh_portal: MeshInstance3D = null

func _ready():
	add_to_group("portal_ascension")
	body_entered.connect(_al_entrar)
	_configurar_componentes_visuales()
	_actualizar_estado_visual()

func _configurar_componentes_visuales():
	_mesh_portal = get_node_or_null("MeshInstance3D")
	
	_luz_portal = get_node_or_null("LuzPortal")
	if _luz_portal == null:
		_luz_portal = OmniLight3D.new()
		_luz_portal.name = "LuzPortal"
		_luz_portal.omni_range = 6.0
		add_child(_luz_portal)
		
	_label_info = get_node_or_null("LabelPortal")
	if _label_info == null:
		_label_info = Label3D.new()
		_label_info.name = "LabelPortal"
		_label_info.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_label_info.no_depth_test = true
		_label_info.outline_size = 10
		_label_info.font_size = 40
		_label_info.position = Vector3(0.0, 2.4, 0.0)
		add_child(_label_info)

func _process(_delta: float):
	if not portal_abierto:
		var partida = get_tree().get_first_node_in_group("partida")
		if partida != null:
			var parca_muerta = ("parca_derrotada" in partida and partida.parca_derrotada)
			var tiempo_agotado = ("tiempo" in partida and partida.tiempo <= 0.001)
			if parca_muerta or (tiempo_agotado and _sin_jefes_vivos()):
				desbloquear_portal()

func _sin_jefes_vivos() -> bool:
	var jefes = get_tree().get_nodes_in_group("jefes")
	if jefes.is_empty():
		jefes = get_tree().get_nodes_in_group("bosses")
	return jefes.is_empty()

func desbloquear_portal():
	if portal_abierto:
		return
	portal_abierto = true
	_actualizar_estado_visual()
	
	var dopamina = get_tree().get_first_node_in_group("audio_dopamina")
	if dopamina != null and dopamina.has_method("play_level_up"):
		dopamina.play_level_up()

func _actualizar_estado_visual():
	if _label_info != null:
		if portal_abierto:
			_label_info.text = "¡PORTAL DE ASCENSIÓN ABIERTO!\n[Pisa el portal para ascender a la Gloria]"
			_label_info.modulate = Color(0.25, 1.0, 0.55)
		else:
			_label_info.text = "PORTAL DE ASCENSIÓN\n[Derrota a La Parca Roja en Oleada 15]"
			_label_info.modulate = Color(0.75, 0.35, 1.0)
			
	if _luz_portal != null:
		if portal_abierto:
			_luz_portal.light_color = Color(0.2, 1.0, 0.5)
			_luz_portal.light_energy = 4.5
		else:
			_luz_portal.light_color = Color(0.45, 0.15, 0.75)
			_luz_portal.light_energy = 2.0

func _al_entrar(cuerpo: Node3D):
	if not (cuerpo.is_in_group("player") or cuerpo.is_in_group("jugador")):
		return
		
	if not portal_abierto:
		var pool_dano = get_tree().get_first_node_in_group("damage_numbers")
		if pool_dano != null and pool_dano.has_method("mostrar_texto"):
			pool_dano.mostrar_texto(global_position + Vector3(0, 2.0, 0), "🔒 ¡Portal Sellado! Elimina la amenaza colosal.", Color(1.0, 0.3, 0.3), 1.2)
		return
		
	var partida = get_tree().get_first_node_in_group("partida")
	if partida != null and partida.has_method("ganar"):
		partida.ganar()
