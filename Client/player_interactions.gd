extends Node2D

var _previousPosition = Vector2.ZERO
var _moveCamera = false
var waypoint = preload("res://assets/flag.tscn")
var attackline = preload("res://Weapons/attackline.tscn")
var target = preload("res://Weapons/Target.tscn")
var last_event_index
"""
this holds things the player interactions with like the camera, the lines, stuff htey do during their turn
"""
func pan(event, camera):
	#print("cam master"+str(camera.get_network_master()))
	#print(camera.is_network_master())
	if camera.is_network_master():
		if event.is_action_pressed("left_click"):
			_previousPosition = event.position
		if event is InputEventMouseMotion && Input.is_action_pressed("left_click"): # && event == last_event_index:
			camera.position += (_previousPosition - event.position)*camera.zoom.x;
			_previousPosition = event.position
func zoom(value, camera):
	if camera.is_network_master():
			camera.zoom.x = value
			camera.zoom.y = value

func line_intelligence(generic_unit):
	var last_pos = generic_unit.waypoints[generic_unit.waypoints.size()-1]
	var total_distance = generic_unit.waypoint_dist + last_pos.distance_to(get_global_mouse_position())
	if total_distance > unit_handling.unit_movement[generic_unit.unit_type]*generic_unit.movement_modifier:
		generic_unit.get_parent().waypoint_color = Color(0,0,0,1)
		generic_unit.get_parent().can_waypoint = false
		generic_unit.get_parent().ghost.global_position = last_pos
		
	else:
		generic_unit.get_parent().waypoint_color = Color(0.05,1,0,1)
		generic_unit.get_parent().can_waypoint = true

"""
SELECTION
"""
func remove_last_waypoint(generic_unit):
	generic_unit.get_node("Line2D").remove_point(generic_unit.get_node("Line2D").get_point_count()-1)

func deselect_unit(generic_player,generic_unit,generic_collision):
	all_toggles_off(generic_unit)
	generic_unit.get_node("Line2D").default_color = Color(0.05,1,0,1)
	if generic_player.movement_planning == true:
		remove_last_waypoint(generic_unit)
	if generic_player.attack_planning == true:
		generic_unit.attackline.queue_free()
		generic_unit.attackline = Line2D
		generic_player.attack_planning = false
	generic_collision.get_node("highlight").visible = false
	generic_player.selected_unit = CollisionShape2D
	generic_unit.get_node("HUD/Selector").visible = false
	kill_ghost(generic_player)
	if generic_unit.target != Sprite and generic_unit.target_lock == Vector2():
		generic_unit.target.queue_free()
		generic_unit.target = Sprite
	generic_player.movement_planning = false
	generic_player.attack_planning = false

func clear_target(generic_unit):
	if generic_unit.target != Sprite:
		generic_unit.target.queue_free()
		generic_unit.target = Sprite
	generic_unit.target_lock = Vector2()
		
func select_unit(highlight):
	var generic_collision = highlight.get_parent()
	var generic_unit = generic_collision.get_parent()
	var generic_player = generic_unit.get_parent()
	
	#deselect previous unit
	if generic_player.selected_unit != CollisionShape2D:
		#print(generic_player.selected_unit.name)
		var last_collision = generic_player.selected_unit
		var last_unit = last_collision.get_parent()
		deselect_unit(generic_player, last_unit, last_collision)
	
	
	#add the new one
	generic_player.selected_unit = generic_collision
	highlight.visible = true
	generic_unit.get_node("HUD/Selector").visible = true
	
	if generic_unit.waypoints.size()>1:
		create_ghost(generic_player,generic_unit.unit_type)
	
	#draw_empty_circle(highlight.get_global_position(),Vector2(0,200),Color(0.05,1,0,1),100)

"""
WAYPOINTS
"""

func clear_waypoints(generic_unit):
	generic_unit.waypoints.clear()
	generic_unit.waypoint_dist = 0
	for flag in generic_unit.flags:
		flag.queue_free()
	generic_unit.flags = []
	generic_unit.get_node("Line2D").clear_points()
	generic_unit.can_move = false

