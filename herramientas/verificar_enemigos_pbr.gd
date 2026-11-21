extends SceneTree

const OUT_DIR := "C:/Users/USER/.gemini/antigravity/brain/c999e97c-985b-4dc3-aa3b-ad816d088d31/scratch/"

const ESPECIES: Array[Dictionary] = [
	{"id": "guardia", "nombre": "Guardia Pretoriano", "faccion": "Guarnicion", "escena": "res://guardia.tscn", "altura": 2.45},
	{"id": "arquero", "nombre": "Arquero Balistico", "faccion": "Guarnicion", "escena": "res://arquero.tscn", "altura": 2.30},
	{"id": "centurion", "nombre": "Centurion Corrupto", "faccion": "Guarnicion", "escena": "res://centurion_corrupto.tscn", "altura": 3.20},
	{"id": "mini_jefe", "nombre": "Heraldo de la Arena", "faccion": "Guarnicion", "escena": "res://mini_jefe.tscn", "altura": 3.40},
	{"id": "coloso", "nombre": "Coloso de Bronce", "faccion": "Guarnicion", "escena": "res://coloso_bronce.tscn", "altura": 4.85},
	{"id": "espectro", "nombre": "Espectro del Foso", "faccion": "Foso Bio-Hazard", "escena": "res://espectro.tscn", "altura": 2.00},
	{"id": "berserker", "nombre": "Berserker Rabioso", "faccion": "Foso Bio-Hazard", "escena": "res://berserker.tscn", "altura": 2.70},
	{"id": "kamikaze", "nombre": "Minero Kamikaze", "faccion": "Foso Bio-Hazard", "escena": "res://kamikaze.tscn", "altura": 1.55},
	{"id": "bruto", "nombre": "Bruto Aplastador", "faccion": "Foso Bio-Hazard", "escena": "res://bruto.tscn", "altura": 2.95},
	{"id": "parasito_cursor", "nombre": "Parasito del Cursor", "faccion": "Foso Bio-Hazard", "escena": "res://parasito_cursor.tscn", "altura": 0.90},
	{"id": "maestra", "nombre": "Maestra Sanguinaria", "faccion": "Corte Carmesi / Vacio", "escena": "res://maestra_sanguinaria.tscn", "altura": 3.45},
	{"id": "parca", "nombre": "La Parca Roja", "faccion": "Corte Carmesi / Vacio", "escena": "res://parca_roja.tscn", "altura": 4.15},
	{"id": "canalizador_vacio", "nombre": "Canalizador del Vacio", "faccion": "Corte Carmesi / Vacio", "escena": "res://canalizador_vacio.tscn", "altura": 2.45},
	{"id": "espejo_sombrio", "nombre": "El Espejo Sombrio", "faccion": "Corte Carmesi / Vacio", "escena": "res://espejo_sombrio.tscn", "altura": 2.90},
	{"id": "golem_tesoro", "nombre": "Golem de Tesoro", "faccion": "Corte Carmesi / Vacio", "escena": "res://golem_tesoro.tscn", "altura": 1.65},
	{"id": "heraldo_clic", "nombre": "Heraldo del Clic", "faccion": "Corte Carmesi / Vacio", "escena": "res://heraldo_clic.tscn", "altura": 2.55},
]


func _initialize() -> void:
	call_deferred("_ejecutar")


func _ejecutar() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var hacer_render: bool = ("--render" in args)
	var hacer_audit: bool = ("--audit" in args) or not hacer_render

	if hacer_audit:
		var ok: bool = await _ejecutar_auditoria()
		if not ok:
			quit(1)
			return
	if hacer_render:
		await _ejecutar_renders()
	quit(0)


func _calcular_aabb_en_raiz(nodo: Node, raiz_ref: Node3D) -> AABB:
	var xf_inv: Transform3D = raiz_ref.global_transform.affine_inverse()
	return _acumular_aabb(nodo, xf_inv, AABB())


func _acumular_aabb(nodo: Node, xf_inv: Transform3D, acc: AABB) -> AABB:
	var cur: AABB = acc
	if nodo is MeshInstance3D:
		var mi := nodo as MeshInstance3D
		if mi.mesh != null and mi.visible:
			var local_xf: Transform3D = xf_inv * mi.global_transform
			var b: AABB = local_xf * mi.mesh.get_aabb()
			if cur.size == Vector3.ZERO and cur.position == Vector3.ZERO:
				cur = b
			else:
				cur = cur.merge(b)
	for hijo in nodo.get_children():
		cur = _acumular_aabb(hijo, xf_inv, cur)
	return cur


