@tool
class_name MuscleIO

## Helpers for profile serialization.
static func to_json(profile: MuscleProfile) -> String:
    return JSON.stringify(profile.muscles)

static func from_json(text: String) -> MuscleProfile:
    var result := MuscleProfile.new()
    var data := JSON.parse_string(text)
    if typeof(data) == TYPE_DICTIONARY:
        result.muscles = data
    return result
