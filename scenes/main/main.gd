extends Node2D

# Main game controller

@export var num_players: int = 4
@export var round_time: int = 180  # 3 minutes

# Player colors for neon aesthetic
const PLAYER_COLORS = [
	Color.CYAN,      # Player 1
	Color.MAGENTA,   # Player 2
	Color.YELLOW,    # Player 3
	Color.LIME,      # Player 4
	Color.ORANGE,    # Player 5
	Color.HOT_PINK   # Player 6
]

# Spawn points
var spawn_points: Array = []

# Weapon spawn locations
var weapon_spawn_points: Array = []

# Game state
var active_players: Array = []
var game_started: bool = false

@onready var ui = $UI
@onready var arena = $Arena
@onready var camera = $Camera2D

func _ready():
	# Setup input for all players
	InputManager.setup_input_maps()
	
	# Collect spawn points
	_collect_spawn_points()
	
	# Setup UI
	if ui and ui.has_method("_ready"):
		pass  # UI will setup itself
	
	# Show start menu
	_show_start_menu()

func _collect_spawn_points():
	var spawn_container = $Arena/SpawnPoints
	if spawn_container:
		for child in spawn_container.get_children():
			if child is Marker2D:
				spawn_points.append(child.global_position)
	
	var weapon_spawn_container = $Arena/WeaponSpawns
	if weapon_spawn_container:
		for child in weapon_spawn_container.get_children():
			if child is Marker2D:
				weapon_spawn_points.append(child.global_position)

func _show_start_menu():
	# Simple text display for player count selection
	print("Tiny Twigs - Press 2-6 to select number of players, then SPACE to start")

func _input(event):
	if not game_started:
		if event is InputEventKey and event.pressed:
			if event.keycode >= KEY_2 and event.keycode <= KEY_6:
				num_players = event.keycode - KEY_0
				print("Selected %d players" % num_players)
				if ui and ui.has_method("update_player_count"):
					ui.update_player_count(num_players)
			elif event.keycode == KEY_SPACE:
				_start_game()

func _start_game():
	game_started = true
	_spawn_players()
	_spawn_initial_weapons()
	_start_weapon_spawn_timer()
	
	# Update UI
	if ui and ui.has_method("show_game_ui"):
		ui.show_game_ui(active_players)

func _spawn_players():
	var player_scene = preload("res://entities/player/player.tscn")
	
	for i in range(num_players):
		var player = player_scene.instantiate()
		player.player_id = i + 1
		player.player_color = PLAYER_COLORS[i]
		
		# Spawn at designated point
		if i < spawn_points.size():
			player.global_position = spawn_points[i]
		else:
			# Random position if not enough spawn points
			player.global_position = Vector2(
				randf_range(100, 900),
				randf_range(100, 500)
			)
		
		add_child(player)
		active_players.append(player)

func _spawn_initial_weapons():
	# Spawn a few weapons at the start
	for i in range(min(4, weapon_spawn_points.size())):
		_spawn_random_weapon(weapon_spawn_points[i])

func _start_weapon_spawn_timer():
	var timer = Timer.new()
	timer.wait_time = 5.0  # Spawn weapon every 5 seconds
	timer.timeout.connect(_spawn_weapon_at_random_location)
	timer.autostart = true
	add_child(timer)

func _spawn_weapon_at_random_location():
	if weapon_spawn_points.size() > 0:
		var spawn_pos = weapon_spawn_points[randi() % weapon_spawn_points.size()]
		_spawn_random_weapon(spawn_pos)

func _spawn_random_weapon(spawn_position: Vector2):
	var weapon_types = ["pistol", "shotgun", "laser", "burst", "rocket", "railgun", "flamethrower"]
	var weapon_type = weapon_types[randi() % weapon_types.size()]
	
	var pickup_scene = preload("res://entities/weapons/weapon_pickup.tscn")
	var pickup = pickup_scene.instantiate()
	pickup.weapon_type = weapon_type
	pickup.global_position = spawn_position
	add_child(pickup)

func _physics_process(_delta):
	if game_started and active_players.size() > 0:
		_update_camera()

func _update_camera():
	# Center camera on all active players
	var center = Vector2.ZERO
	var count = 0
	
	for player in active_players:
		if is_instance_valid(player):
			center += player.global_position
			count += 1
	
	if count > 0:
		camera.global_position = center / count
