extends Area2D
## Revolver bullet: flies straight, damages the first enemy it hits.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var damage: int = 1
var _life: float = 0.7

func _ready() -> void:
	# Tracer visual: small bright diamond.
	var poly := Polygon2D.new()
	poly.color = Color(1, 0.9, 0.3)
	poly.polygon = PackedVector2Array([Vector2(10, 0), Vector2(0, -4), Vector2(-10, 0), Vector2(0, 4)])
	add_child(poly)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	# Point the tracer along travel direction.
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()

func _exit_tree() -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
	# Walls and props also stop the bullet.
	queue_free()
