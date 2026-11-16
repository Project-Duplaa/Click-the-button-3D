extends SceneTree

func _init():
	print("--- RENDERIZANDO PREVIEW DE JEFES CON CORAZA / ESCUDO REDISEÑADO ---")

	var vp = SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.07, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.38, 0.42)
	env.ambient_light_energy = 1.0
	env_node.environment = env
	vp.add_child(env_node)

	var cam = Camera3D.new()
	cam.position = Vector3(0.0, 3.8, 9.5)
	cam.look_at_from_position(cam.position, Vector3(0.0, 1.8, 0.0), Vector3.UP)
	vp.add_child(cam)

	var dir_light = DirectionalLight3D.new()
	dir_light.transform = Transform3D(Basis.looking_at(Vector3(-0.4, -0.7, -0.6).normalized()))
	dir_light.light_energy = 1.2
	dir_light.shadow_enabled = true
	vp.add_child(dir_light)

	# Suelo
	var floor_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(30, 30)
	floor_mesh.mesh = plane
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.12, 0.14, 0.18)
	floor_mat.roughness = 0.7
	floor_mesh.material_override = floor_mat
	vp.add_child(floor_mesh)

	# 1. Coloso de Bronce (a la izquierda)
	var coloso_scn = load("res://coloso_bronce.tscn")
	if coloso_scn:
		var coloso = coloso_scn.instantiate()
		coloso.position = Vector3(-3.8, 0.0, 0.0)
		vp.add_child(coloso)
		await process_frame
		if coloso.has_method("_activar_coraza"):
			coloso._activar_coraza(3, "BRONCE")

	# 2. Parca Roja (a la derecha)
	var parca_scn = load("res://parca_roja.tscn")
	if parca_scn:
		var parca = parca_scn.instantiate()
		parca.position = Vector3(3.8, 0.0, 0.0)
		vp.add_child(parca)

	for i in range(15):
		await process_frame

	var tex = vp.get_texture()
	if tex:
		var img = tex.get_image()
		if img:
			var save_path = "C:/Users/Everett/.gemini/antigravity/brain/04807b17-144b-4559-9883-33f2c3128899/preview_escudos_redisenados.png"
			img.save_png(save_path)
			print("✓ Preview guardado en: ", save_path)

	quit(0)
