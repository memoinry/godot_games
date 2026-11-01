extends Node
## Application state and interface. Arena never depends on UI controls.
## States: menu, howto, settings, credits, playing, paused, upgrade, results.

const ArenaScript = preload("res://scripts/arena.gd")
const SoundScript = preload("res://scripts/sound_bank.gd")
const SaveScript = preload("res://scripts/save_data.gd")
const ArtScript = preload("res://scripts/menu_art.gd")
const FONT = preload("res://assets/interface_font.tres")
const HEADING_FONT = preload("res://assets/heading_font.tres")
const WHITE := Color("eef2e6")
const MUTED := Color("8496a8")
const CYAN := Color("6ee7f2")
const LIME := Color("ccff70")
const PINK := Color("ff6b8e")
const INK := Color("080f20")

var arena: Node2D
var sound: Node
var data := SaveScript.new()
var canvas: CanvasLayer
var ui: Control
var art: Node2D
var state: String = "menu"
var hud: Dictionary = {}
var offer: Array[Dictionary] = []
var banner_title: String = ""
var banner_subtitle: String = ""
var banner_timer: float = 0.0
var settings_return: String = "menu"
var last_won: bool = false
var session_best: int = 0

func _ready() -> void:
	data.load_data()
	session_best = data.best_score
	sound = SoundScript.new()
	add_child(sound)
	sound.master_volume = data.volume
	arena = ArenaScript.new()
	arena.sfx = sound
	arena.shake_enabled = data.shake
	add_child(arena)
	arena.wave_cleared.connect(show_upgrade)
	arena.run_finished.connect(on_run_finished)
	arena.announcement.connect(on_announcement)
	art = ArtScript.new()
	add_child(art)
	canvas = CanvasLayer.new()
	add_child(canvas)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	apply_window()
	show_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "playing":
		pause_game()

func clear_ui() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	hud.clear()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func box_style(fill: Color, border: Color, radius: int = 8, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func panel(at: Vector2, size_value: Vector2, fill: Color = Color("101c2e"), edge: Color = Color("2a3c50"), parent: Node = null) -> Panel:
	var node := Panel.new()
	node.position = at
	node.size = size_value
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_stylebox_override("panel", box_style(fill, edge))
	(parent if parent != null else ui).add_child(node)
	return node

func label(text_value: String, at: Vector2, width: float, font_size: int = 18, color: Color = WHITE, parent: Node = null) -> Label:
	var node := Label.new()
	node.text = text_value
	node.position = at
	node.size = Vector2(width, 0)
	node.add_theme_font_override("font", HEADING_FONT if font_size >= 24 else FONT)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else ui).add_child(node)
	return node

func paragraph(text_value: String, at: Vector2, width: float, font_size: int = 18, color: Color = MUTED, parent: Node = null) -> Label:
	var node := label(text_value, at, width, font_size, color, parent)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node

func button(text_value: String, at: Vector2, size_value: Vector2, action: Callable, primary: bool = false, parent: Node = null) -> Button:
	var node := Button.new()
	node.text = text_value
	node.position = at
	node.size = size_value
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_override("font", FONT)
	node.add_theme_font_size_override("font_size", 18)
	node.add_theme_color_override("font_color", INK if primary else WHITE)
	node.add_theme_color_override("font_hover_color", INK if primary else LIME)
	node.add_theme_color_override("font_pressed_color", INK)
	node.add_theme_color_override("font_focus_color", INK if primary else WHITE)
	node.add_theme_stylebox_override("normal", box_style(LIME if primary else Color("142235"), LIME if primary else Color("304457")))
	node.add_theme_stylebox_override("hover", box_style(Color("e0ffab") if primary else Color("20384a"), LIME))
	node.add_theme_stylebox_override("pressed", box_style(CYAN, CYAN))
	node.add_theme_stylebox_override("focus", box_style(Color(0, 0, 0, 0), CYAN, 8, 2))
	(parent if parent != null else ui).add_child(node)
	node.pressed.connect(func() -> void:
		sound.play("click")
		action.call()
	)
	return node

func top_line(right_text: String) -> void:
	label("N / B", Vector2(54, 28), 100, 24, LIME)
	label("INDEPENDENT FLIGHT SYSTEMS", Vector2(152, 36), 500, 13, MUTED)
	var right := label(right_text, Vector2(900, 36), 326, 13, CYAN)
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel(Vector2(54, 77), Vector2(1172, 1), Color("28384b"), Color("28384b"))

