extends Node
class_name InputManager

# Input configuration for 6 players on a single keyboard
# Each player gets: movement (left/right), jump, shoot, block, drop

static func setup_input_maps():
	# Clear existing actions if they exist
	_clear_player_actions()
	
	# Player 1: WASD + QE
	_setup_player_input(1, KEY_A, KEY_D, KEY_W, KEY_S, KEY_Q, KEY_E)
	
	# Player 2: IJKL + UO
	_setup_player_input(2, KEY_J, KEY_L, KEY_I, KEY_K, KEY_U, KEY_O)
	
	# Player 3: Arrow Keys + , .
	_setup_player_input(3, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_COMMA, KEY_PERIOD)
	
	# Player 4: TFGH + RY
	_setup_player_input(4, KEY_F, KEY_H, KEY_T, KEY_G, KEY_R, KEY_Y)
	
	# Player 5: Numpad 4685 + 79
	_setup_player_input(5, KEY_KP_4, KEY_KP_6, KEY_KP_8, KEY_KP_5, KEY_KP_7, KEY_KP_9)
	
	# Player 6: ZXCV + MB
	_setup_player_input(6, KEY_Z, KEY_C, KEY_X, KEY_V, KEY_M, KEY_B)

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
	
	# Left
	var action_left = prefix + "left"
	InputMap.add_action(action_left)
	var event_left = InputEventKey.new()
	event_left.keycode = left_key
	InputMap.action_add_event(action_left, event_left)
	
	# Right
	var action_right = prefix + "right"
	InputMap.add_action(action_right)
	var event_right = InputEventKey.new()
	event_right.keycode = right_key
	InputMap.action_add_event(action_right, event_right)
	
	# Jump
	var action_jump = prefix + "jump"
	InputMap.add_action(action_jump)
	var event_jump = InputEventKey.new()
	event_jump.keycode = jump_key
	InputMap.action_add_event(action_jump, event_jump)
	
	# Shoot (use down key as shoot)
	var action_shoot = prefix + "shoot"
	InputMap.add_action(action_shoot)
	var event_shoot = InputEventKey.new()
	event_shoot.keycode = down_key
	InputMap.action_add_event(action_shoot, event_shoot)
	
	# Block
	var action_block = prefix + "block"
	InputMap.add_action(action_block)
	var event_block = InputEventKey.new()
	event_block.keycode = block_key
	InputMap.action_add_event(action_block, event_block)
	
	# Drop
	var action_drop = prefix + "drop"
	InputMap.add_action(action_drop)
	var event_drop = InputEventKey.new()
	event_drop.keycode = drop_key
	InputMap.action_add_event(action_drop, event_drop)

static func get_control_scheme_text(player_id: int) -> String:
	match player_id:
		1: return "P1: A/D=Move W=Jump S=Shoot Q=Block E=Drop"
		2: return "P2: J/L=Move I=Jump K=Shoot U=Block O=Drop"
		3: return "P3: ←/→=Move ↑=Jump ↓=Shoot ,=Block .=Drop"
		4: return "P4: F/H=Move T=Jump G=Shoot R=Block Y=Drop"
		5: return "P5: Num4/6=Move Num8=Jump Num5=Shoot Num7=Block Num9=Drop"
		6: return "P6: Z/C=Move X=Jump V=Shoot M=Block B=Drop"
		_: return "Unknown player"
