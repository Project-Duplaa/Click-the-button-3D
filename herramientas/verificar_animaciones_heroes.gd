@tool
extends SceneTree

## ==============================================================================
## AUDITORÍA Y RENDER VISUAL DE RIG ARTICULADO Y ANIMACIONES (4 HÉROES)
## Uso:
##   Godot --headless --path . --script res://herramientas/verificar_animaciones_heroes.gd -- --audit
##   Godot --path . --script res://herramientas/verificar_animaciones_heroes.gd -- --render
## ==============================================================================

const CLASES := [
	{"id": "rookie", "label": "NOVATO", "clase_juego": "Novato", "glb": "res://personaje/player_rookie.glb"},
	{"id": "warrior", "label": "GUERRERO", "clase_juego": "Guerrero", "glb": "res://personaje/player_warrior.glb"},
	{"id": "archer", "label": "ARQUERO", "clase_juego": "Cazador", "glb": "res://personaje/player_archer.glb"},
	{"id": "mage", "label": "MAGO", "clase_juego": "Mago", "glb": "res://personaje/player_mage.glb"},
]

const HUESOS_ESPERADOS := {
	"root": "",
	"leg-left": "root",
	"shin-left": "leg-left",
	"foot-left": "shin-left",
	"leg-right": "root",
	"shin-right": "leg-right",
	"foot-right": "shin-right",
	"torso": "root",
	"arm-left": "torso",
	"forearm-left": "arm-left",
	"hand-left": "forearm-left",
	"arm-right": "torso",
	"forearm-right": "arm-right",
	"hand-right": "forearm-right",
	"head": "torso",
}

const CLIPS_ESPERADOS: Array[String] = [
	"idle", "static", "holding-both", "block-walk", "holding-right-shoot",
	"walk", "run", "sprint",
	"attack-melee-right", "attack-melee-left", "shoot-bow", "cast-magic",
	"whirlwind", "dash", "hit", "crouch", "jump", "fall", "die", "telegraph", "stunned",
]

const SOLE_SAMPLE_POINTS: Array[Vector3] = [
	Vector3(0.0, -0.037, -0.042),
	Vector3(0.0, -0.037, 0.016),
	Vector3(-0.022, -0.037, 0.072),
	Vector3(0.022, -0.037, 0.072),
]

const OUT_DIR := "C:/Users/USER/.gemini/antigravity/brain/c999e97c-985b-4dc3-aa3b-ad816d088d31/scratch"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var modo_render := ("--render" in args)
	if modo_render:
		await _ejecutar_render()
	else:
		await _ejecutar_auditoria()


func _medir_pie_y_rodilla(inst: Node3D) -> Dictionary:
	var base_y := inst.global_position.y
	var min_y := 999.0
	for fn: String in ["foot-left", "foot-right"]:
		var f_node := inst.find_child(fn, true, false) as Node3D
		if f_node == null:
			continue
		var gp: Transform3D = f_node.global_transform
		for pt: Vector3 in SOLE_SAMPLE_POINTS:
			var wy := (gp * pt).y - base_y
			if wy < min_y:
				min_y = wy
	var sl_node := inst.find_child("shin-left", true, false) as Node3D
	var sr_node := inst.find_child("shin-right", true, false) as Node3D
	var kl := rad_to_deg(sl_node.quaternion.get_angle()) if sl_node != null else 0.0
	var kr := rad_to_deg(sr_node.quaternion.get_angle()) if sr_node != null else 0.0
	var fr_node := inst.find_child("forearm-right", true, false) as Node3D
	var er := rad_to_deg(fr_node.quaternion.get_angle()) if fr_node != null else 0.0
	var h_node := inst.find_child("head", true, false) as Node3D
	var hy := (h_node.global_position.y - base_y) if h_node != null else 0.0
	var t_node := inst.find_child("torso", true, false) as Node3D
	var ty := (t_node.global_position.y - base_y) if t_node != null else 1.0
	return {
		"min_sole_y": min_y,
		"max_knee_deg": maxf(kl, kr),
		"elbow_r_deg": er,
		"head_y": hy,
		"torso_y": ty,
	}


