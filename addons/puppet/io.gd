@tool
class_name PuppetIO

const PuppetProfile = preload("res://addons/puppet/profile_resource.gd")

## Helpers for profile serialization.
static func to_json(profile: PuppetProfile) -> String:
    var data := {
        "muscles": profile.muscles,
        "bones": profile.bones,
        "bone_map": profile.bone_map,
        "version": profile.version,
    }
    return JSON.stringify(data)

static func from_json(text: String) -> PuppetProfile:
    var result := PuppetProfile.new()
    var data := JSON.parse_string(text)
    if typeof(data) == TYPE_DICTIONARY:
        result.muscles = data.get("muscles", {})
        result.bones = data.get("bones", {})
        result.bone_map = data.get("bone_map", {})
        result.version = data.get("version", result.version)
    return result
