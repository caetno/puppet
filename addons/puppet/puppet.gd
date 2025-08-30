@tool
extends EditorPlugin
const MuscleWindow = preload("res://addons/puppet/muscle_window.gd")

var _button: Button
var _muscle_window: MuscleWindow

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
	var nodes := get_editor_interface().get_selection().get_selected_nodes()
	if nodes.size() > 0 and nodes[0] is Skeleton3D:
		_muscle_window.load_skeleton(nodes[0])
	_muscle_window.popup_centered()

func _update_button_visibility() -> void:
	var nodes := get_editor_interface().get_selection().get_selected_nodes()
	var node: Node = null
	if nodes.size() > 0:
		node = nodes[0]
	if node is Skeleton3D:
		_button.visible = true
	else:
		_button.visible = false
