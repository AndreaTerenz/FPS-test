extends Node

signal settings_loaded(defaults)
signal failed_to_load(error)
signal settings_saved
signal failed_to_save(error)
signal changed_setting(sett_name, newVal)

enum SECTIONS {
	CONTROLS,
	GRAPHICS,
	AUDIO
}

class SettingsEdit:
	var section : String
	var key : String
	var original_value
	var current_value
	
	func _init(s: String, k: String) -> void:
		section = s
		key = k
		original_value = Settings.get_value(section, key)
		current_value = original_value
				
	func reset():
		current_value = original_value
		
	func apply():
		if current_value != original_value:
			Settings.set_value(section, key, current_value)
			original_value = current_value

var config := ConfigFile.new()
var target_file := "res://settings.cfg"
var data_loaded := false

######################################
const CONTROLS := "Controls"
const INVERT_Y := "invert_y_axis"
const MOUSE_SENS := "mouse_sensitivity"

######################################
const GRAPHICS := "Graphics"
const USE_VSYNC := "use_vsync"
const RESOLUTION := "resolution"

const NATIVE_RES := "native"
const STD_RESS := [
	"800 x 600",
	"1024 x 600",
	"1024 x 768",
	"1280 x 720",
	"1280 x 960",
	"1366 x 768",
	"1400 x 1050",
	"1600 x 900",
	"1920 x 1080",
	"2560 x 1440",
]

const WIN_MODE := "window_mode"
const WIN_MODE_FULL := "fullscreen"
const WIN_MODE_WINDW := "windowed"
const WIN_MODE_BRDRLESS := "borderless"

######################################
const AUDIO := "Audio"

const defaults : Dictionary = {
	CONTROLS : {
		MOUSE_SENS: 1.0,
		INVERT_Y: false
	},
	GRAPHICS : {
		USE_VSYNC: true,
		RESOLUTION: NATIVE_RES,
		WIN_MODE: WIN_MODE_FULL
	},
	AUDIO : {},
}

var debug_force_defaults = false
func _ready():
	if not data_loaded:
		var err = config.load(target_file)
		data_loaded = true
		
		if debug_force_defaults or err == ERR_FILE_NOT_FOUND:
			load_defaults()
			if err == ERR_FILE_NOT_FOUND:
				save_data()
		elif err == OK:
			emit_signal("settings_loaded", false)
		else:
			emit_signal("failed_to_load", err)
			data_loaded = false
			
		if data_loaded:
			apply_all()
		
func save_data():
	var err = config.save(target_file)
	
	if err == OK:
		emit_signal("settings_saved")
	else:
		emit_signal("failed_to_save", err)

func load_defaults():
	for section in defaults.keys():
		for key in defaults[section].keys():
			set_value(section, key, defaults[section][key], false, false)
			
	emit_signal("settings_loaded", true)
	
func get_value(section: String, key: String, default = null):
	return config.get_value(section, key, default)
	
func set_value(section: String, key: String, value, apply := true, emit_change := true):
	config.set_value(section, key, value)
	apply_setting(section, key, value)
	
	if emit_change:
		emit_signal("changed_setting", get_section_key_str(section, key), value)
		
func apply_setting(section: String, key: String, value):
	if section == CONTROLS:
		pass
	elif section == GRAPHICS:
		match key:
			USE_VSYNC:
				OS.vsync_enabled = bool(value)
			RESOLUTION: 
				#OBVIOUSLY MAKE SURE TO BRIEFLY RESET TO THE NATIVE RESOLUTION EVERY TIME
				#Globals.set_resolution()
				
				var str_v := str(value)
				
				if str_v != NATIVE_RES:
					var tmp = split_resolution_str(str_v)
					var w = int(tmp[0])
					var h = int(tmp[1])
					
					Globals.set_resolution()
					
					if w != OS.get_screen_size().x and h != OS.get_screen_size().y:
						Globals.set_resolution(w, h)
						"""
						var window_size := OS.get_screen_size()
						var ratio = window_size.x / window_size.y
						var minsize = Vector2(w * ratio, h)
						get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_VIEWPORT, SceneTree.STRETCH_ASPECT_KEEP_WIDTH, minsize)
						"""
				else:
					Globals.set_resolution()
			WIN_MODE:
				match str(value).to_lower():
					WIN_MODE_FULL:
						Globals.set_fullscreen(true)
					WIN_MODE_WINDW: 
						Globals.set_fullscreen(false)
	elif section == AUDIO:
		pass
		
func apply_all():
	for section in config.get_sections():
		for key in config.get_section_keys(section):
			var value = config.get_value(section, key)
			apply_setting(section, key, value)
		
func get_section_key_str(section: String, key: String):
	return "%s.%s" % [section, key]
	
func section_key_from_str(string: String):
	return string.split(".", true, 1)
	
func split_resolution_str(res: String):
	return res.replace(" ", "").split("x")
	
	
	
	
	