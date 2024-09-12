extends Node2D

func _ready():
	$thunder_delay.start(randi_range(25, 40))


func _on_thunder_delay_timeout():
	$anim_player.play("def")
	$thunder_delay.start(randi_range(25, 40))
	GlobalFunctions.add_audio_effect("res://assets/sounds/gameplay/stages/spooky_mansion/thunder" + str(randi_range(0, 1)) + ".ogg")
	get_node("player/anim_player").stop()
	get_node("player/anim_player").play("fear")
	get_node("girlfriend/anim_player").stop()
	get_node("girlfriend/anim_player").play("fear")
