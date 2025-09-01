@tool
class_name BoneOrientation

## Stores pre/post rotation and limit sign data for humanoid bones.
# The data can be generated from Unity's Avatar API and cached as JSON so the
# addon can use the information without requiring Unity at runtime.

const CACHE_PATH := "res://addons/puppet/bone_orientation_data.json"

static var _pre_rotations: Dictionary = {}
static var _post_rotations: Dictionary = {}
static var _limit_signs: Dictionary = {}
static var _loaded := false

## Ensures the cached orientation data is loaded from disk.
static func load_cache(path: String = CACHE_PATH, skeleton: Skeleton3D = null) -> void:
    if not _loaded:
        _loaded = true
        if FileAccess.file_exists(path):
            var file := FileAccess.open(path, FileAccess.READ)
            if file:
                var json := JSON.new()
                if json.parse(file.get_as_text()) == OK:
                    var data: Dictionary = json.data
                    _pre_rotations = _parse_basis_dict(data.get("pre_rotations", {}))
                    _post_rotations = _parse_basis_dict(data.get("post_rotations", {}))
                    _limit_signs = _parse_vector_dict(data.get("limit_signs", {}))
    if skeleton:
        generate_from_skeleton(skeleton)

## Generates orientation data from a Unity export and saves it to the cache.
# `unity_json_path` should be a JSON file produced by a Unity editor script that
# queries Avatar.GetPreRotation / GetPostRotation / GetLimitSign for each bone.
static func generate_from_unity(unity_json_path: String, cache_path: String = CACHE_PATH) -> void:
    var file := FileAccess.open(unity_json_path, FileAccess.READ)
    if not file:
        push_warning("Unity export file not found: %s" % unity_json_path)
        return
    var json := JSON.new()
    if json.parse(file.get_as_text()) != OK:
        push_error("Failed to parse Unity export JSON: %s" % unity_json_path)
        return
    var data: Dictionary = json.data
    _pre_rotations = _parse_basis_dict(data.get("preRotations", data.get("pre_rotations", {})))
    _post_rotations = _parse_basis_dict(data.get("postRotations", data.get("post_rotations", {})))
    _limit_signs = _parse_vector_dict(data.get("limitSigns", data.get("limit_signs", {})))
    _save_cache(cache_path)

## Generates orientation data for the bones present in `skeleton`.
## Results are stored in the static dictionaries, augmenting any cache data.
static func generate_from_skeleton(skeleton: Skeleton3D) -> void:
    if not skeleton:
        return

    var ref_basis := _reference_basis_from_skeleton(skeleton)

    for i in skeleton.get_bone_count():
        var name := skeleton.get_bone_name(i)
        if _pre_rotations.has(name) and _post_rotations.has(name) and _limit_signs.has(name):
            continue

        var joint_basis := _derive_bone_basis(skeleton, i, ref_basis)

        var bone_global := _get_global_rest(skeleton, i)

        # Pre/post rotations map the joint frame to the rest pose similar to
        # Unity's Avatar.GetPreRotation / GetPostRotation.
        var parent := skeleton.get_bone_parent(i)
        var parent_global := Transform3D.IDENTITY
        if parent != -1:
            parent_global = _get_global_rest(skeleton, parent)
        var joint_local := parent_global.basis.inverse() * joint_basis
        var bone_local := skeleton.get_bone_rest(i).basis

        _pre_rotations[name] = bone_local * joint_local.inverse()
        _post_rotations[name] = Basis()

        _limit_signs[name] = Vector3(
            1.0 if bone_local.x.dot(joint_local.x) >= 0.0 else -1.0,
            1.0 if bone_local.y.dot(joint_local.y) >= 0.0 else -1.0,
            1.0 if bone_local.z.dot(joint_local.z) >= 0.0 else -1.0,
        )

static func get_pre_rotation(bone: String, skeleton: Skeleton3D = null) -> Basis:
    load_cache(CACHE_PATH, skeleton)
    return _pre_rotations.get(bone, Basis())

static func get_post_rotation(bone: String, skeleton: Skeleton3D = null) -> Basis:
    load_cache(CACHE_PATH, skeleton)
    return _post_rotations.get(bone, Basis())

static func get_limit_sign(bone: String, skeleton: Skeleton3D = null) -> Vector3:
    load_cache(CACHE_PATH, skeleton)
    return _limit_signs.get(bone, Vector3.ONE)

static func apply_rotations(bone: String, basis: Basis, skeleton: Skeleton3D = null) -> Basis:
    return get_pre_rotation(bone, skeleton) * basis * get_post_rotation(bone, skeleton)

# -- Runtime generation helpers ---------------------------------------------

static func _get_global_rest(skeleton: Skeleton3D, bone: int) -> Transform3D:
    var t := skeleton.get_bone_rest(bone)
    var parent := skeleton.get_bone_parent(bone)
    while parent != -1:
        t = skeleton.get_bone_rest(parent) * t
        parent = skeleton.get_bone_parent(parent)
    return t

