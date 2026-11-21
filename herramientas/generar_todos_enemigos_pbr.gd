@tool
extends SceneTree

## ==============================================================================
## EJECUTOR MAESTRO: GENERACIÓN DE LOS 16 ENEMIGOS PBR EN .GLB
## Uso:
##   godot --headless --path . --script res://herramientas/generar_todos_enemigos_pbr.gd
##   godot --headless --path . --script res://herramientas/generar_todos_enemigos_pbr.gd -- --only=guardia
## ==============================================================================

const Kit = preload("res://herramientas/enemigos_pbr_kit.gd")
const FaccionGuarnicion = preload("res://herramientas/enemigos_faccion_guarnicion.gd")
const FaccionFoso = preload("res://herramientas/enemigos_faccion_foso.gd")
const FaccionCorteYVacio = preload("res://herramientas/enemigos_faccion_corte_y_vacio.gd")


func _init() -> void:
	var only_id: String = ""
	for arg in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg.begins_with("--only="):
			only_id = arg.substr(7).strip_edges().to_lower()

	print("==================================================================")
	print("GENERANDO MODELOS 3D PBR DE ENEMIGOS (filtro: %s)" % ("TODOS" if only_id == "" else only_id))
	print("==================================================================")

	var catalogo: Dictionary = {}
	var bloques: Array = [
		FaccionGuarnicion.construir_todos(),
		FaccionFoso.construir_todos(),
		FaccionCorteYVacio.construir_todos(),
	]
	for b in bloques:
		for k in b.keys():
			catalogo[k] = b[k]

	var generados := 0
	var errores := 0

	for id_enemigo: String in catalogo.keys():
		var entry: Dictionary = catalogo[id_enemigo]
		var nodo := entry.get("nodo", null) as Node3D
		var ruta := String(entry.get("ruta", ""))
		if only_id != "" and id_enemigo.to_lower() != only_id:
			if nodo != null:
				nodo.free()
			continue
		if nodo == null or ruta == "":
			printerr("ERROR: Entrada inválida para '%s'" % id_enemigo)
			errores += 1
			continue

		var altura := Kit.exportar_glb(nodo, ruta)
		if altura <= 0.05:
			printerr("ERROR: Altura sospechosa (%.3f) para '%s'" % [altura, id_enemigo])
			errores += 1
		else:
			generados += 1
		nodo.free()

	print("==================================================================")
	print("RESUMEN: %d generados, %d errores." % [generados, errores])
	print("==================================================================")
	quit(1 if errores > 0 else 0)
