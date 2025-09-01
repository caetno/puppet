@tool
class_name MuscleData

# Humanoid skeleton muscle defaults.
#
# Each muscle operates on one of three canonical channels:
# X = twist around the bone, Y = front/back swing and Z = left/right swing.
const HUMANOID_BONES := [
    "Hips",
    "LeftUpperLeg",
    "LeftLowerLeg",
    "LeftFoot",
    "LeftToes",
    "RightUpperLeg",
    "RightLowerLeg",
    "RightFoot",
    "RightToes",
    "Spine",
    "Chest",
    "UpperChest",
    "Neck",
    "Head",
    "Jaw",
    "LeftEye",
    "RightEye",
    "LeftShoulder",
    "LeftUpperArm",
    "LeftLowerArm",
    "LeftHand",
    "LeftThumbMetacarpal",
    "LeftThumbProximal",
    "LeftThumbDistal",
    "LeftIndexProximal",
    "LeftIndexIntermediate",
    "LeftIndexDistal",
    "LeftMiddleProximal",
    "LeftMiddleIntermediate",
    "LeftMiddleDistal",
    "LeftRingProximal",
    "LeftRingIntermediate",
    "LeftRingDistal",
    "LeftLittleProximal",
    "LeftLittleIntermediate",
    "LeftLittleDistal",
    "RightShoulder",
    "RightUpperArm",
    "RightLowerArm",
    "RightHand",
    "RightThumbMetacarpal",
    "RightThumbProximal",
    "RightThumbDistal",
    "RightIndexProximal",
    "RightIndexIntermediate",
    "RightIndexDistal",
    "RightMiddleProximal",
    "RightMiddleIntermediate",
    "RightMiddleDistal",
    "RightRingProximal",
    "RightRingIntermediate",
    "RightRingDistal",
    "RightLittleProximal",
    "RightLittleIntermediate",
    "RightLittleDistal",
]

# Axis channel semantics:
# X – twist around the bone's length.
# Y – swing front/back (flexion and extension).
# Z – swing left/right (abduction and adduction).
# Bones not listed default to a single X‑axis twist channel.
const BONE_AXES := {
        "Hips": {"X": "twist", "Y": "front_back", "Z": "left_right"},
        "LeftUpperLeg": {"X": "roll_in_out", "Y": "front_back", "Z": "left_right"},
        "LeftLowerLeg": {"X": "roll_in_out", "Y": "front_back"},
        "LeftFoot": {"X": "twist", "Y": "front_back"},
        "LeftToes": {"Y": "front_back"},
        "RightUpperLeg": {"X": "roll_in_out", "Y": "front_back", "Z": "left_right"},
        "RightLowerLeg": {"X": "roll_in_out", "Y": "front_back"},
        "RightFoot": {"X": "twist", "Y": "front_back"},
        "RightToes": {"Y": "front_back"},
        "Spine": {"X": "twist", "Y": "front_back", "Z": "left_right"},
        "Chest": {"X": "twist", "Y": "front_back", "Z": "left_right"},
        "UpperChest": {"X": "twist", "Y": "front_back", "Z": "left_right"},
        "Neck": {"X": "twist", "Y": "nod", "Z": "tilt"},
        "Head": {"X": "twist", "Y": "nod", "Z": "tilt"},
        "Jaw": {"Y": "open_close"},
        "LeftEye": {"Z": "left_right"},
        "RightEye": {"Z": "left_right"},
        "LeftShoulder": {"X": "twist", "Y": "front_back"},
        "LeftUpperArm": {"X": "roll_in_out", "Y": "front_back", "Z": "down_up"},
        "LeftLowerArm": {"X": "roll_in_out", "Y": "front_back"},
        "LeftHand": {"X": "twist", "Y": "finger_open_close"},
        "LeftThumbMetacarpal": {"Y": "finger_open_close", "Z": "finger_in_out"},
        "LeftThumbProximal": {"Y": "finger_open_close", "Z": "finger_in_out"},
        "LeftThumbDistal": {"Y": "finger_open_close"},
        "LeftIndexProximal": {"Y": "finger_open_close", "Z": "finger_in_out"},
        "LeftIndexIntermediate": {"Y": "finger_open_close"},
        "LeftIndexDistal": {"Y": "finger_open_close"},
        "LeftMiddleProximal": {"Y": "finger_open_close", "Z": "finger_in_out"},
        "LeftMiddleIntermediate": {"Y": "finger_open_close"},
        "LeftMiddleDistal": {"Y": "finger_open_close"},
        "LeftRingProximal": {"Y": "finger_open_close", "Z": "finger_in_out"},
        "LeftRingIntermediate": {"Y": "finger_open_close"},
        "LeftRingDistal": {"Y": "finger_open_close"},
        "LeftLittleProximal": {"Y": "finger_open_close", "Z": "finger_in_out"},
        "LeftLittleIntermediate": {"Y": "finger_open_close"},
        "LeftLittleDistal": {"Y": "finger_open_close"},
        "RightShoulder": {"X": "twist", "Y": "front_back"},
        "RightUpperArm": {"X": "roll_in_out", "Y": "front_back", "Z": "down_up"},
        "RightLowerArm": {"X": "roll_in_out", "Y": "front_back"},
        "RightHand": {"X": "twist", "Y": "finger_open_close"},
        "RightThumbMetacarpal": {"Y": "finger_open_close", "Z": "finger_in_out"},
        "RightThumbProximal": {"Y": "finger_open_close", "Z": "finger_in_out"},
        "RightThumbDistal": {"Y": "finger_open_close"},
        "RightIndexProximal": {"Y": "finger_open_close", "Z": "finger_in_out"},
        "RightIndexIntermediate": {"Y": "finger_open_close"},
        "RightIndexDistal": {"Y": "finger_open_close"},
        "RightMiddleProximal": {"Y": "finger_open_close", "Z": "finger_in_out"},
        "RightMiddleIntermediate": {"Y": "finger_open_close"},
        "RightMiddleDistal": {"Y": "finger_open_close"},
        "RightRingProximal": {"Y": "finger_open_close", "Z": "finger_in_out"},
        "RightRingIntermediate": {"Y": "finger_open_close"},
        "RightRingDistal": {"Y": "finger_open_close"},
        "RightLittleProximal": {"Y": "finger_open_close", "Z": "finger_in_out"},
        "RightLittleIntermediate": {"Y": "finger_open_close"},
        "RightLittleDistal": {"Y": "finger_open_close"},
}


