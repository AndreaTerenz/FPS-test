extends Node

var layers = []

func _ready() -> void:
	for i in range(1, 21):
		layers.append(ProjectSettings.get_setting("layer_names/3d_physics/layer_%d" % i))

func get_layer_bit(name: String):
	return layers.find(name)
	
func get_layer_bit_in_object(obj: CollisionObject, name: String) -> bool:
	return obj.get_collision_layer_bit(get_layer_bit(name))
	
func get_mask_bit_in_object(obj: Spatial, name: String) -> bool:
	if obj is CollisionObject or obj is RayCast:
		return obj.get_collision_mask_bit(get_layer_bit(name))
	return false
	
func set_layer_bit_in_object(obj: CollisionObject, name: String, value := true):
	var bit = get_layer_bit(name)
	obj.set_collision_layer_bit(bit, value)
	
func set_mask_bit_in_object(obj: Spatial, name: String, value := true):
	if obj is CollisionObject or obj is RayCast:
		var bit = get_layer_bit(name)
		obj.set_collision_mask_bit(bit, value)
	
func set_layer_bits_in_object(obj: CollisionObject, names: PoolStringArray, value := true):
	for n in names:
		set_layer_bit_in_object(obj, n, value)
		
func set_mask_bits_in_object(obj: Spatial, names: PoolStringArray, value := true):
	if obj is CollisionObject or obj is RayCast:
		for n in names:
			set_mask_bit_in_object(obj, n, value)
	
func toggle_layer_bit_in_object(obj: CollisionObject, name: String):
	var bit = get_layer_bit(name)
	var current = get_layer_bit_in_object(obj, name)
	set_layer_bit_in_object(obj, name, not current)
	
func toggle_mask_bit_in_object(obj: Spatial, name: String):
	if obj is CollisionObject or obj is RayCast:
		var bit = get_layer_bit(name)
		var current = get_mask_bit_in_object(obj, name)
		set_mask_bit_in_object(obj, name, not current)
	
func toggle_layer_bits_in_object(obj: CollisionObject, names: PoolStringArray):
	for n in names:
		toggle_layer_bit_in_object(obj, n)
		
func toggle_mask_bits_in_object(obj: Spatial, names: PoolStringArray):
	if obj is CollisionObject or obj is RayCast:
		for n in names:
			toggle_mask_bit_in_object(obj, n)
			
static func toggle_area(a: Area, stat: bool):
	a.monitorable = stat
	a.monitoring = stat

static func bool_to_sign(b: bool):
	return 1 if b else -1

static func vec3_horizontal(v: Vector3) -> Vector2:
	return vec3_remove_axis(v, Vector3.AXIS_Y)
	
static func vec3_remove_axis(v: Vector3, axis : int = Vector3.AXIS_Y) -> Vector2:
	match axis:
		Vector3.AXIS_X: return Vector2(v.y, v.z)
		Vector3.AXIS_Y: return Vector2(v.x, v.z)
		Vector3.AXIS_Z: return Vector2(v.x, v.y)
		
	return Vector2.ZERO
	
static func vec3_deg2rad(v: Vector3):
	return Vector3(deg2rad(v.x), deg2rad(v.y), deg2rad(v.z))
	
static func vec2_deg2rad(v: Vector2):
	return Vector2(deg2rad(v.x), deg2rad(v.y))
	
static func mirror_vec2(origin: Vector2, to_mirror: Vector2):
	return origin - (origin - to_mirror)
	
static func mirror_vec3(origin: Vector3, to_mirror: Vector3):
	return origin - (origin - to_mirror)
	
static func round_vec2(v : Vector2, digits : int = 3):
	return Vector2(stepify(v.x, pow(10, -digits)), stepify(v.y, pow(10, -digits)))

func root_origin() -> Vector3:
	var root = get_tree().current_scene
	
	if root is Spatial:
		return root.global_transform.origin
	
	return Vector3.ZERO
	
func get_global_rotation(obj: Spatial):
	return obj.global_transform.basis
	
func get_global_pos(obj: Spatial, relative_to_root := true) -> Vector3:
	return obj.global_transform.origin - (root_origin() * float(relative_to_root))
	
func set_global_pos(obj: Spatial, origin: Vector3, relative_to_root := true):
	obj.global_transform.origin = origin + (root_origin() * float(relative_to_root))
	
static func copy_global_pos(source: Spatial, dest: Spatial):
	dest.global_transform.origin = source.global_transform.origin
	
static func get_dir_vector(obj: Spatial, axis := Vector3.AXIS_Z) -> Vector3:
	match axis:
		Vector3.AXIS_X: return obj.global_transform.basis.x
		Vector3.AXIS_Y: return obj.global_transform.basis.y
		Vector3.AXIS_Z: return obj.global_transform.basis.z
		
	return Vector3.ZERO
	
static func local_direction(obj: Spatial, direction : Vector3) -> Vector3:
	match direction:
		Vector3.BACK: return -obj.global_transform.basis.z
		Vector3.FORWARD: return obj.global_transform.basis.z
			
		Vector3.UP: return obj.global_transform.basis.y
		Vector3.DOWN: return -obj.global_transform.basis.y
		
		Vector3.RIGHT: return -obj.global_transform.basis.x
		Vector3.LEFT: return obj.global_transform.basis.x
		
	return Vector3.ZERO

static func lerp_rot_towards(obj: Spatial, target: Spatial, amount: float = 1.0) -> Quat:
	var target_pos = Utils.get_global_pos(target)
	var obj_pos = Utils.get_global_pos(obj)
	var obj_global_tr = obj.global_transform
	
	var wtransform = obj_global_tr.looking_at(target_pos,Vector3.UP)
	
	return Utils.transform2quat(obj_global_tr).slerp(Utils.transform2quat(wtransform), amount)
	
static func transform2quat(tr: Transform) -> Quat:
	return Quat(tr.basis)
	
static func rotate_with_mouse(event: InputEventMouseMotion, node: Spatial, x_rot_node : Spatial, sensitivity := .1 , head_rot_lim := 80.0, invert_y := false):
	var event_rel : Vector2 = Utils.vec2_deg2rad(-event.relative * sensitivity)
	var y_rot = event_rel.x

	node.rotate_y(y_rot)
	x_rot_node.rotate_x(event_rel.y * -bool_to_sign(invert_y))

	var hrl = deg2rad(head_rot_lim)
	x_rot_node.rotation.x = clamp(x_rot_node.rotation.x, -hrl, hrl)
	
static func delete_children(node):
	for n in node.get_children():
		n.queue_free()
		
func transfer_node(obj: Node, new_parent: Node = null):
	obj.get_parent().remove_child(obj)
	
	if new_parent:
		new_parent.add_child(obj)
	else:
		get_tree().root.add_child(obj)

static func log_line(obj: Node, msg: String):
	var time = OS.get_time()
	var time_str = "%02d:%02d:%02d" % [time.hour, time.minute, time.second]
	Console.write_line("@%s [%s]: %s" % [time_str, obj.name, msg])

static func list_files_in_directory(path, extensions = [], include_hidden = false) -> PoolStringArray:
	var files : PoolStringArray = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	var done = false
	while not done:
		var file : String = dir.get_next()
		done = (file == "")
		
		var is_visible = (not file.begins_with(".") or include_hidden)
		var correct_ext = (len(extensions) == 0 or file.get_extension() in extensions)
		
		if is_visible and correct_ext:
			files.append(file)

	dir.list_dir_end()

	return files