func set_waypoint(_event, collision_shape):
	var line = collision_shape.get_node("../Line2D")
	var new_position = get_global_mouse_position()
	var genericunit = collision_shape.get_node("..")
	var old_position = genericunit.waypoints[genericunit.waypoints.size()-1]
	var Waypoint = waypoint.instance()
	#add the distance
	genericunit.waypoint_dist += old_position.distance_to(new_position)
	#new point
	collision_shape.get_parent().waypoints.append(new_position)
	line.set_point_position(line.get_point_count()-1,new_position)
	line.add_point(get_global_mouse_position())
	collision_shape.get_node("../../..").add_child(Waypoint)
	genericunit.flags.append(Waypoint)
	Waypoint.set_global_position(new_position)
	genericunit.get_node("HUD/Selector").global_position = new_position


func pass_waypoint(generic_unit):
	if generic_unit.waypoints.size() <= generic_unit.flags.size():
		generic_unit.get_node("Line2D").remove_point(0)
		generic_unit.flags[0].queue_free()
		generic_unit.flags.pop_front()
	generic_unit.waypoints.pop_front()

"""
GHOST
"""

func create_ghost(generic_player, unit_type):
	var ghost = unit_handling.unit_sprite[unit_type]
	var Ghost = ghost.instance()
	var generic_unit = generic_player.selected_unit.get_parent()
	Ghost.modulate = Color(1,1,1,0.5)
	Ghost.z_index = 2
	#print(generic_unit.waypoints)
	#var last_waypoint = generic_unit.waypoints.size()-1
	var last_position = Vector2()
	if generic_unit.waypoints.size() == 0:
		last_position = generic_unit.global_position
	else:
		last_position = generic_unit.waypoints[generic_unit.waypoints.size()-1]
	#print(last_position)
	generic_player.add_child(Ghost)
	generic_player.ghost = Ghost
	Ghost.set_global_position(last_position)
	
func update_ghost(generic_unit,ghost):
	if generic_unit.get_parent().ghost != Sprite:
		if generic_unit.get_parent().can_waypoint == true and generic_unit.get_parent().movement_planning == true:
			ghost.global_position = get_global_mouse_position()
		ghost.rotation = (generic_unit.waypoints[generic_unit.waypoints.size()-1]-get_global_mouse_position()).angle()+deg2rad(90)
		#ghost.rotation = generic_unit.waypoints[generic_unit.waypoints.size()-1].get_angle_to(get_global_mouse_position())

func kill_ghost(generic_player):
	if generic_player.ghost != Sprite:
		generic_player.ghost.queue_free()
	generic_player.ghost = Sprite 

"""
PLANNING MOVEMENT/ATTACK
"""

func cancel_leave_selector(generic_unit):
	deselect_unit(generic_unit.get_parent(),generic_unit,generic_unit.Collision)
	clear_waypoints(generic_unit)
	clear_target(generic_unit)
	generic_unit.get_node("HUD/Selector").position = Vector2(0,0)
	select_unit(generic_unit.Collision.get_node("highlight"))

func cancel(generic_unit):
	deselect_unit(generic_unit.get_parent(),generic_unit,generic_unit.Collision)
	clear_waypoints(generic_unit)
	clear_target(generic_unit)
	generic_unit.get_node("HUD/Selector").position = Vector2(0,0)
	all_toggles_off(generic_unit)
	
func all_toggles_off(generic_unit):
	generic_unit.get_node("HUD/Selector").toggle_everything_off()

func start_movement_planning(generic_unit):
	var generic_player = generic_unit.get_parent()
	
	#cancel attacks if they exist
	if generic_unit.target != Sprite:
		generic_unit.target.queue_free()
		generic_unit.target = Sprite
		generic_unit.target_lock = Vector2()
		
	if generic_unit.flags.size() > 0:
		continue_movement_data(generic_unit)
	else:
		fresh_movement_data(generic_unit)
	if generic_player.ghost == Sprite:
		create_ghost(generic_player, generic_unit.unit_type)
	generic_player.movement_planning = true

func fresh_movement_data(generic_unit):
	generic_unit.get_node("Line2D").add_point(generic_unit.get_global_position())
	generic_unit.get_node("Line2D").add_point(generic_unit.get_global_position())
	if generic_unit.waypoints.size() == 0:
		generic_unit.waypoints.append(generic_unit.get_global_position())

func continue_movement_data(generic_unit):
	generic_unit.get_node("Line2D").add_point(generic_unit.get_global_position())

func end_movement_planning(generic_unit):
	generic_unit.get_node("Line2D").default_color = Color(0.05,1,0,1)
	var generic_player = generic_unit.get_parent()
	if generic_unit.get_node("Line2D").get_point_count()-1 == generic_unit.waypoints.size():
		remove_last_waypoint(generic_unit)
	generic_player.movement_planning = false
	generic_player.can_waypoint = false
	send_ghost_to_waypoint(generic_unit)
	
