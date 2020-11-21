extends Node2D

var actions = 0
var default_actions = 2

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

remote func turn_notifier(playername):
	print("trying to change turn label")
	$GUIcanvas/GUI/Turn.text = str(playername)+"'s Turn"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
