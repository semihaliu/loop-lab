extends Control
## Bölüm editörü iskeleti (A5): 1152x648 piksel piksel oyunla aynı tuval (ölçeklenmez), üstte
## 36 px çubuk, solda gizlenebilen palet, altta 32 px durum çubuğu. Veri her zaman tek bir
## `BolumVerisi` sözlüğüdür (`veri`); tuvaldeki nesneler `BolumKurucu.nesne_kur` ile kurulan
## gerçek düğümlerdir ve `Onizleme` altında PROCESS_MODE_DISABLED durur (taslak §3).
## Fare/klavye işleyicileri aşağıdaki herkese açık API'yi çağırır; API `veri`yi değiştirir,
## geri al kaydı atar ve önizlemeyi günceller. Dene (A6) durumu `EditorOturumu`'na yazıp geçici
## sahneyi açar; dönüşte durum geri yüklenir. Doğrula, bağlantı ve Bölümlerim sonraki aşamadır.

const ANA_MENU_SAHNESI := "res://scenes/ana_menu.tscn"
const ONAY_METNI := "Kaydedilmemiş değişiklikler silinecek. Devam edilsin mi?"
const KATMAN_BETIGI := preload("res://scripts/editor/editor_katmani.gd")

const EKRAN := Vector2(1152, 648)
const UST_YUKSEKLIK := 36.0
const DURUM_YUKSEKLIK := 32.0
const GECMIS_AZAMI := 100          # en çok bu kadar geri alma adımı
const IZGARA_ADIMI := 20
const IZGARA_ADIMI_SHIFT := 10
const EN_KUCUK_BOYUT := 10
const TUTAMAC_YARICAPI := 6.0
const BASLANGIC_ID := "@baslangic"   # seçim kimlikleri (geçerli bir nesne id'si olamaz)
const CIKIS_ID := "@cikis"

## Düzenlenen bölüm (BolumVerisi biçimi).
var veri: Dictionary = {}
## Dosya kökü; testler "user://test_editor/" yazar.
var kok: String = BolumYollari.VARSAYILAN_KOK
var secili: String = ""
var arac: String = "sec"           # "sec" | "blok" | "baslangic" | "cikis" | "bagla" | yerleşen tür adı
var bagla_kaynak: String = ""      # Bağla aracında seçilmiş tetikleyici
var secili_kablo: Array = []       # [hedef_id, tetik_id] ya da boş
## Tek tıkla yerleştirilen türler (blok sürüklenerek çizilir). Palet sırası.
var yerlesen_turler: Array = ["plaka", "zamanli_plaka", "mandal_plaka", "salter", "gecit", "asansor", "lazer", "kutu", "ziplatici", "bant", "tek_yonlu"]
var izgara_acik: bool = true
var kimlik_kilitli: bool = false   # ilk Kaydet'ten sonra kimlik değişmez
var kilit_kimlik: String = ""
var son_yol: String = ""

# Geri al / yinele
var gecmis: Array = []
var gecmis_i: int = -1

# Fare etkileşimi
var imlec: Vector2 = Vector2.ZERO
var imlec_var: bool = false
var hayalet: Rect2 = Rect2()
var hayalet_var: bool = false
var surukle: String = ""           # "" | "blok" | "tasi" | "boyut" | "kablo" | "parametre"
var _s_kablo_nokta: int = -1
var _s_kablo_bekle: bool = false   # kablo basıldı, sürükleme henüz veriyi değiştirmedi
var _s_bas: Vector2 = Vector2.ZERO
var _s_orijinal: Vector2 = Vector2.ZERO
var _s_alan0: Array = []
var _s_tutamac: int = -1
var _s_degisti: bool = false

# Önizleme
var dugumler: Dictionary = {}      # id -> kurulmuş düğüm
var durum_mesaji: String = ""

# Arayüz düğümleri
var tuval: Control
var onizleme: Node2D
var katman: Control
var ust_cubuk: PanelContainer
var palet: PanelContainer
var durum_cubugu: PanelContainer
var durum_etiketi: Label
var ad_alani: LineEdit
var klon_secici: OptionButton
var geri_dugmesi: Button
var yinele_dugmesi: Button
var izgara_kutusu: CheckBox
var ac_menusu: PopupMenu
var arac_dugmeleri: Dictionary = {}
var kablo_sifirla_dugmesi: Button
var kablo_gizle_dugmesi: Button
var ozellik_paneli: PanelContainer
var ozellik_baslik: Label
var ozellik_satirlari: Dictionary = {}   # alan -> {"satir": Control, "kontrol": Control}
var _ozellik_esitleniyor: bool = false
var _ac_yollari: Array = []
var onay_diyalogu: ConfirmationDialog
var _bekleyen: Callable = Callable()   # onay bekleyen işlem
var _temiz_goruntu: String = ""        # son Kaydet/Aç/Yeni anındaki içerik + çözüm + doğrulama metni


func _ready() -> void:
	theme = _tema_yap()
	_arayuz_kur()
	if EditorOturumu.donus:
		_oturumdan_yukle()
	else:
		# Dene'ye girilmeden açılan editör (menüden) hep boş başlar; eski oturum kalıntısı atılır.
		# Bölümlerim'den "Aç" ile gelindiyse o dosya yüklenir (kök de oradan gelir).
		var acilacak := EditorOturumu.ac_yolu
		var gelen_kok := EditorOturumu.kok
		EditorOturumu.temizle()
		if gelen_kok != "":
			kok = gelen_kok
		yeni()
		if acilacak != "":
			ac(acilacak)


# --- Arayüz kurulumu -------------------------------------------------------------------

func _tema_yap() -> Theme:
	var t := LabTema.olustur()
	for ad in ["normal", "hover", "pressed", "disabled", "focus"]:
		var s := t.get_stylebox(ad, "Button").duplicate() as StyleBoxFlat
		s.content_margin_left = 10.0
		s.content_margin_right = 10.0
		s.content_margin_top = 3.0
		s.content_margin_bottom = 3.0
		t.set_stylebox(ad, "Button", s)
	t.default_font_size = 14
	t.set_constant("shadow_offset_x", "Label", 0)
	t.set_constant("shadow_offset_y", "Label", 0)
	return t