func _recoger_errores_materiales(nodo: Node, contexto: String, errores: Array[String], info_out: Dictionary) -> void:
	if nodo is MeshInstance3D:
		var mi := nodo as MeshInstance3D
		if mi.is_visible_in_tree() and mi.mesh != null:
			var mats: Array[Material] = []
			if mi.material_override != null:
				mats.append(mi.material_override)
			for s in range(mi.mesh.get_surface_count()):
				var mat_s: Material = mi.get_active_material(s)
				if mat_s != null:
					mats.append(mat_s)
			for m in mats:
				if m is StandardMaterial3D:
					var sm := m as StandardMaterial3D
					if sm.cull_mode == BaseMaterial3D.CULL_FRONT and sm.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
						continue
					if sm.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
						errores.append("%s/%s usa SHADING_MODE_UNSHADED visible" % [contexto, mi.name])
						continue
					if sm.metallic > 0.65:
						errores.append("%s/%s metallic=%.2f > 0.65 (%s)" % [contexto, mi.name, sm.metallic, sm.resource_name])
					if sm.emission_enabled:
						info_out["max_em"] = maxf(float(info_out.get("max_em", 0.0)), sm.emission_energy_multiplier)
						if sm.emission_energy_multiplier > 0.72:
							errores.append("%s/%s emission=%.2f > 0.72 (%s)" % [contexto, mi.name, sm.emission_energy_multiplier, sm.resource_name])
					info_out["max_met"] = maxf(float(info_out.get("max_met", 0.0)), sm.metallic)
	if nodo is OmniLight3D:
		var ol := nodo as OmniLight3D
		if ol.is_visible_in_tree() and ol.light_energy > 0.5:
			errores.append("%s/%s OmniLight3D visible con energia %.2f > 0.5" % [contexto, ol.name, ol.light_energy])
	for hijo in nodo.get_children():
		_recoger_errores_materiales(hijo, contexto, errores, info_out)


func _desactivar_procesamiento(nodo: Node) -> void:
	nodo.set_process(false)
	nodo.set_physics_process(false)
	for h in nodo.get_children():
		_desactivar_procesamiento(h)