## Builds a global reference basis (sideways, up, forward) from hip and shoulder
## positions.  If required bones are missing the skeleton's global transform is
## used instead.
static func _reference_basis_from_skeleton(skeleton: Skeleton3D) -> Basis:
    if not skeleton:
        return Basis()

    var left_leg := skeleton.find_bone("LeftUpperLeg")
    if left_leg == -1:
        left_leg = skeleton.find_bone("LeftUpLeg")
    var right_leg := skeleton.find_bone("RightUpperLeg")
    if right_leg == -1:
        right_leg = skeleton.find_bone("RightUpLeg")

    var left_shoulder := skeleton.find_bone("LeftShoulder")
    if left_shoulder == -1:
        left_shoulder = skeleton.find_bone("LeftUpperArm")
    var right_shoulder := skeleton.find_bone("RightShoulder")
    if right_shoulder == -1:
        right_shoulder = skeleton.find_bone("RightUpperArm")

    if left_leg == -1 or right_leg == -1 or left_shoulder == -1 or right_shoulder == -1:
        return skeleton.global_transform.basis

    var left_leg_pos := _get_global_rest(skeleton, left_leg).origin
    var right_leg_pos := _get_global_rest(skeleton, right_leg).origin
    var left_shoulder_pos := _get_global_rest(skeleton, left_shoulder).origin
    var right_shoulder_pos := _get_global_rest(skeleton, right_shoulder).origin

    var sideways := (right_leg_pos - left_leg_pos + right_shoulder_pos - left_shoulder_pos) * 0.5
    if sideways.length() == 0.0:
        sideways = Vector3.RIGHT
    sideways = sideways.normalized()

    var hip_center := (left_leg_pos + right_leg_pos) * 0.5
    var shoulder_center := (left_shoulder_pos + right_shoulder_pos) * 0.5
    var up := (shoulder_center - hip_center).normalized()
    if up.length() == 0.0:
        up = Vector3.UP

    var forward := sideways.cross(up).normalized()
    if forward.length() == 0.0:
        forward = Vector3.FORWARD
    up = forward.cross(sideways).normalized()
    return Basis(sideways, up, forward)

## Derives the joint basis for `bone` using `ref_basis` for sideways and up
## directions.  The bone's longitudinal axis is the average direction of all its
## children.
static func _derive_bone_basis(skeleton: Skeleton3D, bone: int, ref_basis: Basis) -> Basis:
    var bone_global := _get_global_rest(skeleton, bone)

    var z_axis := Vector3.ZERO
    var child_count := 0
    for j in skeleton.get_bone_count():
        if skeleton.get_bone_parent(j) == bone:
            var child_global := _get_global_rest(skeleton, j)
            var dir := (child_global.origin - bone_global.origin).normalized()
            if dir.length() > 0.0:
                z_axis += dir
                child_count += 1

    if child_count == 0:
        z_axis = bone_global.basis.z.normalized()
    else:
        z_axis = z_axis.normalized()

    var x_axis := (ref_basis.x - z_axis * ref_basis.x.dot(z_axis))
    if x_axis.length() == 0.0:
        x_axis = ref_basis.y.cross(z_axis)
    x_axis = x_axis.normalized()

    var y_axis := z_axis.cross(x_axis).normalized()
    if y_axis.dot(ref_basis.y) < 0.0:
        y_axis = -y_axis
        x_axis = -x_axis

    return Basis(x_axis, y_axis, z_axis)

## Exposed helper so other scripts can derive a joint basis from the skeleton's
## geometry.
static func joint_basis_from_skeleton(skeleton: Skeleton3D, bone: int) -> Basis:
    load_cache(CACHE_PATH, skeleton)
    var ref := _reference_basis_from_skeleton(skeleton)
    return _derive_bone_basis(skeleton, bone, ref)

# -- Serialization helpers --------------------------------------------------

static func _parse_basis_dict(src: Dictionary) -> Dictionary:
    var result := {}
    for k in src.keys():
        var arr = src[k]
        if arr is Array and arr.size() == 4:
            var q := Quaternion(arr[0], arr[1], arr[2], arr[3])
            result[k] = Basis(q)
    return result

static func _parse_vector_dict(src: Dictionary) -> Dictionary:
    var result := {}
    for k in src.keys():
        var arr = src[k]
        if arr is Array and arr.size() == 3:
            result[k] = Vector3(arr[0], arr[1], arr[2])
    return result

static func _serialize_basis_dict(src: Dictionary) -> Dictionary:
    var res := {}
    for k in src.keys():
        var b: Basis = src[k]
        var q: Quaternion = Quaternion(b)
        res[k] = [q.x, q.y, q.z, q.w]
    return res

static func _serialize_vector_dict(src: Dictionary) -> Dictionary:
    var res := {}
    for k in src.keys():
        var v: Vector3 = src[k]
        res[k] = [v.x, v.y, v.z]
    return res

static func _save_cache(path: String) -> void:
    var data := {
        "pre_rotations": _serialize_basis_dict(_pre_rotations),
        "post_rotations": _serialize_basis_dict(_post_rotations),
        "limit_signs": _serialize_vector_dict(_limit_signs),
    }
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))
        file.close()
