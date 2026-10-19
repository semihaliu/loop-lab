class_name Gorunum
extends Node2D
## Dünya nesnelerinin ortak görünümü (yalnızca çizim). Bir nesnenin çocuğu olarak eklenir,
## durumu üst düğümden OKUR (basılı mı, açık mı...) ve hiçbir şeyi değiştirmez.
## Çarpışma, konum ve mantığa dokunmaz. Rastgelelik yok; animasyon fizik karesinden türer.
## Katman: asansör/geçit z_index = -1 çizilir, böylece zemin/kat içine gömülürken örtülür.

enum Tur { DUVAR, TEK_YONLU, PLAKA, ASANSOR, KAPI, GECIT, SALTER, LAZER, ASANSOR_ISARET, BANT, ASKI, KUTU, ZIPLATICI, PLAKA_ZAMANLI, PLAKA_MANDAL }

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
	if (t == Tur.PLAKA or t == Tur.PLAKA_ZAMANLI or t == Tur.PLAKA_MANDAL) and (ust.has_meta("aski_tavan_y") or ust.has_meta("aski_duvar_x")):
		# Havada duran plaka: tavana ve/veya duvara görsel askı (plakanın arkasında, z -1).
		var k := Gorunum.new()
		k.name = "GorunumAski"
		k.tur = Tur.ASKI
		k.z_index = -1
		ust.add_child(k)
	return g


## Üst düğümün ilk CollisionShape2D'sinin dikdörtgenini yerel koordinatta verir.
static func sekil_alani(ust: Node) -> Rect2:
	for c in ust.get_children():
		if c is CollisionShape2D and c.shape is RectangleShape2D:
			var b: Vector2 = c.shape.size
			return Rect2(c.position - b / 2.0, b)
	return Rect2(-10, -10, 20, 20)


## Taşıma bandı kayan desen fazı (yalnızca görsel; oyun mantığına karışmaz).
var _bant_faz := 0.0
## Yaylı zıplatıcı sıkışma animasyonu: fırlatmanın görüldüğü fizik karesi (-1 = yok).
## Yalnızca görsel zamanlayıcı; gövdelerin velocity değeri OKUNUR, yazılmaz.
var _sik_kare := -1
const SIK_SURE := 16


func _process(delta: float) -> void:
	if LabPaleti.ekransiz():
		return
	if tur == Tur.BANT:
		var p: Node = get_parent()
		_bant_faz += float(p.yon) * float(p.hiz) * delta
	elif tur == Tur.ZIPLATICI:
		var pz: Area2D = get_parent() as Area2D
		var hiz: float = float(pz.get("firlatma_hizi"))
		for g in pz.get_overlapping_bodies():
			var v = g.get("velocity")
			if v != null and v.y <= -hiz * 0.9 and _sik_kare < 0:
				_sik_kare = _faz()
		if _sik_kare >= 0 and _faz() - _sik_kare > SIK_SURE:
			_sik_kare = -1
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
		Tur.BANT: _bant()
		Tur.ASKI: _aski()
		Tur.KUTU: _kutu()
		Tur.ZIPLATICI: _ziplatici()
		Tur.PLAKA_ZAMANLI:
			_plaka()
			_plaka_sayac()
		Tur.PLAKA_MANDAL:
			_plaka()
			_plaka_mandal()


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
	var sr := Gorunum.sekil_alani(get_parent())
	if sr.size.y > 20.0:
		_plaka_kalin(sr, basili)
		return
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


## Yüksek (örn. 60x32) plaka: şeklin tamamını kaplayan kalın blok, üstünde basınç yüzeyi.
func _plaka_kalin(r: Rect2, basili: bool) -> void:
	var renk := LabPaleti.CAMGOBEGI if basili else LabPaleti.AMBER
	_cerceve(r, LabPaleti.PASLI)
	var ic := r.grow(-2.0)
	var ust := 3.0 if basili else 0.0
	draw_rect(Rect2(ic.position.x, ic.position.y + ust, ic.size.x, 7.0), LabPaleti.KENAR)
	draw_rect(Rect2(ic.position.x + 1.0, ic.position.y + ust + 1.0, ic.size.x - 2.0, 5.0), renk.darkened(0.15))
	if not basili:
		var x := ic.position.x + 4.0
		while x < ic.end.x - 8.0:
			draw_line(Vector2(x, ic.position.y + 6.0), Vector2(x + 6.0, ic.position.y + 1.0), LabPaleti.KENAR, 2.0)
			x += 11.0
	draw_rect(Rect2(ic.position.x, ic.position.y + 10.0, ic.size.x, ic.size.y - 10.0), LabPaleti.PANEL)
	draw_rect(Rect2(ic.position.x, ic.end.y - 4.0, ic.size.x, 4.0), Color(0, 0, 0, 0.3))
	_percin(Vector2(ic.position.x + 6.0, ic.end.y - 7.0), LabPaleti.METAL)
	_percin(Vector2(ic.end.x - 6.0, ic.end.y - 7.0), LabPaleti.METAL)
	var c := Vector2(r.get_center().x, r.position.y + 20.0)
	if basili:
		draw_circle(c, 8.0, Color(LabPaleti.YESIL, 0.18))
	draw_circle(c, 3.0, LabPaleti.YESIL if basili else LabPaleti.UYARI_KOYU)


