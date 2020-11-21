extends Node

var current_turn = 0
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

remote func change_turn():
	current_turn += 1
	var next_index =  current_turn % get_node("/root/GenericWorld/Players").get_child_count()
	var next_player = get_node("/root/GenericWorld/Players").get_child(next_index)
	rpc("start_turn",next_player.name)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _start_turn(starting_player):
	rpc("start_turn",starting_player)
