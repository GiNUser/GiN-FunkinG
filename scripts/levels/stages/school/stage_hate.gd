extends Node2D

const FADE_SPRITE = preload("res://scenes/levels/objects/school/fade_sprite.scn")

func _on_timer_timeout():
	var sprite_inst = FADE_SPRITE.instantiate()
	var sprite = $opponent/anim_sprite
	sprite_inst.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	sprite_inst.position = sprite.global_position
	sprite_inst.scale = Vector2(6, 6)
	sprite_inst.texture_filter = sprite.texture_filter
	add_child(sprite_inst)
