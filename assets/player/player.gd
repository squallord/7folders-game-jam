extends CharacterBody2D


@export var speed : float = 100.0
@export var knockback_damping_speed : float = 4.0
@export var jump_velocity : float = -200.0
@export var double_jump_velocity : float = -150.0

@onready var _animated_sprite = $AnimatedSprite2D
@onready var _state_label = $DebugState
@onready var _slash_hitbox = $SwordHitbox/SlashHitbox
@onready var _hurt_cooldown = $HurtCooldown

const _state_text : String = "State: "
const _blood_hp_pool = preload("res://assets/blood_hp/blood_hp.tscn")

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var _has_double_jump : bool = false
var _is_lock_attack_state : bool = false
var _char_flipped : bool = false
var _hp_pool_flipped : bool = false
var _enemy : CharacterBody2D = null

const _max_blood_amount : int = 3

var _blood_amount : int = 1
var _blood_initial_position : Vector2 = self.position + Vector2(-10, -10)
var _hp_pool = []
var _is_player_invulnerable : bool = false
var _is_knocked_back_state : bool = false
var _invulnerability_flash_counter : int = 0

signal killed_an_enemy

func _ready():
	self.add_to_group("Player")
	for i in range(_blood_amount):
		_add_blood_hp(i)
		
func _add_blood_hp(index):
	var blood = _blood_hp_pool.instantiate()
	blood.offset_position = _blood_initial_position + index * Vector2(-1, 1)
	self.add_child(blood)
	_hp_pool.append(blood)
	print("blood hp added!")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		if not _is_player_invulnerable:
			_state_label.text = _state_text + "Jump"
		velocity.y += gravity * delta
		if not _is_lock_attack_state:
			if velocity.y <= 0:
				_animated_sprite.play("Jump")
			else:
				_animated_sprite.play("Fall")

	# Handle Jump.
	if not _is_knocked_back_state:
		if is_on_floor():
			_has_double_jump = true
			if Input.is_action_just_pressed("jump"):
				velocity.y = jump_velocity
		elif _has_double_jump and Input.is_action_just_pressed("jump"):
			velocity.y = double_jump_velocity
			_has_double_jump = false

	if not _is_lock_attack_state:
		if Input.is_action_just_pressed("slash"):
			_state_label.text = _state_text + "Slash"
			_animated_sprite.play("Slash")
			_is_lock_attack_state = true
			_slash_hitbox.disabled = false
		elif Input.is_action_just_pressed("heavy_slash"):
			_state_label.text = _state_text + "HSlash"
			_animated_sprite.play("Up_Slash")
			_is_lock_attack_state = true
			_slash_hitbox.disabled = false
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("left", "right")
	if not _is_knocked_back_state:
		if direction:
			velocity.x = direction * speed
			if is_on_floor() && not _is_lock_attack_state:
				if abs(velocity.x) > 0:
					_state_label.text = _state_text + "Walk"
					_animated_sprite.play("Walk")
			
			if direction > 0:
				_animated_sprite.flip_h = false
				if _char_flipped:
					_slash_hitbox.position.x = -_slash_hitbox.position.x
				_char_flipped = false
			elif direction < 0:
				_animated_sprite.flip_h = true
				if not _char_flipped:
					_slash_hitbox.position.x = -_slash_hitbox.position.x
				_char_flipped = true
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			if is_on_floor() and velocity.x == 0 && not _is_lock_attack_state:
				_state_label.text = _state_text + "Idle"
				_animated_sprite.play("Idle")

	if _is_knocked_back_state and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, knockback_damping_speed)

	_update_blood_hp_location()
	_update_player_graphics()
	move_and_slide()

func _update_blood_hp_location():
	if _char_flipped:
		if not _hp_pool_flipped:
			for hp in _hp_pool:
				hp.offset_position.x = -hp.offset_position.x
		_hp_pool_flipped = true
	else:
		if _hp_pool_flipped:
			for hp in _hp_pool:
				hp.offset_position.x = -hp.offset_position.x
		_hp_pool_flipped = false

func _update_player_graphics():
	if _is_player_invulnerable:
		if _invulnerability_flash_counter % 4 == 0:
			self.modulate = Color(1.0, 1.0, 1.0, 0.25)
		elif _invulnerability_flash_counter % 4 == 2:
			self.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_invulnerability_flash_counter += 1
	else:
		self.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_invulnerability_flash_counter = 0

func _on_animated_sprite_2d_animation_finished():
	_is_lock_attack_state = false
	_slash_hitbox.disabled = true


func _on_sword_hitbox_body_entered(body):
	if body.has_method("enemy_death") and not body.is_dead():
		_enemy = body
		_enemy.enemy_death()
		emit_signal("killed_an_enemy")
		if _blood_amount < _max_blood_amount:
			_blood_amount += 1
			_add_blood_hp(_blood_amount)
		print("enemy slashed!")
	if body.has_method("turn_into_fade") and body.is_invading():
		body.turn_into_fade()
		print("shadow doom turned back into fade...")

func _on_sword_hitbox_body_exited(body):
	_enemy = null
	print("finished slashing")

func takes_damage(position: Vector2):
	print("damage taken!")
	var knock_back_direction = _get_knock_back_direction(position)
	velocity = knock_back_direction * 200
	_is_knocked_back_state = true
	if not _hp_pool.is_empty():
		var blood_hp = _hp_pool.pop_back()
		_blood_amount -= 1
		blood_hp.queue_free()
	else:
		self.queue_free()
		get_tree().quit()

func _get_knock_back_direction(position):
	return (Vector2(self.position.x - position.x, 0).normalized()+ Vector2.UP).normalized()

func start_invulnerability_frames():
	_hurt_cooldown.start()
	_is_player_invulnerable = true
	_state_label.text = _state_text + "Invulnerable"

func is_player_invulnerable():
	return _is_player_invulnerable

func _on_hurt_cooldown_timeout():
	_is_player_invulnerable = false
	_is_knocked_back_state = false

func is_knocked_back_state():
	return _is_knocked_back_state
	
func is_char_flipped():
	return _char_flipped
