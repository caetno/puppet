@tool
class_name PuppetOrientationBaker

## Baker for canonical humanoid bone orientation data.
## Produces per‑bone dictionaries containing a pre‑rotation quaternion, mirror
## signs for each axis and the preferred degree‑of‑freedom rotation order.

const DOF_ORDER := {
	"Neck": ["z", "x", "y"],
	"Head": ["z", "x", "y"],
	"LeftUpperArm": ["x", "z", "y"],
	"RightUpperArm": ["x", "z", "y"],
	"LeftUpperLeg": ["x", "z", "y"],
	"RightUpperLeg": ["x", "z", "y"],
}

static var _cache: Dictionary = {}

static func generate_from_skeleton(skeleton: Skeleton3D) -> Dictionary:
	if not skeleton:
		return {}
	var data := bake(skeleton)
	_cache[skeleton.get_instance_id()] = data
	return data

static func _get_data(bone: String, skeleton: Skeleton3D) -> Dictionary:
	var cached := _cache.get(skeleton.get_instance_id(), {})
	return cached.get(bone, {})

static func apply_rotations(bone: String, basis: Basis, skeleton: Skeleton3D) -> Basis:
	var data := _get_data(bone, skeleton)
	if data.has("pre_q"):
		basis = Basis(data["pre_q"]) * basis
	return basis

static func get_limit_sign(bone: String, skeleton: Skeleton3D) -> Vector3:
	var data := _get_data(bone, skeleton)
	return data.get("mirror", Vector3.ONE)

## Bakes orientation data for all bones in `skeleton` and returns it as a
## dictionary mapping bone names to orientation info.
static func bake(skeleton: Skeleton3D) -> Dictionary:
	var result := {}
	if not skeleton:
		return result

	var ref_basis := _reference_basis_from_skeleton(skeleton)

	for i in skeleton.get_bone_count():
		var name := skeleton.get_bone_name(i)

		var aligned_ref := _align_hand_reference(skeleton, i, ref_basis)
		var joint_basis := _derive_bone_basis(skeleton, i, aligned_ref)

		var parent := skeleton.get_bone_parent(i)
		var parent_global := Transform3D.IDENTITY
		if parent != -1:
			parent_global = _get_global_rest(skeleton, parent)
		var joint_local := parent_global.basis.inverse() * joint_basis
		var bone_local := skeleton.get_bone_rest(i).basis

		var pre_rot := bone_local * joint_local.inverse()
		var sign := Vector3(
			1.0 if bone_local.x.dot(joint_local.x) >= 0.0 else -1.0,
			1.0 if bone_local.y.dot(joint_local.y) >= 0.0 else -1.0,
			1.0 if bone_local.z.dot(joint_local.z) >= 0.0 else -1.0,
		)

		result[name] = {
			"pre_q": pre_rot.get_rotation_quaternion(),
			"mirror": sign,
			"dof_order": DOF_ORDER.get(name, ["x", "y", "z"]),
		}

	return result


## Derives a joint basis from the skeleton geometry so X points sideways, Y up
## and Z follows the average direction of the children.	 This mirrors the
## behaviour of Unity's humanoid rigging.
static func joint_basis_from_skeleton(skeleton: Skeleton3D, bone: int) -> Basis:
	var ref := _reference_basis_from_skeleton(skeleton)
	ref = _align_hand_reference(skeleton, bone, ref)
	return _derive_bone_basis(skeleton, bone, ref)


# -- Runtime generation helpers ---------------------------------------------

static func _get_global_rest(skeleton: Skeleton3D, bone: int) -> Transform3D:
	var t := skeleton.get_bone_rest(bone)
	var parent := skeleton.get_bone_parent(bone)
	while parent != -1:
		t = skeleton.get_bone_rest(parent) * t
		parent = skeleton.get_bone_parent(parent)
	return t


