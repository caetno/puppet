@tool
class_name JointConverter

const PuppetProfile = preload("res://addons/puppet/profile_resource.gd")
const OrientationBaker = preload("res://addons/puppet/bone_orientation.gd")

const AXIS_TO_INDEX := {
                "X": 0,
                "Y": 1,
                "Z": 2,
}

# Per-bone degree-of-freedom rotation order mappings.
# These specify the order in which canonical axis rotations are composed for
# specific bones.  Bones not listed use the default X->Y->Z order.
const DOF_ORDER := {
		"Neck": ["z", "x", "y"],
		"Head": ["z", "x", "y"],
		"LeftUpperArm": ["x", "z", "y"],
		"RightUpperArm": ["x", "z", "y"],
		"LeftUpperLeg": ["x", "z", "y"],
		"RightUpperLeg": ["x", "z", "y"],
}

## Utility functions for converting joints and applying limits.


# -- Joint conversion -------------------------------------------------------
# The editor often creates physical bones using a variety of joint types
# (hinge, cone‐twist …).  For the purposes of the muscle system we want every
# bone to use a fully configurable 6 degrees of freedom joint so the limits can
# be adjusted individually on each axis.  `convert_to_6dof` walks the given
# skeleton and replaces every existing `Joint3D` descendant with a
# `Generic6DOFJoint3D` while preserving the original attachment nodes and
# transform.
static func convert_to_6dof(profile: PuppetProfile, skeleton: Skeleton3D) -> void:
        if not skeleton:
                return

	# Collect all joints that need to be converted.	 We gather them first so we
	# can safely modify the scene tree while iterating.

	var to_convert: Array = []

	var stack: Array[Node] = [skeleton]
	while stack.size() > 0:
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			stack.append(child)
			if child is Joint3D and not (child is Generic6DOFJoint3D):
				to_convert.append(child)

	for old_joint: Joint3D in to_convert:
		var new_joint: Generic6DOFJoint3D = Generic6DOFJoint3D.new()
		new_joint.name = old_joint.name
		new_joint.transform = old_joint.transform
		# Preserve the bodies the joint is attached to.
		new_joint.node_a = old_joint.node_a
		new_joint.node_b = old_joint.node_b
		new_joint.disable_collisions_between_bodies = old_joint.disable_collisions_between_bodies

		# Place the new joint in the same position in the scene tree.
		var parent: Node = old_joint.get_parent()
		var child_idx: int = parent.get_children().find(old_joint)
		parent.remove_child(old_joint)
		parent.add_child(new_joint)
		parent.move_child(new_joint, child_idx)
		old_joint.queue_free()

		# Configure the joint frame so X is the sideways axis, Y is forward and
		# Z follows the bone direction.	 This mirrors Unity's humanoid setup
		# which derives the frame from the bone and its child direction.
                var bone_name := new_joint.name
                var idx := skeleton.find_bone(bone_name)
                if idx == -1:
                        continue
                var basis := OrientationBaker.joint_basis_from_skeleton(skeleton, idx)
                basis = Basis(profile.get_pre_quaternion(bone_name)) * basis
                new_joint.transform.basis = basis
                var sign: Vector3 = profile.get_mirror(bone_name)
                new_joint.set("angular_limit_x/axis", basis.x * sign.x)
                new_joint.set("angular_limit_y/axis", basis.y * sign.y)
                new_joint.set("angular_limit_z/axis", basis.z * sign.z)

		new_joint.set("angular_limit_x/enabled", true)
		new_joint.set("angular_limit_y/enabled", true)
		new_joint.set("angular_limit_z/enabled", true)
		new_joint.set("angular_limit_x/lower_angle", -PI)
		new_joint.set("angular_limit_x/upper_angle", PI)
		new_joint.set("angular_limit_y/lower_angle", -PI)
		new_joint.set("angular_limit_y/upper_angle", PI)
		new_joint.set("angular_limit_z/lower_angle", -PI)
		new_joint.set("angular_limit_z/upper_angle", PI)


# Previous helper for deriving joint bases has been replaced by
# OrientationBaker.joint_basis_from_skeleton which performs the same task while
# taking the global reference frame into account.


