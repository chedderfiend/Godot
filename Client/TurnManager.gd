extends Node


func end_turn(generic_player):
	for unit in generic_player.get_children():
		if unit.has_method("_is_unit"):
			unit_handling.show_unit(unit)
	rpc_id(1,"change_turn")

func check_end_turn(generic_player):
	var turn_over = true
	for unit in generic_player.get_children():
		if unit.has_method("_is_unit"):
			if unit.used == false and unit.alive == true:
				turn_over = false
	if turn_over == true:
		end_turn(generic_player)

puppet func start_turn(starting_player):
	var generic_player = get_node("/root/GenericWorld/Players/"+str(starting_player))
	var starting_player_id = generic_player.get_network_master()
	for unit in generic_player.get_children():
		if unit.has_method("_is_unit"):
			unit_handling.free_unit(unit)
	var player_name = str(gamestate.players[starting_player_id])
	var my_id = str(get_tree().get_network_unique_id())
	print(my_id)
	get_node("/root/GenericWorld/Players/"+my_id+"/GenericGUI/Turn").text = player_name+"'s  Turn"
	
		
