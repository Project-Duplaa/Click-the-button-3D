extends SceneTree

const ArbolInterconectadoDatos = preload("res://arbol_interconectado_datos.gd")
const MetaprogresoManager = preload("res://metaprogreso_manager.gd")

const OUT_PNG := "C:/Users/USER/.gemini/antigravity/brain/c999e97c-985b-4dc3-aa3b-ad816d088d31/scratch/arbol_habilidades_boton.png"

const BTN_IDS: Array[String] = [
	"btn_disipador_1",
	"btn_tamano_1",
	"btn_enfriamiento_1",
	"btn_ritmo_1",
	"btn_ancla_orbita_1",
	"btn_cadenas_1",
	"btn_sobrecarga_termica_1",
	"btn_fiebre_sostenida_1",
	"btn_palancas_1",
	"btn_frenesi_duracion_1",
	"btn_keystone_criogenico",
	"btn_keystone_rompecadenas",
]


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if "--render" in args:
		await _ejecutar_render()
	else:
		await _ejecutar_auditoria()


func _verificar_grafo(fallos: Array[String]) -> void:
	var nodos: Dictionary = ArbolInterconectadoDatos.generar_arbol()
	if nodos.size() != 80:
		fallos.append("Cantidad esperada 80 nodos, obtenido: %d" % nodos.size())

	for bid: String in BTN_IDS:
		if not nodos.has(bid):
			fallos.append("Falta nodo de botón: %s" % bid)
		else:
			var nb: SkillNodeData = nodos[bid]
			if nb.rama != "boton":
				fallos.append("Nodo %s tiene rama '%s' (esperada 'boton')" % [bid, nb.rama])

	# Bidireccionalidad estricta
	for id_a in nodos.keys():
		var na: SkillNodeData = nodos[id_a]
		for id_b: String in na.nodos_conectados:
			if not nodos.has(id_b):
				fallos.append("Conexión rota %s -> %s" % [id_a, id_b])
			else:
				var nb: SkillNodeData = nodos[id_b]
				if not nb.nodos_conectados.has(str(id_a)):
					fallos.append("Falta arista inversa %s -> %s" % [id_b, str(id_a)])

	# Alcanzabilidad BFS desde nodo_origen
	var visitados: Dictionary = {}
	var cola: Array[String] = ["nodo_origen"]
	visitados["nodo_origen"] = true
	while cola.size() > 0:
		var act: String = cola.pop_front()
		var n_act: SkillNodeData = nodos[act]
		for vec: String in n_act.nodos_conectados:
			if nodos.has(vec) and not visitados.has(vec):
				visitados[vec] = true
				cola.append(vec)
	if visitados.size() != nodos.size():
		fallos.append("BFS alcanzó %d/%d nodos desde nodo_origen" % [visitados.size(), nodos.size()])

	# Espaciado mínimo entre cualquier par de nodos
	var keys: Array = nodos.keys()
	var min_dist: float = 99999.0
	var par_min: String = ""
	for i in range(keys.size()):
		for j in range(i + 1, keys.size()):
			var ka: String = str(keys[i])
			var kb: String = str(keys[j])
			var na: SkillNodeData = nodos[ka]
			var nb: SkillNodeData = nodos[kb]
			var d: float = na.posicion.distance_to(nb.posicion)
			if d < min_dist:
				min_dist = d
				par_min = "%s <-> %s" % [ka, kb]
	if min_dist < 90.0:
		fallos.append("Espaciado mínimo demasiado pequeño (%.1f px en %s < 90)" % [min_dist, par_min])
	print("GRAFO OK: nodos=%d alcanzables=%d min_dist=%.1f (%s)" % [nodos.size(), visitados.size(), min_dist, par_min])


