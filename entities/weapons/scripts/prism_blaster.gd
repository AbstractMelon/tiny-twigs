extends Weapon
class_name PrismBlaster

const BOLT_COUNT := 3
const SPREAD_DEG := 7.0

func _spawn_projectile(from_position: Vector2, direction: Vector2):
	if projectile_scene == null:
		return

	var base_angle := direction.angle()
	var spawn_offset := direction.normalized() * 24.0

	var colors := [
		weapon_color,
		weapon_color.lerp(Color.WHITE, 0.45),
		weapon_color.lerp(Color.BLACK, 0.15),
	]

	for i in range(BOLT_COUNT):
		var t := 0.0
		if BOLT_COUNT > 1:
			t = float(i) / float(BOLT_COUNT - 1)
		var spread := deg_to_rad(lerp(-SPREAD_DEG, SPREAD_DEG, t))
		var bolt_dir := Vector2.RIGHT.rotated(base_angle + spread)

		var projectile = projectile_scene.instantiate()
		get_tree().root.add_child(projectile)
		projectile.initialize(from_position + spawn_offset, bolt_dir, projectile_speed, owner_player)
		projectile.projectile_color = colors[i]
		projectile.damage = damage
		projectile.lifetime = projectile_lifetime
		projectile.knockback_force = projectile_knockback
