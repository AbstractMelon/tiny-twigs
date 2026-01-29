extends Weapon
class_name RailGun

const PIERCE_COUNT = 3  # Number of enemies it can pierce


func _spawn_projectile(from_position: Vector2, direction: Vector2):
	var rail_shot = projectile_scene.instantiate()
	get_tree().root.add_child(rail_shot)
	
	var spawn_offset = direction * 30
	rail_shot.initialize(from_position + spawn_offset, direction, projectile_speed, owner_player)
	rail_shot.projectile_color = weapon_color
	rail_shot.damage = damage
	rail_shot.lifetime = projectile_lifetime
	rail_shot.knockback_force = projectile_knockback
	
	# Make it thinner and longer
	rail_shot.scale = Vector2(4, 0.5)
	
	# Create muzzle flash effect
	_create_muzzle_flash(from_position + spawn_offset, direction)

func _create_muzzle_flash(flash_position: Vector2, direction: Vector2):
	var flash = Line2D.new()
	flash.position = flash_position
	flash.points = PackedVector2Array([Vector2.ZERO, direction * 40])
	flash.width = 8.0
	flash.default_color = weapon_color
	flash.modulate.a = 0.8
	
	get_tree().root.add_child(flash)
	
	# Fade out quickly
	var tween = flash.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.15)
	tween.finished.connect(flash.queue_free)
