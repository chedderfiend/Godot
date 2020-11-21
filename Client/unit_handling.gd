extends Node2D

"""

This code will store the basic information about the unit types (archer, etc.)
it will also handle their actions and movements

"""

# use this to store info about the unit types
var archer_collision = preload("res://Units/Archer_collision.tscn")
var warrior_collision = preload("res://Units/Warrior_collision.tscn")
var wizard_collision = preload("res://Units/Wizard_collision.tscn")

#use this to store sprites for ghosts
var archer_sprite = preload("res://Units/ArcherSprite.tscn")
var warrior_sprite = preload("res://Units/WarriorSprite.tscn")
var wizard_sprite = preload("res://Units/WizardSprite.tscn")

#Use this to store selectors for units
var archer_selector = preload("res://GUI/selector/Selector.tscn")
var warrior_selector = preload("res://GUI/selector/Selector_warrior.tscn")
var wizard_selector = preload("res://GUI/selector/Selector_wizard.tscn")

#weapons
var arrow = preload("res://Weapons/Arrow.tscn")
var fireball = preload("res://Weapons/Fireball/fireball.tscn")

#effects
var blood = preload("res://Weapons/blood.tscn")

#unit stats
var unit_max_health = {"archer":100,"warrior":200, "wizard":75}
var unit_movement = {"archer":400,"warrior":400,"wizard":400}
var unit_damage = {"archer":20,"warrior":20,"wizard":50}
var unit_range = {"archer":400, "warrior":100, "wizard":300}
var unit_attack_range = {"archer":750, "warrior":100,"wizard":800}
var unit_collision = {"archer":archer_collision, "warrior":warrior_collision, "wizard":wizard_collision}
var unit_sprite = {"archer":archer_sprite, "warrior":warrior_sprite, "wizard":wizard_sprite}
var unit_selector = {"archer":archer_selector, "warrior":warrior_selector, "wizard":wizard_selector}
var speed = 150
var angle_error = 5.0



func move_unit(generic_unit):
	if generic_unit.target != Sprite:
		generic_unit.target.queue_free()
		generic_unit.target = Sprite
	if generic_unit.waypoints.size() > 0 and generic_unit.can_move == true:
		var current_pos = generic_unit.global_position
		var next_pos = generic_unit.waypoints[0]
		generic_unit.movement = current_pos.direction_to(next_pos) * speed * generic_unit.movement_modifier
		generic_unit.rotation = (next_pos-current_pos).angle()-deg2rad(90)
		generic_unit.get_node("Line2D").set_point_position(0,current_pos)
		if current_pos.distance_to(next_pos) < 5:
			player_interactions.pass_waypoint(generic_unit)
	else:
		generic_unit.get_node("HUD/Selector").position = Vector2(0,0)
		generic_unit.movement = Vector2.ZERO
		player_interactions.clear_waypoints(generic_unit)
		if generic_unit.target_lock != Vector2():
			#unit attacks
			if generic_unit.unit_type == "archer":
				archer_attack(generic_unit)
			if generic_unit.unit_type == "warrior":
				warrior_approach(generic_unit)
			if generic_unit.unit_type =="wizard":
				wizard_attack(generic_unit)
		else:
			generic_unit.can_move = false
			use_unit(generic_unit)

remotesync func play_animation(generic_unit_path,animation):
	var generic_unit = get_node(generic_unit_path)
	generic_unit.Collision.get_node("Sprite/AnimationPlayer").play(animation)

func warrior_approach(generic_unit):
	generic_unit.rotation = (generic_unit.target_lock-generic_unit.global_position).angle()-deg2rad(90)
	generic_unit.target_approach = true
	generic_unit.can_move = false
	use_unit(generic_unit)

func warrior_attack(attacker,victim):
	#attacker.Collision.get_node("Sprite/AnimationPlayer").play("attack")
	rpc("play_animation",player_interactions.node_path(attacker),"attack")
	attacker.target_lock = Vector2()
	var hit_chance = rand_range(1.0,2.0)
	if hit_chance > victim.defense_modifier:
		rpc("warrior_hits",player_interactions.node_path(attacker), player_interactions.node_path(victim))

