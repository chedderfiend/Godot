extends Node2D

var unit_array = ["archer","archer","archer"]
var unit_num = 0
var unit = preload("res://Units/GenericUnit.tscn")
var selected_unit = CollisionShape2D
var can_waypoint = true
var waypoint_color = Color(0.05,1,0,1)
var ghost = Sprite
var attack_planning = false



func _ready():
	for x in unit_array:
		var Unit = unit.instance()
		Unit.name = str(unit_num)
		Unit.set_network_master(get_network_master())
		add_child(Unit)
		unit_num += 1 
		#var Unit = unit.instance()
		#Unit.unit_type = str(x)
		#Unit.unit_health = unit_handling.unit_max_health[x]
		#Unit.name = str(unit_num)
		#Unit.position = Vector2(unit_num*50,50)
		#Unit.get_node("HUD/healthbar").value = Unit.unit_health
		#Unit.get_node("HUD/healthbar").max_value = Unit.unit_health
		#add_child(Unit
