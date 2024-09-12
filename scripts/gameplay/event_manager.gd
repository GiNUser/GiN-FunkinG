extends Node

@export var type = "MAIN"
@onready var level = get_tree().root.get_node("level")
var parent

var events = []

func _process(_delta):
	for event in events:
		if level.t > event[0]:
			activate_event(event)


func activate_event(event):
	match event[2]:
		#level
		"cmnf":
			parent.get_node("stage").call(event[1])
		"sb":
			parent.bop_on_beats = event[1][0]
			parent.set_bop_power(event[1][1])
		#camera
		"sct":
			parent.set_target(event[1])
		"scz":
			parent.zoom_on_none = float(event[1][0])
			parent.zoom_on_target = float(event[1][1])
			if parent.target == "none":
				parent.real_zoom = parent.zoom_on_none
			else:
				parent.real_zoom = parent.zoom_on_target
			parent.set_target(parent.target)
		#character
		"ca":
			parent.change_animations(event[1])
		"pa":
			parent.get_node("anim_player").stop()
			parent.get_node("anim_player").play(event[1][1])
		"cca":
			var cur_var = 1
			for varible in ["left", "down", "up", "right"]:
				self[varible] = int(event[1][cur_var])
				cur_var += 1
			parent.connect_arrows()
		"dca":
			for i in parent.get_incoming_connections():
				var has = false
				for signal_to_pass in ["animation_finished", "_on_beat"]:
					if str(i["signal"]).find(signal_to_pass) != -1:
						has = true
				if !has:
					i.signal.disconnect(i.callable)
			parent.cur_dir = ""
		"ccsf":
			pass
	events.erase(event)
	if events.is_empty():
		queue_free()


func add_events(events_dict):
	parent = get_parent()
	for event_type in GlobalVaribles.EVENTS_DATA.EVENTS_LISTS[type]:
		if events_dict.has(event_type):
			for event in events_dict[event_type]:
				match type:
					"CHARACTER":
						if event[1][0] != get_parent().name:
							continue
				event.append(event_type)
				events.append(event)
	
	for event in events:
		if event[0] <= 0:
			activate_event(event)
			match event[2]:
				"scz":
					parent.smooth_zoom = parent.real_zoom
	
	if events.is_empty():
		queue_free()
