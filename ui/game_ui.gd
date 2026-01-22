extends CanvasLayer

# UI overlay for player info and game state

var player_labels: Array = []

func _ready():
	_setup_ui()

func _setup_ui():
	# Title
	var title = Label.new()
	title.text = "TINY TWIGS"
	title.position = Vector2(20, 10)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.CYAN)
	add_child(title)
	
	# Control hints
	var controls = Label.new()
	controls.text = "Press 2-6 to select players | SPACE to start"
	controls.position = Vector2(20, 50)
	controls.add_theme_font_size_override("font_size", 16)
	controls.add_theme_color_override("font_color", Color.WHITE)
	add_child(controls)

func update_player_count(count: int):
	var controls = get_node_or_null("ControlLabel")
	if controls:
		controls.text = "%d Players Selected - Press SPACE to start" % count

func show_game_ui(players: Array):
	# Clear start menu
	for child in get_children():
		child.queue_free()
	
	# Create player status indicators
	for i in range(players.size()):
		var player_info = VBoxContainer.new()
		player_info.position = Vector2(20, 20 + i * 50)
		
		var top_row = HBoxContainer.new()
		player_info.add_child(top_row)
		
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(20, 20)
		color_rect.color = players[i].player_color
		top_row.add_child(color_rect)
		
		var label = Label.new()
		label.text = " P%d" % (i + 1)
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", players[i].player_color)
		top_row.add_child(label)
		
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
			health_bar.value = new_val
			health_bar.max_value = max_val
		)
		
		add_child(player_info)
		player_labels.append(player_info)
