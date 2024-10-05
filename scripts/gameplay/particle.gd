extends Node2D

@export var sprite_anim = ""
@export var animation = ""
@export var delete_on_end = true
@export var anim_player_speed = 1

func _ready():
	if sprite_anim is int:
		$anim_sprite.frame = sprite_anim
	elif sprite_anim != "":
		$anim_sprite.play(sprite_anim)
	if animation != "":
		$anim_player.speed_scale = anim_player_speed
		$anim_player.play(animation)
	else:
		$anim_player.queue_free()
	
	if delete_on_end:
		$anim_sprite.animation_finished.connect(destroy)
		$anim_player.animation_finished.connect(destroy)


func destroy(_arg = ""):
	queue_free()