func _ejecutar_auditoria() -> bool:
	print("=================================================================")
	print("AUDITORIA PBR & ESTRUCTURAL DE LOS 16 ENEMIGOS")
	print("=================================================================")
	var errores: Array[String] = []

	for esp in ESPECIES:
		var id: String = String(esp["id"])
		var ruta: String = String(esp["escena"])
		var h_obj: float = float(esp["altura"])
		if not ResourceLoader.exists(ruta):
			errores.append("[%s] No existe escena: %s" % [id, ruta])
			continue
		var ps := load(ruta) as PackedScene
		if ps == null:
			errores.append("[%s] Error cargando PackedScene: %s" % [id, ruta])
			continue

		var inst := ps.instantiate() as Node3D
		if inst == null:
			errores.append("[%s] No instancia Node3D: %s" % [id, ruta])
			continue

		root.add_child(inst)
		await process_frame
		_desactivar_procesamiento(inst)

		var modelo := inst.get_node_or_null("Modelo") as Node3D
		if modelo == null:
			errores.append("[%s] Falta nodo hijo 'Modelo'" % id)
			inst.queue_free()
			await process_frame
			continue

		var ap: AnimationPlayer = AnimadorEntidad.buscar_animation_player(modelo)
		if ap == null:
			errores.append("[%s] Falta AnimationPlayer en Modelo" % id)
		else:
			var anims: PackedStringArray = ap.get_animation_list()
			for req in ["idle", "walk", "run", "hit"]:
				if not (req in anims):
					errores.append("[%s] Falta animacion requerida '%s'" % [id, req])

		if id == "canalizador_vacio":
			var nucleo := modelo.find_child("NucleoSingularidad", true, false) as MeshInstance3D
			if nucleo == null:
				errores.append("[canalizador_vacio] Falta MeshInstance3D 'NucleoSingularidad'")
			else:
				var ny: float = nucleo.global_position.y
				if ny < 1.55 or ny > 2.15:
					errores.append("[canalizador_vacio] NucleoSingularidad Y=%.2fm fuera de [1.55, 2.15]" % ny)

		var aabb: AABB = _calcular_aabb_en_raiz(modelo, inst)
		var h_real: float = aabb.size.y
		var base_y: float = aabb.position.y
		var tol: float = h_obj * 0.15
		if absf(h_real - h_obj) > tol:
			errores.append("[%s] Altura=%.2fm fuera de rango %.2fm +-15%%" % [id, h_real, h_obj])
		if base_y < -0.10 or base_y > 0.12:
			errores.append("[%s] Base Y=%.3fm fuera de [-0.10, 0.12]" % [id, base_y])

		var info_mat: Dictionary = {"max_em": 0.0, "max_met": 0.0}
		_recoger_errores_materiales(inst, id, errores, info_mat)

		var anim_cnt: int = ap.get_animation_list().size() if ap != null else 0
		print("  ✓ %-18s | H=%.2fm (obj=%.2f) | baseY=%+.3fm | anims=%d | maxEm=%.2f | maxMet=%.2f" % [
			id, h_real, h_obj, base_y, anim_cnt, float(info_mat["max_em"]), float(info_mat["max_met"])
		])

		inst.queue_free()
		await process_frame

	print("--- Smoke Test main.tscn + CodiceGladiadorUI (16 IDs Bestiario) ---")
	var main_ps := load("res://main.tscn") as PackedScene
	if main_ps == null:
		errores.append("[main] No se pudo cargar main.tscn")
	else:
		var main_inst := main_ps.instantiate()
		root.add_child(main_inst)
		await process_frame
		_desactivar_procesamiento(main_inst)

		var codice_scr := load("res://codice_gladiador_ui.gd") as Script
		if codice_scr == null:
			errores.append("[codice] No se pudo cargar codice_gladiador_ui.gd")
		else:
			var codice: Node = codice_scr.new()
			codice.process_mode = Node.PROCESS_MODE_ALWAYS
			main_inst.add_child(codice)
			codice.call("abrir", 2)
			paused = false
			await process_frame
			for esp in ESPECIES:
				var eid: String = String(esp["id"])
				codice.call("_seleccionar_enemigo_bestiario", eid)
				await process_frame
				var preview_inst: Variant = codice.get("instancia_malla_actual")
				if preview_inst == null:
					errores.append("[bestiario:%s] instancia_malla_actual es null" % eid)
			codice.call("cerrar")
			paused = false
		main_inst.queue_free()
		await process_frame

	print("=================================================================")
	if errores.is_empty():
		print("AUDIT_PASS: 16/16 enemigos, main.tscn y Bestiario validados sin errores.")
		print("=================================================================")
		return true

	print("AUDIT_FAIL: %d errores detectados:" % errores.size())
	for err in errores:
		printerr("  [FAIL] ", err)
	print("=================================================================")
	return false


func _ocultar_nodos_combate(n: Node) -> void:
	for hijo in n.get_children():
		if hijo is Light3D or hijo is CollisionShape3D or hijo is Area3D:
			if hijo is CanvasItem or hijo is Node3D:
				hijo.set("visible", false)
		else:
			var nl: String = hijo.name.to_lower()
			if nl.contains("telegraph") or nl.contains("marca") or nl.contains("aura") or nl.contains("escudo") or nl.contains("coraza") or nl.contains("burbuja") or nl.contains("laser"):
				if hijo is Node3D:
					(hijo as Node3D).visible = false
		_ocultar_nodos_combate(hijo)


func _ejecutar_renders() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	await _renderizar_galeria_estudio()
	await _renderizar_lineup_arena()