func _panel_stili(alfa: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(LabPaleti.DUVAR, alfa)
	s.border_color = LabPaleti.CAM_SOLUK
	s.set_border_width_all(1)
	s.content_margin_left = 6.0
	s.content_margin_right = 6.0
	s.content_margin_top = 2.0
	s.content_margin_bottom = 2.0
	return s


func _dugme(ad: String, metin: String, kutu: Control) -> Button:
	var d := Button.new()
	d.name = ad
	d.text = metin
	d.focus_mode = Control.FOCUS_NONE   # ok tuşları/Del odak gezintisine gitmesin
	kutu.add_child(d)
	return d


func _arayuz_kur() -> void:
	# Tuval: tüm düzenleme burada olur; ölçeklenmez.
	tuval = Control.new()
	tuval.name = "Tuval"
	tuval.position = Vector2.ZERO
	tuval.size = EKRAN
	tuval.custom_minimum_size = EKRAN
	tuval.clip_contents = true
	tuval.mouse_filter = Control.MOUSE_FILTER_STOP
	tuval.gui_input.connect(_tuval_girdi)
	add_child(tuval)
	# Arka plan en altta çizilir: geçit/asansör görünümü z_index -1 kullanır, tuvalin kendi çizimi onları örtmesin.
	var zemin := Control.new()
	zemin.name = "Zemin"
	zemin.size = EKRAN
	zemin.z_index = -100
	zemin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zemin.draw.connect(func() -> void: _tuval_ciz(zemin))
	tuval.add_child(zemin)
	onizleme = Node2D.new()
	onizleme.name = "Onizleme"
	tuval.add_child(onizleme)
	katman = Control.new()
	katman.set_script(KATMAN_BETIGI)
	katman.name = "EditorKatmani"
	katman.set("ed", self)
	katman.position = Vector2.ZERO
	katman.size = EKRAN
	katman.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tuval.add_child(katman)

	# Üst çubuk
	ust_cubuk = PanelContainer.new()
	ust_cubuk.name = "UstCubuk"
	ust_cubuk.position = Vector2.ZERO
	ust_cubuk.custom_minimum_size = Vector2(EKRAN.x, UST_YUKSEKLIK)
	ust_cubuk.size = Vector2(EKRAN.x, UST_YUKSEKLIK)
	ust_cubuk.add_theme_stylebox_override("panel", _panel_stili(0.9))
	add_child(ust_cubuk)
	var kutu := HBoxContainer.new()
	kutu.name = "Kutu"
	kutu.add_theme_constant_override("separation", 6)
	ust_cubuk.add_child(kutu)
	_dugme("YeniDugmesi", "Yeni", kutu).pressed.connect(yeni_iste)
	_dugme("KaydetDugmesi", "Kaydet", kutu).pressed.connect(_on_kaydet)
	_dugme("AcDugmesi", "Aç", kutu).pressed.connect(_on_ac)
	_dugme("BolumlerimDugmesi", "Bölümlerim", kutu).pressed.connect(bolumlerim_iste)
	var ad_etiketi := Label.new()
	ad_etiketi.text = "Ad:"
	kutu.add_child(ad_etiketi)
	ad_alani = LineEdit.new()
	ad_alani.name = "AdAlani"
	ad_alani.custom_minimum_size = Vector2(190, 0)
	ad_alani.max_length = BolumVerisi.AD_AZAMI
	# Tab odağı ad alanına çalmasın (Tab paleti gizler); alan yalnız tıklayınca odaklanır.
	ad_alani.focus_mode = Control.FOCUS_CLICK
	ad_alani.text_submitted.connect(_on_ad_girildi)
	ad_alani.focus_exited.connect(_on_ad_odak_cikti)
	kutu.add_child(ad_alani)
	var klon_etiketi := Label.new()
	klon_etiketi.text = "Klon:"
	kutu.add_child(klon_etiketi)
	klon_secici = OptionButton.new()
	klon_secici.name = "KlonSecici"
	klon_secici.focus_mode = Control.FOCUS_NONE
	for n in [1, 2, 3]:
		klon_secici.add_item(str(n))
	klon_secici.item_selected.connect(func(i: int) -> void: klon_ata(i + 1))
	kutu.add_child(klon_secici)
	kutu.add_child(VSeparator.new())
	geri_dugmesi = _dugme("GeriAlDugmesi", "Geri al", kutu)
	geri_dugmesi.pressed.connect(geri_al)
	yinele_dugmesi = _dugme("YineleDugmesi", "Yinele", kutu)
	yinele_dugmesi.pressed.connect(yinele)
	kutu.add_child(VSeparator.new())
	izgara_kutusu = CheckBox.new()
	izgara_kutusu.name = "IzgaraKutusu"
	izgara_kutusu.text = "Izgara"
	izgara_kutusu.focus_mode = Control.FOCUS_NONE
	izgara_kutusu.button_pressed = true
	izgara_kutusu.toggled.connect(izgara_ac_kapa)
	kutu.add_child(izgara_kutusu)
	kutu.add_child(VSeparator.new())
	_dugme("DeneDugmesi", "Dene", kutu).pressed.connect(dene_baslat)
	_dugme("DogrulaDugmesi", "Doğrula", kutu).pressed.connect(dogrula_baslat)
	_dugme("MenuDugmesi", "Menü", kutu).pressed.connect(menu_iste)

	# Palet (yarı saydam, tuvalin üstüne biner)
	palet = PanelContainer.new()
	palet.name = "Palet"
	palet.position = Vector2(0, UST_YUKSEKLIK + 6.0)
	palet.add_theme_stylebox_override("panel", _panel_stili(0.78))
	add_child(palet)
	var pk := VBoxContainer.new()
	pk.name = "Kutu"
	pk.add_theme_constant_override("separation", 4)
	palet.add_child(pk)
	var grup := ButtonGroup.new()
	# İki sütun: 16 araç tek sütunda tuvale fazla biner.
	var izgara := GridContainer.new()
	izgara.name = "Araclar"
	izgara.columns = 2
	izgara.add_theme_constant_override("h_separation", 4)
	izgara.add_theme_constant_override("v_separation", 4)
	pk.add_child(izgara)
	var araclar := [["sec", "SecDugmesi", "Seç"], ["bagla", "BaglaDugmesi", "Bağla"],
		["blok", "BlokDugmesi", "Blok"], ["tek_yonlu", "TekYonluDugmesi", "Tek yönlü"],
		["baslangic", "BaslangicDugmesi", "Başlangıç"], ["cikis", "CikisDugmesi", "Çıkış"],
		["plaka", "PlakaDugmesi", "Plaka"], ["zamanli_plaka", "ZamanliPlakaDugmesi", "Zamanlı"],
		["mandal_plaka", "MandalPlakaDugmesi", "Mandal"], ["salter", "SalterDugmesi", "Şalter"],
		["gecit", "GecitDugmesi", "Geçit"], ["asansor", "AsansorDugmesi", "Asansör"],
		["lazer", "LazerDugmesi", "Lazer"], ["kutu", "KutuDugmesi", "Kutu"],
		["ziplatici", "ZiplaticiDugmesi", "Zıplatıcı"], ["bant", "BantDugmesi", "Bant"]]
	for a in araclar:
		var d := _dugme(a[1], a[2], izgara)
		d.toggle_mode = true
		d.button_group = grup
		d.custom_minimum_size = Vector2(88, 0)
		d.pressed.connect(arac_sec.bind(a[0]))
		arac_dugmeleri[a[0]] = d
	arac_dugmeleri["sec"].button_pressed = true
	kablo_sifirla_dugmesi = _dugme("KabloSifirlaDugmesi", "Kabloyu sıfırla", pk)
	kablo_sifirla_dugmesi.pressed.connect(func() -> void: kablo_sifirla())
	kablo_gizle_dugmesi = _dugme("KabloGizleDugmesi", "Kabloyu gizle", pk)
	kablo_gizle_dugmesi.pressed.connect(func() -> void: kablo_gizle_degistir())
	_kablo_dugmelerini_esitle()
	_ozellik_paneli_kur()

	# Durum çubuğu
	durum_cubugu = PanelContainer.new()
	durum_cubugu.name = "DurumCubugu"
	durum_cubugu.position = Vector2(0, EKRAN.y - DURUM_YUKSEKLIK)
	durum_cubugu.custom_minimum_size = Vector2(EKRAN.x, DURUM_YUKSEKLIK)
	durum_cubugu.size = Vector2(EKRAN.x, DURUM_YUKSEKLIK)
	# Tuvalin alt 32 px'ini örtmesin: arka plan tamamen şeffaf, okunabilirlik outline ile.
	var bos_stil := StyleBoxEmpty.new()
	bos_stil.content_margin_left = 6.0
	bos_stil.content_margin_right = 6.0
	durum_cubugu.add_theme_stylebox_override("panel", bos_stil)
	durum_cubugu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(durum_cubugu)
	durum_etiketi = Label.new()
	durum_etiketi.name = "DurumEtiketi"
	durum_etiketi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	durum_etiketi.add_theme_color_override("font_color", LabPaleti.ONLUK)
	durum_etiketi.add_theme_color_override("font_outline_color", LabPaleti.KENAR)
	durum_etiketi.add_theme_constant_override("outline_size", 4)
	durum_etiketi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	durum_cubugu.add_child(durum_etiketi)

	ac_menusu = PopupMenu.new()
	ac_menusu.name = "AcMenusu"
	ac_menusu.id_pressed.connect(_on_ac_secildi)
	add_child(ac_menusu)

	onay_diyalogu = ConfirmationDialog.new()
	onay_diyalogu.name = "OnayDiyalogu"
	onay_diyalogu.title = "Onayla"
	onay_diyalogu.dialog_text = ONAY_METNI
	onay_diyalogu.ok_button_text = "Evet"
	onay_diyalogu.cancel_button_text = "İptal"
	onay_diyalogu.confirmed.connect(onay_kabul)
	onay_diyalogu.canceled.connect(onay_iptal)
	add_child(onay_diyalogu)


# --- Özellik paneli -------------------------------------------------------------------------

## [satır anahtarı, JSON alanı, geçerli türler, denetim tipi, etiket, alt, üst, varsayılan]
const OZELLIK_SATIRLARI := [
	["bant_yon", "yon", ["bant"], "dugme", "Yön", 0, 0, 1],
	["tutma_kare", "tutma_kare", ["zamanli_plaka"], "sayi", "Tutma (kare)", 1, 600, 180],
	["baslangic_sagda", "baslangic_sagda", ["salter"], "kutu", "Başlangıçta sağda", 0, 0, false],
	["lazer_yon", "yon", ["lazer"], "secim", "Yön", 0, 0, "asagi"],
	["uzunluk", "uzunluk", ["lazer"], "sayi", "Uzunluk", 10, 1100, 200],
	["tetik_aktifken_kapali", "tetik_aktifken_kapali", ["lazer"], "kutu", "Tetikleyici basılıyken kapalı", 0, 0, true],
	["acik_taraf_sag", "acik_taraf_sag", ["gecit"], "kutu", "Şalter sağdayken açık", 0, 0, true],
	["lazer_acik_sag", "acik_taraf_sag", ["lazer"], "kutu", "Şalter sağdayken tetik aktif", 0, 0, true],
	["kayma_mesafe", "kayma_mesafe", ["gecit"], "sayi", "Kayma mesafesi", 10, 200, 100],
	["yukseklik", "yukseklik", ["asansor"], "sayi", "Yükseklik", 20, 600, 180],
]
const LAZER_YON_ADLARI := {"asagi": "Aşağı", "yukari": "Yukarı", "sag": "Sağ", "sol": "Sol"}


## Seçili nesnenin düzenlenebilir alanları için sağ üstte küçük panel. Denetimler tek sefer kurulur,
## `_ozellik_paneli_esitle` türe göre satırları gösterir/gizler ve değerleri verilerden okur.
func _ozellik_paneli_kur() -> void:
	ozellik_paneli = PanelContainer.new()
	ozellik_paneli.name = "OzellikPaneli"
	ozellik_paneli.position = Vector2(EKRAN.x - 262.0, UST_YUKSEKLIK + 6.0)
	ozellik_paneli.custom_minimum_size = Vector2(254, 0)
	ozellik_paneli.add_theme_stylebox_override("panel", _panel_stili(0.78))
	ozellik_paneli.visible = false
	add_child(ozellik_paneli)
	var kutu := VBoxContainer.new()
	kutu.name = "Kutu"
	kutu.add_theme_constant_override("separation", 4)
	ozellik_paneli.add_child(kutu)
	ozellik_baslik = Label.new()
	ozellik_baslik.name = "Baslik"
	ozellik_baslik.add_theme_color_override("font_color", LabPaleti.AMBER)
	kutu.add_child(ozellik_baslik)
	for s in OZELLIK_SATIRLARI:
		var satir := HBoxContainer.new()
		satir.name = "Satir_" + s[0]
		satir.add_theme_constant_override("separation", 6)
		kutu.add_child(satir)
		var alan: String = s[1]
		var kontrol: Control
		match s[3]:
			"dugme":
				var d := Button.new()
				d.focus_mode = Control.FOCUS_NONE
				d.pressed.connect(func() -> void: _ozellik_degisti(alan, -int(_nesne(secili).get("yon", 1))))
				kontrol = d
			"sayi":
				var sp := SpinBox.new()
				sp.min_value = float(s[5])
				sp.max_value = float(s[6])
				sp.step = 1.0
				sp.custom_minimum_size = Vector2(90, 0)
				sp.value_changed.connect(func(v: float) -> void:
					_ozellik_degisti(alan, int(v))
					sp.get_line_edit().release_focus())   # Del/ok tuşları yazı kutusunda kalmasın
				kontrol = sp
			"kutu":
				var cb := CheckBox.new()
				cb.focus_mode = Control.FOCUS_NONE
				cb.toggled.connect(func(b: bool) -> void: _ozellik_degisti(alan, b))
				kontrol = cb
			"secim":
				var ob := OptionButton.new()
				ob.focus_mode = Control.FOCUS_NONE
				for y in BolumVerisi.LAZER_YONLERI:
					ob.add_item(LAZER_YON_ADLARI[y])
				ob.item_selected.connect(func(i: int) -> void: _ozellik_degisti(alan, BolumVerisi.LAZER_YONLERI[i]))
				kontrol = ob
		kontrol.name = "Kontrol"
		if s[3] != "kutu":
			var et := Label.new()
			et.text = str(s[4])
			satir.add_child(et)
		else:
			(kontrol as CheckBox).text = str(s[4])
		satir.add_child(kontrol)
		ozellik_satirlari[s[0]] = {"satir": satir, "kontrol": kontrol, "tip": s[3], "alan": alan, "turler": s[2], "varsayilan": s[7]}


func _ozellik_degisti(alan: String, deger: Variant) -> void:
	if _ozellik_esitleniyor or secili == "":
		return
	ozellik_ata(secili, alan, deger)


## Paneli seçili nesneye göre günceller; düzenlenecek alan yoksa gizlenir.
func _ozellik_paneli_esitle() -> void:
	if ozellik_paneli == null:
		return
	var n := _nesne(secili)
	var tur := str(n.get("tur", ""))
	var gorunen := 0
	_ozellik_esitleniyor = true
	for anahtar in ozellik_satirlari:
		var k: Dictionary = ozellik_satirlari[anahtar]
		var uygun: bool = not n.is_empty() and (k["turler"] as Array).has(tur)
		(k["satir"] as Control).visible = uygun
		if not uygun:
			continue
		gorunen += 1
		var deger: Variant = n.get(k["alan"], k["varsayilan"])
		match k["tip"]:
			"dugme":
				(k["kontrol"] as Button).text = "Sağa →" if int(deger) >= 0 else "← Sola"
			"sayi":
				(k["kontrol"] as SpinBox).set_value_no_signal(float(deger))
			"kutu":
				(k["kontrol"] as CheckBox).set_pressed_no_signal(bool(deger))
			"secim":
				(k["kontrol"] as OptionButton).select(maxi(BolumVerisi.LAZER_YONLERI.find(str(deger)), 0))
	_ozellik_esitleniyor = false
	ozellik_paneli.visible = gorunen > 0
	if gorunen > 0:
		ozellik_baslik.text = "%s  (%s)" % [secili, tur]
		ozellik_paneli.reset_size()


## Bir nesne alanını doğrulayıp yazar (panel ve tutamaklar buradan geçer). Aralık dışı sayılar
## kıstırılır; türle uyumsuz alan/değer reddedilir. Dönüş: değişti mi. (Fare tutamakları kendi aralıklarını
## uygular: lazer ucu 10..1100, asansör/geçit `_parametre_uygula`; ikisi de aynı alanları yazar.)
func ozellik_ata(id: String, alan: String, deger: Variant) -> bool:
	var n := _nesne(id)
	if n.is_empty():
		return false
	var tur := str(n.get("tur", ""))
	var satir: Array = []
	for s in OZELLIK_SATIRLARI:
		if s[1] == alan and (s[2] as Array).has(tur):
			satir = s
			break
	if satir.is_empty():
		return false
	var yeni: Variant
	match satir[3]:
		"sayi":
			if typeof(deger) != TYPE_INT and typeof(deger) != TYPE_FLOAT:
				return false
			yeni = clampi(roundi(float(deger)), int(satir[5]), int(satir[6]))
		"kutu":
			if typeof(deger) != TYPE_BOOL:
				return false
			yeni = deger
		"dugme":
			if not (typeof(deger) == TYPE_INT or typeof(deger) == TYPE_FLOAT) or not (int(deger) == 1 or int(deger) == -1):
				return false
			yeni = int(deger)
		"secim":
			if typeof(deger) != TYPE_STRING or not BolumVerisi.LAZER_YONLERI.has(str(deger)):
				return false
			yeni = str(deger)
	if n.get(alan, satir[7]) == yeni:
		return false   # zaten bu değerde (alan yoksa varsayılan sayılır)
	n[alan] = yeni
	_dugum_yenile(id)
	_degisti()
	return true


func _tuval_ciz(hedef: Control) -> void:
	if LabPaleti.ekransiz():
		return
	hedef.draw_rect(Rect2(Vector2.ZERO, EKRAN), LabPaleti.ARKA_UST, true)


# --- Herkese açık API --------------------------------------------------------------------

## Boş bölümle başlar; kimlik ilk Kaydet'e kadar ada göre üretilir.
func yeni() -> void:
	veri = BolumVerisi.bos("Yeni Bölüm", BolumVerisi.yeni_kimlik("Yeni Bölüm", kok))
	kimlik_kilitli = false
	kilit_kimlik = ""
	son_yol = ""
	secili = ""
	secili_kablo = []
	bagla_kaynak = ""
	durum_mesaji = ""
	_gecmisi_sifirla()
	_onizlemeyi_kur()
	_arayuzu_esitle()
	_durum_guncelle()
	_temizi_isaretle()


## Yeni blok ekler (alan [x, y, gen, yuk]; gen/yuk en az 10). Dönüş: kimlik ("Blok1".. benzersiz);
## geçersiz alan ya da 200 nesne dolu ise "".
func blok_ekle(alan: Array) -> String:
	if alan.size() != 4 or veri["nesneler"].size() >= BolumVerisi.AZAMI_NESNE:
		return ""
	var id := _yeni_blok_id()
	var n := {"tur": "blok", "id": id, "alan": _alan_duzelt(alan)}
	veri["nesneler"].append(n)
	_dugum_yenile(id)
	_degisti()
	return id


## Blok dışındaki bir nesneyi ekler (`p` taslak §1.3'teki çapadır: plaka ayak, geçit kapalı alt kenar
## ortası, asansör alt konumdaki üst yüzey ortası, lazer yayıcı..). Türe özgü alanlar varsayılanla yazılır.
## Dönüş: kimlik; geçersiz tür ya da dolu bölümde "".
func nesne_ekle(tur: String, p: Vector2) -> String:
	if not yerlesen_turler.has(tur) or veri["nesneler"].size() >= BolumVerisi.AZAMI_NESNE:
		return ""
	var id := _yeni_id(tur)
	var n := {"tur": tur, "id": id, "konum": [roundi(p.x), roundi(p.y)]}
	match tur:
		"gecit":
			n["kayma_mesafe"] = BolumKurucu.VARSAYILAN_KAYMA_MESAFESI
			n["tetikleyiciler"] = []
			n["acik_taraf_sag"] = true
		"asansor":
			n["yukseklik"] = BolumKurucu.VARSAYILAN_YUKSEKLIK
		"lazer":
			n["yon"] = "asagi"
			n["uzunluk"] = BolumKurucu.VARSAYILAN_UZUNLUK
			n["tetikleyiciler"] = []
			n["tetik_aktifken_kapali"] = true
			n["acik_taraf_sag"] = true
		"bant":
			n["yon"] = 1
		"zamanli_plaka":
			n["tutma_kare"] = BolumKurucu.VARSAYILAN_TUTMA_KARE
		"salter":
			n["baslangic_sagda"] = false
	veri["nesneler"].append(n)
	_dugum_yenile(id)
	_degisti()
	return id


## Tetikleyiciyi hedefe bağlar ya da (bağlıysa) kaldırır. Dönüş: "baglandi" | "kaldirildi" | "onay" | "red".
## "onay": asansörün başka plakası var; onay diyaloğu açılır, "Evet" bağlantıyı değiştirir.
func bagla(tetik_id: String, hedef_id: String, onayli: bool = false) -> String:
	var onceki := BolumVerisi.kanonik_metin(veri)
	var s := BaglantiIslemleri.bagla(veri, tetik_id, hedef_id, onayli)
	var sonuc := str(s["sonuc"])
	if sonuc == "onay":
		_soru_sor(str(s["mesaj"]), bagla.bind(tetik_id, hedef_id, true))
		return sonuc
	_mesaj(str(s["mesaj"]))
	if sonuc == "baglandi" or sonuc == "kaldirildi":
		if BolumVerisi.kanonik_metin(veri) != onceki:
			secili_kablo = []
			_dugum_yenile(hedef_id)
			_degisti()
	return sonuc


func baslangic_koy(p: Vector2) -> void:
	veri["baslangic"] = [roundi(p.x), roundi(p.y)]
	_degisti()


func cikis_koy(p: Vector2) -> void:
	veri["cikis"] = [roundi(p.x), roundi(p.y)]
	_degisti()


## Nesneyi (ya da "@baslangic"/"@cikis" işaretini) kaydırır. Blokta alan, diğerlerinde konum.
func nesne_tasi(id: String, delta: Vector2) -> void:
	if not _tasi_uygula(id, delta):
		return
	_degisti()


func blok_boyutla(id: String, alan: Array) -> void:
	var n := _nesne(id)
	if n.is_empty() or str(n["tur"]) != "blok" or alan.size() != 4:
		return
	n["alan"] = _alan_duzelt(alan)
	_dugum_yenile(id)
	_degisti()


func nesne_sil(id: String) -> void:
	for i in veri["nesneler"].size():
		if str(veri["nesneler"][i].get("id", "")) == id:
			veri["nesneler"].remove_at(i)
			_dugum_kaldir(id)
			if secili == id:
				secili = ""
			if bagla_kaynak == id:
				bagla_kaynak = ""
			secili_kablo = []
			for hid in BaglantiIslemleri.referanslari_sil(veri, id):
				_dugum_yenile(hid)
			_degisti()
			return


func sec(id: String) -> void:
	secili_kablo = []
	_kablo_dugmelerini_esitle()
	if id == BASLANGIC_ID or id == CIKIS_ID or not _nesne(id).is_empty():
		secili = id
	else:
		secili = ""
	_ozellik_paneli_esitle()
	_durum_guncelle()
	katman.queue_redraw()


func geri_al() -> void:
	if gecmis_i <= 0:
		return
	gecmis_i -= 1
	_gecmisten_yukle()


func yinele() -> void:
	if gecmis_i >= gecmis.size() - 1:
		return
	gecmis_i += 1
	_gecmisten_yukle()


## Kimlik ilk Kaydet'te kilitlenir. Dönüş: yazma sonucu.
func kaydet() -> Error:
	if is_inside_tree():
		get_viewport().gui_release_focus()   # panelde Enter'sız yazılan sayı işlensin
	# Enter'a basılmadan yazılan ad (düğmeler odağı almaz) kimlik kilitlenmeden işlenir.
	if ad_alani != null:
		ad_ata(ad_alani.text)
	if not kimlik_kilitli:
		var k := BolumVerisi.yeni_kimlik(str(veri["ad"]), kok)
		if k == "":
			return ERR_CANT_CREATE
		veri["kimlik"] = k
	var yol := BolumYollari.bolumler_dizini(kok) + str(veri["kimlik"]) + ".json"
	var h := BolumVerisi.yaz(veri, yol)
	if h == OK:
		kimlik_kilitli = true
		kilit_kimlik = str(veri["kimlik"])
		son_yol = yol
		_temizi_isaretle()
		_mesaj("Kaydedildi: %s" % yol)
	else:
		_mesaj("Kaydedilemedi (hata %d)" % h)
	return h


## Dosyadan açar. Dönüş: şema sorunları (boş sözlük dönerse bölüm değişmez). Geçmiş sıfırlanır.
func ac(yol: String) -> Array:
	var sonuc := BolumVerisi.oku(yol)
	var sorunlar: Array = sonuc["sorunlar"]
	var yeni_veri: Dictionary = sonuc["veri"]
	if yeni_veri.is_empty():
		_mesaj("Açılamadı: %s" % (str(sorunlar[0]["mesaj"]) if sorunlar.size() > 0 else yol))
		return sorunlar
	# Şema HATA'sı olan dosya reddedilir (taslak §1.5); bölüm değişmez.
	for sorun in sorunlar:
		if str(sorun.get("seviye", "")) == "HATA":
			_mesaj("Açılamadı, şema hatası: %s" % str(sorun["mesaj"]))
			return sorunlar
	veri = yeni_veri
	kimlik_kilitli = true
	kilit_kimlik = str(veri["kimlik"])
	son_yol = yol
	secili = ""
	secili_kablo = []
	bagla_kaynak = ""
	_gecmisi_sifirla()
	_onizlemeyi_kur()
	_arayuzu_esitle()
	if sorunlar.size() > 0:
		_mesaj("Açıldı, %d şema sorunu: %s" % [sorunlar.size(), str(sorunlar[0]["mesaj"])])
	else:
		_mesaj("Açıldı: %s" % yol)
	_durum_guncelle()
	_temizi_isaretle()
	return sorunlar


## Son Kaydet/Aç/Yeni'den beri veri değişti mi? İçerik, çözüm kaydı ve doğrulama sonucu sayılır.
func kirli_mi() -> bool:
	return BolumVerisi.kirlilik_metni(veri) != _temiz_goruntu


func _temizi_isaretle() -> void:
	_temiz_goruntu = BolumVerisi.kirlilik_metni(veri)


## Yeni/Aç/Menü: temizse hemen yürütür, kirliyse onay sorar.
func yeni_iste() -> void:
	_ad_isle()
	_onayla(yeni)


func ac_iste(yol: String) -> void:
	_ad_isle()
	_onayla(ac.bind(yol))


func menu_iste() -> void:
	_ad_isle()
	_onayla(_menuye_git)


## Bölümlerim ekranına gider (kirliyse onay sorar; doğrulama sürerken gitmez).
func bolumlerim_iste() -> void:
	if get_tree() != null and get_tree().root.get_node_or_null("EditorDogrulama") != null:
		return
	_ad_isle()
	_onayla(_bolumlerime_git)


## Enter'a basılmadan yazılan ad (düğmeler odağı almaz) kirlilik hesabına girsin.
func _ad_isle() -> void:
	if ad_alani != null:
		ad_ata(ad_alani.text)


func _onayla(islem: Callable) -> void:
	if not kirli_mi():
		islem.call()
		return
	_bekleyen = islem
	if onay_diyalogu.is_inside_tree():
		onay_diyalogu.popup_centered()


## Özel soru metniyle onay ister (kirlilik denetimi yok).
func _soru_sor(metin: String, islem: Callable) -> void:
	_bekleyen = islem
	onay_diyalogu.dialog_text = metin
	if onay_diyalogu.is_inside_tree():
		onay_diyalogu.popup_centered()


## Onay diyaloğunda "Evet": bekleyen işlemi yürütür.
func onay_kabul() -> void:
	var islem := _bekleyen
	_bekleyen = Callable()
	onay_diyalogu.hide()
	onay_diyalogu.dialog_text = ONAY_METNI
	if islem.is_valid():
		islem.call()


## Onay diyaloğunda "İptal": bekleyen işlem atılır.
func onay_iptal() -> void:
	_bekleyen = Callable()
	onay_diyalogu.hide()
	onay_diyalogu.dialog_text = ONAY_METNI


func _bolumlerime_git() -> void:
	Kayitlar.sifirla()
	EditorOturumu.temizle()
	EditorOturumu.kok = kok   # Bölümlerim aynı kökü okusun (testlerde user://test_editor/)
	get_tree().change_scene_to_file(BolumYollari.BOLUMLERIM_SAHNESI)


func _menuye_git() -> void:
	Kayitlar.sifirla()
	EditorOturumu.temizle()
	get_tree().change_scene_to_file(ANA_MENU_SAHNESI)


## Bölümü denetler; HATA yoksa durumu oturuma yazıp geçici Dene sahnesini açar.
## Çözümsüzlük engel değildir (S4). Dönüş: sahne değiştirme başlatıldı mı.
func dene_baslat() -> bool:
	if get_tree() != null and get_tree().root.get_node_or_null("EditorDogrulama") != null:
		return false   # doğrulama sürerken ikinci bir sahne değişimi başlamasın
	if is_inside_tree():
		get_viewport().gui_release_focus()   # panelde Enter'sız yazılan sayı işlensin
	if ad_alani != null:
		ad_ata(ad_alani.text)
	for sorun in BolumDenetci.statik(veri):
		if str(sorun.get("seviye", "")) == "HATA":
			_mesaj("Dene açılamadı: %s" % str(sorun.get("mesaj", "")))
			return false
	var yol := BolumKurucu.yeni_gecici_yol(BolumYollari.editor_dizini(kok), "dene")
	var h := BolumKurucu.sahneye_kaydet(veri, yol)
	if h != OK:
		_mesaj("Dene açılamadı (hata %d)" % h)
		return false
	_oturuma_yaz()
	Kayitlar.sifirla()
	get_tree().change_scene_to_file(yol)
	return true


## "Doğrula" (F6): statik HATA yoksa ve çözüm kayıtlıysa geçici sahneyi yazar, durumu oturuma bırakır ve
## `EditorDogrulama`'yı `root` altında başlatır (editör sahnesi doğrulama sırasında yok olur; sonuç
## dönüşte `_oturumdan_yukle`'de işlenir). Çözümsüzlük Dene/Oyna'yı engellemez (S4). Dönüş: başladı mı.
func dogrula_baslat() -> bool:
	if get_tree() != null and get_tree().root.get_node_or_null("EditorDogrulama") != null:
		return false   # doğrulama zaten sürüyor
	if is_inside_tree():
		get_viewport().gui_release_focus()
	if ad_alani != null:
		ad_ata(ad_alani.text)
	for sorun in BolumDenetci.statik(veri):
		if str(sorun.get("seviye", "")) == "HATA":
			_mesaj("Doğrulanamadı: %s" % str(sorun.get("mesaj", "")))
			return false
	var cozum: Variant = veri.get("cozum", {})
	if typeof(cozum) != TYPE_DICTIONARY or (cozum.get("oyuncu", []) as Array).is_empty():
		_mesaj("Doğrulanamadı: çözüm yok (önce Dene ile çözüp \"Çözümü kaydet\" deyin)")
		return false
	var yol := BolumKurucu.yeni_gecici_yol(BolumYollari.editor_dizini(kok), "dene")
	var h := BolumKurucu.sahneye_kaydet(veri, yol)
	if h != OK:
		_mesaj("Doğrulanamadı (hata %d)" % h)
		return false
	_oturuma_yaz()
	Kayitlar.sifirla()
	var d := EditorDogrulama.new()
	d.name = "EditorDogrulama"
	get_tree().root.add_child(d)
	d.baslat(veri.duplicate(true), yol)
	return true


func _oturuma_yaz() -> void:
	EditorOturumu.donus = true
	EditorOturumu.veri = veri.duplicate(true)
	EditorOturumu.gecmis = gecmis.duplicate(true)
	EditorOturumu.gecmis_i = gecmis_i
	EditorOturumu.kimlik_kilitli = kimlik_kilitli
	EditorOturumu.kilit_kimlik = kilit_kimlik
	EditorOturumu.son_yol = son_yol
	EditorOturumu.secili = secili
	EditorOturumu.temiz_goruntu = _temiz_goruntu
	EditorOturumu.cozum = {}
	EditorOturumu.dogrulama = {}
	EditorOturumu.kok = kok


## Dene'den dönüş: durumu geri yükler; çözüm geldiyse `veri["cozum"]`a yazar ve eski
## doğrulama sonucunu siler (geçmişe kayıt atılmaz).
func _oturumdan_yukle() -> void:
	veri = (EditorOturumu.veri as Dictionary).duplicate(true)
	gecmis = (EditorOturumu.gecmis as Array).duplicate(true)
	gecmis_i = EditorOturumu.gecmis_i
	kimlik_kilitli = EditorOturumu.kimlik_kilitli
	kilit_kimlik = EditorOturumu.kilit_kimlik
	son_yol = EditorOturumu.son_yol
	secili = EditorOturumu.secili
	_temiz_goruntu = EditorOturumu.temiz_goruntu
	if EditorOturumu.kok != "":
		kok = EditorOturumu.kok
	var cozum: Dictionary = EditorOturumu.cozum
	EditorOturumu.cozum = {}
	EditorOturumu.donus = false
	if secili != BASLANGIC_ID and secili != CIKIS_ID and _nesne(secili).is_empty():
		secili = ""
	if not cozum.is_empty():
		var turlar: Array = []
		for t in cozum.get("turlar", []):
			turlar.append(BolumVerisi.kayit_kodla(t))
		veri["cozum"] = {"turlar": turlar, "oyuncu": BolumVerisi.kayit_kodla(cozum.get("oyuncu", []))}
		veri.erase("dogrulama")
		# Geri al/yinele çözümü kaybetmesin: geçerli anlık görüntüye de yazılır.
		if gecmis_i >= 0 and gecmis_i < gecmis.size():
			gecmis[gecmis_i] = veri.duplicate(true)
		durum_mesaji = "Çözüm kaydedildi"
	var dog: Dictionary = EditorOturumu.dogrulama
	EditorOturumu.dogrulama = {}
	if not dog.is_empty():
		_dogrulama_isle(dog)
	_onizlemeyi_kur()
	_arayuzu_esitle()
	_durum_guncelle()


## Doğrulama sonucunu işler: iptalde hiçbir şey yazılmaz; aksi hâlde `dogrulama` kaydı güncel içerik
## özetiyle yazılır (içerik değişince özet tutmaz, durum "taslak" sayılır). Geçmişe kayıt atılmaz.
func _dogrulama_isle(dog: Dictionary) -> void:
	if bool(dog.get("iptal", false)):
		durum_mesaji = "Doğrulama iptal edildi (hiçbir şey yazılmadı)"
		return
	var kayit := {"durum": str(dog.get("durum", "taslak")), "icerik_ozeti": BolumVerisi.icerik_ozeti(veri),
		"hata": int(dog.get("hata", 0)), "uyari": int(dog.get("uyari", 0))}
	if int(dog.get("bitis_kare", -1)) >= 0:
		kayit["bitis_kare"] = int(dog["bitis_kare"])
	veri["dogrulama"] = kayit
	if gecmis_i >= 0 and gecmis_i < gecmis.size():
		gecmis[gecmis_i] = veri.duplicate(true)
	if kayit["durum"] == "dogrulandi":
		durum_mesaji = "Doğrulandı (bitiş karesi %d, %d uyarı); kalıcı olması için Kaydet" % [int(kayit.get("bitis_kare", 0)), int(kayit["uyari"])]
	else:
		var ilk := ""
		for sorun in dog.get("sorunlar", []):
			if str(sorun.get("seviye", "")) == "HATA":
				ilk = str(sorun.get("mesaj", ""))
				break
		durum_mesaji = "Taslak: doğrulanamadı (%d hata)%s" % [int(kayit["hata"]), (": " + ilk) if ilk != "" else ""]


## Çözüm ve doğrulama durumu: "Doğrulandı" yalnız kayıt güncel içerikle tutuyorsa.
func dogrulama_durumu() -> String:
	return BolumVerisi.dogrulama_durumu(veri)


func izgara_ac_kapa(acik: bool) -> void:
	izgara_acik = acik
	if izgara_kutusu != null:
		izgara_kutusu.set_pressed_no_signal(acik)
	katman.queue_redraw()


## Izgara adımı: kapalıysa 1, açıkta 20 (Shift: 10).
func izgara_adimi(shift: bool) -> int:
	if not izgara_acik:
		return 1
	return IZGARA_ADIMI_SHIFT if shift else IZGARA_ADIMI


## Izgaraya oturtur; ekran kenarları (0, 1152, 648) adımın yarısı kadar yakınlıkta mıknatıs
## gibi çeker. Izgara kapalıyken yalnız 1 px'e yuvarlar, mıknatıs yoktur.
func miknatis(p: Vector2, shift: bool) -> Vector2:
	if not izgara_acik:
		return Vector2(roundf(p.x), roundf(p.y))
	var adim := float(izgara_adimi(shift))
	var r := Vector2(roundf(p.x / adim) * adim, roundf(p.y / adim) * adim)
	var esik := adim / 2.0
	if absf(p.x - EKRAN.x) <= esik:
		r.x = EKRAN.x
	if absf(p.y - EKRAN.y) <= esik:
		r.y = EKRAN.y
	return r


func onizleme_dugumu(id: String) -> Node:
	return dugumler.get(id, null)


func ad_ata(metin: String) -> void:
	var m := metin.strip_edges().left(BolumVerisi.AD_AZAMI)
	if m == "" or m == str(veri["ad"]):
		_arayuzu_esitle()
		return
	veri["ad"] = m
	if not kimlik_kilitli:
		var k := BolumVerisi.yeni_kimlik(m, kok)
		if k != "":
			veri["kimlik"] = k
	_degisti()


func klon_ata(n: int) -> void:
	n = clampi(n, 1, 3)
	if int(veri["max_klon"]) == n:
		return
	veri["max_klon"] = n
	_degisti()


## Kabloyu seçer (Kabloyu sıfırla / gizle düğmeleri ona uygulanır). Dönüş: seçildi mi.
func kablo_sec(hedef_id: String, tetik_id: String) -> bool:
	var h := _nesne(hedef_id)
	if h.is_empty() or BaglantiIslemleri.sira(h, tetik_id) < 0:
		return false
	secili = ""
	secili_kablo = [hedef_id, tetik_id]
	_ozellik_paneli_esitle()
	_kablo_dugmelerini_esitle()
	_durum_guncelle()
	katman.queue_redraw()
	return true


## Editörde çizilen kablo noktaları (gizli kablo da dahil).
func kablo_yolu(hedef_id: String, tetik_id: String) -> PackedVector2Array:
	return BaglantiIslemleri.yol(veri, hedef_id, tetik_id, true)


## Kabloya ara nokta ekler (ızgaraya oturur). Dönüş: ara nokta sırası (-1: olmadı).
func ara_nokta_ekle(hedef_id: String, tetik_id: String, p: Vector2, shift: bool = false) -> int:
	var i := BaglantiIslemleri.ara_ekle(veri, hedef_id, tetik_id, miknatis(p, shift))
	if i >= 0:
		_kablo_degisti(hedef_id)
	return i


func ara_nokta_tasi(hedef_id: String, tetik_id: String, i: int, p: Vector2, shift: bool = false) -> bool:
	if not BaglantiIslemleri.ara_tasi(veri, hedef_id, tetik_id, i, miknatis(p, shift)):
		return false
	_kablo_degisti(hedef_id)
	return true


func ara_nokta_sil(hedef_id: String, tetik_id: String, i: int) -> bool:
	if not BaglantiIslemleri.ara_sil(veri, hedef_id, tetik_id, i):
		return false
	_kablo_degisti(hedef_id)
	return true


## Seçili (ya da verilen) kabloyu otomatik yola döndürür.
func kablo_sifirla(hedef_id: String = "", tetik_id: String = "") -> bool:
	if hedef_id == "" and secili_kablo.size() == 2:
		hedef_id = secili_kablo[0]
		tetik_id = secili_kablo[1]
	if not BaglantiIslemleri.sifirla(veri, hedef_id, tetik_id):
		return false
	_kablo_degisti(hedef_id)
	return true


## Seçili (ya da verilen) kabloyu gizler/gösterir; bağlantı çalışmaya devam eder.
func kablo_gizle_degistir(hedef_id: String = "", tetik_id: String = "") -> bool:
	if hedef_id == "" and secili_kablo.size() == 2:
		hedef_id = secili_kablo[0]
		tetik_id = secili_kablo[1]
	if _nesne(hedef_id).is_empty():
		return false
	if not BaglantiIslemleri.gizle(veri, hedef_id, tetik_id, not BaglantiIslemleri.gizli_mi(veri, hedef_id, tetik_id)):
		return false
	_kablo_degisti(hedef_id)
	return true


func _kablo_degisti(hedef_id: String) -> void:
	_dugum_yenile(hedef_id)
	_degisti()
	_kablo_dugmelerini_esitle()


func _kablo_dugmelerini_esitle() -> void:
	if kablo_sifirla_dugmesi == null:
		return
	var var_mi := secili_kablo.size() == 2 and BaglantiIslemleri.sira(_nesne(secili_kablo[0]), secili_kablo[1]) >= 0
	if not var_mi:
		secili_kablo = []
	kablo_sifirla_dugmesi.disabled = not var_mi
	kablo_gizle_dugmesi.disabled = not var_mi
	kablo_gizle_dugmesi.text = "Kabloyu göster" if var_mi and BaglantiIslemleri.gizli_mi(veri, secili_kablo[0], secili_kablo[1]) else "Kabloyu gizle"


## Asansör yüksekliği (20..600) ya da geçit kayma mesafesi (10..200). Dönüş: değişti mi.
func parametre_ata(id: String, deger: int) -> bool:
	var n := _nesne(id)
	if n.is_empty() or not _parametre_uygula(n, deger):
		return false
	_degisti()
	return true


func _parametre_uygula(n: Dictionary, deger: int) -> bool:
	var alan := ""
	var alt := 0
	var ust := 0
	match str(n.get("tur", "")):
		"asansor":
			alan = "yukseklik"
			alt = 20
			ust = 600
		"gecit":
			alan = "kayma_mesafe"
			alt = 10
			ust = 200
		_:
			return false
	var yeni := clampi(deger, alt, ust)
	if int(n.get(alan, -1)) == yeni:
		return false
	n[alan] = yeni
	_dugum_yenile(str(n["id"]))
	return true


## Asansör üst konumu / geçit açık konumu üst kenarındaki tutamak; yoksa Vector2.INF.
func parametre_tutamaci(id: String) -> Vector2:
	var n := _nesne(id)
	if n.is_empty() or not (n.get("konum") is Array):
		return Vector2.INF
	var k := _nokta(n["konum"])
	match str(n.get("tur", "")):
		"asansor":
			return k + Vector2(0, -float(n.get("yukseklik", BolumKurucu.VARSAYILAN_YUKSEKLIK)))
		"gecit":
			return k + Vector2(0, -200.0 - float(n.get("kayma_mesafe", BolumKurucu.VARSAYILAN_KAYMA_MESAFESI)))
		"lazer":
			# Işının ucu: sürüklemek uzunluğu ve yönü ayarlar.
			var yon: Vector2 = BolumKurucu.LAZER_YONLERI.get(str(n.get("yon", "asagi")), Vector2.DOWN)
			return k + yon * float(n.get("uzunluk", BolumKurucu.VARSAYILAN_UZUNLUK))
	return Vector2.INF


func arac_sec(ad: String) -> void:
	if not arac_dugmeleri.has(ad):
		return
	arac = ad
	bagla_kaynak = ""
	imlec_var = false
	for k in arac_dugmeleri:
		(arac_dugmeleri[k] as Button).set_pressed_no_signal(k == ad)
	katman.queue_redraw()


# --- Veri yardımcıları -----------------------------------------------------------------------

func _nesne(id: String) -> Dictionary:
	for n in veri["nesneler"]:
		if str(n.get("id", "")) == id:
			return n
	return {}


func _yeni_blok_id() -> String:
	return _yeni_id("blok")


## "Blok1", "Plaka1", "Gecit1", "Asansor1".. benzersiz kimlik.
func _yeni_id(tur: String) -> String:
	var onek := {"blok": "Blok", "plaka": "Plaka", "gecit": "Gecit", "asansor": "Asansor", "zamanli_plaka": "ZamanliPlaka",
		"mandal_plaka": "MandalPlaka", "salter": "Salter", "lazer": "Lazer", "kutu": "Kutu", "ziplatici": "Ziplatici",
		"bant": "Bant", "tek_yonlu": "TekYonlu"}.get(tur, "Nesne") as String
	var k := 1
	while not _nesne("%s%d" % [onek, k]).is_empty():
		k += 1
	return "%s%d" % [onek, k]


func _alan_duzelt(alan: Array) -> Array:
	return [roundi(float(alan[0])), roundi(float(alan[1])),
		maxi(roundi(float(alan[2])), EN_KUCUK_BOYUT), maxi(roundi(float(alan[3])), EN_KUCUK_BOYUT)]


## Veriyi değiştirir (geçmişe yazmaz). Dönüş: değişti mi.
func _tasi_uygula(id: String, delta: Vector2) -> bool:
	var d := Vector2(roundf(delta.x), roundf(delta.y))
	if id == BASLANGIC_ID or id == CIKIS_ID:
		var anahtar := "baslangic" if id == BASLANGIC_ID else "cikis"
		veri[anahtar] = [int(veri[anahtar][0]) + int(d.x), int(veri[anahtar][1]) + int(d.y)]
		return true
	var n := _nesne(id)
	if n.is_empty():
		return false
	if str(n["tur"]) == "blok":
		n["alan"] = [int(n["alan"][0]) + int(d.x), int(n["alan"][1]) + int(d.y), n["alan"][2], n["alan"][3]]
	elif n.has("konum"):
		n["konum"] = [int(n["konum"][0]) + int(d.x), int(n["konum"][1]) + int(d.y)]
	else:
		return false
	BaglantiIslemleri.uclari_sil(veri, id)
	_dugum_yenile(id)
	# Kablo meta'sı tetikleyici konumundan hesaplanır: bağlı hedefler yeniden kurulur.
	for b in BaglantiIslemleri.baglantilar(veri):
		if b["tetik"] == id and b["hedef"] != id:
			_dugum_yenile(b["hedef"])
	return true


func _nokta(v: Variant) -> Vector2:
	return Vector2(float(v[0]), float(v[1]))


func baslangic_dikdortgeni() -> Rect2:
	var b := _nokta(veri["baslangic"])
	return Rect2(b.x - BolumDenetci.KARAKTER.x / 2.0, b.y - BolumDenetci.KARAKTER.y, BolumDenetci.KARAKTER.x, BolumDenetci.KARAKTER.y)


func cikis_dikdortgeni() -> Rect2:
	var c := _nokta(veri["cikis"])
	return Rect2(c.x - BolumDenetci.CIKIS_BOYUTU.x / 2.0, c.y - BolumDenetci.CIKIS_BOYUTU.y, BolumDenetci.CIKIS_BOYUTU.x, BolumDenetci.CIKIS_BOYUTU.y)


## Seçilebilir nesnenin tuval dikdörtgeni; kurulamayan/bozuk nesne için boş Rect2.
func secim_dikdortgeni(id: String) -> Rect2:
	if id == BASLANGIC_ID:
		return baslangic_dikdortgeni()
	if id == CIKIS_ID:
		return cikis_dikdortgeni()
	var n := _nesne(id)
	if n.is_empty():
		return Rect2()
	var tur := str(n.get("tur", ""))
	if tur == "blok":
		if not (n.get("alan") is Array) or n["alan"].size() != 4:
			return Rect2()
	elif not (n.get("konum") is Array) or n["konum"].size() != 2 or not BolumVerisi.TURLER.has(tur):
		return Rect2()
	return BolumDenetci.nesne_dikdortgeni(n)


func tutamaclar_var(id: String) -> bool:
	var n := _nesne(id)
	return not n.is_empty() and str(n.get("tur", "")) == "blok"


## 8 tutamak: sol üst, üst, sağ üst, sağ, sağ alt, alt, sol alt, sol (saat yönü).
func tutamac_noktalari(r: Rect2) -> Array[Vector2]:
	var c := r.get_center()
	return [r.position, Vector2(c.x, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x, c.y),
		r.end, Vector2(c.x, r.end.y), Vector2(r.position.x, r.end.y), Vector2(r.position.x, c.y)]


# --- Geçmiş ---------------------------------------------------------------------------------

func _gecmisi_sifirla() -> void:
	gecmis = [veri.duplicate(true)]
	gecmis_i = 0


## Her değişiklikte tüm verinin derin kopyası; ileri kayıtlar atılır, en çok GECMIS_AZAMI adım.
func _gecmise_ekle() -> void:
	if gecmis_i < gecmis.size() - 1:
		gecmis.resize(gecmis_i + 1)
	gecmis.append(veri.duplicate(true))
	while gecmis.size() > GECMIS_AZAMI + 1:
		gecmis.pop_front()
	gecmis_i = gecmis.size() - 1


func _gecmisten_yukle() -> void:
	veri = (gecmis[gecmis_i] as Dictionary).duplicate(true)
	if kimlik_kilitli:
		veri["kimlik"] = kilit_kimlik
	if secili != BASLANGIC_ID and secili != CIKIS_ID and _nesne(secili).is_empty():
		secili = ""
	bagla_kaynak = ""
	_onizlemeyi_kur()
	_arayuzu_esitle()
	_durum_guncelle()


func _degisti() -> void:
	_gecmise_ekle()
	_arayuzu_esitle()
	_durum_guncelle()
	katman.queue_redraw()


# --- Önizleme --------------------------------------------------------------------------------

func _onizlemeyi_kur() -> void:
	for id in dugumler.keys():
		_dugum_kaldir(id)
	# Geçit/lazer `_ready`'de tetikleyici yollarını çözer: önce tetikleyiciler (ve diğerleri), sonra hedefler.
	for hedefler in [false, true]:
		for n in veri["nesneler"]:
			if _yollu_mu(n) == hedefler:
				_dugum_kur(n)
	var sira := 0
	for n in veri["nesneler"]:
		var d: Node = dugumler.get(str(n.get("id", "")), null)
		if d != null:
			onizleme.move_child(d, sira)
			sira += 1
	_asansorlari_bagla()
	katman.queue_redraw()


## Tetikleyici yolu çözen tür (geçit, lazer).
func _yollu_mu(n: Dictionary) -> bool:
	var tur := str(n.get("tur", ""))
	return tur == "gecit" or tur == "lazer"


func _dugum_kaldir(id: String) -> void:
	var d: Node = dugumler.get(id, null)
	dugumler.erase(id)
	if d != null and is_instance_valid(d):
		d.get_parent().remove_child(d)   # ad çakışmasın diye hemen ağaçtan çıkar
		d.queue_free()


func _dugum_yenile(id: String) -> void:
	_dugum_kaldir(id)
	var n := _nesne(id)
	if not n.is_empty():
		_dugum_kur(n)
		_asansorlari_bagla()
	katman.queue_redraw()


func _dugum_kur(n: Dictionary) -> void:
	var kaynak := n
	if _yollu_mu(n) and typeof(n.get("tetikleyiciler")) == TYPE_ARRAY:
		# Kurulmamış (eksik/bozuk) tetikleyiciye giden yol `get_node` hatası vermesin.
		var var_olan: Array = []
		for t in n["tetikleyiciler"]:
			if dugumler.has(str(t)):
				var_olan.append(t)
		if var_olan.size() != n["tetikleyiciler"].size():
			kaynak = n.duplicate(true)
			kaynak["tetikleyiciler"] = var_olan
	var d := BolumKurucu.nesne_kur(kaynak, veri)
	if d == null:
		return
	d.process_mode = Node.PROCESS_MODE_DISABLED
	if str(n["tur"]) == "blok":
		# bolum.gd:_gorunumu_kur ile aynı çağrı: renkli kutu gizlenir, ortak duvar çizimi eklenir.
		var kutu := d.get_node_or_null("Gorsel") as ColorRect
		if kutu != null:
			kutu.visible = false
			Gorunum.ekle(d, Gorunum.Tur.DUVAR, Rect2(kutu.position, kutu.size))
	onizleme.add_child(d)
	dugumler[str(n["id"])] = d
	# JSON sırasında kal (çizim sırası)
	var sira: int = veri["nesneler"].find(n)
	if sira >= 0:
		onizleme.move_child(d, mini(sira, onizleme.get_child_count() - 1))


## Asansörün `plaka` düğüm referansı kardeş düğüm gerektirir (nesne_kur bağlayamaz).
func _asansorlari_bagla() -> void:
	for n in veri["nesneler"]:
		if str(n.get("tur", "")) == "asansor" and dugumler.has(str(n["id"])) and dugumler.has(str(n.get("plaka", ""))):
			dugumler[str(n["id"])].set("plaka", dugumler[str(n["plaka"])])


# --- Arayüz eşitleme --------------------------------------------------------------------------

func _arayuzu_esitle() -> void:
	if ad_alani == null:
		return
	ad_alani.text = str(veri["ad"])
	var k := int(veri["max_klon"])
	klon_secici.select(k - 1 if k >= 1 and k <= 3 else -1)
	geri_dugmesi.disabled = gecmis_i <= 0
	yinele_dugmesi.disabled = gecmis_i >= gecmis.size() - 1
	izgara_kutusu.set_pressed_no_signal(izgara_acik)
	_kablo_dugmelerini_esitle()
	_ozellik_paneli_esitle()


func _mesaj(m: String) -> void:
	durum_mesaji = m
	_durum_guncelle()


func _durum_guncelle() -> void:
	if durum_etiketi == null:
		return
	var ozet := BolumDenetci.ozet(BolumDenetci.statik(veri))
	var sec_metni := "yok"
	if secili == BASLANGIC_ID:
		sec_metni = "Başlangıç"
	elif secili == CIKIS_ID:
		sec_metni = "Çıkış"
	elif secili != "":
		sec_metni = secili
	var metin := "Seçili: %s   |   Nesne: %d   |   %d HATA, %d UYARI (bilgi amaçlı)   |   %s" % [sec_metni, veri["nesneler"].size(), ozet["hata"], ozet["uyari"], dogrulama_durumu()]
	if bagla_kaynak != "":
		metin += "   |   Bağla: %s -> hedefi tıklayın (Esc: iptal)" % bagla_kaynak
	if durum_mesaji != "":
		metin += "   |   " + durum_mesaji
	durum_etiketi.text = metin


# --- Arayüz olayları --------------------------------------------------------------------------

func _on_kaydet() -> void:
	kaydet()


func _on_ad_girildi(metin: String) -> void:
	ad_ata(metin)
	ad_alani.release_focus()


func _on_ad_odak_cikti() -> void:
	ad_ata(ad_alani.text)


## Kayıtlı bölümlerin basit listesi (user://bolumler/*.json).
func _on_ac() -> void:
	ac_menusu.clear()
	_ac_yollari.clear()
	var dizin := BolumYollari.bolumler_dizini(kok)
	var adlar: Array = []
	for f in DirAccess.get_files_at(dizin):
		if f.ends_with(".json"):
			adlar.append(f)
	adlar.sort()
	for f in adlar:
		ac_menusu.add_item(f.get_basename(), _ac_yollari.size())
		_ac_yollari.append(dizin + f)
	if adlar.is_empty():
		ac_menusu.add_item("(kayıtlı bölüm yok)", 0)
		ac_menusu.set_item_disabled(0, true)
	var d := ust_cubuk.get_node("Kutu/AcDugmesi") as Control
	ac_menusu.popup(Rect2i(Vector2i(d.global_position + Vector2(0, d.size.y)), Vector2i(220, 0)))


func _on_ac_secildi(i: int) -> void:
	if i >= 0 and i < _ac_yollari.size():
		ac_iste(_ac_yollari[i])


# --- Fare ve klavye ------------------------------------------------------------------------------

func _tuval_girdi(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		_fare_hareket(e.position, e.shift_pressed)
	elif e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				ad_alani.release_focus()
				get_viewport().gui_release_focus()   # özellik panelindeki sayı kutusu klavyeyi tutmasın
				_fare_bas(e.position, e.shift_pressed, e.double_click)
			else:
				_fare_birak(e.position, e.shift_pressed)
		elif e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
			_sag_tik(e.position)


## En üstteki nesne (ya da işaret) kimliği; yoksa "".
func nesne_bul(p: Vector2) -> String:
	if cikis_dikdortgeni().grow(2.0).has_point(p):
		return CIKIS_ID
	if baslangic_dikdortgeni().grow(2.0).has_point(p):
		return BASLANGIC_ID
	for i in range(veri["nesneler"].size() - 1, -1, -1):
		var id := str(veri["nesneler"][i].get("id", ""))
		var r := secim_dikdortgeni(id)
		if r.size != Vector2.ZERO and r.grow(2.0).has_point(p):
			return id
		# Lazerin ışını 6 px incedir: yayıcı gövdesi de tutulabilir.
		var n: Dictionary = veri["nesneler"][i]
		if str(n.get("tur", "")) == "lazer" and n.get("konum") is Array and n["konum"].size() == 2 \
				and Rect2(_nokta(n["konum"]) - Vector2(12, 12), Vector2(24, 24)).has_point(p):
			return id
	return ""


func _tutamac_bul(p: Vector2) -> int:
	if secili == "" or not tutamaclar_var(secili):
		return -1
	var noktalar := tutamac_noktalari(secim_dikdortgeni(secili))
	for i in noktalar.size():
		if noktalar[i].distance_to(p) <= TUTAMAC_YARICAPI + 2.0:
			return i
	return -1


func _fare_bas(p: Vector2, shift: bool, cift_tik: bool = false) -> void:
	if yerlesen_turler.has(arac):
		var yid := nesne_ekle(arac, miknatis(p, shift))
		if yid != "":
			sec(yid)
		katman.queue_redraw()
		return
	match arac:
		"bagla":
			_bagla_tikla(p)
		"blok":
			surukle = "blok"
			_s_bas = miknatis(p, shift)
			hayalet = Rect2(_s_bas, Vector2.ZERO)
			hayalet_var = true
		"baslangic":
			baslangic_koy(miknatis(p, shift))
		"cikis":
			cikis_koy(miknatis(p, shift))
		"sec":
			var h := _tutamac_bul(p)
			if h >= 0:
				surukle = "boyut"
				_s_tutamac = h
				_s_alan0 = (_nesne(secili)["alan"] as Array).duplicate()
				_s_degisti = false
				return
			if secili != "" and parametre_tutamaci(secili).distance_to(p) <= TUTAMAC_YARICAPI + 2.0:
				surukle = "parametre"
				_s_degisti = false
				return
			var kab := BaglantiIslemleri.en_yakin(veri, p)
			var id := nesne_bul(p)
			var id_blok := id == "" or id == BASLANGIC_ID or id == CIKIS_ID or str(_nesne(id).get("tur", "")) == "blok"
			if not kab.is_empty() and (int(kab["nokta"]) >= 0 or id_blok):
				_kablo_tikla(kab, p, shift, cift_tik)
				return
			sec(id)
			if id != "":
				surukle = "tasi"
				_s_bas = p
				_s_orijinal = _sabit_nokta(id)
				_s_degisti = false
	katman.queue_redraw()


## Kablo üstüne basış: ara noktaya basılırsa taşınır (çift tık siler), parçaya basılırsa o noktada
## yeni ara nokta doğar ve sürüklenir.
func _kablo_tikla(kab: Dictionary, p: Vector2, shift: bool, cift_tik: bool) -> void:
	kablo_sec(kab["hedef"], kab["tetik"])
	if int(kab["nokta"]) >= 0:
		if cift_tik:
			# Otomatik L köşesi de ara noktadır: silmeden önce açık listeye çevrilir.
			BaglantiIslemleri.ara_ac(veri, kab["hedef"], kab["tetik"])
			ara_nokta_sil(kab["hedef"], kab["tetik"], int(kab["nokta"]))
			return
		_s_kablo_nokta = int(kab["nokta"])
	else:
		_s_kablo_nokta = -1   # parça: sürükleme başlayınca (3 px) yeni ara nokta doğar
	_s_bas = p
	_s_kablo_bekle = true
	_s_degisti = false
	surukle = "kablo"
	katman.queue_redraw()


## Bağla aracı: önce tetikleyici, sonra hedef.
func _bagla_tikla(p: Vector2) -> void:
	var id := nesne_bul(p)
	var n := _nesne(id)
	if n.is_empty():
		_mesaj("Bağla: önce bir plaka ya da şalteri, sonra hedefi (geçit, lazer, asansör) tıklayın")
		return
	var hedef := BaglantiIslemleri.hedef_mi(n)
	if bagla_kaynak == "" or (BaglantiIslemleri.tetikleyici_mi(n) and not hedef):
		if BaglantiIslemleri.tetikleyici_mi(n):
			bagla_kaynak = id
			sec(id)
			_mesaj("Kaynak: %s. Şimdi hedefi tıklayın (Esc: iptal)" % id)
		else:
			_mesaj("Bağla: önce bir plaka ya da şalter seçin")
		return
	if hedef:
		var kaynak := bagla_kaynak
		bagla_kaynak = ""
		bagla(kaynak, id)
	else:
		_mesaj("Bağla: hedef bir geçit, lazer ya da asansör olmalı")
	katman.queue_redraw()


## Sürükleme başındaki tutma noktası: blokta sol üst, işarette ayak, diğerlerinde konum.
func _sabit_nokta(id: String) -> Vector2:
	if id == BASLANGIC_ID:
		return _nokta(veri["baslangic"])
	if id == CIKIS_ID:
		return _nokta(veri["cikis"])
	var n := _nesne(id)
	if str(n["tur"]) == "blok":
		return Vector2(float(n["alan"][0]), float(n["alan"][1]))
	return _nokta(n["konum"])


func _fare_hareket(p: Vector2, shift: bool) -> void:
	imlec = miknatis(p, shift)
	imlec_var = true
	match surukle:
		"blok":
			var a := _s_bas
			var b := imlec
			hayalet = Rect2(minf(a.x, b.x), minf(a.y, b.y), absf(a.x - b.x), absf(a.y - b.y))
		"tasi":
			_surukle_tasi(p, shift)
		"boyut":
			_surukle_boyutla(p, shift)
		"kablo":
			_surukle_kablo(p, shift)
		"parametre":
			_surukle_parametre(p, shift)
	katman.queue_redraw()


func _surukle_tasi(p: Vector2, shift: bool) -> void:
	var hedef := _s_orijinal + (p - _s_bas)
	var yeni_nokta := miknatis(hedef, shift)
	var n := _nesne(secili)
	if not n.is_empty() and str(n["tur"]) == "blok":
		# Sağ/alt kenar da mıknatısa girebilsin: hangisi tuttuysa o düzeltme uygulanır.
		var boy := Vector2(float(n["alan"][2]), float(n["alan"][3]))
		var sag_alt := miknatis(hedef + boy, shift) - boy
		if sag_alt.distance_to(hedef) < yeni_nokta.distance_to(hedef):
			yeni_nokta = sag_alt
	var simdiki := _sabit_nokta(secili)
	var fark := yeni_nokta - simdiki
	if fark != Vector2.ZERO and _tasi_uygula(secili, fark):
		_s_degisti = true


func _surukle_boyutla(p: Vector2, shift: bool) -> void:
	var m := miknatis(p, shift)
	var sol := float(_s_alan0[0])
	var ust := float(_s_alan0[1])
	var sag := sol + float(_s_alan0[2])
	var alt := ust + float(_s_alan0[3])
	var h := _s_tutamac
	if h == 0 or h == 6 or h == 7:
		sol = minf(m.x, sag - EN_KUCUK_BOYUT)
	if h == 2 or h == 3 or h == 4:
		sag = maxf(m.x, sol + EN_KUCUK_BOYUT)
	if h == 0 or h == 1 or h == 2:
		ust = minf(m.y, alt - EN_KUCUK_BOYUT)
	if h == 4 or h == 5 or h == 6:
		alt = maxf(m.y, ust + EN_KUCUK_BOYUT)
	var n := _nesne(secili)
	var yeni_alan := [roundi(sol), roundi(ust), roundi(sag - sol), roundi(alt - ust)]
	if yeni_alan != n["alan"]:
		n["alan"] = yeni_alan
		_dugum_yenile(secili)
		_s_degisti = true


## Tek tık kabloyu yalnız seçer; veri 3 px sürüklenince değişir (parçada yeni nokta, noktada
## otomatik L açılır).
func _surukle_kablo(p: Vector2, shift: bool) -> void:
	if secili_kablo.size() != 2:
		return
	var h: String = secili_kablo[0]
	var t: String = secili_kablo[1]
	if _s_kablo_bekle:
		if p.distance_to(_s_bas) < 3.0:
			return
		_s_kablo_bekle = false
		if _s_kablo_nokta < 0:
			_s_kablo_nokta = BaglantiIslemleri.ara_ekle(veri, h, t, miknatis(_s_bas, shift))
			if _s_kablo_nokta < 0:
				return
		else:
			BaglantiIslemleri.ara_ac(veri, h, t)
		_s_degisti = true
	if _s_kablo_nokta >= 0 and BaglantiIslemleri.ara_tasi(veri, h, t, _s_kablo_nokta, miknatis(p, shift)):
		_s_degisti = true
	_dugum_yenile(h)


func _surukle_parametre(p: Vector2, shift: bool) -> void:
	var n := _nesne(secili)
	if n.is_empty():
		return
	var m := miknatis(p, shift)
	var k := _nokta(n["konum"])
	if str(n["tur"]) == "lazer":
		_surukle_lazer_ucu(n, m - k)
		return
	var deger := roundi(k.y - m.y) if str(n["tur"]) == "asansor" else roundi(k.y - 200.0 - m.y)
	if _parametre_uygula(n, deger):
		_s_degisti = true
		_ozellik_paneli_esitle()


## Lazer ucu yayıcıdan uzağa sürüklenir: baskın eksen yönü, o eksendeki uzaklık uzunluğu belirler.
func _surukle_lazer_ucu(n: Dictionary, v: Vector2) -> void:
	var yon := "asagi"
	var uz := v.y
	if absf(v.x) > absf(v.y):
		yon = "sag" if v.x >= 0.0 else "sol"
		uz = absf(v.x)
	else:
		yon = "asagi" if v.y >= 0.0 else "yukari"
		uz = absf(v.y)
	var yeni_uz := clampi(roundi(uz), 10, 1100)
	if str(n.get("yon", "asagi")) == yon and int(n.get("uzunluk", BolumKurucu.VARSAYILAN_UZUNLUK)) == yeni_uz:
		return
	n["yon"] = yon
	n["uzunluk"] = yeni_uz
	_dugum_yenile(str(n["id"]))
	_s_degisti = true
	_ozellik_paneli_esitle()


func _fare_birak(_p: Vector2, _shift: bool) -> void:
	match surukle:
		"blok":
			var r := hayalet
			hayalet_var = false
			if r.size.x >= 4.0 or r.size.y >= 4.0:   # tek tıklama blok üretmez
				var id := blok_ekle([r.position.x, r.position.y, r.size.x, r.size.y])
				if id != "":
					sec(id)
		"tasi", "boyut", "kablo", "parametre":
			if _s_degisti:
				_degisti()
	surukle = ""
	_s_degisti = false
	_s_kablo_bekle = false
	katman.queue_redraw()


func _sag_tik(p: Vector2) -> void:
	var id := nesne_bul(p)
	if id != "" and id != BASLANGIC_ID and id != CIKIS_ID:
		nesne_sil(id)


func _unhandled_key_input(e: InputEvent) -> void:
	if not (e is InputEventKey) or not e.pressed:
		return
	var k := e as InputEventKey
	if k.ctrl_pressed or k.meta_pressed:
		match k.keycode:
			KEY_Z:
				if k.shift_pressed:
					yinele()
				else:
					geri_al()
			KEY_Y:
				yinele()
			_:
				return
		get_viewport().set_input_as_handled()
		return
	var oklar := {KEY_LEFT: Vector2.LEFT, KEY_RIGHT: Vector2.RIGHT, KEY_UP: Vector2.UP, KEY_DOWN: Vector2.DOWN}
	if oklar.has(k.keycode):
		if secili != "":
			nesne_tasi(secili, oklar[k.keycode] * float(1 if k.shift_pressed else izgara_adimi(false)))
		get_viewport().set_input_as_handled()
		return
	if k.echo:
		return
	match k.keycode:
		KEY_DELETE:
			if secili != "" and secili != BASLANGIC_ID and secili != CIKIS_ID:
				nesne_sil(secili)
		KEY_B:
			if BaglantiIslemleri.tetikleyici_mi(_nesne(secili)):
				var kaynak := secili
				arac_sec("bagla")
				bagla_kaynak = kaynak
				_mesaj("Kaynak: %s. Şimdi hedefi tıklayın (Esc: iptal)" % kaynak)
		KEY_ESCAPE:
			if bagla_kaynak == "":
				return
			bagla_kaynak = ""
			_durum_guncelle()
			katman.queue_redraw()
		KEY_G:
			izgara_ac_kapa(not izgara_acik)
		KEY_H:
			ust_cubuk.visible = not ust_cubuk.visible
			durum_cubugu.visible = ust_cubuk.visible
		KEY_F5:
			dene_baslat()
		KEY_F6:
			dogrula_baslat()
		KEY_TAB:
			palet.visible = not palet.visible
		_:
			return
	get_viewport().set_input_as_handled()


## Tab, viewport'ta `ui_focus_next` olarak tüketilmeden yakalanır (paleti gizler/gösterir).
func _input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_TAB:
		palet.visible = not palet.visible
		get_viewport().set_input_as_handled()
