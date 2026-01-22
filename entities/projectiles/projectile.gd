extends Area2D
class_name Projectile

@export var damage: int = 10
@export var knockback_force: float = 300.0
@export var speed: float = 800.0
@export var lifetime: float = 3.0
@export var projectile_color: Color = Color.YELLOW

var velocity: Vector2 = Vector2.ZERO
var shooter: Player = null

@onready var trail = $Trail
@onready var glow = $Glow
@onready var collision_shape = $CollisionShape2D

func _ready():
	_setup_visual()
	
	# Connect collision
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _setup_visual():
	if glow:
		glow.color = projectile_color
	if trail:
		trail.default_color = projectile_color

func _physics_process(delta):
	position += velocity * delta
	
	# Rotate to face direction of travel
	rotation = velocity.angle()

func initialize(start_pos: Vector2, direction: Vector2, projectile_speed: float, source_player: Player):
	global_position = start_pos
	velocity = direction.normalized() * projectile_speed
	shooter = source_player

func _on_body_entered(body):
	if body is Player and body != shooter:
		var knockback = velocity.normalized() * knockback_force
		body.take_damage(damage, knockback)
		_explode()
	elif body is TileMap or body is StaticBody2D:
		_explode()

func _on_area_entered(area):
	if area is Projectile and area != self:
		_explode()

func _explode():
	# Create explosion effect
	var explosion = preload("res://vfx/scenes/explosion.tscn").instantiate()
	explosion.global_position = global_position
	explosion.color = projectile_color
	get_tree().root.add_child(explosion)
	
	# Create particle burst
	var burst_script = preload("res://vfx/scripts/particle_burst.gd")
	var burst = burst_script.new()
	burst.global_position = global_position
	burst.particle_color = projectile_color
	get_tree().root.add_child(burst)
	
	queue_free()
