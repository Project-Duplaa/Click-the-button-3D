extends Node3D
class_name AmbienteIndustrialPBR

## AmbienteIndustrialPBR — Transformación Visual Integral PBR & Sci-Fi Industrial
## Preserva texturas UV originales enriquecidas con mapas normales/ORM, elimina charcos
## planos neón sustituyéndolos por derrames aceitosos oscuros, estiliza el núcleo cian
## con corona carmesí, consolida LEDs en MultiMesh y añade la consola amarilla y cables.

const SHADER_FLOOR := preload("res://shaders/industrial_steel_floor.gdshader")
const SHADER_PBR := preload("res://shaders/industrial_pbr_material.gdshader")
const TEX_FLOOR_MICRO_N := preload("res://assets/texturas_pbr/floor_micro_normal.png")
const TEX_METAL_N := preload("res://assets/texturas_pbr/metal_brush_normal.png")
const TEX_METAL_ORM := preload("res://assets/texturas_pbr/metal_brush_orm.png")
const TEX_GRATE_N := preload("res://assets/texturas_pbr/grate_industrial_normal.png")
const TEX_GRATE_ORM := preload("res://assets/texturas_pbr/grate_industrial_orm.png")
const SCENE_CMD_TERMINAL := preload("res://assets/modelos/prop_command_terminal.glb")

var _mats_cache: Dictionary = {}
var _crate_led_transforms: Array[Transform3D] = []

func _ready() -> void:
	call_deferred("_aplicar_transformacion_completa")

func _aplicar_transformacion_completa() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var arena := get_parent()
	if arena == null:
		return

	_crate_led_transforms.clear()
	_aplicar_suelo_industrial_pbr(arena)
	_transformar_nucleo_central_y_rejillas(arena)
	_aplicar_materiales_muros_y_techo(arena)
	_procesar_props_en_rama(arena)

	var main_node := arena.get_parent()
	if main_node != null:
		_procesar_props_en_rama(main_node.get_node_or_null("Obstaculos"))
		_procesar_props_en_rama(main_node.get_node_or_null("DecoracionesArena"))
		_agregar_anillo_tactico_jugador(main_node)
		_agregar_anillo_seguridad_boton(main_node)
		_agregar_anillos_objetivos(main_node)

	_construir_multimesh_leds_cajas()
	_construir_detalles_ambientales_scifi(arena)

# ==============================================================================
# 1. SUELO INDUSTRIAL DE PLACAS ASIMÉTRICAS
# ==============================================================================

func _aplicar_suelo_industrial_pbr(arena: Node) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_FLOOR
	mat.set_shader_parameter("micro_normal_tex", TEX_FLOOR_MICRO_N)
	mat.set_shader_parameter("grate_normal_tex", TEX_GRATE_N)
	mat.set_shader_parameter("grate_orm_tex", TEX_GRATE_ORM)
	mat.set_shader_parameter("plate_size", 4.0)
	mat.set_shader_parameter("micro_uv_scale", 0.36)
	mat.set_shader_parameter("normal_strength", 0.48)

	var piso_mesh := arena.get_node_or_null("Piso/MeshInstance3D") as MeshInstance3D
	if piso_mesh != null:
		piso_mesh.visible = false

	var anf := arena.get_node_or_null("GeometriaAnfiteatro") as Node3D
	if anf != null:
		var malla_foso := anf.get_node_or_null("PisoFoso/MallaFoso") as MeshInstance3D
		if malla_foso != null:
			malla_foso.visible = false
		var malla_pasarela := anf.get_node_or_null("PasarelaPerimetral/MallaPasarela") as MeshInstance3D
		if malla_pasarela != null:
			var mat_pas := _get_pbr_mat("anf_pasarela_pbr", 0, Color(0.24, 0.27, 0.32), Color(0.32, 0.36, 0.42), 0.30, 0.55)
			malla_pasarela.material_override = mat_pas
		_estilizar_superficies_anfiteatro(anf)

	# Subdividir el suelo visual en tiles 8x8 (13.5m x 13.5m) para evitar el limite de 8 luces por malla en gl_compatibility
	var prev_tiles := get_node_or_null("PisoIndustrialTiles")
	if prev_tiles != null:
		prev_tiles.queue_free()

	var tiles_root := Node3D.new()
	tiles_root.name = "PisoIndustrialTiles"
	add_child(tiles_root)

	var tile_plane := PlaneMesh.new()
	tile_plane.size = Vector2(13.5, 13.5)
	tile_plane.subdivide_width = 3
	tile_plane.subdivide_depth = 3

	for ix: int in range(8):
		var cx: float = -47.25 + float(ix) * 13.5
		for iz: int in range(8):
			var cz: float = -47.25 + float(iz) * 13.5
			var tile := MeshInstance3D.new()
			tile.name = "Tile_%d_%d" % [ix, iz]
			tile.mesh = tile_plane
			tile.position = Vector3(cx, 0.004, cz)
			tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			tile.material_override = mat
			tiles_root.add_child(tile)

