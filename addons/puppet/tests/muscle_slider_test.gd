extends SceneTree

func _init() -> void:
    var avatar_scene: PackedScene = load("res://addons/puppet/tests/avatar.tscn")
    var avatar: Node3D = avatar_scene.instantiate()
    root.add_child(avatar)
    call_deferred("quit")
