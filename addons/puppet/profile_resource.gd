@tool
extends Resource
class_name PuppetProfile

const MuscleData = preload("res://addons/puppet/muscle_data.gd")
const OrientationBaker = preload("res://addons/puppet/bone_orientation.gd")

## Resource storing muscle configuration values for a humanoid avatar.
@export var skeleton: NodePath
@export var muscles: Dictionary = {}
@export var version: String = "0.1"
@export var bone_map: Dictionary = {}
@export var bones: Dictionary = {}

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
        bake_bones(skel)

func bake_bones(skel: Skeleton3D) -> void:
        bones = OrientationBaker.bake(skel)

func get_pre_quaternion(bone: String) -> Quaternion:
        var data: Dictionary = bones.get(bone, {})
        return data.get("pre_q", Quaternion())

func get_mirror(bone: String) -> Vector3:
        var data: Dictionary = bones.get(bone, {})
        return data.get("mirror", Vector3.ONE)

func get_dof_order(bone: String) -> Array:
        var data: Dictionary = bones.get(bone, {})
        return data.get("dof_order", ["x", "y", "z"])
