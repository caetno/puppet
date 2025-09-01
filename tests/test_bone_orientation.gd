extends SceneTree
const OrientationBaker = preload("res://addons/puppet/bone_orientation.gd")

func _init():
	test_humanoid()
	test_gltf()
	test_mixamo()
	print("All tests passed")
	quit()

func _assert_basis_valid(basis: Basis):
	assert(basis.x.length() > 0.9)
	assert(basis.y.length() > 0.9)
	assert(basis.z.length() > 0.9)
	assert(basis.determinant() > 0.9)

func _build_skeleton(names: Array, parents: Array, positions: Array) -> Skeleton3D:
	var parent_node := Node3D.new()
	get_root().add_child(parent_node)
	var s := Skeleton3D.new()
	parent_node.add_child(s)
	for i in names.size():
	s.add_bone(names[i])
	s.set_bone_parent(i, parents[i])
	s.set_bone_rest(i, Transform3D(Basis(), positions[i]))
	return s

func test_humanoid():
	var names = ["LeftLowerArm", "LeftHand", "LeftMiddleProximal", "LeftMiddleIntermediate"]
	var parents = [-1, 0, 1, 2]
	var positions = [Vector3.ZERO, Vector3(0.3, 0, 0), Vector3(0.2, 0, 0), Vector3(0.1, 0, -0.1)]
	var s = _build_skeleton(names, parents, positions)
	var idx = s.find_bone("LeftMiddleProximal")
	var basis = OrientationBaker.joint_basis_from_skeleton(s, idx)
	_assert_basis_valid(basis)
	assert(basis.y.dot(Vector3.UP) > 0.9)

func test_gltf():
	var names = ["LeftForeArm", "LeftWrist", "LeftMiddleProximal", "LeftMiddleIntermediate"]
	var parents = [-1, 0, 1, 2]
	var positions = [Vector3.ZERO, Vector3(0.3, 0, 0), Vector3(0.2, 0, 0), Vector3(0.1, 0, -0.1)]
	var s = _build_skeleton(names, parents, positions)
	var idx = s.find_bone("LeftMiddleProximal")
	var basis = OrientationBaker.joint_basis_from_skeleton(s, idx)
	_assert_basis_valid(basis)
	assert(basis.y.dot(Vector3.UP) > 0.9)

func test_mixamo():
	var names = ["mixamorig_LeftForeArm", "mixamorig_LeftHand", "mixamorig_LeftHandMiddle1", "mixamorig_LeftHandMiddle2"]
	var parents = [-1, 0, 1, 2]
	var positions = [Vector3.ZERO, Vector3(0.3, 0, 0), Vector3(0.2, 0, 0), Vector3.ZERO]
	var s = _build_skeleton(names, parents, positions)
	var idx = s.find_bone("mixamorig_LeftHandMiddle1")
	var basis = OrientationBaker.joint_basis_from_skeleton(s, idx)
	_assert_basis_valid(basis)
	assert(abs(basis.y.dot(Vector3.UP)) > 0.9)