func _evaluar_pose(ap: AnimationPlayer, clip: String, t: float) -> void:
	ap.stop()
	ap.play(clip)
	ap.seek(t, true)
	ap.advance(0.0)
	ap.pause()


func _buscar_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c in n.get_children():
		var r := _buscar_ap(c)
		if r != null:
			return r
	return null


func _ejecutar_auditoria() -> void:
	var fallos: Array[String] = []
	var aprobados := 0

	for info: Dictionary in CLASES:
		var cid: String = info["id"]
		var ruta: String = info["glb"]
		var ps := load(ruta) as PackedScene
		if ps == null:
			fallos.append("%s: no se pudo cargar %s" % [cid, ruta])
			continue
		var inst := ps.instantiate() as Node3D
		root.add_child(inst)
		await process_frame

		var ap := _buscar_ap(inst)
		if ap == null:
			fallos.append("%s: falta AnimationPlayer" % cid)
			inst.queue_free()
			continue

		# 1. Validar los 15 nodos articulares y su jerarquía padre-hijo exacta
		var ok_hero := true
		for b_name: String in HUESOS_ESPERADOS.keys():
			var b_node := inst.find_child(b_name, true, false) as Node3D
			if b_node == null:
				fallos.append("%s: falta nodo articular '%s'" % [cid, b_name])
				ok_hero = false
				continue
			var p_esperado: String = HUESOS_ESPERADOS[b_name]
			if p_esperado != "":
				var p_real: String = "" if b_node.get_parent() == null else String(b_node.get_parent().name)
				if p_real != p_esperado:
					fallos.append("%s: nodo '%s' tiene padre '%s' (esperado '%s')" % [cid, b_name, p_real, p_esperado])
					ok_hero = false

		# 2. Validar los 21 clips y densidad de keyframes
		for c_name: String in CLIPS_ESPERADOS:
			if not ap.has_animation(c_name):
				fallos.append("%s: falta animación '%s'" % [cid, c_name])
				ok_hero = false
				continue
			var a := ap.get_animation(c_name)
			if a.get_track_count() < 15:
				fallos.append("%s/%s: tracks=%d (< 15)" % [cid, c_name, a.get_track_count()])
				ok_hero = false
			var max_keys := 0
			for ti in range(a.get_track_count()):
				max_keys = maxi(max_keys, a.track_get_key_count(ti))
			var min_keys := 1 if c_name == "static" else (10 if c_name in ["dash", "hit"] else 12)
			if max_keys < min_keys:
				fallos.append("%s/%s: muy pocas claves (%d < %d)" % [cid, c_name, max_keys, min_keys])
				ok_hero = false

		# 3. Validar cinemática real (suelo, rodillas, codo arquero, cabeza retrato)
		_evaluar_pose(ap, "idle", 0.4)
		var m_idle := _medir_pie_y_rodilla(inst)
		if m_idle["min_sole_y"] < -0.020 or m_idle["min_sole_y"] > 0.025:
			fallos.append("%s/idle: min_sole_y=%.4f fuera de [-0.020, 0.025]" % [cid, m_idle["min_sole_y"]])
			ok_hero = false
		if m_idle["head_y"] < 0.48 or m_idle["head_y"] > 0.60:
			fallos.append("%s/idle: head_y=%.4f fuera de rango HUD [0.48, 0.60]" % [cid, m_idle["head_y"]])
			ok_hero = false

		var max_knee_walk := 0.0
		for ti in range(9):
			_evaluar_pose(ap, "walk", 0.80 * (float(ti) / 8.0))
			var mw := _medir_pie_y_rodilla(inst)
			max_knee_walk = maxf(max_knee_walk, mw["max_knee_deg"])
			if mw["min_sole_y"] < -0.022 or mw["min_sole_y"] > 0.025:
				fallos.append("%s/walk@%.2f: min_sole_y=%.4f fuera de suelo" % [cid, 0.80 * (float(ti) / 8.0), mw["min_sole_y"]])
				ok_hero = false
		if max_knee_walk < 45.0:
			fallos.append("%s/walk: rodilla máxima %.1f° (< 45°)" % [cid, max_knee_walk])
			ok_hero = false

		var max_knee_run := 0.0
		for ti in range(9):
			_evaluar_pose(ap, "run", 0.62 * (float(ti) / 8.0))
			var mr := _medir_pie_y_rodilla(inst)
			max_knee_run = maxf(max_knee_run, mr["max_knee_deg"])
		if max_knee_run < 70.0:
			fallos.append("%s/run: rodilla máxima %.1f° (< 70°)" % [cid, max_knee_run])
			ok_hero = false

		_evaluar_pose(ap, "crouch", 0.3)
		var mc := _medir_pie_y_rodilla(inst)
		if mc["max_knee_deg"] < 70.0 or absf(mc["min_sole_y"]) > 0.022:
			fallos.append("%s/crouch: rodilla=%.1f°, sole_y=%.4f" % [cid, mc["max_knee_deg"], mc["min_sole_y"]])
			ok_hero = false

		_evaluar_pose(ap, "shoot-bow", 0.24)
		var mb := _medir_pie_y_rodilla(inst)
		if mb["elbow_r_deg"] < 90.0:
			fallos.append("%s/shoot-bow: codo derecho=%.1f° (< 90°)" % [cid, mb["elbow_r_deg"]])
			ok_hero = false

		_evaluar_pose(ap, "die", 0.96)
		var md := _medir_pie_y_rodilla(inst)
		var torso_y: float = md["torso_y"]
		if torso_y > 0.20:
			fallos.append("%s/die@0.96: torso muy alto (%.3fm)" % [cid, torso_y])
			ok_hero = false

		print("AUDIT %s: knee_walk=%.1f° knee_run=%.1f° crouch=%.1f° bow_elbow=%.1f° idle_sole=%.4f idle_head=%.3f die_torso=%.3f min_die=%.4f" % [
			cid, max_knee_walk, max_knee_run, mc["max_knee_deg"], mb["elbow_r_deg"], m_idle["min_sole_y"], m_idle["head_y"], torso_y, md["min_sole_y"]
		])
		if ok_hero:
			aprobados += 1
		inst.queue_free()
		await process_frame

	# 4. Smoke-test de integración en main.tscn (cambios de clase + HUD + física)
	var main_ps := load("res://main.tscn") as PackedScene
	if main_ps != null:
		var m_inst := main_ps.instantiate()
		root.add_child(m_inst)
		await process_frame
		await process_frame
		var pj: Node = m_inst.get_node_or_null("Personaje")
		if pj == null:
			fallos.append("main.tscn: no se encontró nodo Personaje")
		else:
			for info: Dictionary in CLASES:
				var cg: String = info["clase_juego"]
				pj.aplicar_clase(cg)
				await process_frame
				var ac: Variant = pj.get("_anim_ctrl")
				if ac == null or not ac.esta_listo() or not ac.tiene_clip("block-walk"):
					fallos.append("main.tscn/%s: AnimadorEntidad no listo o sin block-walk" % cg)
		m_inst.queue_free()
		await process_frame
	else:
		fallos.append("No se pudo cargar res://main.tscn")

	if fallos.is_empty():
		print("HERO_ANIM_AUDIT_PASS: %d/%d" % [aprobados, CLASES.size()])
		quit(0)
	else:
		for f: String in fallos:
			printerr("FAIL: ", f)
		quit(1)


