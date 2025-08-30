extends SceneTree

const MuscleData = preload("res://addons/puppet/muscle_data.gd")
const MuscleWindow = preload("res://addons/puppet/muscle_window.gd")

var _mw: MuscleWindow


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

    _mw = MuscleWindow.new()
    _mw._base_global_poses = base_global

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

        var axis_vec: Vector3 = _mw._axis_to_vector(axis_name, bone_name, skeleton).normalized()
        var rot := Basis(axis_vec, deg_to_rad(test_angle))
        var pose: Transform3D = base_global[bone_name]
        pose.basis = pose.basis * rot
        skeleton.set_bone_global_pose_override(idx, pose, 1.0, true)

        var new_pose: Transform3D = skeleton.get_bone_global_pose(idx)
        var delta_basis: Basis = base_global[bone_name].basis.inverse() * new_pose.basis
        var delta_quat: Quaternion = Quaternion(delta_basis.orthonormalized())
        var alignment: float = axis_vec.dot(_canonical_axis(axis_name, bone_name, skeleton))

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

    # Check that forearms bend upward for positive front_back values.
    var forearm_ok := true
    for side in ["Left", "Right"]:
        var bone := "%sLowerArm" % side
        var hand := "%sHand" % side
        skeleton.clear_bones_global_pose_override()
        var axis_vec := _mw._axis_to_vector("front_back", bone, skeleton).normalized()
        var pose: Transform3D = base_global[bone]
        pose.basis = pose.basis * Basis(axis_vec, deg_to_rad(test_angle))
        skeleton.set_bone_global_pose_override(skeleton.find_bone(bone), pose, 1.0, true)
        var hand_pose: Transform3D = skeleton.get_bone_global_pose(skeleton.find_bone(hand))
        var diff: Vector3 = hand_pose.origin - base_global[hand].origin
        if diff.y <= 0.0:
            print("%s forearm bent downward for positive front_back" % side)
            forearm_ok = false
        skeleton.clear_bones_global_pose_override()

    var all_ok := forearm_ok
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

func _canonical_axis(axis: String, bone_name: String, skeleton: Skeleton3D) -> Vector3:
    var basis: Basis = _mw._bone_basis_from_skeleton(bone_name, skeleton)
    match axis:
        "front_back", "nod", "finger_open_close", "open_close":
            return basis.x
        "left_right", "down_up", "tilt":
            return basis.y
        "roll_in_out", "twist":
            return -basis.z
        _:
            return Vector3.ZERO