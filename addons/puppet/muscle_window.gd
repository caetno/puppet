@tool
extends Window
class_name MuscleWindow

const MuscleProfile = preload("res://addons/puppet/profile_resource.gd")
const MuscleData = preload("res://addons/puppet/muscle_data.gd")
const DualSlider = preload("res://addons/puppet/dual_slider.gd")
const BoneOrientation = preload("res://addons/puppet/bone_orientation.gd")

## Editor window for muscle configuration.
var editor_plugin: EditorPlugin
var _profile: MuscleProfile = MuscleProfile.new()
var _model: Node3D

@onready var _list: VBoxContainer = $VBox/Main/Right/Scroll/List
@onready var _viewport_container: SubViewportContainer = $VBox/Main/ViewportPane
@onready var _viewport: SubViewport = $VBox/Main/ViewportPane/SubViewport
@onready var _picker: EditorResourcePicker = $VBox/Top/ProfilePicker
@onready var _tree: Tree = $VBox/Main/Left/Tree
@onready var _reset_button: Button = $VBox/Top/ResetButton

var _orbiting := false
var _pivot: Node3D
var _camera: Camera3D
var _cam_distance := 3.0
var _cam_rotation := Vector2.ZERO
var _base_global_poses := {}
var _base_local_poses := {}
var _warned_bones := {}
var _sliders := {}
var _group_muscles := {}
var _group_sliders := {}

func _ready() -> void:
	title = "Humanoid Muscles"
	var screen_size := DisplayServer.screen_get_size()
	size = (screen_size * 0.8).max(Vector2(800, 600))
	move_to_center()
	close_requested.connect(func(): hide())
	_setup_picker()
	_reset_button.pressed.connect(_on_reset_pressed)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_viewport_container.gui_input.connect(_on_viewport_input)
	_viewport.world_3d = World3D.new()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hide()

func _setup_picker() -> void:
	_picker.base_type = "MuscleProfile"
	_picker.edited_resource = _profile
	_picker.resource_changed.connect(_on_profile_changed)

func _on_profile_changed(res: Resource) -> void:
	if res:
		_profile = res
		if _profile.muscles.is_empty():
			var skeleton := (_model if _model is Skeleton3D else _model.get_node_or_null("Skeleton")) as Skeleton3D
			if skeleton:
				_profile.load_from_skeleton(skeleton)
	else:
		_profile = MuscleProfile.new()
		var skeleton := (_model if _model is Skeleton3D else _model.get_node_or_null("Skeleton")) as Skeleton3D
		if skeleton:
			_profile.load_from_skeleton(skeleton)
	_populate_list()
	_apply_all_muscles()

func load_skeleton(skeleton: Skeleton3D) -> void:
	_load_model(skeleton)
	_populate_list()
	_apply_all_muscles()

func _load_model(src: Node3D) -> void:
	for child in _viewport.get_children():
		child.queue_free()
	_model = src.duplicate()
	_remove_physical_bones(_model)

	_viewport.add_child(_model)
	_pivot = Node3D.new()
	_viewport.add_child(_pivot)
	_camera = Camera3D.new()
	_camera.position = Vector3(0, 1.5, _cam_distance)
	_pivot.add_child(_camera)
	_camera.look_at(Vector3.ZERO, Vector3.UP)
	_camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	_viewport.add_child(light)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.2, 0.2, 0.2)
	_viewport.add_child(env)
	var skeleton := (_model if _model is Skeleton3D else _model.get_node_or_null("Skeleton")) as Skeleton3D
	if skeleton:
		if _profile.muscles.is_empty():
			_profile.load_from_skeleton(skeleton)
		else:
			_profile.skeleton = _model.get_path_to(skeleton)
	_cache_bone_poses()
	_populate_tree()

func _remove_physical_bones(node: Node) -> void:
	if node is PhysicalBoneSimulator3D:
		node.queue_free()
		return
	for child in node.get_children():
		_remove_physical_bones(child)

