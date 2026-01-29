extends Node
class_name InputManager

# Input configuration for 6 players on a single keyboard
# Each player gets: movement (left/right), jump, shoot, block, drop

const SCHEMES = {
	1: {
		"name": "WASD + QE",
		"keys": [KEY_A, KEY_D, KEY_W, KEY_S, KEY_Q, KEY_E],
		"display": "A/D, W, S, Q, E"
	},
	2: {
		"name": "IJKL + UO",
		"keys": [KEY_J, KEY_L, KEY_I, KEY_K, KEY_U, KEY_O],
		"display": "J/L, I, K, U, O"
	},
	3: {
		"name": "Arrows + ,.",
		"keys": [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_COMMA, KEY_PERIOD],
		"display": "←/→, ↑, ↓, , , ."
	},
	4: {
		"name": "TFGH + RY",
		"keys": [KEY_F, KEY_H, KEY_T, KEY_G, KEY_R, KEY_Y],
		"display": "F/H, T, G, R, Y"
	},
	5: {
		"name": "Numpad 4685 + 79",
		"keys": [KEY_KP_4, KEY_KP_6, KEY_KP_8, KEY_KP_5, KEY_KP_7, KEY_KP_9],
		"display": "N4/6, N8, N5, N7, N9"
	},
	6: {
		"name": "ZXCV + MB",
		"keys": [KEY_Z, KEY_C, KEY_X, KEY_V, KEY_M, KEY_B],
		"display": "Z/C, X, V, M, B"
	}
}

static func setup_input_maps(player_scheme_mapping: Dictionary = {}):
	# Clear existing actions if they exist
	_clear_player_actions()
	
	# If no mapping provided, use defaults
	if player_scheme_mapping.is_empty():
		for i in range(1, 7):
			player_scheme_mapping[i] = i
	
	# Setup each player according to the mapping
	for player_id in player_scheme_mapping:
		var scheme_id = player_scheme_mapping[player_id]
		if SCHEMES.has(scheme_id):
			var s = SCHEMES[scheme_id]
			var keys = s.keys
			_setup_player_input(player_id, keys[0], keys[1], keys[2], keys[3], keys[4], keys[5])

static func _clear_player_actions():
	for i in range(1, 7):
		var actions = [
			"p%d_left" % i,
			"p%d_right" % i,
			"p%d_jump" % i,
			"p%d_shoot" % i,
			"p%d_block" % i,
			"p%d_drop" % i
		]
		for action in actions:
			if InputMap.has_action(action):
				InputMap.erase_action(action)

static func _setup_player_input(player_id: int, left_key: int, right_key: int, 
								jump_key: int, down_key: int, 
								block_key: int, drop_key: int):
	var prefix = "p%d_" % player_id
	
	var mappings = [
		["left", left_key],
		["right", right_key],
		["jump", jump_key],
		["shoot", down_key],
		["block", block_key],
		["drop", drop_key]
	]
	
	for m in mappings:
		var action = prefix + m[0]
		InputMap.add_action(action)
		var event = InputEventKey.new()
		event.keycode = m[1]
		InputMap.action_add_event(action, event)

static func get_control_scheme_text(scheme_id: int) -> String:
	if SCHEMES.has(scheme_id):
		return SCHEMES[scheme_id].display
	return "Unknown"

static func get_scheme_name(scheme_id: int) -> String:
	if SCHEMES.has(scheme_id):
		return SCHEMES[scheme_id].name
	return "None"
