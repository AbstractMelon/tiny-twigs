extends Weapon
class_name FlameWeapon

# Short-range flamethrower that creates fire zones

const FLAME_RANGE = 150.0
const FLAME_WIDTH = 60.0


func _spawn_projectile(from_position: Vector2, direction: Vector2):
	# Spawn multiple flame particles in a cone
	for i in range(3):
		var spread = deg_to_rad(randf_range(-15, 15))
		var flame_direction = direction.rotated(spread)
		
		var flame = projectile_scene.instantiate()
		get_tree().root.add_child(flame)
		
		var spawn_offset = direction * 22
		flame.initialize(from_position + spawn_offset, flame_direction, projectile_speed, owner_player)
		flame.projectile_color = weapon_color
		flame.damage = damage
		flame.lifetime = 0.4  # Short-lived flames
		flame.scale = Vector2(0.7, 0.7)
