extends SceneTree

func _init():
    var JC = load("res://addons/puppet/joint_converter.gd")
    var BO = load("res://addons/puppet/bone_orientation.gd")
    var scene = load("res://addons/puppet/tests/runtime_generation.tscn").instantiate()
    get_root().add_child(scene)
    var skeleton: Skeleton3D = scene.get_node("Skeleton3D")
    JC.call("convert_to_6dof", skeleton)
    var bo = BO.new()
    assert(bo._pre_rotations.has("CustomChest"))
    var joint = skeleton.get_node("CustomChest")
    assert(joint is Generic6DOFJoint3D)
    var MW = load("res://addons/puppet/muscle_window.gd").new()
    var v = MW._axis_to_vector("front_back", "CustomChest", skeleton)
    assert(v.length() > 0.0)
    print("runtime orientation generation ok")
    quit()
