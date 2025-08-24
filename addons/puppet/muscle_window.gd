@tool
extends Window

## Placeholder editor window for muscle configuration.
var editor_plugin: EditorPlugin

var _profile: MuscleProfile
@onready var _picker: EditorResourcePicker = $VBox/ProfilePicker

func _ready() -> void:
    title = "Humanoid Muscles"
    size = Vector2(800, 600)
    _picker.base_type = "MuscleProfile"
    _picker.allow_create = true
    _picker.resource_changed.connect(_on_picker_resource_changed)

func _on_picker_resource_changed(res: Resource) -> void:
    if _profile and _profile.changed.is_connected(_on_muscle_edited):
        _profile.changed.disconnect(_on_muscle_edited)
    if res == null:
        _profile = MuscleProfile.new()
        _picker.resource = _profile
        _load_default_profile()
    else:
        _profile = res
    _profile.changed.connect(_on_muscle_edited)

func _load_default_profile() -> void:
    _profile.muscles.clear()
    for muscle in MuscleData.DEFAULT_MUSCLES:
        _profile.muscles[muscle["bone_ref"]] = muscle
    _on_muscle_edited()

func _on_muscle_edited() -> void:
    if _profile and _profile.resource_path != "":
        ResourceSaver.save(_profile.resource_path, _profile)
