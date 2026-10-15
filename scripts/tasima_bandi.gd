extends StaticBody2D
## Taşıma bandı: katı yüzey; üstündekini Godot'un sabit platform hızıyla taşır.

## 1 = sağ, -1 = sol.
@export var yon := 1
@export var hiz := 100.0


func _ready() -> void:
	collision_layer = 1
	constant_linear_velocity = Vector2(yon * hiz, 0.0)
