extends Node2D
## Run simulation, collisions, wave director, rendering and upgrade application.
## No browser code is embedded: this is an independent Godot implementation.

signal wave_cleared
signal run_finished(won: bool)
signal announcement(title: String, subtitle: String, duration: float)

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const WAVE_SECONDS: float = 45.0
const NORMAL_WAVES: int = 6
const CYAN := Color("6ee7f2")
const LIME := Color("ccff70")
const PINK := Color("ff6b8e")

var player: Node2D
var sfx: Node
var enemies: Array[Node2D] = []
var bullets: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var float_texts: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var wave: int = 0
var remaining: float = WAVE_SECONDS
var spawn_timer: float = 0.0
var elapsed: float = 0.0
var kills: int = 0
var score: int = 0
var combo: int = 0
var combo_timer: float = 0.0
var running: bool = false
var ended: bool = false
var shake_enabled: bool = true
var shake_amount: float = 0.0
var hit_flash: float = 0.0
var boss: Node2D
var magnet_radius: float = 95.0
var pickup_boost: float = 1.0
var test_invincible: bool = false
var test_mode: bool = false
var next_bullet_id: int = 0
var acquired: Dictionary = {}
var stars: Array[Vector3] = []

const UPGRADES: Array[Dictionary] = [
	{"id": "damage", "mark": "ATK", "title": "超载弹芯", "text": "所有武器伤害 +22%", "note": "更快击破重装单位", "color": "ffc477"},
	{"id": "rate", "mark": "RPM", "title": "冷却旁路", "text": "所有武器射速 +18%", "note": "持续输出 · 火力压制", "color": "6ee7f2"},
	{"id": "hull", "mark": "HP+", "title": "复合装甲", "text": "最大护甲 +25，并恢复 35", "note": "提高容错 · 继续战斗", "color": "ccff70"},
	{"id": "dash", "mark": "DSH", "title": "相位引擎", "text": "冲刺冷却缩短 20%", "note": "冲刺期间免疫伤害", "color": "c8a2ff"},
	{"id": "speed", "mark": "SPD", "title": "矢量推进", "text": "移动速度 +12%", "note": "拉开距离 · 绕开弹幕", "color": "6ee7f2"},
	{"id": "salvage", "mark": "MAG", "title": "回收力场", "text": "拾取范围 +60，维修量 +25%", "note": "道具自动向你靠拢", "color": "ccff70"}
]

func _ready() -> void:
	rng.seed = 310027
	for i in range(105):
		stars.append(Vector3(rng.randf_range(28, 1252), rng.randf_range(96, 728), rng.randf_range(0.5, 1.8)))
	rng.randomize()
	player = PlayerScript.new()
	player.arena = self
	add_child(player)
	player.position = Vector2(640, 430)
	player.visible = false

func start() -> void:
	clear_entities()
	wave = 0
	score = 0
	kills = 0
	combo = 0
	combo_timer = 0.0
	elapsed = 0.0
	ended = false
	acquired.clear()
	magnet_radius = 95.0
	pickup_boost = 1.0
	var old_player := player
	remove_child(old_player)
	old_player.queue_free()
	player = PlayerScript.new()
	player.arena = self
	add_child(player)
	player.position = Vector2(640, 430)
	player.invulnerable = 2.5
	begin_wave()

func clear_entities() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	bullets.clear()
	particles.clear()
	pickups.clear()
	float_texts.clear()
	boss = null

func begin_wave() -> void:
	wave += 1
	remaining = WAVE_SECONDS
	spawn_timer = 1.8
	running = true
	bullets.clear()
	player.invulnerable = maxf(player.invulnerable, 1.5)
	if wave <= NORMAL_WAVES:
		var hints: Array[String] = ["移动瞄准 · 按住左键射击 · 空格冲刺", "炮手已接近 · 保持移动躲避来袭弹丸", "突击者将锁定航线 · 看见橙线后侧移", "分裂核心释放环形弹幕 · 磁轨可穿透敌人", "集中火力 · 收集维修包与清场脉冲", "最后一波 · 保留护甲，准备核心战"]
		announce("SECTOR %02d / 第 %d 波" % [wave, wave], hints[wave - 1], 3.6)
	else:
		announce("WARNING / 母核苏醒", "击破母核完成突围 · 空格冲刺可穿越弹幕", 4.0)
		sfx.play("warning")
		spawn_enemy(4, Vector2(640, 210))

