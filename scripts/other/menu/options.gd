extends Control

const LETTERS_SPRITE_FRAMES = preload("res://assets/resources/sprite_frames/anim_sprite/letters.res")
const SOUND_MENU_CONFIRM = preload("res://assets/sounds/menu/confirm.ogg")
const SOUND_MENU_CANCEL = preload("res://assets/sounds/menu/cancel.ogg")
const SOUND_MENU_SCROLL = preload("res://assets/sounds/menu/scroll.ogg")

var cur_layer = "main"
var cur_btn = 0
var tween

func _ready():
	spawn_sprite_text("options", Vector2(20, 27.5), $top_bar)
	for text in ["preferences", "gameplay", "audio", "controls"]:
		spawn_sprite_text(text, Vector2(35, 50), $main_container.get_node(text))
	$main_container.position = Vector2(-1000, 280)
	update_options_btn()
	
	tween = create_tween()
	tween.tween_property($main_container, "position", Vector2(0, -$main_container.get_child(cur_btn).position.y + 280), 0.2).set_trans(Tween.TRANS_EXPO)
	await RenderingServer.frame_post_draw
	$anim_player.play("show")


func spawn_sprite_text(text = "", pos = Vector2.ZERO, node = self, from_right_to_left = false):
	var letter_pos = 0
	for letter in text:
		if letter == " ":
			letter_pos += 1
			continue
		var set_pos
		if from_right_to_left:
			set_pos = pos - Vector2(30 * (text.length() - letter_pos), 0)
		else:
			set_pos = pos + Vector2(30 * letter_pos, 0)
		GlobalFunctions.add_particle(node, {
			"sprite_frames" : LETTERS_SPRITE_FRAMES,
			"scale" : Vector2(0.7, 0.7),
			"position" : set_pos,
			"sprite_anim" : letter.to_lower(),
			"delete_on_end" : false,
			})
		letter_pos += 1


func _input(_event): if GlobalVaribles.menu_layer == "options":
	if Input.is_action_just_pressed("accept"):
		if cur_layer == "main":
			tween_hide($main_container.get_child(cur_btn).name, 0)
			
			update_options_btn()
			get_node(cur_layer + "_container").position.y = -get_node(cur_layer + "_container").get_child(cur_btn).position.y + 280
			GlobalFunctions.add_audio_effect(SOUND_MENU_CONFIRM, 0, PROCESS_MODE_ALWAYS)
		else:
			get_node(cur_layer + "_container").get_child(cur_btn).use()
	elif Input.is_action_just_pressed("cancel"):
		if cur_layer == "main":
			$anim_player.play("hide")
			
			if tween:
				tween.kill()
			tween = create_tween()
			tween.tween_property($main_container, "position", Vector2(-1000, -$main_container.get_child(cur_btn).position.y + 280), 0.2).set_trans(Tween.TRANS_EXPO)
		else:
			var to_btn = 0
			for i in $main_container.get_children().size():
				if $main_container.get_child(i).name == cur_layer:
					to_btn = i
					break
			tween_hide("main", to_btn)
		GlobalFunctions.add_audio_effect(SOUND_MENU_CANCEL, 0, PROCESS_MODE_ALWAYS)
		
		update_options_btn()
		get_node(cur_layer + "_container").position.y = -get_node(cur_layer + "_container").get_child(cur_btn).position.y + 280
	elif Input.is_action_just_pressed("up"):
		cur_btn -= 1
		if cur_btn < 0:
			cur_btn = get_node(cur_layer + "_container").get_child_count() - 1
		update_options_btn()
		GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)
	elif Input.is_action_just_pressed("down"):
		cur_btn += 1
		if cur_btn > get_node(cur_layer + "_container").get_child_count() - 1:
			cur_btn = 0
		update_options_btn()
		GlobalFunctions.add_audio_effect(SOUND_MENU_SCROLL, 0, PROCESS_MODE_ALWAYS)


func update_options_btn():
	for child in get_node(cur_layer + "_container").get_children():
		child.modulate = "99999999"
	get_node(cur_layer + "_container").get_child(cur_btn).modulate = Color.WHITE
	
	for child in $description.get_children():
		child.queue_free()
	if get_node(cur_layer + "_container").get_child(cur_btn).get_script():
		spawn_sprite_text(get_node(cur_layer + "_container").get_child(cur_btn).description, Vector2.ZERO, $description, true)


func _on_anim_player_animation_finished(anim_name):
	if anim_name == "hide":
		GlobalVaribles.menu_layer = "main"
		queue_free()


func tween_hide(to_layer, to_btn):
	var target = get_node(cur_layer + "_container")
	var y_pos = -target.get_child(cur_btn).position.y + 280
	if tween:
		tween.kill()
	tween = create_tween()
	
	tween.tween_property(target, "position", Vector2(-800, y_pos), 0.2).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property(target, "visible", false, 0.2)
	
	cur_layer = to_layer
	cur_btn = to_btn
	
	target = get_node(cur_layer + "_container")
	target.show()
	y_pos = 280
	if cur_layer == "main":
		y_pos -= target.get_child(cur_btn).position.y
	target.position = Vector2(-800, y_pos)
	tween.parallel().tween_property(target, "position", Vector2(0, y_pos), 0.2).set_trans(Tween.TRANS_EXPO)


func _process(delta):
	get_node(cur_layer + "_container").position.y -= (get_node(cur_layer + "_container").position.y - (-get_node(cur_layer + "_container").get_child(cur_btn).position.y + 280)) * clamp(delta * 15, 0, 0.99)
