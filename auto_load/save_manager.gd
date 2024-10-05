extends Node

const DEFAULT_GAME_DATA = {
	"opponent_splash_particles" = true,
	"zoom_on_bop" = true,
	"auto_pause" = true,
	"opponent_note_damage" = true,
	"adaptive_health" = true,
	"centered_arrows" = true,
	"start_intro" = true,
	"fullscreen_on_start" = false,
	"voices" = true,
	"sounds" = true,
	"volume" = 10,
	"max_fps" = -1,
	"time_scale" = 1.0,
	"levels_data" = {},
	"storys_data" = {},
	"input_map" = {
		"left" = 65,
		"down" = 83,
		"up" = 87,
		"right" = 68,
		"volume_up" = 61,
		"volume_down" = 45,
		"volume_mute" = 48,
		"accept" = 90,
		"cancel" = 88,
		"freeplay_favourite" = 70,
		"freeplay_right" = 81,
		"freeplay_left" = 69,
		"screenshot" = 4194333,
		"debug" = 4194334,
	},
}
const SAVE_FILE_PATH = "user://s.f"
var game_data

func _enter_tree():
	load_data()


func load_data():
	var file = FileAccess.open_compressed(SAVE_FILE_PATH , FileAccess.READ, FileAccess.COMPRESSION_ZSTD)
	if !FileAccess.file_exists(SAVE_FILE_PATH):
		game_data = DEFAULT_GAME_DATA.duplicate()
		save_data()
	else:
		game_data = file.get_var()
		var old_data = game_data.duplicate()
		for key in DEFAULT_GAME_DATA:
			if !old_data.has(key):
				game_data[key] = DEFAULT_GAME_DATA[key]
			
			if game_data[key] is Dictionary:
				for v in DEFAULT_GAME_DATA[key]:
					if !game_data[key].has(v):
						game_data[key].merge({v : DEFAULT_GAME_DATA[key][v]})


func save_data():
	var file = FileAccess.open_compressed(SAVE_FILE_PATH , FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
	file.store_var(game_data)