remotesync func warrior_hits(attacker_path, victim_path):
	var attacker = get_node(attacker_path)
	var victim = get_node(victim_path)
	var Blood = blood.instance()
	victim.add_child(Blood)
	damage(victim,attacker.unit_type,attacker.attack_modifier)

func archer_attack(generic_unit):
	var damage_multiplier = 1
	if generic_unit.waypoint_dist > 0:
		damage_multiplier = 0.5
	var applied_error = 0
	var dist_target = generic_unit.get_global_position().distance_to(generic_unit.target_lock)
	if dist_target > unit_range[generic_unit.unit_type]*generic_unit.range_modifier:
		applied_error = rand_range(-1.0,1.0)*angle_error
		#print(applied_error)
	generic_unit.rotation = (generic_unit.target_lock-generic_unit.global_position).angle()-deg2rad(90+applied_error)
	yield(get_tree().create_timer(1),"timeout")
	shoot(generic_unit, clamp(dist_target+50,0,1500),damage_multiplier)

func wizard_attack(generic_unit):
	var damage_multiplier = 1
	if generic_unit.waypoint_dist > 0:
		damage_multiplier = 0.5
	var applied_error = 0
	var dist_target = generic_unit.get_global_position().distance_to(generic_unit.target_lock)
	if dist_target > unit_range[generic_unit.unit_type]*generic_unit.range_modifier:
		applied_error = rand_range(-1.0,1.0)*angle_error
		#print(applied_error)
	generic_unit.rotation = (generic_unit.target_lock-generic_unit.global_position).angle()-deg2rad(90+applied_error)
	yield(get_tree().create_timer(1),"timeout")
	#cast_fire(generic_unit, clamp(dist_target+50,0,1500),damage_multiplier)
	cast_lighting(generic_unit, clamp(dist_target+50,0,1500),damage_multiplier)
	
func use_unit(generic_unit):
		generic_unit.Collision.get_node("Sprite").modulate = Color(1,1,1,0.6)
		generic_unit.disabled = true
		generic_unit.used = true
		turnmanager.check_end_turn(generic_unit.get_parent())

func show_unit(generic_unit):
		generic_unit.Collision.get_node("Sprite").modulate = Color(1,1,1,1)

func free_unit(generic_unit):
		generic_unit.Collision.get_node("Sprite").modulate = Color(1,1,1,1)
		generic_unit.disabled = false
		generic_unit.used = false

func target_lock(generic_unit):
	generic_unit.target_lock = generic_unit.target.get_global_position()#get_global_mouse_position()
	player_interactions.deselect_unit(generic_unit.get_parent(),generic_unit,generic_unit.Collision)
	#print("target_locked")
	#player_interactions.deselect_unit(generic_unit.get_parent(),generic_unit,generic_unit.Collision)
	#for unit in generic_unit.get_parent().get_children():
	#	if unit.has_method("_is_unit"):
	#		print(unit.target_lock)

func cast_fire(generic_unit,dist_target,damage_multiplier):
	generic_unit.rpc("cast_fire", dist_target, damage_multiplier)
	use_unit(generic_unit)

func cast_lighting(generic_unit,dist_target,damage_multiplier):
	generic_unit.rpc("cast_lightning", dist_target, damage_multiplier)

func shoot(generic_unit, dist_target,damage_multiplier):
	generic_unit.rpc("shoot",dist_target,damage_multiplier)
	use_unit(generic_unit)

func kill(generic_unit):
	generic_unit.rpc("die")

func damage(generic_unit,unit_type,damage_multiplier):
	if generic_unit.is_network_master():
		generic_unit.unit_health -= unit_damage[unit_type]*damage_multiplier
		print(unit_damage[unit_type]*damage_multiplier)
		if generic_unit.unit_health <= 0:
			kill(generic_unit)
		generic_unit.rpc("update_health",generic_unit.unit_health)
		
		
