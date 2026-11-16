extends SceneTree

func _init():
	var paths = [
		"res://assets/modelos/amalgama_radiactiva.glb",
		"res://assets/modelos/mecha_infectado.glb",
		"res://assets/modelos/plasma_abominacion.glb",
		"res://assets/modelos/simbionte_espinoso.glb"
	]
	for p in paths:
		print("\n=== RECURSO: ", p, " ===")
		var scn = load(p)
		if scn:
			var inst = scn.instantiate()
			_print_tree(inst, "")
	quit(0)

func _print_tree(n: Node, indent: String):
	var info = n.name + " (" + n.get_class() + ")"
	if n is MeshInstance3D and n.mesh:
		info += " mesh=" + n.mesh.get_class()
		if n.material_override:
			info += " mat=" + str(n.material_override)
	print(indent, info)
	for c in n.get_children():
		_print_tree(c, indent + "  ")
