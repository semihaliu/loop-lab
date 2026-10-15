class_name Gorunum
extends Node2D
## Dünya nesnelerinin ortak görünümü (yalnızca çizim). Bir nesnenin çocuğu olarak eklenir,
## durumu üst düğümden OKUR (basılı mı, açık mı...) ve hiçbir şeyi değiştirmez.
## Çarpışma, konum ve mantığa dokunmaz. Rastgelelik yok; animasyon fizik karesinden türer.
## Katman: asansör/geçit z_index = -1 çizilir, böylece zemin/kat içine gömülürken örtülür.

enum Tur { DUVAR, TEK_YONLU, PLAKA, ASANSOR, KAPI, GECIT, SALTER, LAZER, ASANSOR_ISARET }

var tur: Tur = Tur.DUVAR
## Nesnenin yerel dikdörtgeni (üst düğümün yerel koordinatı).
var alan := Rect2()


## Üst düğüme görünüm ekler. alan verilmezse tür kendi varsayılanını kullanır.
static func ekle(ust: Node, t: Tur, a: Rect2 = Rect2()) -> Gorunum:
	var g := Gorunum.new()
	g.name = "Gorunum"
	g.tur = t
	g.alan = a
	if t == Tur.ASANSOR or t == Tur.GECIT:
		g.z_index = -1
	ust.add_child(g)
	if t == Tur.ASANSOR:
		# Zemine gömülü asansörün dinlenme yeri görünür kalsın diye üstte ince işaret çizilir.
		var i := Gorunum.new()
		i.name = "GorunumIsaret"
		i.tur = Tur.ASANSOR_ISARET
		i.alan = a
		ust.add_child(i)
	return g


## Üst düğümün ilk CollisionShape2D'sinin dikdörtgenini yerel koordinatta verir.
static func sekil_alani(ust: Node) -> Rect2:
	for c in ust.get_children():
		if c is CollisionShape2D and c.shape is RectangleShape2D:
			var b: Vector2 = c.shape.size
			return Rect2(c.position - b / 2.0, b)
	return Rect2(-10, -10, 20, 20)


func _process(_delta: float) -> void:
	if LabPaleti.ekransiz():
		return
	queue_redraw()


func _faz() -> int:
	return Engine.get_physics_frames()


func _draw() -> void:
	if LabPaleti.ekransiz():
		return
	match tur:
		Tur.DUVAR: _duvar(alan)
		Tur.TEK_YONLU: _tek_yonlu(alan)
		Tur.PLAKA: _plaka()
		Tur.ASANSOR: _asansor()
		Tur.KAPI: _kapi()
		Tur.GECIT: _gecit()
		Tur.SALTER: _salter()
		Tur.LAZER: _lazer()
		Tur.ASANSOR_ISARET: _asansor_isaret()


# ---------- yardımcılar ----------

func _percin(p: Vector2, renk: Color = LabPaleti.METAL_ACIK) -> void:
	draw_circle(p, 2.2, LabPaleti.KENAR)
	draw_circle(p + Vector2(-0.4, -0.4), 1.4, renk)


func _cerceve(r: Rect2, dolgu: Color, kenar: Color = LabPaleti.KENAR, kalin := 2.0) -> void:
	draw_rect(r, kenar)
	draw_rect(r.grow(-kalin), dolgu)


# ---------- zemin / duvar / tavan ----------

func _duvar(r: Rect2) -> void:
	_cerceve(r, LabPaleti.PANEL)
	var ic := r.grow(-2.0)
	# Üst yüzey: yürünen kenar, soluk camgöbeği ışıklı şerit
	draw_rect(Rect2(ic.position, Vector2(ic.size.x, minf(5.0, ic.size.y))), LabPaleti.PANEL_ACIK)
	draw_rect(Rect2(ic.position, Vector2(ic.size.x, 1.5)), Color(LabPaleti.CAMGOBEGI, 0.55))
	# Alt gölge
	if ic.size.y > 12.0:
		draw_rect(Rect2(ic.position.x, ic.end.y - 4.0, ic.size.x, 4.0), Color(0, 0, 0, 0.3))
	# Panel dikişleri (64 px aralık, sabit)
	var x := ic.position.x + 64.0
	while x < ic.end.x - 4.0:
		draw_line(Vector2(x, ic.position.y + 6.0), Vector2(x, ic.end.y - 2.0), Color(0, 0, 0, 0.35), 2.0)
		draw_line(Vector2(x + 2.0, ic.position.y + 6.0), Vector2(x + 2.0, ic.end.y - 2.0), Color(1, 1, 1, 0.05), 1.0)
		if ic.size.y >= 20.0:
			_percin(Vector2(x - 8.0, ic.position.y + 12.0), LabPaleti.METAL)
			_percin(Vector2(x + 10.0, ic.end.y - 8.0), LabPaleti.METAL)
		x += 64.0
	# Pas lekeleri ve çatlak (sabit desen)
	var n := int(ic.size.x / 120.0)
	for i in range(n + 1):
		var cx := ic.position.x + 40.0 + i * 120.0
		if cx > ic.end.x - 10.0:
			continue
		if i % 2 == 0:
			draw_rect(Rect2(cx, ic.position.y + 5.0, 14.0, 4.0), Color(LabPaleti.PAS, 0.55))
		if ic.size.y >= 28.0 and i % 3 == 1:
			var y0 := ic.position.y + 8.0
			draw_polyline(PackedVector2Array([Vector2(cx, y0), Vector2(cx + 5, y0 + 9), Vector2(cx - 2, y0 + 16), Vector2(cx + 6, y0 + 24)]), Color(0, 0, 0, 0.5), 1.5)
	# Dik duvar parçası: kenar vurgusu
	if r.size.x < r.size.y:
		draw_rect(Rect2(ic.position.x, ic.position.y, 2.0, ic.size.y), Color(LabPaleti.CAMGOBEGI, 0.18))


