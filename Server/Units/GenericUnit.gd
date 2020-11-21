extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

puppet var puppet_pos
puppet var puppet_rot


# Called when the node enters the scene tree for the first time.
func _ready():
	print(get_network_master())
	pass # Replace with function body.

remotesync func shoot(dist_target,damage_multiplier):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
