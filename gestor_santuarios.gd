extends Node
class_name GestorSantuarios

## GestorSantuarios - Coordina el Presagio inicial, la colocación de santuarios
## y ánforas rompibles en la arena, la reposición por oleadas y el pity de 180 s.

const EstatuaScript = preload("res://estatua_fortuna.gd")
const ArenaColiseo = preload("res://arena_coliseo.gd")
const ForjaScript = preload("res://forja_vulcano.gd")
const FuenteScript = preload("res://fuente_deseos.gd")
const AnforaScript = preload("res://anfora_rompible.gd")
const CofreScript = preload("res://cofre_gladiador.gd")
const PactoScript = preload("res://pacto_marte.gd")

const INTERVALO_PITY_SANTUARIO: float = 150.0
const MAX_ANFORAS_OLEADA: int = 6
const MAX_SANTUARIOS_ACTIVOS: int = 5

const PUNTOS_SPAWN_VERIFICADOS: Array[Vector3] = [
	# Foso Central interior/medio (Y = 0.00 m, 10 puntos libres de Núcleo y rampas)
	Vector3(-15.0, 0.0, 4.5),
	Vector3(15.0, 0.0, -4.5),
	Vector3(5.0, 0.0, 16.5),
	Vector3(-5.0, 0.0, -16.5),
	Vector3(-19.5, 0.0, -10.5),
	Vector3(19.5, 0.0, 10.5),
	Vector3(21.5, 0.0, -6.5),
	Vector3(-21.5, 0.0, 6.5),
	Vector3(11.0, 0.0, 22.0),
	Vector3(-11.0, 0.0, -22.0),
	# Anillo Exterior del Foso (Y = 0.00 m, 10 puntos distribuidos en r = 28..35 m)
	Vector3(10.9, 0.0, -30.1),
	Vector3(30.1, 0.0, -10.9),
	Vector3(30.1, 0.0, 10.9),
	Vector3(10.9, 0.0, 30.1),
	Vector3(-10.9, 0.0, 30.1),
	Vector3(-30.1, 0.0, 10.9),
	Vector3(-30.1, 0.0, -10.9),
	Vector3(-10.9, 0.0, -30.1),
	Vector3(22.5, 0.0, -25.0),
	Vector3(-22.5, 0.0, 25.0),
	# Bastiones Diagonales (Y = +0.40 m, 4 decks planos a r = 34 m)
	Vector3(24.0, 0.40, -24.0),
	Vector3(24.0, 0.40, 24.0),
	Vector3(-24.0, 0.40, 24.0),
	Vector3(-24.0, 0.40, -24.0),
	# Pasarela Perimetral (Y = +0.80 m, 12 sectores en r = 46.0 m)
	Vector3(11.9, 0.80, -44.4),
	Vector3(32.5, 0.80, -32.5),
	Vector3(44.4, 0.80, -11.9),
	Vector3(44.4, 0.80, 11.9),
	Vector3(32.5, 0.80, 32.5),
	Vector3(11.9, 0.80, 44.4),
	Vector3(-11.9, 0.80, 44.4),
	Vector3(-32.5, 0.80, 32.5),
	Vector3(-44.4, 0.80, 11.9),
	Vector3(-44.4, 0.80, -11.9),
	Vector3(-32.5, 0.80, -32.5),
	Vector3(-11.9, 0.80, -44.4),
]

@export var pausar_en_jefes: bool = true

var _presagio_actual: Dictionary = {}
var _banner_mostrado: bool = false
var _ultima_oleada: int = 1
var _reloj_pity_santuario: float = 0.0
var _spawner_ref: Node = null
var _arena_inicial_desplegada: bool = false
var _oleadas_santuarios_desplegadas: Dictionary = {}

func _ready() -> void:
	add_to_group("gestor_santuarios")
	call_deferred("_inicializar_run")

func _inicializar_run() -> void:
	if not is_inside_tree():
		return
	_presagio_actual = FortunaManager.tirar_presagio()

	_spawner_ref = get_tree().get_first_node_in_group("spawner")
	if _spawner_ref != null and "oleada_actual" in _spawner_ref:
		_ultima_oleada = int(_spawner_ref.oleada_actual)

	var boton := get_tree().get_first_node_in_group("boton_movil")
	if boton != null and boton.has_signal("click_presionado"):
		boton.click_presionado.connect(_on_primer_click_boton)
		if "total_clicks" in boton and int(boton.total_clicks) > 0:
			_mostrar_banner_presagio(_presagio_actual)
			_desplegar_inicio_combate()
	else:
		_mostrar_banner_presagio(_presagio_actual)

