extends Control
## 5-digit code puzzle UI, built in code so the scene stays simple.
## Opened by the player when near the PC in Room 2 (press E).

@export var correct_code: String = "12345"

signal code_solved

const ROOM_PATH := "user://room.cfg"

var _code_edit: LineEdit
var _message: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "PC - Enter 5-digit code"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	_code_edit = LineEdit.new()
	_code_edit.max_length = 5
	_code_edit.placeholder_text = "_____"
	_code_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_code_edit.add_theme_font_size_override("font_size", 36)
	vbox.add_child(_code_edit)

	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_message)

	var enter_button := Button.new()
	enter_button.text = "Enter code"
	enter_button.pressed.connect(_on_enter_pressed)
	vbox.add_child(enter_button)

	var clear_button := Button.new()
	clear_button.text = "Clear"
	clear_button.pressed.connect(func() -> void: _code_edit.clear())
	vbox.add_child(clear_button)

	var close_button := Button.new()
	close_button.text = "Close (Esc)"
	close_button.pressed.connect(close_puzzle)
	vbox.add_child(close_button)

	_code_edit.text_submitted.connect(func(_text: String) -> void: _on_enter_pressed())

func open_puzzle() -> void:
	visible = true
	_code_edit.clear()
	_message.text = ""
	_code_edit.grab_focus()

func close_puzzle() -> void:
	visible = false

func is_open() -> bool:
	return visible

func _on_enter_pressed() -> void:
	if _code_edit.text == correct_code:
		_message.text = "Correct - vault open!"
		var cfg := ConfigFile.new()
		cfg.set_value("room", "solved", true)
		cfg.save(ROOM_PATH)
		code_solved.emit()
	else:
		_message.text = "Wrong code."
		_code_edit.clear()
