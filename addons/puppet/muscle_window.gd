@tool
extends Window

## Editor window for muscle configuration.
var editor_plugin: EditorPlugin

const MuscleData = preload("res://addons/puppet/muscle_data.gd")
const MuscleProfile = preload("res://addons/puppet/profile_resource.gd")
const HumanoidScene = preload("res://humanoid_example.tscn")

var _profile: MuscleProfile = MuscleProfile.new()
var _model: Node3D

@onready var _list: VBoxContainer = $VBox/Main/Right/List
@onready var _tree: Tree = $VBox/Main/Left/NodeTree
@onready var _viewport: SubViewport = $VBox/Main/ViewportPane/SubViewport
@onready var _picker: EditorResourcePicker = $VBox/Top/ProfilePicker

func _ready() -> void:
    title = "Humanoid Muscles"
    size = Vector2(1200, 600)
    _setup_picker()
    _load_default_profile()
    _load_model()
    _populate_tree()
    _populate_list()

func _setup_picker() -> void:
    _picker.base_type = "MuscleProfile"
    _picker.edited_resource = _profile
    _picker.resource_changed.connect(_on_profile_changed)

func _on_profile_changed(res: Resource) -> void:
    if res:
        _profile = res
    else:
        _profile = MuscleProfile.new()
        _load_default_profile()
    _populate_list()

func _load_model() -> void:
    for child in _viewport.get_children():
        child.queue_free()
    _model = HumanoidScene.instantiate()
    _viewport.add_child(_model)
    var cam := Camera3D.new()
    cam.position = Vector3(0, 1.5, 3)
    cam.look_at(Vector3.ZERO)
    _viewport.add_child(cam)
    _viewport.camera_3d = cam
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45, -30, 0)
    _viewport.add_child(light)

func _populate_tree() -> void:
    _tree.clear()
    var root := _tree.create_item()
    root.set_text(0, _model.name)
    _add_tree_items(root, _model)

func _add_tree_items(parent: TreeItem, node: Node) -> void:
    for child in node.get_children():
        var item := _tree.create_item(parent)
        item.set_text(0, child.name)
        _add_tree_items(item, child)

func _load_default_profile() -> void:
    _profile.muscles.clear()
    for muscle in MuscleData.DEFAULT_MUSCLES:
        _profile.muscles[str(muscle["muscle_id"])] = muscle.duplicate(true)

func _populate_list() -> void:
    for child in _list.get_children():
        child.queue_free()
    for id in _profile.muscles.keys():
        var data = _profile.muscles[id]
        var row := HBoxContainer.new()
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
        slider.value_changed.connect(func(v, id=id): _profile.muscles[id]["default_deg"] = v)
        row.add_child(slider)

