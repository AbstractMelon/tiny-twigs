extends Weapon
class_name RocketLauncher


func _spawn_projectile(from_position: Vector2, direction: Vector2):
	var rocket = projectile_scene.instantiate()
	get_tree().root.add_child(rocket)
	
	var spawn_offset = direction * 28
	rocket.initialize(from_position + spawn_offset, direction, projectile_speed, owner_player)
	rocket.projectile_color = weapon_color
	rocket.damage = damage
	rocket.knockback_force = 1000.0  # Much stronger knockback
	
	# Make rocket larger
	rocket.scale = Vector2(2, 2)