func _on_primer_click_boton(_total_clicks: int) -> void:
	if not _banner_mostrado and not _presagio_actual.is_empty():
		_mostrar_banner_presagio(_presagio_actual)
	_desplegar_inicio_combate()

func _desplegar_inicio_combate() -> void:
	if _arena_inicial_desplegada:
		return
	_arena_inicial_desplegada = true
	var libres := _obtener_puntos_libres()
	var cant_anforas: int = FortunaManager.rng.randi_range(2, 3)
	for i in range(mini(cant_anforas, libres.size())):
		_instanciar_interactuable(AnforaScript, libres[i])

func _hay_jefe_activo() -> bool:
	if _spawner_ref != null and is_instance_valid(_spawner_ref) and _spawner_ref.has_method("hay_jefe_activo"):
		if bool(_spawner_ref.hay_jefe_activo()):
			return true
	var tree := get_tree()
	if tree == null:
		return false
	for grupo in ["jefes", "bosses"]:
		for n in tree.get_nodes_in_group(grupo):
			if is_instance_valid(n) and not n.is_queued_for_deletion():
				var esta_muerto := ("muerto" in n and bool(n.muerto))
				var tiene_vida := (not ("vida" in n) or float(n.vida) > 0.0)
				if not esta_muerto and tiene_vida:
					return true
	for p in tree.get_nodes_in_group("portal_spawn"):
		if is_instance_valid(p) and not p.is_queued_for_deletion() and ("es_jefe" in p and bool(p.es_jefe)):
			if not ("_spawneado" in p) or not bool(p._spawneado):
				return true
	return false

func _process(delta: float) -> void:
	if not is_inside_tree() or get_tree() == null:
		return
	if _spawner_ref == null or not is_instance_valid(_spawner_ref):
		_spawner_ref = get_tree().get_first_node_in_group("spawner")
	if _spawner_ref == null:
		return

	var partida_iniciada := bool(_spawner_ref.get("partida_iniciada"))
	if not partida_iniciada:
		return

	if not _arena_inicial_desplegada:
		_desplegar_inicio_combate()

	if pausar_en_jefes and _hay_jefe_activo():
		return

	# Reposición de ánforas y despliegue escalonado de santuarios al subir de oleada
	if "oleada_actual" in _spawner_ref:
		var oleada_ahora := int(_spawner_ref.oleada_actual)
		if oleada_ahora > _ultima_oleada:
			var prev_ol := _ultima_oleada
			_ultima_oleada = oleada_ahora
			_reponer_anforas_oleada()
			_desplegar_santuarios_por_oleada(prev_ol, oleada_ahora)

	# Pity de 150s sin activar ningún santuario (solo activo a partir de Oleada 3)
	if _ultima_oleada >= 3:
		_reloj_pity_santuario += delta
		if _reloj_pity_santuario >= INTERVALO_PITY_SANTUARIO:
			_reloj_pity_santuario = 0.0
			_forzar_santuario_pity()

func _desplegar_santuarios_por_oleada(prev_oleada: int, oleada_ahora: int) -> void:
	if get_tree() == null:
		return
	var techo_santuarios: int = MAX_SANTUARIOS_ACTIVOS + maxi(0, FortunaManager.santuarios_extra)
	for ol in range(prev_oleada + 1, oleada_ahora + 1):
		if _oleadas_santuarios_desplegadas.has(ol):
			continue
		_oleadas_santuarios_desplegadas[ol] = true
		var santuarios_activos := get_tree().get_nodes_in_group("santuarios").size()
		if santuarios_activos >= techo_santuarios:
			continue
		var libres := _obtener_puntos_libres()
		if libres.is_empty():
			continue
		var script_elegido = null
		if ol == 3:
			script_elegido = EstatuaScript
		elif ol == 4:
			script_elegido = FuenteScript
		elif ol == 5:
			var pool_mid := [ForjaScript, CofreScript, PactoScript]
			script_elegido = pool_mid[FortunaManager.rng.randi_range(0, pool_mid.size() - 1)]
		elif ol >= 7 and ol % 2 == 1:
			var pool_late := [EstatuaScript, FuenteScript, ForjaScript, CofreScript, PactoScript]
			script_elegido = pool_late[FortunaManager.rng.randi_range(0, pool_late.size() - 1)]
		if script_elegido != null:
			_instanciar_interactuable(script_elegido, libres[0])


