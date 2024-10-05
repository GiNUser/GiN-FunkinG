extends Node2D

var dir = "right"

func _ready():
	position = Vector2(1200, 200)
	if dir == "left":
		$anim_sprite.flip_h = true
		position.x *= -1
	scale *= randf_range(0.95, 1.05)


func _process(delta): match dir:
	"left":
		position.x += delta * 900
	"right":
		position.x -= delta * 900


func _on_anim_player_animation_finished(_anim_name):
	queue_free()


func _on_timer_timeout():
	$anim_player.stop()
	$anim_player.play(["die_1", "die_2"].pick_random())
	dir = ""
