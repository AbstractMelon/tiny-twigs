extends AnimatableBody2D
class_name MovingPlatform

@export var platform_width: float = 180.0:
	set(value):
		platform_width = max(value, 40.0)
		_apply_geometry()

@export var platform_height: float = 10.0:
	set(value):
		platform_height = clamp(value, 4.0, 40.0)
		_apply_geometry()

@export var line_color: Color = Color(0.4, 1.0, 1.0, 1.0):
	set(value):
		line_color = value
		_apply_visuals()

@export var glow_color: Color = Color(0.0, 1.0, 1.0, 0.15):
	set(value):
		glow_color = value
		_apply_visuals()

@export var line_width: float = 3.0:
	set(value):
		line_width = clamp(value, 1.0, 12.0)
		_apply_visuals()

@export var glow_width: float = 12.0:
	set(value):
		glow_width = clamp(value, 2.0, 40.0)
		_apply_visuals()

@export var movement_offset: Vector2 = Vector2(260, 0)
@export_range(0.2, 20.0, 0.1) var period: float = 3.5
@export var phase: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var glow_line: Line2D = $Glow
@onready var platform_line: Line2D = $Line

var _start_pos: Vector2
var _time: float = 0.0

func _ready() -> void:
	_start_pos = position
	_apply_geometry()
	_apply_visuals()

func _physics_process(delta: float) -> void:
	_time += delta
	if period <= 0.0:
		return
	var omega := TAU / period
	var a := (sin((_time + phase) * omega) + 1.0) * 0.5
	position = _start_pos + (movement_offset * (a - 0.5) * 2.0)

func _apply_geometry() -> void:
	if not is_node_ready():
		return
	if collision_shape and collision_shape.shape is RectangleShape2D:
		(collision_shape.shape as RectangleShape2D).size = Vector2(platform_width, platform_height)
	var half := platform_width * 0.5
	if glow_line:
		glow_line.points = PackedVector2Array([Vector2(-half, 0), Vector2(half, 0)])
	if platform_line:
		platform_line.points = PackedVector2Array([Vector2(-half, 0), Vector2(half, 0)])

func _apply_visuals() -> void:
	if not is_node_ready():
		return
	if glow_line:
		glow_line.default_color = glow_color
		glow_line.width = glow_width
	if platform_line:
		platform_line.default_color = line_color
		platform_line.width = line_width
