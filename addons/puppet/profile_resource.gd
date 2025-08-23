@tool
extends Resource
class_name MuscleProfile

## Resource storing muscle configuration values for a humanoid avatar.
@export var skeleton: NodePath
@export var muscles: Dictionary = {}
@export var version: String = "0.1"
