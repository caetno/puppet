@tool
extends Resource
class_name MuscleProfile

const MuscleData = preload("res://addons/puppet/muscle_data.gd")

## Resource storing muscle configuration values for a humanoid avatar.
@export var skeleton: NodePath
@export var muscles: Dictionary = {}
@export var version: String = "0.1"
@export var bone_map: Dictionary = {}

const UNITY_BONES := [
	"Hips",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "LeftToes",
	"RightUpperLeg", "RightLowerLeg", "RightFoot", "RightToes",
	"Spine", "Chest", "UpperChest",
	"Neck", "Head", "Jaw", "LeftEye", "RightEye",
	"LeftShoulder", "LeftUpperArm", "LeftLowerArm", "LeftHand",
	"LeftThumbMetacarpal", "LeftThumbProximal", "LeftThumbDistal",
	"LeftIndexProximal", "LeftIndexIntermediate", "LeftIndexDistal",
	"LeftMiddleProximal", "LeftMiddleIntermediate", "LeftMiddleDistal",
	"LeftRingProximal", "LeftRingIntermediate", "LeftRingDistal",
	"LeftLittleProximal", "LeftLittleIntermediate", "LeftLittleDistal",
	"RightShoulder", "RightUpperArm", "RightLowerArm", "RightHand",
	"RightThumbMetacarpal", "RightThumbProximal", "RightThumbDistal",
	"RightIndexProximal", "RightIndexIntermediate", "RightIndexDistal",
	"RightMiddleProximal", "RightMiddleIntermediate", "RightMiddleDistal",
	"RightRingProximal", "RightRingIntermediate", "RightRingDistal",
	"RightLittleProximal", "RightLittleIntermediate", "RightLittleDistal",
]

func load_from_skeleton(skel: Skeleton3D) -> void:
	self.skeleton = skel.get_path()
	bone_map.clear()
	for name in UNITY_BONES:
		if skel.find_bone(name) != -1:
			bone_map[name] = name
		else:
			bone_map[name] = ""
	muscles.clear()
	for muscle in MuscleData.default_muscles():
		muscles[str(muscle["muscle_id"])] = muscle.duplicate(true)
