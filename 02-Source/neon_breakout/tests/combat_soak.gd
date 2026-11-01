extends SceneTree
## Natural campaign simulation with an immortal aim bot. The director and combat
## run normally: no forced wave clears or enemy deletion. Not a difficulty test.
var app: Node
var cleared: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.data.save_path = "user://soak_test.cfg"
	app.sound.master_volume = 0.0
	app.sound.music_enabled = false
	for voice in app.sound.voices:
		voice.stop()
	app.start_game()
	var arena: Node2D = app.arena
	arena.test_mode = true
	arena.test_invincible = true
	arena.rng.seed = 77102
	arena.player.automated = true
	arena.player.weapon = 2
	var shots_peak := 0
	var enemies_peak := 0
	for tick in range(42000):
		if app.state == "results":
			break
		if app.state == "upgrade":
			cleared += 1
			var selection := 0
			for i in range(app.offer.size()):
				if app.offer[i].id in ["damage", "rate"]:
					selection = i
					break
			app.choose_upgrade(selection)
			print("Natural clear: wave %d / t=%.1f / score=%d" % [cleared, arena.elapsed, arena.score])
		var nearest: Node2D = null
		var distance := INF
		for enemy in arena.enemies:
			var d: float = enemy.position.distance_squared_to(arena.player.position)
			if d < distance:
				distance = d
				nearest = enemy
		if nearest != null:
			arena.player.bot_aim = nearest.position - arena.player.position
		var destination := Vector2(640, 416) + Vector2(cos(arena.elapsed * 0.28) * 350, sin(arena.elapsed * 0.28) * 200)
		arena.player.bot_move = (destination - arena.player.position).normalized()
		arena.step(1.0 / 60.0)
		shots_peak = maxi(shots_peak, arena.bullets.size())
		enemies_peak = maxi(enemies_peak, arena.enemies.size())
		if tick % 120 == 0:
			await process_frame
	var success: bool = app.state == "results" and app.last_won and cleared == 6
	print("SOAK: won=%s / waves=%d / simulated=%.1fs / kills=%d / peak_bullets=%d / peak_enemies=%d" % [success, cleared, arena.elapsed, arena.kills, shots_peak, enemies_peak])
	DirAccess.remove_absolute(app.data.save_path)
	app.queue_free()
	await process_frame
	quit(0 if success else 1)
