extends Node2D

# Main game controller

@export var round_time: int = 180  # 3 minutes

# Spawn points
var spawn_points: Array = []

# Weapon spawn locations
var weapon_spawn_points: Array = []

# Per-spawn occupancy: index matches weapon_spawn_points.
var weapon_pickups_at_spawns: Array[WeaponPickup] = []

# Game state
var active_players: Array = []
var game_started: bool = false

var weapon_spawn_timer: Timer = null

var round_reset_in_progress: bool = false

@onready var music_player: AudioStreamPlayer = $MusicPlayer
var gameplay_tracks: Array[AudioStream] = []
var music_track_index: int = 0

@onready var ui = $UI
@onready var arena = $Arena
@onready var camera = $Camera2D

# Camera framing
@export var camera_padding: Vector2 = Vector2(220, 160)
@export_range(0.0, 20.0, 0.1) var camera_pos_smooth: float = 2.0
@export_range(0.0, 20.0, 0.1) var camera_zoom_smooth: float = 1.8
@export_range(0.05, 4.0, 0.01) var camera_min_zoom: float = 0.6
@export_range(0.05, 4.0, 0.01) var camera_max_zoom: float = 1.6
@export var clamp_camera_to_arena_bounds: bool = true

@onready var arena_bounds_top_left: Marker2D = get_node_or_null("Arena/Bounds/TopLeft")
@onready var arena_bounds_bottom_right: Marker2D = get_node_or_null("Arena/Bounds/BottomRight")

func _ready():
	# Collect spawn points
	_collect_spawn_points()
	if camera:
		camera.make_current()

	_setup_gameplay_music()
	_setup_ui_signals()
	_ensure_weapon_spawn_timer()
	
	# Start game immediately using GameState settings
	_start_game()


func _setup_ui_signals() -> void:
	if not ui:
		return
	if ui.has_signal("new_round_requested"):
		ui.new_round_requested.connect(_start_new_round)
	if ui.has_signal("menu_requested"):
		ui.menu_requested.connect(_return_to_menu)


func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/menu.tscn")


func _setup_gameplay_music() -> void:
	if not music_player:
		return
	if gameplay_tracks.is_empty():
		gameplay_tracks = [
			preload("res://assets/audio/LEMMiNO - Firecracker (BGM).mp3.ogg"),
			preload("res://assets/audio/LEMMiNO - Nocturnal (BGM).mp3"),
		]
		for track in gameplay_tracks:
			if track is AudioStreamMP3 or track is AudioStreamOggVorbis:
				track.loop = false
	# Ensure we cycle through the playlist.
	if not music_player.finished.is_connected(_on_music_finished):
		music_player.finished.connect(_on_music_finished)

	# If the current stream is already one of our gameplay tracks, keep its index.
	for i in range(gameplay_tracks.size()):
		if music_player.stream == gameplay_tracks[i]:
			music_track_index = i
			break

	# If the scene MusicPlayer wasn't already playing (e.g. autoplay disabled), start it.
	if not music_player.playing and not gameplay_tracks.is_empty():
		music_player.stream = gameplay_tracks[music_track_index]
		music_player.play()


func _on_music_finished() -> void:
	if gameplay_tracks.is_empty() or not music_player:
		return
	music_track_index = (music_track_index + 1) % gameplay_tracks.size()
	music_player.stream = gameplay_tracks[music_track_index]
	music_player.play()

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

	weapon_pickups_at_spawns.clear()
	weapon_pickups_at_spawns.resize(weapon_spawn_points.size())
	for i in range(weapon_pickups_at_spawns.size()):
		weapon_pickups_at_spawns[i] = null

func _start_game():
	game_started = true
	
	_spawn_players()
	_spawn_initial_weapons()
	if weapon_spawn_timer:
		weapon_spawn_timer.start()
	
	# Update UI
	if ui and ui.has_method("show_game_ui"):
		ui.show_game_ui(active_players)

