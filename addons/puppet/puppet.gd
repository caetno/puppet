@tool
extends EditorPlugin

var _button: Button
var _muscle_window: Window

func _enter_tree() -> void:
    _button = Button.new()
    _button.text = "Muscles"
    _button.pressed.connect(_on_button_pressed)
    add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, _button)
    get_editor_interface().get_selection().selection_changed.connect(_update_button_visibility)
    _update_button_visibility()

func _exit_tree() -> void:
    get_editor_interface().get_selection().selection_changed.disconnect(_update_button_visibility)
    remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, _button)
    _button.free()
    if _muscle_window:
        _muscle_window.queue_free()

func _on_button_pressed() -> void:
    if _muscle_window == null:
        _muscle_window = preload("res://addons/puppet/muscle_window.tscn").instantiate()
        _muscle_window.editor_plugin = self
        get_editor_interface().get_editor_main_screen().add_child(_muscle_window)
    _muscle_window.popup_centered()

func _update_button_visibility() -> void:
    var nodes := get_editor_interface().get_selection().get_selected_nodes()
    var node: Node = nodes.size() > 0 ? nodes[0] : null
    _button.visible = node is Skeleton3D and _has_humanoid_map(node)

func _has_humanoid_map(skeleton: Skeleton3D) -> bool:
    return skeleton.humanoid_bone_map != null
