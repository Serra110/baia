extends CharacterBody2D
## Top-down 2D movement: 8-way WASD / arrow keys / left stick.
## Level 0: plain L-room. Level 1: PC code puzzle. Level 2: enemies + revolver.

@export var speed: float = 200.0
@export var acceleration: float = 1200.0
@export var friction: float = 1500.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var gun: Node2D = $Gun

var _facing: StringName = &"idle"
var level: int = 0
var solved: bool = false
var all_dead: bool = false

# Revolver (last level only).
var hp: int = 5
var ammo: int = 6
const AMMO_MAX := 6
var _aim_direction: Vector2 = Vector2.RIGHT
var _reload_timer: float = 0.0
var _hurt_cooldown: float = 0.0

const SAVE_PATH := "user://save.cfg"
const ROOM_PATH := "user://room.cfg"
const MENU_SCENE := "res://control.tscn"
const BULLET_SCRIPT := preload("res://bullet.gd")

func _puzzle() -> Node:
	return get_node_or_null("../UI/CodePuzzle")

func _clue() -> Node:
	return get_node_or_null("../UI/DocumentClue")

func _exit_locked() -> bool:
	return (level == 1 and not solved) or (level == 2 and not all_dead)

func _update_exit_blocker() -> void:
	# Second hitbox behind the exit door: solid while the level is locked.
	var blocker := get_node_or_null("../ExitBlocker") as StaticBody2D
	if blocker:
		var locked := _exit_locked()
		blocker.collision_layer = 1 if locked else 0
		blocker.collision_mask = 0
		var label := get_node_or_null("../Decor/ExitLabel") as Label
		if label:
			if locked:
				label.text = "LOCKED" if level == 1 else "KILL ALL"
			else:
				label.text = "EXIT"

func _update_hud() -> void:
	var ammo_label := get_node_or_null("../UI/AmmoLabel") as Label
	if ammo_label:
		ammo_label.visible = level == 2
		ammo_label.text = "Ammo: %d/%d" % [ammo, AMMO_MAX]
	var hp_label := get_node_or_null("../UI/HPLabel") as Label
	if hp_label:
		hp_label.visible = level == 2
		hp_label.text = "HP: %d" % hp

func _on_code_solved() -> void:
	solved = true
	_update_exit_blocker()
	var vault := get_node_or_null("../Props/Vault") as Sprite2D
	if vault:
		vault.region_rect = Rect2(384, 0, 64, 64)

func _ready() -> void:
	add_to_group("player")
	var cfg := ConfigFile.new()
	if cfg.load(ROOM_PATH) == OK:
		level = int(cfg.get_value("room", "index", 0))
		solved = bool(cfg.get_value("room", "solved", false))
		all_dead = bool(cfg.get_value("room", "all_dead", false))
	# Camera rotates with the room: Level 1 = 90 degrees, Level 2 = 180, etc.
	if camera:
		camera.rotation_degrees = float(level % 4 * 90)
	# PC / Board / Vault props only in Level 1; enemies + gun only in Level 2.
	var props := get_node_or_null("../Props")
	if props:
		props.visible = level == 1
		var bodies := props.get_node_or_null("PropBodies") as StaticBody2D
		if bodies:
			bodies.collision_layer = 1 if level == 1 else 0
			bodies.collision_mask = 0
	var enemies := get_node_or_null("../Enemies")
	if enemies:
		enemies.visible = level == 2
	if gun:
		gun.visible = level == 2
	var puzzle := _puzzle()
	if puzzle:
		puzzle.visible = false
		if puzzle.has_signal("code_solved") and not puzzle.code_solved.is_connected(_on_code_solved):
			puzzle.code_solved.connect(_on_code_solved)
	if _clue():
		_clue().visible = false
	_update_exit_blocker()
	_update_hud()
	# Show a different vault frame once solved (last frame = open).
	var vault := get_node_or_null("../Props/Vault") as Sprite2D
	if vault and solved:
		vault.region_rect = Rect2(384, 0, 64, 64)
	if cfg.load(SAVE_PATH) == OK:
		var saved_pos: Variant = cfg.get_value("player", "position", position)
		if saved_pos is Vector2:
			position = saved_pos