## Zamanlı plaka: plakanın üstünde azalan şerit (kalan kare / tutma_kare) ve iki yanda
## sayaç tik işaretleri. Yalnızca görsel; kalan süreyi üst düğümden okur.
func _plaka_sayac() -> void:
	var p: Node = get_parent()
	var sr := Gorunum.sekil_alani(p)
	var toplam := maxi(int(p.tutma_kare), 1)
	var oran := clampf(float(int(p.kalan_kare)) / float(toplam), 0.0, 1.0)
	var etkin: bool = p.basili_mi()
	var w := 40.0
	var y := sr.position.y - 14.0
	draw_rect(Rect2(-w / 2.0 - 1.0, y - 1.0, w + 2.0, 6.0), LabPaleti.KENAR)
	draw_rect(Rect2(-w / 2.0, y, w, 4.0), LabPaleti.PANEL)
	if oran > 0.0:
		var renk := LabPaleti.CAMGOBEGI if oran > 0.34 else LabPaleti.UYARI
		draw_rect(Rect2(-w / 2.0, y, w * oran, 4.0), renk)
	elif etkin:
		draw_rect(Rect2(-w / 2.0, y, w, 4.0), LabPaleti.CAMGOBEGI)
	for i in range(5):
		draw_line(Vector2(-w / 2.0 + i * w / 4.0, y + 5.0), Vector2(-w / 2.0 + i * w / 4.0, y + 8.0), LabPaleti.METAL, 1.0)


## Mandal plaka: üstte asma kilit. Basılana dek kilit açık (kanca kalkık, soluk),
## basılınca kalıcı kapalı ve yeşil yanar. Yalnızca görsel.
func _plaka_mandal() -> void:
	var p: Node = get_parent()
	var sr := Gorunum.sekil_alani(p)
	var kilitli: bool = p.kilitli
	var c := Vector2(0, sr.position.y - 14.0)
	var renk := LabPaleti.YESIL if kilitli else LabPaleti.UYARI
	if kilitli:
		draw_circle(c, 11.0, Color(LabPaleti.YESIL, 0.2))
	# Kanca (yay): kilitliyken gövdeye oturur, değilken yana kalkık
	var kc := c + Vector2(0, -3.0 if kilitli else -6.0)
	draw_arc(kc, 4.0, PI, TAU, 10, LabPaleti.KENAR, 4.0)
	draw_arc(kc, 4.0, PI, TAU, 10, LabPaleti.METAL_ACIK, 2.0)
	# Gövde
	draw_rect(Rect2(c.x - 7.0, c.y - 3.0, 14.0, 10.0), LabPaleti.KENAR)
	draw_rect(Rect2(c.x - 6.0, c.y - 2.0, 12.0, 8.0), LabPaleti.METAL if kilitli else LabPaleti.PASLI)
	draw_circle(c + Vector2(0, 2.0), 2.0, renk)


# ---------- taşıma bandı ----------

