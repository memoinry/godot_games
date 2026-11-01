extends Node2D
## Code-drawn hangar illustration. No external artwork is required.
var clock: float = 0.0

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	var center := Vector2(948, 402)
	var cyan := Color("6ee7f2")
	var lime := Color("ccff70")
	draw_circle(center, 238, Color("0b1728"))
	for radius in [104, 176, 232, 252]:
		draw_arc(center, radius, 0, TAU, 120, Color(cyan, 0.12), 1.0, true)
	draw_arc(center, 232, clock * 0.09, clock * 0.09 + 1.2, 40, cyan, 2.0, true)
	draw_arc(center, 176, -clock * 0.12 + 2, -clock * 0.12 + 3.5, 40, Color(lime, 0.6), 2.0, true)
	for i in range(60):
		var angle := TAU * i / 60.0
		var direction := Vector2.from_angle(angle)
		draw_line(center + direction * 245, center + direction * (252 if i % 5 == 0 else 248), Color(cyan, 0.35), 1.0, true)
	draw_line(center - Vector2(272, 0), center + Vector2(272, 0), Color(cyan, 0.12), 1.0)
	draw_line(center - Vector2(0, 272), center + Vector2(0, 272), Color(cyan, 0.12), 1.0)
	var ship := PackedVector2Array([Vector2(0, -113), Vector2(74, 75), Vector2(21, 54), Vector2(0, 76), Vector2(-21, 54), Vector2(-74, 75)])
	var shadow := PackedVector2Array()
	for p in ship:
		shadow.append(center + p + Vector2(8, 15))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.25))
	for i in range(ship.size()):
		ship[i] += center
	draw_colored_polygon(ship, Color("182b36"))
	ship.append(ship[0])
	draw_polyline(ship, lime, 2.5, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -93), center + Vector2(22, 39), center + Vector2(0, 20), center + Vector2(-22, 39)]), lime)
	draw_line(center + Vector2(0, -43), center + Vector2(0, 15), Color("f2ffe0"), 2.0, true)
	for x in [-27, 27]:
		var engine := center + Vector2(x, 63)
		draw_line(engine, engine + Vector2(0, 25 + sin(clock * 18 + x) * 8), Color(cyan, 0.15), 14.0, true)
		draw_line(engine, engine + Vector2(0, 22 + sin(clock * 18 + x) * 6), cyan, 4.0, true)
	for i in range(3):
		var at := center + Vector2.from_angle(i * TAU / 3 + clock * 0.045) * 206
		draw_circle(at, 6.0, Color("ff6b8e"))
		draw_arc(at, 12, 0, TAU, 24, Color(1, 0.42, 0.56, 0.3), 1.0, true)