func _physics_process(delta: float) -> void:
	if not test_mode:
		step(delta)

func step(delta: float) -> void:
	if not running or ended:
		return
	elapsed += delta
	shake_amount = move_toward(shake_amount, 0.0, delta * 30.0)
	hit_flash = maxf(0.0, hit_flash - delta)
	if shake_enabled and shake_amount > 0.1:
		position = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * shake_amount
	else:
		position = Vector2.ZERO
	combo_timer = maxf(0.0, combo_timer - delta)
	if combo_timer <= 0.0:
		combo = 0
	player.step(delta)
	if test_invincible:
		player.invulnerable = 1.0
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy) and not enemy.dead:
			enemy.step(delta)
			if ended:
				break
	if ended:
		queue_redraw()
		return
	step_bullets(delta)
	step_pickups(delta)
	step_effects(delta)
	if wave <= NORMAL_WAVES:
		remaining = maxf(0.0, remaining - delta)
		spawn_timer -= delta
		if remaining > 0.0 and spawn_timer <= 0.0 and enemies.size() < 55:
			spawn_timer = maxf(0.42, 1.15 - wave * 0.095)
			var count := 2 if wave >= 4 and rng.randf() < 0.25 else 1
			for i in range(count):
				var pool := mini(wave, 4)
				spawn_enemy(rng.randi_range(0, pool - 1), edge_spawn())
		if remaining <= 0.0 and enemies.is_empty():
			running = false
			position = Vector2.ZERO
			bullets.clear()
			# Recover leftover pickups so a cleared wave never wastes earned repairs.
			for item in pickups:
				collect(item)
			pickups.clear()
			player.hp = minf(player.max_hp, player.hp + 10.0)
			sfx.play("upgrade")
			wave_cleared.emit()
	queue_redraw()

func edge_spawn() -> Vector2:
	var side := rng.randi_range(0, 3)
	var result := Vector2.ZERO
	match side:
		0: result = Vector2(35, rng.randf_range(115, 705))
		1: result = Vector2(1245, rng.randf_range(115, 705))
		2: result = Vector2(rng.randf_range(45, 1235), 104)
		3: result = Vector2(rng.randf_range(45, 1235), 720)
	if result.distance_to(player.position) < 240.0:
		result = Vector2(1280 - result.x, 825 - result.y)
	return result

func spawn_enemy(kind: int, at: Vector2) -> Node2D:
	var enemy := EnemyScript.new()
	enemy.configure(self, kind, at, wave)
	add_child(enemy)
	enemies.append(enemy)
	if kind == 4:
		boss = enemy
	burst(at, enemy.color, 10, 65.0)
	return enemy

func add_bullet(at: Vector2, velocity: Vector2, damage: float, hostile: bool, pierce: int, color: Color, lifetime: float = 1.7) -> void:
	if bullets.size() >= 800:
		return
	next_bullet_id += 1
	bullets.append({"id": next_bullet_id, "p": at, "old": at, "v": velocity, "damage": damage, "hostile": hostile, "pierce": pierce, "color": color, "life": lifetime, "hits": []})

func step_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		if ended:
			break
		var bullet: Dictionary = bullets[i]
		bullet.old = bullet.p
		bullet.p += bullet.v * delta
		bullet.life -= delta
		var remove: bool = bullet.life <= 0.0 or not Rect2(10, 85, 1260, 655).has_point(bullet.p)
		if not remove:
			if bullet.hostile:
				if segment_distance(player.position, bullet.old, bullet.p) < 15.0:
					player.hurt(bullet.damage)
					remove = true
			else:
				for enemy in enemies.duplicate():
					if not is_instance_valid(enemy) or enemy.dead or enemy.get_instance_id() in bullet.hits:
						continue
					if segment_distance(enemy.position, bullet.old, bullet.p) < enemy.radius + 4.0:
						bullet.hits.append(enemy.get_instance_id())
						enemy.hurt(bullet.damage)
						burst(bullet.p, bullet.color, 3, 60.0)
						if bullet.pierce <= 0:
							remove = true
							break
						bullet.pierce -= 1
		if remove and i < bullets.size():
			bullets.remove_at(i)

