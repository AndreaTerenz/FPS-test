class_name SceneManager
extends Spatial

signal player_died

export(String) var scene_name = ""
export(NodePath) var player_spawn_ref
export(NodePath) var world_env_ref
export(NodePath) var sun_light_ref
export(Array, String) var gi_probes_refs = []

onready var player_spawn : Position3D = Utils.try_get_node(player_spawn_ref, self)
onready var world_env : Environment = Utils.try_get_node(world_env_ref, self)
onready var sun_light : DirectionalLight = Utils.try_get_node(sun_light_ref, self)

var gi_probes := []
var global_audio_srcs : Dictionary = {}

func _ready() -> void:
	if scene_name == "":
		scene_name = name
	
	if Utils.is_release():
		reset_debug_vars()
	
	for child in get_children():
		if not(world_env) and child is WorldEnvironment:
			world_env = child.environment
		if not(sun_light) and child is DirectionalLight:
			sun_light = child
		if child is GIProbe:
			Console.write_line("Detected GIProbe #%d (%s)" % [len(gi_probes), child.name])
			gi_probes.append(child)
		if child is AudioStreamPlayer:
			Console.write_line("Detected global audio player #%d (%s)" % [len(global_audio_srcs), child.name])
			global_audio_srcs[child] = child.volume_db
			
	for gp_r in gi_probes_refs:
		var gp = Utils.try_get_node(gp_r, self)
		if gp and not(gp.parent == self) and gp is GIProbe:
			Console.write_line("Added GIProbe #%d (%s)" % [len(gi_probes), gp.name])
			gi_probes.append(gp)
			
	if not world_env:
		Console.Log.warn("NO WORLD ENVIRONMENT DETECTED")
	else:
		Console.write_line("Detected world environment")
			
	if not sun_light:
		Console.Log.warn("NO DIRECTIONAL SUN DETECTED")
	else:
		Console.write_line("Detected directional sun light")
	
	Console.add_command("toggle_sun", self, "toggle_sun")\
	.set_description("toggles scene directional light")\
	.register()
	
	Console.add_command("toggle_sun_shadow", self, "toggle_sun_shadow")\
	.set_description("toggles scene directional light shadows")\
	.register()
	
	Console.add_command("toggle_gi_probes", self, "toggle_gi_probes")\
	.set_description("toggles GIProbes")\
	.register()
	
	Console.add_command("env_set_property", self, "env_set_property")\
	.set_description("set value for world env property")\
	.add_argument("prop", TYPE_STRING)\
	.add_argument("value", TYPE_STRING)\
	.register()
	
	Globals.set_scene_manager(self)
	
	if not Globals.player:
		yield(Globals, "player_set")
		
	Globals.player.connect("killed", self, "on_player_dead")
	spawn_player()
	
	Globals.player.tracker_save()
	
func spawn_player():
	if player_spawn:
		var p : Player = Globals.player
		p.reset_transform(
			player_spawn.global_translation,
			player_spawn.rotation_degrees.x,
			player_spawn.rotation_degrees.y)

func reset_debug_vars():
	pass
			
func on_player_dead():
	emit_signal("player_died")
	
	Globals.player.tracker_load(false)

func toggle_sun():
	if sun_light:
		sun_light.visible = not sun_light.visible
	else:
		Console.Log.warn("NO SUN FOUND IN SCENE - command failed")

func toggle_sun_shadow():
	if sun_light:
		sun_light.shadow_enabled = not sun_light.shadow_enabled
	else:
		Console.Log.warn("NO SUN FOUND IN SCENE - command failed")

func toggle_gi_probes():
	for gip in gi_probes:
		gip.visible = not gip.visible
		
func env_set_property(prop, value):
	if world_env and prop in world_env:
		#Console.write_line("Property '%s' found" % prop)
		var p = world_env.get(prop)
		var val = value
		
		match typeof(p):
			TYPE_INT:
				val = int(value)
			TYPE_BOOL:
				val = true if (value.to_lower() == "true") else false
			TYPE_REAL:
				val = float(value)
		
		#Console.write_line("%s %s" % [value, val])
		
		world_env.set(prop, val)
