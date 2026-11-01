extends SceneTree
## Developer-only screenshots of real rendered game states. Excluded from export.
var app: Node
var output: String

func _initialize() -> void:
	call_deferred("run")

func capture(name_value: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var result := image.save_png(output.path_join(name_value + ".png"))
	print("CAPTURE %s: %s" % [name_value, result])

func run() -> void:
	output = ProjectSettings.globalize_path("res://../NeonBreakout-Previews")
	DirAccess.make_dir_recursive_absolute(output)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.data.save_path = "user://capture_test.cfg"
	app.sound.master_volume = 0.0
	app.sound.music_enabled = false
	app.arena.test_mode = true
	app.art.clock = 14
	await capture("01-menu")
	app.show_howto()
	await capture("02-guide")
	app.show_settings("menu")
	await capture("03-settings")
	app.start_game()
	var arena: Node2D = app.arena
	arena.rng.seed = 963
	arena.wave = 4
	arena.remaining = 22
	arena.elapsed = 136
	arena.score = 18240
	arena.kills = 93
	arena.test_invincible = true
	arena.player.automated = true
	arena.player.weapon = 1
	arena.player.position = Vector2(640, 460)
	arena.player.bot_move = Vector2(0.2, -0.1)
	arena.player.bot_aim = Vector2(1, -0.2)
	for i in range(18):
		var angle := TAU * i / 18.0
		arena.spawn_enemy(i % 4, Vector2(640, 416) + Vector2(cos(angle) * 400, sin(angle) * 220))
	for i in range(80):
		arena.step(1.0 / 60.0)
	app.banner_timer = 0
	arena.player.invulnerable = 0
	arena.player.queue_redraw()
	await capture("04-combat")
	app.pause_game()
	await capture("05-paused")
	app.show_upgrade()
	await capture("06-upgrades")
	app.resume_game()
	arena.clear_entities()
	arena.wave = 6
	arena.begin_wave()
	arena.player.position = Vector2(460, 540)
	arena.player.bot_move = Vector2(0.1, 0)
	arena.player.bot_aim = Vector2(1, -0.8)
	arena.boss.position = Vector2(740, 325)
	arena.boss.hp = 1200
	for i in range(100):
		arena.step(1.0 / 60.0)
	app.banner_timer = 0
	await capture("07-boss")
	arena.boss.hurt(99999)
	await capture("08-victory")
	app.start_game()
	arena.player.invulnerable = 0
	arena.player.hurt(1000)
	await capture("09-failure")
	app.show_credits()
	await capture("10-credits")
	DirAccess.remove_absolute(app.data.save_path)
	app.queue_free()
	await process_frame
	quit()
