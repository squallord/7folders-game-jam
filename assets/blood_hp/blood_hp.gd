extends Node2D

@export var amplitude : float = 2.5
@export var frequency : float = 1
@export var phase : float = 0

@onready var _blood_hp = $Animation

var offset_position : Vector2 = Vector2.ZERO
var phase_offset_x : float = PI / 2
var phase_offset_y : float = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	_blood_hp.play("LiveBlood")
	phase_offset_y = randf_range(0, 2 * PI)
	phase_offset_x = randf_range(0, 2 * PI)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	phase += delta
	self.position.y = sin(phase * frequency + phase_offset_y) * amplitude + offset_position.y
	self.position.x = sin(phase * frequency +  phase_offset_x) * amplitude + offset_position.x
