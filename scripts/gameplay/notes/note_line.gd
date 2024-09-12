extends Area2D

@onready var level = get_tree().root.get_node("level")

const ANIM_SPRITE = preload("res://scenes/gameplay/animated_sprite.scn")
const NOTE = preload("res://scenes/gameplay/notes/note.scn")
const TALE = preload("res://scenes/gameplay/notes/tale.scn")

var TALE_SPLASH
var SPLASH
var RATE

const SICK_MS = 33.33
const GOOD_MS = 83.33
const BAD_MS = 96.66

signal arrow_press(dir)
signal arrow_miss(dir)
signal arrow_release(dir)

@onready var note_speed = level.note_speed
@export var id = 0

var arrows_to_spawn = []
var arrows_in_area = []

@onready var player_note = (id == 0 or id == 1 or id == 2 or id == 3)
var pressed = false
var hold = false
var dir = ""

func _ready():
	match id % 4:
		0: dir = "left"
		1: dir = "down"
		2: dir = "up"
		3: dir = "right"
	level.json_loaded.connect(json_loaded)


func json_loaded():
	if !level.chart.notes.has(str(id)):
		queue_free()
		return
	load_notes(level.chart.notes)
	
	if !GlobalVaribles.preloaded_styles.has(level.chart.data.style):
		GlobalVaribles.preloaded_styles.merge({level.chart.data.style : {}})
		GlobalVaribles.preloaded_styles[level.chart.data.style].merge({"strum_line" : GlobalFunctions.load_thread("res://assets/resources/sprite_frames/anim_sprite/styles/" + level.chart.data.style + "/strum_line.res", "SpriteFrames")})
		GlobalVaribles.preloaded_styles[level.chart.data.style].merge({"splash" : GlobalFunctions.load_thread("res://assets/resources/sprite_frames/anim_sprite/styles/" + level.chart.data.style + "/splash.res", "SpriteFrames")})
		GlobalVaribles.preloaded_styles[level.chart.data.style].merge({"tale_splash" : GlobalFunctions.load_thread("res://assets/resources/sprite_frames/anim_sprite/styles/" + level.chart.data.style + "/tale_splash.res", "SpriteFrames")})
		GlobalVaribles.preloaded_styles[level.chart.data.style].merge({"rate" : GlobalFunctions.load_thread("res://assets/resources/sprite_frames/anim_sprite/styles/" + level.chart.data.style + "/rate.res", "SpriteFrames")})
		GlobalVaribles.preloaded_styles[level.chart.data.style].merge({"hold" : GlobalFunctions.load_thread("res://assets/resources/sprite_frames/anim_sprite/styles/" + level.chart.data.style + "/hold.res", "SpriteFrames")})
	
	$sprite.set_sprite_frames(GlobalVaribles.preloaded_styles[level.chart.data.style].strum_line)
	SPLASH = GlobalVaribles.preloaded_styles[level.chart.data.style].splash
	TALE_SPLASH = GlobalVaribles.preloaded_styles[level.chart.data.style].tale_splash
	RATE = GlobalVaribles.preloaded_styles[level.chart.data.style].rate
	$hold.sprite_frames = GlobalVaribles.preloaded_styles[level.chart.data.style].hold
	
	$sprite.play(dir)
	$hold.animation = dir
	match level.chart.data.style:
		"pixel":
			$sprite.scale = Vector2(6, 6)
			$sprite.texture_filter = TEXTURE_FILTER_NEAREST
			$hold.scale = Vector2(6, 6)
			$hold.texture_filter = TEXTURE_FILTER_NEAREST


func load_notes(data):
	for note in data[str(id)]:
		var arrow_data = []
		if note.has("l"):
			arrow_data = [note.t, note.l]
		else:
			arrow_data = [note.t, 0]
		if player_note:
			level.total_notes += 1
		if note.has("a"):
			arrow_data.append(note.a)
		arrows_to_spawn.append(arrow_data)


