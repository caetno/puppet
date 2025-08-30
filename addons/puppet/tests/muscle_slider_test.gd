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
    var results := {}
    var order := []
    var axes_by_bone := {}

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
        results[id] = {
            "id": id,
            "bone": bone_name,
            "axis": axis_name,
            "angle": angle_deg,
            "alignment": alignment,
            "axis_vec": axis_vec,
            "ok": abs(alignment) > 0.95 and abs(angle_deg - test_angle) < 0.5,
        }
        order.append(id)
        if not axes_by_bone.has(bone_name):
            axes_by_bone[bone_name] = []
        axes_by_bone[bone_name].append(id)

    for bone_name in axes_by_bone.keys():
        var ids = axes_by_bone[bone_name]
        for i in range(ids.size()):
            for j in range(i + 1, ids.size()):
                var v1: Vector3 = results[ids[i]]["axis_vec"]
                var v2: Vector3 = results[ids[j]]["axis_vec"]
                if abs(v1.dot(v2)) > 0.95:
                    results[ids[i]]["ok"] = false
                    results[ids[i]]["dup_with"] = ids[j]
                    results[ids[j]]["ok"] = false
                    results[ids[j]]["dup_with"] = ids[i]

    var all_ok := true
    for id in order:
        var r = results[id]
        print("%s (%s %s): angle %.2f alignment %.2f %s%s" % [
            r["id"], r["bone"], r["axis"], r["angle"], r["alignment"],
            ("OK" if r["ok"] else "Mismatch"),
            ("" if not r.has("dup_with") else " duplicate with %s" % r["dup_with"]),
        ])
        if not r["ok"]:
            all_ok = false

    call_deferred("quit", 0 if all_ok else 1)

func _axis_to_vector(axis: String, bone_name: String, skeleton: Skeleton3D, base_global: Dictionary) -> Vector3:
    var basis: Basis = _bone_basis_from_skeleton(bone_name, skeleton, base_global)
    var sign: Vector3 = BoneOrientation.get_limit_sign(bone_name)
    match axis:
        "front_back", "nod", "open_close":
            return basis.y * sign.y
        "down_up":
            return basis.x * sign.x
        "left_right", "tilt", "finger_open_close":
            return basis.x * sign.x
        "roll_in_out", "twist":
            return -basis.z * sign.z
        _:
            return Vector3.ZERO

func _canonical_axis(axis: String, bone_name: String, skeleton: Skeleton3D, base_global: Dictionary) -> Vector3:
    var basis: Basis = _bone_basis_from_skeleton(bone_name, skeleton, base_global)
    match axis:
        "front_back", "nod", "open_close":
            return basis.y
        "down_up":
            return basis.x
        "left_right", "tilt", "finger_open_close":
            return basis.x
        "roll_in_out", "twist":
            return -basis.z
        _:
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
