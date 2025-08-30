extends SceneTree

const MuscleData = preload("res://addons/puppet/muscle_data.gd")
const BoneOrientation = preload("res://addons/puppet/bone_orientation.gd")

func _init() -> void:
    var ybot_scene: PackedScene = load("res://addons/puppet/tests/muscle_slider_test.tscn")
    var ragdoll: Node3D = ybot_scene.instantiate()
    root.add_child(ragdoll)
    call_deferred("_run_test", ragdoll)

func _run_test(ragdoll: Node3D) -> void:
    var skeleton: Skeleton3D = ragdoll.get_node("Y Bot/GeneralSkeleton")

    var muscles := {}
    for m in MuscleData.default_muscles():
        muscles[str(m["muscle_id"])] = m

    var base_global := {}
    for i in range(skeleton.get_bone_count()):
        var name = skeleton.get_bone_name(i)
        base_global[name] = skeleton.get_bone_global_pose(i)

    var test_angle := 10.0
    var results := []

    for id in muscles.keys():
        var muscle: Dictionary = muscles[id]
        var bone_name: String = muscle.get("bone_ref", "")
        var axis_name: String = muscle.get("axis", "")
        var idx := skeleton.find_bone(bone_name)
        if idx == -1:
            continue

        skeleton.clear_bones_global_pose_override()

        var axis_vec: Vector3 = _axis_to_vector(axis_name, bone_name, skeleton, base_global).normalized()
        var rot := Basis(axis_vec, deg_to_rad(test_angle))
        var pose: Transform3D = base_global[bone_name]
        pose.basis = pose.basis * rot
        skeleton.set_bone_global_pose_override(idx, pose, 1.0, true)

        var new_pose: Transform3D = skeleton.get_bone_global_pose(idx)
        var delta_basis: Basis = base_global[bone_name].basis.inverse() * new_pose.basis
        var delta_quat: Quaternion = Quaternion(delta_basis.orthonormalized())
        var alignment: float = axis_vec.dot(_canonical_axis(axis_name, bone_name, skeleton, base_global))
        var angle_deg: float = rad_to_deg(delta_quat.get_angle())
        var ok: bool = abs(alignment) > 0.95 and abs(angle_deg - test_angle) < 0.5
        results.append({
            "id": id,
            "bone": bone_name,
            "axis": axis_name,
            "angle": angle_deg,
            "alignment": alignment,
            "ok": ok,
        })

    for r in results:
        print("%s (%s %s): angle %.2f alignment %.2f %s" % [
            r["id"], r["bone"], r["axis"], r["angle"], r["alignment"],
            ("OK" if r["ok"] else "Mismatch")
        ])

    call_deferred("quit")

func _axis_to_vector(axis: String, bone_name: String, skeleton: Skeleton3D, base_global: Dictionary) -> Vector3:
    var basis: Basis = _bone_basis_from_skeleton(bone_name, skeleton, base_global)
    var sign: Vector3 = BoneOrientation.get_limit_sign(bone_name)
    if axis in ["front_back", "nod", "down_up", "finger_open_close", "open_close"]:
        return basis.x * sign.x
    elif axis == "left_right":
        return basis.y * sign.y
    elif axis in ["tilt", "roll_in_out", "twist"]:
        return -basis.z * sign.z
    else:
        return Vector3.ZERO

func _canonical_axis(axis: String, bone_name: String, skeleton: Skeleton3D, base_global: Dictionary) -> Vector3:
    var basis: Basis = _bone_basis_from_skeleton(bone_name, skeleton, base_global)
    if axis in ["front_back", "nod", "down_up", "finger_open_close", "open_close"]:
        return basis.x
    elif axis == "left_right":
        return basis.y
    elif axis in ["tilt", "roll_in_out", "twist"]:
        return -basis.z
    else:
        return Vector3.ZERO

func _bone_basis_from_skeleton(bone_name: String, skeleton: Skeleton3D, base_global: Dictionary) -> Basis:
    var idx := skeleton.find_bone(bone_name)
    if idx == -1:
        return Basis()

    var bone_global: Transform3D = base_global.get(bone_name, Transform3D.IDENTITY)
    var z_axis: Vector3 = -bone_global.basis.z

    for i in range(skeleton.get_bone_count()):
        if skeleton.get_bone_parent(i) == idx:
            var child_name := skeleton.get_bone_name(i)
            var child_global: Transform3D = base_global.get(child_name, Transform3D.IDENTITY)
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
