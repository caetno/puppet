extends SceneTree

const MuscleProfile = preload("res://addons/puppet/profile_resource.gd")
const JointConverter = preload("res://addons/puppet/joint_converter.gd")
const BoneOrientation = preload("res://addons/puppet/bone_orientation.gd")

func _build_skeleton() -> Skeleton3D:
	var parent := Node3D.new()
	get_root().add_child(parent)
	var s := Skeleton3D.new()
	parent.add_child(s)
	# Create a simple arm with two bones so joint bases can be derived.
	s.add_bone("LeftLowerArm")
	s.set_bone_rest(0, Transform3D(Basis(), Vector3.ZERO))
	s.add_bone("LeftHand")
	s.set_bone_parent(1, 0)
	s.set_bone_rest(1, Transform3D(Basis(), Vector3(0.3, 0, 0)))
	return s

func _find_muscle(profile: MuscleProfile, bone: String, axis: String) -> String:
	for id in profile.muscles.keys():
		var m = profile.muscles[id]
		if m.get("bone_ref", "") == bone and m.get("axis", "") == axis:
			return id
	return ""

func _init():
	var skeleton := _build_skeleton()
	BoneOrientation.generate_from_skeleton(skeleton)

	var profile := MuscleProfile.new()
	profile.muscles = {
		"0": {
			"bone_ref": "LeftLowerArm",
			"axis": "front_back",
			"min_deg": 0.0,
			"max_deg": 160.0,
			"default_deg": 0.0,
		},
	}
	var muscle_id := "0"

	# First application
	JointConverter.apply_muscles(profile, skeleton, {muscle_id: 1.0})
	var pose1 := skeleton.get_bone_pose(0)

	# Re-applying the same value should not change the pose further.
	JointConverter.apply_muscles(profile, skeleton, {muscle_id: 1.0})
	var pose2 := skeleton.get_bone_pose(0)
	assert(pose1.is_equal_approx(pose2))

	# Reset to rest by applying zero.
	JointConverter.apply_muscles(profile, skeleton, {muscle_id: 0.0})
	var rest_pose := skeleton.get_bone_pose(0)
	assert(rest_pose.is_equal_approx(skeleton.get_bone_rest(0)))
	print("apply_muscles tests passed")
	quit()
