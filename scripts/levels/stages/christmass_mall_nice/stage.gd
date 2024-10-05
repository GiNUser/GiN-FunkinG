extends Node2D

func _ready():
	$anim_player.speed_scale = get_tree().root.get_node("level").bps
