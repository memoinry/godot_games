extends Node2D
## Player movement and weapon state. Arena owns collisions and run progression.

const CYAN := Color("6ee7f2")
const LIME := Color("ccff70")
var arena: Node2D
var hp: float = 100.0
var max_hp: float = 100.0
var speed: float = 265.0
var damage_scale: float = 1.0
var rate_scale: float = 1.0
var dash_cooldown: float = 2.6
var dash_timer: float = 0.0
var dash_left: float = 0.0
var dash_direction := Vector2.RIGHT
var invulnerable: float = 0.0
var fire_timer: float = 0.0
var weapon: int = 0
var weapons: Array[String] = ["脉冲 / PULSE", "霰射 / SCATTER", "磁轨 / RAIL"]
var aim: float = 0.0
var motion := Vector2.ZERO
var time: float = 0.0
var automated: bool = false
var bot_aim := Vector2.RIGHT
var bot_move := Vector2.ZERO
var trail: Array[Vector2] = []
var trail_timer: float = 0.0

func step(delta: float) -> void:
	time += delta
	invulnerable = maxf(0.0, invulnerable - delta)
	dash_timer = maxf(0.0, dash_timer - delta)
	fire_timer = maxf(0.0, fire_timer - delta)
	var direction := bot_move if automated else Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	direction = direction.limit_length()
	var aim_vector: Vector2 = bot_aim if automated else get_global_mouse_position() - global_position
	if aim_vector.length() > 1.0:
		aim = aim_vector.angle()
	if not automated:
		for i in range(3):
			if Input.is_physical_key_pressed(KEY_1 + i):
				weapon = i
	if dash_left > 0.0:
		dash_left -= delta
		motion = dash_direction * 1080.0
	else:
		motion = motion.lerp(direction * speed, minf(1.0, delta * 16.0))
	position += motion * delta
	position.x = clampf(position.x, 44.0, 1236.0)
	position.y = clampf(position.y, 112.0, 710.0)
	trail_timer -= delta
	if trail_timer <= 0.0:
		trail_timer = 0.022
		trail.push_front(position)
		if trail.size() > 10:
			trail.pop_back()
	if (automated or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and fire_timer <= 0.0:
		shoot()
	queue_redraw()

func dash() -> void:
	if dash_timer > 0.0:
		return
	dash_timer = dash_cooldown
	dash_left = 0.16
	invulnerable = maxf(invulnerable, 0.24)
	dash_direction = motion.normalized() if motion.length() > 15.0 else Vector2.from_angle(aim)
	arena.sfx.play("dash")
	arena.burst(position, CYAN, 14, 120.0)

func shoot() -> void:
	var muzzle := position + Vector2.from_angle(aim) * 25.0
	match weapon:
		0:
			fire_timer = 0.15 / rate_scale
			arena.add_bullet(muzzle, Vector2.from_angle(aim) * 760.0, 17.0 * damage_scale, false, 0, CYAN)
			arena.sfx.play("shot", 0.45)
		1:
			fire_timer = 0.54 / rate_scale
			for angle in [-0.22, -0.11, 0.0, 0.11, 0.22]:
				arena.add_bullet(muzzle, Vector2.from_angle(aim + angle) * 650.0, 12.0 * damage_scale, false, 0, LIME, 0.68)
			arena.sfx.play("scatter", 0.6)
		2:
			fire_timer = 0.72 / rate_scale
			arena.add_bullet(muzzle, Vector2.from_angle(aim) * 1150.0, 58.0 * damage_scale, false, 4, Color("d9a5ff"))
			arena.sfx.play("rail", 0.55)
	arena.burst(muzzle, CYAN, 3, 60.0)

func hurt(amount: float) -> void:
	if invulnerable > 0.0 or arena.ended:
		return
	hp = maxf(0.0, hp - amount)
	invulnerable = 0.85
	arena.shake_amount = 11.0
	arena.hit_flash = 0.22
	arena.sfx.play("hit")
	arena.burst(position, Color("ff6b8e"), 18, 180.0)
	if hp <= 0.0:
		arena.finish(false)

func _draw() -> void:
	if invulnerable > 0.0 and dash_left <= 0.0 and fmod(time, 0.12) < 0.06:
		return
	draw_circle(Vector2.ZERO, 30, Color(0.43, 0.91, 0.95, 0.045))
	if dash_left > 0.0:
		draw_arc(Vector2.ZERO, 24, 0, TAU, 32, CYAN, 2.0, true)
	var points := PackedVector2Array()
	for point in [Vector2(22, 0), Vector2(-15, -14), Vector2(-8, 0), Vector2(-15, 14)]:
		points.append(point.rotated(aim))
	draw_colored_polygon(points, LIME)
	draw_polyline(PackedVector2Array([points[1], points[0], points[3]]), Color("efffd4"), 1.2, true)
	draw_circle(Vector2(-2, 0).rotated(aim), 3.5, Color("0a2032"))
	var flame := 7.0 + sin(time * 50) * 4.0 + motion.length() * 0.025
	draw_line(Vector2(-12, 0).rotated(aim), Vector2(-12 - flame, 0).rotated(aim), CYAN, 4.0, true)
