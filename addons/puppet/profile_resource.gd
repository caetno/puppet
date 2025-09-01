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
@export var bone_settings: Dictionary = {}
@export var bones: Dictionary = {}

class BoneSettings:
        extends Resource
        var pre_q: Quaternion = Quaternion.IDENTITY
        var dof_order: Array = []
        var mirror: Vector3 = Vector3.ONE
        var limits: Array = []
        var translate_dof: Vector3 = Vector3.ZERO


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
        bone_settings.clear()
        bones.clear()
        for name in UNITY_BONES:
                var idx := skel.find_bone(name)
                bone_map[name] = idx
                var settings := BoneSettings.new()
                bone_settings[name] = settings
                bones[name] = {
                        "pre_q": settings.pre_q,
                        "dof_order": settings.dof_order,
                        "mirror": settings.mirror,
                }
        muscles.clear()
        for muscle in MuscleData.default_muscles():
                muscles[str(muscle["muscle_id"])] = muscle.duplicate(true)

func get_pre_quaternion(bone: String) -> Quaternion:
        if bone_settings.has(bone):
                return (bone_settings[bone] as BoneSettings).pre_q
        var d: Dictionary = bones.get(bone, {})
        return d.get("pre_q", Quaternion.IDENTITY)

func get_mirror(bone: String) -> Vector3:
        if bone_settings.has(bone):
                return (bone_settings[bone] as BoneSettings).mirror
        var d: Dictionary = bones.get(bone, {})
        return d.get("mirror", Vector3.ONE)

func get_dof_order(bone: String) -> Array:
        if bone_settings.has(bone):
                var arr: Array = (bone_settings[bone] as BoneSettings).dof_order
                return arr if arr.size() > 0 else ["x", "y", "z"]
        var d: Dictionary = bones.get(bone, {})
        return d.get("dof_order", ["x", "y", "z"])
