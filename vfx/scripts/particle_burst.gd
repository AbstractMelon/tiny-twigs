extends Node2D
class_name ParticleBurst

# Particle burst effect for impacts and hits

@export var particle_color: Color = Color.WHITE
@export var particle_count: int = 12
@export var spread_speed: float = 200.0
@export var lifetime: float = 0.8

func _ready():
	_create_particles()

func _create_particles():
	for i in range(particle_count):
		var angle = (TAU / particle_count) * i
		var direction = Vector2.RIGHT.rotated(angle)
		
		var particle = Line2D.new()
		var points = PackedVector2Array()
		points.append(Vector2.ZERO)
		points.append(direction * 3)
		particle.points = points
		particle.width = 2.0
		particle.default_color = particle_color
		particle.begin_cap_mode = Line2D.LINE_CAP_ROUND
		particle.end_cap_mode = Line2D.LINE_CAP_ROUND
		add_child(particle)
		
		_animate_particle(particle, direction)
	
	# Cleanup after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _animate_particle(particle: Line2D, direction: Vector2):
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Move outward
	var target_pos = direction * spread_speed * lifetime
	tween.tween_property(particle, "position", target_pos, lifetime)
	
	# Fade out
	tween.tween_property(particle, "modulate:a", 0.0, lifetime)

static func create_at(pos: Vector2, color: Color):
	var burst = ParticleBurst.new()
	burst.global_position = pos
	burst.particle_color = color
	return burst