## Bant: koyu kemer üstünde parlak amber yön okları sürekli akar, uçlarda makaralar döner.
## Yön ve hız üst düğümün `yon`/`hiz` değerinden okunur (ters bant = ters akış). Yalnızca
## görsel zaman (_process); fizik karesine ve oyun mantığına karışmaz.
func _bant() -> void:
	var p: Node = get_parent()
	var r := alan
	var yon_i: int = signi(int(p.yon))
	var rad := r.size.y / 2.0
	var cy := r.get_center().y
	var x0 := r.position.x + rad
	var x1 := r.end.x - rad
	# Dış hat (koyu) ve çevre zeminden ayıran parlak amber üst kenar şeridi
	draw_rect(r, LabPaleti.KENAR)
	var kemer := Rect2(x0, r.position.y + 2.0, x1 - x0, r.size.y - 4.0)
	draw_rect(kemer, LabPaleti.BANT_ZEMIN)
	draw_rect(Rect2(x0, r.position.y, x1 - x0, 2.0), LabPaleti.BANT_OK)
	draw_rect(Rect2(x0, r.end.y - 2.0, x1 - x0, 2.0), LabPaleti.BANT_OK.darkened(0.45))
	# Akan oklar (aralık 20 px). Faz = yon * hiz * zaman: ok ucu hep bandın yönüne bakar.
	var ara := 20.0
	var x := x0 - ara + fposmod(_bant_faz, ara)
	while x < x1 + ara:
		var a := float(yon_i) * 4.0
		var k := rad * 0.5
		var nokta := [
			[Vector2(x - a, cy - k), Vector2(x + a, cy)],
			[Vector2(x + a, cy), Vector2(x - a, cy + k)],
		]
		for ln in nokta:
			# Kemer dışına taşan oklar kırpılır (yalnızca kemer içindeki kısım çizilir)
			var u0: Vector2 = ln[0]
			var u1: Vector2 = ln[1]
			if u0.x > x0 + 1.0 and u0.x < x1 - 1.0 and u1.x > x0 + 1.0 and u1.x < x1 - 1.0:
				draw_line(u0, u1, LabPaleti.BANT_OK, 3.0)
		# Oklar arasında akan koyu oluk (hareket hissini güçlendirir)
		var g := x + ara * 0.5
		if g > x0 + 1.0 and g < x1 - 1.0:
			draw_line(Vector2(g, r.position.y + 3.0), Vector2(g, r.end.y - 3.0), LabPaleti.BANT_OLUK, 2.0)
		x += ara
	# Uç makaraları: üst yüzey bant yönünde ilerleyecek şekilde döner (faz / yarıçap)
	var ac := _bant_faz / rad
	for cx in [r.position.x + rad, r.end.x - rad]:
		var c := Vector2(cx, cy)
		draw_circle(c, rad, LabPaleti.KENAR)
		draw_circle(c, rad - 1.5, LabPaleti.METAL_ACIK)
		for i in range(4):
			var t := ac + i * TAU / 4.0
			draw_line(c, c + Vector2(cos(t), sin(t)) * (rad - 2.5), LabPaleti.KENAR, 2.0)
		draw_circle(c, 3.0, LabPaleti.BANT_OK)
		draw_circle(c, 1.2, LabPaleti.KENAR)


# ---------- plaka askısı ----------

## Havada duran plakayı tavana (meta aski_tavan_y, dünya y) ve/veya duvara (meta aski_duvar_x,
## dünya x) bağlayan kol/halat. Yalnızca görsel; plakanın arkasında çizilir.
func _aski() -> void:
	var p: Node2D = get_parent()
	var sr := Gorunum.sekil_alani(p)
	var gp := p.global_position
	if p.has_meta("aski_tavan_y"):
		var ty: float = float(p.get_meta("aski_tavan_y")) - gp.y
		for sx in [sr.position.x + 8.0, sr.end.x - 8.0]:
			draw_line(Vector2(sx, sr.position.y), Vector2(sx, ty), LabPaleti.KENAR, 5.0)
			draw_line(Vector2(sx, sr.position.y), Vector2(sx, ty), LabPaleti.METAL, 3.0)
			draw_line(Vector2(sx - 0.8, sr.position.y), Vector2(sx - 0.8, ty), Color(1, 1, 1, 0.15), 1.0)
			draw_rect(Rect2(sx - 7.0, ty, 14.0, 5.0), LabPaleti.KENAR)
			draw_rect(Rect2(sx - 6.0, ty, 12.0, 3.0), LabPaleti.METAL_ACIK)
			var y := ty + 22.0
			while y < sr.position.y - 6.0:
				draw_rect(Rect2(sx - 4.0, y, 8.0, 3.0), LabPaleti.PASLI)
				y += 26.0
	if p.has_meta("aski_duvar_x"):
		var dx: float = float(p.get_meta("aski_duvar_x")) - gp.x
		var yon_d := signf(dx)
		var bas := sr.end.x if yon_d > 0.0 else sr.position.x
		var ay := sr.position.y + sr.size.y * 0.5
		var kol := Rect2(minf(bas, dx), ay - 5.0, absf(dx - bas), 10.0)
		_cerceve(kol, LabPaleti.METAL, LabPaleti.KENAR, 2.0)
		draw_rect(Rect2(kol.position.x + 2.0, kol.position.y + 2.0, kol.size.x - 4.0, 2.0), LabPaleti.METAL_ACIK)
		var mx := dx - 5.0 if yon_d > 0.0 else dx - 1.0
		draw_rect(Rect2(mx, ay - 12.0, 6.0, 24.0), LabPaleti.KENAR)
		_percin(Vector2(mx + 3.0, ay - 7.0), LabPaleti.METAL)
		_percin(Vector2(mx + 3.0, ay + 7.0), LabPaleti.METAL)


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
	_kablo(p)
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


