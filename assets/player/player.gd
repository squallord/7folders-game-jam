extends CharacterBody2D

@onready var _animated_sprite = $AnimatedSprite2D

func _ready():
	pass


func _process(delta):
	if Input.is_action_pressed("ui_right"):
		_animated_sprite.flip_h = false
		_animated_sprite.play("Walk")
	elif Input.is_action_pressed("ui_left"):
		_animated_sprite.flip_h = true
		_animated_sprite.play("Walk")
	else:
		_animated_sprite.play("Idle")
	pass
