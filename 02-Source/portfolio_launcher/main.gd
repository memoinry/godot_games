extends Control
const BG = Color("101e30")
const LIME = Color("ccff70")
var games = [{"en": "NEON BREAKOUT", "exe": "NeonBreakout", "img": "neon-combat.png"}, {"en": "GRID SNAKE", "exe": "GridSnake", "img": "grid-snake.png"}, {"en": "BRICK SHIFT", "exe": "BrickShift", "img": "brick-shift.png"}, {"en": "PADDLE DUEL", "exe": "PaddleDuel", "img": "paddle-duel.png"}]

func text(value: String, at: Vector2, width: float, size_value: int, ink: Color = Color("eef2e6")) -> Label:
 var item = Label.new()
 item.text = value
 item.position = at
 item.size.x = width
 item.add_theme_font_size_override("font_size", size_value)
 item.add_theme_color_override("font_color", ink)
 add_child(item)
 return item

func action(value: String, at: Vector2, width: float, callback: Callable) -> void:
 var item = Button.new()
 item.text = value
 item.position = at
 item.size = Vector2(width, 44)
 item.add_theme_font_size_override("font_size", 16)
 item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 var style = StyleBoxFlat.new()
 style.bg_color = LIME
 style.set_corner_radius_all(6)
 item.add_theme_stylebox_override("normal", style)
 item.add_theme_color_override("font_color", Color("101824"))
 item.pressed.connect(callback)
 add_child(item)

func _ready() -> void:
 text("memory / GAME PORTFOLIO", Vector2(40, 24), 1000, 30)
 text("04 GAMES   /   GODOT 4   /   PLAYABLE COLLECTION", Vector2(42, 74), 1000, 15, Color("8fa1b6"))
 for i in range(games.size()):
  var g = games[i]
  var at = Vector2(40 + (i % 2) * 532, 123 + (i / 2) * 265)
  var panel = Panel.new()
  panel.position = at
  panel.size = Vector2(508, 245)
  var style = StyleBoxFlat.new()
  style.bg_color = BG
  style.set_corner_radius_all(10)
  panel.add_theme_stylebox_override("panel", style)
  add_child(panel)
  var preview = TextureRect.new()
  preview.position = at + Vector2(16,16)
  preview.size = Vector2(476,133)
  preview.texture = load("res://images/" + g.img)
  preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
  preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
  add_child(preview)
  text(g.en, at + Vector2(18,157), 340, 23)
  text("BY memory", at + Vector2(18,199), 200, 13, Color("8fa1b6"))
  action("PLAY  >", at + Vector2(365,180), 125, func(): launch(g.exe))
 action("VIEW PORTFOLIO", Vector2(40,683), 260, func(): open_file("00-Portfolio.html"))
 action("PROJECT SOURCES", Vector2(320,683), 260, func(): open_file("02-Source"))
 text("Author: memory  /  Offline / Windows x64", Vector2(620,698), 470, 14, Color("8fa1b6"))

func root_path() -> String:
 return OS.get_executable_path().get_base_dir().get_base_dir()

func open_file(relative: String) -> void:
 OS.shell_open(root_path().path_join(relative))

func launch(game: String) -> void:
 var executable = OS.get_executable_path()
 var args = PackedStringArray()
 if game != "NeonBreakout":
  args.append("--main-pack")
  args.append(executable.get_base_dir().path_join(game + ".pck"))
 var result = OS.create_process(executable, args)
 if result == -1:
  text("Could not start game. Keep all files in the same folder.", Vector2(40,654), 1000, 16, Color("ff6b8e"))
