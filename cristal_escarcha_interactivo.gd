extends Area3D

var _manager: Node = null
var vida: float = 35.0
var _destruido: bool = false

func configurar_cristal(mgr: Node, vida_inicial: float = 35.0) -> void:
	_manager = mgr
	vida = vida_inicial

func _ready() -> void:
	add_to_group("rompibles")

func recibir_dano(cantidad: float, _fuente = "normal", _es_critico: bool = false) -> void:
	if _destruido:
		return
	vida -= cantidad
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 1.16, 0.05)
	tw.tween_property(self, "scale", Vector3.ONE, 0.08)
	if vida <= 0.0:
		_destruido = true
		if _manager != null and is_instance_valid(_manager) and _manager.has_method("_detonar_cristal_escarcha"):
			_manager._detonar_cristal_escarcha(global_position)
		queue_free()
