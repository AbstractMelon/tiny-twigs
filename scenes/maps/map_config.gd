extends Node2D
class_name MapConfig

@export var gravity_scale: float = 1.0

func get_gravity_scale_value() -> float:
	return max(gravity_scale, 0.05)