# ==============================================================================
# RENDERIZADO DE HOJAS DE CONTACTO VISUALES (GPU)
# ==============================================================================

func _crear_stage_estudio(size_px: Vector2i, fov_deg: float, cam_pos: Vector3, look_at: Vector3) -> Dictionary:
	var sv := SubViewport.new()
	sv.size = size_px
	sv.own_world_3d = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.transparent_bg = false

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.11, 0.13, 0.17)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.68, 0.72, 0.80)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var we := WorldEnvironment.new()
	we.environment = env
	sv.add_child(we)

	var key := DirectionalLight3D.new()
	key.light_energy = 1.65
	key.light_color = Color(1.0, 0.96, 0.90)
	key.shadow_enabled = true
	key.rotation_degrees = Vector3(-42.0, 38.0, 0.0)
	sv.add_child(key)

	var rim := DirectionalLight3D.new()
	rim.light_energy = 0.85
	rim.light_color = Color(0.55, 0.78, 1.0)
	rim.rotation_degrees = Vector3(-24.0, -140.0, 0.0)
	sv.add_child(rim)

	# Piso calibrado exactamente en y = 0.000
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2.2, 2.2)
	floor_mi.mesh = pm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.17, 0.19, 0.23)
	fmat.roughness = 0.86
	floor_mi.material_override = fmat
	sv.add_child(floor_mi)

	# Líneas de referencia en y = 0.001 para verificar contacto exacto de suelas
	var ref_line := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(1.1, 0.002, 0.012)
	ref_line.mesh = rm
	ref_line.position = Vector3(0.0, 0.001, 0.0)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.28, 0.72, 0.88)
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ref_line.material_override = rmat
	sv.add_child(ref_line)

	var cam := Camera3D.new()
	cam.fov = fov_deg
	sv.add_child(cam)
	cam.look_at_from_position(cam_pos, look_at, Vector3.UP)

	var lbl := Label.new()
	lbl.position = Vector2(10, 6)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	lbl.add_theme_constant_override("outline_size", 4)
	sv.add_child(lbl)

	root.add_child(sv)
	return {"sv": sv, "cam": cam, "lbl": lbl}