func _estilizar_superficies_anfiteatro(anf: Node3D) -> void:
	var mat_bastion := _get_pbr_mat("anf_bastion_pbr", 0, Color(0.21, 0.24, 0.29), Color(0.29, 0.33, 0.39), 0.32, 0.60)
	var mat_rampa := _get_pbr_mat("anf_rampa_pbr", 2, Color(0.28, 0.32, 0.38), Color(0.36, 0.40, 0.47), 0.25, 0.65)
	var stack: Array[Node] = [anf]
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		if curr is MeshInstance3D:
			var mi := curr as MeshInstance3D
			if mi.name == "MallaRampa":
				mi.material_override = mat_rampa
			elif mi.name == "VisualApron" or mi.name.begins_with("Bastion"):
				mi.material_override = mat_bastion
		for child in curr.get_children():
			stack.append(child)

# ==============================================================================
# 2. BIOCONTENEDOR CIAN CON CORONA ROJA Y ANILLO DE REJILLAS
# ==============================================================================

func _transformar_nucleo_central_y_rejillas(arena: Node) -> void:
	var nucleo := arena.get_node_or_null("NucleoBioEstatico") as Node3D
	if nucleo != null:
		var luz_central := nucleo.get_node_or_null("LuzRadioactivaCentral") as OmniLight3D
		if luz_central != null:
			luz_central.light_color = Color(0.0, 0.88, 1.0, 1.0)
			luz_central.light_energy = 3.2
			luz_central.omni_range = 14.5
			luz_central.omni_attenuation = 1.05

		if nucleo.get_node_or_null("LuzReboteSueloCyan") == null:
			var luz_suelo := OmniLight3D.new()
			luz_suelo.name = "LuzReboteSueloCyan"
			luz_suelo.position = Vector3(0.0, 0.35, 0.0)
			luz_suelo.light_color = Color(0.0, 0.84, 1.0, 1.0)
			luz_suelo.light_energy = 2.0
			luz_suelo.omni_range = 9.0
			luz_suelo.omni_attenuation = 1.15
			luz_suelo.shadow_enabled = false
			nucleo.add_child(luz_suelo)

		var modelo_bio := nucleo.get_node_or_null("ModeloBiocontenedor") as Node3D
		if modelo_bio != null:
			var mat_acero_osc := _get_pbr_mat("bio_dark_steel", 0, Color(0.11, 0.14, 0.18), Color(0.24, 0.28, 0.34), 0.35)
			var mat_aluminio := _get_pbr_mat("bio_bright_steel", 2, Color(0.32, 0.38, 0.46), Color(0.54, 0.60, 0.68), 0.25)
			# Emisión calibrada a 2.1 para no quemar a blanco el interior del cilindro
			var mat_plasma_cian := _get_emissive_mat("bio_cyan_plasma", Color(0.05, 0.78, 0.92), Color(0.0, 0.86, 1.0), 2.1, 0.14)
			var mat_gauge_cian := _get_emissive_mat("bio_gauge_cyan", Color(0.10, 0.82, 0.95), Color(0.0, 0.84, 1.0), 1.8, 0.22)
			_override_por_nombre_material(modelo_bio, {
				"Mat_BioDarkSteel": mat_acero_osc,
				"Mat_BioBrightSteel": mat_aluminio,
				"Mat_BioToxicFluid": mat_plasma_cian,
				"Mat_BioBubbleGlow": mat_plasma_cian,
				"Mat_BioGauge": mat_gauge_cian,
			}, mat_acero_osc)

			# Corona superior roja carmesí visible y proporcionada en la tapa del reactor
			var corona_prev := nucleo.get_node_or_null("CoronaReactorCarmesi")
			if corona_prev != null:
				corona_prev.queue_free()
			var aabb := _computar_aabb_local(modelo_bio, nucleo)
			var corona_y: float = clampf(aabb.position.y + aabb.size.y * 0.85, 2.2, 3.6) if aabb.size.y > 0.5 else 2.85
			var mat_carmesi := _get_emissive_mat("corona_carmesi", Color(0.92, 0.12, 0.20), Color(1.0, 0.14, 0.24), 2.8, 0.24)
			BunkerVisualKit.make_torus(
				nucleo,
				"CoronaReactorCarmesi",
				1.15,
				1.42,
				mat_carmesi,
				Vector3(0.0, corona_y, 0.0),
				Vector3.ZERO,
				40,
				14
			)

	# Plataforma central: preservar texturas UV originales enriquecidas con PBR
	var plat_central := arena.get_node_or_null("PlataformaCentral") as Node3D
	if plat_central != null:
		_enriquecer_uv_pbr(plat_central, TEX_METAL_N, TEX_METAL_ORM, 0.34, 0.42, 0.42)

	# Anillo de rejillas: preservar texturas UV originales y eliminar cualquier FosoOscuroRejilla
	var anillo_rejillas := arena.get_node_or_null("AnilloRejillas") as Node3D
	if anillo_rejillas != null:
		var foso_prev := anillo_rejillas.get_node_or_null("FosoOscuroRejilla")
		if foso_prev != null:
			foso_prev.queue_free()
		_enriquecer_uv_pbr_rejilla(anillo_rejillas)

	# Limpiar desorden visual en el primer plano sobre el anillo y alrededor del stencil A-01
	var det := arena.get_node_or_null("DetallesCentro") as Node3D
	if det != null:
		for nombre_oculto: String in ["CamillaMockup_1", "CamillaMockup_2", "CamillaMockup_3", "BarreraMockup_2", "RampaCentro_S"]:
			var n_occ := det.get_node_or_null(nombre_oculto) as Node3D
			if n_occ != null:
				n_occ.visible = false
		var caja3 := det.get_node_or_null("CajaMockup_3") as Node3D
		if caja3 != null:
			caja3.position = Vector3(-3.15, 0.04, 0.85)
			caja3.rotation_degrees = Vector3(0.0, 18.0, 0.0)

