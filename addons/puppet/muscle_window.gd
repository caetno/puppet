@tool
extends Window

## Placeholder editor window for muscle configuration.
var editor_plugin: EditorPlugin

@onready var _tree: Tree = $Split/Tree
@onready var _viewport_container: SubViewportContainer = $Split/SubViewportContainer
@onready var _list: VBoxContainer = $Split/PanelContainer/ScrollContainer/VBoxContainer

func _ready() -> void:
    title = "Humanoid Muscles"
    size = Vector2(800, 600)
