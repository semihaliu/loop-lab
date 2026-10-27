extends Control
## Editöre özgü çizimler (ızgara, ekran sınırı, başlangıç/çıkış işaretleri, seçim çerçevesi,
## tutamaçlar, blok hayaleti, imleç). Oyun sahnesine girmez; önizleme düğümlerinin ÜSTÜNDE durur
## ve fareyi yutmaz. Veriyi `ed` (editor.gd) üzerinden OKUR, hiçbir şey yazmaz.

var ed: Control   # editor.gd kökü


func _draw() -> void:
	if ed == null or LabPaleti.ekransiz():
		return
	var ekran := Rect2(0, 0, 1152, 648)
	# Izgara çizgileri
	if ed.izgara_acik:
		var adim := float(ed.izgara_adimi(Input.is_key_pressed(KEY_SHIFT)))
		var renk := Color(LabPaleti.CAMGOBEGI, 0.07)
		var x := adim
		while x < ekran.size.x:
			draw_line(Vector2(x, 0), Vector2(x, ekran.size.y), renk, 1.0)
			x += adim
		var y := adim
		while y < ekran.size.y:
			draw_line(Vector2(0, y), Vector2(ekran.size.x, y), renk, 1.0)
			y += adim
	# Ekran sınırı
	draw_rect(ekran, Color(LabPaleti.AMBER, 0.55), false, 2.0)
	_kablolari_ciz()
	# Başlangıç ve çıkış işaretleri (ayak noktası + kutu)
	var b := ed.baslangic_dikdortgeni() as Rect2
	draw_rect(b, Color(LabPaleti.KLON, 0.22), true)
	draw_rect(b, LabPaleti.KLON, false, 2.0)
	_yazi("Başlangıç", b.position + Vector2(-14, -6), LabPaleti.KLON)
	var c := ed.cikis_dikdortgeni() as Rect2
	draw_rect(c, Color(LabPaleti.YESIL, 0.22), true)
	draw_rect(c, LabPaleti.YESIL, false, 2.0)
	_yazi("Çıkış", c.position + Vector2(-4, -6), LabPaleti.YESIL)
	# Seçim çerçevesi ve tutamaçlar
	if ed.secili != "":
		var r := ed.secim_dikdortgeni(ed.secili) as Rect2
		if r.size != Vector2.ZERO:
			draw_rect(r.grow(1.0), LabPaleti.AMBER, false, 2.0)
			if ed.tutamaclar_var(ed.secili):
				for h in ed.tutamac_noktalari(r):
					draw_rect(Rect2(h - Vector2(4, 4), Vector2(8, 8)), LabPaleti.AMBER, true)
					draw_rect(Rect2(h - Vector2(4, 4), Vector2(8, 8)), LabPaleti.KENAR, false, 1.0)
	_secili_hayaletleri_ciz()
	# Bağla aracı: kaynaktan imlece lastik çizgi
	if ed.arac == "bagla" and ed.bagla_kaynak != "" and ed.imlec_var:
		var kr := ed.secim_dikdortgeni(ed.bagla_kaynak) as Rect2
		if kr.size != Vector2.ZERO:
			draw_dashed_line(kr.get_center(), ed.imlec, LabPaleti.ONLUK, 2.0, 6.0)
			draw_circle(kr.get_center(), 5.0, LabPaleti.ONLUK)
	# Yerleştirme hayaleti (plaka / geçit / asansör)
	if ed.imlec_var and ed.yerlesen_turler.has(ed.arac):
		var hr := BolumDenetci.nesne_dikdortgeni({"tur": ed.arac, "konum": [ed.imlec.x, ed.imlec.y]})
		draw_rect(hr, Color(LabPaleti.CAMGOBEGI, 0.25), true)
		draw_rect(hr, LabPaleti.CAMGOBEGI, false, 2.0)
	# Blok hayaleti (sürüklerken)
	if ed.hayalet_var:
		draw_rect(ed.hayalet, Color(LabPaleti.CAMGOBEGI, 0.25), true)
		draw_rect(ed.hayalet, LabPaleti.CAMGOBEGI, false, 2.0)
	# İmleç (araç ızgara noktasına oturur)
	if ed.imlec_var and ed.arac != "sec":
		var p := ed.imlec as Vector2
		draw_line(p - Vector2(8, 0), p + Vector2(8, 0), LabPaleti.AMBER, 1.0)
		draw_line(p - Vector2(0, 8), p + Vector2(0, 8), LabPaleti.AMBER, 1.0)


