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
const RAGDOLL_RECOVERY_TIME = 1.02
const MIN_STUN_DURATION = 0.05

# Physics
var BASE_GRAVITY: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var gravity: float = BASE_GRAVITY

# State tracking
var is_blocking = false
var is_ragdoll = false
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var block_timer = 0.0
var ragdoll_timer = 0.0
var stun_timer = 0.0
var was_on_floor_last_frame = false

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
@onready var visuals = $Visuals
@onready var body_parts = $Visuals/BodyParts
@onready var head = $Visuals/BodyParts/Head
@onready var torso = $Visuals/BodyParts/Torso
@onready var arm_left = $Visuals/BodyParts/ArmLeft
@onready var arm_right = $Visuals/BodyParts/ArmRight
@onready var leg_left = $Visuals/BodyParts/LegLeft
@onready var leg_right = $Visuals/BodyParts/LegRight
@onready var weapon_holder = $Visuals/WeaponHolder
@onready var collision_shape = $CollisionShape2D
@onready var glow_effect = $GlowEffect
@onready var animation_player = $AnimationPlayer

func _ready():
	_setup_input_actions()
	_setup_visual_style()
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	safe_margin = 0.1
	was_on_floor_last_frame = is_on_floor()
	
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
	if stun_timer > 0:
		_handle_stun_movement(delta)
	else:
		_handle_jump()
		_handle_movement()
		_update_weapon_orientation(delta)
		_handle_combat()
	_animate_body_parts()
	
	move_and_slide()
	_update_coyote_state()

func _update_timers(delta):
	if coyote_timer > 0:
		coyote_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if block_timer > 0:
		block_timer -= delta
	else:
		is_blocking = false
	if stun_timer > 0:
		stun_timer = max(stun_timer - delta, 0.0)

func _handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func _update_coyote_state():
	var on_floor_now := is_on_floor()
	if on_floor_now:
		coyote_timer = COYOTE_TIME
	elif was_on_floor_last_frame and velocity.y >= 0.0:
		coyote_timer = COYOTE_TIME
	was_on_floor_last_frame = on_floor_now

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
	var direction = Input.get_axis(input_left, input_right)
	
	var control_factor = AIR_CONTROL if not is_on_floor() else 1.0
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * control_factor * 0.2)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.25)

func _handle_stun_movement(delta: float):
	var recovery_drag := 800.0
	velocity.x = move_toward(velocity.x, 0.0, recovery_drag * delta)
	if animation_player.current_animation != "hurt":
		animation_player.play("hurt")

func _handle_combat():
	# Block
	if Input.is_action_just_pressed(input_block):
		is_blocking = true
		block_timer = BLOCK_DURATION
		animation_player.play("block")
	
	# Shoot
	if Input.is_action_pressed(input_shoot) and current_weapon:
		_shoot_weapon()
	
	# Drop weapon
	if Input.is_action_just_pressed(input_drop) and current_weapon:
		_drop_weapon()

func set_gravity_scale(multiplier: float):
	gravity = BASE_GRAVITY * max(multiplier, 0.05)

func apply_stun(duration: float, knockback: Vector2 = Vector2.ZERO):
	if is_ragdoll:
		return
	stun_timer = max(stun_timer, max(duration, MIN_STUN_DURATION))
	if knockback != Vector2.ZERO:
		velocity += knockback
		velocity.x = clamp(velocity.x, -650.0, 650.0)
		velocity.y = clamp(velocity.y, -900.0, 900.0)
	is_blocking = false
	block_timer = 0.0
	animation_player.play("hurt")

func _shoot_weapon() -> bool:
	if not current_weapon:
		return false
	
	var direction = Vector2.RIGHT.rotated(weapon_holder.rotation)
	# If facing left, flip the direction appropriately
	if visuals.scale.x < 0:
		direction = Vector2.LEFT.rotated(-weapon_holder.rotation)
		
	if current_weapon.fire(global_position, direction):
		# Recoil - apply in opposite direction of shot
		velocity -= direction * current_weapon.recoil_force
		_play_shoot_animation()
		
		# Auto-drop if empty
		if current_weapon.ammo == 0:
			_drop_weapon()
			
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
		animation_player.play("hurt")
	
	health_changed.emit(health, max_health)
	
	# Apply knockback
	velocity += knockback
	velocity.x = clamp(velocity.x, -700.0, 700.0)
	velocity.y = clamp(velocity.y, -950.0, 950.0)
	
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
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(visuals, "modulate:a", 0.0, 1.0)
	tween.finished.connect(func(): queue_free())

func _enter_ragdoll():
	is_ragdoll = true
	ragdoll_timer = RAGDOLL_RECOVERY_TIME
	# Visual effect: make body parts limp
	visuals.modulate.a = 0.7

func _handle_ragdoll(delta):
	velocity.y += gravity * delta
	velocity.x = move_toward(velocity.x, 0, 200 * delta)
	move_and_slide()
	
	ragdoll_timer -= delta
	if ragdoll_timer <= 0:
		_exit_ragdoll()

func _exit_ragdoll():
	is_ragdoll = false
	visuals.modulate.a = 1.0

func _animate_body_parts():
	if is_ragdoll or is_blocking or animation_player.current_animation == "hurt":
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
		
	# All players aim where they move (keyboard-style)
	var h_dir = 0.0
	if Input.is_action_pressed(input_left): h_dir -= 1.0
	if Input.is_action_pressed(input_right): h_dir += 1.0
	
	if h_dir != 0:
		visuals.scale.x = -1 if h_dir < 0 else 1
	
	var target_rot = 0.0
	weapon_holder.rotation = lerp_angle(weapon_holder.rotation, target_rot, 15.0 * delta)
	weapon_holder.scale.y = 1 # Keep weapon scale normal relative to flipped visuals

func _play_shoot_animation():
	# Recoil animation with arm kickback
	var tween = create_tween()
	var shooting_arm = arm_right if visuals.scale.x > 0 else arm_left
	var current_rot = shooting_arm.rotation
	tween.tween_property(shooting_arm, "rotation", current_rot - deg_to_rad(30), 0.05)
	tween.chain().tween_property(shooting_arm, "rotation", current_rot, 0.15)