# ==============================================================================
# 3. MUROS Y TECHO
# ==============================================================================

func _aplicar_materiales_muros_y_techo(arena: Node) -> void:
	var muros := arena.get_node_or_null("Muros") as Node3D
	if muros != null:
		var mat_muro_grafito := _get_pbr_mat("wall_graphite", 0, Color(0.11, 0.13, 0.17), Color(0.22, 0.26, 0.32), 0.30, 0.65, 0.40)
		var mat_cornisa := _get_pbr_mat("wall_cornice", 0, Color(0.08, 0.10, 0.13), Color(0.18, 0.21, 0.26), 0.30, 0.55)
		var mat_red_tube := _get_emissive_mat("wall_bulkhead_red", Color(1.0, 0.20, 0.12), Color(1.0, 0.14, 0.08), 3.0, 0.20)

		for muro in muros.get_children():
			for child in muro.get_children():
				if child is MeshInstance3D:
					var mi := child as MeshInstance3D
					mi.material_override = mat_cornisa if "Cornisa" in mi.name else mat_muro_grafito
				elif child is OmniLight3D:
					var ol := child as OmniLight3D
					ol.light_color = Color(1.0, 0.22, 0.10, 1.0)
					ol.light_energy = 1.45
					ol.omni_range = 8.5
				elif child.scene_file_path != "":
					_enriquecer_uv_pbr(child, TEX_METAL_N, TEX_METAL_ORM, 0.36, 0.44, 0.42, {"Mat_BulkheadRed": mat_red_tube})

	var techo := arena.get_node_or_null("Techo") as Node3D
	if techo != null:
		var mat_techo := _get_pbr_mat("ceiling_steel", 0, Color(0.07, 0.08, 0.11), Color(0.14, 0.16, 0.20), 0.20, 0.5)
		for child in techo.get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).material_override = mat_techo

# ==============================================================================
# 4. FAMILIAS PBR EN CONTENEDORES, BARRERAS, CHARCOS Y EQUIPAMIENTO
# ==============================================================================

