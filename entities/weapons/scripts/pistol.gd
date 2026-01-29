extends Weapon
class_name PistolWeapon


func _spawn_projectile(from_position: Vector2, direction: Vector2):
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	
	var spawn_offset = direction * 20  # Spawn in front of player
	projectile.initialize(from_position + spawn_offset, direction, projectile_speed, owner_player)
	projectile.projectile_color = weapon_color
	projectile.lifetime = projectile_lifetime
	projectile.knockback_force = projectile_knockback
