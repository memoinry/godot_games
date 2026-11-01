extends SceneTree
## Deterministic integration checks. Run with --headless --script res://tests/run_tests.gd.
var failures: Array[String] = []
var checks: int = 0
var app: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func run() -> void:
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.data.save_path = "user://campaign_test.cfg"
	app.sound.master_volume = 0
	app.sound.music_enabled = false
	await process_frame
	app.arena.test_mode = true
	check(app.state == "menu", "Main menu loads")
	app.show_howto()
	check(app.state == "howto", "Instructions open")
	app.show_settings("menu")
	app.close_settings()
	check(app.state == "menu", "Settings return to menu")
	app.show_credits()
	check(app.state == "credits", "Credits open")
	app.start_game()
	var arena: Node2D = app.arena
	var pilot: Node2D = arena.player
	pilot.automated = true
	pilot.bot_move = Vector2.RIGHT
	pilot.bot_aim = Vector2.RIGHT
	check(arena.wave == 1 and arena.running, "New campaign starts at wave one")
	var x: float = pilot.position.x
	arena.step(0.1)
	check(pilot.position.x > x, "Player movement works")
	pilot.dash()
	check(pilot.dash_timer > 0.0 and pilot.invulnerable > 0.0, "Dash grants invulnerability and cooldown")
	var hp_before: float = pilot.hp
	pilot.hurt(20)
	check(pilot.hp == hp_before, "Invulnerability blocks damage")
	pilot.invulnerable = 0
	pilot.hurt(20)
	check(pilot.hp == hp_before - 20, "Normal damage reduces armor")
	app.pause_game()
	var elapsed_before: float = arena.elapsed
	arena.step(1.0)
	check(app.state == "paused" and arena.elapsed == elapsed_before, "Pause freezes simulation")
	app.show_settings("paused")
	app.close_settings()
	check(app.state == "paused", "Settings preserve pause state")
	app.resume_game()
	check(arena.running and app.state == "playing", "Resume restores campaign")
	# Swept collision must catch a fast projectile crossing an enemy in one step.
	arena.clear_entities()
	pilot.position = Vector2(300, 400)
	var target: Node2D = arena.spawn_enemy(0, Vector2(500, 400))
	arena.add_bullet(Vector2(400, 400), Vector2(1200, 0), 100, false, 0, Color.WHITE)
	arena.step_bullets(0.2)
	check(target.dead, "Swept bullet collision prevents tunneling")
	for weapon_id in range(3):
		arena.bullets.clear()
		pilot.weapon = weapon_id
		pilot.shoot()
		check(arena.bullets.size() == (5 if weapon_id == 1 else 1), "Weapon %d emits expected projectiles" % (weapon_id + 1))
	arena.clear_entities()
	var a: Node2D = arena.spawn_enemy(0, Vector2(500, 400))
	var b: Node2D = arena.spawn_enemy(0, Vector2(600, 400))
	arena.add_bullet(Vector2(400, 400), Vector2(1200, 0), 100, false, 4, Color.WHITE)
	arena.step_bullets(0.2)
	check(a.dead and b.dead, "Rail projectile pierces multiple enemies")
	arena.clear_entities()
	pilot.hp = 40
	arena.collect({"kind": 0})
	check(pilot.hp == 58, "Repair pickup restores armor")
	arena.add_bullet(Vector2(500, 300), Vector2.ZERO, 12, true, 0, Color.WHITE)
	arena.collect({"kind": 1})
	check(arena.bullets.is_empty(), "Pulse pickup clears hostile projectiles")
	# Complete all six waves using the normal director and upgrade transitions.
	for wave_index in range(1, 7):
		arena.clear_entities()
		arena.remaining = 0.01
		arena.spawn_timer = 100
		arena.step(0.02)
		check(app.state == "upgrade" and not arena.running, "Wave %d opens upgrade selection" % wave_index)
		var ids: Array[String] = []
		for choice in app.offer:
			ids.append(choice.id)
		check(ids.size() == 3 and ids[0] != ids[1] and ids[0] != ids[2] and ids[1] != ids[2], "Upgrade offers are distinct")
		app.choose_upgrade(0)
		check(app.state == "playing" and arena.wave == wave_index + 1, "Upgrade advances to next sector")
	check(is_instance_valid(arena.boss) and arena.boss.kind == 4, "Final sector spawns boss")
	var boss: Node2D = arena.boss
	arena.bullets.clear()
	boss.timer = 0
	boss.step(0.02)
	check(arena.bullets.size() >= 13, "Boss phase one emits radial pattern")
	boss.hp = boss.max_hp * 0.6
	boss.step(0.02)
	check(boss.phase == 2, "Boss enters phase two")
	boss.hp = boss.max_hp * 0.2
	boss.step(0.02)
	check(boss.phase == 3, "Boss enters phase three")
	boss.hurt(99999)
	check(app.state == "results" and app.last_won, "Boss defeat reaches victory results")
	check(arena.ended and not arena.running, "Victory stops combat")
	app.start_game()
	pilot = arena.player
	pilot.invulnerable = 0
	pilot.hurt(1000)
	check(app.state == "results" and not app.last_won, "Lethal damage reaches failure results")
	# Verify the real serializer in an isolated test save; do not contaminate pilot records.
	var Save = load("res://scripts/save_data.gd")
	var save = Save.new()
	save.save_path = "user://integration_test.cfg"
	save.best_score = 12345
	save.wins = 2
	save.runs = 4
	save.volume = 0.37
	check(save.save() == OK, "Save writes successfully")
	var restored = Save.new()
	restored.save_path = save.save_path
	restored.load_data()
	check(restored.best_score == 12345 and restored.wins == 2 and is_equal_approx(restored.volume, 0.37), "Save reload preserves records and settings")
	DirAccess.remove_absolute(save.save_path)
	DirAccess.remove_absolute(app.data.save_path)
	print("INTEGRATION: %d checks, %d failures" % [checks, failures.size()])
	# Deferred deletion is flushed before exiting to avoid spurious orphan warnings.
	app.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	quit(0 if failures.is_empty() else 1)
