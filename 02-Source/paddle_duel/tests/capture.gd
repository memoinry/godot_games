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
 await shot("paddle-duel-menu")
 game.start_game()
 game.player_points = 3
 game.rival_points = 2
 game.ball = Vector2(637, 236)
 game.player_y = 360
 game.rival_y = 250
 game.velocity = Vector2(-480, 120)
 game.longest_rally = 8
 game.score = 430
 game.notice_timer = 0
 game.refresh_hud()
 game.queue_redraw()
 await shot("paddle-duel")
 game.pause_game()
 await shot("paddle-duel-pause")
 game.resume_game()
 game.finish(true, "A game by memory.")
 await shot("paddle-duel-result")
 game.show_help()
 await shot("paddle-duel-help")
 DirAccess.remove_absolute(game.save_path)
 game.queue_free()
 await process_frame
 quit()
