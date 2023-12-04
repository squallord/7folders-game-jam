extends Node2D

const _hellhound_scene = preload("res://assets/enemies/hellhound/hellhound.tscn")
@export var enemy_type : EnemyType
@export var number_of_enemies : int = 1

var _enemies_spawned : bool = false

enum EnemyType {
	hellhound
}

func _ready():
	pass

func _process(delta):
	if not _enemies_spawned:
		for i in range(number_of_enemies):
			_spawn_enemy()
		_enemies_spawned = true

func _spawn_enemy():
	if enemy_type == EnemyType.hellhound:
		var hellhound = _hellhound_scene.instantiate()
		hellhound.position = self.position
		self.get_parent().add_child(hellhound)
		#self.get_tree().root.add_child(hellhound)
		print("hellhound enemy spawned at position" + str(hellhound.position) + "!")
