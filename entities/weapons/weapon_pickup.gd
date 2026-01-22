extends Node2D
class_name WeaponPickup

# Droppable weapon that can be picked up

@export var weapon_type: String = "pistol"  # pistol, shotgun, laser
@export var pickup_radius: float = 30.0

var weapon_scene: PackedScene
var is_on_ground: bool = true

@onready var sprite = $Sprite
@onready var glow = $Glow
@onready var area = $PickupArea

func _ready():
	_setup_weapon_type()
	_setup_pickup_area()
	
	# Bobbing animation
	_start_bobbing()

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
		glow.color = color
		temp_weapon.free()

func _setup_pickup_area():
	if area:
		area.body_entered.connect(_on_body_entered)

func _start_bobbing():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 10, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", position.y + 10, 1.0).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body):
	if body is Player:
		# Create weapon instance from scene
		if weapon_scene:
			var weapon = weapon_scene.instantiate()
			body.pickup_weapon(weapon)
			queue_free()
