extends Node2D
## Common application shell for memory's three independent Godot arcade projects.
## Subclasses provide configure/reset_game/step_game/draw_game/game_key/draw_preview.
const WHITE := Color("eef2e6")
const MUTED := Color("8fa1b6")
const CYAN := Color("6ee7f2")
const LIME := Color("ccff70")
const PINK := Color("ff6b8e")
const SoundBank = preload("res://scripts/sound_bank.gd")
var title_text: String = "ARCADE"
var tagline: String = "A game by memory"
var instructions: String = ""
var controls: String = ""
var accent: Color = LIME
var state: String = "menu"
var score: int = 0
var best: int = 0
var elapsed: float = 0.0
var notice: String = ""
var notice_timer: float = 0.0
var save_path: String = "user://record.cfg"
var ui: Control
var sfx: Node
var hud_score: Label
var hud_info: Label
var hud_notice: Label
var automatic_steps: bool = true
var result_won: bool = false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	configure()
	rng.randomize()
	var cfg := ConfigFile.new()
	if cfg.load(save_path) == OK:
		best = maxi(0, int(cfg.get_value("record", "best", 0)))
	sfx = SoundBank.new()
	add_child(sfx)
	sfx.music_enabled = false
	sfx.master_volume = 0.45
	var canvas := CanvasLayer.new()
	add_child(canvas)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	reset_game()
	show_menu()

func configure() -> void: pass
func reset_game() -> void: pass
func step_game(_delta: float) -> void: pass
func draw_game() -> void: pass
func game_key(_key: int) -> void: pass
func draw_preview(_at: Vector2) -> void: pass
func game_info() -> String: return ""

func style(fill: Color, border: Color) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = border
	result.set_border_width_all(1)
	result.set_corner_radius_all(8)
	return result

func text(value: String, at: Vector2, width: float, font_size: int = 20, ink: Color = WHITE) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.size.x = width
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", ink)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(label)
	return label

func paragraph(value: String, at: Vector2, width: float, font_size: int = 18, ink: Color = MUTED) -> Label:
	var label := text(value, at, width, font_size, ink)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func button(value: String, at: Vector2, width: float, action: Callable, primary: bool = false) -> Button:
	var item := Button.new()
	item.text = value
	item.position = at
	item.size = Vector2(width, 50)
	item.add_theme_font_size_override("font_size", 18)
	item.add_theme_color_override("font_color", Color("08101d") if primary else WHITE)
	item.add_theme_color_override("font_hover_color", Color("08101d") if primary else accent)
	item.add_theme_color_override("font_pressed_color", Color("08101d"))
	item.add_theme_stylebox_override("normal", style(accent if primary else Color("142235"), accent if primary else Color("33465b")))
	item.add_theme_stylebox_override("hover", style(Color("dfffad") if primary else Color("22364a"), accent))
	item.add_theme_stylebox_override("pressed", style(CYAN, CYAN))
	item.focus_mode = Control.FOCUS_NONE
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.pressed.connect(func() -> void:
		sfx.play("click")
		action.call()
	)
	ui.add_child(item)
	return item

func clear_ui() -> void:
	for node in ui.get_children():
		ui.remove_child(node)
		node.queue_free()
	hud_score = null
	hud_info = null
	hud_notice = null

func header() -> void:
	text("MEMORY / ARCADE", Vector2(32, 20), 400, 16, accent)
	var right := text("GODOT 4  /  OFFLINE", Vector2(650, 20), 278, 14, MUTED)
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func show_menu() -> void:
	state = "menu"
	clear_ui()
	header()
	text(title_text, Vector2(48, 142), 620, 48, WHITE)
	paragraph(tagline, Vector2(50, 215), 440, 21, accent)
	paragraph("Built to play. One more round.\nAuthor: memory", Vector2(50, 280), 450, 19)
	button("PLAY  /  ENTER", Vector2(50, 379), 330, start_game, true)
	button("HOW TO PLAY", Vector2(50, 447), 330, show_help)
	text("PERSONAL BEST   %05d" % best, Vector2(50, 542), 600, 17, CYAN)
	text("v1.0  /  memory", Vector2(750, 597), 190, 14, MUTED)
	queue_redraw()

func show_help() -> void:
	state = "help"
	clear_ui()
	header()
	text("HOW TO PLAY", Vector2(70, 110), 820, 38)
	paragraph(instructions, Vector2(72, 190), 810, 21, WHITE)
	paragraph("P / ESC   Pause or resume\nR   Restart a run\nM   Mute / unmute\nF11   Toggle fullscreen", Vector2(72, 375), 800, 18)
	button("BACK", Vector2(72, 542), 200, show_menu)
	button("LET'S PLAY", Vector2(612, 542), 270, start_game, true)
	queue_redraw()

