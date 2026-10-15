class_name LabArkaplani
extends Control
## Laboratuvar duvarı: degrade, panel dikişleri, borular, dişli, kadran, kırık monitör, soluk ışık.
## Bölümlerde en alt CanvasLayer'a, menü ve haritada kök altına konur. Yalnızca görünüm;
## rastgelelik yok (her şey sabit sayılardan çizilir), kontrast düşük tutulur.

## Yoğunluk 1.0 bölüm arka planı, haritada daha az süs için 0.6 verilebilir.
var yogunluk := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# CanvasLayer altında anchor boyut vermez; ekran boyutu açıkça verilir. Anchor ve boyut
	# birlikte verilirse Godot "size overridden after _ready()" uyarısı üretir, o yüzden ayrı dallar.
	if get_parent() is CanvasLayer:
		size = get_viewport_rect().size
	else:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)


func _draw() -> void:
	if LabPaleti.ekransiz():
		return
	ciz(self, size, yogunluk)


## Çizimi verilen CanvasItem üzerine yapar (başka betikler de çağırabilir).
static func ciz(ci: CanvasItem, boyut: Vector2, yogunluk: float = 1.0) -> void:
	var w := boyut.x
	var h := boyut.y
	# Degrade zemin
	ci.draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([LabPaleti.ARKA_UST, LabPaleti.ARKA_UST, LabPaleti.ARKA_ALT, LabPaleti.ARKA_ALT]))
	# Karo/panel dikişleri (96 px) ve çatlak karoların açık/koyu tonu
	var dikis := Color(1, 1, 1, 0.035)
	var x := 0.0
	while x <= w:
		ci.draw_line(Vector2(x, 0), Vector2(x, h), dikis, 2.0)
		x += 96.0
	var y := 0.0
	while y <= h:
		ci.draw_line(Vector2(0, y), Vector2(w, y), dikis, 2.0)
		y += 96.0
	# Bazı karolar biraz daha aydınlık/koyu (sabit desen, indeks hesabı)
	for i in range(int(w / 96.0) + 1):
		for j in range(int(h / 96.0) + 1):
			var n := (i * 7 + j * 13 + i * j) % 9
			if n == 0:
				ci.draw_rect(Rect2(i * 96 + 2, j * 96 + 2, 92, 92), Color(1, 1, 1, 0.025))
			elif n == 4:
				ci.draw_rect(Rect2(i * 96 + 2, j * 96 + 2, 92, 92), Color(0, 0, 0, 0.18))
	# Soluk ışık hüzmeleri (tavan lambaları)
	for lx in [w * 0.2, w * 0.55, w * 0.88]:
		ci.draw_colored_polygon(
			PackedVector2Array([Vector2(lx - 8, 0), Vector2(lx + 8, 0), Vector2(lx + 90, h * 0.8), Vector2(lx - 90, h * 0.8)]),
			Color(LabPaleti.CAMGOBEGI, 0.035 * yogunluk))
	if yogunluk < 0.3:
		return
	# Borular: yatay ve dikey, bağlantı halkalarıyla
	_boru(ci, Vector2(0, h * 0.11), Vector2(w, h * 0.11), 14.0)
	_boru(ci, Vector2(0, h * 0.53), Vector2(w * 0.35, h * 0.53), 10.0)
	_boru(ci, Vector2(w * 0.35, h * 0.53), Vector2(w * 0.35, h), 10.0)
	_boru(ci, Vector2(w * 0.78, h * 0.11), Vector2(w * 0.78, h * 0.62), 12.0)
	# Dişli ve kadran (büyük, çok soluk)
	_disli(ci, Vector2(w * 0.12, h * 0.78), 64.0, 12, 0.0)
	_disli(ci, Vector2(w * 0.12 + 92, h * 0.78 - 56), 36.0, 8, 0.2)
	_kadran(ci, Vector2(w * 0.62, h * 0.3), 58.0)
	# Kırık monitörler
	_monitor(ci, Rect2(w * 0.43, h * 0.2, 86, 58), false)
	_monitor(ci, Rect2(w * 0.9 - 40, h * 0.7, 70, 48), true)


