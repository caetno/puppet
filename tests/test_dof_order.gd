extends SceneTree

const PuppetProfile = preload("res://addons/puppet/profile_resource.gd")

func _compose_rotation(profile: PuppetProfile, basis: Basis, angles: Vector3, bone: String) -> Basis:
    var order: Array = profile.get_dof_order(bone)
    var parts: Dictionary = {
        "x": Basis(basis.x, angles.x),
        "y": Basis(basis.y, angles.y),
        "z": Basis(basis.z, angles.z),
    }
    var rot := Basis()
    for k in order:
        rot = rot * parts[k]
    return rot

func _init():
    var profile := PuppetProfile.new()
    profile.bones["Neck"] = {"dof_order": ["z", "x", "y"]}
    var basis := Basis()
    var angles := Vector3(0.1, 0.2, 0.3)
    var default_rot := _compose_rotation(profile, basis, angles, "Unknown")
    var expected_default := Basis(basis.x, angles.x) * Basis(basis.y, angles.y) * Basis(basis.z, angles.z)
    assert(default_rot.is_equal_approx(expected_default))
    var custom_rot := _compose_rotation(profile, basis, angles, "Neck")
    var expected_custom := Basis(basis.z, angles.z) * Basis(basis.x, angles.x) * Basis(basis.y, angles.y)
    assert(custom_rot.is_equal_approx(expected_custom))
    print("DOF order tests passed")
    quit()

