extends "res://scripts/arcade_base.gd"
## Keyboard/mouse Pong against a deliberately imperfect, speed-limited opponent.
const TOP: float = 100.0
const BOTTOM: float = 550.0
var player_y: float = 325.0
var rival_y: float = 325.0
var ball := Vector2(480, 325)
var velocity := Vector2.ZERO
var player_points: int = 0
var rival_points: int = 0
var serve_timer: float = 1.2
var serve_direction: float = 1.0
var rally: int = 0
var longest_rally: int = 0
var mouse_target: float = 325.0
var last_mouse := Vector2.ZERO

func configure() -> void:
	title_text = "PADDLE DUEL"
	tagline = "Read the angle. Own the next rally."
	controls = "W S / ARROWS / MOUSE: MOVE   SPACE: SERVE"
	instructions = "Move your left paddle with W/S, the arrows or the mouse.\nThe first player to seven points wins the match.\nHit with the paddle edges to change the return angle.\nRallies speed up over time. Space serves early between points."
	accent = Color("c8a2ff")

func reset_game() -> void:
	player_y = 325
	rival_y = 325
	player_points = 0
	rival_points = 0
	longest_rally = 0
	mouse_target = player_y
	last_mouse = get_global_mouse_position()
	serve_direction = 1.0
	reset_ball()

func reset_ball() -> void:
	ball = Vector2(480, 325)
	velocity = Vector2.ZERO
	rally = 0
	serve_timer = 1.2
	announce("SPACE TO SERVE", 1.2)

func serve() -> void:
	if velocity != Vector2.ZERO: return
	serve_timer = 0
	velocity = Vector2(serve_direction, rng.randf_range(-0.45, 0.45)).normalized() * 380.0
	notice_timer = 0

func game_key(key: int) -> void:
	if key == KEY_SPACE: serve()

func step_game(delta: float) -> void:
	var current_mouse := get_global_mouse_position()
	if current_mouse.distance_to(last_mouse) > 1:
		mouse_target = current_mouse.y
		last_mouse = current_mouse
	var direction := float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	if direction != 0:
		player_y += direction * 560.0 * delta
		mouse_target = player_y
	else:
		player_y = move_toward(player_y, mouse_target, 1000.0 * delta)
	player_y = clampf(player_y, TOP + 49, BOTTOM - 49)
	var target: float = ball.y + sin(elapsed * 1.9) * 41.0 if velocity.x > 0 else 325.0
	rival_y = move_toward(rival_y, target, (240.0 + minf(60, player_points * 8)) * delta)
	rival_y = clampf(rival_y, TOP + 49, BOTTOM - 49)
	if velocity == Vector2.ZERO:
		serve_timer -= delta
		if serve_timer <= 0: serve()
		return
	var substeps := maxi(1, ceili(velocity.length() * delta / 6.0))
	for i in range(substeps):
		advance_ball(delta / substeps)
		if state != "playing" or velocity == Vector2.ZERO: break

func advance_ball(delta: float) -> void:
	var previous := ball
	ball += velocity * delta
	if ball.y < TOP + 7:
		ball.y = TOP + 7
		velocity.y = absf(velocity.y)
	elif ball.y > BOTTOM - 7:
		ball.y = BOTTOM - 7
		velocity.y = -absf(velocity.y)
	if velocity.x < 0 and previous.x >= 68 and ball.x <= 68 and absf(ball.y - player_y) < 56:
		rebound(player_y, 1.0)
		ball.x = 69
		score += 10
	elif velocity.x > 0 and previous.x <= 892 and ball.x >= 892 and absf(ball.y - rival_y) < 56:
		rebound(rival_y, -1.0)
		ball.x = 891
	if ball.x < 20:
		point(false)
	elif ball.x > 940:
		point(true)

func rebound(paddle_y: float, direction: float) -> void:
	var offset := clampf((ball.y - paddle_y) / 49, -1, 1)
	velocity = Vector2(direction, offset * 1.1).normalized() * minf(690, velocity.length() + 27)
	rally += 1
	longest_rally = maxi(longest_rally, rally)
	sfx.play("shot", 0.5)

func point(player_scored: bool) -> void:
	if player_scored:
		player_points += 1
		score += 100
		serve_direction = 1
		sfx.play("pickup", 0.7)
	else:
		rival_points += 1
		serve_direction = -1
		sfx.play("hit", 0.6)
	if player_points >= 7:
		score += 500
		finish(true, "Match won: %d - %d. You owned the court." % [player_points, rival_points])
	elif rival_points >= 7:
		finish(false, "Match lost: %d - %d. Try aiming for the far corners." % [player_points, rival_points])
	else:
		reset_ball()

func game_info() -> String:
	return "YOU  %d   :   %d  RIVAL     FIRST TO 7     LONGEST RALLY %02d" % [player_points, rival_points, longest_rally]

func draw_game() -> void:
	draw_rect(Rect2(32, 93, 896, 466), Color("2c3b50"), false, 2)
	for y in range(103, 550, 26):
		draw_line(Vector2(480, y), Vector2(480, y + 13), Color("304055"), 2)
	draw_arc(Vector2(480, 325), 63, 0, TAU, 64, Color("213249"), 1.0, true)
	draw_style_box(style(LIME, LIME), Rect2(48, player_y - 49, 13, 98))
	draw_style_box(style(accent, accent), Rect2(899, rival_y - 49, 13, 98))
	draw_circle(ball, 15, Color(CYAN, 0.1))
	if velocity.length() > 1:
		draw_line(ball - velocity.normalized() * 26, ball, Color(CYAN, 0.45), 4, true)
	draw_circle(ball, 7, WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(385, 155), str(player_points), HORIZONTAL_ALIGNMENT_CENTER, -1, 45, Color(LIME, 0.65))
	draw_string(ThemeDB.fallback_font, Vector2(550, 155), str(rival_points), HORIZONTAL_ALIGNMENT_CENTER, -1, 45, Color(accent, 0.65))

func draw_preview(at: Vector2) -> void:
	draw_line(at + Vector2(0, -110), at + Vector2(0, 110), Color("304055"), 2)
	draw_style_box(style(LIME, LIME), Rect2(at + Vector2(-110, -65), Vector2(14, 100)))
	draw_style_box(style(accent, accent), Rect2(at + Vector2(98, -25), Vector2(14, 100)))
	draw_line(at + Vector2(-30, 47), at + Vector2(45, 15), Color(CYAN, 0.5), 3, true)
	draw_circle(at + Vector2(45, 15), 10, WHITE)
