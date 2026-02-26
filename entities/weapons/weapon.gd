extends Node2D
class_name Weapon

# Weapon properties
@export var weapon_name: String = "Basic Gun"
@export var weapon_color: Color = Color.YELLOW
@export var damage: int = 10
@export var fire_rate: float = 0.3
@export var recoil_force: float = 100.0
@export var ammo: int = -1  # -1 for unlimited
@export var projectile_speed: float = 800.0
@export var projectile_lifetime: float = 2.0
@export var projectile_knockback: float = 300.0

# State
var owner_player: Player = null
var can_fire: bool = true

# Projectile scene to spawn
@export var projectile_scene: PackedScene

@onready var shape: Line2D = $Visuals/Shape
@onready var sprite: Sprite2D = $Visuals/Sprite
@onready var glow: PointLight2D = $Visuals/Glow

func _ready():
	_setup_visual()
	if shape:
		shape.default_color = weapon_color
	if glow:
		glow.color = weapon_color
	
	# Apply color to sprite if it's modular
	if sprite and sprite.texture:
		sprite.modulate = Color(1.2, 1.2, 1.2) # Slight brightness boost

func _setup_visual():
	# Override in specific weapon classes
	pass

func fire(from_position: Vector2, direction: Vector2) -> bool:
	if not can_fire:
		return false
	
	if ammo == 0:
		return false
	
	if ammo > 0:
		ammo -= 1
	
	_spawn_projectile(from_position, direction)
	can_fire = false
	_start_cooldown()
	return true

func _start_cooldown():
	var timer := get_tree().create_timer(fire_rate)
	timer.timeout.connect(func():
		can_fire = true
	)

func _spawn_projectile(_from_position: Vector2, _direction: Vector2):
	# Override in specific weapon classes
	pass

func pickup(player: Player):
	owner_player = player
	visible = true
	# Reset dissolve
	if $Visuals.material is ShaderMaterial:
		$Visuals.material.set_shader_parameter("dissolve_value", 0.0)
	$Visuals.position = Vector2.ZERO # Reset any drift from drop animation
	$Visuals.modulate.a = 1.0

func drop(_from_position: Vector2, _initial_velocity: Vector2):
	owner_player = null
	
	# Visual dissipation effect
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://vfx/shaders/dissolve.gdshader")
	mat.set_shader_parameter("edge_color", weapon_color)
	mat.set_shader_parameter("dissolve_value", 0.0)
	
	$Visuals.material = mat
	for child in $Visuals.get_children():
		if child is CanvasItem:
			child.use_parent_material = true
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(mat, "shader_parameter/dissolve_value", 1.1, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Visuals, "position:y", $Visuals.position.y - 30, 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property($Visuals, "modulate:a", 0.0, 0.6)
	
	tween.chain().finished.connect(queue_free)
