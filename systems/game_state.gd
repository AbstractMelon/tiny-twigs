extends Node

# Persistent game state to share between menu and game scene

var num_players: int = 4
# pid -> scheme_id
var player_schemes: Dictionary = {1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6}

# pid -> wins
var player_wins: Dictionary = {}

const PLAYER_COLORS = [
	Color.CYAN,      # Player 1
	Color.MAGENTA,   # Player 2
	Color.YELLOW,    # Player 3
	Color.LIME,      # Player 4
	Color.ORANGE,    # Player 5
	Color.HOT_PINK   # Player 6
]


func reset_wins() -> void:
	player_wins.clear()
	for pid in range(1, num_players + 1):
		player_wins[pid] = 0


func add_win(player_id: int) -> void:
	player_wins[player_id] = int(player_wins.get(player_id, 0)) + 1


func get_wins(player_id: int) -> int:
	return int(player_wins.get(player_id, 0))
