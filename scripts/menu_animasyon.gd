extends Control
## Ana menü arka plan animasyonu: yavaş dönen kadran halkası, yükselen kabarcıklar, nabız atan ışık.
## Yalnızca görünüm; `_process` görsel zamanla çalışır, rastgelelik yok. Ekransız modda kapalı.

var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(not LabPaleti.ekransiz())


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if LabPaleti.ekransiz():
		return
	var c := size * 0.5
	var nabiz := 0.5 + 0.5 * sin(_t * 0.9)
	# Büyük kadran halkası
	var r := minf(size.x, size.y) * 0.46
	draw_arc(c, r, 0.0, TAU, 96, Color(LabPaleti.CAM_SOLUK, 0.18 + 0.08 * nabiz), 3.0, true)
	draw_arc(c, r * 0.8, 0.0, TAU, 96, Color(LabPaleti.CAM_SOLUK, 0.10), 2.0, true)
	for i in range(60):
		var a := TAU * i / 60.0 + _t * 0.05
		var d := Vector2(cos(a), sin(a))
		var uzun := i % 5 == 0
		draw_line(c + d * r, c + d * (r - (16.0 if uzun else 7.0)), Color(LabPaleti.CAMGOBEGI, 0.22 if uzun else 0.10), 2.0)
	# Kadran ibreleri
	var a1 := _t * 0.35
	var a2 := _t * 0.35 / 12.0
	draw_line(c, c + Vector2(cos(a1), sin(a1)) * r * 0.75, Color(LabPaleti.CAMGOBEGI, 0.16), 4.0)
	draw_line(c, c + Vector2(cos(a2), sin(a2)) * r * 0.5, Color(LabPaleti.AMBER, 0.16), 6.0)
	draw_circle(c, 7.0, Color(LabPaleti.AMBER, 0.2))
	# Yükselen kabarcıklar (sabit sayılardan)
	for i in range(14):
		var hiz := 14.0 + (i % 5) * 6.0
		var x := fmod(37.0 + i * 83.0, size.x) + sin(_t * 0.6 + i) * 12.0
		var y := size.y + 20.0 - fmod(_t * hiz + i * 97.0, size.y + 40.0)
		draw_circle(Vector2(x, y), 3.0 + (i % 3) * 2.0, Color(LabPaleti.CAMGOBEGI, 0.10))
