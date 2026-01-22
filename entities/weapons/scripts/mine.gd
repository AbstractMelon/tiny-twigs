extends Area2D
class_name Mine

# Proximity mine that explodes when players get near

@export var explosion_radius: float = 120.0
@export var explosion_damage: int = 40
@export var explosion_force: float = 700.0
@export var activation_time: float = 1.0
@export var mine_color: Color = Color.DEEP_PINK

var is_armed: bool = false
var placer: Player = null

@onready var sprite = $Sprite
@onready var glow = $Glow
@onready var detection_area = $DetectionArea

func _ready():
	_setup_visual()
	
	# Arm after delay
	await get_tree().create_timer(activation_time).timeout
	_arm_mine()

func _setup_visual():
	if sprite:
		sprite.default_color = mine_color
	if glow:
		glow.color = mine_color
		glow.energy = 0.5

func _arm_mine():
	is_armed = true
	if glow:
		glow.energy = 2.0
	
	# Start scanning pulse animation
	_pulse_animation()
	
	if detection_area:
		detection_area.body_entered.connect(_on_player_detected)

func _pulse_animation():
	while is_armed:
		var tween = create_tween()
		tween.tween_property(glow, "energy", 3.0, 0.3)
		tween.tween_property(glow, "energy", 2.0, 0.3)
		await tween.finished

func _on_player_detected(body):
	if body is Player and body != placer and is_armed:
		_explode()

func place_mine(pos: Vector2, source_player: Player):
	global_position = pos
	placer = source_player

func _explode():
	if not is_armed:
		return
	
	is_armed = false
	
	# Find all players in explosion radius
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = explosion_radius
	query.shape = circle_shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 1
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var body = result.collider
		if body is Player:
			var direction_to_player = (body.global_position - global_position).normalized()
			var distance = global_position.distance_to(body.global_position)
			var falloff = 1.0 - (distance / explosion_radius)
			var knockback = direction_to_player * explosion_force * falloff
			body.take_damage(int(explosion_damage * falloff), knockback)
	
	# Create explosion visual
	var explosion = preload("res://vfx/scenes/explosion.tscn").instantiate()
	explosion.global_position = global_position
	explosion.scale = Vector2.ONE * (explosion_radius / 50.0)
	explosion.color = mine_color
	get_tree().root.add_child(explosion)
	
	queue_free()
