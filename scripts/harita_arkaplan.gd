extends Control
## Harita arka planı: ortak laboratuvar duvarı (LabArkaplani) ve ince nokta ızgarası (koddan çizilir).

const UST_RENK := Color(0.07, 0.09, 0.15)
const ALT_RENK := Color(0.14, 0.17, 0.27)
const NOKTA_RENGI := Color(1, 1, 1, 0.08)
const ARALIK := 48.0


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	# Ortak laboratuvar duvarı (bölümlerle aynı tema), haritada daha soluk süslerle.
	LabArkaplani.ciz(self, size, 0.7)
	var y := ARALIK / 2.0
	while y < size.y:
		var x := ARALIK / 2.0
		while x < size.x:
			draw_circle(Vector2(x, y), 1.6, NOKTA_RENGI)
			x += ARALIK
		y += ARALIK
