extends Node

# Persistent game state to share between menu and game scene

var num_players: int = 4
# pid -> scheme_id
var player_schemes: Dictionary = {1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6}

const PLAYER_COLORS = [
	Color.CYAN,      # Player 1
	Color.MAGENTA,   # Player 2
	Color.YELLOW,    # Player 3
	Color.LIME,      # Player 4
	Color.ORANGE,    # Player 5
	Color.HOT_PINK   # Player 6
]
