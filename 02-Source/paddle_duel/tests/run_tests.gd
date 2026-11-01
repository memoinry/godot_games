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
	check(game.velocity == Vector2.ZERO, "New match waits for a serve")
	game.serve()
	check(game.velocity.x > 0, "Serve launches toward the rival")
	game.ball = Vector2(70, game.player_y)
	game.velocity = Vector2(-400, 0)
	game.advance_ball(0.01)
	check(game.velocity.x > 0 and game.score == 10, "Player paddle returns the ball and scores")
	game.ball = Vector2(890, game.rival_y + 35)
	game.velocity = Vector2(400, 0)
	game.advance_ball(0.01)
	check(game.velocity.x < 0 and absf(game.velocity.y) > 1, "Off-center rival hit changes the angle")
	game.ball = Vector2(500, 108)
	game.velocity = Vector2(100, -400)
	game.advance_ball(0.01)
	check(game.velocity.y > 0, "Top wall reflects the ball")
	game.point(true)
	check(game.player_points == 1 and game.velocity == Vector2.ZERO, "Scoring resets the ball for another serve")
	for i in range(6): game.point(true)
	check(game.state == "result" and game.result_won, "Seven player points win the match")
	game.start_game()
	for i in range(7): game.point(false)
	check(game.state == "result" and not game.result_won, "Seven rival points lose the match")