func _spawn_players():
	var player_scene = preload("res://entities/player/player.tscn")
	
	# Randomize spawn points
	var available_spawns = spawn_points.duplicate()
	available_spawns.shuffle()
	
	for i in range(GameState.num_players):
		var player = player_scene.instantiate()
		player.player_id = i + 1
		player.player_color = GameState.PLAYER_COLORS[i]
		
		# Spawn at designated point
		if i < available_spawns.size():
			player.global_position = available_spawns[i]
		else:
			# Random position if not enough spawn points
			player.global_position = Vector2(
				randf_range(100, 900),
				randf_range(100, 500)
			)
		
		add_child(player)
		active_players.append(player)
		player.died.connect(_on_player_died.bind(player))

func _on_player_died(player):
	if player in active_players:
		active_players.erase(player)
	
	_check_win_condition()

func _check_win_condition():
	if not game_started:
		return
		
	if active_players.size() <= 1:
		game_started = false
		var winner = active_players[0] if active_players.size() == 1 else null
		if weapon_spawn_timer:
			weapon_spawn_timer.stop()

		if winner:
			GameState.add_win(int(winner.player_id))
		
		# Show win UI
		if ui and ui.has_method("show_win_screen"):
			ui.show_win_screen(winner)

func _spawn_initial_weapons():
	# Spawn a few weapons at the start
	for i in range(min(4, weapon_spawn_points.size())):
		_spawn_random_weapon_at_index(i)

func _ensure_weapon_spawn_timer() -> void:
	if weapon_spawn_timer:
		return
	weapon_spawn_timer = Timer.new()
	weapon_spawn_timer.wait_time = 5.0  # Spawn weapon every 5 seconds
	weapon_spawn_timer.timeout.connect(_spawn_weapon_at_random_location)
	weapon_spawn_timer.one_shot = false
	add_child(weapon_spawn_timer)


func _start_new_round() -> void:
	# Only allow starting a new round once the previous one ended.
	if game_started or round_reset_in_progress:
		return
	round_reset_in_progress = true

	await _clear_round_entities()

	active_players.clear()
	game_started = true
	_spawn_players()
	_spawn_initial_weapons()
	if weapon_spawn_timer:
		weapon_spawn_timer.start()
	if ui and ui.has_method("show_game_ui"):
		ui.show_game_ui(active_players)
	round_reset_in_progress = false


func _clear_round_entities() -> void:
	# Remove players and weapon pickups left from the previous round.
	for child in get_children():
		if child is Player:
			child.queue_free()
		elif child is WeaponPickup:
			child.queue_free()

	# Wait one frame so queued frees are applied before respawning.
	await get_tree().process_frame

func _spawn_weapon_at_random_location():
	if not game_started:
		return

	if weapon_spawn_points.is_empty():
		return

	# Only spawn on a point that doesn't currently have an unpicked weapon.
	var free_indices: Array[int] = []
	for i in range(weapon_spawn_points.size()):
		var existing := weapon_pickups_at_spawns[i]
		if existing == null or not is_instance_valid(existing):
			free_indices.append(i)

	if free_indices.is_empty():
		return

	var spawn_index := free_indices[randi() % free_indices.size()]
	_spawn_random_weapon_at_index(spawn_index)

func _spawn_random_weapon_at_index(spawn_index: int) -> void:
	if spawn_index < 0 or spawn_index >= weapon_spawn_points.size():
		return

	var existing := weapon_pickups_at_spawns[spawn_index]
	if existing != null and is_instance_valid(existing):
		return

	var weapon_types = [
		"pistol",
		"shotgun",
		"laser",
		"burst",
		"rocket",
		"railgun",
		"flamethrower",
		"prism_blaster",
		"grenade_launcher",
		"mine_layer",
	]
	var weapon_type = weapon_types[randi() % weapon_types.size()]

	var pickup_scene = preload("res://entities/weapons/weapon_pickup.tscn")
	var pickup: WeaponPickup = pickup_scene.instantiate()
	pickup.weapon_type = weapon_type
	pickup.spawn_index = spawn_index
	pickup.global_position = weapon_spawn_points[spawn_index]
	weapon_pickups_at_spawns[spawn_index] = pickup
	add_child(pickup)

	# Clear occupancy no matter why it disappears (picked up, removed on new round, etc.)
	pickup.tree_exited.connect(_on_weapon_pickup_exited.bind(spawn_index, pickup))