func start_game() -> void:
	score = 0
	elapsed = 0.0
	result_won = false
	notice = ""
	notice_timer = 0.0
	reset_game()
	state = "playing"
	build_hud()
	queue_redraw()

func build_hud() -> void:
	clear_ui()
	text(title_text, Vector2(32, 19), 440, 25)
	text("by memory", Vector2(34, 55), 350, 13, MUTED)
	hud_score = text("SCORE  00000", Vector2(500, 21), 300, 23, accent)
	button("PAUSE", Vector2(817, 18), 110, pause_game)
	hud_info = text("", Vector2(32, 576), 895, 17, WHITE)
	text(controls + "   |   P: PAUSE   M: MUTE", Vector2(32, 610), 900, 13, MUTED)
	hud_notice = text("", Vector2(160, 270), 640, 26, WHITE)
	hud_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	refresh_hud()

func refresh_hud() -> void:
	if is_instance_valid(hud_score):
		hud_score.text = "SCORE  %05d" % score
		hud_info.text = game_info()
		hud_notice.text = notice if notice_timer > 0 else ""

func pause_game() -> void:
	if state != "playing": return
	state = "paused"
	clear_ui()
	shade()
	text("TAKE A BREATHER", Vector2(250, 175), 560, 38)
	text("Your round is waiting.", Vector2(250, 239), 540, 20, MUTED)
	button("RESUME", Vector2(250, 311), 460, resume_game, true)
	button("RESTART", Vector2(250, 377), 460, start_game)
	button("MAIN MENU", Vector2(250, 443), 460, show_menu)
	queue_redraw()

func resume_game() -> void:
	state = "playing"
	build_hud()
	queue_redraw()

func shade() -> void:
	var background := ColorRect.new()
	background.color = Color(0.02, 0.035, 0.065, 0.94)
	background.size = Vector2(960, 640)
	ui.add_child(background)

func finish(won: bool, reason: String) -> void:
	if state == "result": return
	result_won = won
	state = "result"
	best = maxi(best, score)
	var cfg := ConfigFile.new()
	cfg.set_value("record", "best", best)
	cfg.save(save_path)
	sfx.play("upgrade" if won else "boom", 0.8)
	clear_ui()
	shade()
	header()
	text("ROUND COMPLETE" if won else "ONE MORE ROUND?", Vector2(160, 145), 760, 42, accent if won else PINK)
	paragraph(reason, Vector2(163, 220), 650, 21, WHITE)
	text("SCORE  %05d   /   BEST  %05d" % [score, best], Vector2(163, 308), 760, 26, accent)
	button("PLAY AGAIN  /  ENTER", Vector2(163, 406), 350, start_game, true)
	button("MAIN MENU", Vector2(539, 406), 250, show_menu)
	text("Author: memory", Vector2(163, 531), 600, 17, MUTED)
	queue_redraw()

func announce(value: String, duration: float = 1.5) -> void:
	notice = value
	notice_timer = duration

func _physics_process(delta: float) -> void:
	if automatic_steps:
		step(delta)

func step(delta: float) -> void:
	if state != "playing": return
	elapsed += delta
	notice_timer = maxf(0.0, notice_timer - delta)
	step_game(delta)
	refresh_hud()
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var key: int = event.physical_keycode
	if key == KEY_M:
		sfx.master_volume = 0.0 if sfx.master_volume > 0 else 0.45
	elif key == KEY_F11:
		var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif state in ["menu", "result"] and key == KEY_ENTER:
		start_game()
	elif state == "paused" and key in [KEY_P, KEY_ESCAPE]:
		resume_game()
	elif state == "playing":
		if key in [KEY_P, KEY_ESCAPE]: pause_game()
		elif key == KEY_R: start_game()
		else: game_key(key)
	elif state == "help" and key == KEY_ESCAPE:
		show_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "playing":
		pause_game()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 640), Color("080f20"))
	for x in range(0, 961, 32):
		draw_line(Vector2(x, 86), Vector2(x, 563), Color(0.3, 0.5, 0.6, 0.055))
	for y in range(86, 564, 32):
		draw_line(Vector2(24, y), Vector2(936, y), Color(0.3, 0.5, 0.6, 0.055))
	draw_line(Vector2(32, 83), Vector2(928, 83), Color("2c4152"))
	draw_line(Vector2(32, 565), Vector2(928, 565), Color("2c4152"))
	if state == "menu":
		var at := Vector2(710, 330)
		draw_circle(at, 165, Color("0e1c2c"))
		draw_arc(at, 177, 0, TAU, 80, Color(accent, 0.25), 1.0, true)
		draw_preview(at)
	elif state != "help":
		draw_game()
