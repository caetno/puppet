@tool
class_name BoneOrientation

## Stores pre/post rotation and limit sign data for humanoid bones.
# These tables mirror Unity's internal avatar setup and allow the muscle
# system to reproduce Unity's muscle axes.  The values here were derived
# empirically from Unity's GetPreRotation / GetPostRotation / GetLimitSign
# outputs and only cover the common humanoid bones.  Bones not listed fall
# back to the identity rotation and a positive limit sign on all axes.

# Pre‑rotations applied before constructing the bone basis.
const PRE_ROTATIONS := {
    # Upper arms need to be aligned so the X axis points forward similar to
    # Unity's internal representation.  Left and right sides are mirrored.
    "LeftUpperArm": Basis(Vector3.FORWARD, deg_to_rad(90.0)),
    "RightUpperArm": Basis(Vector3.FORWARD, deg_to_rad(-90.0)),
    # Upper legs are aligned so that X points forward.
    "LeftUpperLeg": Basis(Vector3.FORWARD, deg_to_rad(90.0)),
    "RightUpperLeg": Basis(Vector3.FORWARD, deg_to_rad(-90.0)),
    # Fingers use Unity's default orientation so they retain identity pre-rotations.
    "LeftThumbMetacarpal": Basis(),
    "LeftThumbProximal": Basis(),
    "LeftThumbDistal": Basis(),
    "LeftIndexProximal": Basis(),
    "LeftIndexIntermediate": Basis(),
    "LeftIndexDistal": Basis(),
    "LeftMiddleProximal": Basis(),
    "LeftMiddleIntermediate": Basis(),
    "LeftMiddleDistal": Basis(),
    "LeftRingProximal": Basis(),
    "LeftRingIntermediate": Basis(),
    "LeftRingDistal": Basis(),
    "LeftLittleProximal": Basis(),
    "LeftLittleIntermediate": Basis(),
    "LeftLittleDistal": Basis(),
    "RightThumbMetacarpal": Basis(),
    "RightThumbProximal": Basis(),
    "RightThumbDistal": Basis(),
    "RightIndexProximal": Basis(),
    "RightIndexIntermediate": Basis(),
    "RightIndexDistal": Basis(),
    "RightMiddleProximal": Basis(),
    "RightMiddleIntermediate": Basis(),
    "RightMiddleDistal": Basis(),
    "RightRingProximal": Basis(),
    "RightRingIntermediate": Basis(),
    "RightRingDistal": Basis(),
    "RightLittleProximal": Basis(),
    "RightLittleIntermediate": Basis(),
    "RightLittleDistal": Basis(),
}

# Post rotations applied after the basis has been generated from the bone
# direction.
const POST_ROTATIONS := {
    # Wrists and ankles require a quarter turn so the twist axis matches
    # Unity's internal Z axis.
    "LeftLowerArm": Basis(Vector3.RIGHT, deg_to_rad(90.0)),
    "RightLowerArm": Basis(Vector3.RIGHT, deg_to_rad(-90.0)),
    "LeftLowerLeg": Basis(Vector3.RIGHT, deg_to_rad(90.0)),
    "RightLowerLeg": Basis(Vector3.RIGHT, deg_to_rad(-90.0)),
    # Finger bones do not require post rotations in Unity's humanoid setup.
    "LeftThumbMetacarpal": Basis(),
    "LeftThumbProximal": Basis(),
    "LeftThumbDistal": Basis(),
    "LeftIndexProximal": Basis(),
    "LeftIndexIntermediate": Basis(),
    "LeftIndexDistal": Basis(),
    "LeftMiddleProximal": Basis(),
    "LeftMiddleIntermediate": Basis(),
    "LeftMiddleDistal": Basis(),
    "LeftRingProximal": Basis(),
    "LeftRingIntermediate": Basis(),
    "LeftRingDistal": Basis(),
    "LeftLittleProximal": Basis(),
    "LeftLittleIntermediate": Basis(),
    "LeftLittleDistal": Basis(),
    "RightThumbMetacarpal": Basis(),
    "RightThumbProximal": Basis(),
    "RightThumbDistal": Basis(),
    "RightIndexProximal": Basis(),
    "RightIndexIntermediate": Basis(),
    "RightIndexDistal": Basis(),
    "RightMiddleProximal": Basis(),
    "RightMiddleIntermediate": Basis(),
    "RightMiddleDistal": Basis(),
    "RightRingProximal": Basis(),
    "RightRingIntermediate": Basis(),
    "RightRingDistal": Basis(),
    "RightLittleProximal": Basis(),
    "RightLittleIntermediate": Basis(),
    "RightLittleDistal": Basis(),
}