func _on_weapon_pickup_exited(spawn_index: int, pickup: WeaponPickup) -> void:
	if spawn_index < 0 or spawn_index >= weapon_pickups_at_spawns.size():
		return
	if weapon_pickups_at_spawns[spawn_index] == pickup:
		weapon_pickups_at_spawns[spawn_index] = null

func _physics_process(delta):
	if game_started and active_players.size() > 0:
		_update_camera(delta)

func _update_camera(delta: float):
	if not camera:
		return

	# Compute bounding box of all active players
	var any_valid: bool = false
	var min_pos: Vector2 = Vector2(INF, INF)
	var max_pos: Vector2 = Vector2(-INF, -INF)
	for player in active_players:
		if not is_instance_valid(player):
			continue
		any_valid = true
		var pos: Vector2 = player.global_position
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)
		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.y, pos.y)

	if not any_valid:
		return

	var target_center: Vector2 = (min_pos + max_pos) * 0.5
	var bbox_size: Vector2 = (max_pos - min_pos).abs()
	# Prevent division by zero / extreme zoom when players overlap
	bbox_size.x = max(bbox_size.x, 64.0)
	bbox_size.y = max(bbox_size.y, 64.0)
	bbox_size += camera_padding * 2.0

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	viewport_size.x = max(viewport_size.x, 1.0)
	viewport_size.y = max(viewport_size.y, 1.0)

	# Godot Camera2D: larger zoom => closer (less world visible)
	var zoom_fit: float = min(viewport_size.x / bbox_size.x, viewport_size.y / bbox_size.y)
	zoom_fit = clamp(zoom_fit, camera_min_zoom, camera_max_zoom)

	if clamp_camera_to_arena_bounds:
		var arena_rect := _get_arena_bounds_rect()
		if arena_rect.size.x > 1.0 and arena_rect.size.y > 1.0:
			var half_view: Vector2 = (viewport_size * 0.5) / zoom_fit
			target_center = _clamp_point_to_rect_with_margin(target_center, arena_rect, half_view)

	# Smooth position/zoom (frame-rate independent)
	var pos_t: float = 1.0 - exp(-camera_pos_smooth * delta)
	var zoom_t: float = 1.0 - exp(-camera_zoom_smooth * delta)
	camera.global_position = camera.global_position.lerp(target_center, pos_t)
	var target_zoom: Vector2 = Vector2(zoom_fit, zoom_fit)
	camera.zoom = camera.zoom.lerp(target_zoom, zoom_t)

func _get_arena_bounds_rect() -> Rect2:
	if arena_bounds_top_left and arena_bounds_bottom_right:
		var tl: Vector2 = arena_bounds_top_left.global_position
		var br: Vector2 = arena_bounds_bottom_right.global_position
		var left: float = min(tl.x, br.x)
		var top: float = min(tl.y, br.y)
		var right: float = max(tl.x, br.x)
		var bottom: float = max(tl.y, br.y)
		return Rect2(Vector2(left, top), Vector2(right - left, bottom - top))
	return Rect2()

func _clamp_point_to_rect_with_margin(point: Vector2, rect: Rect2, margin: Vector2) -> Vector2:
	var min_x: float = rect.position.x + margin.x
	var max_x: float = rect.position.x + rect.size.x - margin.x
	var min_y: float = rect.position.y + margin.y
	var max_y: float = rect.position.y + rect.size.y - margin.y

	# If the camera view is bigger than the arena, just center.
	if min_x > max_x:
		point.x = rect.position.x + rect.size.x * 0.5
	else:
		point.x = clamp(point.x, min_x, max_x)
	if min_y > max_y:
		point.y = rect.position.y + rect.size.y * 0.5
	else:
		point.y = clamp(point.y, min_y, max_y)

	return point