func _ejecutar_auditoria() -> void:
	var fallos: Array[String] = []
	_verificar_grafo(fallos)

	MetaprogresoManager.asegurar_inicializado()
	var backup_mejoras: Dictionary = MetaprogresoManager.mejoras_arbol.duplicate(true)
	var backup_pura: bool = MetaprogresoManager.modo_run_pura
	var backup_chasis: String = MetaprogresoManager.chasis_equipado

	MetaprogresoManager.modo_run_pura = false
	MetaprogresoManager.mejoras_arbol = {}
	MetaprogresoManager.chasis_equipado = "estandar"

	var main_ps: PackedScene = load("res://main.tscn") as PackedScene
	if main_ps == null:
		fallos.append("No se pudo cargar res://main.tscn")
	else:
		var m: Node = main_ps.instantiate()
		root.add_child(m)
		await process_frame
		await process_frame

		var pj: Node = m.get_node_or_null("Personaje")
		var boton: Node = get_first_node_in_group("boton_movil")
		var palanca: Node = get_first_node_in_group("palancas_boton")
		if pj == null or boton == null or palanca == null:
			fallos.append("Falta nodo en main.tscn (pj=%s boton=%s palanca=%s)" % [str(pj != null), str(boton != null), str(palanca != null)])
		else:
			boton.aplicar_chasis("estandar")
			pj.mejoras_arbol = {}
			pj.recalcular_stats_incrementales()

			if not is_equal_approx(float(boton.calor_por_clic), 16.0):
				fallos.append("Base calor_por_clic esperado 16.0, obtenido %.3f" % float(boton.calor_por_clic))
			if int(boton.clics_para_bloqueo) != 20:
				fallos.append("Base clics_para_bloqueo esperado 20, obtenido %d" % int(boton.clics_para_bloqueo))
			if not is_equal_approx(float(palanca._obtener_rango_activacion()), 3.5):
				fallos.append("Base rango palanca esperado 3.5, obtenido %.3f" % float(palanca._obtener_rango_activacion()))

			# Activar todos los nodos de la rama "boton" al máximo
			var arbol: Dictionary = ArbolInterconectadoDatos.generar_arbol()
			var max_btn: Dictionary = {}
			for bid: String in BTN_IDS:
				var nb: SkillNodeData = arbol[bid]
				max_btn[bid] = nb.nivel_max
			pj.mejoras_arbol = max_btn.duplicate(true)
			pj.recalcular_stats_incrementales()
			pj.recalcular_stats_incrementales() # Segunda llamada para comprobar idempotencia

			if not is_equal_approx(float(boton.calor_por_clic), 8.0):
				fallos.append("Max calor_por_clic esperado 8.0, obtenido %.3f" % float(boton.calor_por_clic))
			if not is_equal_approx(float(boton.velocidad_enfriamiento), 53.2):
				fallos.append("Max velocidad_enfriamiento esperado 53.2, obtenido %.3f" % float(boton.velocidad_enfriamiento))
			if not is_equal_approx(float(boton.calor_maximo), 160.0):
				fallos.append("Max calor_maximo esperado 160.0, obtenido %.3f" % float(boton.calor_maximo))
			if int(boton.clics_para_bloqueo) != 36:
				fallos.append("Max clics_para_bloqueo esperado 36, obtenido %d" % int(boton.clics_para_bloqueo))
			if not is_equal_approx(float(boton.mult_ventana_ritmo), 1.60):
				fallos.append("Max mult_ventana_ritmo esperado 1.60, obtenido %.3f" % float(boton.mult_ventana_ritmo))
			if not is_equal_approx(float(boton.escala_actual), 1.40):
				fallos.append("Max escala_actual esperado 1.40, obtenido %.3f" % float(boton.escala_actual))
			if not is_equal_approx(float(palanca._obtener_rango_activacion()), 8.0):
				fallos.append("Max rango palanca esperado 8.0, obtenido %.3f" % float(palanca._obtener_rango_activacion()))
			if int(boton.obtener_multiplicador_frenesi()) != 4:
				fallos.append("Max multiplicador_frenesi esperado 4, obtenido %d" % int(boton.obtener_multiplicador_frenesi()))
			if float(boton.obtener_multiplicador_termico()) < 2.479:
				fallos.append("Max multiplicador_termico esperado >= 2.48, obtenido %.3f" % float(boton.obtener_multiplicador_termico()))

			# Probar Nova Criogénica al 100% de calor
			boton.calor_actual = float(boton.calor_maximo) - 1.0
			boton._cooldown_nova_criogenica = 0.0
			boton.pulsar_boton()
			if bool(boton.sobrecalentado):
				fallos.append("Nova Criogénica no evitó el estado sobrecalentado")
			if not is_equal_approx(float(boton.calor_actual), float(boton.calor_maximo) * 0.35):
				fallos.append("Nova Criogénica calor esperado %.2f, obtenido %.2f" % [float(boton.calor_maximo) * 0.35, float(boton.calor_actual)])

			# Probar Keystone Rompecadenas (solo 2 palancas requeridas)
			boton.activar_bloqueo_cadenas()
			if int(boton.cadenas_requeridas) != 2 or int(boton.cadenas_activas) != 2:
				fallos.append("Rompecadenas esperado 2/2 cadenas, obtenido %d/%d" % [int(boton.cadenas_activas), int(boton.cadenas_requeridas)])

			# Probar persistencia tras cambiar de chasis a Cometa
			boton.aplicar_chasis("cometa")
			if int(boton.clics_para_bloqueo) != 36 or not is_equal_approx(float(boton.mult_ventana_ritmo), 1.45 * 1.60) or not is_equal_approx(float(boton.escala_actual), 1.40):
				fallos.append("Fallo persistencia tras aplicar_chasis('cometa')")

			# Probar reversión limpia (modo Run Pura / reset)
			pj.mejoras_arbol = {}
			pj.recalcular_stats_incrementales()
			boton.aplicar_chasis("estandar")
			if not is_equal_approx(float(boton.calor_por_clic), 16.0) or not is_equal_approx(float(boton.calor_maximo), 100.0) or int(boton.clics_para_bloqueo) != 20 or not is_equal_approx(float(boton.escala_actual), 1.0) or not is_equal_approx(float(palanca._obtener_rango_activacion()), 3.5):
				fallos.append("Reversión a valores base incompleta tras limpiar mejoras_arbol")

		m.queue_free()
		await process_frame

	# Verificar panel UI de arbol_mejoras_poe.tscn
	var arb_ps: PackedScene = load("res://arbol_mejoras_poe.tscn") as PackedScene
	if arb_ps == null:
		fallos.append("No se pudo cargar res://arbol_mejoras_poe.tscn")
	else:
		var arb: CanvasLayer = arb_ps.instantiate() as CanvasLayer
		root.add_child(arb)
		await process_frame
		var nd: SkillNodeData = arb.diccionario_nodos.get("btn_disipador_1", null) as SkillNodeData
		if nd == null:
			fallos.append("arb.diccionario_nodos no contiene btn_disipador_1")
		else:
			arb._on_nodo_seleccionado_en_lienzo(nd, "desbloqueable")
			if not String(arb.lbl_nodo_rama.text).contains("INGENIERÍA DEL NÚCLEO MÓVIL"):
				fallos.append("lbl_nodo_rama inesperado: '%s'" % String(arb.lbl_nodo_rama.text))
			if arb.btn_sector_boton == null:
				fallos.append("Falta btn_sector_boton en arbol_mejoras_poe.gd")
		arb.queue_free()
		await process_frame

	MetaprogresoManager.mejoras_arbol = backup_mejoras
	MetaprogresoManager.modo_run_pura = backup_pura
	MetaprogresoManager.chasis_equipado = backup_chasis

	if fallos.is_empty():
		print("BOTON_ARBOL_AUDIT_PASS")
		quit(0)
	else:
		for f: String in fallos:
			printerr("AUDIT_FAIL: ", f)
		quit(1)


