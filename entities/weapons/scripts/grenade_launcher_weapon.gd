extends Weapon
class_name GrenadeLauncherWeapon

const GRENADE_SCENE := preload("res://entities/weapons/deployables/grenade.tscn")

func _spawn_projectile(from_position: Vector2, direction: Vector2):
	var grenade = GRENADE_SCENE.instantiate()
	get_tree().root.add_child(grenade)

	# Map generic Weapon stats onto the grenade's parameters.
	grenade.grenade_color = weapon_color
	grenade.explosion_damage = damage
	grenade.explosion_force = projectile_knockback
	grenade.fuse_time = projectile_lifetime
	grenade.explosion_radius = 150.0

	var spawn_offset := direction * 22.0
	grenade.throw_grenade(from_position + spawn_offset, direction, projectile_speed, owner_player)
