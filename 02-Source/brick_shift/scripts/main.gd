extends "res://scripts/arcade_base.gd"
## Three-board Breakout with swept substeps, armor bricks and falling boosts.
var paddle_x: float = 480.0
var paddle_width: float = 116.0
var ball := Vector2(480, 508)
var velocity := Vector2.ZERO
var attached: bool = true
var lives: int = 3
var level: int = 1
var bricks: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var wide_timer: float = 0.0
var last_mouse := Vector2.ZERO
var mouse_target: float = 480.0
var destroyed: int = 0

func configure() -> void:
	title_text = "BRICK SHIFT"
	tagline = "One paddle. Three sectors. Clear them all."
	controls = "MOUSE / A D: MOVE   SPACE / CLICK: LAUNCH"
	instructions = "Move the paddle with your mouse, A/D or arrow keys.\nPress Space or click to launch the ball.\nClear all three boards before your three lives run out.\nArmored bricks take two hits. Catch green boosts for a wider paddle."
	accent = CYAN

func reset_game() -> void:
	paddle_x = 480
	paddle_width = 116
	lives = 3
	level = 1
	wide_timer = 0
	destroyed = 0
	drops.clear()
	last_mouse = get_global_mouse_position()
	mouse_target = paddle_x
	make_board()
	reset_ball()

func make_board() -> void:
	bricks.clear()
	for row in range(5):
		for column in range(9):
			if level == 2 and row == 2 and column % 2 == 0: continue
			if level == 3 and (row + column) % 5 == 0: continue
			bricks.append({"rect": Rect2(48 + column * 97, 123 + row * 36, 88, 25), "hp": 2 if level >= 2 and row < 2 else 1, "color": [Color("6ee7f2"), Color("c8a2ff"), Color("ff6b8e"), Color("ffc477"), Color("ccff70")][row]})

func reset_ball() -> void:
	attached = true
	velocity = Vector2.ZERO
	ball = Vector2(paddle_x, 508)
	announce("SPACE / CLICK TO LAUNCH", 999.0)

func launch() -> void:
	if not attached: return
	attached = false
	velocity = Vector2(0.4 if rng.randf() < 0.5 else -0.4, -1).normalized() * (395.0 + level * 35)
	notice_timer = 0
	sfx.play("shot", 0.4)

func game_key(key: int) -> void:
	if key == KEY_SPACE: launch()

func _unhandled_input(event: InputEvent) -> void:
	if state == "playing" and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		launch()

func step_game(delta: float) -> void:
	var current_mouse := get_global_mouse_position()
	if current_mouse.distance_to(last_mouse) > 1.0:
		mouse_target = current_mouse.x
		last_mouse = current_mouse
	var direction := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	if direction != 0:
		paddle_x += direction * 640 * delta
		mouse_target = paddle_x
	else:
		paddle_x = move_toward(paddle_x, mouse_target, 1200 * delta)
	wide_timer = maxf(0, wide_timer - delta)
	paddle_width = 176.0 if wide_timer > 0 else 116.0
	paddle_x = clampf(paddle_x, 36 + paddle_width / 2, 924 - paddle_width / 2)
	if attached:
		ball = Vector2(paddle_x, 508)
	else:
		var substeps := maxi(1, ceili(velocity.length() * delta / 6.0))
		for i in range(substeps):
			advance_ball(delta / substeps)
			if attached or state != "playing": break
	for i in range(drops.size() - 1, -1, -1):
		drops[i].p.y += 160 * delta
		if Rect2(paddle_x - paddle_width / 2 - 10, 510, paddle_width + 20, 30).has_point(drops[i].p):
			wide_timer = 12
			drops.remove_at(i)
			sfx.play("pickup", 0.6)
		elif drops[i].p.y > 560:
			drops.remove_at(i)

func advance_ball(delta: float) -> void:
	var previous := ball
	ball += velocity * delta
	if ball.x < 39:
		ball.x = 39
		velocity.x = absf(velocity.x)
		sfx.play("shot", 0.25)
	elif ball.x > 921:
		ball.x = 921
		velocity.x = -absf(velocity.x)
		sfx.play("shot", 0.25)
	if ball.y < 100:
		ball.y = 100
		velocity.y = absf(velocity.y)
	var paddle := Rect2(paddle_x - paddle_width / 2, 522, paddle_width, 12)
	if velocity.y > 0 and previous.y <= 516 and ball.y >= 516 and absf(ball.x - paddle_x) <= paddle_width / 2 + 7:
		var offset := clampf((ball.x - paddle_x) / (paddle_width / 2), -0.94, 0.94)
		velocity = Vector2(offset * 0.85, -1).normalized() * minf(680, velocity.length() + 4)
		ball.y = paddle.position.y - 7
		sfx.play("shot", 0.35)
	for i in range(bricks.size() - 1, -1, -1):
		var rect: Rect2 = bricks[i].rect
		if not rect.grow(6).has_point(ball): continue
		if previous.y <= rect.position.y - 5 or previous.y >= rect.end.y + 5:
			velocity.y *= -1
		else:
			velocity.x *= -1
		ball = previous
		bricks[i].hp -= 1
		score += 10
		sfx.play("hit", 0.35)
		if bricks[i].hp <= 0:
			destroyed += 1
			if destroyed % 8 == 0:
				drops.append({"p": rect.get_center()})
			bricks.remove_at(i)
		break
	if bricks.is_empty():
		score += 200
		if level >= 3:
			finish(true, "All three sectors cleared. A clean sweep.")
		else:
			level += 1
			drops.clear()
			make_board()
			reset_ball()
		return
	if ball.y > 560:
		lives -= 1
		sfx.play("boom", 0.5)
		if lives <= 0: finish(false, "Out of lives. Aim with the edges of your paddle.")
		else: reset_ball()

func game_info() -> String:
	return "BOARD %d / 3     LIVES %d     BRICKS %02d%s" % [level, lives, bricks.size(), "     WIDE %ds" % ceili(wide_timer) if wide_timer > 0 else ""]

func draw_game() -> void:
	draw_rect(Rect2(32, 93, 896, 466), Color("223b4c"), false, 2)
	for brick in bricks:
		var ink: Color = brick.color
		draw_style_box(style(Color(ink, 0.16), ink), brick.rect)
		if brick.hp > 1:
			draw_line(brick.rect.position + Vector2(8, 12), brick.rect.end - Vector2(8, 13), ink, 2)
	draw_style_box(style(LIME if wide_timer > 0 else CYAN, WHITE), Rect2(paddle_x - paddle_width / 2, 522, paddle_width, 12))
	draw_circle(ball, 13, Color(CYAN, 0.12))
	draw_circle(ball, 6, WHITE)
	for drop in drops:
		draw_style_box(style(LIME, LIME), Rect2(drop.p - Vector2(12, 7), Vector2(24, 14)))

func draw_preview(at: Vector2) -> void:
	for row in range(3):
		for column in range(4):
			var ink: Color = [CYAN, Color("c8a2ff"), PINK][row]
			draw_style_box(style(Color(ink, 0.2), ink), Rect2(at + Vector2(-113 + column * 58, -90 + row * 32), Vector2(50, 22)))
	draw_line(at + Vector2(-40, 40), at + Vector2(35, -5), Color(CYAN, 0.3), 2)
	draw_circle(at + Vector2(35, -5), 8, WHITE)
	draw_style_box(style(CYAN, CYAN), Rect2(at + Vector2(-56, 85), Vector2(112, 12)))
