extends Node2D


#multiplayer stuff
puppet var puppet_pos
puppet var puppet_rot

puppet var inactive = false
puppet var used = false
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func re_activate():
	rset("inactive",false)
	rset("used",false)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