func show_menu() -> void:
	state = "menu"
	arena.running = false
	arena.player.visible = false
	arena.clear_entities()
	arena.queue_redraw()
	art.visible = true
	clear_ui()
	top_line("OFFLINE / SINGLE PLAYER")
	label("01  /  逃离封锁区", Vector2(64, 132), 500, 16, CYAN)
	label("NEON", Vector2(58, 164), 620, 88, WHITE)
	label("BREAKOUT", Vector2(58, 264), 660, 80, LIME)
	label("霓 虹 突 围", Vector2(65, 383), 550, 26, WHITE)
	paragraph("在无人机的包围中保持移动。\n升级武器，击破母核，夺回你的航线。", Vector2(66, 443), 520, 19)
	var start := button("开始突围     →", Vector2(66, 541), Vector2(338, 60), start_game, true)
	start.grab_focus()
	button("操作指南", Vector2(66, 618), Vector2(156, 46), show_howto)
	button("设置", Vector2(238, 618), Vector2(105, 46), func() -> void: show_settings("menu"))
	button("制作信息", Vector2(359, 618), Vector2(145, 46), show_credits)
	label("VESSEL 01", Vector2(748, 126), 400, 16, CYAN)
	label("相位截击机 / PHASE INTERCEPTOR", Vector2(748, 151), 450, 13, MUTED)
	label("PULSE  /  SCATTER  /  RAIL", Vector2(773, 682), 450, 14, CYAN)
	panel(Vector2(54, 726), Vector2(1172, 1), Color("28384b"), Color("28384b"))
	label("最高记录  %06d" % data.best_score, Vector2(66, 746), 300, 16, WHITE)
	label("突围成功  %02d  /  出击  %02d" % [data.wins, data.runs], Vector2(440, 746), 400, 16, MUTED)
	label("memory   ·   v1.0   ·   GODOT 4", Vector2(992, 750), 260, 13, MUTED)

func show_howto() -> void:
	state = "howto"
	clear_ui()
	art.visible = false
	top_line("PILOT BRIEFING / 操作指南")
	label("先活下来，再漂亮地突围。", Vector2(90, 117), 1100, 36)
	paragraph("撑过 6 波封锁，每波结束选择一项强化；第 7 区击破母核即通关。", Vector2(92, 181), 1080, 20)
	var entries := [
		["W A S D / 方向键", "移动", "保持绕行，避免在角落停留。"],
		["鼠标 + 左键", "瞄准 / 射击", "按住左键持续开火，无需装填。"],
		["SPACE / 空格", "相位冲刺", "朝移动方向冲刺，短暂无敌；静止时朝准星冲刺。"],
		["1 / 2 / 3", "切换武器", "脉冲均衡，霰射近战，磁轨可穿透多个敌人。"],
		["ESC / P", "暂停", "可调节声音、屏幕震动并返回主菜单。"],
		["维修包 / 脉冲环", "收集补给", "绿色十字修复护甲，青色圆环伤害敌人并清除敌弹。"]
	]
	for i in range(entries.size()):
		var y := 254.0 + i * 66
		panel(Vector2(90, y), Vector2(1100, 56), Color("101c2e"), Color("233447"))
		label(entries[i][0], Vector2(110, y + 13), 255, 17, LIME)
		label(entries[i][1], Vector2(367, y + 13), 170, 18)
		label(entries[i][2], Vector2(532, y + 15), 655, 16, MUTED)
	button("返回", Vector2(90, 704), Vector2(160, 50), show_menu)
	button("准备好了，出击 →", Vector2(875, 704), Vector2(315, 50), start_game, true)

func start_game() -> void:
	state = "playing"
	art.visible = false
	clear_ui()
	arena.start()
	build_hud()

