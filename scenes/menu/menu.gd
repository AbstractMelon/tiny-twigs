extends Node2D

@onready var parallax_bg = $Background/ParallaxBackground
@onready var player_selection_list = $MenuUI/PlayerSelectionList
@onready var control_label = $MenuUI/ControlLabel

var body_font = preload("res://assets/fonts/Hey Comic.ttf")
@export var scroll_speed = 125.0

func _ready():
	_update_ui()

func _process(delta):
	# Scroll the parallax background
	parallax_bg.scroll_offset.x += scroll_speed * delta

func _input(event):
	if event is InputEventKey and event.pressed:
		# Number of players (2-6)
		if event.keycode >= KEY_2 and event.keycode <= KEY_6:
			GameState.num_players = event.keycode - KEY_0
			_update_ui()
		
		# Swap schemes (F1-F6)
		elif event.keycode >= KEY_F1 and event.keycode <= KEY_F6:
			var pid = event.keycode - KEY_F1 + 1
			# Cycle through available schemes (1-6)
			GameState.player_schemes[pid] = (GameState.player_schemes[pid] % 6) + 1
			_update_ui()
				
		elif event.keycode == KEY_SPACE:
			_start_game()

func _update_ui():
	# Clear existing
	for child in player_selection_list.get_children():
		child.queue_free()
	
	# Update title
	control_label.text = "PLAYERS SELECTED: %d\nF1-F6: Swap Keybinds | SPACE: Start" % GameState.num_players

	# List players
	for i in range(GameState.num_players):
		var pid = i + 1
		var sid = GameState.player_schemes[pid]
		
		var row = HBoxContainer.new()
		player_selection_list.add_child(row)
		
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(24, 24)
		color_rect.color = GameState.PLAYER_COLORS[i]
		row.add_child(color_rect)
		
		var label = Label.new()
		label.text = " Player %d: [%s] Keys: %s" % [pid, InputManager.get_scheme_name(sid), InputManager.get_control_scheme_text(sid)]
		label.add_theme_font_override("font", body_font)
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", GameState.PLAYER_COLORS[i])
		row.add_child(label)

func _start_game():
	# Setup input based on selected schemes
	InputManager.setup_input_maps(GameState.player_schemes)
	# Load main game scene
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
