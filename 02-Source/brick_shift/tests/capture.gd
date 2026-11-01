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
 await shot("brick-shift-menu")
 game.start_game()
 game.level = 2
 game.make_board()
 for i in range(8): game.bricks.remove_at(i * 2)
 game.attached = false
 game.ball = Vector2(640, 428)
 game.velocity = Vector2(200, -380)
 game.paddle_x = 620
 game.score = 370
 game.drops.append({"p": Vector2(390, 370)})
 game.notice_timer = 0
 game.refresh_hud()
 game.queue_redraw()
 await shot("brick-shift")
 game.pause_game()
 await shot("brick-shift-pause")
 game.resume_game()
 game.finish(true, "A game by memory.")
 await shot("brick-shift-result")
 game.show_help()
 await shot("brick-shift-help")
 DirAccess.remove_absolute(game.save_path)
 game.queue_free()
 await process_frame
 quit()
