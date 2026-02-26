extends RigidBody2D
class_name Grenade

@export var explosion_radius: float = 150.0
@export var explosion_damage: int = 50
@export var explosion_force: float = 800.0
@export var fuse_time: float = 2.0
@export var grenade_color: Color = Color.RED

@onready var sprite = $Sprite
@onready var glow = $Glow
@onready var fuse_timer = $FuseTimer

var thrower: Player = null
var exploded: bool = false

func _ready():
	_setup_visual()
	body_entered.connect(_on_body_entered)
	fuse_timer.wait_time = fuse_time
	fuse_timer.timeout.connect(_explode)
	fuse_timer.start()
	
	# Blink faster as fuse runs out
	_blink_effect()

func _setup_visual():
	if sprite:
		sprite.default_color = grenade_color
	if glow:
		glow.color = grenade_color

func _blink_effect():
	while fuse_timer.time_left > 0:
		var blink_rate = maxf(0.1, fuse_timer.time_left / fuse_time * 0.5)
		glow.energy = 2.0
		await get_tree().create_timer(blink_rate / 2).timeout
		glow.energy = 0.5
		await get_tree().create_timer(blink_rate / 2).timeout

func throw_grenade(start_pos: Vector2, direction: Vector2, force: float, source_player: Player):
	global_position = start_pos
	linear_velocity = direction.normalized() * force
	thrower = source_player

func _on_body_entered(body: Node) -> void:
	if body is Player:
		_explode()

func _explode():
	if exploded:
		return
	exploded = true
	if fuse_timer and not fuse_timer.is_stopped():
		fuse_timer.stop()

	# Find all players in explosion radius
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = explosion_radius
	query.shape = circle_shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 1 + 2 # Environment and Players
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var body = result.collider
		if body is Player: # Allowed to damage self too
			var direction_to_player = (body.global_position - global_position).normalized()
			if direction_to_player == Vector2.ZERO: direction_to_player = Vector2.UP
			var distance = global_position.distance_to(body.global_position)
			var falloff = 1.0 - (distance / explosion_radius)
			var knockback = direction_to_player * explosion_force * falloff
			body.take_damage(int(explosion_damage * falloff), knockback)
	
	# Create explosion visual
	var explosion = preload("res://vfx/scenes/explosion.tscn").instantiate()
	explosion.global_position = global_position
	explosion.scale = Vector2.ONE * (explosion_radius / 50.0)
	explosion.color = grenade_color
	get_tree().root.add_child(explosion)
	
	queue_free()