func _renderizar_galeria_estudio() -> void:
	print(">>> Renderizando galeria_16_enemigos_estudio.png (1920x1080)...")
	var cell_w := 480
	var cell_h := 270
	var atlas := Image.create(cell_w * 4, cell_h * 4, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0.05, 0.06, 0.08, 1.0))

	var vp := SubViewport.new()
	vp.size = Vector2i(cell_w, cell_h)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	vp.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(vp)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.085, 0.11, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.65)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.glow_intensity = 0.30
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 1.25
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)

	var l_key := DirectionalLight3D.new()
	l_key.rotation_degrees = Vector3(-35, 25, 0)
	l_key.light_color = Color(1.0, 0.98, 0.94)
	l_key.light_energy = 1.15
	vp.add_child(l_key)

	var l_fill := DirectionalLight3D.new()
	l_fill.rotation_degrees = Vector3(-20, -45, 0)
	l_fill.light_color = Color(0.65, 0.80, 1.0)
	l_fill.light_energy = 0.55
	vp.add_child(l_fill)

	var l_rim := DirectionalLight3D.new()
	l_rim.rotation_degrees = Vector3(30, 180, 0)
	l_rim.light_color = Color(1.0, 0.85, 0.6)
	l_rim.light_energy = 0.65
	vp.add_child(l_rim)

	var disco := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 2.4
	cm.bottom_radius = 2.5
	cm.height = 0.08
	var mat_d := StandardMaterial3D.new()
	mat_d.albedo_color = Color(0.14, 0.16, 0.19)
	mat_d.roughness = 0.86
	mat_d.metallic = 0.12
	cm.material = mat_d
	disco.mesh = cm
	disco.position = Vector3(0.0, -0.04, 0.0)
	vp.add_child(disco)

	var cam := Camera3D.new()
	cam.fov = 38.0
	cam.current = true
	vp.add_child(cam)

	var ui_layer := CanvasLayer.new()
	vp.add_child(ui_layer)
	var bar := ColorRect.new()
	bar.color = Color(0.04, 0.05, 0.07, 0.86)
	bar.position = Vector2(0, cell_h - 32)
	bar.size = Vector2(cell_w, 32)
	ui_layer.add_child(bar)
	var lbl := Label.new()
	lbl.position = Vector2(10, cell_h - 28)
	lbl.size = Vector2(cell_w - 20, 26)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98))
	ui_layer.add_child(lbl)

	var borde := ReferenceRect.new()
	borde.position = Vector2(0, 0)
	borde.size = Vector2(cell_w, cell_h)
	borde.border_color = Color(0.22, 0.26, 0.32, 1.0)
	borde.border_width = 2.0
	borde.editor_only = false
	ui_layer.add_child(borde)

	for i in range(ESPECIES.size()):
		var esp: Dictionary = ESPECIES[i]
		var ps := load(String(esp["escena"])) as PackedScene
		var inst := ps.instantiate() as Node3D
		inst.set_script(null)
		_ocultar_nodos_combate(inst)
		inst.rotation.y = PI + 0.45
		vp.add_child(inst)

		var mod := inst.get_node_or_null("Modelo") as Node3D
		if mod != null:
			var anim := AnimadorEntidad.new(mod)
			if anim.esta_listo():
				anim.reproducir_bucle("idle", 0.0, 1.0, 0)

		var aabb: AABB = _calcular_aabb_en_raiz(mod if mod != null else inst, inst)
		var h: float = maxf(aabb.size.y, 0.8)
		var w: float = maxf(aabb.size.x, aabb.size.z)
		var centro_y: float = aabb.position.y + h * 0.50
		var dist: float = maxf(h * 1.72, w * 1.65) + 0.55
		disco.scale = Vector3.ONE * clampf(w * 0.65, 0.75, 2.2)
		cam.look_at_from_position(Vector3(0.0, centro_y + h * 0.14, dist), Vector3(0.0, centro_y - h * 0.04, 0.0), Vector3.UP)
		lbl.text = "%02d. %s (%.2fm · %s)" % [i + 1, String(esp["nombre"]), h, String(esp["faccion"])]

		for _f in range(5):
			await process_frame

		var cell_img: Image = vp.get_texture().get_image()
		if cell_img != null:
			var col: int = i % 4
			var row: int = i / 4
			atlas.blit_rect(cell_img, Rect2i(0, 0, cell_w, cell_h), Vector2i(col * cell_w, row * cell_h))

		inst.queue_free()
		await process_frame

	vp.queue_free()
	await process_frame

	var out_path := OUT_DIR + "galeria_16_enemigos_estudio.png"
	atlas.save_png(out_path)
	print("✓ Guardado: %s (%dx%d)" % [out_path, atlas.get_width(), atlas.get_height()])


