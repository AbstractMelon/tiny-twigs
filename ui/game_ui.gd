extends CanvasLayer

# UI overlay for player info and game state

@onready var game_hud = $GameHUD
@onready var player_status_list = $GameHUD/PlayerStatusList

var player_labels: Array = []

func _ready():
	game_hud.hide()

func show_game_ui(players: Array):
	game_hud.show()
	
	# Clear existing status indicators
	for child in player_status_list.get_children():
		child.queue_free()
	player_labels = []
	
	# Create player status indicators
	for i in range(players.size()):
		var player_info = VBoxContainer.new()
		player_status_list.add_child(player_info)
		
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
		
		player_labels.append(player_info)
