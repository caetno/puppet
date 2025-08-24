@tool
class_name JointConverter

const MuscleProfile = preload("res://addons/puppet/profile_resource.gd")

## Utility functions for converting joints and applying limits.

# -- Joint conversion -------------------------------------------------------
# The editor often creates physical bones using a variety of joint types
# (hinge, cone‐twist …).  For the purposes of the muscle system we want every
# bone to use a fully configurable 6 degrees of freedom joint so the limits can
# be adjusted individually on each axis.  `convert_to_6dof` walks the given
# skeleton and replaces every existing `Joint3D` descendant with a
# `Generic6DOFJoint3D` while preserving the original attachment nodes and
# transform.
static func convert_to_6dof(skeleton: Skeleton3D) -> void:
    if skeleton == null:
        return

    # Collect all joints that need to be converted.  We gather them first so we
    # can safely modify the scene tree while iterating.
    var to_convert: Array = []

    var stack: Array = [skeleton]
    while stack.size() > 0:
        var node: Node = stack.pop_back()
        for child in node.get_children():
            stack.append(child)
            if child is Joint3D and not (child is Generic6DOFJoint3D):
                to_convert.append(child)

    for old_joint in to_convert:
        var new_joint := Generic6DOFJoint3D.new()
        new_joint.name = old_joint.name
        new_joint.transform = old_joint.transform
        # Preserve the bodies the joint is attached to.
        new_joint.node_a = old_joint.node_a
        new_joint.node_b = old_joint.node_b
        new_joint.disable_collisions_between_bodies = old_joint.disable_collisions_between_bodies

        # Place the new joint in the same position in the scene tree.
        var parent: Node = old_joint.get_parent()
        var idx: int = parent.get_children().find(old_joint)
        parent.remove_child(old_joint)
        parent.add_child(new_joint)
        parent.move_child(new_joint, idx)
        old_joint.queue_free()

        # Configure default angular limits on the three joint axes.  Godot
        # requires the axis vectors to be normalised before limits are enabled,
        # so derive them from the joint's basis and store them explicitly.
        var basis := new_joint.transform.basis.orthonormalized()
        new_joint.transform.basis = basis
        new_joint.set("angular_limit_x/axis", basis.x)
        new_joint.set("angular_limit_y/axis", basis.y)
        new_joint.set("angular_limit_z/axis", basis.z)

        new_joint.set("angular_limit_x/enabled", true)
        new_joint.set("angular_limit_y/enabled", true)
        new_joint.set("angular_limit_z/enabled", true)
        new_joint.set("angular_limit_x/lower_angle", -PI)
        new_joint.set("angular_limit_x/upper_angle", PI)
        new_joint.set("angular_limit_y/lower_angle", -PI)
        new_joint.set("angular_limit_y/upper_angle", PI)
        new_joint.set("angular_limit_z/lower_angle", -PI)
        new_joint.set("angular_limit_z/upper_angle", PI)


# -- Limit application ------------------------------------------------------
# Reads limit information from a `MuscleProfile` and applies it to the 6‑DOF
# joints generated above.  Each muscle entry defines a bone, an axis and the
# minimum / maximum angles in degrees.  The limits are translated to the
# corresponding joint properties.
static func apply_limits(profile: MuscleProfile, skeleton: Skeleton3D) -> void:
    if profile == null or skeleton == null:
        return

    # Build a lookup table of joints by name for fast access when iterating
    # over the muscles.  The typical workflow is to name the joint after the
    # bone it controls which makes this straightforward.
    var joints: Dictionary = {}

    var stack: Array = [skeleton]
    while stack.size() > 0:
        var node: Node = stack.pop_back()
        for child in node.get_children():
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

        var axis_char := _axis_to_char(axis)
        if axis_char == "":
            continue
        var base := "angular_limit_%s" % axis_char
        joint.set("%s/enabled" % base, true)
        joint.set("%s/lower_angle" % base, deg_to_rad(min_deg))
        joint.set("%s/upper_angle" % base, deg_to_rad(max_deg))


# -- Helpers ----------------------------------------------------------------
static func _axis_to_char(axis: String) -> String:
    # Maps the profile axis names to the corresponding Generic6DOFJoint axis.
    match axis:
        "front_back", "nod", "down_up", "finger_open_close", "open_close":
            return "x"
        "left_right":
            return "y"
        "tilt":
            return "z"
        _:
            return ""
