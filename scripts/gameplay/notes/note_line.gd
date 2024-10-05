extends Node2D

signal note_press(dir)
signal note_miss(dir)
signal note_release(dir)

const PARTICLE = preload("res://scenes/gameplay/particle.scn")
const NOTE = preload("res://scenes/gameplay/notes/note.scn")
const TALE = preload("res://scenes/gameplay/notes/tale.scn")
const SICK_MS = 33.33
const GOOD_MS = 83.33
const BAD_MS = 96.66
const TRIGGER_MS = 108.0

var TALE_SPLASH
var SPLASH

@onready var level = get_tree().root.get_node("level")
@onready var note_speed = level.note_speed
@export var id = 0

var notes_to_spawn = []
var notes = []
var notes_in_area = []
var notes_to_delete = []

@onready var player_note = (id == 0 or id == 1 or id == 2 or id == 3)
var pressed = false
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
	$sprite.sprite_frames = GlobalVaribles.preloaded_styles[level.chart.data.style].strum_line
	$sprite.play(dir)
	SPLASH = GlobalVaribles.preloaded_styles[level.chart.data.style].splash
	TALE_SPLASH = GlobalVaribles.preloaded_styles[level.chart.data.style].tale_splash
	$hold.sprite_frames = GlobalVaribles.preloaded_styles[level.chart.data.style].hold
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
		notes_to_spawn.append(arrow_data)


func _process(delta):
	$notes.position.y = -(level.t * level.note_speed)
	for note in notes_to_spawn:
		if note[0] - 700 / level.note_speed < level.t:
			notes_to_spawn.erase(note)
			var note_inst = NOTE.instantiate()
			var pos = note[0] * level.note_speed
			note_inst.position.y = pos
			note_inst.dir = dir
			
			$notes.add_child(note_inst)
			notes.append(note_inst)
			if note[1]:
				var tale_inst = TALE.instantiate()
				tale_inst.l = note[1]
				tale_inst.dir = dir
				tale_inst.position.y = pos
				$notes.add_child(tale_inst)
				notes.append(tale_inst)
			break
	
	for note in notes:
		if note.position.y + $notes.position.y < TRIGGER_MS:
			notes_in_area.append(note)
			notes.erase(note)
	
	for note in notes_in_area:
		if note.is_in_group("tale"):
			if note.position.y + $notes.position.y < -(note.l * level.note_speed) - TRIGGER_MS:
				notes_to_delete.append(note)
				notes_in_area.erase(note)
		elif note.position.y + $notes.position.y < -TRIGGER_MS:
			notes_to_delete.append(note)
			notes_in_area.erase(note)
			
			if player_note:
				note.miss()
				note_miss.emit(dir)
				level.add_stat("missed")
				GlobalFunctions.add_audio_effect("res://assets/sounds/gameplay/miss/" + str(randi_range(0, 2)) + ".ogg", -10)
	
	for note in notes_to_delete:
		if note.is_in_group("tale"):
			if note.position.y + $notes.position.y < -(note.l * level.note_speed) - 140:
				notes_to_delete.erase(note)
				note.queue_free()
		elif note.position.y + $notes.position.y < -140.0:
			notes_to_delete.erase(note)
			note.queue_free()
	
	if player_note:
		player_func(delta)
	else:
		bot_func(delta)


func player_func(delta):
	if Input.is_action_pressed(dir):
		if Input.is_action_just_pressed(dir):
			key_pressed()
		if notes_in_area.is_empty():
			return
		var note = notes_in_area[0]
		if pressed and note.is_in_group("tale"):
			note.progress()
			level.tale_hold(delta * 50)
			if note.t_pressed > note.l:
				note.queue_free()
				notes_in_area.erase(note)
				
				$sprite.play(dir + "_empty_pressed")
				$hold_anim.play(level.chart.data.style + "_end")
				spawn_anim_particle("tale_splash", "funkin_splash")
			else:
				$sprite.play(dir + "_pressed")
				$hold.show()
				$hold_anim.play(level.chart.data.style)
	elif Input.is_action_just_released(dir):
		if !notes_in_area.is_empty():
			var note = notes_in_area[0]
			if note.is_in_group("tale"):
				note.miss()
				note_miss.emit(dir)
				level.get_node("player_stream").stop()
				$hold_anim.play(level.chart.data.style + "_end")
				
				notes_to_delete.append(note)
				notes_in_area.erase(note)
		
		if $sprite.animation == dir + "_empty_pressed":
			$sprite.play(dir)
		if pressed and $press_delay.is_stopped():
			note_release.emit(dir)