func segment_distance(point: Vector2, from: Vector2, to: Vector2) -> float:
	var line := to - from
	if line.length_squared() < 0.001:
		return point.distance_to(from)
	return point.distance_to(from + line * clampf((point - from).dot(line) / line.length_squared(), 0.0, 1.0))

func enemy_killed(enemy: Node2D) -> void:
	enemies.erase(enemy)
	kills += 1
	combo += 1
	combo_timer = 3.5
	var multiplier := 1 + mini(combo / 8, 4)
	var earned: int = [100, 180, 170, 240, 5000][enemy.kind] * multiplier
	score += earned
	burst(enemy.position, enemy.color, 18 if enemy.kind != 4 else 100, 170.0)
	float_texts.append({"p": enemy.position, "text": "+%d" % earned, "life": 0.8, "color": enemy.color})
	shake_amount = maxf(shake_amount, 2.0 if enemy.kind != 4 else 18.0)
	if kills % 3 == 0 or enemy.kind == 4:
		sfx.play("boom", 0.45)
	if enemy.kind == 3:
		for offset in [Vector2(-24, 0), Vector2(24, 0)]:
			spawn_enemy(0, enemy.position + offset)
	if rng.randf() < 0.15:
		drop_pickup(enemy.position, 0 if rng.randf() < 0.75 else 1)
	if enemy.kind == 4:
		finish(true)

func drop_pickup(at: Vector2, kind: int) -> void:
	pickups.append({"p": at, "kind": kind, "life": 15.0})

func step_pickups(delta: float) -> void:
	for i in range(pickups.size() - 1, -1, -1):
		var item: Dictionary = pickups[i]
		item.life -= delta
		var distance: float = item.p.distance_to(player.position)
		if distance < magnet_radius:
			item.p = item.p.move_toward(player.position, delta * 350.0)
		if item.p.distance_to(player.position) < 23.0:
			collect(item)
			pickups.remove_at(i)
		elif item.life <= 0.0:
			pickups.remove_at(i)

func collect(item: Dictionary) -> void:
	sfx.play("pickup", 0.55)
	if item.kind == 0:
		player.hp = minf(player.max_hp, player.hp + 18.0 * pickup_boost)
		float_texts.append({"p": player.position, "text": "+ REPAIR", "life": 1.1, "color": LIME})
	else:
		for enemy in enemies.duplicate():
			if is_instance_valid(enemy):
				enemy.hurt(80.0)
		bullets = bullets.filter(func(b: Dictionary) -> bool: return not b.hostile)
		burst(player.position, CYAN, 55, 500.0)
		shake_amount = 8.0

func burst(at: Vector2, color: Color, count: int, force: float) -> void:
	for i in range(count):
		if particles.size() >= 1000:
			break
		var lifetime := rng.randf_range(0.18, 0.6)
		particles.append({"p": at, "v": Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(force * 0.2, force), "life": lifetime, "max": lifetime, "color": color})

