extends SceneTree
var game: Node2D
func _initialize() -> void:
 call_deferred("run")
func shot(name_value: String) -> void:
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../../docs/images/" + name_value + ".png"))
func run() -> void:
 game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.automatic_steps = false
 game.sfx.master_volume = 0
 game.save_path = "user://capture_test.cfg"
 await shot("grid-snake-menu")
 game.start_game()
 game.snake.clear()
 for x in range(18, 9, -1): game.snake.append(Vector2i(x, 8))
 for y in range(9, 14): game.snake.append(Vector2i(10, y))
 for x in range(11, 19): game.snake.append(Vector2i(x, 13))
 game.food = Vector2i(22, 8)
 game.foods_eaten = 17
 game.score = 170
 game.refresh_hud()
 game.queue_redraw()
 await shot("grid-snake")
 game.pause_game()
 await shot("grid-snake-pause")
 game.resume_game()
 game.finish(true, "A game by memory.")
 await shot("grid-snake-result")
 game.show_help()
 await shot("grid-snake-help")
 DirAccess.remove_absolute(game.save_path)
 game.queue_free()
 await process_frame
 quit()
