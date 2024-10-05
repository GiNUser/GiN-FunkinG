extends Node2D

func _ready():
	$thunder_delay.start(randi_range(20, 45))


func _on_thunder_delay_timeout():
	$bg.play("def")
	$thunder_delay.start(randi_range(20, 45))
	GlobalFunctions.add_audio_effect("res://assets/sounds/gameplay/stages/spooky_mansion/thunder" + str(randi_range(0, 1)) + ".ogg")
	$player/anim_player.stop()
	$player/anim_player.play("fear")
	$girlfriend/anim_player.stop()
	$girlfriend/anim_player.play("fear")
