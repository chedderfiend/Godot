extends Node

# Default game port
const DEFAULT_PORT = 8000

# Max number of players
const MAX_PLAYERS = 12

# Players dict stored as id:name
var players = {}
var ready_players = []
var server = WebSocketServer
var spawn_count = 0

#startpoints
var start_points = [Vector2(70,70),Vector2(1200,600),Vector2(70,600),Vector2(832,64)]


func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	
	create_server()

func _process(delta):
	if server.is_listening(): # is_listening is true when the server is active and listening
		server.poll();

func create_server():
	#var host = NetworkedMultiplayerENet.new()
	#host.create_server(DEFAULT_PORT, MAX_PLAYERS)
	#get_tree().set_network_peer(host)
	server = WebSocketServer.new()
	server.listen(DEFAULT_PORT, PoolStringArray(), true)
	get_tree().set_network_peer(server);
	print("server up")

# Callback from SceneTree, called when client connects
func _player_connected(_id):
	print("Client ", _id, " connected")

# Callback from SceneTree, called when client disconnects
func _player_disconnected(id):
	if ready_players.has(id):
		ready_players.erase(id)
		rpc("unregister_player", id)
	
	print("Client ", id, " disconnected")

remote func debug(mystring):
	print(mystring)
	
# Player management functions
remote func register_player(new_player_name):
	# We get id this way instead of as parameter, to prevent users from pretending to be other users
	var caller_id = get_tree().get_rpc_sender_id()
	
	# If game is going, just ignore new guy
	if not has_node("/root/GenericWorld"):
		# Add him to our list
		players[caller_id] = new_player_name
		
		# Add everyone to new player:
		for p_id in players:
			rpc_id(caller_id, "register_player", p_id, players[p_id]) # Send each player to new dude
		
		rpc("register_player", caller_id, players[caller_id]) # Send new dude to all players
		# NOTE: this means new player's register gets called twice, but fine as same info sent both times
		
		print("Client ", caller_id, " registered as ", new_player_name)

puppetsync func unregister_player(id):
	players.erase(id)
	print("Client ", id, " was unregistered")

remote func player_ready():
	var caller_id = get_tree().get_rpc_sender_id()

	if not ready_players.has(caller_id):
		ready_players.append(caller_id)

	if ready_players.size() == players.size():
		pre_start_game()

func pre_start_game():
	var world = load("res://GenericWorld.tscn").instance()
	get_tree().get_root().add_child(world)

	# Spawn all the people
	var x = 0
	for id in players:
		get_node("/root/GenericWorld").spawn_player(start_points[x], id)
		x +=1

	rpc("pre_start_game")


remote func post_start_game():
	
	var caller_id = get_tree().get_rpc_sender_id()
	var world = get_node("/root/GenericWorld")
	var starting_player = get_node("/root/GenericWorld/Players").get_child(0).name
	
	for player in world.get_node("Players").get_children():
		world.rpc_id(caller_id, "spawn_player", player.position, player.get_network_master())
	
	turnmanager._start_turn(starting_player)

# Return random 2D vector inside bounds 0, 0, bound_x, bound_y
func random_vector2(bound_x, bound_y):
	return Vector2(randf() * bound_x, randf() * bound_y)