func _poblar_arena_inicial() -> void:
	var arena := get_parent()
	if arena == null:
		return

	var puntos: Array[Vector3] = []
	puntos.assign(PUNTOS_SPAWN_VERIFICADOS)
	_barajar_con_rng(puntos)

	# 1. Santuarios garantizados: al menos 1 Estatua de Fortuna y 1 Fuente de los Deseos
	var scripts_santuarios: Array = [EstatuaScript, FuenteScript]
	var conteo := {
		"estatua": 1,
		"fuente": 1,
		"forja": 0,
		"cofre": 0,
		"pacto": 0,
	}

	var cant_anforas: int = FortunaManager.rng.randi_range(4, 5)
	var cant_extras: int = FortunaManager.rng.randi_range(2, 5) + FortunaManager.santuarios_extra
	var max_santuarios: int = PUNTOS_SPAWN_VERIFICADOS.size() - cant_anforas
	var total_santuarios_objetivo: int = mini(2 + cant_extras, max_santuarios)

	var candidatos: Array[Dictionary] = [
		{"clave": "forja", "script": ForjaScript, "max": 2},
		{"clave": "cofre", "script": CofreScript, "max": 2},
		{"clave": "pacto", "script": PactoScript, "max": 2},
		{"clave": "estatua", "script": EstatuaScript, "max": 2},
		{"clave": "fuente", "script": FuenteScript, "max": 2},
	]

	var intentos := 0
	while scripts_santuarios.size() < total_santuarios_objetivo and intentos < 40:
		intentos += 1
		var c: Dictionary = candidatos[FortunaManager.rng.randi_range(0, candidatos.size() - 1)]
		var clave: String = String(c["clave"])
		if int(conteo[clave]) < int(c["max"]):
			conteo[clave] = int(conteo[clave]) + 1
			scripts_santuarios.append(c["script"])

	var idx_punto := 0
	for scr in scripts_santuarios:
		if idx_punto >= puntos.size():
			break
		_instanciar_interactuable(scr, puntos[idx_punto])
		idx_punto += 1

	for _a in range(cant_anforas):
		if idx_punto >= puntos.size():
			break
		_instanciar_interactuable(AnforaScript, puntos[idx_punto])
		idx_punto += 1

func _reponer_anforas_oleada() -> void:
	if get_tree() == null:
		return
	var actuales: int = get_tree().get_nodes_in_group("rompibles").size()
	var faltantes: int = MAX_ANFORAS_OLEADA - actuales
	if faltantes <= 0:
		return
	var libres := _obtener_puntos_libres()
	for i in range(mini(faltantes, libres.size())):
		_instanciar_interactuable(AnforaScript, libres[i])

func _forzar_santuario_pity() -> void:
	if get_tree() == null:
		return
	var techo_santuarios: int = MAX_SANTUARIOS_ACTIVOS + maxi(0, FortunaManager.santuarios_extra)
	if get_tree().get_nodes_in_group("santuarios").size() >= techo_santuarios:
		return
	var libres := _obtener_puntos_libres()
	if libres.is_empty():
		return
	var opciones := [EstatuaScript, FuenteScript, CofreScript, ForjaScript]
	var elegido = opciones[FortunaManager.rng.randi_range(0, opciones.size() - 1)]
	_instanciar_interactuable(elegido, libres[0])

