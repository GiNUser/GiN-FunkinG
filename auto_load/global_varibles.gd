extends Node

const LEVELS = ["tutorial", "bopeebo", "fresh", "dadbattle", "spookeez", "south", "monster",
	"pico", "philly-nice", "blammed", "satin-panties", "high", "milf", "cocoa",
	"eggnog", "winter-horrorland", "senpai", "roses", "thorns", "ugh", "guns",
	"stress"]#, "darnell", "lit-up", "2hot"]

const LEVELS_ERECT = ["bopeebo", "fresh", "dadbattle", "spookeez", "south", "pico", "philly-nice",
"blammed", "satin-panties", "high", "eggnog", "senpai", "roses", "thorns"]

@onready var CHARACTERS_DATA = JSON.parse_string(FileAccess.open_compressed("res://assets/resources/characters_data.json", FileAccess.READ, FileAccess.COMPRESSION_ZSTD).get_as_text())
@onready var EVENTS_DATA = JSON.parse_string(FileAccess.open_compressed("res://assets/resources/events.json", FileAccess.READ, FileAccess.COMPRESSION_ZSTD).get_as_text())

var preloaded_characters = {}
var preloaded_stages = {}
var preloaded_styles = {}

var menu_layer = ""
var level_name = "Bopeebo"
var level_dict_name = "bopeebo"
var difficulty = "normal"
var cur_freeplay_level = 1

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
	}

var story_info = []