# -- Limit application ------------------------------------------------------
# -- Limit application ------------------------------------------------------
# Reads limit information from a `PuppetProfile` and applies it to the 6‑DOF
# joints generated above.  Each muscle entry defines a bone, an axis and the
# minimum / maximum angles in degrees.	The limits are translated to the
# corresponding joint properties.
static func apply_limits(profile: PuppetProfile, skeleton: Skeleton3D) -> void:
	if not profile or not skeleton:
		return

	# Build a lookup table of joints by name for fast access when iterating
	# over the muscles.  The typical workflow is to name the joint after the
	# bone it controls which makes this straightforward.
	var joints: Dictionary = {}

	var stack: Array[Node] = [skeleton]
	while stack.size() > 0:
		var node: Node = stack.pop_back()
		for child: Node in node.get_children():
			stack.append(child)
			if child is Generic6DOFJoint3D:
				joints[child.name] = child

	for id in profile.muscles.keys():
		var data: Dictionary = profile.muscles[id]
		var bone_name: String = data.get("bone_ref", "")
		if bone_name.is_empty() or not joints.has(bone_name):
			continue

		var joint: Generic6DOFJoint3D = joints[bone_name]
		var axis: String = data.get("axis", "")
		var min_deg: float = data.get("min_deg", -180.0)
		var max_deg: float = data.get("max_deg", 180.0)

		var axis_char: String = _axis_to_char(axis)
		if axis_char == "":
			continue

		var base := "angular_limit_%s" % axis_char
		joint.set("%s/enabled" % base, true)
		joint.set("%s/lower_angle" % base, deg_to_rad(min_deg))
		joint.set("%s/upper_angle" % base, deg_to_rad(max_deg))


# -- Muscle application -----------------------------------------------------
# Applies muscle values to the given skeleton.	Rotations are composed in the
# canonical joint frame using baked BoneSettings orientation data.  Muscle
# values are mapped between their minimum/center/maximum limits and mirrored
# using the limit sign so left/right bones behave consistently.	 The resulting
# transforms are written as bone poses relative to the rest pose so repeated
# calls do not accumulate rotation.
static func apply_muscles(profile: MuscleProfile, skeleton: Skeleton3D, values: Dictionary) -> void:
	if not profile or not skeleton:
		return

	skeleton.reset_bone_poses()

	# Accumulate Euler angles for each bone in radians.
	var bone_angles: Dictionary = {}
	for id in profile.muscles.keys():
		var data: Dictionary = profile.muscles[id]
		var bone_name: String = data.get("bone_ref", "")
		if bone_name.is_empty():
			continue

		var axis_idx: int = axis_to_index(data.get("axis", ""))
		if axis_idx == -1:
			continue

		var value: float = values.get(id, 0.0)
		var min_deg: float = data.get("min_deg", -180.0)
		var max_deg: float = data.get("max_deg", 180.0)
		var center_deg: float = data.get("default_deg", 0.0)

		var angle_deg: float = center_deg
		if value >= 0.0:
			angle_deg = center_deg + (max_deg - center_deg) * value
		else:
			angle_deg = center_deg + (center_deg - min_deg) * value

		var sign: Vector3 = BoneOrientation.get_limit_sign(bone_name, skeleton)
		var sign_val: float = [sign.x, sign.y, sign.z][axis_idx]
		var angle: float = deg_to_rad(angle_deg) * sign_val

		var current: Vector3 = bone_angles.get(bone_name, Vector3.ZERO)
		if axis_idx == 0:
			current.x += angle
		elif axis_idx == 1:
			current.y += angle
		else:
			current.z += angle
		bone_angles[bone_name] = current

	for bone_name in bone_angles.keys():
		var idx := skeleton.find_bone(bone_name)
		if idx == -1:
			continue
		var basis := BoneOrientation.joint_basis_from_skeleton(skeleton, idx)
		basis = BoneOrientation.apply_rotations(bone_name, basis, skeleton)
		var rot := _compose_rotation(basis, bone_angles[bone_name], bone_name)
		var rest: Transform3D = skeleton.get_bone_rest(idx)
		var local_pose := Transform3D(rest.basis * rot, rest.origin)
		skeleton.set_bone_pose(idx, local_pose)


# -- Helpers ----------------------------------------------------------------
static func _compose_rotation(basis: Basis, angles: Vector3, bone: String) -> Basis:
		var order := DOF_ORDER.get(bone, ["x", "y", "z"])
		var parts := {
				"x": Basis(basis.x, angles.x),
				"y": Basis(basis.y, angles.y),
				"z": Basis(basis.z, angles.z),
		}
		var rot := Basis()
		for k in order:
				rot = rot * parts[k]
		return rot

static func axis_to_index(axis: String) -> int:
                return AXIS_TO_INDEX.get(axis, -1)

static func _axis_to_char(axis: String) -> String:
                var idx := axis_to_index(axis)
                return ["x", "y", "z"].get(idx, "")