func build_hud() -> void:
	clear_ui()
	panel(Vector2(0, 0), Vector2(1280, 87), Color("0b1425"), Color("23384a"))
	label("N / B", Vector2(29, 17), 100, 24, LIME)
	label("霓虹突围", Vector2(29, 53), 130, 12, MUTED)
	label("HULL / 护甲", Vector2(158, 17), 180, 12, MUTED)
	hud.hp_text = label("100 / 100", Vector2(158, 39), 210, 19)
	hud.hp_back = panel(Vector2(158, 69), Vector2(220, 4), Color("293444"), Color("293444"))
	hud.hp_fill = panel(Vector2(158, 69), Vector2(220, 4), LIME, LIME)
	label("SECTOR", Vector2(426, 17), 160, 12, MUTED)
	hud.wave = label("01 / 07", Vector2(426, 38), 190, 23, WHITE)
	label("SCORE", Vector2(625, 17), 180, 12, MUTED)
	hud.score = label("000000", Vector2(625, 38), 260, 23, LIME)
	label("ELAPSED", Vector2(872, 17), 150, 12, MUTED)
	hud.time = label("00:00", Vector2(872, 38), 150, 23)
	button("暂停  II", Vector2(1090, 20), Vector2(155, 48), pause_game)
	panel(Vector2(0, 741), Vector2(1280, 59), Color("0b1425"), Color("23384a"))
	for i in range(3):
		var text_value: String = ["1  脉冲", "2  霰射", "3  磁轨"][i]
		var weapon_button := button(text_value, Vector2(28 + i * 140, 750), Vector2(128, 40), func() -> void: arena.player.weapon = i)
		weapon_button.add_theme_font_size_override("font_size", 15)
		hud["weapon%d" % i] = weapon_button
		weapon_button.focus_mode = Control.FOCUS_NONE
	for control in ui.get_children():
		if control is Button:
			control.focus_mode = Control.FOCUS_NONE
	hud.dash = label("SPACE  /  冲刺就绪", Vector2(493, 760), 270, 15, CYAN)
	hud.progress = label("清理封锁区", Vector2(790, 760), 340, 15, MUTED)
	hud.combo = label("", Vector2(1040, 760), 210, 15, LIME)
	var banner := panel(Vector2(350, 111), Vector2(580, 90), Color(0.04, 0.08, 0.14, 0.93), Color("34505a"))
	hud.banner = banner
	hud.banner_title = label(banner_title, Vector2(20, 12), 540, 23, LIME, banner)
	hud.banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.banner_subtitle = label(banner_subtitle, Vector2(16, 54), 548, 14, WHITE, banner)
	hud.banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.boss_back = panel(Vector2(390, 211), Vector2(500, 6), Color("43323c"), Color("43323c"))
	hud.boss_fill = panel(Vector2(390, 211), Vector2(500, 6), PINK, PINK)
	hud.boss_name = label("母核 / THE WARDEN", Vector2(490, 223), 300, 13, PINK)
	hud.boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _process(delta: float) -> void:
	if state != "playing":
		return
	banner_timer = maxf(0.0, banner_timer - delta)
	if hud.is_empty():
		return
	var pilot: Node2D = arena.player
	hud.hp_text.text = "%d / %d" % [ceili(pilot.hp), int(pilot.max_hp)]
	hud.hp_fill.size.x = maxf(1.0, 220.0 * pilot.hp / pilot.max_hp)
	hud.hp_fill.modulate = PINK if pilot.hp < pilot.max_hp * 0.3 else Color.WHITE
	hud.wave.text = "%02d / 07" % arena.wave
	hud.score.text = "%06d" % arena.score
	hud.time.text = format_time(arena.elapsed)
	hud.dash.text = "SPACE  /  冲刺就绪" if pilot.dash_timer <= 0.0 else "SPACE  /  %.1fs 充能" % pilot.dash_timer
	hud.dash.modulate = Color.WHITE if pilot.dash_timer <= 0.0 else Color("728196")
	hud.progress.text = "击破母核完成突围" if arena.wave > 6 else ("清理剩余敌人：%d" % arena.enemies.size() if arena.remaining <= 0.0 else "下一次补给  %02ds" % ceili(arena.remaining))
	hud.combo.text = "CHAIN %02d  ×%d" % [arena.combo, 1 + mini(arena.combo / 8, 4)] if arena.combo >= 3 else ""
	for i in range(3):
		hud["weapon%d" % i].modulate = LIME if i == pilot.weapon else Color("8793a2")
	hud.banner.visible = banner_timer > 0.0
	hud.banner_title.text = banner_title
	hud.banner_subtitle.text = banner_subtitle
	var has_boss: bool = is_instance_valid(arena.boss) and not arena.boss.dead
	hud.boss_back.visible = has_boss
	hud.boss_fill.visible = has_boss
	hud.boss_name.visible = has_boss
	if has_boss:
		hud.boss_fill.size.x = maxf(1, 500.0 * arena.boss.hp / arena.boss.max_hp)

func on_announcement(title: String, subtitle: String, duration: float) -> void:
	banner_title = title
	banner_subtitle = subtitle
	banner_timer = duration

