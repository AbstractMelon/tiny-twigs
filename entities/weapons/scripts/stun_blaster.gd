extends Weapon
class_name StunBlasterWeapon

func _spawn_projectile(_from_position: Vector2, direction: Vector2):
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)

	var fire_pos = muzzle.global_position
	projectile.initialize(fire_pos, direction, projectile_speed, owner_player)
	projectile.projectile_color = weapon_color
	projectile.lifetime = projectile_lifetime
	projectile.knockback_force = projectile_knockback
	projectile.damage = damage
