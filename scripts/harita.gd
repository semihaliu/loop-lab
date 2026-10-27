extends Control
## İlerleme haritası: bölümler altıgen düğüm olarak yerleşir, bağlı düğümler çizgiyle birleşir.
## Kilit yok; her düğüme basılabilir. Konumlar ve bağlantılar BolumListesi.liste()'nden (resmî + canlı bölümler) gelir,
## yeni bölüm eklemek bu betiği değiştirmez. Görseller koddan çizilir.
##
## Çizim sırası (alttan üste): Arkaplan, Baglantilar (Line2D), Dugumler, başlık, Geri.
## Not: bağlantılar eskiden bu kökün `_draw`'ında çiziliyordu; kökün çizimi çocuk
## düğümlerin ALTINDA kaldığından arka plan çizgiyi örtüyordu.

const MENU_SAHNESI := "res://scenes/ana_menu.tscn"
## Bağlantı çizgisi düğümün kenarından başlar (altıgen yarıçapı).
const HEX_YARICAP := HaritaDugumu.YARICAP
const BASLANGIC_RENGI := LabPaleti.AMBER
const NORMAL_RENK := LabPaleti.CAM_SOLUK
const CIZGI_DIS := Color(0.03, 0.05, 0.06, 0.95)
const CIZGI_IC := Color(0.42, 0.62, 0.62)  # boru gibi soluk metal

## [başlangıç konumu, bitiş konumu] çiftleri (veri).
var baglantilar: Array = []

@onready var cizgiler: Node2D = $Baglantilar
@onready var dugumler: Control = $Dugumler
@onready var geri_dugmesi: Button = $GeriDugmesi


func _ready() -> void:
	baglantilar = BolumListesi.baglantilar()
	for i in range(baglantilar.size()):
		_cizgi_olustur(i, baglantilar[i][0], baglantilar[i][1])
	var kayitlar := BolumListesi.liste()
	for i in range(kayitlar.size()):
		_dugum_olustur(i, kayitlar[i])
	_geri_dugmesini_hazirla()


## Kenardan kenara iki katmanlı çizgi: koyu dış + açık iç, yuvarlak uçlu.
func _cizgi_olustur(i: int, a: Vector2, b: Vector2) -> void:
	var yon := (b - a).normalized()
	var bas := a + yon * HEX_YARICAP
	var son := b - yon * HEX_YARICAP
	for katman in [["Dis", 12.0, CIZGI_DIS], ["Ic", 7.0, CIZGI_IC]]:
		var cizgi := Line2D.new()
		cizgi.name = "Cizgi%d_%s" % [i + 1, katman[0]]
		cizgi.width = katman[1]
		cizgi.default_color = katman[2]
		cizgi.begin_cap_mode = Line2D.LINE_CAP_ROUND
		cizgi.end_cap_mode = Line2D.LINE_CAP_ROUND
		cizgi.antialiased = true
		cizgi.points = PackedVector2Array([bas, son])
		cizgiler.add_child(cizgi)


func _dugum_olustur(i: int, kayit: Dictionary) -> void:
	var konum: Vector2 = kayit["konum"]
	var baslangic: bool = kayit["onceki"] == ""
	var dugme := HaritaDugumu.new()
	dugme.name = "Dugum%d" % (i + 1)
	dugme.kur(i + 1, BASLANGIC_RENGI if baslangic else NORMAL_RENK)
	dugme.canli = str(kayit.get("kaynak", "resmi")) == "canli"
	dugme.position = konum - dugme.size / 2.0
	dugumler.add_child(dugme)

	var etiket := Label.new()
	etiket.name = "Etiket%d" % (i + 1)
	var ad: String = str(kayit.get("ad", ""))
	etiket.text = "Bölüm %d" % (i + 1) if ad == "" else "Bölüm %d: %s" % [i + 1, ad]
	if dugme.canli:
		etiket.text += " · Canlı"
	etiket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiket.add_theme_font_size_override("font_size", 22)
	# Resmî etiketler eskisi gibi sabit 280 px. Yalnız canlı bölüm etiketi (uzun kullanıcı adı) genişler ve ekrana
	# kenetlenir; ölçüm ağaçtan bağımsız yazı tipiyle yapılır (ağaca eklenmemiş Label tema önbelleği 16 px sayar).
	var etiket_genislik := 280.0
	if dugme.canli:
		var yazi_olcusu := etiket.get_theme_default_font().get_string_size(etiket.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		etiket_genislik = clampf(yazi_olcusu + 24.0, 280.0, 1144.0)
	etiket.size = Vector2(etiket_genislik, 30)
	etiket.position = konum + Vector2(-etiket_genislik / 2.0, HEX_YARICAP + 14.0)
	etiket.position.x = clampf(etiket.position.x, 4.0, 1152.0 - etiket_genislik - 4.0)
	etiket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiket.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	etiket.add_theme_constant_override("outline_size", 6)
	etiket.visible = false
	dugumler.add_child(etiket)

	dugme.mouse_entered.connect(func() -> void: etiket.visible = true)
	dugme.mouse_exited.connect(func() -> void: etiket.visible = false)
	dugme.pressed.connect(_bolume_gir.bind(kayit["yol"]))


func _geri_dugmesini_hazirla() -> void:
	geri_dugmesi.focus_mode = Control.FOCUS_NONE
	geri_dugmesi.text = "<  Geri"
	geri_dugmesi.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	geri_dugmesi.add_theme_font_size_override("font_size", 22)
	geri_dugmesi.add_theme_stylebox_override("normal", _geri_stili(LabPaleti.PANEL, LabPaleti.CAM_SOLUK))
	geri_dugmesi.add_theme_stylebox_override("hover", _geri_stili(LabPaleti.PANEL_ACIK, LabPaleti.CAMGOBEGI))
	geri_dugmesi.add_theme_stylebox_override("pressed", _geri_stili(LabPaleti.DUVAR, LabPaleti.AMBER))
	geri_dugmesi.pressed.connect(_on_geri)


func _geri_stili(dolgu: Color, kenar: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = dolgu
	s.border_color = kenar
	s.set_border_width_all(2)
	s.set_corner_radius_all(10)
	return s


## Seçilen bölüme temiz klon listesiyle girer.
func _bolume_gir(yol: String) -> void:
	Kayitlar.sifirla()
	get_tree().change_scene_to_file(yol)


func _on_geri() -> void:
	get_tree().change_scene_to_file(MENU_SAHNESI)
