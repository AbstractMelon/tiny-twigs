extends Weapon
class_name BurstRifle

const BURST_COUNT = 3
const BURST_DELAY = 0.1

func fire(from_position: Vector2, direction: Vector2) -> bool:
	if not can_fire:
		return false
	
	if ammo == 0:
		return false
	
	can_fire = false
	_handle_burst(from_position, direction)
	return true

func _handle_burst(from_position: Vector2, direction: Vector2):
	for i in range(BURST_COUNT):
		if ammo > 0:
			_spawn_projectile(from_position, direction)
			ammo -= 1
		await get_tree().create_timer(BURST_DELAY).timeout
	
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true

func _spawn_projectile(from_position: Vector2, direction: Vector2):
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	
	# Add slight spread to burst
	var spread = deg_to_rad(randf_range(-2, 2))
	var spread_direction = direction.rotated(spread)
	
	var spawn_offset = spread_direction * 26
	projectile.initialize(from_position + spawn_offset, spread_direction, projectile_speed, owner_player)
	projectile.projectile_color = weapon_color
	projectile.damage = damage
