extends CanvasLayer

func _enter_tree():
	$player.stream.file = "res://assets/videos/" + GlobalVaribles.story_info.scenario[0][1] + ".ogv"


func _ready():
	GlobalVaribles.story_info.scenario.remove_at(0)


func _input(_event):
	if Input.is_action_just_pressed("accept"):
		change_scene()


func change_scene():
	if GlobalVaribles.story_info.scenario.size() == 0:
		GlobalFunctions.unload_story()
		SceneChanger.change_to("scenes/main_scenes/main.scn")
	else:
		get_tree().change_scene_to_file("scenes/main_scenes/" + GlobalVaribles.story_info.scenario[0][0] + ".scn")