func _yazi(metin: String, konum: Vector2, renk: Color) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, konum, metin, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, renk)


## Bütün bağlantıların kabloları: görünür kablo ince çizgi (oyundaki çizimin altında/üstünde
## yön verir), gizli kablo kesik çizgi; ara noktalar halka, seçili kablo parlak.
func _kablolari_ciz() -> void:
	for b in BaglantiIslemleri.baglantilar(ed.veri):
		var yol := ed.kablo_yolu(b["hedef"], b["tetik"]) as PackedVector2Array
		if yol.size() < 2:
			continue
		var gizli := BaglantiIslemleri.gizli_mi(ed.veri, b["hedef"], b["tetik"])
		var secili: bool = ed.secili_kablo.size() == 2 and ed.secili_kablo[0] == b["hedef"] and ed.secili_kablo[1] == b["tetik"]
		var renk: Color = LabPaleti.ONLUK if secili else (Color(LabPaleti.METAL, 0.7) if gizli else Color(LabPaleti.CAMGOBEGI, 0.55))
		for i in yol.size() - 1:
			if gizli:
				draw_dashed_line(yol[i], yol[i + 1], renk, 1.5, 5.0)
			else:
				draw_line(yol[i], yol[i + 1], renk, 2.5 if secili else 1.5)
		for i in range(1, yol.size() - 1):
			draw_circle(yol[i], 4.5 if secili else 3.0, LabPaleti.KENAR)
			draw_circle(yol[i], 2.5 if secili else 1.5, renk)


## Seçili geçit/asansörün açık/üst konum hayaleti (kesik çizgi) ve parametre tutamağı.
func _secili_hayaletleri_ciz() -> void:
	if ed.secili == "":
		return
	var n: Dictionary = ed._nesne(ed.secili)
	var tur := str(n.get("tur", ""))
	if tur != "gecit" and tur != "asansor" and tur != "lazer":
		return
	var t := ed.parametre_tutamaci(ed.secili) as Vector2
	if t == Vector2.INF:
		return
	if tur == "lazer":
		# Işın ucu tutamağı (hayalet yok: ışın zaten çizili).
		draw_rect(Rect2(t - Vector2(4, 4), Vector2(8, 8)), LabPaleti.AMBER, true)
		draw_rect(Rect2(t - Vector2(4, 4), Vector2(8, 8)), LabPaleti.KENAR, false, 1.0)
		return
	var r := ed.secim_dikdortgeni(ed.secili) as Rect2
	var fark := t - Vector2(float(n["konum"][0]), float(n["konum"][1]))
	var acik := Rect2(r.position + fark, r.size)
	draw_rect(acik, Color(LabPaleti.CAMGOBEGI, 0.12), true)
	var kose := [acik.position, Vector2(acik.end.x, acik.position.y), acik.end, Vector2(acik.position.x, acik.end.y), acik.position]
	for i in 4:
		draw_dashed_line(kose[i], kose[i + 1], LabPaleti.CAMGOBEGI, 1.5, 5.0)
	draw_rect(Rect2(t - Vector2(4, 4), Vector2(8, 8)), LabPaleti.AMBER, true)
	draw_rect(Rect2(t - Vector2(4, 4), Vector2(8, 8)), LabPaleti.KENAR, false, 1.0)
