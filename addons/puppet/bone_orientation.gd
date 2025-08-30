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
static func load_cache(path: String = CACHE_PATH) -> void:
    if _loaded:
        return
    _loaded = true
    if not FileAccess.file_exists(path):
        return
    var file := FileAccess.open(path, FileAccess.READ)
    if not file:
        return
    var json := JSON.new()
    if json.parse(file.get_as_text()) != OK:
        return
    var data: Dictionary = json.data
    _pre_rotations = _parse_basis_dict(data.get("pre_rotations", {}))
    _post_rotations = _parse_basis_dict(data.get("post_rotations", {}))
    _limit_signs = _parse_vector_dict(data.get("limit_signs", {}))

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

static func get_pre_rotation(bone: String) -> Basis:
    load_cache()
    return _pre_rotations.get(bone, Basis())

static func get_post_rotation(bone: String) -> Basis:
    load_cache()
    return _post_rotations.get(bone, Basis())

static func get_limit_sign(bone: String) -> Vector3:
    load_cache()
    return _limit_signs.get(bone, Vector3.ONE)

static func apply_rotations(bone: String, basis: Basis) -> Basis:
    return get_pre_rotation(bone) * basis * get_post_rotation(bone)

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