# ---------- plaka kablosu (isteğe bağlı) ----------

## Plaka ile bağlı geçit/lazer arasında ince "kablo" (yalnızca görünüm, çarpışma/fizik yok).
## Üst düğümde `kablo` meta'sı (dünya koordinatlı PackedVector2Array çoklu çizgi) varsa
## çizilir; meta yoksa hiçbir şey çizilmez (eski bölümler değişmez). Tetikleyici plakalardan
## biri etkinse kablo yanar (camgöbeği), değilse soluk metal. Yalnızca okur.
func _kablo(p: Node) -> void:
	# İkinci kablo (`kablo_2`) varsa her kablo kendi tetikleyicisiyle yanar: kablo -> 1., kablo_2 -> 2.
	var iki := p.has_meta("kablo_2")
	_kablo_ciz(p, "kablo", 0 if iki else -1)
	if iki:
		_kablo_ciz(p, "kablo_2", 1)


## Tek kablo çizimi. sira < 0: tetikleyicilerden herhangi biri etkinse yanar; sira >= 0: yalnız o sıradaki.
func _kablo_ciz(p: Node, meta: String, sira: int) -> void:
	if not p.has_meta(meta):
		return
	var nokta: PackedVector2Array = p.get_meta(meta)
	if nokta.size() < 2:
		return
	var yerel := PackedVector2Array()
	for w in nokta:
		yerel.append(to_local(w))
	var yanik := false
	var yollar = p.get("tetikleyici_yollari")
	if yollar != null:
		for i in yollar.size():
			if sira >= 0 and i != sira:
				continue
			var t: Node = p.get_node_or_null(yollar[i])
			if t != null and t.has_method("basili_mi") and t.basili_mi():
				yanik = true
	draw_polyline(yerel, LabPaleti.KENAR, 5.0)
	draw_polyline(yerel, LabPaleti.CAMGOBEGI if yanik else LabPaleti.METAL, 3.0)
	if yanik:
		draw_polyline(yerel, Color(1, 1, 1, 0.35), 1.0)
	for u in [yerel[0], yerel[yerel.size() - 1]]:
		draw_circle(u, 3.5, LabPaleti.KENAR)
		draw_circle(u, 2.0, LabPaleti.YESIL if yanik else LabPaleti.METAL_ACIK)


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
	_kablo(p)
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


# ---------- kutu ----------

## Metal takviyeli ahşap kasa: köşe plakaları, iç panel, çapraz bağ, perçinler.
## Boyut gerçek çarpışma şeklinden (alan) gelir; sabit tasarım, durum okumaz.
func _kutu() -> void:
	var r := alan
	var k := clampf(minf(r.size.x, r.size.y) * 0.22, 5.0, 10.0)
	_cerceve(r, LabPaleti.PASLI, LabPaleti.KENAR, 2.0)
	var ic := r.grow(-2.0)
	# Üst ışık, alt gölge (ahşap tahta hissi)
	draw_rect(Rect2(ic.position, Vector2(ic.size.x, 2.0)), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(ic.position.x, ic.end.y - 3.0, ic.size.x, 3.0), Color(0, 0, 0, 0.3))
	# İç panel (hafif koyu) ve çapraz bağ
	var pn := ic.grow(-k)
	draw_rect(pn, LabPaleti.PASLI.darkened(0.25))
	draw_line(pn.position, pn.end, LabPaleti.KENAR, 4.0)
	draw_line(pn.position + Vector2(0, pn.size.y), pn.position + Vector2(pn.size.x, 0), LabPaleti.KENAR, 4.0)
	draw_line(pn.position, pn.end, LabPaleti.PAS, 2.0)
	draw_line(pn.position + Vector2(0, pn.size.y), pn.position + Vector2(pn.size.x, 0), LabPaleti.PAS, 2.0)
	# İnce panel kenar çizgisi
	draw_rect(pn, Color(LabPaleti.KENAR, 0.9), false, 1.5)
	# Köşe metal takviyeleri
	for cx in [0, 1]:
		for cy in [0, 1]:
			var x0 := ic.position.x if cx == 0 else ic.end.x - k
			var y0 := ic.position.y if cy == 0 else ic.end.y - k
			draw_rect(Rect2(x0, y0, k, k), LabPaleti.KENAR)
			draw_rect(Rect2(x0 + 1.0, y0 + 1.0, k - 2.0, k - 2.0), LabPaleti.METAL)
			_percin(Vector2(x0 + k * 0.5, y0 + k * 0.5), LabPaleti.METAL_ACIK)
	# Üst kenar vurgusu: kutu zemin/duvardan ayrışsın
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 1.0), Color(LabPaleti.METAL_ACIK, 0.6))


