@tool
extends Window
class_name MuscleWindow
const MuscleProfile = preload("res://addons/puppet/profile_resource.gd")

## Placeholder editor window for muscle configuration.
var editor_plugin: EditorPlugin
var _profile: MuscleProfile = MuscleProfile.new()

func _ready() -> void:
    title = "Humanoid Muscles"
    size = Vector2(800, 600)

func load_skeleton(skeleton: Skeleton3D) -> void:
    _profile.load_from_skeleton(skeleton)
