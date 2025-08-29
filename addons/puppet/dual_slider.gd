@tool
extends Control
class_name DualSlider

signal range_changed(lower: float, upper: float)

## Overall range of slider
@export var min_value := -180.0:
    set(value):
        min_value = value
        _update_handles()

@export var max_value := 180.0:
    set(value):
        max_value = value
        _update_handles()

## Current lower limit
@export var lower := -45.0:
    set(value):
        lower = clamp(value, min_value, upper)
        _update_handles()
        range_changed.emit(lower, upper)

## Current upper limit
@export var upper := 45.0:
    set(value):
        upper = clamp(value, lower, max_value)
        _update_handles()
        range_changed.emit(lower, upper)

var _dragging_left := false
var _dragging_right := false

@onready var _left_handle := ColorRect.new()
@onready var _right_handle := ColorRect.new()

func _ready() -> void:
    _left_handle.color = Color.WHITE
    _left_handle.custom_minimum_size = Vector2(8, 16)
    _left_handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_left_handle)
    _right_handle.color = Color.WHITE
    _right_handle.custom_minimum_size = Vector2(8, 16)
    _right_handle.mouse_filter = Control.MOUSE_FILTER_IGNORE

    add_child(_right_handle)
    mouse_filter = Control.MOUSE_FILTER_PASS
    _update_handles()

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED:
        _update_handles()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            if Rect2(_left_handle.position, _left_handle.size).has_point(event.position):
                _dragging_left = true
            elif Rect2(_right_handle.position, _right_handle.size).has_point(event.position):

                _dragging_right = true
        else:
            _dragging_left = false
            _dragging_right = false
    elif event is InputEventMouseMotion:
        if _dragging_left or _dragging_right:
            var t := clamp(event.position.x / size.x, 0.0, 1.0)
            var val := lerp(min_value, max_value, t)
            if _dragging_left:
                lower = clamp(val, min_value, upper)
            else:
                upper = clamp(val, lower, max_value)

func _update_handles() -> void:
    if not is_inside_tree():
        return
    var width := size.x
    var lh_x := inverse_lerp(min_value, max_value, lower) * width - _left_handle.size.x / 2
    var rh_x := inverse_lerp(min_value, max_value, upper) * width - _right_handle.size.x / 2
    _left_handle.position = Vector2(lh_x, (size.y - _left_handle.size.y) / 2)
    _right_handle.position = Vector2(rh_x, (size.y - _right_handle.size.y) / 2)
    queue_redraw()

func _draw() -> void:
    var track_rect := Rect2(0, size.y / 2 - 2, size.x, 4)
    draw_rect(track_rect, Color.DIM_GRAY)
    var sel_rect := Rect2(_left_handle.position.x + _left_handle.size.x / 2, track_rect.position.y,
        _right_handle.position.x - _left_handle.position.x, track_rect.size.y)
    draw_rect(sel_rect, Color(0.4, 0.7, 1.0))

func set_from_muscle(muscle: Dictionary) -> void:
    lower = muscle.get("min_deg", min_value)
    upper = muscle.get("max_deg", max_value)