func _procesar_props_en_rama(root_branch: Node) -> void:
	if root_branch == null:
		return
	var stack: Array[Node] = [root_branch]
	var idx_crate: int = 0
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		if curr == self:
			continue
		var scn_path: String = curr.scene_file_path
		if scn_path.ends_with("prop_military_crate.glb"):
			_estilizar_caja(curr as Node3D, idx_crate)
			idx_crate += 1
			continue
		elif scn_path.ends_with("prop_hazard_barrier.glb"):
			_estilizar_barrera(curr as Node3D)
			continue
		elif scn_path.ends_with("prop_pressure_tank.glb"):
			_estilizar_tanque(curr as Node3D)
			continue
		elif scn_path.ends_with("prop_bunker_generator.glb"):
			_enriquecer_uv_pbr(curr, TEX_METAL_N, TEX_METAL_ORM, 0.35, 0.44, 0.40)
			continue
		elif scn_path.ends_with("prop_server_rack.glb"):
			_estilizar_servidor(curr as Node3D)
			continue
		elif scn_path.ends_with("prop_hazard_lockers.glb"):
			_enriquecer_uv_pbr(curr, TEX_METAL_N, TEX_METAL_ORM, 0.30, 0.48, 0.38)
			continue
		elif scn_path.ends_with("prop_cable_ramp.glb"):
			_estilizar_rampa_cable(curr as Node3D)
			continue
		elif scn_path.ends_with("prop_toxic_barrel.glb"):
			_enriquecer_uv_pbr(curr, TEX_METAL_N, TEX_METAL_ORM, 0.28, 0.52, 0.38)
			continue
		elif scn_path.ends_with("prop_medical_stretcher.glb"):
			_estilizar_camilla(curr as Node3D)
			continue
		elif scn_path.ends_with("prop_acid_puddle.glb") or scn_path.ends_with("prop_oil_puddle.glb"):
			_estilizar_charco_industrial(curr as Node3D)
			continue

		for child in curr.get_children():
			stack.append(child)

func _estilizar_caja(caja: Node3D, idx: int) -> void:
	if caja == null:
		return
	var es_amarilla: bool = (idx % 3 == 1)
	var tinte := Color(1.15, 0.86, 0.35) if es_amarilla else Color(0.88, 0.94, 0.85)
	_enriquecer_uv_pbr(caja, TEX_METAL_N, TEX_METAL_ORM, 0.32, 0.46, 0.42, {}, tinte)

	var aabb := _computar_aabb_local(caja, caja)
	var top_y: float = aabb.position.y + aabb.size.y + 0.012 if aabb.size.y > 0.15 else 0.72
	for offset_x: float in [-0.20, 0.0, 0.20]:
		var local_xf := Transform3D(Basis.IDENTITY, Vector3(offset_x, top_y, 0.0))
		_crate_led_transforms.append(caja.global_transform * local_xf)

func _estilizar_barrera(barrera: Node3D) -> void:
	_enriquecer_uv_pbr(barrera, TEX_METAL_N, TEX_METAL_ORM, 0.18, 0.68, 0.45)

func _estilizar_tanque(tanque: Node3D) -> void:
	var mat_hull := _get_pbr_mat("tank_petrol_alu", 2, Color(0.22, 0.34, 0.44), Color(0.45, 0.58, 0.68), 0.30, 0.85, 0.32)
	var mat_base := _get_pbr_mat("tank_base_steel", 0, Color(0.12, 0.15, 0.19), Color(0.26, 0.30, 0.36), 0.28)
	var mat_valve := _get_pbr_mat("tank_valve_red", 1, Color(0.72, 0.16, 0.14), Color(0.48, 0.52, 0.58), 0.35)
	var mat_copper := _get_pbr_mat("tank_copper", 2, Color(0.70, 0.42, 0.22), Color(0.86, 0.62, 0.42), 0.25)
	_override_por_nombre_material(tanque, {
		"Mat_TankHull": mat_hull,
		"Mat_TankBase": mat_base,
		"Mat_ValveRed": mat_valve,
		"Mat_TankPipes": mat_copper,
	}, mat_hull)

func _estilizar_servidor(srv: Node3D) -> void:
	var mat_rack := _get_pbr_mat("srv_steel", 0, Color(0.11, 0.14, 0.18), Color(0.24, 0.29, 0.36), 0.30)
	var mat_led := _get_emissive_mat("srv_led_cyan", Color(0.0, 0.90, 1.0), Color(0.0, 0.92, 1.0), 2.2, 0.15)
	var mat_amber := _get_emissive_mat("srv_led_amber", Color(1.0, 0.62, 0.08), Color(1.0, 0.55, 0.05), 2.0, 0.15)
	_override_por_nombre_material(srv, {
		"Mat_RackSteel": mat_rack,
		"Mat_RackLED": mat_led,
		"Mat_RackAmber": mat_amber,
	}, mat_rack)

