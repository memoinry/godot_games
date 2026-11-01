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
	game.game_key(KEY_UP)
	game.game_key(KEY_LEFT)
	game.tick()
	check(game.direction == Vector2i.UP and game.snake[0] == Vector2i(15, 9), "Only one turn is queued per tick")
	game.game_key(KEY_DOWN)
	game.tick()
	check(game.direction == Vector2i.UP, "Immediate reverse is rejected")
	game.food = game.snake[0] + game.direction
	var length_before: int = game.snake.size()
	game.tick()
	check(game.snake.size() == length_before + 1 and game.score == 10, "Food grows the snake and scores")
	check(game.food not in game.snake, "New food avoids occupied cells")
	game.snake.assign([Vector2i(2, 2), Vector2i(2, 3), Vector2i(1, 3), Vector2i(1, 2)])
	game.direction = Vector2i.LEFT
	game.pending_direction = Vector2i.LEFT
	game.food = Vector2i(20, 10)
	game.tick()
	check(game.state == "playing", "Moving into the departing tail is legal")
	game.snake.assign([Vector2i(2, 2), Vector2i(3, 2), Vector2i(3, 3), Vector2i(2, 3), Vector2i(1, 3)])
	game.direction = Vector2i.DOWN
	game.pending_direction = Vector2i.DOWN
	game.tick()
	check(game.state == "result" and not game.result_won, "Body collision ends the run")
	game.start_game()
	game.snake[0] = Vector2i(0, 10)
	game.direction = Vector2i.LEFT
	game.pending_direction = Vector2i.LEFT
	game.tick()
	check(game.state == "result" and not game.result_won, "Wall collision ends the run")
	game.start_game()
	game.snake.clear()
	for y in range(game.ROWS):
		for x in range(game.COLUMNS): game.snake.append(Vector2i(x, y))
	game.place_food()
	check(game.state == "result" and game.result_won, "Filling the entire board wins")
