@tool
extends Window

## Placeholder editor window for muscle configuration.
var editor_plugin: EditorPlugin

func _ready() -> void:
    title = "Humanoid Muscles"
    size = Vector2(800, 600)
