@tool
extends Control

var punto_origen1: Vector2 = Vector2.ZERO
var punto_origen2: Vector2 = Vector2.ZERO
var punto_destino: Vector2 = Vector2.ZERO
var color_fondo: Color = Color(0.06, 0.08, 0.14, 0.96)
var color_borde: Color = Color(0.92, 0.76, 0.36, 1.0)
var activo: bool = false

func actualizar_cola(p1: Vector2, p2: Vector2, dest: Vector2, visible_cola: bool, nuevo_borde: Color = Color(0.92, 0.76, 0.36, 1.0)):
	punto_origen1 = p1
	punto_origen2 = p2
	punto_destino = dest
	activo = visible_cola
	color_borde = nuevo_borde
	queue_redraw()

func ocultar():
	activo = false
	queue_redraw()

func _draw():
	if not activo:
		return
	var triangulo = PackedVector2Array([punto_origen1, punto_origen2, punto_destino])
	draw_polygon(triangulo, PackedColorArray([color_fondo]))
	draw_line(punto_origen1, punto_destino, color_borde, 2.5, true)
	draw_line(punto_origen2, punto_destino, color_borde, 2.5, true)
