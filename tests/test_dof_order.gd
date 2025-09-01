extends SceneTree

const DOF_ORDER := {
    "Neck": ["z", "x", "y"],
}

func _compose_rotation(basis: Basis, angles: Vector3, bone: String) -> Basis:
    var order: Array = DOF_ORDER.get(bone, ["x", "y", "z"])
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
    var basis := Basis()
    var angles := Vector3(0.1, 0.2, 0.3)
    var default_rot := _compose_rotation(basis, angles, "Unknown")
    var expected_default := Basis(basis.x, angles.x) * Basis(basis.y, angles.y) * Basis(basis.z, angles.z)
    assert(default_rot.is_equal_approx(expected_default))
    var custom_rot := _compose_rotation(basis, angles, "Neck")
    var expected_custom := Basis(basis.z, angles.z) * Basis(basis.x, angles.x) * Basis(basis.y, angles.y)
    assert(custom_rot.is_equal_approx(expected_custom))
    print("DOF order tests passed")
    quit()
