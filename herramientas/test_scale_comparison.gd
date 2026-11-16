extends SceneTree

func _init():
	print("--- TEST DE ESCALA DEL PERSONAJE DESDE LA CÁMARA DE JUEGO ---")

	var main_scene = load("res://main.tscn").instantiate()
	root.add_child(main_scene)

	var pj = main_scene.get_node_or_null("Personaje")
	if pj == null:
		printerr("No se encontró Personaje")
		quit(1)
		return

	var modelo = pj.get_node_or_null("Modelo")
	if modelo == null:
		printerr("No se encontró Modelo")
		quit(1)
		return

	# Probar con escala incrementada para que sea claramente visible y heroico
	# Actualmente tiene (-2.6, 2.6, -2.6). Vamos a probar con (-5.5, 5.5, -5.5)
	modelo.scale = Vector3(-5.5, 5.5, -5.5)

	# Ajustar CollisionShape para que coincida con el tamaño heroico
	var col = pj.get_node_or_null("CollisionShape3D")
	if col and col.shape is CapsuleShape3D:
		col.shape.height = 2.4
		col.shape.radius = 0.55
		col.position.y = 1.2

	for i in range(10):
		await process_frame

	var vp = root.get_viewport()
	if vp:
		var img = vp.get_texture().get_image()
		if img:
			var path = "C:/Users/Everett/.gemini/antigravity/brain/04807b17-144b-4559-9883-33f2c3128899/test_escala_5_5.png"
			img.save_png(path)
			print("✓ Test escala 5.5 guardado en: ", path)

	quit(0)