func _estilizar_rampa_cable(ramp: Node3D) -> void:
	var mat_yel := _get_pbr_mat("ramp_yellow", 1, Color(0.84, 0.58, 0.06), Color(0.32, 0.36, 0.42), 0.35)
	var mat_blk := _get_pbr_mat("ramp_rubber", 3, Color(0.07, 0.08, 0.10), Color(0.14, 0.15, 0.18), 0.20)
	_override_por_nombre_material(ramp, {
		"Mat_CableRampYellow": mat_yel,
		"Mat_CableRampBlack": mat_blk,
		"Mat_CablesCore": mat_blk,
	}, mat_blk)

func _estilizar_camilla(cam: Node3D) -> void:
	var mat_alu := _get_pbr_mat("stretcher_alu", 2, Color(0.34, 0.39, 0.46), Color(0.55, 0.62, 0.70), 0.25)
	_override_por_nombre_material(cam, {}, mat_alu)

func _estilizar_charco_industrial(charco: Node3D) -> void:
	if not _mats_cache.has("wet_oil_puddle"):
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.03, 0.05, 0.07, 0.58)
		mat.roughness = 0.08
		mat.metallic = 0.55
		mat.emission_enabled = false
		_mats_cache["wet_oil_puddle"] = mat
	var mat_oil: StandardMaterial3D = _mats_cache["wet_oil_puddle"]
	var stack: Array[Node] = [charco]
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		if curr is MeshInstance3D:
			(curr as MeshInstance3D).material_override = mat_oil
		for child in curr.get_children():
			stack.append(child)

# ==============================================================================
# 5. MULTIMESH LEDS DE CAJAS Y DETALLES AMBIENTALES SCI-FI
# ==============================================================================

func _construir_multimesh_leds_cajas() -> void:
	if _crate_led_transforms.is_empty():
		return
	var existente := get_node_or_null("LEDsCajasMultiMesh")
	if existente != null:
		existente.queue_free()

	var box := BoxMesh.new()
	box.size = Vector3(0.095, 0.028, 0.048)
	box.material = _get_emissive_mat("crate_amber_led", Color(1.0, 0.68, 0.14), Color(1.0, 0.52, 0.04), 2.8, 0.18)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = box
	mm.instance_count = _crate_led_transforms.size()
	for i: int in range(_crate_led_transforms.size()):
		mm.set_instance_transform(i, _crate_led_transforms[i])

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "LEDsCajasMultiMesh"
	mmi.top_level = true
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

