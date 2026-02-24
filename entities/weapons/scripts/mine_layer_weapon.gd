extends Weapon
class_name MineLayerWeapon

const MINE_SCENE := preload("res://entities/weapons/deployables/mine.tscn")

func _spawn_projectile(from_position: Vector2, direction: Vector2):
	var mine = MINE_SCENE.instantiate()
	get_tree().root.add_child(mine)

	mine.mine_color = weapon_color
	mine.explosion_damage = damage
	mine.explosion_force = projectile_knockback
	mine.explosion_radius = 120.0

	# Place slightly in front and below the player's hands so it lands on the ground.
	var place_pos := from_position + (direction.normalized() * 16.0) + Vector2(0, 16)
	mine.place_mine(place_pos, owner_player)