## Builds a global reference basis (sideways, up, forward) from hip and shoulder
## positions.  If required bones are missing the skeleton's global transform is
## used instead.
static func _reference_basis_from_skeleton(skeleton: Skeleton3D) -> Basis:
	if not skeleton:
		return Basis()

	var left_leg := skeleton.find_bone("LeftUpperLeg")
	if left_leg == -1:
		left_leg = skeleton.find_bone("LeftUpLeg")
	var right_leg := skeleton.find_bone("RightUpperLeg")
	if right_leg == -1:
		right_leg = skeleton.find_bone("RightUpLeg")

	var left_shoulder := skeleton.find_bone("LeftShoulder")
	if left_shoulder == -1:
		left_shoulder = skeleton.find_bone("LeftUpperArm")
	var right_shoulder := skeleton.find_bone("RightShoulder")
	if right_shoulder == -1:
		right_shoulder = skeleton.find_bone("RightUpperArm")

	if left_leg == -1 or right_leg == -1 or left_shoulder == -1 or right_shoulder == -1:
		return skeleton.global_transform.basis

	var left_leg_pos := _get_global_rest(skeleton, left_leg).origin
	var right_leg_pos := _get_global_rest(skeleton, right_leg).origin
	var left_shoulder_pos := _get_global_rest(skeleton, left_shoulder).origin
	var right_shoulder_pos := _get_global_rest(skeleton, right_shoulder).origin

	var sideways := (right_leg_pos - left_leg_pos + right_shoulder_pos - left_shoulder_pos) * 0.5
	if sideways.length() == 0.0:
		sideways = Vector3.RIGHT
	sideways = sideways.normalized()

	var hip_center := (left_leg_pos + right_leg_pos) * 0.5
	var shoulder_center := (left_shoulder_pos + right_shoulder_pos) * 0.5
	var up := (shoulder_center - hip_center).normalized()
	if up.length() == 0.0:
		up = Vector3.UP

	var forward := sideways.cross(up).normalized()
	if forward.length() == 0.0:
		forward = Vector3.FORWARD
	up = forward.cross(sideways).normalized()
	return Basis(sideways, up, forward)


## Derives the joint basis for `bone` using `ref_basis` for sideways and up
## directions.	The bone's longitudinal axis is the average direction of all its
## children.
static func _derive_bone_basis(skeleton: Skeleton3D, bone: int, ref_basis: Basis) -> Basis:
	var bone_global := _get_global_rest(skeleton, bone)

	var z_axis := Vector3.ZERO
	var child_count := 0
	for j in skeleton.get_bone_count():
		if skeleton.get_bone_parent(j) == bone:
			var child_global := _get_global_rest(skeleton, j)
			var dir := (child_global.origin - bone_global.origin).normalized()
			if dir.length() > 0.0:
				z_axis += dir
				child_count += 1

	if child_count == 0:
		z_axis = bone_global.basis.z.normalized()
	else:
		z_axis = z_axis.normalized()

	var x_axis := ref_basis.x - z_axis * ref_basis.x.dot(z_axis)
	if x_axis.length() == 0.0:
		x_axis = ref_basis.y.cross(z_axis)
	x_axis = x_axis.normalized()

	var y_axis := z_axis.cross(x_axis).normalized()
	if y_axis.dot(ref_basis.y) < 0.0:
		y_axis = -y_axis
		x_axis = -x_axis

	return Basis(x_axis, y_axis, z_axis)