func _construir_detalles_ambientales_scifi(arena: Node) -> void:
	# A. Consola amarilla limpia orientada hacia la cámara junto al borde delantero del anillo
	var prev_cmd := get_node_or_null("ConsolaAdvertenciaCentral")
	if prev_cmd != null:
		prev_cmd.queue_free()
	if SCENE_CMD_TERMINAL != null:
		var consola_wrap := Node3D.new()
		consola_wrap.name = "ConsolaAdvertenciaCentral"
		consola_wrap.position = Vector3(-2.55, 0.02, 3.35)
		consola_wrap.rotation_degrees = Vector3(0.0, 28.0, 0.0)
		add_child(consola_wrap)

		var term := SCENE_CMD_TERMINAL.instantiate() as Node3D
		if term != null:
			term.scale = Vector3.ONE
			consola_wrap.add_child(term)
			var mat_yel := _get_pbr_mat("cmd_yellow", 1, Color(0.86, 0.58, 0.08), Color(0.36, 0.40, 0.46), 0.35)
			var mat_dark := _get_pbr_mat("cmd_dark", 0, Color(0.11, 0.14, 0.18), Color(0.24, 0.28, 0.34), 0.30)
			var mat_scr := _get_emissive_mat("cmd_screen_navy", Color(0.04, 0.25, 0.45), Color(0.04, 0.38, 0.68), 1.1, 0.15)
			_override_por_nombre_material(term, {
				"Mat_HazardYellow": mat_yel,
				"Mat_Olive": mat_yel,
				"Mat_SteelDark": mat_dark,
				"Mat_SteelMid": mat_dark,
				"Mat_CmdScreen1": mat_scr,
				"Mat_CmdScreen2": mat_scr,
				"Mat_GlowCyan": mat_scr,
			}, mat_yel)

			var warn_lbl := Label3D.new()
			warn_lbl.name = "IconoAlertaPantalla"
			warn_lbl.text = "⚠"
			warn_lbl.font_size = 76
			warn_lbl.pixel_size = 0.0042
			warn_lbl.modulate = Color(0.45, 0.98, 1.0, 1.0)
			warn_lbl.outline_size = 6
			warn_lbl.outline_modulate = Color(0.0, 0.18, 0.32, 1.0)
			warn_lbl.shaded = false
			warn_lbl.position = Vector3(0.0, 1.32, 0.20)
			consola_wrap.add_child(warn_lbl)

	# B. Zócalos LED cian en base de muros perimetrales
	if get_node_or_null("ZocalosLEDCian") == null:
		var bar_mesh := BoxMesh.new()
		bar_mesh.size = Vector3(4.2, 0.06, 0.10)
		bar_mesh.material = _get_emissive_mat("plinth_cyan_led", Color(0.1, 0.92, 1.0), Color(0.0, 0.90, 1.0), 2.4, 0.14)

		var xforms: Array[Transform3D] = []
		var tiene_anf: bool = arena.get_node_or_null("GeometriaAnfiteatro") != null
		if tiene_anf:
			for k_ang: int in range(8):
				var ang: float = float(k_ang) * (PI * 0.25)
				var pos_bar := Vector3(sin(ang) * 38.5, 0.04, -cos(ang) * 38.5)
				var rot_bar := Basis(Vector3.UP, -ang)
				xforms.append(Transform3D(rot_bar, pos_bar))
		else:
			for coord: float in [-21.0, -10.5, 10.5, 21.0]:
				xforms.append(Transform3D(Basis.IDENTITY, Vector3(coord, 0.04, -29.6)))
				xforms.append(Transform3D(Basis.IDENTITY, Vector3(coord, 0.04, 29.6)))
				var rot_y := Basis(Vector3.UP, PI * 0.5)
				xforms.append(Transform3D(rot_y, Vector3(-29.6, 0.04, coord)))
				xforms.append(Transform3D(rot_y, Vector3(29.6, 0.04, coord)))

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = bar_mesh
		mm.instance_count = xforms.size()
		for i: int in range(xforms.size()):
			mm.set_instance_transform(i, xforms[i])

		var mmi := MultiMeshInstance3D.new()
		mmi.name = "ZocalosLEDCian"
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)

	# C. Cables industriales de caucho en suelo conectando pilares al anillo central
	if get_node_or_null("CablesSuelo") == null:
		var cables_node := Node3D.new()
		cables_node.name = "CablesSuelo"
		add_child(cables_node)
		var mat_cable := _get_pbr_mat("floor_cable", 3, Color(0.05, 0.055, 0.065), Color(0.12, 0.14, 0.17), 0.15)
		var tramos: Array[Dictionary] = [
			{"a": Vector3(4.41, 0.018, -2.55), "b": Vector3(6.8, 0.018, -1.8)},
			{"a": Vector3(4.41, 0.018, 2.55), "b": Vector3(7.6, 0.018, 3.8)},
			{"a": Vector3(-4.41, 0.018, 2.55), "b": Vector3(-7.4, 0.018, 4.1)},
			{"a": Vector3(-2.35, 0.018, 3.15), "b": Vector3(-4.8, 0.018, 4.5)},
		]
		for t_idx: int in range(tramos.size()):
			var p_a: Vector3 = tramos[t_idx]["a"]
			var p_b: Vector3 = tramos[t_idx]["b"]
			var mid: Vector3 = (p_a + p_b) * 0.5
			var seg: Vector3 = p_b - p_a
			var dist := seg.length()
			var cable := MeshInstance3D.new()
			cable.name = "CableTramo_%d" % t_idx
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.032
			cyl.bottom_radius = 0.032
			cyl.height = dist
			cyl.radial_segments = 8
			cable.mesh = cyl
			cable.material_override = mat_cable
			cable.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cables_node.add_child(cable)
			cable.position = mid
			var dir_xz := Vector2(seg.x, seg.z).angle()
			cable.rotation = Vector3(0.0, -dir_xz, PI * 0.5)