func bot_func(delta):
	for note in notes_in_area: if note.position.y + $notes.position.y < SICK_MS:
		if note.is_in_group("tale"):
			note.progress()
			if SaveManager.game_data.opponent_note_damage:
				level.get_opponent_tale_damage(delta * 50)
			if note.t_pressed > note.l:
				notes_in_area.erase(note)
				note.queue_free()
				$hold_anim.play(level.chart.data.style + "_end")
				if SaveManager.game_data.opponent_splash_particles:
					spawn_anim_particle("tale_splash", "funkin_splash")
				$press_delay.start()
			else:
				$sprite.play(dir + "_pressed")
				$hold.show()
				$hold_anim.play(level.chart.data.style)
				$press_delay.stop()
		else:
			$sprite.stop()
			$sprite.play(dir + "_pressed")
			note_press.emit(dir)
			if SaveManager.game_data.opponent_note_damage:
				level.get_opponent_note_damage()
			if SaveManager.game_data.opponent_splash_particles:
				spawn_anim_particle("splash", "", Vector2(0.85, 0.85))
			$press_delay.start()
			notes_in_area.erase(note)
			note.queue_free()


func key_pressed():
	if !notes_in_area.is_empty():
		var note = notes_in_area[0]
		if note.is_in_group("tale"):
			return
		var delay = abs(note.position.y + $notes.position.y)
		var score = ((TRIGGER_MS - delay) / TRIGGER_MS) * 500
		var ui = level.get_node("ui")
		if delay < SICK_MS:
			spawn_anim_particle("splash", "", Vector2(0.85, 0.85))
			level.add_stat("sick", score)
			ui.show_rate(0)
			note.queue_free()
		elif delay < GOOD_MS:
			level.add_stat("good", score)
			ui.show_rate(1)
			note.queue_free()
		elif delay < BAD_MS:
			level.add_stat("bad", score)
			ui.show_rate(2)
			note.miss()
			notes_to_delete.append(note)
		else:
			level.add_stat("shit", score)
			ui.show_rate(3)
			note.miss()
			notes_to_delete.append(note)
		note_press.emit(dir)
		notes_in_area.erase(note)
		
		$sprite.stop()
		$sprite.play(dir + "_pressed")
		$press_delay.start()
	else:
		level.add_stat("")
		$sprite.play(dir + "_empty_pressed")
		note_miss.emit(dir)
		GlobalFunctions.add_audio_effect("res://assets/sounds/gameplay/miss/" + str(randi_range(0, 2)) + ".ogg", -10)
	pressed = true


func spawn_anim_particle(sprite_frames, animation = "", inst_scale = Vector2(1, 1)):
	var inst_rot = 0
	var inst_texture_filter = TEXTURE_FILTER_LINEAR
	match level.chart.data.style:
		"funkin":
			if animation != "funkin_splash":
				inst_rot = randf_range(-25, 25)
		"pixel":
			if animation == "funkin_splash":
				animation = ""
			inst_scale *= 6.5
			inst_texture_filter = TEXTURE_FILTER_NEAREST
	GlobalFunctions.add_particle(self, {
		"sprite_frames" : self[sprite_frames.to_upper()],
		"sprite_anim" : dir,
		"animation" : animation,
		"scale" : inst_scale,
		"texture_filter" : inst_texture_filter,
		"rotation_degrees" : inst_rot,
		"modulate" : Color(1, 1, 1, 0.75),
	})


func _on_sprite_animation_finished(): if $sprite.animation == dir + "_pressed":
	if player_note and Input.is_action_pressed(dir):
		$sprite.play(dir + "_empty_pressed")
	else:
		$sprite.play(dir)


func _on_press_delay_timeout():
	if !(player_note and Input.is_action_pressed(dir)):
		note_release.emit(dir)


func unpaused():
	if player_note:
		$hold_anim.play(level.chart.data.style + "_end")
		$sprite.play(dir)
		note_release.emit(dir)


func _on_note_release(_dir):
	pressed = false
