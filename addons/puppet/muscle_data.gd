@tool
class_name MuscleData

# Humanoid skeleton muscle defaults.
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

# Axes to create for each bone. Bones not listed default to a single twist axis.
const BONE_AXES := {
	"Hips": ["front_back", "left_right", "twist"],
	"LeftUpperLeg": ["front_back", "roll_in_out", "left_right"],
	"LeftLowerLeg": ["front_back", "roll_in_out"],
	"LeftFoot": ["front_back", "twist"],
	"LeftToes": ["front_back"],
	"RightUpperLeg": ["front_back", "roll_in_out", "left_right"],
	"RightLowerLeg": ["front_back", "roll_in_out"],
	"RightFoot": ["front_back", "twist"],
	"RightToes": ["front_back"],
	"Spine": ["front_back", "left_right", "twist"],
	"Chest": ["front_back", "left_right", "twist"],
	"UpperChest": ["front_back", "left_right", "twist"],
	"Neck": ["nod", "tilt", "twist"],
	"Head": ["nod", "tilt", "twist"],
	"Jaw": ["open_close"],
	"LeftEye": ["left_right"],
	"RightEye": ["left_right"],
	"LeftShoulder": ["front_back", "twist"],
	"LeftUpperArm": ["down_up", "front_back", "roll_in_out"],
	"LeftLowerArm": ["front_back", "roll_in_out"],
	"LeftHand": ["finger_open_close", "twist"],
	"LeftThumbMetacarpal": ["finger_open_close", "finger_in_out"],
	"LeftThumbProximal": ["finger_open_close", "finger_in_out"],
	"LeftThumbDistal": ["finger_open_close"],
	"LeftIndexProximal": ["finger_open_close", "finger_in_out"],
	"LeftIndexIntermediate": ["finger_open_close"],
	"LeftIndexDistal": ["finger_open_close"],
	"LeftMiddleProximal": ["finger_open_close", "finger_in_out"],
	"LeftMiddleIntermediate": ["finger_open_close"],
	"LeftMiddleDistal": ["finger_open_close"],
	"LeftRingProximal": ["finger_open_close", "finger_in_out"],
	"LeftRingIntermediate": ["finger_open_close"],
	"LeftRingDistal": ["finger_open_close"],
	"LeftLittleProximal": ["finger_open_close", "finger_in_out"],
	"LeftLittleIntermediate": ["finger_open_close"],
	"LeftLittleDistal": ["finger_open_close"],
	"RightShoulder": ["front_back", "twist"],
	"RightUpperArm": ["down_up", "front_back", "roll_in_out"],
	"RightLowerArm": ["front_back", "roll_in_out"],
	"RightHand": ["finger_open_close", "twist"],
	"RightThumbMetacarpal": ["finger_open_close", "finger_in_out"],
	"RightThumbProximal": ["finger_open_close", "finger_in_out"],
	"RightThumbDistal": ["finger_open_close"],
	"RightIndexProximal": ["finger_open_close", "finger_in_out"],
	"RightIndexIntermediate": ["finger_open_close"],
	"RightIndexDistal": ["finger_open_close"],
	"RightMiddleProximal": ["finger_open_close", "finger_in_out"],
	"RightMiddleIntermediate": ["finger_open_close"],
	"RightMiddleDistal": ["finger_open_close"],
	"RightRingProximal": ["finger_open_close", "finger_in_out"],
	"RightRingIntermediate": ["finger_open_close"],
	"RightRingDistal": ["finger_open_close"],
	"RightLittleProximal": ["finger_open_close", "finger_in_out"],
	"RightLittleIntermediate": ["finger_open_close"],
	"RightLittleDistal": ["finger_open_close"],
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


static func _angle_limits(bone: String, axis: String = "") -> Array:
	var min_deg := -30.0
	var max_deg := 30.0
	if (
		bone.contains("UpperArm")
		or bone.contains("Shoulder")
		or bone.contains("UpperLeg")
		or bone.contains("Foot")
	):
		min_deg = -90.0
		max_deg = 90.0
	elif bone.contains("LowerArm") and axis == "front_back":
		min_deg = 0.0
		max_deg = 160.0
	elif bone.contains("LowerLeg") and axis == "front_back":
		min_deg = 0.0
		max_deg = 150.0
	elif bone.contains("LowerArm") or bone.contains("LowerLeg"):
		min_deg = -90.0
		max_deg = 90.0
	elif bone == "Neck" or bone == "Head":
		min_deg = -40.0
		max_deg = 40.0
	if (
		bone.find("Hand") != -1
		or bone.find("Thumb") != -1
		or bone.find("Index") != -1
		or bone.find("Middle") != -1
		or bone.find("Ring") != -1
		or bone.find("Little") != -1
		or bone.find("Toe") != -1
	):
		if axis == "finger_in_out":
			min_deg = -30.0
			max_deg = 30.0
		else:
			min_deg = 0.0
			max_deg = 90.0
	if axis == "roll_in_out" or axis == "twist":
		min_deg = -180.0
		max_deg = 180.0
	return [min_deg, max_deg]


static func _build_default_muscles() -> Array:
	var muscles: Array = []
	var id := 0
	for bone in HUMANOID_BONES:
		var axes = BONE_AXES.get(bone, ["twist"])
		var group = _bone_group(bone)
		for axis in axes:
			var limits = _angle_limits(bone, axis)
			(
				muscles
				. append(
					{
						"muscle_id": id,
						"group": group,
						"bone_ref": bone,
						"axis": axis,
						"min_deg": limits[0],
						"max_deg": limits[1],
						"default_deg": 0.0,
						"enabled": true,
					}
				)
			)
			id += 1
	return muscles


static func default_muscles() -> Array:
	return _build_default_muscles()