func _physics_process(delta):
	$notes.position.y = -(level.t * level.note_speed)
	for child in $notes.get_children():
		if child.is_in_group("tale"):
			if child.position.y + $notes.position.y < -(child.l * level.note_speed) - 140:
				child.queue_free()
				break
		else:
			if player_note and child.position.y + $notes.position.y < -110.0:
				child.miss()
			if child.position.y + $notes.position.y < -140:
				child.queue_free()
				break
	
	for arrow_to_add in arrows_to_spawn:
		if arrow_to_add[0] - 700 / level.note_speed < level.t:
			arrows_to_spawn.erase(arrow_to_add)
			var note = NOTE.instantiate()
			var pos = arrow_to_add[0] * level.note_speed
			note.position.y = pos
			note.dir = dir
			note.t = arrow_to_add[0]
			$notes.call_deferred("add_child", note)
			if arrow_to_add[1]:
				var tale_inst = TALE.instantiate()
				tale_inst.l = arrow_to_add[1]
				tale_inst.dir = dir
				tale_inst.position.y = pos
				$notes.call_deferred("add_child", tale_inst)
			break
	
	if !player_note:
		for arrow in arrows_in_area:
			if arrow.is_in_group("tale") and arrow.position.y + $notes.position.y < SICK_MS:
				arrow.progress()
				if SaveManager.game_data.opponent_note_damage:
					level.get_opponent_tale_damage(delta * 50)
				if arrow.t_pressed - 10 > arrow.l:
					arrow.queue_free()
					$hold_anim.play(level.chart.data.style + "_end")
					if SaveManager.game_data.opponent_splash_particles:
						spawn_anim_particle("tale_splash", "funkin_splash")
					$press_delay.start()
				else:
					$hold.show()
					$hold_anim.play(level.chart.data.style)
					$press_delay.stop()
					$sprite.play(dir + "_pressed")
			elif arrow.position.y + $notes.position.y < SICK_MS:
				$sprite.stop()
				$sprite.play(dir + "_pressed")
				arrow_press.emit(dir)
				if SaveManager.game_data.opponent_note_damage:
					level.get_opponent_note_damage()
				if SaveManager.game_data.opponent_splash_particles:
					spawn_anim_particle("splash", "", Vector2(0.85, 0.85))
				$press_delay.start()
				arrow.call_deferred("queue_free")
		return
	if Input.is_action_pressed(dir):
		if Input.is_action_just_pressed(dir):
			key_pressed()
		for arrow in arrows_in_area:
			if hold and arrow.is_in_group("tale"):
				arrow.progress()
				level.tale_hold(delta * 50)
				if arrow.t_pressed + 40 > arrow.l:
					arrow.queue_free()
					$hold_anim.play(level.chart.data.style + "_end")
					spawn_anim_particle("tale_splash", "funkin_splash")
					$sprite.play(dir + "_empty_pressed")
					hold = false
				else:
					$hold.show()
					$hold_anim.play(level.chart.data.style)
					$sprite.play(dir + "_pressed")
	elif Input.is_action_just_released(dir):
		$hold_anim.play(level.chart.data.style + "_end")
		for arrow in arrows_in_area:
			if arrow.is_in_group("tale"):
				arrow.inactive()
				arrow_miss.emit(dir)
				level.get_node("player_stream").stop()
				break
		if $sprite.animation == dir + "_empty_pressed":
			$sprite.play(dir)
		if pressed and $press_delay.is_stopped():
			pressed = false
			arrow_release.emit(dir)


func key_pressed():
	if !arrows_in_area.is_empty():
		var arrow = arrows_in_area[0]
		if arrow.is_in_group("tale"):
			return
		var delay = abs(arrow.position.y + $notes.position.y)
		var score = ((200 - delay) / 200) * 500
		var ui = level.get_node("ui")
		if delay < SICK_MS:
			spawn_anim_particle("splash", "", Vector2(0.85, 0.85))
			level.add_stat("sick", score)
			ui.show_rate(0)
			arrow.call_deferred("queue_free")
		elif delay < GOOD_MS:
			level.add_stat("good", score)
			ui.show_rate(1)
			arrow.call_deferred("queue_free")
		elif delay < BAD_MS:
			level.add_stat("bad", score)
			ui.show_rate(2)
			arrow.skipped()
		else:
			level.add_stat("shit", score)
			ui.show_rate(3)
			arrow.skipped()
		arrow_press.emit(dir)
		arrows_in_area.erase(arrow)
		hold = true
		$sprite.stop()
		$sprite.play(dir + "_pressed")
		$press_delay.start()
	else:
		level.add_stat("")
		$sprite.play(dir + "_empty_pressed")
		arrow_miss.emit(dir)
		if SaveManager.game_data.miss_sound:
			GlobalFunctions.add_audio_effect("res://assets/sounds/gameplay/miss/" + str(randi_range(0, 2)) + ".ogg", -10)
	pressed = true


func note_miss():
	if player_note:
		level.add_stat("missed")
		arrow_miss.emit(dir)
		if SaveManager.game_data.miss_sound:
			GlobalFunctions.add_audio_effect("res://assets/sounds/gameplay/miss/" + str(randi_range(0, 2)) + ".ogg", -10)


func spawn_anim_particle(sprite_frames, animation = "", inst_scale = Vector2(1, 1)):
	var new_inst_scale = inst_scale
	var inst_rot = 0
	var inst_texture_filter = TEXTURE_FILTER_LINEAR
	match level.chart.data.style:
		"funkin":
			if animation != "funkin_splash":
				inst_rot = randf_range(-25, 25)
		"pixel":
			if animation == "funkin_splash":
				animation = ""
			new_inst_scale = inst_scale * 6.5
			inst_texture_filter = TEXTURE_FILTER_NEAREST
	GlobalFunctions.add_anim_sprite(self, {
		"sprite_frames" : self[sprite_frames.to_upper()],
		"sprite_anim" : dir,
		"animation" : animation,
		"scale" : new_inst_scale,
		"texture_filter" : inst_texture_filter,
		"rotation_degrees" : inst_rot,
		"modulate" : Color(1, 1, 1, 0.75),
	})


func _on_manager_entered(node):
	arrows_in_area.append(node)


func _on_manager_exited(node):
	if arrows_in_area.has(node):
		arrows_in_area.erase(node)


func _on_sprite_animation_finished():
	if $sprite.animation == dir + "_pressed":
		if player_note and Input.is_action_pressed(dir):
			$sprite.play(dir + "_empty_pressed")
		else:
			$sprite.play(dir)


func _on_press_delay_timeout():
	if player_note and Input.is_action_pressed(dir):
		return
	arrow_release.emit(dir)
	pressed = false


func unpaused():
	if $sprite.animation.find("pressed") != -1:
		$hold_anim.play(level.chart.data.style + "_end")
		pressed = false
		arrow_release.emit(dir)
		$sprite.play(dir)