func shade() -> void:
	var cover := ColorRect.new()
	cover.color = Color(0.015, 0.025, 0.05, 0.88)
	cover.size = Vector2(1280, 800)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(cover)

func pause_game() -> void:
	if state != "playing":
		return
	state = "paused"
	arena.running = false
	arena.position = Vector2.ZERO
	clear_ui()
	shade()
	panel(Vector2(390, 153), Vector2(500, 480))
	label("FLIGHT SUSPENDED", Vector2(430, 192), 450, 14, CYAN)
	label("稍作停靠", Vector2(430, 227), 420, 40)
	label("第 %d 区  /  本局分数 %06d" % [arena.wave, arena.score], Vector2(430, 302), 420, 17, MUTED)
	button("继续突围  →", Vector2(430, 357), Vector2(420, 55), resume_game, true).grab_focus()
	button("声音与画面", Vector2(430, 428), Vector2(420, 50), func() -> void: show_settings("paused"))
	button("结束本局并返回菜单", Vector2(430, 494), Vector2(420, 50), abandon_run)
	label("ESC / P 继续 · 切出窗口时自动暂停", Vector2(430, 574), 430, 14, MUTED)

func abandon_run() -> void:
	data.record(arena.score, false)
	show_menu()

func resume_game() -> void:
	state = "playing"
	arena.running = true
	build_hud()

func show_upgrade() -> void:
	state = "upgrade"
	clear_ui()
	shade()
	offer = arena.choices()
	label("SECTOR %02d / CLEARED" % arena.wave, Vector2(94, 110), 1100, 17, CYAN)
	label("航线已清空。选择下一项强化。", Vector2(90, 151), 1150, 36)
	label("波次奖励：护甲恢复 10 · 所有武器共享强化 · 选择后继续", Vector2(94, 221), 1100, 18, MUTED)
	for i in range(offer.size()):
		var item: Dictionary = offer[i]
		var x := 92.0 + i * 374
		var ink := Color(item.color)
		panel(Vector2(x, 295), Vector2(348, 320), Color("111e30"), Color("35465a"))
		label("0%d  /  %s" % [i + 1, item.mark], Vector2(x + 25, 318), 300, 16, ink)
		label(item.title, Vector2(x + 25, 367), 300, 28)
		paragraph(item.text, Vector2(x + 25, 427), 298, 19, ink)
		paragraph(item.note, Vector2(x + 25, 475), 298, 15, MUTED)
		button("选择强化   [%d]" % (i + 1), Vector2(x + 24, 543), Vector2(300, 48), func() -> void: choose_upgrade(i), i == 0)
	label("当前护甲  %d / %d" % [int(arena.player.hp), int(arena.player.max_hp)], Vector2(94, 666), 600, 18, LIME)
	label("强化会持续到本局结束", Vector2(910, 669), 300, 15, MUTED)

func choose_upgrade(index: int) -> void:
	if state != "upgrade" or index < 0 or index >= offer.size():
		return
	state = "playing"
	arena.apply_upgrade(offer[index].id)
	build_hud()

func on_run_finished(won: bool) -> void:
	last_won = won
	data.record(arena.score, won)
	state = "results"
	clear_ui()
	shade()
	sound.play("upgrade" if won else "boom")
	var ink := LIME if won else PINK
	label("MISSION COMPLETE" if won else "SIGNAL LOST", Vector2(130, 100), 1100, 17, ink)
	label("突围成功。航线属于你。" if won else "本次航行结束。再试一次。", Vector2(126, 140), 1100, 43)
	paragraph("母核已被击破，封锁解除。" if won else "保持移动，利用冲刺穿过弹幕；近距离尝试霰射，远距离使用磁轨。", Vector2(132, 221), 1000, 19)
	var values: Array[String] = ["%06d" % arena.score, "%03d" % arena.kills, format_time(arena.elapsed), "%02d / 07" % arena.wave]
	var names: Array[String] = ["本局分数 / SCORE", "击破数量 / DESTROYED", "航行时间 / TIME", "到达区域 / SECTOR"]
	for i in range(4):
		var x := 130 + i * 260
		panel(Vector2(x, 313), Vector2(240, 155))
		label(names[i], Vector2(x + 22, 338), 215, 13, MUTED)
		label(values[i], Vector2(x + 20, 386), 220, 34, ink)
	label("NEW PERSONAL BEST" if arena.score > session_best else "PERSONAL BEST  /  %06d" % data.best_score, Vector2(132, 506), 900, 18, CYAN)
	session_best = data.best_score
	label("记录已保存在本机", Vector2(132, 548), 600, 15, MUTED)
	button("再次出击  →", Vector2(132, 635), Vector2(360, 60), start_game, true).grab_focus()
	button("返回主菜单", Vector2(516, 635), Vector2(240, 60), show_menu)
	label("每次突破，都是下一次的起点。", Vector2(132, 739), 1000, 15, MUTED)

