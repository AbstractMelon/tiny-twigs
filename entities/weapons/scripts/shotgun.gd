extends Weapon
class_name ShotgunWeapon

const PELLET_COUNT = 8
const SPREAD_ANGLE = 30.0


func _spawn_projectile(from_position: Vector2, direction: Vector2):
	var base_angle = direction.angle()
	var spawn_offset = direction * 24
	
	for i in range(PELLET_COUNT):
		var spread = deg_to_rad(randf_range(-SPREAD_ANGLE, SPREAD_ANGLE))
		var pellet_angle = base_angle + spread
		var pellet_direction = Vector2.RIGHT.rotated(pellet_angle)
		
		var projectile = projectile_scene.instantiate()
		get_tree().root.add_child(projectile)
		projectile.initialize(from_position + spawn_offset, pellet_direction, projectile_speed, owner_player)
		projectile.projectile_color = weapon_color
		projectile.damage = damage
