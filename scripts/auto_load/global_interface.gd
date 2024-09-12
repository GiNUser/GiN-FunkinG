extends CanvasLayer

const SCREENSHOT_SOUND = preload("res://assets/sounds/screenshot.ogg")
var prev_volume = -1
var in_game = true

func _ready():
	if SaveManager.game_data.fullscreen_on_start:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
	AudioServer.set_bus_volume_db(0, (SaveManager.game_data.volume - 10) * 2)
	if SaveManager.game_data.volume == 0:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		$ui/box/volume.texture = GlobalFunctions.load_thread("res://assets/images/volume-box/bars_" + str(SaveManager.game_data.volume) + ".png", "Image")


func _input(_event):
	if Input.is_action_just_pressed("volume_up"):
		volume_up()
	elif Input.is_action_just_pressed("volume_down"):
		volume_down()
	elif Input.is_action_just_pressed("volume_mute"):
		volume_zero()
	elif Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode(0) != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, 0)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, 0)
	elif Input.is_action_just_pressed("screenshot"):
		$scrennshot_anim.stop()
		await RenderingServer.frame_post_draw
		GlobalFunctions.add_audio_effect(SCREENSHOT_SOUND, 0, PROCESS_MODE_ALWAYS)
		var img = get_viewport().get_texture().get_image()
		img.save_png(OS.get_user_data_dir().trim_suffix("AppData/Roaming/Godot/app_userdata/FunkinG") + "Pictures/" + Time.get_datetime_string_from_system().replace(":", "-") + ".png")
		$ui/screenshot_image.texture = ImageTexture.create_from_image(img)
		$scrennshot_anim.play("def")
		await $scrennshot_anim.animation_finished
		$ui/screenshot_image.texture = null
	elif Input.is_action_just_pressed("debug"):
		update_debug()


func _process(_delta):
	if DisplayServer.window_is_focused():
		if !in_game:
			in_game = true
			AudioServer.set_bus_volume_db(0, (SaveManager.game_data.volume - 10) * 2)
	elif in_game:
		in_game = false
		AudioServer.set_bus_volume_db(0, -100)
		if get_tree().root.has_node("level/ui") and SaveManager.game_data.auto_pause:
			get_tree().root.get_node("level/ui").show_pause()


func volume_up():
	if prev_volume != -1:
		SaveManager.game_data.volume = prev_volume + 1
		prev_volume = -1
	else:
		SaveManager.game_data.volume += 1
	if SaveManager.game_data.volume == 11:
		GlobalFunctions.add_audio_effect("res://assets/sounds/volume-box/vol_max.ogg")
	else:
		GlobalFunctions.add_audio_effect("res://assets/sounds/volume-box/vol_up.ogg")
	SaveManager.game_data.volume = clamp(SaveManager.game_data.volume, 0, 10)
	if !$ui/box.visible or $anim_player.current_animation == "hide_volume_box":
		$anim_player.play("show_volume_box")
	$ui/box/volume.texture = GlobalFunctions.load_thread("res://assets/images/volume-box/bars_" + str(SaveManager.game_data.volume) + ".png", "Image")
	$ui/box/volume.show()
	$volume_box_time.stop()
	$volume_box_time.start()
	SaveManager.save_data()
	AudioServer.set_bus_volume_db(0, (SaveManager.game_data.volume - 10) * 2)
	AudioServer.set_bus_mute(0, false)


func volume_down():
	if prev_volume != -1:
		SaveManager.game_data.volume = prev_volume - 1
		prev_volume = -1
	else:
		SaveManager.game_data.volume -= 1
	SaveManager.game_data.volume = clamp(SaveManager.game_data.volume, 0, 10)
	if !$ui/box.visible or $anim_player.current_animation == "hide_volume_box":
		$anim_player.play("show_volume_box")
	if !SaveManager.game_data.volume:
		$ui/box/volume.hide()
		AudioServer.set_bus_mute(0, true)
	else:
		$ui/box/volume.texture = GlobalFunctions.load_thread("res://assets/images/volume-box/bars_" + str(SaveManager.game_data.volume) + ".png", "Image")
		$ui/box/volume.show()
		AudioServer.set_bus_volume_db(0, (SaveManager.game_data.volume - 10) * 2)
		AudioServer.set_bus_mute(0, false)
		GlobalFunctions.add_audio_effect("res://assets/sounds/volume-box/vol_down.ogg")
	$volume_box_time.stop()
	$volume_box_time.start()
	SaveManager.save_data()


func _on_volume_box_time_timeout():
	$anim_player.play("hide_volume_box")


func volume_zero():
	if prev_volume == -1:
		prev_volume = SaveManager.game_data.volume
		SaveManager.game_data.volume = 0
		AudioServer.set_bus_mute(0, true)
		$ui/box/volume.hide()
	else:
		SaveManager.game_data.volume = prev_volume
		AudioServer.set_bus_volume_db(0, (SaveManager.game_data.volume - 10) * 2)
		AudioServer.set_bus_mute(0, false)
		prev_volume = -1
		$ui/box/volume.show()
	if !$ui/box.visible or $anim_player.current_animation == "hide_volume_box":
		$anim_player.play("show_volume_box")
	$volume_box_time.stop()
	$volume_box_time.start()
	SaveManager.save_data()


func update_debug():
	if !has_node("ui/fps_label"):
		$ui.call_deferred("add_child", preload("res://scenes/interface/fps_label.scn").instantiate())
	else:
		get_node("ui/fps_label").queue_free()
