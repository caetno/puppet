@tool
extends Window

## Editor window for muscle configuration.
var editor_plugin: EditorPlugin

const MuscleData = preload("res://addons/puppet/muscle_data.gd")
const MuscleIO = preload("res://addons/puppet/io.gd")
const MuscleProfile = preload("res://addons/puppet/profile_resource.gd")

var _profile: MuscleProfile = MuscleProfile.new()

@onready var _list: VBoxContainer = $VBox/Scroll/List
@onready var _load_dialog: FileDialog = $LoadDialog
@onready var _save_dialog: FileDialog = $SaveDialog

func _ready() -> void:
    title = "Humanoid Muscles"
    size = Vector2(800, 600)
    _load_default_profile()
    _populate_list()
    $VBox/Buttons/LoadButton.pressed.connect(_on_load_pressed)
    $VBox/Buttons/SaveButton.pressed.connect(_on_save_pressed)
    _load_dialog.file_selected.connect(_on_load_file_selected)
    _save_dialog.file_selected.connect(_on_save_file_selected)

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

        var enabled := CheckBox.new()
        enabled.button_pressed = data.get("enabled", true)
        enabled.toggled.connect(func(v, id=id): _profile.muscles[id]["enabled"] = v)
        row.add_child(enabled)

        var label := Label.new()
        label.text = "%s / %s" % [data.get("bone_ref", ""), data.get("axis", "")]
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(label)

        var min_box := SpinBox.new()
        min_box.min_value = -180.0
        min_box.max_value = 180.0
        min_box.step = 1.0
        min_box.value = data.get("min_deg", 0.0)
        min_box.value_changed.connect(func(v, id=id): _profile.muscles[id]["min_deg"] = v)
        row.add_child(min_box)

        var max_box := SpinBox.new()
        max_box.min_value = -180.0
        max_box.max_value = 180.0
        max_box.step = 1.0
        max_box.value = data.get("max_deg", 0.0)
        max_box.value_changed.connect(func(v, id=id): _profile.muscles[id]["max_deg"] = v)
        row.add_child(max_box)

        var def_box := SpinBox.new()
        def_box.min_value = -180.0
        def_box.max_value = 180.0
        def_box.step = 1.0
        def_box.value = data.get("default_deg", 0.0)
        def_box.value_changed.connect(func(v, id=id): _profile.muscles[id]["default_deg"] = v)
        row.add_child(def_box)

func _on_load_pressed() -> void:
    _load_dialog.popup_centered()

func _on_save_pressed() -> void:
    _save_dialog.popup_centered()

func _on_load_file_selected(path: String) -> void:
    var file := FileAccess.open(path, FileAccess.READ)
    if file:
        var text := file.get_as_text()
        _profile = MuscleIO.from_json(text)
        _populate_list()

func _on_save_file_selected(path: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file:
        file.store_string(MuscleIO.to_json(_profile))
