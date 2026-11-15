extends CharacterBody2D
## Last-level enemy: chases the player, plays directional attack
## animations from assets/enemy/, takes bullet damage, dies at 0 HP.

const ROOM_PATH := "user://room.cfg"

@export var speed: float = 90.0
@export var hp: int = 3
@export var damage: int = 1

var _attack_cooldown: float = 0.0
var _player: Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("enemies")
	_build_animations()
	var cfg := ConfigFile.new()
	var level := int(cfg.get_value("room", "index", 0)) if cfg.load(ROOM_PATH) == OK else 0
	if level != 2:
		visible = false
		collision_layer = 0
		collision_mask = 0
		set_physics_process(false)
		return
	_player = get_tree().get_first_node_in_group("player") as Node2D

func _build_animations() -> void:
	var frames := SpriteFrames.new()
	_add_animation(frames, "front", "res://assets/enemy/atack_animation_first.png", 6, 8.0)
	_add_animation(frames, "back", "res://assets/enemy/attack_animation_backshots.png", 6, 8.0)
	_add_animation(frames, "left", "res://assets/enemy/attack_animation_left.png", 5, 8.0)
	_add_animation(frames, "right", "res://assets/enemy/attack_animation_right.png", 4, 8.0)
	sprite.sprite_frames = frames
	sprite.animation = "front"
	sprite.scale = Vector2(2, 2)
	sprite.play("front")

func _add_animation(frames: SpriteFrames, anim_name: String, path: String, count: int, fps: float) -> void:
	var tex := load(path) as Texture2D
	if tex == null:
		push_error("Missing enemy texture: " + path)
		return
	var anim_frames: Array = []
	for i in count:
		var region := AtlasTexture.new()
		region.atlas = tex
		region.region = Rect2(i * 32, 0, 32, 32)
		anim_frames.append({"duration": 1.0, "texture": region})
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, true)
	frames.set_animation_speed(anim_name, fps)
	for i in count:
		frames.add_frame(anim_name, anim_frames[i]["texture"])

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	var to_player := _player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player.normalized() if dist > 0.01 else Vector2.ZERO

	# Directional attack animation by dominant axis.
	var anim := "front"
	if absf(dir.y) >= absf(dir.x):
		anim = "back" if dir.y < 0.0 else "front"
	else:
		anim = "left" if dir.x < 0.0 else "right"
	if sprite.animation != anim:
		sprite.play(anim)

	if dist > 36.0:
		velocity = velocity.move_toward(dir * speed, 600.0 * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
		if _attack_cooldown <= 0.0:
			_attack_cooldown = 1.0
			if _player.has_method("take_damage"):
				_player.take_damage(damage, dir)
	move_and_slide()

func take_damage(amount: int) -> void:
	hp -= amount
	# Hit flash.
	sprite.modulate = Color(2, 2, 2)
	var timer := get_tree().create_timer(0.08)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(sprite):
			sprite.modulate = Color.WHITE)
	if hp <= 0:
		remove_from_group("enemies")
		queue_free()
