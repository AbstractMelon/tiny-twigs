extends Area2D
class_name Mine

# Proximity mine that explodes when players get near

@export var explosion_radius: float = 120.0
@export var explosion_damage: int = 40
@export var explosion_force: float = 700.0
@export var activation_time: float = 3.0
@export var hunt_speed: float = 220.0
@export var trigger_distance: float = 18.0
@export var mine_color: Color = Color.DEEP_PINK
@export var idle_hover_radius: float = 14.0
@export var idle_wobble_speed: float = 2.2
@export var chase_wobble_strength: float = 22.0
@export var accel: float = 950.0

var is_armed: bool = false
var placer: Player = null
var current_target: Player = null
var is_exploding: bool = false
var spawn_position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var state_time: float = 0.0

@onready var sprite = $Sprite
@onready var glow = $Glow
@onready var detection_area = $DetectionArea

func _ready():
	_setup_visual()
	spawn_position = global_position
	if detection_area:
		detection_area.body_entered.connect(_on_player_detected)
	
	# Arm after delay
	_set_unarmed_visuals()
	await get_tree().create_timer(activation_time).timeout
	_arm_mine()

func _physics_process(delta):
	state_time += delta

	if is_exploding:
		return

	if not is_armed:
		_update_unarmed_motion(delta)
		return

	if not _is_valid_target(current_target):
		current_target = _find_nearest_target()

	if not _is_valid_target(current_target):
		_update_armed_idle_motion(delta)
		return

	var to_target := current_target.global_position - global_position
	if to_target.length() <= trigger_distance:
		_explode()
		return

	_update_hunt_motion(delta, to_target)

func _setup_visual():
	if sprite:
		sprite.default_color = mine_color
	if glow:
		glow.color = mine_color
		glow.energy = 0.5

func _set_unarmed_visuals():
	if sprite:
		sprite.default_color = mine_color.darkened(0.45)
		sprite.width = 2.0
		sprite.modulate.a = 0.7
	if glow:
		glow.color = mine_color.darkened(0.25)
		glow.energy = 0.4
		glow.texture_scale = 0.95

func _set_armed_visuals():
	if sprite:
		sprite.default_color = mine_color.lerp(Color.WHITE, 0.28)
		sprite.width = 3.6
		sprite.modulate.a = 1.0
	if glow:
		glow.color = mine_color.lerp(Color.WHITE, 0.15)
		glow.energy = 2.2
		glow.texture_scale = 1.2

func _update_unarmed_motion(delta: float):
	var hover := Vector2(
		sin(state_time * idle_wobble_speed),
		cos(state_time * (idle_wobble_speed * 1.3))
	) * (idle_hover_radius * 0.45)
	global_position = spawn_position + hover
	rotation += delta * 0.65
	if glow:
		glow.energy = 0.35 + (sin(state_time * 2.6) + 1.0) * 0.25

func _update_armed_idle_motion(delta: float):
	var drift_target := spawn_position + Vector2(
		sin(state_time * 1.4),
		cos(state_time * 1.9)
	) * idle_hover_radius
	var to_drift := drift_target - global_position
	var target_vel := to_drift * 3.4
	velocity = velocity.move_toward(target_vel, accel * 0.55 * delta)
	global_position += velocity * delta
	rotation += delta * 2.4

func _update_hunt_motion(delta: float, to_target: Vector2):
	var dir := to_target.normalized()
	var perp := Vector2(-dir.y, dir.x)
	var wobble := perp * sin(state_time * 11.0) * chase_wobble_strength
	var target_vel := (dir * hunt_speed) + wobble
	velocity = velocity.move_toward(target_vel, accel * delta)
	global_position += velocity * delta
	rotation = velocity.angle() + PI * 0.5

func _arm_mine():
	is_armed = true
	_set_armed_visuals()
	if glow:
		glow.energy = 2.0
	
	# Start scanning pulse animation
	_pulse_animation()

func _pulse_animation():
	while is_armed:
		var tween = create_tween()
		tween.tween_property(glow, "energy", 3.8, 0.15)
		tween.tween_property(glow, "energy", 2.1, 0.2)
		await tween.finished

func _on_player_detected(body):
	if body is Player and body != placer and is_armed:
		current_target = body

func _find_nearest_target() -> Player:
	if not detection_area:
		return null

	var nearest: Player = null
	var nearest_dist := INF
	for body in detection_area.get_overlapping_bodies():
		if body is Player and body != placer:
			var dist := global_position.distance_to(body.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = body

	return nearest

func _is_valid_target(target: Player) -> bool:
	return target != null and is_instance_valid(target)

func place_mine(pos: Vector2, source_player: Player):
	global_position = pos
	spawn_position = pos
	placer = source_player

func _explode():
	if not is_armed or is_exploding:
		return
	
	is_exploding = true
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
