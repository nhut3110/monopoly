extends Control

# Legacy compatibility overlay node kept lightweight because crisp 3D isometric labels
# (prices on outer camera-facing bevels + uppercase tile names) now live directly on the 3D tiles.

var camera: Camera3D
var game

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
