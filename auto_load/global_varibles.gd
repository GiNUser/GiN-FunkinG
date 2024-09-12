extends Node

@onready var CHARACTERS_DATA = JSON.parse_string(FileAccess.open_compressed("res://assets/resources/characters_data.json", FileAccess.READ, FileAccess.COMPRESSION_ZSTD).get_as_text())
@onready var EVENTS_DATA = JSON.parse_string(FileAccess.open_compressed("res://assets/resources/events.json", FileAccess.READ, FileAccess.COMPRESSION_ZSTD).get_as_text())

var preloaded_characters = {}
var preloaded_stages = {}
var preloaded_styles = {}

var menu_layer = ""
var level_dict_name = ""
var difficulty = "normal"
var cur_freeplay_level = 1

#[["difs"], ["opponent", "bpm", "rates"]]
var freeplay_capsules_infos = {}

var level_infos = {
		"score" : 0,
		"sick" : 0,
		"good" : 0,
		"bad" : 0,
		"shit" : 0,
		"missed" : 0,
		"max_combo" : 0,
		"total_notes" : 0,
		"rate" : 0,
	}

var story_info = {
	"is_story" : false,
	"scenario" : [],
	"preload_resources" : {},
	}
