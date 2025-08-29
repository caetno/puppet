extends Control

var muscle := {
    "min_deg": -45.0,
    "max_deg": 45.0,
}

const DualSlider = preload("res://addons/puppet/dual_slider.gd")

@onready var slider: DualSlider = $DualSlider

func _ready() -> void:
    slider.set_from_muscle(muscle)
    slider.range_changed.connect(_on_range_changed)

func _on_range_changed(lower: float, upper: float) -> void:
    muscle["min_deg"] = lower
    muscle["max_deg"] = upper
    print("Updated muscle limits: %s to %s" % [lower, upper])
