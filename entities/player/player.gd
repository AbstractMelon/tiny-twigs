extends CharacterBody2D
class_name Player

# Player configuration
@export var player_id: int = 1
@export var player_color: Color = Color.CYAN
@export var max_health: float = 100.0
var health: float = 100.0

signal health_changed(new_health, max_health)
signal died

# Movement constants
const SPEED = 300.0
const JUMP_VELOCITY = -450.0
const AIR_CONTROL = 0.7
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1

# Combat constants
const BLOCK_DURATION = 0.5
const SHOOT_COOLDOWN = 0.3
const RAGDOLL_RECOVERY_TIME = 1.0

# Physics
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# State tracking
var is_blocking = false
var is_ragdoll = false
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var block_timer = 0.0
var ragdoll_timer = 0.0

# Current weapon
var current_weapon: Weapon = null

# Input actions (set dynamically based on player_id)
var input_left: String
var input_right: String
var input_jump: String
var input_shoot: String
var input_block: String
var input_drop: String

# References to child nodes
@onready var body_parts = $BodyParts
@onready var head = $BodyParts/Head
@onready var torso = $BodyParts/Torso
@onready var arm_left = $BodyParts/ArmLeft
@onready var arm_right = $BodyParts/ArmRight
@onready var leg_left = $BodyParts/LegLeft
@onready var leg_right = $BodyParts/LegRight
@onready var weapon_holder = $WeaponHolder
@onready var collision_shape = $CollisionShape2D
@onready var glow_effect = $GlowEffect
@onready var animation_player = $AnimationPlayer

func _ready():
	_setup_input_actions()
	_setup_visual_style()
	
func _setup_input_actions():
	# Set up input action names based on player ID
	input_left = "p" + str(player_id) + "_left"
	input_right = "p" + str(player_id) + "_right"
	input_jump = "p" + str(player_id) + "_jump"
	input_shoot = "p" + str(player_id) + "_shoot"
	input_block = "p" + str(player_id) + "_block"
	input_drop = "p" + str(player_id) + "_drop"

func _setup_visual_style():
	# Apply neon glow effect to all body parts
	for part in body_parts.get_children():
		if part is Line2D:
			part.default_color = player_color
			part.width = 3.0
			
	# Configure glow effect
	if glow_effect:
		glow_effect.color = player_color

func _physics_process(delta):
	if is_ragdoll:
		_handle_ragdoll(delta)
		return
	
	_update_timers(delta)
	_handle_gravity(delta)
	_handle_jump()
	_handle_movement()
	_update_weapon_orientation(delta)
	await _handle_combat()
	_animate_body_parts()
	
	move_and_slide()

func _update_timers(delta):
	if coyote_timer > 0:
		coyote_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if block_timer > 0:
		block_timer -= delta
	else:
		is_blocking = false

func _handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		coyote_timer = COYOTE_TIME

func _handle_jump():
	# Jump buffer
	if Input.is_action_just_pressed(input_jump):
		jump_buffer_timer = JUMP_BUFFER_TIME
	
	# Execute jump if conditions met
	if jump_buffer_timer > 0 and (is_on_floor() or coyote_timer > 0):
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0

func _handle_movement():
	var direction = 0.0
	if Input.is_action_pressed(input_left):
		direction -= 1.0
	if Input.is_action_pressed(input_right):
		direction += 1.0
	
	var control_factor = AIR_CONTROL if not is_on_floor() else 1.0
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * control_factor * 0.1)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.15)

func _handle_combat():
	# Block
	if Input.is_action_just_pressed(input_block):
		is_blocking = true
		block_timer = BLOCK_DURATION
	
	# Shoot
	if Input.is_action_pressed(input_shoot) and current_weapon:
		await _shoot_weapon()
	
	# Drop weapon
	if Input.is_action_just_pressed(input_drop) and current_weapon:
		_drop_weapon()

