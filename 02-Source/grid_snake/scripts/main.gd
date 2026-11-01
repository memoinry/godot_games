extends "res://scripts/arcade_base.gd"
## Original grid-based Snake implementation, authored for memory.
const COLUMNS: int = 30
const ROWS: int = 20
const CELL: float = 22.0
const ORIGIN := Vector2(150, 103)
var snake: Array[Vector2i] = []
var direction := Vector2i.RIGHT
var pending_direction := Vector2i.RIGHT
var turn_queued: bool = false
var food := Vector2i.ZERO
var accumulator: float = 0.0
var tick_interval: float = 0.13
var foods_eaten: int = 0

func configure() -> void:
	title_text = "GRID SNAKE"
	tagline = "Find your rhythm. Leave no loose ends."
	controls = "ARROWS / WASD: TURN   R: RESTART"
	instructions = "Turn with the arrow keys or WASD.\nEat the glowing fruit to grow and earn 10 points.\nEvery five fruits increase your speed.\nAvoid the walls and your own body. Fill the board to win."
	accent = LIME

func reset_game() -> void:
	snake.clear()
	for i in range(5): snake.append(Vector2i(15 - i, 10))
	direction = Vector2i.RIGHT
	pending_direction = direction
	turn_queued = false
	accumulator = 0.0
	tick_interval = 0.13
	foods_eaten = 0
	place_food()

func game_key(key: int) -> void:
	var wanted := Vector2i.ZERO
	match key:
		KEY_W, KEY_UP: wanted = Vector2i.UP
		KEY_S, KEY_DOWN: wanted = Vector2i.DOWN
		KEY_A, KEY_LEFT: wanted = Vector2i.LEFT
		KEY_D, KEY_RIGHT: wanted = Vector2i.RIGHT
	if wanted != Vector2i.ZERO and wanted != -direction and not turn_queued:
		pending_direction = wanted
		turn_queued = true

func step_game(delta: float) -> void:
	accumulator += delta
	while accumulator >= tick_interval and state == "playing":
		accumulator -= tick_interval
		tick()

func tick() -> void:
	direction = pending_direction
	turn_queued = false
	var next := snake[0] + direction
	var growing := next == food
	var occupied := snake.duplicate()
	if not growing: occupied.pop_back()
	if next.x < 0 or next.x >= COLUMNS or next.y < 0 or next.y >= ROWS:
		finish(false, "The wall wins this round. Watch the next turn.")
		return
	if next in occupied:
		finish(false, "You crossed your own path. Give yourself more room.")
		return
	snake.push_front(next)
	if growing:
		score += 10
		foods_eaten += 1
		tick_interval = maxf(0.065, 0.13 - (foods_eaten / 5) * 0.008)
		sfx.play("pickup", 0.55)
		place_food()
	else:
		snake.pop_back()

func place_food() -> void:
	var empty: Array[Vector2i] = []
	for y in range(ROWS):
		for x in range(COLUMNS):
			var cell := Vector2i(x, y)
			if cell not in snake: empty.append(cell)
	if empty.is_empty():
		finish(true, "Perfect circuit. Every cell belongs to you.")
		return
	food = empty[rng.randi_range(0, empty.size() - 1)]

func game_info() -> String:
	return "LENGTH %03d     SPEED %02d     BEST %05d" % [snake.size(), 1 + foods_eaten / 5, best]

func draw_game() -> void:
	draw_rect(Rect2(ORIGIN - Vector2.ONE * 4, Vector2(COLUMNS, ROWS) * CELL + Vector2.ONE * 8), Color("21394b"), false, 2.0)
	for x in range(COLUMNS):
		for y in range(ROWS):
			draw_rect(Rect2(ORIGIN + Vector2(x, y) * CELL + Vector2.ONE, Vector2.ONE * (CELL - 2)), Color("0c1829"))
	for i in range(snake.size() - 1, -1, -1):
		var cell := ORIGIN + Vector2(snake[i]) * CELL
		var ink := LIME if i == 0 else Color("53bfa0").lerp(Color("1c5364"), minf(float(i) / 30.0, 0.8))
		draw_style_box(style(ink, ink), Rect2(cell + Vector2.ONE, Vector2.ONE * (CELL - 2)))
		if i == 0:
			var at := cell + Vector2.ONE * CELL / 2
			var forward := Vector2(direction) * 4
			var side := Vector2(direction).orthogonal() * 4
			draw_circle(at + forward + side, 2, Color("08101d"))
			draw_circle(at + forward - side, 2, Color("08101d"))
	var fruit := ORIGIN + (Vector2(food) + Vector2.ONE * 0.5) * CELL
	draw_circle(fruit, 12, Color(PINK, 0.12))
	draw_circle(fruit, 6.5, PINK)
	draw_circle(fruit + Vector2(-2, -2), 2, WHITE)

func draw_preview(at: Vector2) -> void:
	var cells: Array[Vector2] = [Vector2(-80, 30), Vector2(-40, 30), Vector2(0, 30), Vector2(40, 30), Vector2(40, -10), Vector2(40, -50)]
	for i in range(cells.size()):
		var ink := LIME if i == cells.size() - 1 else Color("53bfa0")
		draw_style_box(style(ink, ink), Rect2(at + cells[i] - Vector2.ONE * 16, Vector2.ONE * 32))
	draw_circle(at + Vector2(-65, -60), 12, PINK)
