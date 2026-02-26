extends Projectile
class_name ShockwaveProjectile

@export var stun_duration: float = 0.8
@export var impact_damage: int = 6
@export var knockback_multiplier: float = 1.35

func _ready():
	damage = impact_damage
	super._ready()

func _on_body_entered(body):
	if body is Player and body != shooter:
		var knockback = velocity.normalized() * knockback_force * knockback_multiplier
		body.take_damage(damage, knockback)
		if body.has_method("apply_stun"):
			body.apply_stun(stun_duration, knockback)
		_explode()
	elif body is TileMap or body is StaticBody2D:
		_explode()
