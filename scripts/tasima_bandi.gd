extends StaticBody2D
## Taşıma bandı: katı yüzey; üstündekini Godot'un sabit platform hızıyla taşır.

## 1 = sağ, -1 = sol.
@export var yon := 1
@export var hiz := 100.0


func _ready() -> void:
	collision_layer = 1
	constant_linear_velocity = Vector2(yon * hiz, 0.0)
	# Görünüm: eski kutu gizlenir; kayan kemer/makara çizimini Gorunum yapar (yalnızca görsel).
	var eski := get_node_or_null("Gorsel")
	if eski != null:
		eski.visible = false
	Gorunum.ekle(self, Gorunum.Tur.BANT, Gorunum.sekil_alani(self))