## Adjusts the reference basis so finger curling follows the forearm direction.
## Unity's avatar mapper re‑orients the hand using the vector between the lower
## arm and the hand before mapping finger bones.  This mirrors that behavior so
## the `finger_open_close` muscle curls the fingers instead of moving them
## sideways.
static func _align_hand_reference(skeleton: Skeleton3D, bone: int, ref: Basis) -> Basis:
	if not skeleton:
		push_warning("No skeleton provided; skipping hand alignment")
		return ref

	var left_hand := _find_bone(skeleton, ["LeftHand", "LeftWrist"])
	var right_hand := _find_bone(skeleton, ["RightHand", "RightWrist"])
	# Bone names may include prefixes (e.g. "mixamorig:LeftHand").
	# _find_bone performs suffix matching so such variants are handled.
	var hand := -1
	var lower := -1
	var middle := -1
	if left_hand != -1 and _is_descendant_of(skeleton, bone, left_hand):
		hand = left_hand
		lower = _find_bone(skeleton, ["LeftLowerArm", "LeftForeArm", "LeftForearm"])
		middle = _find_bone(skeleton, ["LeftMiddleProximal", "LeftHandMiddle1"])
	elif right_hand != -1 and _is_descendant_of(skeleton, bone, right_hand):
		hand = right_hand
		lower = _find_bone(skeleton, ["RightLowerArm", "RightForeArm", "RightForearm"])
		middle = _find_bone(skeleton, ["RightMiddleProximal", "RightHandMiddle1"])
	else:
		if left_hand == -1 and right_hand == -1:
			var name := skeleton.get_bone_name(bone).to_lower()
			if name.find("finger") != -1 or name.find("hand") != -1:
				push_error(
					"Hand bones not found; finger alignment skipped for %s" % skeleton.get_bone_name(bone)
				)
		return ref

	if lower == -1 or hand == -1:
		push_error("Required forearm/hand bones not found; finger alignment skipped")
		return ref

	if middle == -1:
		push_error("Middle finger bone not found; using fallback orientation")
		var hand_pos_f := _get_global_rest(skeleton, hand).origin
		var lower_pos_f := _get_global_rest(skeleton, lower).origin
		return _fallback_hand_orientation(skeleton, hand, hand_pos_f - lower_pos_f, ref)

	var hand_pos := _get_global_rest(skeleton, hand).origin
	var lower_pos := _get_global_rest(skeleton, lower).origin
	var hand_dir := hand_pos - lower_pos
	if hand_dir.length() == 0.0:
		push_error("Hand and forearm positions are identical; finger alignment skipped")
		return ref

	var middle_child := -1
	for j in skeleton.get_bone_count():
		if skeleton.get_bone_parent(j) == middle:
			middle_child = j
			break
	if middle_child == -1:
		push_error("Middle finger child not found; using fallback orientation")
		return _fallback_hand_orientation(skeleton, hand, hand_dir, ref)
	var middle_pos := _get_global_rest(skeleton, middle).origin
	var middle_child_pos := _get_global_rest(skeleton, middle_child).origin
	var middle_dir := middle_child_pos - middle_pos
	if middle_dir.length() == 0.0:
		push_error("Middle finger bone has zero length; using fallback orientation")
		return _fallback_hand_orientation(skeleton, hand, hand_dir, ref)

	var palm_normal := hand_dir.cross(middle_dir)
	if palm_normal.length() == 0.0:
		push_warning("Invalid palm normal; using fallback orientation")
		return _fallback_hand_orientation(skeleton, hand, hand_dir, ref)

	hand_dir = hand_dir.normalized()
	palm_normal = palm_normal.normalized()
	var z_axis := hand_dir.cross(palm_normal).normalized()
	var y_axis := z_axis.cross(hand_dir).normalized()

	# Preserve a right-handed basis. When the forearm points opposite the
	# reference X axis (left hand), flipping all three axes would mirror the
	# transform and yield a determinant of -1. Instead flip only Y and Z so
	# X remains aligned with the actual hand direction while keeping the
	# basis rotation-only.
	if hand_dir.dot(ref.x) < 0.0:
		y_axis = -y_axis
		z_axis = -z_axis

	return Basis(hand_dir, y_axis, z_axis)


static func _fallback_hand_orientation(skeleton: Skeleton3D, hand: int, hand_dir: Vector3, ref: Basis) -> Basis:
	if hand_dir.length() == 0.0:
		return ref
	hand_dir = hand_dir.normalized()
	var y_axis := ref.y - hand_dir * ref.y.dot(hand_dir)
	if y_axis.length() == 0.0:
		y_axis = ref.z.cross(hand_dir)
	if y_axis.length() == 0.0:
		y_axis = Vector3.UP.cross(hand_dir)
	y_axis = y_axis.normalized()
	var z_axis := hand_dir.cross(y_axis).normalized()
	return Basis(hand_dir, y_axis, z_axis)


static func _find_bone(skeleton: Skeleton3D, names: Array) -> int:
	for n in names:
		var idx := skeleton.find_bone(n)
		if idx != -1:
			return idx
	for i in skeleton.get_bone_count():
		var name := skeleton.get_bone_name(i).to_lower()
		for n in names:
			var target := String(n).to_lower()
			if name.ends_with(target):
				return i
	return -1


static func _is_descendant_of(skeleton: Skeleton3D, bone: int, ancestor: int) -> bool:
	var p := bone
	while p != -1:
		if p == ancestor:
			return true
		p = skeleton.get_bone_parent(p)
	return false

