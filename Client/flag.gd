extends Sprite

onready var animationState = $AnimationTree.get('parameters/playback')

func _ready():
	#connect("delete_flags",self,"_erase")
	animationState.start("flag_start")
	#pass