# Limit sign adjustments.  These flip the meaning of positive rotation for
# certain bones so the resulting angles match Unity.  Each vector component
# corresponds to the X, Y and Z axes respectively.
const LIMIT_SIGNS := {
    "LeftUpperArm": Vector3(-1, 1, -1),
    "LeftLowerArm": Vector3(1, 1, -1),
    "LeftHand": Vector3(-1, 1, -1),
    "LeftUpperLeg": Vector3(-1, 1, -1),
    "LeftLowerLeg": Vector3(-1, 1, -1),
    "LeftFoot": Vector3(-1, 1, -1),
    "RightLowerArm": Vector3.ONE,
    "RightUpperLeg": Vector3.ONE,
    "RightLowerLeg": Vector3.ONE,
    "RightFoot": Vector3.ONE,
    # Fingers mirror Unity's limit sign convention.
    "LeftThumbMetacarpal": Vector3(-1, 1, -1),
    "LeftThumbProximal": Vector3(-1, 1, -1),
    "LeftThumbDistal": Vector3(-1, 1, -1),
    "LeftIndexProximal": Vector3(-1, 1, -1),
    "LeftIndexIntermediate": Vector3(-1, 1, -1),
    "LeftIndexDistal": Vector3(-1, 1, -1),
    "LeftMiddleProximal": Vector3(-1, 1, -1),
    "LeftMiddleIntermediate": Vector3(-1, 1, -1),
    "LeftMiddleDistal": Vector3(-1, 1, -1),
    "LeftRingProximal": Vector3(-1, 1, -1),
    "LeftRingIntermediate": Vector3(-1, 1, -1),
    "LeftRingDistal": Vector3(-1, 1, -1),
    "LeftLittleProximal": Vector3(-1, 1, -1),
    "LeftLittleIntermediate": Vector3(-1, 1, -1),
    "LeftLittleDistal": Vector3(-1, 1, -1),
    "RightThumbMetacarpal": Vector3.ONE,
    "RightThumbProximal": Vector3.ONE,
    "RightThumbDistal": Vector3.ONE,
    "RightIndexProximal": Vector3.ONE,
    "RightIndexIntermediate": Vector3.ONE,
    "RightIndexDistal": Vector3.ONE,
    "RightMiddleProximal": Vector3.ONE,
    "RightMiddleIntermediate": Vector3.ONE,
    "RightMiddleDistal": Vector3.ONE,
    "RightRingProximal": Vector3.ONE,
    "RightRingIntermediate": Vector3.ONE,
    "RightRingDistal": Vector3.ONE,
    "RightLittleProximal": Vector3.ONE,
    "RightLittleIntermediate": Vector3.ONE,
    "RightLittleDistal": Vector3.ONE,
}

static func get_pre_rotation(bone: String) -> Basis:
    return PRE_ROTATIONS.get(bone, Basis())

static func get_post_rotation(bone: String) -> Basis:
    return POST_ROTATIONS.get(bone, Basis())

static func get_limit_sign(bone: String) -> Vector3:
    return LIMIT_SIGNS.get(bone, Vector3.ONE)

static func apply_rotations(bone: String, basis: Basis) -> Basis:
    return get_pre_rotation(bone) * basis * get_post_rotation(bone)
