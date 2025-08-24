@tool
class_name JointConverter

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

        # Allow all angular movement initially – limits will be applied later.
        new_joint.set("angular_limit_enabled_x", true)
        new_joint.set("angular_limit_enabled_y", true)
        new_joint.set("angular_limit_enabled_z", true)
        new_joint.set("angular_limit_lower_x", -PI)
        new_joint.set("angular_limit_upper_x", PI)
        new_joint.set("angular_limit_lower_y", -PI)
        new_joint.set("angular_limit_upper_y", PI)
        new_joint.set("angular_limit_lower_z", -PI)
        new_joint.set("angular_limit_upper_z", PI)


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
        var lower_prop := "angular_limit_lower_%s" % axis_char
        var upper_prop := "angular_limit_upper_%s" % axis_char
        var enable_prop := "angular_limit_enabled_%s" % axis_char

        joint.set(enable_prop, true)
        joint.set(lower_prop, deg_to_rad(min_deg))
        joint.set(upper_prop, deg_to_rad(max_deg))


# -- Helpers ----------------------------------------------------------------
static func _axis_to_char(axis: String) -> String:
    # Maps the profile axis names to the corresponding Generic6DOFJoint axis.
    match axis:
        "front_back", "nod", "down_up", "finger_open_close":
            return "x"
        "left_right":
            return "y"
        "tilt":
            return "z"
        _:
            return ""
