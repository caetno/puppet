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
    for i in skeleton.get_bone_count():
        var name := skeleton.get_bone_name(i)
        if _pre_rotations.has(name) and _post_rotations.has(name) and _limit_signs.has(name):
            continue
        var joint_basis := _joint_basis_from_skeleton(skeleton, i)
        var bone_global := _get_global_rest(skeleton, i)
        _pre_rotations[name] = bone_global.basis * joint_basis.inverse()
        _post_rotations[name] = Basis()
        _limit_signs[name] = Vector3(
            1.0 if bone_global.basis.x.dot(joint_basis.x) >= 0.0 else -1.0,
            1.0 if bone_global.basis.y.dot(joint_basis.y) >= 0.0 else -1.0,
            1.0 if bone_global.basis.z.dot(joint_basis.z) >= 0.0 else -1.0,
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

static func _joint_basis_from_skeleton(skeleton: Skeleton3D, bone: int) -> Basis:
    var bone_global := _get_global_rest(skeleton, bone)
    var z_axis: Vector3 = bone_global.basis.z
    var child := -1
    for j in skeleton.get_bone_count():
        if skeleton.get_bone_parent(j) == bone:
            child = j
            break
    if child != -1:
        var child_global := _get_global_rest(skeleton, child)
        var dir := (child_global.origin - bone_global.origin).normalized()
        if dir.length() > 0.0:
            z_axis = dir
    var ref: Vector3 = Vector3.UP
    if abs(z_axis.dot(ref)) > 0.99:
        ref = skeleton.global_transform.basis.z
    var x_axis := ref.cross(z_axis).normalized()
    if x_axis.length() == 0.0:
        x_axis = ref.cross(Vector3.RIGHT).normalized()
    var y_axis := z_axis.cross(x_axis).normalized()
    return Basis(x_axis, y_axis, z_axis)

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
