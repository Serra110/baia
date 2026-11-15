extends Area2D
## Exit at the bottom of the vertical leg.
## Level 0: free exit to Level 1. Level 1: locked until the PC code is solved.
## Level 2: locked until all enemies are dead, then exiting wins the game.

const ROOM_PATH := "user://room.cfg"
const SAVE_PATH := "user://save.cfg"
const MENU_SCENE := "res://control.tscn"

var _done := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _done or not (body is CharacterBody2D):
		return

	var cfg := ConfigFile.new()
	var level := 0
	var solved := false
	var all_dead := false
	if cfg.load(ROOM_PATH) == OK:
		level = int(cfg.get_value("room", "index", 0))
		solved = bool(cfg.get_value("room", "solved", false))
		all_dead = bool(cfg.get_value("room", "all_dead", false))

	if (level == 1 and not solved) or (level == 2 and not all_dead):
		var label := get_node_or_null("../Decor/ExitLabel") as Label
		if label:
			label.text = "LOCKED" if level == 1 else "KILL ALL"
		return

	_done = true
	# Next level starts at spawn, so clear any Esc-save position.
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

	if level >= 2:
		# Final level cleared: you win, back to the main menu.
		if FileAccess.file_exists(ROOM_PATH):
			DirAccess.remove_absolute(ROOM_PATH)
		get_tree().change_scene_to_file(MENU_SCENE)
		return

	cfg.set_value("room", "index", level + 1)
	cfg.set_value("room", "solved", false)
	cfg.set_value("room", "all_dead", false)
	cfg.save(ROOM_PATH)
	get_tree().reload_current_scene()