func _renderizar_lineup_arena() -> void:
	print(">>> Renderizando lineup_arena_main.png (1920x1080)...")
	var vp := SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	vp.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(vp)

	var main_ps := load("res://main.tscn") as PackedScene
	var main_inst := main_ps.instantiate() as Node3D
	vp.add_child(main_inst)
	await process_frame
	await process_frame

	# Pausar simulacion y ocultar UI/obstaculos que tapen la formacion
	for n_name in ["OleadasSpawner", "Partida", "GestorAltares", "GestorAnomalias", "GestorSantuarios", "ClickHUD", "PantallaFinPartida", "BotonMovil", "Obstaculos", "Personaje", "Camera3D"]:
		var nd := main_inst.get_node_or_null(n_name)
		if nd != null:
			_desactivar_procesamiento(nd)
			if nd is CanvasLayer:
				(nd as CanvasLayer).visible = false
			elif n_name in ["BotonMovil", "Obstaculos"] and nd is Node3D:
				(nd as Node3D).visible = false
			elif nd is Camera3D:
				(nd as Camera3D).current = false

	var pj := main_inst.get_node_or_null("Personaje") as Node3D
	if pj != null:
		pj.position = Vector3(-11.8, 0.0, 16.0)
		pj.rotation = Vector3(0.0, PI + 0.30, 0.0)
		var lbl_pj := Label3D.new()
		lbl_pj.text = "HEROE (~3.0m)"
		lbl_pj.font_size = 30
		lbl_pj.pixel_size = 0.0072
		lbl_pj.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl_pj.no_depth_test = true
		lbl_pj.modulate = Color(0.45, 0.92, 1.0, 0.96)
		lbl_pj.position = Vector3(0.0, 3.55, 0.0)
		pj.add_child(lbl_pj)

	# Disposicion en zona sur despejada del suelo plano (delante del nucleo central)
	var fila_trasera := ["coloso", "parca", "centurion", "mini_jefe", "maestra", "espejo_sombrio", "bruto", "berserker"]
	var fila_delantera := ["guardia", "arquero", "espectro", "kamikaze", "parasito_cursor", "canalizador_vacio", "golem_tesoro", "heraldo_clic"]

	var mapa_esp: Dictionary = {}
	for e in ESPECIES:
		mapa_esp[String(e["id"])] = e

	var sp_trasera := 2.95
	for idx in range(fila_trasera.size()):
		var eid: String = fila_trasera[idx]
		var x: float = -10.3 + float(idx) * sp_trasera
		_instanciar_en_lineup(main_inst, mapa_esp[eid], Vector3(x, 0.0, 11.2))

	var sp_delantera := 2.85
	for idx in range(fila_delantera.size()):
		var eid: String = fila_delantera[idx]
		var x: float = -8.4 + float(idx) * sp_delantera
		_instanciar_en_lineup(main_inst, mapa_esp[eid], Vector3(x, 0.0, 16.0))

	var cam := Camera3D.new()
	cam.fov = 42.0
	cam.current = true
	vp.add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 8.6, 33.5), Vector3(0.0, 1.8, 13.5), Vector3.UP)

	var ui := CanvasLayer.new()
	vp.add_child(ui)
	var banner := ColorRect.new()
	banner.color = Color(0.03, 0.04, 0.06, 0.78)
	banner.position = Vector2(0, 0)
	banner.size = Vector2(1920, 40)
	ui.add_child(banner)
	var txt := Label.new()
	txt.position = Vector2(18, 8)
	txt.text = "LINEUP IN-ARENA (main.tscn): Izquierda = Heroe Rookie (~3.0m ref) | Fila Delantera = Tropas & Especiales | Fila Trasera = Pesados & Jefes"
	txt.add_theme_font_size_override("font_size", 18)
	txt.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98))
	ui.add_child(txt)

	await process_frame
	for _f in range(6):
		await process_frame

	var img: Image = vp.get_texture().get_image()
	var out_path := OUT_DIR + "lineup_arena_main.png"
	if img != null:
		img.save_png(out_path)
		print("✓ Guardado: %s (%dx%d)" % [out_path, img.get_width(), img.get_height()])

	vp.queue_free()
	await process_frame


func _instanciar_en_lineup(padre: Node3D, esp: Dictionary, pos: Vector3) -> void:
	var ps := load(String(esp["escena"])) as PackedScene
	if ps == null:
		return
	var inst := ps.instantiate() as Node3D
	padre.add_child(inst)
	inst.position = pos
	inst.rotation = Vector3(0.0, PI, 0.0)
	_desactivar_procesamiento(inst)

	var lbl := Label3D.new()
	lbl.text = String(esp["nombre"])
	lbl.font_size = 30
	lbl.pixel_size = 0.0072
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.modulate = Color(0.92, 0.95, 1.0, 0.92)
	lbl.position = Vector3(0.0, float(esp["altura"]) + 0.55, 0.0)
	lbl.rotation = Vector3(0.0, -PI, 0.0)
	inst.add_child(lbl)
