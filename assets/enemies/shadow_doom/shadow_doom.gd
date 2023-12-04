extends CharacterBody2D


@export var walk_speed : float = 50.0
@export var run_speed : float = 150.0
@export var jump_velocity : float = -200.0
@export var fade_offset : Vector2 = Vector2(-20, -18)

@onready var _animated_sprite = $AnimatedSprite2D
@onready var _collision_shape = $CollisionShape2D
@onready var _timer = $Timer
@onready var _hitbox = $Hitbox/CollisionShape2D
@onready var _death_timer = $DeathTimer
@onready var _attack_cooldown = $AttackCooldown
@onready var _attack_startup = $AttackStartup


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var _random_walk : float = randf_range(-1, 1)
var _player : CharacterBody2D = null
var _player_chase : bool = false
var _char_flipped : bool = false
var _death_flash_counter : int = 0

var _fade_level : float = 0.25
var _fade_level_increment : float = 0.25
var _fade_level_changed : bool = false
var _fade_mode : bool = true

var _is_lock_attack_state : bool = false
var _attack_cooldown_finished : bool = true
var _player_in_attack_range : bool = false
var _attack_startup_finished : bool = false

signal trigger_enemy_death
signal damage_player

enum Orientation {
	LEFT,
	RIGHT
}

func _ready():
	self.modulate = Color(1.0, 1.0, 1.0, _fade_level)
	_player = self.get_tree().get_nodes_in_group("Player")[0]

func _physics_process(delta):
	
	if not _fade_mode:
		if not is_on_floor():
			velocity.y += gravity * delta
		
		var direction = _get_direction()
		var speed = walk_speed
		if not _is_lock_attack_state:
			if direction:
				if _player_chase:
					_animated_sprite.play("Run")
					speed = run_speed
				else:
					_animated_sprite.play("Walk")
					speed = walk_speed
				if direction < 0:
					_flip_char(Orientation.LEFT)
				elif direction > 0:
					_flip_char(Orientation.RIGHT)
				velocity.x = direction * speed
			else:
				velocity.x = move_toward(velocity.x, 0, speed)
				
			if velocity.x == 0:
				_animated_sprite.play("Idle")
				
			_update_enemy_chase()
			move_and_slide()
		
		#if _player_in_attack_range:
		#	_attack_player()
	
	else:
		if _player != null:
			_hitbox.disabled = true
			_collision_shape.disabled = true
			_animated_sprite.play("Idle")
			self.position = _player.position + fade_offset
			_update_fade_level()
	
func _get_direction():
	if _player_chase:
		return sign(_player.position.x - self.position.x)
	else:
		return _random_walk
	

func _flip_char(orientation):
	if orientation == Orientation.RIGHT:
		_animated_sprite.flip_h = false
		if _char_flipped:
			_hitbox.position.x = -_hitbox.position.x
		_char_flipped = false
	elif orientation == Orientation.LEFT:
		_animated_sprite.flip_h = true
		if not _char_flipped:
			_hitbox.position.x = -_hitbox.position.x
		_char_flipped = true

func _update_enemy_chase():
	if _player != null and not _player.is_knocked_back_state():
		_player_chase = true
	else:
		_player_chase = false

func _on_timer_timeout():
	_random_walk = randi_range(-1, 1)


func _on_detection_area_body_entered(body):
	print("player detected by shadow doom")


func _on_detection_area_body_exited(body):
	_player_chase = false
	print("shadow doom is not pursuing the player anymore")

#func _attack_player():
#	_is_lock_attack_state = true
#	if not _player.is_player_invulnerable() and _attack_cooldown_finished:
#		_attack_cooldown_finished = false
#		_animated_sprite.play("Attack")
#		if _attack_startup_finished:
#			_player.takes_damage(self.position)
#			_player.start_invulnerability_frames()

func _on_hitbox_body_entered(body):
	_is_lock_attack_state = true
	#_player_in_attack_range = true
	#_attack_startup_finished = false
	_animated_sprite.play("Attack")
	#_attack_startup.start()
	_attack_cooldown.start()
	_player.takes_damage(self.position)
	_player.start_invulnerability_frames()
	
func _on_hitbox_body_exited(body):
	_player_in_attack_range = false

func _on_attack_startup_timeout():
	_attack_startup_finished = true

func _on_attack_cooldown_timeout():
	_is_lock_attack_state = false
	_attack_cooldown_finished = true

func _on_death_timer_timeout():
	self.queue_free()

func _update_fade_level():
	if _fade_level_changed:
		_fade_level += _fade_level_increment
		self.modulate = Color(1.0, 1.0, 1.0, _fade_level)
		_fade_level_changed = false
		print("fade level increased!")
		if _fade_level == 1:
			_shadow_doom_invasion()

func _shadow_doom_invasion():
	self.modulate = Color(1.0, 1.0, 1.0, 1.0)
	self.position = _player.position + Vector2(200, -150)
	_hitbox.disabled = false
	_collision_shape.disabled = false
	_fade_mode = false
	
func turn_into_fade():
	_fade_level = 0.25
	if _char_flipped:
		_flip_char(Orientation.RIGHT)
	self.modulate = Color(1.0, 1.0, 1.0, _fade_level)
	_fade_mode = true
	
func is_invading():
	return not _fade_mode

func _on_player_killed_an_enemy():
	_fade_level_changed = true
	print("fade knows an enemy was killed...")
