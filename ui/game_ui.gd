extends CanvasLayer

# UI overlay for player info and game state

signal new_round_requested
signal menu_requested

@onready var game_hud = $GameHUD
@onready var player_status_list = $GameHUD/PlayerStatusList
@onready var win_screen = $WinScreen
@onready var winner_text = $WinScreen/Panel/VBox/WinnerText
@onready var restart_button = $WinScreen/Panel/VBox/Buttons/RestartButton
@onready var menu_button = $WinScreen/Panel/VBox/Buttons/MenuButton

@onready var pause_menu = $PauseMenu
@onready var resume_button = $PauseMenu/Panel/VBox/Buttons/ResumeButton
@onready var exit_button = $PauseMenu/Panel/VBox/Buttons/ExitButton

var body_font = GameState.theme_font
var player_labels: Array = []
var active_players_ui: Array = []

func _ready():
	game_hud.hide()
	win_screen.hide()
	pause_menu.hide()
	
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	resume_button.pressed.connect(_toggle_pause)
	exit_button.pressed.connect(_on_menu_pressed)


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if not win_screen.visible:
			_toggle_pause()
		return

	if not win_screen.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_on_restart_pressed()

func _toggle_pause():
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	pause_menu.visible = new_pause_state
	
	if new_pause_state:
		# Ensure we can still use the mouse for buttons
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func show_game_ui(players: Array):
	game_hud.show()
	win_screen.hide()
	pause_menu.hide()
	get_tree().paused = false
	
	# Clear existing status indicators
	for child in player_status_list.get_children():
		child.queue_free()
	player_labels = []
	active_players_ui.clear()
	
	# Create player status indicators
	for i in range(players.size()):
		var player_info = VBoxContainer.new()
		player_status_list.add_child(player_info)
		
		var top_row = HBoxContainer.new()
		player_info.add_child(top_row)
		
		var label = Label.new()
		var pid: int = int(players[i].player_id)
		label.text = " P%d  W:%d" % [pid, GameState.get_wins(pid)]
		label.add_theme_font_override("font", body_font)
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", players[i].player_color)
		top_row.add_child(label)
		
		# Weapon row
		var weapon_row = HBoxContainer.new()
		player_info.add_child(weapon_row)
		var weapon_icon = TextureRect.new()
		weapon_icon.custom_minimum_size = Vector2(16, 16)
		weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		weapon_row.add_child(weapon_icon)
		
		var weapon_label = Label.new()
		weapon_label.add_theme_font_override("font", body_font)
		weapon_label.add_theme_font_size_override("font_size", 14)
		weapon_row.add_child(weapon_label)
		
		# Health bar
		var health_bar = ProgressBar.new()
		health_bar.custom_minimum_size = Vector2(120, 10)
		health_bar.max_value = players[i].max_health
		health_bar.value = players[i].health
		health_bar.show_percentage = false
		
		# Stylize health bar
		var sb = StyleBoxFlat.new()
		sb.bg_color = players[i].player_color
		sb.set_border_width_all(1)
		health_bar.add_theme_stylebox_override("fill", sb)
		
		player_info.add_child(health_bar)
		
		# Connect health signal
		players[i].health_changed.connect(func(new_val, max_val):
			if is_instance_valid(health_bar):
				health_bar.value = new_val
				health_bar.max_value = max_val
		)
		
		player_labels.append(player_info)
		active_players_ui.append({
			"player": players[i],
			"weapon_icon": weapon_icon,
			"weapon_label": weapon_label
		})

func _process(_delta):
	for p_info in active_players_ui:
		var p = p_info["player"]
		if not is_instance_valid(p):
			continue
		
		var icon: TextureRect = p_info["weapon_icon"]
		var label: Label = p_info["weapon_label"]
		if not is_instance_valid(icon) or not is_instance_valid(label):
			continue
			
		if p.current_weapon and is_instance_valid(p.current_weapon):
			var w = p.current_weapon
			if w.sprite and w.sprite.texture:
				icon.texture = w.sprite.texture
				icon.modulate = w.weapon_color
				icon.show()
			else:
				icon.texture = null
				icon.hide()
			var ammo_text = str(w.ammo) if w.ammo >= 0 else "∞"
			label.text = "%s [%s]" % [w.weapon_name, ammo_text]
			label.add_theme_color_override("font_color", w.weapon_color)
		else:
			icon.texture = null
			icon.hide()
			label.text = "Unarmed"
			label.add_theme_color_override("font_color", Color.GRAY)

func show_win_screen(winner):
	game_hud.hide()
	win_screen.show()
	
	if winner:
		winner_text.text = "PLAYER %d WINS!" % winner.player_id
		winner_text.add_theme_color_override("font_color", winner.player_color)
	else:
		winner_text.text = "IT'S A TIE!"
		winner_text.add_theme_color_override("font_color", Color.WHITE)

func _on_restart_pressed():
	new_round_requested.emit()

func _on_menu_pressed():
	menu_requested.emit()