func _tek_yonlu(r: Rect2) -> void:
	_cerceve(r, LabPaleti.METAL)
	var ic := r.grow(-2.0)
	var x := ic.position.x + 4.0
	while x < ic.end.x - 2.0:
		draw_rect(Rect2(x, ic.position.y + 2.0, 5.0, ic.size.y - 4.0), Color(0, 0, 0, 0.45))
		x += 10.0
	# Üstü açık yeşil çizgi: "içinden yukarı geçilir" işareti
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2.0), LabPaleti.YESIL)
	draw_rect(Rect2(r.position.x, r.position.y - 2.0, r.size.x, 2.0), Color(LabPaleti.YESIL, 0.25))


# ---------- basınç plakası ----------

func _plaka() -> void:
	var basili: bool = get_parent().basili_mi()
	# Yuva (alt) ve plaka (üst)
	draw_rect(Rect2(-31, -2, 62, 10), LabPaleti.KENAR)
	draw_rect(Rect2(-29, 0, 58, 7), LabPaleti.PASLI)
	var ust := 2.0 if basili else -5.0
	var renk := LabPaleti.CAMGOBEGI if basili else LabPaleti.AMBER
	draw_rect(Rect2(-26, ust, 52, 5), LabPaleti.KENAR)
	draw_rect(Rect2(-25, ust + 1.0, 50, 3), renk.darkened(0.15))
	# Hazard şeritleri (boşta belirgin)
	if not basili:
		for i in range(5):
			draw_line(Vector2(-22 + i * 11, ust + 4.0), Vector2(-16 + i * 11, ust + 1.0), LabPaleti.KENAR, 2.0)
	# Gösterge lambası: basılıyken parlar
	var lamba := LabPaleti.YESIL if basili else LabPaleti.UYARI_KOYU
	if basili:
		draw_circle(Vector2(0, -9), 7.0, Color(LabPaleti.YESIL, 0.18))
	draw_circle(Vector2(0, -9), 2.8, lamba)


# ---------- asansör ----------

func _asansor() -> void:
	var p: Node = get_parent()
	var yarim := Vector2(60, 10)
	if alan.size != Vector2.ZERO:
		yarim = alan.size / 2.0
	# Ray: alt ve üst konum arası, platform hareket etse de sabit yerde durur
	var ust_ofs: float = p.ust_y - p.position.y
	var alt_ofs: float = p.alt_y - p.position.y
	for sx in [-yarim.x + 6.0, yarim.x - 6.0]:
		draw_rect(Rect2(sx - 2.0, ust_ofs - yarim.y, 4.0, alt_ofs - ust_ofs + yarim.y * 2.0), Color(LabPaleti.METAL, 0.55))
		draw_rect(Rect2(sx - 0.5, ust_ofs - yarim.y, 1.0, alt_ofs - ust_ofs + yarim.y * 2.0), Color(1, 1, 1, 0.12))
	# Platform
	var r := Rect2(-yarim, yarim * 2.0)
	_cerceve(r, LabPaleti.METAL)
	draw_rect(Rect2(r.position.x + 2, r.position.y + 2, r.size.x - 4, 3), LabPaleti.METAL_ACIK)
	# Sarı-siyah uyarı şeridi (alt yarı)
	var x := r.position.x + 4.0
	var y0 := r.position.y + r.size.y * 0.5
	var y1 := r.end.y - 2.0
	while x < r.end.x - 10.0:
		draw_colored_polygon(PackedVector2Array([Vector2(x, y1), Vector2(x + 6, y0), Vector2(x + 12, y0), Vector2(x + 6, y1)]), LabPaleti.AMBER)
		x += 14.0
	_percin(Vector2(r.position.x + 5, r.position.y + 5))
	_percin(Vector2(r.end.x - 5, r.position.y + 5))