func send_ghost_to_waypoint(generic_unit):
	var ghost_position = Vector2(0,0)
	if generic_unit.waypoints.size() == 0:
		ghost_position = generic_unit.global_position
	else:
		ghost_position = generic_unit.waypoints[generic_unit.waypoints.size()-1]
	generic_unit.get_parent().ghost.set_global_position(ghost_position)
	

func plan_attack(generic_unit):	
	generic_unit.get_parent().attack_planning = true
	
	#generic_unit.get_node("Line2D").default_color = Color(0.05,1,0,1)
	#make the attack line
	var Attackline = attackline.instance()
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1,0,0,1))
	gradient.set_color(1, Color(1,0,0,1))
	var attack_start = Vector2()
	if generic_unit.waypoints.size() == 0:
		generic_unit.waypoints.append(generic_unit.global_position)
	attack_start = generic_unit.waypoints[generic_unit.waypoints.size()-1]
	Attackline.add_point(attack_start)
	Attackline.add_point(get_global_mouse_position())
	Attackline.set_gradient(gradient)
	generic_unit.add_child(Attackline)
	generic_unit.attackline = Attackline
	#make target
	if generic_unit.target_lock != Vector2():
		generic_unit.target_lock == Vector2()
	if generic_unit.target != Sprite:
		generic_unit.target.queue_free()
		generic_unit.target = Sprite
	var Target = target.instance()
	generic_unit.add_child(Target)
	generic_unit.target = Target
	Target.global_position=get_global_mouse_position()
	#kill the ghost and clear the movement
	if generic_unit.get_parent().ghost == Sprite:
		create_ghost(generic_unit.get_parent(),generic_unit.unit_type)
	send_ghost_to_waypoint(generic_unit)

remotesync func start_defend(generic_unit_path):
	var generic_unit= get_node(generic_unit_path)
	generic_unit.defense_modifier = 1.75
	generic_unit.attack_modifier = 0.25
	generic_unit.movement_modifier = 0.50
	generic_unit.Collision.get_node("Sprite/AnimationPlayer").play("defense")
	generic_unit.get_node("HUD/bonus").text = "DEFENSE 175%\nATTACK 25%\nMOVEMENT 50%"
	generic_unit.default_animation = "defense"

func node_path(nodeobject):
	return nodeobject.get_path()
	

remotesync func stop_defend(generic_unit_path):
	var generic_unit= get_node(generic_unit_path)
	generic_unit.defense_modifier = 1
	generic_unit.attack_modifier = 1
	generic_unit.movement_modifier = 1
	generic_unit.Collision.get_node("Sprite/AnimationPlayer").play("idle")
	generic_unit.get_node("HUD/bonus").text = ""
	generic_unit.default_animation = "idle"

func stop_plan_attack(generic_unit):
	generic_unit.get_parent().attack_planning = false
	if generic_unit.target != Sprite and generic_unit.target_lock == Vector2():
		generic_unit.target.queue_free()
		generic_unit.target = Sprite
	if generic_unit.attackline != Line2D:
		generic_unit.attackline.queue_free()
		generic_unit.attackline = Line2D

func update_attack(generic_unit):
	var effective_range = unit_handling.unit_range[generic_unit.unit_type]*generic_unit.range_modifier
	var attack_range = unit_handling.unit_attack_range[generic_unit.unit_type]*generic_unit.range_modifier
	var dist = generic_unit.waypoints[generic_unit.waypoints.size()-1].distance_to(get_global_mouse_position())
	if dist > effective_range:
		generic_unit.attackline.gradient.set_color(1,Color(1,0,0,.5))
		generic_unit.attackline.gradient.set_color(1,Color(1,0,0,0))
	else:
		generic_unit.attackline.gradient.set_color(1,Color(1,0,0,1))
	var new_position = Vector2()
	if dist > attack_range:
		var normal_vec = (get_global_mouse_position() - generic_unit.waypoints[generic_unit.waypoints.size()-1]).normalized()
		new_position = generic_unit.waypoints[generic_unit.waypoints.size()-1]+(normal_vec * attack_range)
	else:
		new_position = get_global_mouse_position()
	generic_unit.attackline.set_point_position(1,new_position)
	generic_unit.target.global_position = new_position
