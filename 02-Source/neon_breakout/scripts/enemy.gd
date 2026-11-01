extends Node2D
## Four archetypes plus a three-phase boss. All attacks are simulated in Arena.step.

var arena: Node2D
var kind: int = 0
var hp: float = 34.0
var max_hp: float = 34.0
var radius: float = 16.0
var speed: float = 95.0
var timer: float = 1.0
var age: float = 0.0
var flash: float = 0.0
var dead: bool = false
var charge_warning: float = 0.0
var charging: float = 0.0
var charge_direction := Vector2.ZERO
var color := Color("ff6b8e")
var phase: int = 1
var special_timer: float = 6.0

func configure(host: Node2D, enemy_kind: int, at: Vector2, wave: int) -> void:
	arena = host
	kind = enemy_kind
	position = at
	timer = arena.rng.randf_range(0.8, 2.0)
	match kind:
		0:
			hp = 30.0 + wave * 5.0
			speed = 90.0 + wave * 5.0
			color = Color("ff6b8e")
		1:
			hp = 48.0 + wave * 8.0
			speed = 65.0
			radius = 19.0
			color = Color("6ee7f2")
		2:
			hp = 54.0 + wave * 7.0
			speed = 75.0
			radius = 18.0
			color = Color("ffc477")
		3:
			hp = 75.0 + wave * 10.0
			speed = 57.0
			radius = 23.0
			color = Color("c8a2ff")
		4:
			hp = 4400.0
			speed = 42.0
			radius = 58.0
			color = Color("ffc477")
	max_hp = hp

func step(delta: float) -> void:
	if dead:
		return
	age += delta
	flash = maxf(0.0, flash - delta)
	timer -= delta
	var difference: Vector2 = arena.player.position - position
	var direction := difference.normalized()
	match kind:
		0:
			position += direction.rotated(sin(age * 2.0) * 0.2) * speed * delta
		1:
			var distance := difference.length()
			if distance > 310.0:
				position += direction * speed * delta
			elif distance < 200.0:
				position -= direction * speed * delta
			position += direction.orthogonal() * sin(age * 0.8) * 38.0 * delta
			if timer <= 0.0:
				timer = maxf(1.2, 2.7 - arena.wave * 0.12)
				arena.add_bullet(position + direction * 24, direction * 225.0, 12, true, 0, color, 5.5)
		2:
			if charging > 0.0:
				charging -= delta
				position += charge_direction * 510.0 * delta
			elif charge_warning > 0.0:
				charge_warning -= delta
				if charge_warning <= 0.0:
					charging = 0.5
					arena.burst(position, color, 8, 90.0)
			elif timer <= 0.0:
				timer = 3.8
				charge_warning = 0.85
				charge_direction = direction
			else:
				position += direction * speed * delta
		3:
			position += direction * speed * delta
			if timer <= 0.0:
				timer = 3.2
				for i in range(8):
					var angle := TAU * i / 8.0 + age * 0.2
					arena.add_bullet(position, Vector2.from_angle(angle) * 165, 10, true, 0, color, 4.0)
		4:
			step_boss(delta, direction)
	position.x = clampf(position.x, 32.0, 1248.0)
	position.y = clampf(position.y, 102.0, 724.0)
	if difference.length() < radius + 12.0:
		arena.player.hurt(25.0 if kind == 4 else 18.0)
		if kind != 4:
			position -= direction * 25.0
	queue_redraw()

func step_boss(delta: float, direction: Vector2) -> void:
	var new_phase := 1 if hp > max_hp * 0.66 else (2 if hp > max_hp * 0.33 else 3)
	if new_phase != phase:
		phase = new_phase
		arena.announce("核心过载 / PHASE %02d" % phase, "警惕环形弹幕 · 冲刺可穿越弹幕", 2.8)
		arena.sfx.play("warning")
		arena.burst(position, color, 45, 230)
	position += direction * speed * delta
	if timer <= 0.0:
		timer = 1.8 - phase * 0.3
		var count := 10 + phase * 3
		for i in range(count):
			var angle := TAU * i / count + age * 0.26
			arena.add_bullet(position + Vector2.from_angle(angle) * 58.0, Vector2.from_angle(angle) * (120.0 + phase * 24.0), 14, true, 0, color, 7.0)
		if phase >= 2:
			for offset in [-0.18, 0.0, 0.18]:
				arena.add_bullet(position, direction.rotated(offset) * 255.0, 16, true, 0, Color("ff6b8e"), 5)
	special_timer -= delta
	if special_timer <= 0.0:
		special_timer = 8.5
		for i in range(phase + 1):
			arena.spawn_enemy(0, arena.edge_spawn())
		arena.drop_pickup(position + Vector2(0, 85), 0)

func hurt(damage: float) -> void:
	if dead:
		return
	hp -= damage
	flash = 0.07
	if hp <= 0.0:
		dead = true
		arena.enemy_killed(self)
		queue_free()

func _draw() -> void:
	var ink := Color.WHITE if flash > 0.0 else color
	draw_circle(Vector2.ZERO, radius * 1.75, Color(color, 0.045))
	if kind == 4:
		draw_arc(Vector2.ZERO, radius + 12, age * 0.5, age * 0.5 + PI * 1.6, 50, ink, 2.5, true)
		draw_arc(Vector2.ZERO, radius + 20, -age * 0.4, -age * 0.4 + PI * 1.4, 50, Color(color, 0.4), 1.0, true)
		var vertices := polygon(6, radius, age * 0.15)
		draw_colored_polygon(vertices, Color("251e25"))
		vertices.append(vertices[0])
		draw_polyline(vertices, ink, 3.0, true)
		for i in range(phase + 2):
			var angle := TAU * i / (phase + 2.0) - age
			draw_circle(Vector2.from_angle(angle) * 36.0, 5, ink)
		draw_circle(Vector2.ZERO, 15.0 + sin(age * 5) * 3.0, ink)
		draw_circle(Vector2.ZERO, 7, Color("11192b"))
	else:
		var sides: int = [4, 4, 3, 6][kind]
		var angle: float = (arena.player.position - position).angle()
		if kind == 1 or kind == 3:
			angle = age * 0.45
		var vertices := polygon(sides, radius, angle)
		draw_colored_polygon(vertices, Color(color, 0.13))
		vertices.append(vertices[0])
		draw_polyline(vertices, ink, 2.0, true)
		draw_circle(Vector2.ZERO, 3.0, ink)
		if hp < max_hp:
			draw_line(Vector2(-radius, -radius - 8), Vector2(radius, -radius - 8), Color("283449"), 3.0)
			draw_line(Vector2(-radius, -radius - 8), Vector2(-radius + 2 * radius * maxf(0, hp / max_hp), -radius - 8), ink, 3.0)
	if charge_warning > 0.0:
		draw_line(Vector2.ZERO, charge_direction * 350.0, Color(color, 0.28 + sin(age * 28) * 0.15), 2.0, true)
		draw_arc(Vector2.ZERO, radius + 7, 0, TAU * (1.0 - charge_warning / 0.85), 32, ink, 2.0, true)

func polygon(sides: int, size_value: float, angle: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(sides):
		points.append(Vector2.from_angle(TAU * i / sides + angle) * size_value)
	return points
