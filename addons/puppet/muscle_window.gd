@tool
extends Window

## Editor window for muscle configuration.
var editor_plugin: EditorPlugin

const MuscleData = preload("res://addons/puppet/muscle_data.gd")
const MuscleProfile = preload("res://addons/puppet/profile_resource.gd")
const HumanoidScene = preload("res://humanoid_example.tscn")

var _profile: MuscleProfile = MuscleProfile.new()
var _model: Node3D

@onready var _list: VBoxContainer = $VBox/Main/Right/Scroll/List
@onready var _viewport_container: SubViewportContainer = $VBox/Main/ViewportPane
@onready var _viewport: SubViewport = $VBox/Main/ViewportPane/SubViewport
@onready var _picker: EditorResourcePicker = $VBox/Top/ProfilePicker

var _orbiting := false
var _pivot: Node3D
var _camera: Camera3D
var _cam_distance := 3.0
var _cam_rotation := Vector2.ZERO
var _base_poses := {}

func _ready() -> void:
    title = "Humanoid Muscles"
    size = Vector2(1200, 600)
    close_requested.connect(func(): hide())
    _setup_picker()
    _load_default_profile()
    _list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _load_model()
    _populate_list()
    _apply_all_muscles()
    _viewport_container.gui_input.connect(_on_viewport_input)

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
            _load_default_profile()
    else:
        _profile = MuscleProfile.new()
        _load_default_profile()
    _update_skeleton_path()
    _populate_list()
    _apply_all_muscles()

func _load_model() -> void:
    for child in _viewport.get_children():
        child.queue_free()
    _model = HumanoidScene.instantiate()
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
    _update_skeleton_path()
    _cache_bone_poses()

func _update_skeleton_path() -> void:
    var skeleton := _model.get_node_or_null("Skeleton")
    if skeleton:
        _profile.skeleton = _model.get_path_to(skeleton)

func _load_default_profile() -> void:
    _profile.muscles.clear()
    for muscle in MuscleData.DEFAULT_MUSCLES:
        _profile.muscles[str(muscle["muscle_id"])] = muscle.duplicate(true)

func _populate_list() -> void:
    for child in _list.get_children():
        child.queue_free()

    var grouped: Dictionary = {}
    for id in _profile.muscles.keys():
        var data = _profile.muscles[id]
        var grp: String = data.get("group", "Misc")
        if not grouped.has(grp):
            grouped[grp] = []
        grouped[grp].append(id)

    var order := ["Body", "Head", "Left Arm", "Left Fingers", "Right Arm", "Right Fingers", "Left Leg", "Right Leg", "Misc"]
    for grp in order:
        if not grouped.has(grp):
            continue
        var header := Label.new()
        header.text = grp
        header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _list.add_child(header)
        for id in grouped[grp]:
            var data = _profile.muscles[id]
            var row := HBoxContainer.new()
            row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            _list.add_child(row)
            var label := Label.new()
            label.text = "%s / %s" % [data.get("bone_ref", ""), data.get("axis", "")]
            label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            row.add_child(label)

            var slider := HSlider.new()
            slider.min_value = data.get("min_deg", -180.0)
            slider.max_value = data.get("max_deg", 180.0)
            slider.step = 1.0
            slider.value = data.get("default_deg", 0.0)
            slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            slider.value_changed.connect(_on_slider_changed.bind(id))
            row.add_child(slider)

func _on_viewport_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT:
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

func _cache_bone_poses() -> void:
    _base_poses.clear()
    var skeleton := _model.get_node_or_null("Skeleton") as Skeleton3D
    if skeleton:
        for i in range(skeleton.get_bone_count()):
            var name = skeleton.get_bone_name(i)
            _base_poses[name] = skeleton.get_bone_global_pose(i)

func _apply_all_muscles() -> void:
    var skeleton := _model.get_node_or_null("Skeleton") as Skeleton3D
    if not skeleton:
        return
    skeleton.clear_bones_global_pose_override()
    for id in _profile.muscles.keys():
        var data = _profile.muscles[id]
        var bone_name: String = data.get("bone_ref", "")
        if not _base_poses.has(bone_name):
            continue
        var bone_idx = skeleton.find_bone(bone_name)
        var base: Transform3D = _base_poses[bone_name]
        var axis_vec = _axis_to_vector(data.get("axis", ""))
        var angle = deg_to_rad(data.get("default_deg", 0.0))
        var rot = Basis(axis_vec, angle)
        var new_basis = base.basis * rot
        var pose = Transform3D(new_basis, base.origin)
        skeleton.set_bone_global_pose_override(bone_idx, pose, 1.0, true)

func _axis_to_vector(axis: String) -> Vector3:
    match axis:
        "front_back", "nod", "down_up", "finger_open_close":
            return Vector3(1, 0, 0)
        "left_right":
            return Vector3(0, 1, 0)
        "tilt":
            return Vector3(0, 0, 1)
        _:
            return Vector3.ZERO