# ---------- kapı (hedef) ----------

func _kapi() -> void:
	var acik: bool = get_parent().acik
	var r := Rect2(-18, -24, 36, 48)
	draw_rect(r.grow(2.0), LabPaleti.KENAR)
	draw_rect(r, LabPaleti.PANEL_ACIK)
	var ic := r.grow(-5.0)
	var nabiz := 0.5 + 0.5 * sin(_faz() * 0.08)
	if acik:
		draw_circle(Vector2(0, 0), 30.0, Color(LabPaleti.YESIL, 0.12))
		draw_rect(ic, Color(LabPaleti.YESIL, 0.85))
		draw_rect(Rect2(ic.position.x + ic.size.x * 0.25, ic.position.y, ic.size.x * 0.5, ic.size.y), Color(1, 1, 1, 0.55))
	else:
		draw_rect(ic, LabPaleti.KENAR)
		# Kapalı: iki kanat, ortada kadran işareti
		draw_rect(Rect2(ic.position.x, ic.position.y, ic.size.x / 2.0 - 1.0, ic.size.y), LabPaleti.PASLI)
		draw_rect(Rect2(0.5, ic.position.y, ic.size.x / 2.0 - 0.5, ic.size.y), LabPaleti.PASLI.lightened(0.08))
		draw_arc(Vector2(0, 0), 7.0, 0.0, TAU, 20, LabPaleti.AMBER, 2.0)
		draw_line(Vector2(0, 0), Vector2(0, -5), LabPaleti.AMBER, 2.0)
		draw_line(Vector2(0, 0), Vector2(4, 1), LabPaleti.AMBER, 2.0)
	var lamba := LabPaleti.YESIL if acik else LabPaleti.AMBER.lerp(LabPaleti.UYARI, 0.3)
	draw_circle(Vector2(0, -29), 3.0, Color(lamba, 0.5 + 0.5 * nabiz))
	draw_circle(Vector2(0, -29), 6.0, Color(lamba, 0.18 * nabiz))


# ---------- geçit ----------

func _gecit() -> void:
	var p: Node = get_parent()
	var r: Rect2 = alan
	var yol: Vector2 = p.acik_konum - p.kapali_konum
	var oran := 0.0
	if yol.length() > 0.0:
		oran = clampf((p.position - p.kapali_konum).length() / yol.length(), 0.0, 1.0)
	var acik := oran > 0.5
	_cerceve(r, LabPaleti.MOR_KOYU)
	var ic := r.grow(-2.0)
	var lamel := LabPaleti.MOR.darkened(0.35) if acik else LabPaleti.MOR
	var uzun_dikey := r.size.y >= r.size.x
	if uzun_dikey:
		var y := ic.position.y + 6.0
		while y < ic.end.y - 4.0:
			draw_rect(Rect2(ic.position.x, y, ic.size.x, 4.0), lamel)
			draw_rect(Rect2(ic.position.x, y + 4.0, ic.size.x, 2.0), Color(0, 0, 0, 0.35))
			y += 14.0
	else:
		var x := ic.position.x + 6.0
		while x < ic.end.x - 4.0:
			draw_rect(Rect2(x, ic.position.y, 4.0, ic.size.y), lamel)
			x += 14.0
	# Durum lambası: kapalı = kırmızı, açık = yeşil; ucu kapanan taraftadır (görünen uç)
	var lamba := LabPaleti.YESIL if acik else LabPaleti.UYARI
	var uc: Vector2
	if uzun_dikey:
		uc = Vector2(0, r.end.y - 8.0) if p.kayma_yonu.y <= 0.0 else Vector2(0, r.position.y + 8.0)
	else:
		uc = Vector2(r.end.x - 8.0, 0) if p.kayma_yonu.x <= 0.0 else Vector2(r.position.x + 8.0, 0)
	draw_circle(uc, 8.0, Color(lamba, 0.2))
	draw_circle(uc, 3.5, lamba)
	if not acik:
		var u := Color(LabPaleti.UYARI, 0.8)
		if uzun_dikey:
			draw_rect(Rect2(r.position.x, r.position.y, 2.0, r.size.y), u)
			draw_rect(Rect2(r.end.x - 2.0, r.position.y, 2.0, r.size.y), u)
		else:
			draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 2.0), u)
			draw_rect(Rect2(r.position.x, r.end.y - 2.0, r.size.x, 2.0), u)


