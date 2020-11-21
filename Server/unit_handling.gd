extends Node2D

"""

This code will store the basic information about the unit types (archer, etc.)
it will also handle their actions and movements

"""


#weapons
#var arrow = preload("res://Weapons/Arrow.tscn")

#unit stats
var unit_max_health = {"archer":100,"warrior":200}
var unit_movement = {"archer":400,"warrior":400}
var unit_damage = {"archer":20,"warrior":20}
var unit_range = {"archer":500, "warrior":20}
#var unit_collision = {"archer":generic_collision}
#var unit_sprite = {"archer":archer_sprite}
var speed = 150
var angle_error = 5.0

puppet var puppet_pos
puppet var puppet_rot
