extends SceneTree
## A short montage recorded from the live renderer with Godot Movie Maker.
## Stage changes are scripted; shooting and enemy attacks use the real simulation.
var app: Node

func _initialize() -> void:
	call_deferred("record")

func frames(count: int, combat: bool = false) -> void:
	for i in range(count):
		if combat:
			var arena: Node2D = app.arena
			var nearest: Node2D = null
			var nearest_distance := INF
			for enemy in arena.enemies:
				var distance: float = enemy.position.distance_squared_to(arena.player.position)
				if distance < nearest_distance:
					nearest_distance = distance
					nearest = enemy
			if nearest != null:
				arena.player.bot_aim = nearest.position - arena.player.position
			var destination := Vector2(640, 416) + Vector2(cos(arena.elapsed * 0.45) * 280, sin(arena.elapsed * 0.45) * 150)
			arena.player.bot_move = (destination - arena.player.position).normalized()
			arena.step(1.0 / 30.0)
			arena.player.invulnerable = 0
			arena.player.queue_redraw()
		await process_frame

func record() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.data.save_path = "user://recording_test.cfg"
	app.arena.test_mode = true
	app.arena.test_invincible = true
	await frames(60)
	app.start_game()
	var arena: Node2D = app.arena
	arena.rng.seed = 4219
	arena.wave = 4
	arena.elapsed = 145
	arena.remaining = 38
	arena.player.automated = true
	arena.player.weapon = 0
	for i in range(20):
		arena.spawn_enemy(i % 4, arena.edge_spawn())
	app.banner_timer = 0
	await frames(120, true)
	arena.player.weapon = 1
	arena.player.dash()
	await frames(120, true)
	arena.player.weapon = 2
	await frames(90, true)
	arena.running = false
	app.show_upgrade()
	await frames(90)
	app.choose_upgrade(0)
	arena.clear_entities()
	arena.wave = 6
	arena.begin_wave()
	arena.player.damage_scale = 1.8
	arena.boss.hp = 2400
	arena.player.weapon = 0
	app.banner_timer = 2
	await frames(240, true)
	if is_instance_valid(arena.boss) and not arena.boss.dead:
		arena.boss.hurt(99999)
	await frames(90)
	DirAccess.remove_absolute(app.data.save_path)
	app.queue_free()
	await process_frame
	quit()
