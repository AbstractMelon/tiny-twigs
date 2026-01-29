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
		flame.lifetime = projectile_lifetime
		flame.knockback_force = projectile_knockback
		flame.scale = Vector2(0.7, 0.7)
		
		# Visual flare for flames: Grow and fade
		var tween = flame.create_tween()
		tween.set_parallel(true)
		tween.tween_property(flame, "scale", Vector2(2.5, 2.5), projectile_lifetime)
		tween.tween_property(flame, "modulate:a", 0.0, projectile_lifetime)
		tween.finished.connect(flame.queue_free)
