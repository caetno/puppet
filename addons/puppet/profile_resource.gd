@tool
extends Resource
class_name MuscleProfile
const MuscleData = preload("res://addons/puppet/muscle_data.gd")

## Resource storing muscle configuration values.
@export var muscles := {}
@export var version: String = "0.1"

## Humanoid bone mapping per Unity's avatar specification.
@export var hips: StringName
@export var left_upper_leg: StringName
@export var right_upper_leg: StringName
@export var left_lower_leg: StringName
@export var right_lower_leg: StringName
@export var left_foot: StringName
@export var right_foot: StringName
@export var spine: StringName
@export var chest: StringName
@export var upper_chest: StringName
@export var neck: StringName
@export var head: StringName
@export var left_shoulder: StringName
@export var right_shoulder: StringName
@export var left_upper_arm: StringName
@export var right_upper_arm: StringName
@export var left_lower_arm: StringName
@export var right_lower_arm: StringName
@export var left_hand: StringName
@export var right_hand: StringName
@export var left_toes: StringName
@export var right_toes: StringName
@export var left_eye: StringName
@export var right_eye: StringName
@export var jaw: StringName
@export var left_thumb_proximal: StringName
@export var left_thumb_intermediate: StringName
@export var left_thumb_distal: StringName
@export var left_index_proximal: StringName
@export var left_index_intermediate: StringName
@export var left_index_distal: StringName
@export var left_middle_proximal: StringName
@export var left_middle_intermediate: StringName
@export var left_middle_distal: StringName
@export var left_ring_proximal: StringName
@export var left_ring_intermediate: StringName
@export var left_ring_distal: StringName
@export var left_little_proximal: StringName
@export var left_little_intermediate: StringName
@export var left_little_distal: StringName
@export var right_thumb_proximal: StringName
@export var right_thumb_intermediate: StringName
@export var right_thumb_distal: StringName
@export var right_index_proximal: StringName
@export var right_index_intermediate: StringName
@export var right_index_distal: StringName
@export var right_middle_proximal: StringName
@export var right_middle_intermediate: StringName
@export var right_middle_distal: StringName
@export var right_ring_proximal: StringName
@export var right_ring_intermediate: StringName
@export var right_ring_distal: StringName
@export var right_little_proximal: StringName
@export var right_little_intermediate: StringName
@export var right_little_distal: StringName

const HUMAN_BONES := [
    "hips",
    "left_upper_leg", "right_upper_leg",
    "left_lower_leg", "right_lower_leg",
    "left_foot", "right_foot",
    "spine", "chest", "upper_chest",
    "neck", "head",
    "left_shoulder", "right_shoulder",
    "left_upper_arm", "right_upper_arm",
    "left_lower_arm", "right_lower_arm",
    "left_hand", "right_hand",
    "left_toes", "right_toes",
    "left_eye", "right_eye",
    "jaw",
    "left_thumb_proximal", "left_thumb_intermediate", "left_thumb_distal",
    "left_index_proximal", "left_index_intermediate", "left_index_distal",
    "left_middle_proximal", "left_middle_intermediate", "left_middle_distal",
    "left_ring_proximal", "left_ring_intermediate", "left_ring_distal",
    "left_little_proximal", "left_little_intermediate", "left_little_distal",
    "right_thumb_proximal", "right_thumb_intermediate", "right_thumb_distal",
    "right_index_proximal", "right_index_intermediate", "right_index_distal",
    "right_middle_proximal", "right_middle_intermediate", "right_middle_distal",
    "right_ring_proximal", "right_ring_intermediate", "right_ring_distal",
    "right_little_proximal", "right_little_intermediate", "right_little_distal",
]

func load_from_skeleton(skeleton: Skeleton3D) -> void:
    for bone_prop in HUMAN_BONES:
        var unity_name := ""
        for part in bone_prop.split("_"):
            unity_name += part.capitalize()
        var idx := skeleton.find_bone(unity_name)
        if idx == -1:
            idx = skeleton.find_bone(bone_prop)
        if idx != -1:
            set(bone_prop, skeleton.get_bone_name(idx))
        else:
            set(bone_prop, StringName())

    muscles.clear()
    for muscle in MuscleData.DEFAULT_MUSCLES:
        muscles[muscle["muscle_id"]] = muscle.duplicate(true)
