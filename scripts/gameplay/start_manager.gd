extends Node

@onready var parent = get_parent()

var start_sounds = {}
var start_pos = 4
var start = false

func _enter_tree():
	get_parent().json_loaded.connect(json_loaded)
	get_parent().health_updated.connect(delete)

func json_loaded():
	for i in 4:
		start_sounds.merge({i : GlobalFunctions.load_thread("res://assets/sounds/gameplay/intro/" + parent.chart.data.style + "/" + str(i) + ".ogg", "AudioStreamOggVorbis")})
	await get_tree().create_timer(parent.stb).timeout
	parent.t = parent.stb * -4000
	start = true
	beat_timeout()
	$start_delay.start(parent.stb)


func beat_timeout():
	if start_pos != 0:
		GlobalFunctions.add_audio_effect(start_sounds[start_pos - 1], -10)
		if start_pos != 4:
			parent.get_node("ui").emit_start(start_pos - 1)
		parent._on_beat.emit(parent.beat)
		parent.beat += 1
	else:
		parent.last_beat = 0
		parent._on_beat.emit(4)
		
		if parent.bop_on_beats.has(4.0):
			parent.play_bop()
		
		for stream in ["main", "opponent", "player"]:
			parent.get_node(stream + "_stream").play()
		delete()
	start_pos -= 1


func _process(delta): if start:
	parent.t += delta * 1000
	parent.song_position = (parent.t + parent.stb * 6000) / 1000
	parent.song_position_in_beats = int(parent.song_position / parent.stb)


func delete(arg = 0): if !arg:
	queue_free()