func _ejecutar_render() -> void:
	MetaprogresoManager.asegurar_inicializado()
	var backup_mejoras: Dictionary = MetaprogresoManager.mejoras_arbol.duplicate(true)

	# Configurar progreso de muestra para apreciar nodos activos, desbloqueables y bloqueados
	MetaprogresoManager.mejoras_arbol = {
		"nodo_origen": 1,
		"clk_fuerza_1": 2,
		"srv_salud_1": 2,
		"eco_oro_1": 1,
		"btn_disipador_1": 5,
		"btn_tamano_1": 3,
		"btn_enfriamiento_1": 2,
		"btn_ritmo_1": 2,
		"btn_ancla_orbita_1": 1,
		"btn_sobrecarga_termica_1": 4,
	}

	var sv := SubViewport.new()
	sv.size = Vector2i(1280, 720)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.transparent_bg = false
	root.add_child(sv)

	var arb_ps: PackedScene = load("res://arbol_mejoras_poe.tscn") as PackedScene
	var arb: CanvasLayer = arb_ps.instantiate() as CanvasLayer
	sv.add_child(arb)
	await process_frame

	arb._sincronizar_niveles_desde_jugador()
	arb.visible = true
	arb._sincronizar_shaders_paneles()
	arb._actualizar_barra_economia()
	arb.lienzo.zoom = 0.66
	arb.lienzo.pan_offset = Vector2(360.0, 20.0)
	arb.lienzo.queue_redraw()

	var nd: SkillNodeData = arb.diccionario_nodos.get("btn_keystone_criogenico", null) as SkillNodeData
	if nd != null:
		arb.lienzo.nodo_seleccionado_id = nd.id
		arb._on_nodo_seleccionado_en_lienzo(nd, ArbolInterconectadoDatos.obtener_estado_nodo(nd, arb.diccionario_nodos))

	await process_frame
	await process_frame
	await process_frame

	var img: Image = sv.get_texture().get_image()
	var err: int = img.save_png(OUT_PNG)
	if err == OK:
		print("RENDER_BOTON_ARBOL_OK -> %s (%dx%d)" % [OUT_PNG, img.get_width(), img.get_height()])
	else:
		printerr("ERROR guardando render: %d" % err)

	MetaprogresoManager.mejoras_arbol = backup_mejoras
	sv.queue_free()
	quit(0 if err == OK else 1)