func _agregar_anillo_tactico_jugador(main_node: Node) -> void:
	var pj := main_node.get_node_or_null("Personaje") as Node3D
	if pj == null or pj.get_node_or_null("AnilloTacticoPies") != null:
		return
	var anillo := BunkerVisualKit.create_hazard_ground_ring(
		0.92,
		BunkerVisualKit.COL_CYAN_ELECTRIC,
		BunkerVisualKit.COL_CYAN_ELECTRIC,
		0.78,
		0.95,
		0.72,
		0.04
	)
	anillo.name = "AnilloTacticoPies"
	anillo.position = Vector3(0.0, 0.025, 0.0)
	var smat := anillo.material_override as ShaderMaterial
	if smat != null:
		smat.set_shader_parameter("segment_duty_cycle", 1.0)
		smat.set_shader_parameter("progress", 1.0)
		smat.set_shader_parameter("active_state", 1.0)
		smat.set_shader_parameter("emission_strength", 2.0)
		smat.set_shader_parameter("overall_alpha", 0.85)
	pj.add_child(anillo)

func _agregar_anillo_seguridad_boton(main_node: Node) -> void:
	var boton := main_node.get_node_or_null("BotonMovil") as Node3D
	if boton == null or main_node.get_node_or_null("AnilloBasePedestal") != null:
		return
	var anillo := BunkerVisualKit.create_hazard_ground_ring(
		1.55,
		BunkerVisualKit.COL_HAZARD_YELLOW,
		BunkerVisualKit.COL_CYAN_ELECTRIC,
		0.76,
		0.96,
		0.55,
		0.0
	)
	anillo.name = "AnilloBasePedestal"
	anillo.position = Vector3(boton.position.x, 0.022, boton.position.z)
	main_node.add_child(anillo)

func _agregar_anillos_objetivos(main_node: Node) -> void:
	for nombre: String in ["Cofre1", "Cofre2", "Cofre3"]:
		var nodo := main_node.get_node_or_null(nombre) as Node3D
		if nodo != null and nodo.get_node_or_null("AnilloSeguridadProp") == null:
			var ring := BunkerVisualKit.create_hazard_ground_ring(
				1.35,
				BunkerVisualKit.COL_HAZARD_YELLOW,
				BunkerVisualKit.COL_HAZARD_YELLOW,
				0.76,
				0.96,
				0.65,
				0.0
			)
			ring.name = "AnilloSeguridadProp"
			ring.position = Vector3(0.0, 0.02, 0.0)
			nodo.add_child(ring)

# ==============================================================================
# HELPERS DE PRESERVACIÓN UV + ENRIQUECIMIENTO PBR
# ==============================================================================

func _enriquecer_uv_pbr(
	root: Node,
	normal_tex: Texture2D,
	orm_tex: Texture2D,
	metal: float,
	rough: float,
	normal_scale: float,
	special_overrides: Dictionary = {},
	albedo_tint: Color = Color.WHITE
) -> void:
	if root == null:
		return
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		if curr is MeshInstance3D:
			var mi := curr as MeshInstance3D
			var mesh: Mesh = mi.mesh
			if mesh != null:
				for s: int in range(mesh.get_surface_count()):
					var orig: Material = mesh.surface_get_material(s)
					var m_name: String = orig.resource_name if orig != null else ""
					if special_overrides.has(m_name):
						mi.set_surface_override_material(s, special_overrides[m_name] as Material)
						continue
					if orig is StandardMaterial3D:
						var std_orig := orig as StandardMaterial3D
						if std_orig.emission_enabled and std_orig.emission_energy_multiplier > 0.5:
							continue
						var mat := std_orig.duplicate() as StandardMaterial3D
						if albedo_tint != Color.WHITE:
							mat.albedo_color = std_orig.albedo_color * albedo_tint
						mat.metallic = metal
						mat.metallic_specular = 0.45
						mat.roughness = maxf(rough, 0.42)
						mat.normal_enabled = true
						mat.normal_texture = normal_tex
						mat.normal_scale = minf(normal_scale, 0.28)
						mat.ao_enabled = true
						mat.ao_texture = orm_tex
						mat.ao_light_affect = 0.45
						mi.set_surface_override_material(s, mat)
		for child in curr.get_children():
			stack.append(child)