func _renderizar_hoja(
	ruta_png: String,
	cell_size: Vector2i,
	cols_specs_por_fila: Array,
	es_retrato: bool = false
) -> void:
	var n_filas: int = CLASES.size()
	var n_cols: int = (cols_specs_por_fila[0] as Array).size() if not es_retrato else 1
	var total_w: int = cell_size.x * (CLASES.size() if es_retrato else n_cols)
	var total_h: int = cell_size.y * (1 if es_retrato else n_filas)
	var sheet := Image.create(total_w, total_h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.09, 0.11, 0.14))

	var stage := _crear_stage_estudio(
		cell_size,
		26.0 if es_retrato else 24.0,
		Vector3(0.050, 0.595, 0.560) if es_retrato else Vector3(0.68, 0.42, 0.76),
		Vector3(0.0, 0.575, 0.005) if es_retrato else Vector3(0.0, 0.30, 0.02)
	)
	var sv: SubViewport = stage["sv"]
	var cam: Camera3D = stage["cam"]
	var lbl: Label = stage["lbl"]

	for r in range(CLASES.size()):
		var info: Dictionary = CLASES[r]
		var ps := load(info["glb"]) as PackedScene
		var modelo := ps.instantiate() as Node3D
		modelo.rotation_degrees.y = 20.0 if es_retrato else 0.0
		sv.add_child(modelo)
		var ap := _buscar_ap(modelo)
		await process_frame

		var row_specs: Array = cols_specs_por_fila[r]
		for c in range(row_specs.size()):
			var sp: Dictionary = row_specs[c]
			var clip: String = sp["clip"]
			var t_pose: float = sp["t"]
			var title: String = sp["title"]
			var cpos: Vector3 = sp.get("cam_pos", Vector3(0.050, 0.595, 0.560) if es_retrato else Vector3(0.68, 0.42, 0.76))
			var ctgt: Vector3 = sp.get("look_at", Vector3(0.0, 0.575, 0.005) if es_retrato else Vector3(0.0, 0.30, 0.02))
			cam.look_at_from_position(cpos, ctgt, Vector3.UP)
			lbl.text = "%s — %s" % [info["label"], title]
			_evaluar_pose(ap, clip, t_pose)
			await process_frame
			await process_frame

			var cell_img := sv.get_texture().get_image()
			var dst_x: int = r * cell_size.x if es_retrato else c * cell_size.x
			var dst_y: int = 0 if es_retrato else r * cell_size.y
			sheet.blit_rect(cell_img, Rect2i(Vector2i.ZERO, cell_size), Vector2i(dst_x, dst_y))

		modelo.queue_free()
		await process_frame

	sv.queue_free()
	var err := sheet.save_png(ruta_png)
	if err == OK:
		print("RENDER_OK -> %s (%dx%d)" % [ruta_png, total_w, total_h])
	else:
		printerr("ERROR guardando PNG %s: %d" % [ruta_png, err])