func _populate_tree() -> void:
	_tree.clear()
	var root := _tree.create_item()
	_tree.hide_root = true
	var skeleton := (_model if _model is Skeleton3D else _model.get_node_or_null("Skeleton")) as Skeleton3D
	if not skeleton:
		return
	var items := {}
	for i in range(skeleton.get_bone_count()):
		var parent := skeleton.get_bone_parent(i)
		var parent_item := root if parent == -1 else items.get(parent, root)
		var item := _tree.create_item(parent_item)
		item.set_text(0, skeleton.get_bone_name(i))
		items[i] = item

func _populate_list() -> void:
	for child in _list.get_children():
		child.queue_free()

	_sliders.clear()
	_group_sliders.clear()
	_group_muscles = {
		"Open Close": [],
		"Left Right": [],
		"Roll Left Right": [],
		"In Out": [],
		"Roll In Out": [],
		"Finger Open Close": [],
		"Finger In Out": [],
	}

	var grouped: Dictionary = {}
	for id in _profile.muscles.keys():
		var data = _profile.muscles[id]
		var grp: String = data.get("group", "Misc")
		if not grouped.has(grp):
			grouped[grp] = []
		grouped[grp].append(id)

		var axis: String = data.get("axis", "")
		var body_grp: String = data.get("group", "")
		if axis == "finger_open_close":
			_group_muscles["Finger Open Close"].append(id)
		elif axis == "finger_in_out":
			_group_muscles["Finger In Out"].append(id)
		elif axis == "tilt":
			_group_muscles["Roll Left Right"].append(id)
		elif axis in ["roll_in_out", "twist"]:
			_group_muscles["Roll In Out"].append(id)
		elif axis == "left_right":
			if body_grp in ["Left Arm", "Right Arm", "Left Leg", "Right Leg"]:
				_group_muscles["In Out"].append(id)
			else:
				_group_muscles["Left Right"].append(id)
		else:
			_group_muscles["Open Close"].append(id)

	var header := Label.new()
	header.text = "Muscle Type Groups"
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_child(header)
	var type_order := [
		"Open Close",
		"Left Right",
		"Roll Left Right",
		"In Out",
		"Roll In Out",
		"Finger Open Close",
		"Finger In Out",
	]
	for g in type_order:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_list.add_child(row)
		var label := Label.new()
		label.text = g
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var slider := HSlider.new()
		slider.min_value = -1.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value_changed.connect(_on_group_slider_changed.bind(g))
		row.add_child(slider)
		_group_sliders[g] = slider

	var order := ["Body", "Head", "Left Arm", "Left Hand", "Right Arm", "Right Hand", "Left Leg", "Right Leg", "Misc"]
	for grp in order:
		if not grouped.has(grp):
			continue
		var section := VBoxContainer.new()
		section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_list.add_child(section)

		var header2 := Button.new()
		header2.toggle_mode = true
		header2.text = "\u25b6 %s" % grp
		header2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section.add_child(header2)

		var content := VBoxContainer.new()
		content.visible = false
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section.add_child(content)

		header2.pressed.connect(func():
			content.visible = header2.button_pressed
			header2.text = "%s %s" % ["\u25bc" if header2.button_pressed else "\u25b6", grp]
		)

		for id in grouped[grp]:
			var data = _profile.muscles[id]
			var container := VBoxContainer.new()
			container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			content.add_child(container)

			var row2 := HBoxContainer.new()
			row2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			container.add_child(row2)

			var toggle := Button.new()
			toggle.toggle_mode = true
			toggle.text = "\u25b6"
			row2.add_child(toggle)

			var label2 := Label.new()
			label2.text = "%s / %s" % [data.get("bone_ref", ""), data.get("axis", "")]
			label2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row2.add_child(label2)

			var slider2 := HSlider.new()
			slider2.min_value = data.get("min_deg", -180.0)
			slider2.max_value = data.get("max_deg", 180.0)
			slider2.step = 1.0
			slider2.value = data.get("default_deg", 0.0)
			slider2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slider2.value_changed.connect(_on_slider_changed.bind(id))
			row2.add_child(slider2)
			_sliders[id] = slider2

			var limit := DualSlider.new()
			limit.visible = false
			limit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			limit.min_value = -180.0
			limit.max_value = 180.0
			limit.set_from_muscle(data)
			container.add_child(limit)

			toggle.pressed.connect(func():
				limit.visible = toggle.button_pressed
				toggle.text = "\u25bc" if toggle.button_pressed else "\u25b6"
			)

			limit.range_changed.connect(_on_limit_changed.bind(id, slider2))