func _enriquecer_uv_pbr_rejilla(root: Node) -> void:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		if curr is MeshInstance3D:
			var mi := curr as MeshInstance3D
			var mesh: Mesh = mi.mesh
			if mesh != null:
				for s: int in range(mesh.get_surface_count()):
					var orig: Material = mesh.surface_get_material(s)
					if orig is StandardMaterial3D:
						var mat := (orig as StandardMaterial3D).duplicate() as StandardMaterial3D
						var m_name := orig.resource_name
						if "Grate" in m_name or "Grate" in mi.name:
							mat.normal_enabled = true
							mat.normal_texture = TEX_GRATE_N
							mat.normal_scale = 0.28
							mat.ao_enabled = true
							mat.ao_texture = TEX_GRATE_ORM
							mat.metallic = 0.42
							mat.metallic_specular = 0.45
							mat.roughness = 0.42
						else:
							mat.normal_enabled = true
							mat.normal_texture = TEX_METAL_N
							mat.normal_scale = 0.28
							mat.ao_enabled = true
							mat.ao_texture = TEX_METAL_ORM
							mat.metallic = 0.32
							mat.metallic_specular = 0.45
							mat.roughness = 0.42
						mi.set_surface_override_material(s, mat)
		for child in curr.get_children():
			stack.append(child)

func _get_pbr_mat(
	key: String,
	family: int,
	col_a: Color,
	col_b: Color,
	_wear: float = 0.35,
	tri_scale: float = 0.85,
	_grime: float = 0.35,
	_haz_band: bool = false
) -> StandardMaterial3D:
	if _mats_cache.has(key):
		return _mats_cache[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	var scale_uv: float = maxf(0.20, tri_scale)
	var es_triplanar: bool = key.begins_with("anf_") or key.begins_with("wall_")
	mat.albedo_color = col_a.lerp(col_b, 0.28)
	match family:
		0: # Acero oscuro / grafito estructural
			mat.metallic = 0.38
			mat.roughness = 0.48
		1: # Metal pintado industrial
			mat.metallic = 0.25
			mat.roughness = 0.50
		2: # Aluminio / acero cepillado brillante
			mat.metallic = 0.55
			mat.roughness = 0.40
		3: # Polimero tecnico / caucho
			mat.metallic = 0.10
			mat.roughness = 0.65
		_:
			mat.metallic = 0.35
			mat.roughness = 0.48
	mat.metallic_specular = 0.42
	if es_triplanar:
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = false
		mat.uv1_triplanar_sharpness = 4.0
		mat.uv1_scale = Vector3(scale_uv, scale_uv, scale_uv)
		mat.normal_enabled = false
	else:
		mat.uv1_triplanar = false
		mat.normal_enabled = true
		mat.normal_texture = TEX_METAL_N
		mat.normal_scale = 0.24
	mat.ao_enabled = true
	mat.ao_texture = TEX_METAL_ORM
	mat.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.ao_light_affect = 0.45
	_mats_cache[key] = mat
	return mat

func _get_emissive_mat(
	key: String,
	albedo: Color,
	emissive: Color,
	energy: float,
	rough: float
) -> StandardMaterial3D:
	if _mats_cache.has(key):
		return _mats_cache[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = rough
	mat.metallic = 0.15
	mat.emission_enabled = true
	mat.emission = emissive
	mat.emission_energy_multiplier = energy
	_mats_cache[key] = mat
	return mat

func _override_por_nombre_material(root: Node, mapa: Dictionary, fallback: Material) -> void:
	if root == null:
		return
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		if curr is MeshInstance3D:
			var mi := curr as MeshInstance3D
			var mesh: Mesh = mi.mesh
			if mesh != null:
				for s: int in range(mesh.get_surface_count()):
					var orig: Material = mesh.surface_get_material(s)
					var m_name: String = orig.resource_name if orig != null else ""
					var chosen: Material = null
					if mapa.has(m_name):
						chosen = mapa[m_name] as Material
					else:
						for k: String in mapa.keys():
							if m_name.begins_with(k):
								chosen = mapa[k] as Material
								break
					if chosen != null:
						mi.set_surface_override_material(s, chosen)
					elif fallback != null:
						mi.set_surface_override_material(s, fallback)
		for child in curr.get_children():
			stack.append(child)

func _computar_aabb_local(nodo: Node3D, espacio_ref: Node3D) -> AABB:
	var result := AABB()
	var primero: bool = true
	var inv_ref := espacio_ref.global_transform.affine_inverse()
	var stack: Array[Node] = [nodo]
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		if curr is MeshInstance3D:
			var mi := curr as MeshInstance3D
			if mi.mesh != null:
				var xf := inv_ref * mi.global_transform
				var box := xf * mi.mesh.get_aabb()
				if primero:
					result = box
					primero = false
				else:
					result = result.merge(box)
		for child in curr.get_children():
			stack.append(child)
	return result
