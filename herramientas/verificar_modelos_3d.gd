extends SceneTree

func _init():
	print("--- RENDERIZANDO SHOWCASE FINAL 3D DE LOS 4 PERSONAJES ---")

	var vp = SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.09, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.38, 0.42)
	env.ambient_light_energy = 1.0
	env_node.environment = env
	vp.add_child(env_node)

	var cam = Camera3D.new()
	cam.position = Vector3(0.0, 1.35, 3.4)
	cam.look_at_from_position(cam.position, Vector3(0.0, 0.55, 0.0), Vector3.UP)
	vp.add_child(cam)

	var dir_light = DirectionalLight3D.new()
	dir_light.transform = Transform3D(Basis.looking_at(Vector3(-0.4, -0.7, -0.6).normalized()))
	dir_light.light_energy = 1.3
	dir_light.shadow_enabled = true
	vp.add_child(dir_light)

	# Suelo
	var floor_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(20, 20)
	floor_mesh.mesh = plane
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.14, 0.16, 0.20)
	floor_mat.roughness = 0.6
	floor_mesh.material_override = floor_mat
	vp.add_child(floor_mesh)

	var clases = [
		{"nombre": "Novato", "path": "res://personaje/player_rookie.glb", "x": -1.95, "rot": 25.0},
		{"nombre": "Guerrero", "path": "res://personaje/player_warrior.glb", "x": -0.65, "rot": 20.0},
		{"nombre": "Arquero", "path": "res://personaje/player_archer.glb", "x": 0.65, "rot": 25.0},
		{"nombre": "Mago", "path": "res://personaje/player_mage.glb", "x": 1.95, "rot": 20.0}
	]

	for c in clases:
		var scene = load(c["path"]) as PackedScene
		if scene == null:
			printerr("ERROR: No se pudo cargar %s" % c["path"])
			continue
		var pj = scene.instantiate() as Node3D
		pj.position = Vector3(c["x"], 0.0, 0.0)
		pj.rotation_degrees.y = c["rot"]
		# Escala estándar de juego
		pj.scale = Vector3(2.5, 2.5, 2.5)
		vp.add_child(pj)

	await process_frame
	await process_frame
	await process_frame
	await process_frame

	var tex = vp.get_texture()
	if tex:
		var img = tex.get_image()
		if img:
			var save_path = "C:/Users/Everett/.gemini/antigravity/brain/04807b17-144b-4559-9883-33f2c3128899/showcase_4_personajes_3d_final.png"
			img.save_png(save_path)
			print("✓ Showcase final guardado en: ", save_path)
	quit(0)
