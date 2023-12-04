extends Node2D

var _player : CharacterBody2D = null

func _ready():
	_player = self.get_tree().get_nodes_in_group("Player")[0]


func _process(delta):
	pass


func _on_area_2d_body_entered(body):
	get_tree().quit()
