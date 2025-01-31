
extends CanvasLayer

const BaseCommands = preload('Misc/BaseCommands.gd')
const DefaultActions = preload('../DefaultActions.gd')
const CommandService = preload('Command/CommandService.gd')

### Custom console types
const IntRangeType = preload('Type/IntRangeType.gd')
const FloatRangeType = preload('Type/FloatRangeType.gd')
const FilterType = preload('Type/FilterType.gd')

## Signals

# @param  bool  is_console_shown
signal toggled(is_console_shown)
# @param  String       name
# @param  Reference    target
# @param  String|null  target_name
signal command_added(name, target, target_name)
# @param  String  name
signal command_removed(name)
# @param  Command  command
signal command_executed(command)
# @param  String  name
signal command_not_found(name)

# @var  History
var History = preload('Misc/History.gd').new(100) setget _set_readonly

# @var  Logger
var Log = preload('Misc/Logger.gd').new() setget _set_readonly

# @var  Command/CommandService
var _command_service

# Used to clear text from bb tags
# @var  RegEx
var _erase_bb_tags_regex

# @var  bool
var is_console_shown = true setget _set_readonly

# @var  bool
var consume_input = true

# @var  Control
var previous_focus_owner = null

# @var Dictionary
var bindings : Dictionary = {}


### Console nodes
onready var _console_box = $ConsoleBox
onready var Text := $ConsoleBox/Container/ConsoleText setget _set_readonly
onready var Line := $ConsoleBox/Container/ConsoleLine setget _set_readonly
onready var _animation_player = $ConsoleBox/AnimationPlayer


func _init():
	self._command_service = CommandService.new(self)
	# Used to clear text from bb tags before printing to engine output
	self._erase_bb_tags_regex = RegEx.new()
	self._erase_bb_tags_regex.compile('\\[[\\/]?[a-z0-9\\=\\#\\ \\_\\-\\,\\.\\;]+\\]')


func _ready():
	# Allow selecting console text
	self.Text.set_selection_enabled(true)
	# Follow console output (for scrolling)
	self.Text.set_scroll_follow(true)
	# React to clicks on console urls
	self.Text.connect('meta_clicked', self.Line, 'set_text')

	# Hide console by default
	self._console_box.hide()
	self._animation_player.connect("animation_finished", self, "_toggle_animation_finished")
	self.toggle_console()

	# Console keyboard control
	set_process_input(true)

	# Show some info
	var v = Engine.get_version_info()
	self.write_line(\
		ProjectSettings.get_setting("application/config/name") + \
		" (Godot " + str(v.major) + '.' + str(v.minor) + '.' + str(v.patch) + ' ' + v.status+")\n" + \
		"Type [color=#ffff66][url=help]help[/url][/color] to get more information about usage")

	# Init base commands
	self.BaseCommands.new(self)


# @param  InputEvent  e
func _input(e: InputEvent):
	var enabled = Args.find_option(Args.USE_CONSOLE) or OS.has_feature("debug")
	if enabled and Input.is_action_just_pressed(DefaultActions.CONSOLE_TOGGLE):
		self.toggle_console()
		
	if not self.is_console_shown and e is InputEventKey and not e.pressed:
		if bindings.has(e.scancode):
			var cmd = bindings[e.scancode]
			execute(cmd)


# @returns  Command/CommandService
func get_command_service():
	return self._command_service


# @param    String  name
# @returns  Command/Command|null
func get_command(name):
	return self._command_service.get(name)

# @param    String  name
# @returns  Command/CommandCollection
func find_commands(name):
	return self._command_service.find(name)

# @param    String  command
# @returns  void
func execute(command):
	self.Line.execute(command)

# @param    int  key_code
# @param    String  command
# @returns  bool
func bind_key_command(key_code, command):
	if not bindings.has(key_code):
		bindings[key_code] = command
	else:
		var key = OS.get_scancode_string(key_code)
		self.Log.warn("Key %s (%d) is already bound to command '%s' - Ignoring" % \
			 [key, key_code, bindings[key_code]])
			
	return bindings[key_code] == command

# @param    int  key_code
# @returns  void
func unbind_key(key_code):
	var key = OS.get_scancode_string(key_code)
	
	if not bindings.erase(key_code):
		self.Log.warn("No binding found for key %s (%d) - Ignoring" % \
			 [key, key_code])

func is_key_bound(key):
	var code = OS.find_scancode_from_string(key)
	
	return code != 0 and bindings.has(code)

func find_bound_command(key):
	var code = OS.find_scancode_from_string(key)
	
	return bindings.get(code)

# Example usage:
# ```gdscript
# Console.add_command('sayHello', self, 'print_hello')\
# 	.set_description('Prints "Hello %name%!"')\
# 	.add_argument('name', TYPE_STRING)\
# 	.register()
# ```
# @param    String       name
# @param    Reference    target
# @param    String|null  target_name
# @returns  Command/CommandBuilder
func add_command(name, target, target_name = null):
	emit_signal("command_added", name, target, target_name)
	return self._command_service.create(name, target, target_name)

# @param    String  name
# @returns  int
func remove_command(name):
	emit_signal("command_removed", name)
	return self._command_service.remove(name)


# @param    String  message
# @returns  void
func write(message):
	message = str(message)
	if self.Text:
		self.Text.append_bbcode(message)
	print(self._erase_bb_tags_regex.sub(message, '', true))

# @param    String  message
# @returns  void
func write_line(message = ''):
	write(str(message) + '\n')
	

func error_line(message = ''):
	write('[color=red][ERROR] ' + message + '\n[/color]')


# @returns  void
func clear():
	if self.Text:
		self.Text.clear()


# @returns  Console
func toggle_console():
	# Open the console
	if !self.is_console_shown:
		previous_focus_owner = self.Line.get_focus_owner()
		self._console_box.show()
		self.Line.clear()
		self.Line.grab_focus()
		self._animation_player.play_backwards('fade')
	else:
		self.Line.accept_event() # Prevents from DefaultActions.console_toggle key character getting into previous_focus_owner value
		if is_instance_valid(previous_focus_owner):
			previous_focus_owner.grab_focus()
		previous_focus_owner = null
		self._animation_player.play('fade')

	is_console_shown = !self.is_console_shown
	emit_signal("toggled", is_console_shown)

	return self


# @returns  void
func _toggle_animation_finished(animation):
	if !self.is_console_shown:
		self._console_box.hide()


# @returns  void
func _set_readonly(value):
	Log.warn('qc/console: _set_readonly: Attempted to set a protected variable, ignoring.')