func _instanciar_interactuable(script_clase, pos: Vector3) -> Node:
	var arena := get_parent()
	if arena == null or script_clase == null:
		return null
	var nodo: Node = script_clase.new()
	arena.add_child(nodo)
	if nodo is Node3D:
		var pos_final: Vector3 = ArenaColiseo.clamping_y_ajustar_a_suelo(pos, 2.2, 0.0)
		var rng: RandomNumberGenerator = ArenaColiseo._obtener_rng_run(self)
		var pj: Node3D = get_tree().get_first_node_in_group("jugador") as Node3D if get_tree() != null else null
		for _j in range(12):
			var jx: float = rng.randf_range(-3.5, 3.5)
			var jz: float = rng.randf_range(-3.5, 3.5)
			var cand := Vector3(pos.x + jx, 0.0, pos.z + jz)
			if not ArenaColiseo.esta_dentro(cand, 2.2):
				continue
			if ArenaColiseo.esta_en_pendiente(cand.x, cand.z, 0.8):
				continue
			if not ArenaColiseo.punto_libre_de_obstaculos(cand, 2.8):
				continue
			var m_c: float = ArenaColiseo.apotema_en_pos(cand.x, cand.z)
			if m_c >= (ArenaColiseo.APOTEMA_FOSO - 1.3) and m_c <= (ArenaColiseo.APOTEMA_FOSO + 1.3):
				continue
			if pj != null and is_instance_valid(pj):
				if Vector2(cand.x - pj.global_position.x, cand.z - pj.global_position.z).length() < 4.0:
					continue
			pos_final = ArenaColiseo.clamping_y_ajustar_a_suelo(cand, 2.2, 0.0)
			break
		(nodo as Node3D).global_position = pos_final
	if nodo.has_signal("activado"):
		nodo.activado.connect(_on_santuario_activado)
	return nodo

func _on_santuario_activado(_santuario) -> void:
	_reloj_pity_santuario = 0.0

func _obtener_puntos_libres() -> Array[Vector3]:
	var libres: Array[Vector3] = []
	var ocupados: Array = []
	if get_tree() != null:
		ocupados.append_array(get_tree().get_nodes_in_group("santuarios"))
		ocupados.append_array(get_tree().get_nodes_in_group("rompibles"))
	var pj: Node = get_tree().get_first_node_in_group("jugador") if get_tree() != null else null

	for p in PUNTOS_SPAWN_VERIFICADOS:
		var libre := true
		if pj is Node3D and Vector2(p.x - (pj as Node3D).global_position.x, p.z - (pj as Node3D).global_position.z).length() < 3.5:
			libre = false
		if libre:
			for o in ocupados:
				if is_instance_valid(o) and o is Node3D:
					var pos_o: Vector3 = (o as Node3D).global_position
					var d: float = Vector2(p.x - pos_o.x, p.z - pos_o.z).length()
					if d < 3.0:
						libre = false
						break
		if libre:
			libres.append(p)

	_barajar_con_rng(libres)
	return libres

func _barajar_con_rng(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = FortunaManager.rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

func _mostrar_banner_presagio(presagio: Dictionary) -> void:
	if _banner_mostrado or get_tree() == null:
		return
	_banner_mostrado = true

	var capa := CanvasLayer.new()
	capa.layer = 22
	add_child(capa)

	var marco := PanelContainer.new()
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco.set_anchors_preset(Control.PRESET_TOP_WIDE)
	marco.offset_left = 290
	marco.offset_top = 136
	marco.offset_right = -290
	marco.offset_bottom = 216

	var color_borde: Color = presagio.get("color", Color(0.92, 0.78, 0.35))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.043, 0.051, 0.082, 0.94)
	sb.border_color = color_borde
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(0, 0, 0, 0.75)
	sb.shadow_size = 12
	marco.add_theme_stylebox_override("panel", sb)
	marco.modulate = Color(1.0, 1.0, 1.0, 0.0)
	capa.add_child(marco)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	marco.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var lbl_tit := Label.new()
	lbl_tit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_tit.text = "%s PRESAGIO: %s" % [String(presagio.get("icono", "☀️")), String(presagio.get("nombre", "Cielo Despejado")).to_upper()]
	lbl_tit.add_theme_font_size_override("font_size", 19)
	lbl_tit.add_theme_color_override("font_color", color_borde)
	vbox.add_child(lbl_tit)

	var lbl_desc := Label.new()
	lbl_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc.text = String(presagio.get("descripcion", ""))
	lbl_desc.add_theme_font_size_override("font_size", 14)
	lbl_desc.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98))
	vbox.add_child(lbl_desc)

	var tw := capa.create_tween()
	tw.tween_property(marco, "modulate:a", 1.0, 0.35)
	tw.tween_interval(2.75)
	tw.tween_property(marco, "modulate:a", 0.0, 0.4)
	tw.finished.connect(capa.queue_free)