# ---------- yaylı zıplatıcı ----------

## Alt taban, bobin yay, üst ped; fırlatınca kısa sıkışıp geri uzar. Üstte soluk yukarı oklar
## etkin alanı gösterir. Sıkışma yalnızca görsel zamanlayıcıdan türer.
func _ziplatici() -> void:
	var r := alan
	var sik := 0.0  # 0..1 sıkışma oranı
	if _sik_kare >= 0:
		var t := float(_faz() - _sik_kare) / float(SIK_SURE)
		# Hızlı sıkış (ilk %25), sonra yavaş geri uzama
		sik = t / 0.25 if t < 0.25 else 1.0 - (t - 0.25) / 0.75
		sik = clampf(sik, 0.0, 1.0)
	var taban_y := r.end.y
	var tab_h := 3.0
	var yay_ust := r.position.y + 4.0 + sik * (r.size.y * 0.35)  # ped üst yüzeyi
	var cx := r.get_center().x
	# Etkin alan işareti: pedin üstünde soluk, yavaşça akan oklar
	var yarim_g := r.size.x * 0.5 - 6.0
	var akis := fposmod(float(_faz()) * 0.35, 18.0)
	for i in range(2):
		var oy := yay_ust - 6.0 - fposmod(akis + i * 9.0, 18.0)
		var a := 0.35 * (1.0 - fposmod(akis + i * 9.0, 18.0) / 18.0)
		for ox in [-yarim_g * 0.5, yarim_g * 0.5]:
			var p := Vector2(cx + ox, oy)
			draw_line(p + Vector2(-5, 3), p, Color(LabPaleti.CAMGOBEGI, a), 2.0)
			draw_line(p, p + Vector2(5, 3), Color(LabPaleti.CAMGOBEGI, a), 2.0)
	# Taban plakası
	draw_rect(Rect2(r.position.x, taban_y - tab_h, r.size.x, tab_h), LabPaleti.KENAR)
	draw_rect(Rect2(r.position.x + 1.0, taban_y - tab_h + 1.0, r.size.x - 2.0, tab_h - 1.0), LabPaleti.PASLI)
	# Yay (bobin): iki yan destek + zigzag
	var yay_alt := taban_y - tab_h
	var ped_alt := yay_ust + 4.0
	var gen := r.size.x * 0.28
	var n := 4
	var pts := PackedVector2Array()
	for i in range(n * 2 + 1):
		var f := float(i) / float(n * 2)
		var y := lerpf(yay_alt, ped_alt, f)
		var x := cx + (gen if i % 2 == 1 else -gen) if i > 0 and i < n * 2 else cx
		pts.append(Vector2(x, y))
	draw_polyline(pts, LabPaleti.KENAR, 4.0)
	draw_polyline(pts, LabPaleti.METAL_ACIK, 2.0)
	for sx in [-r.size.x * 0.4, r.size.x * 0.4]:
		draw_line(Vector2(cx + sx, yay_alt), Vector2(cx + sx, ped_alt), Color(LabPaleti.METAL, 0.6), 2.0)
	# Üst ped: yeşil, parlak ince kenar (yaylı yüzey)
	var ped := Rect2(r.position.x, yay_ust, r.size.x, 4.0)
	draw_rect(ped, LabPaleti.KENAR)
	draw_rect(Rect2(ped.position.x + 1.0, ped.position.y + 1.0, ped.size.x - 2.0, 2.0), LabPaleti.YESIL.darkened(0.2))
	draw_rect(Rect2(ped.position.x + 1.0, ped.position.y, ped.size.x - 2.0, 1.0), Color(LabPaleti.YESIL, 0.9))
	if sik > 0.0:
		draw_circle(Vector2(cx, yay_ust), 10.0 + sik * 4.0, Color(LabPaleti.YESIL, 0.15 * sik))
