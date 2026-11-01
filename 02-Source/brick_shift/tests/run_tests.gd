extends SceneTree
var game: Node2D
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition: print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.automatic_steps = false
	game.sfx.master_volume = 0
	game.save_path = "user://test_record.cfg"
	check(game.state == "menu", "Main menu loads")
	game.show_help()
	check(game.state == "help", "Instructions open")
	game.start_game()
	check(game.state == "playing" and game.score == 0, "Start creates a fresh game")
	game.pause_game()
	var previous: float = game.elapsed
	game.step(1)
	check(game.elapsed == previous and game.state == "paused", "Pause freezes the simulation")
	game.resume_game()
	check(game.state == "playing", "Resume restores play")
	check_gameplay()
	game.start_game()
	game.score = 321
	game.finish(true, "test")
	var cfg := ConfigFile.new()
	check(cfg.load(game.save_path) == OK and int(cfg.get_value("record", "best", 0)) >= 321, "Best score persists to local storage")
	game.start_game()
	check(game.score == 0 and game.elapsed == 0 and game.state == "playing", "Restart resets the round")
	game.show_menu()
	check(game.state == "menu", "Menu return works")
	DirAccess.remove_absolute(game.save_path)
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("RESULT: %d checks / %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func check_gameplay() -> void:
	check(game.attached and game.bricks.size() == 45, "Initial board and attached ball are ready")
	game.launch()
	check(not game.attached and game.velocity.y < 0, "Launch serves upward")
	game.ball = Vector2(game.paddle_x, 514)
	game.velocity = Vector2(0, 450)
	game.advance_ball(0.02)
	check(game.velocity.y < 0, "Paddle returns a descending ball")
	game.ball = Vector2(40, 400)
	game.velocity = Vector2(-400, -10)
	game.advance_ball(0.02)
	check(game.velocity.x > 0, "Side wall reflects the ball")
	var count_before: int = game.bricks.size()
	game.ball = Vector2(92, 108)
	game.velocity = Vector2(0, 400)
	game.advance_ball(0.04)
	check(game.bricks.size() == count_before - 1 and game.score == 10, "Ball destroys a brick and scores")
	game.drops.append({"p": Vector2(game.paddle_x, 520)})
	game.step_game(0)
	check(game.wide_timer > 0 and game.drops.is_empty(), "Catching a boost enables a wider paddle")
	game.start_game()
	for i in range(3):
		game.attached = false
		game.ball = Vector2(480, 558)
		game.velocity = Vector2(0, 500)
		game.advance_ball(0.02)
	check(game.state == "result" and not game.result_won and game.lives == 0, "Three misses reach the loss screen")
	game.start_game()
	for stage in range(1, 4):
		game.bricks.assign([{"rect": Rect2(48, 123, 88, 25), "hp": 1, "color": Color.WHITE}])
		game.attached = false
		game.ball = Vector2(92, 108)
		game.velocity = Vector2(0, 400)
		game.advance_ball(0.04)
		check(game.level == mini(stage + 1, 3), "Cleared board %d advances correctly" % stage)
	check(game.state == "result" and game.result_won, "Clearing all three boards wins")
