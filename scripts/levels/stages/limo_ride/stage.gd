extends Node2D

func _ready():
	$car_pass_time.start(randi_range(2, 15))
	for dancer in $paralax2/dancers.get_children():
		dancer.get_node("anim_player").speed_scale = (1 / get_tree().root.get_node("level").stb) / 2


func _on_car_pass_time_timeout():
	$car_anim.play("def")
	$car_pass_time.start(randi_range(2, 15))
	GlobalFunctions.add_audio_effect("res://assets/sounds/gameplay/stages/limo_ride/car_pass" + str(randi_range(0, 1)) + ".ogg", -10)