func _unhandled_input(event: InputEvent) -> void:
	var puzzle := _puzzle()
	var clue := _clue()
	# Close open UI first instead of quitting to the menu.
	if event.is_action_pressed("ui_cancel"):
		if puzzle and puzzle.visible:
			puzzle.close_puzzle()
			return
		if clue and clue.visible:
			clue.visible = false
			return
	# Space: fire the revolver (last level only).
	if level == 2 and event.is_action_pressed("shoot"):
		_shoot()
		return
	# E near the PC opens the code puzzle; near the documents shows the code.
	if event.is_action_pressed("interact") and level == 1:
		var pc := get_node_or_null("../Props/PC") as Node2D
		if pc and global_position.distance_to(pc.global_position) < 90.0 and puzzle:
			puzzle.open_puzzle()
			return
		var board := get_node_or_null("../Props/Board") as Node2D
		if board and global_position.distance_to(board.global_position) < 90.0 and clue:
			clue.visible = not clue.visible
			return
	# Esc in game: save position and return to the main menu.
	if event.is_action_pressed("ui_cancel"):
		var cfg := ConfigFile.new()
		cfg.set_value("player", "position", position)
		cfg.save(SAVE_PATH)
		get_tree().change_scene_to_file(MENU_SCENE)

func _shoot() -> void:
	if ammo <= 0:
		return
	ammo -= 1
	_spawn_bullet()
	_update_hud()
	if ammo == 0:
		_reload_timer = 2.0

func _spawn_bullet() -> void:
	var bullet := Area2D.new()
	bullet.set_script(BULLET_SCRIPT)
	bullet.direction = _aim_direction
	bullet.global_position = global_position + _aim_direction * 40.0
	get_tree().current_scene.add_child.call_deferred(bullet)

func take_damage(amount: int, from_dir: Vector2) -> void:
	if _hurt_cooldown > 0.0:
		return
	_hurt_cooldown = 0.5
	hp -= amount
	velocity += from_dir * 250.0
	_update_hud()
	if hp <= 0:
		# Respawn the level with full HP.
		hp = 5
		ammo = AMMO_MAX
		position = Vector2(32, 64)
		_update_hud()

func _physics_process(delta: float) -> void:
	var puzzle := _puzzle()
	if puzzle and puzzle.visible:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_hurt_cooldown = maxf(0.0, _hurt_cooldown - delta)
	# Revolver reload.
	if _reload_timer > 0.0:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			ammo = AMMO_MAX
			_update_hud()
	# Last level: killing all enemies unlocks the exit.
	if level == 2 and not all_dead and get_tree().get_nodes_in_group("enemies").is_empty():
		all_dead = true
		var cfg := ConfigFile.new()
		cfg.set_value("room", "all_dead", true)
		cfg.save(ROOM_PATH)
		_update_exit_blocker()

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Normal keybinds in every room: WASD always moves in world axes
	# (W = up, S = down, A = left, D = right), regardless of camera rotation.
	var move_vector := input_vector

	if move_vector != Vector2.ZERO:
		_aim_direction = move_vector.normalized()
		# Normalize done by get_vector, so diagonals aren't faster.
		velocity = velocity.move_toward(move_vector * speed, acceleration * delta)
		# Pick animation by dominant axis (world direction).
		if absf(move_vector.y) >= absf(move_vector.x):
			_facing = &"up" if move_vector.y < 0.0 else &"walk"
		else:
			_facing = &"left" if move_vector.x < 0.0 else &"right"
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		# Keep last facing direction when idle; walk has no idle twin.
		_facing = &"idle" if _facing == &"walk" else _facing

	if sprite and sprite.animation != _facing:
		sprite.play(_facing)
	if gun:
		gun.rotation = _aim_direction.angle()

	move_and_slide()