func show_settings(return_to: String = "menu") -> void:
	settings_return = return_to
	state = "settings"
	art.visible = false
	clear_ui()
	shade()
	panel(Vector2(300, 120), Vector2(680, 560))
	label("SYSTEM CONFIGURATION", Vector2(344, 157), 600, 15, CYAN)
	label("声音与画面", Vector2(340, 193), 600, 36)
	label("总音量", Vector2(344, 279), 300, 19)
	var volume_label := label("%d%%" % roundi(data.volume * 100), Vector2(848, 279), 100, 18, LIME)
	var slider := HSlider.new()
	slider.position = Vector2(344, 329)
	slider.size = Vector2(590, 30)
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = data.volume * 100
	ui.add_child(slider)
	slider.value_changed.connect(func(value: float) -> void:
		data.volume = value / 100.0
		sound.master_volume = data.volume
		volume_label.text = "%d%%" % roundi(value)
	)
	var shake_button := button("屏幕震动：开" if data.shake else "屏幕震动：关", Vector2(344, 397), Vector2(280, 52), func() -> void: pass)
	shake_button.pressed.connect(func() -> void:
		data.shake = not data.shake
		arena.shake_enabled = data.shake
		shake_button.text = "屏幕震动：开" if data.shake else "屏幕震动：关"
	)
	var full_button := button("全屏：开" if data.fullscreen else "全屏：关", Vector2(650, 397), Vector2(280, 52), func() -> void: pass)
	full_button.pressed.connect(func() -> void:
		data.fullscreen = not data.fullscreen
		apply_window()
		full_button.text = "全屏：开" if data.fullscreen else "全屏：关"
	)
	paragraph("F11 切换全屏 · M 静音 / 恢复声音\n设置和最高分会自动保存在本机。", Vector2(344, 486), 600, 16)
	button("保存并返回", Vector2(344, 584), Vector2(590, 52), close_settings, true)

func close_settings() -> void:
	data.save()
	if settings_return == "paused":
		state = "playing"
		pause_game()
	else:
		show_menu()

func apply_window() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if data.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func show_credits() -> void:
	state = "credits"
	art.visible = false
	clear_ui()
	top_line("CREDITS / 制作信息")
	label("一个完整的、小而锋利的游戏。", Vector2(90, 128), 1100, 36)
	paragraph("霓虹突围 / NEON BREAKOUT\n作者：memory  ·  单人俯视角射击  ·  Godot 4", Vector2(94, 212), 1100, 23, LIME)
	paragraph("玩法参考：Radius Raid — Jack Rugile\n本项目重新编写 Godot 游戏逻辑，独立绘制几何画面并合成音效；没有嵌入原版 JavaScript。\n新增波次强化、三种武器、相位冲刺及三阶段母核战。", Vector2(94, 324), 1080, 19, WHITE)
	paragraph("字体：Noto Sans SC（SIL Open Font License 1.1）\n引擎：Godot Engine（MIT）\n来源与许可详见 THIRD_PARTY.md；工程说明详见 README.md。", Vector2(94, 484), 1080, 18, MUTED)
	button("返回主菜单", Vector2(94, 674), Vector2(300, 55), show_menu, true)

func format_time(seconds: float) -> String:
	var whole := int(seconds)
	return "%02d:%02d" % [whole / 60, whole % 60]

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_F11:
		data.fullscreen = not data.fullscreen
		apply_window()
		data.save()
		return
	if event.physical_keycode == KEY_M:
		sound.master_volume = 0.0 if sound.master_volume > 0.0 else data.volume
		return
	if state == "playing":
		if event.physical_keycode in [KEY_ESCAPE, KEY_P]:
			pause_game()
		elif event.physical_keycode == KEY_SPACE:
			arena.player.dash()
	elif state == "paused" and event.physical_keycode in [KEY_ESCAPE, KEY_P]:
		resume_game()
	elif state == "upgrade":
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_3:
			choose_upgrade(event.physical_keycode - KEY_1)
	elif event.physical_keycode == KEY_ESCAPE:
		if state == "settings":
			close_settings()
		elif state in ["credits", "howto"]:
			show_menu()
