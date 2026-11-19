extends Node3D


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("=================================================================")
	print(">>> CAPTURANDO GALERÍA DEFINITIVA DEL BESTIARIO 3D EN ALTA RESOLUCIÓN <<<")
	print("=================================================================")

	var canvas = CanvasLayer.new()
	add_child(canvas)

	var codice_scr = load("res://codice_gladiador_ui.gd")
	var codice = codice_scr.new()
	codice.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas.add_child(codice)
	codice.abrir(2) # Tab 2: Bestiario 3D
	get_tree().paused = false

	var lista_enemigos = [
		{"id": "golem_tesoro", "nombre": "Gólem de Tesoro"},
		{"id": "canalizador_vacio", "nombre": "Canalizador del Vacío"},
		{"id": "espejo_sombrio", "nombre": "El Espejo Sombrío"},
		{"id": "kamikaze", "nombre": "Minero Inestable (Kamikaze)"},
		{"id": "bruto", "nombre": "Bruto Aplastador"},
		{"id": "centurion", "nombre": "Centurión Corrupto"},
		{"id": "arquero", "nombre": "Arquero Balístico"},
		{"id": "maestra", "nombre": "Maestra Sanguinaria"},
		{"id": "parca", "nombre": "La Parca Roja"},
		{"id": "parasito_cursor", "nombre": "Parásito del Cursor"},
		{"id": "coloso", "nombre": "Coloso de Bronce"},
		{"id": "heraldo_clic", "nombre": "Heraldo del Clic"}
	]

	var brain_dir = "C:/Users/Everett/.gemini/antigravity/brain/04807b17-144b-4559-9883-33f2c3128899/"

	for info in lista_enemigos:
		var id = info["id"]
		codice._seleccionar_enemigo_bestiario(id)

		# 1. Captura en perspectiva heroica 3/4
		for f in range(25):
			await get_tree().process_frame
			if codice.preview_nodo_padre != null:
				codice.preview_nodo_padre.rotation.y = 0.52

		# Capturar 3D aislado
		if codice.subviewport_3d:
			var s_tex = codice.subviewport_3d.get_texture()
			if s_tex:
				var s_img = s_tex.get_image()
				if s_img:
					var p_3d = brain_dir + "galeria_3d_" + id + "_34.png"
					s_img.save_png(p_3d)

		# Capturar UI completa
		var vp = get_viewport()
		if vp:
			var tex = vp.get_texture()
			if tex:
				var img = tex.get_image()
				if img:
					var p_ui = brain_dir + "galeria_ui_" + id + ".png"
					img.save_png(p_ui)
					print("✓ Capturado 3/4: ", info["nombre"], " -> ", p_ui)

		# 2. Captura en perfil lateral 90 grados (Demostrando volumen 3D real 360°)
		for f in range(15):
			await get_tree().process_frame
			if codice.preview_nodo_padre != null:
				codice.preview_nodo_padre.rotation.y = 1.57

		if codice.subviewport_3d:
			var s_tex = codice.subviewport_3d.get_texture()
			if s_tex:
				var s_img = s_tex.get_image()
				if s_img:
					var p_side = brain_dir + "galeria_3d_" + id + "_side.png"
					s_img.save_png(p_side)
					print("✓ Capturado Perfil 90°: ", info["nombre"], " -> ", p_side)

	print("=================================================================")
	print("✓ TODAS LAS CAPTURAS COMPLETADAS EXITOSAMENTE")
	print("=================================================================")
	get_tree().quit(0)
