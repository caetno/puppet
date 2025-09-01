@tool
class_name JointConverter

const PuppetProfile = preload("res://addons/puppet/profile_resource.gd")
const BoneOrientation = preload("res://addons/puppet/bone_orientation.gd")

const AXIS_TO_INDEX := {
    "X": 0,
    "Y": 1,
    "Z": 2,
}

static func axis_to_index(axis: String) -> int:
    return AXIS_TO_INDEX.get(axis, -1)

static func convert_to_6dof(profile: PuppetProfile, skeleton: Skeleton3D) -> void:
    if not skeleton:
        return
    # Simplified placeholder for test environment.
    pass

static func apply_limits(profile: PuppetProfile, skeleton: Skeleton3D) -> void:
    if not profile or not skeleton:
        return
    # Simplified placeholder for test environment.
    pass

static func apply_muscles(profile: PuppetProfile, skeleton: Skeleton3D, values: Dictionary) -> void:
    if not profile or not skeleton:
        return
    skeleton.reset_bone_poses()

    var bone_angles: Dictionary = {}
    for id in profile.muscles.keys():
        var data: Dictionary = profile.muscles[id]
        var bone_name: String = data.get("bone_ref", "")
        if bone_name.is_empty():
            continue
        var axis_idx: int = axis_to_index(data.get("axis", ""))
        if axis_idx == -1:
            continue
        var value: float = values.get(id, 0.0)
        var min_deg: float = data.get("min_deg", -180.0)
        var max_deg: float = data.get("max_deg", 180.0)
        var center_deg: float = data.get("default_deg", 0.0)
        var angle_deg: float = center_deg
        if value >= 0.0:
            angle_deg = center_deg + (max_deg - center_deg) * value
        else:
            angle_deg = center_deg + (center_deg - min_deg) * value
        var sign: Vector3 = BoneOrientation.get_limit_sign(bone_name, skeleton)
        var sign_val: float = [sign.x, sign.y, sign.z][axis_idx]
        var angle: float = deg_to_rad(angle_deg) * sign_val
        var current: Vector3 = bone_angles.get(bone_name, Vector3.ZERO)
        if axis_idx == 0:
            current.x += angle
        elif axis_idx == 1:
            current.y += angle
        else:
            current.z += angle
        bone_angles[bone_name] = current

    for bone_name in bone_angles.keys():
        var idx := skeleton.find_bone(bone_name)
        if idx == -1:
            continue
        var basis := BoneOrientation.joint_basis_from_skeleton(skeleton, idx)
        basis = BoneOrientation.apply_rotations(bone_name, basis, skeleton)
        var order := profile.get_dof_order(bone_name)
        var angles: Vector3 = bone_angles[bone_name]
        var parts := {
            "x": Basis(basis.x, angles.x),
            "y": Basis(basis.y, angles.y),
            "z": Basis(basis.z, angles.z),
        }
        var rot := Basis()
        for k in order:
            rot = rot * parts[k]
        var rest: Transform3D = skeleton.get_bone_rest(idx)
        var local_pose := Transform3D(rest.basis * rot, rest.origin)
        skeleton.set_bone_pose(idx, local_pose)

static func _axis_to_char(axis: String) -> String:
    var idx := axis_to_index(axis)
    var arr := ["x", "y", "z"]
    return arr[idx] if idx >= 0 and idx < arr.size() else ""