func step_effects(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		particles[i].life -= delta
		particles[i].p += particles[i].v * delta
		particles[i].v *= maxf(0.0, 1.0 - delta * 3.0)
		if particles[i].life <= 0.0:
			particles.remove_at(i)
	for i in range(float_texts.size() - 1, -1, -1):
		float_texts[i].life -= delta
		float_texts[i].p.y -= delta * 32.0
		if float_texts[i].life <= 0.0:
			float_texts.remove_at(i)

func choices() -> Array[Dictionary]:
	var pool := UPGRADES.duplicate(true)
	var result: Array[Dictionary] = []
	for i in range(3):
		var index := rng.randi_range(0, pool.size() - 1)
		result.append(pool.pop_at(index))
	return result

func apply_upgrade(id: String) -> void:
	acquired[id] = int(acquired.get(id, 0)) + 1
	match id:
		"damage": player.damage_scale *= 1.22
		"rate": player.rate_scale *= 1.18
		"hull":
			player.max_hp += 25.0
			player.hp = minf(player.max_hp, player.hp + 35.0)
		"dash": player.dash_cooldown *= 0.8
		"speed": player.speed *= 1.12
		"salvage":
			magnet_radius += 60.0
			pickup_boost *= 1.25
	sfx.play("upgrade", 0.7)
	begin_wave()

func announce(title: String, subtitle: String, duration: float) -> void:
	announcement.emit(title, subtitle, duration)

func finish(won: bool) -> void:
	if ended:
		return
	ended = true
	running = false
	position = Vector2.ZERO
	run_finished.emit(won)

func _draw() -> void:
	draw_rect(Rect2(-20, -20, 1320, 840), Color("080f20"))
	# Sparse star field and a crisp navigation grid, bounded by a combat frame.
	for star in stars:
		draw_circle(Vector2(star.x, star.y), star.z, Color(0.35, 0.6, 0.7, 0.23 * star.z))
	for x in range(28, 1253, 48):
		draw_line(Vector2(x, 96), Vector2(x, 728), Color(0.22, 0.45, 0.55, 0.075), 1.0)
	for y in range(104, 729, 48):
		draw_line(Vector2(28, y), Vector2(1252, y), Color(0.22, 0.45, 0.55, 0.075), 1.0)
	draw_arc(Vector2(640, 416), 220, 0, TAU, 100, Color(0.25, 0.55, 0.62, 0.055), 1.0, true)
	draw_arc(Vector2(640, 416), 310, 0, TAU, 120, Color(0.25, 0.55, 0.62, 0.045), 1.0, true)
	draw_rect(Rect2(28, 96, 1224, 632), Color("233444"), false, 1.0)
	for corner in [Vector2(28, 96), Vector2(1252, 96), Vector2(28, 728), Vector2(1252, 728)]:
		var inward := Vector2(1 if corner.x < 640 else -1, 1 if corner.y < 416 else -1)
		draw_line(corner, corner + Vector2(inward.x * 28, 0), CYAN, 2.0)
		draw_line(corner, corner + Vector2(0, inward.y * 28), CYAN, 2.0)
	if not is_instance_valid(player) or not player.visible:
		return
	for i in range(1, player.trail.size()):
		draw_line(player.trail[i - 1], player.trail[i], Color(CYAN, (1.0 - float(i) / player.trail.size()) * 0.3), 3.0, true)
	for bullet in bullets:
		var direction: Vector2 = bullet.v.normalized()
		var length_value := 12.0 if bullet.hostile else (27.0 if bullet.pierce > 0 else 17.0)
		draw_line(bullet.p - direction * length_value, bullet.p, Color(bullet.color, 0.14), 9.0, true)
		draw_line(bullet.p - direction * length_value, bullet.p, bullet.color, 3.0 if not bullet.hostile else 4.0, true)
	for particle in particles:
		var alpha: float = particle.life / particle.max
		draw_line(particle.p, particle.p - particle.v * 0.025, Color(particle.color, alpha), 2.0, true)
	for item in pickups:
		if item.life < 3.0 and fmod(elapsed, 0.25) < 0.12:
			continue
		var ink := LIME if item.kind == 0 else CYAN
		var at: Vector2 = item.p
		draw_circle(at, 19.0 + sin(elapsed * 5) * 2.0, Color(ink, 0.06))
		draw_arc(at, 11, 0, TAU, 24, ink, 1.3, true)
		draw_line(at - Vector2(5, 0), at + Vector2(5, 0), ink, 2.0)
		if item.kind == 0:
			draw_line(at - Vector2(0, 5), at + Vector2(0, 5), ink, 2.0)
		else:
			draw_arc(at, 5, 0, TAU, 16, ink, 1.5, true)
	for text_data in float_texts:
		draw_string(ThemeDB.fallback_font, text_data.p, text_data.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 15, Color(text_data.color, minf(1.0, text_data.life * 2.0)))
	if hit_flash > 0.0:
		draw_rect(Rect2(28, 96, 1224, 632), Color(1, 0.2, 0.36, hit_flash * 0.25), false, 10.0)
	if running:
		var cursor := get_global_mouse_position() - position
		if Rect2(28, 96, 1224, 632).has_point(cursor):
			draw_arc(cursor, 9.0, 0, TAU, 24, Color(CYAN, 0.8), 1.0, true)
			for i in range(4):
				var direction := Vector2.from_angle(i * PI / 2.0)
				draw_line(cursor + direction * 13.0, cursor + direction * 19.0, CYAN, 1.0, true)
