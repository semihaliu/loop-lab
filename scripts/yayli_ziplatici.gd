extends Area2D
## Yaylı zıplatıcı: üstündeki oyuncu/klon/kutuyu yukarı fırlatır.
## Yalnızca aşağı veya duran (velocity.y >= 0) gövdelere etki eder, çoklu tetikleme yoktur.

@export var firlatma_hizi := 820.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = (1 << 1) | (1 << 2) | (1 << 3)
	# Görünüm: düz kutu gizlenir, yay/ped çizimini Gorunum yapar (yalnızca görsel).
	var eski := get_node_or_null("Gorsel")
	if eski != null:
		eski.visible = false
	Gorunum.ekle(self, Gorunum.Tur.ZIPLATICI, Gorunum.sekil_alani(self))


func _physics_process(_delta: float) -> void:
	for g in get_overlapping_bodies():
		if g.get("velocity") != null and g.velocity.y >= 0.0:
			g.velocity.y = -firlatma_hizi
