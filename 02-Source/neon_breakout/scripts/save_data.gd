extends RefCounted
## All persistent data lives in user://. No project files are modified at runtime.

var save_path: String = "user://pilot_v1.cfg"
var best_score: int = 0
var wins: int = 0
var runs: int = 0
var volume: float = 0.65
var shake: bool = true
var fullscreen: bool = false

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	best_score = maxi(0, int(cfg.get_value("pilot", "best_score", 0)))
	wins = maxi(0, int(cfg.get_value("pilot", "wins", 0)))
	runs = maxi(0, int(cfg.get_value("pilot", "runs", 0)))
	volume = clampf(float(cfg.get_value("settings", "volume", 0.65)), 0.0, 1.0)
	shake = bool(cfg.get_value("settings", "shake", true))
	fullscreen = bool(cfg.get_value("settings", "fullscreen", false))

func save() -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("pilot", "best_score", best_score)
	cfg.set_value("pilot", "wins", wins)
	cfg.set_value("pilot", "runs", runs)
	cfg.set_value("settings", "volume", volume)
	cfg.set_value("settings", "shake", shake)
	cfg.set_value("settings", "fullscreen", fullscreen)
	return cfg.save(save_path)

func record(score_value: int, won: bool) -> void:
	best_score = maxi(best_score, score_value)
	runs += 1
	if won:
		wins += 1
	save()