func _on_viewport_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_orbiting = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_cam_distance = max(0.5, _cam_distance - 0.2)
			_camera.position = Vector3(0, 1.5, _cam_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_cam_distance += 0.2
			_camera.position = Vector3(0, 1.5, _cam_distance)
	elif event is InputEventMouseMotion and _orbiting:
		_cam_rotation.x = clamp(_cam_rotation.x - event.relative.y * 0.01, -PI / 2, PI / 2)
		_cam_rotation.y -= event.relative.x * 0.01
		_pivot.rotation = Vector3(_cam_rotation.x, _cam_rotation.y, 0)

func _on_slider_changed(value: float, id: String) -> void:
	if _profile.muscles.has(id):
		var muscle = _profile.muscles[id]
		muscle["default_deg"] = value
		_apply_all_muscles()

func _on_limit_changed(lower: float, upper: float, id: String, slider: HSlider) -> void:
	if not _profile.muscles.has(id):
		return
	var muscle = _profile.muscles[id]
	muscle["min_deg"] = lower
	muscle["max_deg"] = upper
	slider.min_value = lower
	slider.max_value = upper
	var deg := clamp(muscle.get("default_deg", 0.0), lower, upper)
	muscle["default_deg"] = deg
	slider.set_value_no_signal(deg)
	_apply_all_muscles()

func _on_group_slider_changed(value: float, group_name: String) -> void:
	if not _group_muscles.has(group_name):
		return
	for id in _group_muscles[group_name]:
		if _profile.muscles.has(id):
			var muscle = _profile.muscles[id]
			var min_deg = muscle.get("min_deg", -180.0)
			var max_deg = muscle.get("max_deg", 180.0)
			var t = (value + 1.0) * 0.5
			var deg = lerp(min_deg, max_deg, t)
			muscle["default_deg"] = deg
			var slider = _sliders.get(id)
			if slider:
				slider.set_value_no_signal(deg)
	_apply_all_muscles()

func _on_reset_pressed() -> void:
	for id in _profile.muscles.keys():
		var muscle = _profile.muscles[id]
		muscle["default_deg"] = 0.0
		var slider: HSlider = _sliders.get(id)
		if slider:
			slider.set_value_no_signal(0.0)
	for g in _group_sliders.keys():
		_group_sliders[g].set_value_no_signal(0.0)
	_apply_all_muscles()

func _cache_bone_poses() -> void:
	_base_global_poses.clear()
	_base_local_poses.clear()
	_warned_bones.clear()
	var skeleton := (_model if _model is Skeleton3D else _model.get_node_or_null("Skeleton")) as Skeleton3D
	if skeleton:
		for i in range(skeleton.get_bone_count()):
			var name = skeleton.get_bone_name(i)
			_base_global_poses[name] = skeleton.get_bone_global_pose(i)
		for i in range(skeleton.get_bone_count()):
			var name = skeleton.get_bone_name(i)
			var parent := skeleton.get_bone_parent(i)
			if parent != -1:
				var parent_name = skeleton.get_bone_name(parent)
				_base_local_poses[name] = _base_global_poses[parent_name].affine_inverse() * _base_global_poses[name]
			else:
				_base_local_poses[name] = _base_global_poses[name]

func _apply_all_muscles() -> void:
	var skeleton := (_model if _model is Skeleton3D else _model.get_node_or_null("Skeleton")) as Skeleton3D
	if not skeleton:
		return
	skeleton.clear_bones_global_pose_override()

	var rotations := {}
	for id in _profile.muscles.keys():
		var data = _profile.muscles[id]
		var bone_name: String = data.get("bone_ref", "")
		if not _base_local_poses.has(bone_name):
			if not _warned_bones.has(bone_name):
				push_warning("Missing bone '%s' for muscle '%s'" % [bone_name, id])
				_warned_bones[bone_name] = true
			continue
		var axis_vec = _axis_to_vector(data.get("axis", ""), bone_name, skeleton)
		if axis_vec == Vector3.ZERO:
			continue
		var angle = deg_to_rad(data.get("default_deg", 0.0))
		var rot = Basis(axis_vec, angle)
		rotations[bone_name] = rotations.get(bone_name, Basis()) * rot

	for i in range(skeleton.get_bone_count()):
		if skeleton.get_bone_parent(i) == -1:
			_apply_bone_recursive(skeleton, i, Transform3D.IDENTITY, rotations)

func _apply_bone_recursive(skeleton: Skeleton3D, bone_idx: int, parent_global: Transform3D, rotations: Dictionary) -> void:
	var name := skeleton.get_bone_name(bone_idx)
	var base_local: Transform3D = _base_local_poses.get(name, Transform3D.IDENTITY)
	var rot_basis: Basis = rotations.get(name, Basis())
	var local_pose := Transform3D(base_local.basis * rot_basis, base_local.origin)
	var global_pose := parent_global * local_pose
	skeleton.set_bone_global_pose_override(bone_idx, global_pose, 1.0, true)
	for j in range(skeleton.get_bone_count()):
		if skeleton.get_bone_parent(j) == bone_idx:
			_apply_bone_recursive(skeleton, j, global_pose, rotations)

func _axis_to_vector(axis: String, bone_name: String, skeleton: Skeleton3D) -> Vector3:
	var basis: Basis = _bone_basis_from_skeleton(bone_name, skeleton)
	var sign: Vector3 = BoneOrientation.get_limit_sign(bone_name)
	if axis in ["front_back", "nod", "down_up", "finger_open_close", "open_close"]:
		return basis.x * sign.x
	elif axis == "left_right":
		return basis.y * sign.y
	elif axis in ["tilt", "roll_in_out", "twist"]:
		return -basis.z * sign.z
	else:
		return Vector3.ZERO

func _bone_basis_from_skeleton(bone_name: String, skeleton: Skeleton3D) -> Basis:
	var idx := skeleton.find_bone(bone_name)
	if idx == -1:
		return Basis()

	var bone_global: Transform3D = _base_global_poses.get(bone_name, Transform3D.IDENTITY)
	var z_axis: Vector3 = -bone_global.basis.z

	# Derive the bone direction from the first child if available.
	for i in range(skeleton.get_bone_count()):
		if skeleton.get_bone_parent(i) == idx:
			var child_name := skeleton.get_bone_name(i)
			var child_global: Transform3D = _base_global_poses.get(child_name, Transform3D.IDENTITY)
			var dir := (child_global.origin - bone_global.origin)
			if dir.length() > 0.0:
				z_axis = -dir.normalized()
				break

	var ref: Vector3 = Vector3.UP
	if abs(z_axis.dot(ref)) > 0.99:
		ref = skeleton.global_transform.basis.x

	var x_axis := ref.cross(z_axis).normalized()
	if x_axis.length() == 0.0:
		ref = skeleton.global_transform.basis.z
		x_axis = ref.cross(z_axis).normalized()
	var y_axis := z_axis.cross(x_axis).normalized()
	var basis := Basis(x_axis, y_axis, z_axis)
	return BoneOrientation.apply_rotations(bone_name, basis)
