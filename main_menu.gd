extends Control
## Main menu: New Game / Load Game / Options / Quit.
## Buttons are TextureButtons using the cropped sprites in assets/main_menu/.
## Nodes are fetched with get_node_or_null so the menu does not error
## while the scene is still being built (e.g. a teammate's WIP menu).

@export var game_scene_path: String = "res://world.tscn"
@export var save_path: String = "user://save.cfg"

@onready var new_button: TextureButton = get_node_or_null("CenterContainer/VBoxContainer/NewGameButton") as TextureButton
@onready var load_button: TextureButton = get_node_or_null("CenterContainer/VBoxContainer/LoadGameButton") as TextureButton
@onready var options_button: TextureButton = get_node_or_null("CenterContainer/VBoxContainer/OptionsButton") as TextureButton
@onready var quit_button: TextureButton = get_node_or_null("CenterContainer/VBoxContainer/QuitButton") as TextureButton
@onready var status_label: Label = get_node_or_null("StatusLabel") as Label
@onready var options_panel: PanelContainer = get_node_or_null("OptionsPanel") as PanelContainer
@onready var volume_slider: HSlider = get_node_or_null("OptionsPanel/VBoxContainer/VolumeSlider") as HSlider
@onready var fullscreen_check: CheckButton = get_node_or_null("OptionsPanel/VBoxContainer/FullscreenCheck") as CheckButton
@onready var close_options_button: Button = get_node_or_null("OptionsPanel/VBoxContainer/CloseOptionsButton") as Button
@onready var ambience: AudioStreamPlayer = get_node_or_null("Ambience") as AudioStreamPlayer

func _ready() -> void:
	if ambience:
		if not ambience.finished.is_connected(ambience.play):
			ambience.finished.connect(ambience.play)
		if not ambience.playing:
			ambience.play()
	if new_button:
		new_button.pressed.connect(_on_new_game_pressed)
		new_button.grab_focus()
	if load_button:
		load_button.pressed.connect(_on_load_game_pressed)
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_changed)
		volume_slider.value = 100.0
	if fullscreen_check:
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	if close_options_button:
		close_options_button.pressed.connect(_on_close_options_pressed)
	if options_panel:
		options_panel.visible = false

func _on_new_game_pressed() -> void:
	if status_label:
		status_label.text = ""
	# Fresh run: clear any old save so Load can't resurrect it.
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	if FileAccess.file_exists("user://room.cfg"):
		DirAccess.remove_absolute("user://room.cfg")
	_change_scene(game_scene_path)

func _on_load_game_pressed() -> void:
	if FileAccess.file_exists(save_path):
		if status_label:
			status_label.text = ""
		_change_scene(game_scene_path)
	elif status_label:
		status_label.text = "No save found."

func _on_options_pressed() -> void:
	if options_panel:
		if status_label:
			status_label.text = ""
		options_panel.visible = true
		if close_options_button:
			close_options_button.grab_focus()
	elif status_label:
		status_label.text = "Options coming soon."
	else:
		print("Options coming soon.")

func _on_close_options_pressed() -> void:
	if options_panel:
		options_panel.visible = false
	if options_button:
		options_button.grab_focus()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_volume_changed(value: float) -> void:
	var db := linear_to_db(value / 100.0) if value > 0.0 else -80.0
	AudioServer.set_bus_volume_db(0, db)

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _change_scene(path: String) -> void:
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Failed to load scene %s: %s" % [path, error_string(err)])



func _on_newbutton_pressed() -> void:
	_on_new_game_pressed()

func _on_gallerybutton_pressed() -> void:
	# No gallery scene exists yet — give feedback instead of silently passing.
	if status_label:
		status_label.text = "Gallery coming soon."
	else:
		print("Gallery coming soon.")

func _on_optionsbutton_pressed() -> void:
	_on_options_pressed()

func _on_button_pressed() -> void:
	# Wired to the Quit button in control.tscn.
	_on_quit_pressed()