func _ejecutar_render() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var cam_side := Vector3(1.28, 0.56, 0.92)
	var tgt_body := Vector3(0.0, 0.34, 0.02)
	var cam_front := Vector3(0.66, 0.56, 1.42)
	var cam_die := Vector3(0.95, 0.62, 0.90)
	var tgt_die := Vector3(0.0, 0.14, -0.05)

	# 1. Locomoción
	var loco_rows: Array = []
	for r in range(CLASES.size()):
		var is_war: bool = String(CLASES[r]["id"]) == "warrior"
		loco_rows.append([
			{"clip": "idle", "t": 0.55, "title": "IDLE", "cam_pos": cam_front, "look_at": tgt_body},
			{"clip": "walk", "t": 0.00, "title": "WALK (Contacto)", "cam_pos": cam_side, "look_at": tgt_body},
			{"clip": "walk", "t": 0.20, "title": "WALK (Paso/Rodilla)", "cam_pos": cam_side, "look_at": tgt_body},
			{"clip": "run", "t": 0.18, "title": "RUN", "cam_pos": cam_side, "look_at": tgt_body},
			{"clip": "sprint", "t": 0.16, "title": "SPRINT", "cam_pos": cam_side, "look_at": tgt_body},
			{"clip": "block-walk" if is_war else "crouch", "t": 0.20 if is_war else 0.30, "title": "BLOCK-WALK" if is_war else "CROUCH", "cam_pos": cam_side, "look_at": tgt_body},
		])
	await _renderizar_hoja(OUT_DIR + "/anim_locomocion_4heroes.png", Vector2i(350, 340), loco_rows, false)

	# 2. Combate
	var combat_rows: Array = []
	for r in range(CLASES.size()):
		var cid: String = CLASES[r]["id"]
		var col4_clip := "holding-both"
		var col4_t := 0.35
		var col4_tit := "GUARDIA"
		if cid == "archer":
			col4_clip = "shoot-bow"
			col4_t = 0.24
			col4_tit = "SHOOT-BOW (Draw)"
		elif cid == "mage":
			col4_clip = "cast-magic"
			col4_t = 0.30
			col4_tit = "CAST-MAGIC"
		elif cid == "warrior":
			col4_clip = "holding-both"
			col4_t = 0.35
			col4_tit = "BLOQUEO ESCUDO"

		var col5_clip := "whirlwind" if cid == "warrior" else "dash"
		var col5_t := 0.24 if cid == "warrior" else 0.14
		var col5_tit := "WHIRLWIND" if cid == "warrior" else "DASH"

		combat_rows.append([
			{"clip": "attack-melee-right", "t": 0.13, "title": "MELEE CARGA", "cam_pos": cam_front, "look_at": tgt_body},
			{"clip": "attack-melee-right", "t": 0.24, "title": "MELEE IMPACTO", "cam_pos": cam_front, "look_at": tgt_body},
			{"clip": "attack-melee-left", "t": 0.23, "title": "ESCUDAZO/REVES" if cid == "warrior" else "MELEE IZQ", "cam_pos": cam_front, "look_at": tgt_body},
			{"clip": col4_clip, "t": col4_t, "title": col4_tit, "cam_pos": cam_front, "look_at": tgt_body},
			{"clip": col5_clip, "t": col5_t, "title": col5_tit, "cam_pos": cam_side, "look_at": tgt_body},
			{"clip": "die", "t": 0.96, "title": "DIE (Suelo)", "cam_pos": cam_die, "look_at": tgt_die},
		])
	await _renderizar_hoja(OUT_DIR + "/anim_combate_4heroes.png", Vector2i(350, 340), combat_rows, false)

	# 3. Retratos HUD
	var port_rows: Array = [
		[{"clip": "idle", "t": 0.0, "title": "HUD RETRATO"}],
		[{"clip": "idle", "t": 0.0, "title": "HUD RETRATO"}],
		[{"clip": "idle", "t": 0.0, "title": "HUD RETRATO"}],
		[{"clip": "idle", "t": 0.0, "title": "HUD RETRATO"}],
	]
	await _renderizar_hoja(OUT_DIR + "/anim_retratos_4heroes.png", Vector2i(300, 320), port_rows, true)

	quit(0)
