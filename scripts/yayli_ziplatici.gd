extends Area2D
## Yaylı zıplatıcı: üstündeki oyuncu/klon/kutuyu yukarı fırlatır.
## Yalnızca aşağı veya duran (velocity.y >= 0) gövdelere etki eder, çoklu tetikleme yoktur.

@export var firlatma_hizi := 820.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = (1 << 1) | (1 << 2) | (1 << 3)


func _physics_process(_delta: float) -> void:
	for g in get_overlapping_bodies():
		if g.get("velocity") != null and g.velocity.y >= 0.0:
			g.velocity.y = -firlatma_hizi
