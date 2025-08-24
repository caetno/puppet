@tool
extends Window

## Placeholder editor window for muscle configuration.
var editor_plugin: EditorPlugin

@onready var _viewport: SubViewport = $VBox/ViewportContainer/Viewport
@onready var _pivot: Node3D = _viewport.get_node("Pivot")
@onready var _camera: Camera3D = _pivot.get_node("Camera3D")

func _ready() -> void:
    title = "Humanoid Muscles"
    size = Vector2(800, 600)

func _on_viewport_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            _camera.translate_object_local(Vector3(0, 0, -0.5))
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            _camera.translate_object_local(Vector3(0, 0, 0.5))
    elif event is InputEventMouseMotion:
        var delta := event.relative
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            var x_rot := clamp(_pivot.rotation.x - delta.y * 0.01, -PI / 2.0, PI / 2.0)
            _pivot.rotation.x = x_rot
            _pivot.rotate_y(-delta.x * 0.01)
        elif Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
            var right := _pivot.global_transform.basis.x
            var up := _pivot.global_transform.basis.y
            _pivot.translate(-right * delta.x * 0.01 + up * delta.y * 0.01)