# ---------- şalter ----------

func _salter() -> void:
	var sagda: bool = get_parent().sagda
	_cerceve(Rect2(-30, -10, 60, 10), LabPaleti.PASLI)
	draw_rect(Rect2(-26, -8, 52, 2), Color(1, 1, 1, 0.12))
	_percin(Vector2(-25, -4))
	_percin(Vector2(25, -4))
	# Sol/sağ konum işaretleri
	draw_circle(Vector2(-22, -14), 2.5, LabPaleti.UYARI if not sagda else LabPaleti.UYARI_KOYU)
	draw_circle(Vector2(22, -14), 2.5, LabPaleti.YESIL if sagda else Color(LabPaleti.YESIL, 0.2))
	# Kol: tabandan çıkar, sağa/sola yatık; ucunda top
	var aci := 0.7 if sagda else -0.7
	var uc := Vector2(0, -10) + Vector2(sin(aci), -cos(aci)) * 36.0
	draw_line(Vector2(0, -10), uc, LabPaleti.KENAR, 7.0)
	draw_line(Vector2(0, -10), uc, LabPaleti.METAL_ACIK, 4.0)
	var top := LabPaleti.YESIL if sagda else LabPaleti.UYARI
	draw_circle(uc, 7.0, LabPaleti.KENAR)
	draw_circle(uc, 5.0, top)
	draw_circle(uc + Vector2(-1.5, -1.5), 1.8, Color(1, 1, 1, 0.5))
	draw_circle(Vector2(0, -10), 4.0, LabPaleti.KENAR)


# ---------- lazer ----------

func _lazer() -> void:
	var p: Node = get_parent()
	var d: Vector2 = p.yon.normalized() if p.yon != Vector2.ZERO else Vector2.RIGHT
	var uz: float = p.uzunluk
	var dik := Vector2(-d.y, d.x)
	var acik: bool = p.acik_mi()
	var son := d * uz
	if acik:
		var nabiz := 0.5 + 0.5 * sin(_faz() * 0.5)
		draw_line(Vector2.ZERO, son, Color(LabPaleti.UYARI, 0.18 + 0.1 * nabiz), 14.0)
		draw_line(Vector2.ZERO, son, Color(LabPaleti.UYARI, 0.55), 7.0)
		draw_line(Vector2.ZERO, son, Color(1.0, 0.85, 0.8), 2.5)
	else:
		# Kapalı: soluk noktalı kılavuz (ışının nereden geçeceği belli olsun)
		var t := 0.0
		while t < uz:
			draw_line(d * t, d * minf(t + 4.0, uz), Color(LabPaleti.UYARI_KOYU, 0.55), 2.0)
			t += 14.0
	# Yayıcı gövdesi ve karşı uçta alıcı
	var g := PackedVector2Array([-d * 8.0 + dik * 11.0, d * 4.0 + dik * 11.0, d * 4.0 - dik * 11.0, -d * 8.0 - dik * 11.0])
	draw_colored_polygon(g, LabPaleti.KENAR)
	var g2 := PackedVector2Array([-d * 6.0 + dik * 9.0, d * 2.0 + dik * 9.0, d * 2.0 - dik * 9.0, -d * 6.0 - dik * 9.0])
	draw_colored_polygon(g2, LabPaleti.METAL)
	var lamba := LabPaleti.UYARI if acik else LabPaleti.UYARI_KOYU
	draw_circle(d * 3.0, 4.5, lamba)
	if acik:
		draw_circle(d * 3.0, 9.0, Color(LabPaleti.UYARI, 0.25))
	var a := PackedVector2Array([son + d * 3.0 + dik * 8.0, son - d * 5.0 + dik * 8.0, son - d * 5.0 - dik * 8.0, son + d * 3.0 - dik * 8.0])
	draw_colored_polygon(a, LabPaleti.KENAR)
	draw_circle(son, 3.0, LabPaleti.METAL)


## Asansörün alt (dinlenme) konumunda, yüzeyin üstüne ince amber-siyah şerit: "burada asansör var".
func _asansor_isaret() -> void:
	var p: Node = get_parent()
	var yarim := Vector2(60, 10)
	if alan.size != Vector2.ZERO:
		yarim = alan.size / 2.0
	var y: float = p.alt_y - p.position.y - yarim.y
	var x := -yarim.x + 2.0
	while x < yarim.x - 6.0:
		draw_rect(Rect2(x, y, 6.0, 3.0), LabPaleti.AMBER)
		draw_rect(Rect2(x + 6.0, y, 6.0, 3.0), LabPaleti.KENAR)
		x += 12.0
