extends Node3D

@onready var label: Label3D = $Label3D

var _datos_pendientes: bool = false
var _cant_p: float = 0.0
var _crit_p: bool = false
var _jug_p: bool = false
var _texto_p: String = ""

func _ready() -> void:
	if label == null:
		label = get_node_or_null("Label3D") as Label3D
	if _datos_pendientes:
		_aplicar_datos(_cant_p, _crit_p, _jug_p, _texto_p)

func iniciar(cantidad: float, es_critico: bool = false, es_jugador: bool = false, texto_custom: String = "") -> void:
	if label == null:
		label = get_node_or_null("Label3D") as Label3D
	
	if label == null:
		_datos_pendientes = true
		_cant_p = cantidad
		_crit_p = es_critico
		_jug_p = es_jugador
		_texto_p = texto_custom
		return
	
	_aplicar_datos(cantidad, es_critico, es_jugador, texto_custom)

func _aplicar_datos(cantidad: float, es_critico: bool = false, es_jugador: bool = false, texto_custom: String = "") -> void:
	if label == null:
		return
	
	if texto_custom != "":
		label.text = texto_custom
	elif es_critico:
		label.text = "CRIT! " + str(int(cantidad))
	else:
		label.text = str(int(cantidad))
		
	if es_jugador:
		label.modulate = Color(1.0, 0.22, 0.22, 1.0) # Rojo daño recibido
		label.font_size = 48
	elif es_critico:
		label.modulate = Color(1.0, 0.92, 0.15, 1.0) # Amarillo oro crítico / click
		label.font_size = 56
	else:
		label.modulate = Color(1.0, 0.82, 0.45, 1.0) # Naranja dorado daño normal
		label.font_size = 42
		
	# Pop de escala y elevación suave
	scale = Vector3(0.5, 0.5, 0.5)
	var tw = create_tween().set_parallel(true)
	var final_y = position.y + 1.6
	var offset_x = randf_range(-0.4, 0.4)
	var offset_z = randf_range(-0.4, 0.4)
	
	tw.tween_property(self, "position:y", final_y, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:x", position.x + offset_x, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:z", position.z + offset_z, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector3(1.15, 1.15, 1.15), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Desvanecimiento al final
	var tw_fade = create_tween()
	tw_fade.tween_interval(0.35)
	tw_fade.tween_property(label, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_LINEAR)
	tw_fade.finished.connect(queue_free)
