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


func _on_animation_finished(_anim_name = ""): if delete_on_end:
	queue_free()
