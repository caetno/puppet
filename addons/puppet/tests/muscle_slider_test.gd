extends SceneTree

const BoneOrientation = preload("res://addons/puppet/bone_orientation.gd")

func _init() -> void:
    var scene: PackedScene = load("res://addons/puppet/tests/muscle_slider_test.tscn")
    var avatar: Node3D = scene.instantiate()
    root.add_child(avatar)

    var skeleton: Skeleton3D = avatar.get_node_or_null("Skeleton3D")
    if skeleton == null:
        push_error("Skeleton3D node not found")
        call_deferred("quit", 1)
        return

    var base_global := {}
    for i in range(skeleton.get_bone_count()):
        var name := skeleton.get_bone_name(i)
        base_global[name] = skeleton.get_bone_global_pose(i)

    var bone_name := "LeftUpperArm"
    var axis := "down_up"
    var idx := skeleton.find_bone(bone_name)
    if idx == -1:
        push_error("%s bone not found" % bone_name)
        call_deferred("quit", 1)
        return
    var before: Transform3D = skeleton.get_bone_global_pose(idx)

    var axis_vec := _axis_to_vector(axis, bone_name, skeleton, base_global)
    var rot_basis := Basis(axis_vec, deg_to_rad(45.0))
    var new_pose := Transform3D(rot_basis * before.basis, before.origin)
    skeleton.set_bone_global_pose_override(idx, new_pose, 1.0, true)

    var after: Transform3D = skeleton.get_bone_global_pose(idx)
    var diff := before.basis.get_euler().distance_to(after.basis.get_euler())
    if diff <= 0.01:
        push_error("Muscle rotation not applied")
        call_deferred("quit", 1)
    else:
        print("Muscle rotation applied")
        call_deferred("quit")

func _axis_to_vector(axis: String, bone_name: String, skeleton: Skeleton3D, base_global: Dictionary) -> Vector3:
    var bone_global: Transform3D = base_global.get(bone_name, Transform3D.IDENTITY)
    var z_axis: Vector3 = -bone_global.basis.z
    var idx := skeleton.find_bone(bone_name)
    for i in range(skeleton.get_bone_count()):
        if skeleton.get_bone_parent(i) == idx:
            var child_name := skeleton.get_bone_name(i)
            var child_global: Transform3D = base_global.get(child_name, Transform3D.IDENTITY)
            var dir := child_global.origin - bone_global.origin
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
    basis = BoneOrientation.apply_rotations(bone_name, basis)
    var sign: Vector3 = BoneOrientation.get_limit_sign(bone_name)
    if axis in ["front_back", "nod", "down_up", "finger_open_close", "open_close"]:
        return basis.x * sign.x
    elif axis == "left_right":
        return basis.y * sign.y
    elif axis in ["tilt", "roll_in_out", "twist"]:
        return -basis.z * sign.z
    else:
        return Vector3.ZERO
