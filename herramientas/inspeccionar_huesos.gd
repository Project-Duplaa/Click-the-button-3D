extends SceneTree

func _init():
	var escena = load("res://personaje/character-male-a.glb").instantiate()
	var skel: Skeleton3D = escena.find_child("Skeleton3D", true, false)
	if skel:
		print("Número de huesos: ", skel.get_bone_count())
		for i in range(skel.get_bone_count()):
			var bname = skel.get_bone_name(i)
			var bpose = skel.get_bone_global_pose(i)
			print("  Hueso [", i, "] ", bname, " pos: ", bpose.origin)
	quit(0)
