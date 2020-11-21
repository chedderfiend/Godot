extends Node2D

onready var Player = load("res://player/GenericPlayer.tscn")

func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pass
	
puppet func spawn_player(spawn_pos, id):
	var player = Player.instance()
	
	#spawn_pos = Vector2(1500,600)
	player.position = spawn_pos
	player.name = String(id) # Important
	player.set_network_master(id) # Important
	$Players.add_child(player)
	
	
