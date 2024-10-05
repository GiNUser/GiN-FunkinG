extends CanvasLayer

var stickers_to_show = []
var stickers_to_hide = []

var show_anim = false
var changing = false

var path = ""

func change_to(new_path = "", anim = "def"):
	if changing:
		return
	path = new_path
	get_tree().paused = true
	match anim:
		"def":
			stickers_to_show = $stickers.get_children()
			$stickers.show()
			$delay_timer.start()
			show_anim = true
		"fade":
			$anim_player.play("show")
	changing = true


func _on_delay_timer_timeout():
	if show_anim:
		if stickers_to_show.size() != 0:
			for i in 2:
				var sticker = stickers_to_show.pick_random()
				sticker.frame = randi_range(0, 17)
				sticker.show()
				sticker.z_index = randi_range(-5, 5)
				var sticker_scale = randf_range(0.65, 0.9)
				sticker.scale = Vector2(sticker_scale, sticker_scale)
				sticker.flip_h = (randi() % 2) == 1
				stickers_to_show.erase(sticker)
			GlobalFunctions.add_audio_effect("res://assets/sounds/stickers/keyClick" + str(randi_range(1, 8)) + ".ogg", -7, PROCESS_MODE_ALWAYS)
		else:
			$delay_timer.stop()
			change()
			stickers_to_hide = $stickers.get_children()
			$delay_timer.start()
			show_anim = false
	elif stickers_to_hide.size() != 0:
		for i in 2:
			var cur_sticker = stickers_to_hide.pick_random()
			cur_sticker.hide()
			stickers_to_hide.erase(cur_sticker)
		GlobalFunctions.add_audio_effect("res://assets/sounds/stickers/keyClick" + str(randi_range(1, 8)) + ".ogg", -7, PROCESS_MODE_ALWAYS)
	else:
		$delay_timer.stop()
		$stickers.hide()
		changing = false


func _animation_finished(anim_name):
	if anim_name == "show":
		change()
		changing = false
		$anim_player.play("hide")


func change():
	if path:
		get_tree().change_scene_to_packed(GlobalFunctions.load_thread("res://" + path + ".scn", "PackedScene"))
	else:
		get_tree().reload_current_scene()
	get_tree().paused = false
