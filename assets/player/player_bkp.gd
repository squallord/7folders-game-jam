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
	elif Input.is_action_just_pressed("ui_punch"):
		pass
	elif Input.is_action_pressed("ui_jump"):
		_animated_sprite.play("Jump")
	elif Input.is_action_just_pressed("ui_slash"):
		_animated_sprite.play("Slash")
	elif Input.is_action_just_pressed("ui_heavy_slash"):
		_animated_sprite.play("Up_Slash")
	else:
		_animated_sprite.play("Idle")
	pass
