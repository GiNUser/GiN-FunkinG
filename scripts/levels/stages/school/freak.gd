extends AnimatedSprite2D

@export var start_anim = "angry0"

func _ready():
	play(start_anim)
