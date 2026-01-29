extends Node2D
class_name WeaponPickup

# Droppable weapon that can be picked up

@export var weapon_type: String = "pistol"  # pistol, shotgun, laser
@export var pickup_radius: float = 30.0

var weapon_scene: PackedScene
var is_on_ground: bool = true

@onready var sprite = $Visuals/Sprite
@onready var inner_sprite = $Visuals/InnerSprite
@onready var particles = $Visuals/Particles
@onready var glow = $Glow
@onready var area = $PickupArea

func _ready():
	_setup_weapon_type()
	_setup_pickup_area()
	
	# Bobbing and rotation animation
	_start_animations()

func _setup_weapon_type():
	var scene_path = "res://entities/weapons/weapon_scenes/" + weapon_type + ".tscn"
	# Map some names if they don't match
	if weapon_type == "rocket":
		scene_path = "res://entities/weapons/weapon_scenes/rocket_launcher.tscn"
	elif weapon_type == "burst":
		scene_path = "res://entities/weapons/weapon_scenes/burst_rifle.tscn"
	
	if FileAccess.file_exists(scene_path):
		weapon_scene = load(scene_path)
		# Update pickup visuals to match weapon color
		var temp_weapon = weapon_scene.instantiate()
		var color = temp_weapon.weapon_color
		sprite.default_color = color
		inner_sprite.default_color = color.lerp(Color.WHITE, 0.5)
		glow.color = color
		if particles:
			particles.color = color
			particles.color.a = 0.4
		temp_weapon.free()

func _setup_pickup_area():
	if area:
		area.body_entered.connect(_on_body_entered)

func _start_animations():
	var tween = create_tween().set_parallel(true).set_loops()
	
	# Floating/Bobbing
	tween.tween_property($Visuals, "position:y", -5.0, 1.2).from(5.0).set_trans(Tween.TRANS_SINE)
	
	# Continuous rotation for the visuals
	var rot_tween = create_tween().set_loops()
	rot_tween.tween_property($Visuals, "rotation", TAU, 3.0).from(0.0)

func _on_body_entered(body):
	if body is Player:
		# Create weapon instance from scene
		if weapon_scene:
			var weapon = weapon_scene.instantiate()
			body.pickup_weapon(weapon)
			queue_free()
