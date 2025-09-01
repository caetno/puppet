@tool
extends Window
class_name MuscleWindow

const PuppetProfile = preload("res://addons/puppet/profile_resource.gd")
const MuscleData = preload("res://addons/puppet/muscle_data.gd")
const DualSlider = preload("res://addons/puppet/dual_slider.gd")
const OrientationBaker = preload("res://addons/puppet/bone_orientation.gd")
const JointConverter = preload("res://addons/puppet/joint_converter.gd")

## Editor window for muscle configuration.
var editor_plugin: EditorPlugin
var _profile: PuppetProfile = PuppetProfile.new()
var _model: Node3D

@onready var _list: VBoxContainer = $VBox/Main/Right/Scroll/List
@onready var _viewport_container: SubViewportContainer = $VBox/Main/ViewportPane
@onready var _viewport: SubViewport = $VBox/Main/ViewportPane/SubViewport
@onready var _picker: EditorResourcePicker = $VBox/Top/ProfilePicker
@onready var _tree: Tree = $VBox/Main/Left/Tree
@onready var _reset_button: Button = $VBox/Top/ResetButton
@onready var _rebake_button: Button = $VBox/Top/RebakeButton

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
	_rebake_button.pressed.connect(_on_rebake_pressed)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_viewport_container.gui_input.connect(_on_viewport_input)
	_viewport.world_3d = World3D.new()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		hide()

func _setup_picker() -> void:
        _picker.base_type = "PuppetProfile"
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
                _profile = PuppetProfile.new()
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
                        _profile.bake_bones(skeleton)
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
                "X": [],
                "Y": [],
                "Z": [],
        }

	var grouped: Dictionary = {}
	for id in _profile.muscles.keys():
		var data = _profile.muscles[id]
		var grp: String = data.get("group", "Misc")
		if not grouped.has(grp):
			grouped[grp] = []
		grouped[grp].append(id)

                var axis: String = data.get("axis", "")
                if _group_muscles.has(axis):
                        _group_muscles[axis].append(id)

        var header := Label.new()
        header.text = "Axis Groups"
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_child(header)
        var type_order := ["X", "Y", "Z"]
        for g in type_order:
                var row := HBoxContainer.new()
                row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                _list.add_child(row)
                var label := Label.new()
                label.text = "Axis %s" % g
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
	var skeleton := (_model if _model is Skeleton3D else _model.get_node_or_null("Skeleton")) as Skeleton3D
	if skeleton:
		for i in range(skeleton.get_bone_count()):
			skeleton.set_bone_local_pose_override(i, Transform3D(), 0.0, false)
	for id in _profile.muscles.keys():
		var muscle = _profile.muscles[id]
		muscle["default_deg"] = 0.0
		var slider: HSlider = _sliders.get(id)
		if slider:
			slider.set_value_no_signal(0.0)
	for g in _group_sliders.keys():
		_group_sliders[g].set_value_no_signal(0.0)
	_apply_all_muscles()

func _on_rebake_pressed() -> void:
	var skeleton := (_model if _model is Skeleton3D else _model.get_node_or_null("Skeleton")) as Skeleton3D
	if skeleton:
		BoneOrientation.generate_from_skeleton(skeleton)
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


	var bone_angles := {}
	for id in _profile.muscles.keys():
		var data = _profile.muscles[id]
		var bone_name: String = data.get("bone_ref", "")
		if not _base_local_poses.has(bone_name):
			if not _warned_bones.has(bone_name):
				push_warning("Missing bone '%s' for muscle '%s'" % [bone_name, id])
				_warned_bones[bone_name] = true
			continue
		var axis_idx := _axis_to_index(data.get("axis", ""))
		if axis_idx == -1:
			continue
                var sign := _profile.get_mirror(bone_name)
                var sign_val = [sign.x, sign.y, sign.z][axis_idx]
		var angle = deg_to_rad(data.get("default_deg", 0.0)) * sign_val
		var angles: Vector3 = bone_angles.get(bone_name, Vector3.ZERO)
		if axis_idx == 0:
			angles.x += angle
		elif axis_idx == 1:
			angles.y += angle
		else:
			angles.z += angle
		bone_angles[bone_name] = angles

	var rotations := {}
	for bone_name in bone_angles.keys():
		var basis := _bone_basis_from_skeleton(bone_name, skeleton)
		var angles: Vector3 = bone_angles[bone_name]
		rotations[bone_name] = _compose_rotation(basis, angles, bone_name)

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

func _axis_to_index(axis: String) -> int:
	return JointConverter.axis_to_index(axis)

func _compose_rotation(basis: Basis, angles: Vector3, bone: String) -> Basis:
        var order := _profile.get_dof_order(bone)
        var parts := {
		"x": Basis(basis.x, angles.x),
		"y": Basis(basis.y, angles.y),
		"z": Basis(basis.z, angles.z),
	}
	var rot := Basis()
	for k in order:
		rot = rot * parts[k]
	return rot


func _bone_basis_from_skeleton(bone_name: String, skeleton: Skeleton3D) -> Basis:
        var idx := skeleton.find_bone(bone_name)
        if idx == -1:
                return Basis()
        var basis := OrientationBaker.joint_basis_from_skeleton(skeleton, idx)
        return Basis(_profile.get_pre_quaternion(bone_name)) * basis
