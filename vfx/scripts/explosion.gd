extends Node2D

# Visual effect node for explosions and impacts

@export var color: Color = Color.RED
@export var duration: float = 0.5
@export var max_scale: float = 2.0

@onready var particles = $Particles
@onready var shockwave = $Shockwave
@onready var glow = $Glow

func _ready():
	_setup_effect()
	_animate()

func _setup_effect():
	if glow:
		glow.color = color
		glow.energy = 3.0
	
	if shockwave:
		shockwave.default_color = color
	
	# Particles setup would go here if using GPUParticles2D

func _animate():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Scale up shockwave
	tween.tween_property(shockwave, "scale", Vector2.ONE * max_scale, duration)
	tween.tween_property(shockwave, "modulate:a", 0.0, duration)
	
	# Fade out glow
	tween.tween_property(glow, "energy", 0.0, duration)
	
	tween.finished.connect(queue_free)
