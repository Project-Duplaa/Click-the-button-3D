class_name DamageNumbersPool
extends Node3D

## DamageNumbersPool — Pool de Alto Rendimiento para Números Flotantes 3D
## Gestiona un pool pre-asignado de 45 Label3D con Billboard activado, sin profundidad oclusiva,
## código cromático por fuente de daño y animaciones de resorte fluidas.

const TAMANO_POOL: int = 45

const COLORES_FUENTE: Dictionary = {
	"clic": Color(0.20, 0.90, 1.0),       # Cian electro-místico
	"hilo": Color(0.85, 0.40, 1.0),       # Violeta arcano de resonancia
	"fuego": Color(1.0, 0.50, 0.10),      # Naranja ígneo
	"normal": Color(0.95, 0.95, 0.95),    # Blanco marfil estándar
	"critico": Color(1.0, 0.88, 0.15),    # Oro radiante
	"curacion": Color(0.25, 0.95, 0.35),  # Esmeralda vital
	"oro": Color(1.0, 0.80, 0.10),        # Moneda dorada
	"jugador_herido": Color(1.0, 0.25, 0.25) # Daño recibido por jugador
}

var _pool: Array[Label3D] = []
var _disponibles: Array[Label3D] = []
var _activos: Array[Label3D] = []

func _ready():
	add_to_group("damage_numbers")
	add_to_group("damage_numbers_pool")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_inicializar_pool()

func _inicializar_pool():
	for i in range(TAMANO_POOL):
		var lbl = Label3D.new()
		lbl.name = "DmgLabel_%d" % i
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		lbl.outline_size = 10
		lbl.outline_modulate = Color(0.02, 0.02, 0.03, 0.95)
		lbl.font_size = 44
		lbl.visible = false
		lbl.pixel_size = 0.0055
		add_child(lbl)
		_pool.append(lbl)
		_disponibles.append(lbl)

func _obtener_instancia() -> Label3D:
	var inst: Label3D = null
	if not _disponibles.is_empty():
		inst = _disponibles.pop_back()
	else:
		inst = _activos.pop_front()
	if is_instance_valid(inst):
		for meta_key in ["_tw_move", "_tw_fade"]:
			if inst.has_meta(meta_key):
				var prev_tw = inst.get_meta(meta_key)
				if prev_tw is Tween and prev_tw.is_valid():
					prev_tw.kill()
				inst.remove_meta(meta_key)
		_activos.append(inst)
	return inst

func _liberar_instancia(lbl: Label3D):
	if is_instance_valid(lbl):
		lbl.visible = false
		_activos.erase(lbl)
		if not _disponibles.has(lbl):
			_disponibles.append(lbl)

func mostrar_dano(pos: Vector3, valor: int, es_critico: bool = false, fuente: String = "normal") -> void:
	var lbl = _obtener_instancia()
	if lbl == null:
		return
		
	var color = COLORES_FUENTE.get(fuente, COLORES_FUENTE["normal"])
	if es_critico:
		color = COLORES_FUENTE["critico"]
		lbl.text = "%d!" % valor
		lbl.font_size = 58
	else:
		lbl.text = str(valor)
		lbl.font_size = 44
		
	lbl.modulate = color
	_ejecutar_animacion_flotante(lbl, pos, es_critico, 1.4 if es_critico else 1.0)

func mostrar_texto(pos: Vector3, texto: String, color: Color = Color.GOLD, escala: float = 1.0) -> void:
	var lbl = _obtener_instancia()
	if lbl == null:
		return
		
	lbl.text = texto
	lbl.modulate = color
	lbl.font_size = int(round(46 * escala))
	_ejecutar_animacion_flotante(lbl, pos, escala > 1.2, escala)

func _ejecutar_animacion_flotante(lbl: Label3D, pos_inicial: Vector3, es_destacado: bool, factor_escala: float):
	lbl.visible = true
	lbl.global_position = pos_inicial + Vector3(randf_range(-0.25, 0.25), 0.2, randf_range(-0.25, 0.25))
	lbl.scale = Vector3(0.3, 0.3, 0.3)
	
	var escala_final = Vector3.ONE * factor_escala
	var altura_salto = 1.85 if es_destacado else 1.45
	var offset_x = randf_range(-0.4, 0.4)
	var offset_z = randf_range(-0.4, 0.4)
	var pos_final = lbl.global_position + Vector3(offset_x, altura_salto, offset_z)
	
	var tw = create_tween().set_parallel(true)
	lbl.set_meta("_tw_move", tw)
	tw.tween_property(lbl, "global_position:y", pos_final.y, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "global_position:x", pos_final.x, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "global_position:z", pos_final.z, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", escala_final, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var tw_fade = create_tween()
	lbl.set_meta("_tw_fade", tw_fade)
	tw_fade.tween_interval(0.38)
	tw_fade.tween_property(lbl, "modulate:a", 0.0, 0.27).set_trans(Tween.TRANS_LINEAR)
	tw_fade.finished.connect(func(): _liberar_instancia(lbl))