func _shoot_weapon() -> bool:
	if not current_weapon:
		return false
	
	var direction = Vector2.RIGHT.rotated(weapon_holder.rotation)
	if await current_weapon.fire(global_position, direction):
		# Recoil - apply in opposite direction of shot
		velocity -= direction * current_weapon.recoil_force
		_play_shoot_animation()
		return true
	return false

func _drop_weapon():
	if not current_weapon:
		return
	
	current_weapon.drop(global_position, velocity)
	current_weapon = null

func pickup_weapon(weapon: Weapon):
	if current_weapon:
		_drop_weapon()
	
	current_weapon = weapon
	weapon.pickup(self)
	weapon_holder.add_child(weapon)

func take_damage(amount: int, knockback: Vector2):
	if is_blocking:
		# Reduced damage and knockback when blocking
		health -= amount * 0.2
		knockback *= 0.3
	else:
		health -= amount
	
	health_changed.emit(health, max_health)
	
	# Apply knockback
	velocity = knockback
	
	if health <= 0:
		health = 0
		die()
	# Enter ragdoll if knockback is strong enough
	elif knockback.length() > 500:
		_enter_ragdoll()

func die():
	died.emit()
	is_ragdoll = true
	ragdoll_timer = 9999.0 # Effectively stay ragdolled
	# Signal or handle respawn/game over
	print("Player ", player_id, " has died!")
	
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(body_parts, "modulate:a", 0.0, 2.0)
	tween.finished.connect(func(): queue_free())

func _enter_ragdoll():
	is_ragdoll = true
	ragdoll_timer = RAGDOLL_RECOVERY_TIME
	# Visual effect: make body parts limp
	for part in body_parts.get_children():
		if part is Line2D:
			part.modulate.a = 0.7

func _handle_ragdoll(delta):
	velocity.y += gravity * delta
	velocity.x = move_toward(velocity.x, 0, 200 * delta)
	move_and_slide()
	
	ragdoll_timer -= delta
	if ragdoll_timer <= 0:
		_exit_ragdoll()

func _exit_ragdoll():
	is_ragdoll = false
	for part in body_parts.get_children():
		if part is Line2D:
			part.modulate.a = 1.0

func _animate_body_parts():
	if is_ragdoll:
		return

	if not is_on_floor():
		if velocity.y < 0:
			animation_player.play("jump")
		else:
			animation_player.play("fall")
	else:
		if abs(velocity.x) > 10.0:
			animation_player.play("walk")
			# Dynamic speed for walk animation
			animation_player.speed_scale = abs(velocity.x) / SPEED * 1.5
		else:
			animation_player.play("idle")
			animation_player.speed_scale = 1.0

func _update_weapon_orientation(delta: float):
	if not weapon_holder:
		return
		
	var facing_left = body_parts.scale.x < 0
	
	# All players aim where they move (keyboard-style)
	var h_dir = 0.0
	if Input.is_action_pressed(input_left): h_dir -= 1.0
	if Input.is_action_pressed(input_right): h_dir += 1.0
	
	if h_dir != 0:
		facing_left = h_dir < 0
	
	var target_rot = PI if facing_left else 0.0
	weapon_holder.rotation = lerp_angle(weapon_holder.rotation, target_rot, 15.0 * delta)

	body_parts.scale.x = -1 if facing_left else 1
	
	# Adjust weapon holder position so it's always in front of the player
	var holder_offset_x = 12.0 # Based on original position in TSCN
	weapon_holder.position.x = -holder_offset_x if facing_left else holder_offset_x
	
	# Correct weapon vertical flip so it's not upside down when pointing left
	weapon_holder.scale.y = -1 if facing_left else 1

func _play_shoot_animation():
	# Recoil animation with arm kickback
	var tween = create_tween()
	var shooting_arm = arm_right if body_parts.scale.x > 0 else arm_left
	var current_rot = shooting_arm.rotation
	tween.tween_property(shooting_arm, "rotation", current_rot - deg_to_rad(30), 0.05)
	tween.chain().tween_property(shooting_arm, "rotation", current_rot, 0.15)
