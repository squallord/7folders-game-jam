extends CharacterBody2D


@export var walk_speed : float = 50.0
@export var run_speed : float = 150.0
@export var jump_velocity : float = -200.0

@onready var _animated_sprite = $AnimatedSprite2D
@onready var _timer = $Timer
@onready var _hitbox = $Hitbox/CollisionShape2D
@onready var _death_timer = $DeathTimer


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var _random_walk : float = randf_range(-1, 1)
var _player : CharacterBody2D = null
var _player_chase : bool = false
var _char_flipped : bool = false
var _triggered_death_animation : bool = false
var _death_flash_counter : int = 0

signal trigger_enemy_death


func _physics_process(delta):
	
	if not _triggered_death_animation:
		if not is_on_floor():
			velocity.y += gravity * delta

		var direction = _get_direction()
		var speed = walk_speed
		if direction:
			if _player_chase:
				_animated_sprite.play("Run")
				speed = run_speed
			else:
				_animated_sprite.play("Walk")
				speed = walk_speed
			if direction < 0:
				_animated_sprite.flip_h = false
				if _char_flipped:
					_hitbox.position.x = -_hitbox.position.x
				_char_flipped = false
			elif direction > 0:
				_animated_sprite.flip_h = true
				if not _char_flipped:
					_hitbox.position.x = -_hitbox.position.x
				_char_flipped = true
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			
		if velocity.x == 0:
			_animated_sprite.play("Idle")
			
		_update_enemy_chase()
		move_and_slide()
	
	else:
		_hitbox.disabled = true
		_animated_sprite.play("Idle")
		if _death_flash_counter % 4 == 0:
			self.modulate = Color(1.0, 0.25, 0.25, 0.25)
		elif _death_flash_counter % 4 == 2:
			self.modulate = Color(1.0, 0.25, 0.25, 1.0)
		_death_flash_counter += 1
	
func _get_direction():
	if _player_chase:
		return sign(_player.position.x - self.position.x)
	else:
		return _random_walk
	

func _update_enemy_chase():
	if _player and not _player.is_knocked_back_state():
		_player_chase = true
	else:
		_player_chase = false

func _on_timer_timeout():
	_random_walk = randi_range(-1, 1)


func _on_detection_area_body_entered(body):
	_player = body
	print("on body entered")


func _on_detection_area_body_exited(body):
	_player = null
	_player_chase = false
	print("on body exited")


func _on_hitbox_body_entered(body):
	if body.has_method("is_player_invulnerable"):
		if not body.is_player_invulnerable():
			body.takes_damage(self.position)
		body.start_invulnerability_frames()

func enemy_death():
	_death_timer.start()
	_triggered_death_animation = true
	print("started death timer!")
	
func is_dead():
	return _triggered_death_animation

func _on_death_timer_timeout():
	self.queue_free()