static func _bone_group(bone: String) -> String:
    if bone.begins_with("Left"):
        if bone.find("Leg") != -1 or bone.find("Foot") != -1 or bone.find("Toe") != -1:
            return "Left Leg"
        if (
            bone.find("Hand") != -1
            or bone.find("Thumb") != -1
            or bone.find("Index") != -1
            or bone.find("Middle") != -1
            or bone.find("Ring") != -1
            or bone.find("Little") != -1
        ):
            return "Left Hand"
        return "Left Arm"
    if bone.begins_with("Right"):
        if bone.find("Leg") != -1 or bone.find("Foot") != -1 or bone.find("Toe") != -1:
            return "Right Leg"
        if (
            bone.find("Hand") != -1
            or bone.find("Thumb") != -1
            or bone.find("Index") != -1
            or bone.find("Middle") != -1
            or bone.find("Ring") != -1
            or bone.find("Little") != -1
        ):
            return "Right Hand"
        return "Right Arm"
    if bone == "Head" or bone == "Jaw" or bone == "Neck" or bone.find("Eye") != -1:
        return "Head"
    return "Body"


static func _axis_limits(bone: String, channel: String) -> Array:
        var min_deg := -30.0
        var max_deg := 30.0
        # Shoulder and arm
        if bone.contains("UpperArm") or bone.contains("Shoulder"):
                match channel:
                        "X":
                                min_deg = -80.0
                                max_deg = 80.0
                        "Y":
                                min_deg = -60.0
                                max_deg = 120.0
                        "Z":
                                min_deg = -90.0
                                max_deg = 90.0
        # Forearm / elbow
        elif bone.contains("LowerArm"):
                match channel:
                        "X":
                                min_deg = -180.0
                                max_deg = 180.0
                        "Y":
                                min_deg = 0.0
                                max_deg = 160.0
                        "Z":
                                min_deg = 0.0
                                max_deg = 0.0
        # Leg and hip
        elif bone.contains("UpperLeg") or bone == "Hips":
                match channel:
                        "X":
                                min_deg = -80.0
                                max_deg = 80.0
                        "Y":
                                min_deg = -90.0
                                max_deg = 90.0
                        "Z":
                                min_deg = -90.0
                                max_deg = 90.0
        # Knee
        elif bone.contains("LowerLeg"):
                match channel:
                        "X":
                                min_deg = -180.0
                                max_deg = 180.0
                        "Y":
                                min_deg = 0.0
                                max_deg = 150.0
                        "Z":
                                min_deg = 0.0
                                max_deg = 0.0
        # Head and neck
        elif bone == "Neck" or bone == "Head":
                match channel:
                        "X":
                                min_deg = -80.0
                                max_deg = 80.0
                        "Y":
                                min_deg = -40.0
                                max_deg = 40.0
                        "Z":
                                min_deg = -40.0
                                max_deg = 40.0
        # Hands, fingers, toes
        elif (
                bone.find("Hand") != -1
                or bone.find("Thumb") != -1
                or bone.find("Index") != -1
                or bone.find("Middle") != -1
                or bone.find("Ring") != -1
                or bone.find("Little") != -1
                or bone.find("Toe") != -1
        ):
                match channel:
                        "X":
                                min_deg = -180.0
                                max_deg = 180.0
                        "Y":
                                min_deg = 0.0
                                max_deg = 90.0
                        "Z":
                                min_deg = -30.0
                                max_deg = 30.0
        elif channel == "X":
                min_deg = -180.0
                max_deg = 180.0
        return [min_deg, 0.0, max_deg]


static func _build_default_muscles() -> Array:
        var muscles: Array = []
        var id := 0
        for bone in HUMANOID_BONES:
                var axes: Dictionary = BONE_AXES.get(bone, {"X": "twist"})
                var group = _bone_group(bone)
                for channel in axes.keys():
                        var limits = _axis_limits(bone, channel)
                        muscles.append(
                                {
                                        "muscle_id": id,
                                        "group": group,
                                        "bone_ref": bone,
                                        "axis": channel,
                                        "min_deg": limits[0],
                                        "max_deg": limits[2],
                                        "default_deg": limits[1],
                                        "enabled": true,
                                }
                        )
                        id += 1
        return muscles


static func default_muscles() -> Array:
    return _build_default_muscles()
