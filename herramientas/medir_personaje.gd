extends SceneTree

func _init():
	var escena = load("res://personaje/player_rookie.glb").instantiate()
	var aabb = AABB()
	var primer := true
	for child in escena.find_children("*", "MeshInstance3D"):
		var mi = child as MeshInstance3D
		if mi.mesh:
			var mi_aabb = mi.global_transform * mi.mesh.get_aabb()
			if primer:
				aabb = mi_aabb
				primer = false
			else:
				aabb = aabb.merge(mi_aabb)
	print("Bounding Box de player_rookie.glb (sin escala):")
	print("  Posición min: ", aabb.position)
	print("  Tamaño (size): ", aabb.size)
	print("  Altura Y: ", aabb.size.y)
	print("Con escala 2.6x: Altura = ", aabb.size.y * 2.6)
	print("Con escala 5.2x: Altura = ", aabb.size.y * 5.2)
	print("Con escala 6.0x: Altura = ", aabb.size.y * 6.0)
	quit(0)