static func _boru(ci: CanvasItem, a: Vector2, b: Vector2, kalin: float) -> void:
	ci.draw_line(a, b, Color(0, 0, 0, 0.45), kalin + 4.0)
	ci.draw_line(a, b, Color(LabPaleti.METAL, 0.28), kalin)
	ci.draw_line(a, b, Color(LabPaleti.METAL_ACIK, 0.12), kalin * 0.3)
	# Bağlantı halkaları
	var uz := a.distance_to(b)
	var yon := (b - a) / maxf(uz, 1.0)
	var dik := Vector2(-yon.y, yon.x)
	var t := 120.0
	while t < uz:
		var p := a + yon * t
		ci.draw_line(p - dik * (kalin * 0.7), p + dik * (kalin * 0.7), Color(LabPaleti.PAS, 0.5), 6.0)
		t += 240.0


static func _disli(ci: CanvasItem, c: Vector2, r: float, dis: int, faz: float) -> void:
	# Köşeli diş şekli: her diş için iki köşe
	var poly := PackedVector2Array()
	for i in range(dis):
		var a0 := faz + TAU * i / dis
		var da := TAU / dis
		for k in [[0.0, 0.82], [0.12, 1.0], [0.38, 1.0], [0.5, 0.82]]:
			var a1: float = a0 + da * float(k[0]) * 1.0
			poly.append(c + Vector2(cos(a1), sin(a1)) * r * float(k[1]))
	ci.draw_colored_polygon(poly, Color(LabPaleti.PANEL_ACIK, 0.5))
	ci.draw_circle(c, r * 0.55, Color(LabPaleti.ARKA_UST, 0.6))
	ci.draw_arc(c, r * 0.55, 0.0, TAU, 28, Color(LabPaleti.METAL, 0.3), 3.0)
	ci.draw_circle(c, r * 0.16, Color(LabPaleti.METAL, 0.35))


static func _kadran(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c, r + 6.0, Color(LabPaleti.KENAR, 0.55))
	ci.draw_arc(c, r, 0.0, TAU, 48, Color(LabPaleti.CAM_SOLUK, 0.5), 4.0)
	for i in range(12):
		var a := TAU * i / 12.0
		var d := Vector2(cos(a), sin(a))
		ci.draw_line(c + d * (r - 10.0), c + d * (r - 2.0), Color(LabPaleti.CAMGOBEGI, 0.4), 3.0)
	# Takılı kalmış akrep ve yelkovan (zaman durmuş)
	ci.draw_line(c, c + Vector2(cos(-1.1), sin(-1.1)) * r * 0.55, Color(LabPaleti.CAMGOBEGI, 0.45), 4.0)
	ci.draw_line(c, c + Vector2(cos(2.2), sin(2.2)) * r * 0.78, Color(LabPaleti.CAMGOBEGI, 0.35), 3.0)
	ci.draw_circle(c, 5.0, Color(LabPaleti.CAMGOBEGI, 0.5))


static func _monitor(ci: CanvasItem, r: Rect2, yanik: bool) -> void:
	ci.draw_rect(r.grow(5.0), Color(LabPaleti.KENAR, 0.7))
	ci.draw_rect(r, Color(LabPaleti.PANEL, 0.7) if yanik else Color(LabPaleti.CAM_SOLUK, 0.22))
	# Çatlak
	var a := r.position + Vector2(r.size.x * 0.35, 0)
	var m1 := r.position + Vector2(r.size.x * 0.5, r.size.y * 0.4)
	var m2 := r.position + Vector2(r.size.x * 0.42, r.size.y * 0.7)
	var b := r.position + Vector2(r.size.x * 0.7, r.size.y)
	ci.draw_polyline(PackedVector2Array([a, m1, m2, b]), Color(0, 0, 0, 0.6), 2.0)
	# Tarama çizgileri
	var yy := r.position.y + 6.0
	while yy < r.end.y:
		ci.draw_line(Vector2(r.position.x, yy), Vector2(r.end.x, yy), Color(1, 1, 1, 0.04), 1.0)
		yy += 8.0
