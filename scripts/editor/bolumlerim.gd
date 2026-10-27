class_name Bolumlerim
extends Control
## Bölümlerim ekranı (taslak §8.1, A10): `<kok>bolumler/*.json` listesi; her satırda ad, doğrulama durumu,
## uyarı sayısı ve Aç / Oyna / Sil düğmeleri. Sıra dosya adına göredir (deterministik).
## "Oyna": bölüm `<kok>oyna/oyna_NNN.tscn` olarak kurulur; çözümsüz bölüm uyarıyla oynanır (S4),
## statik HATA'lı bölüm oynanmaz.
## A12: Canlıya al (sıra seçilir; çözümsüzse önce uyarı onayı) / Canlıdan kaldır / Canlıyı güncelle
## (`CanliBolumler`); canlı bölümün satırında "Canlı: Bölüm N" yazar.
## Oyun fiziğine dokunmaz; ana menü bu sınıfa başvurmaz (yalnız sahne yolu), lazer önbellek kuralı korunur.

const EDITOR_SAHNESI := "res://scenes/editor.tscn"
## Panel genişliği: iki satırlı satırda 40 karakterlik ad ve düğmeler sığsın.
const PANEL_GENISLIK := 900
const BASLIK_ONAY := "Onayla"
const BASLIK_UYARI := "Uyarı"
const SIL_SORUSU := "Bu bölüm kalıcı olarak silinecek. Devam edilsin mi?"
const SIRA_ACIKLAMASI := "Canlı bölüm, seçtiğiniz bölümden hemen sonra gelir; sonraki bölümlerin numarası bir artar."
const COZUM_UYARISI := "Çözüm doğrulanmadı, yine de ekleyeyim mi?"
const KALDIR_SORUSU := "Bu bölüm oyundan kaldırılacak (Bölümlerim'deki kopya kalır); sonraki bölümlerin numarası geri kayar. Devam edilsin mi?"
const GUNCELLE_SORUSU := "Oyundaki canlı kopya Bölümlerim'deki güncel içerikle değiştirilecek. Devam edilsin mi?"

## Dosya kökü; testler "user://test_editor/" yazar.
var kok: String = BolumYollari.VARSAYILAN_KOK
## Son `yenile()` sonucu: dosya adına göre sıralı satır sözlükleri.
var kayitlar: Array[Dictionary] = []
var durum_mesaji: String = ""
## Ekrandaki düğümler (testler okur).
var liste_kutusu: VBoxContainer
var durum_etiketi: Label
var onay_diyalogu: ConfirmationDialog
var uyari_diyalogu: ConfirmationDialog
var sira_diyalogu: ConfirmationDialog
var sira_secici: OptionButton
var sira_aciklama: Label
## Onay diyaloğunun amacı: "sil" | "kaldir" | "guncelle".
var _onay_modu: String = "sil"
var _silinecek: String = ""
## Canlıya alma akışında bekleyen bölüm dosyası.
var _canli_dosya: String = ""
var _sira_secenekleri: Array = []
var _kuruldu := false


func _ready() -> void:
	if EditorOturumu.kok != "":
		kok = EditorOturumu.kok
	_arayuz_kur()
	yenile()


# --- Veri -------------------------------------------------------------------------------------

## Kök altındaki bölüm JSON'larını okuyup satırlara çevirir. Satır: {"dosya", "yol", "ad", "kimlik",
## "bozuk" (okunamadı ya da şema HATA'sı), "hata_metni", "durum" ("Doğrulandı" | "Taslak (...)" | "Bozuk"),
## "uyari" (statik uyarı sayısı), "hata" (statik HATA sayısı), "oynanabilir", "cozumsuz"}.
static func tara(kok_dizin: String) -> Array[Dictionary]:
	var cikti: Array[Dictionary] = []
	var dizin := BolumYollari.bolumler_dizini(kok_dizin)
	var adlar: Array = []
	for f in DirAccess.get_files_at(dizin):
		if f.ends_with(".json"):
			adlar.append(f)
	adlar.sort()
	var birlesik := BolumListesi.olustur(kok_dizin)
	var sira := CanliBolumler.sira_oku(kok_dizin)
	for f in adlar:
		var s := _satir(dizin + f, f)
		_canli_bilgisi(s, kok_dizin, birlesik, sira)
		cikti.append(s)
	return cikti


## Satıra canlı bilgisi ekler: "canli" (bool), "canli_no" (oyundaki numara, 0 = canlı değil),
## "canli_degisti" (Bölümlerim'deki içerik ya da çözüm durumu canlı kopyadan farklı).
static func _canli_bilgisi(s: Dictionary, kok_dizin: String, birlesik: Array, sira: Array) -> void:
	s["canli"] = false
	s["canli_no"] = 0
	s["canli_degisti"] = false
	for k in sira:
		if k["kimlik"] != s["kimlik"]:
			continue
		var yol := BolumYollari.canli_dizini(kok_dizin) + str(k["sahne"])
		s["canli"] = true   # kayıt sira.json'da varsa canlıdır; listede yoksa (sahne dosyası eksik, sınır) canli_no 0 kalır
		for i in birlesik.size():
			if birlesik[i]["yol"] == yol:
				s["canli"] = true
				s["canli_no"] = i + 1
		if bool(s["bozuk"]):
			return
		var veri: Dictionary = BolumVerisi.oku(str(s["yol"]))["veri"]
		s["canli_degisti"] = bool(s["canli"]) and not veri.is_empty() \
			and (str(k["icerik_ozeti"]) != BolumVerisi.icerik_ozeti(veri) or bool(k["cozum_yok"]) != bool(s["cozumsuz"]))
		return


static func _satir(yol: String, dosya: String) -> Dictionary:
	var s := {"dosya": dosya, "yol": yol, "ad": dosya.get_basename(), "kimlik": dosya.get_basename(),
		"bozuk": true, "hata_metni": "", "durum": "Bozuk", "uyari": 0, "hata": 0, "oynanabilir": false, "cozumsuz": true}
	var sonuc := BolumVerisi.oku(yol)
	var veri: Dictionary = sonuc["veri"]
	var sorunlar: Array = sonuc["sorunlar"]
	if veri.is_empty():
		s["hata_metni"] = str(sorunlar[0]["mesaj"]) if sorunlar.size() > 0 else "okunamadı"
		return s
	for o in sorunlar:   # oku()'nun şema HATA'sı: veri güvenilmez, başka hiçbir şey okunmaz
		if str(o.get("seviye", "")) == "HATA":
			s["hata_metni"] = str(o.get("mesaj", ""))
			return s
	var denetim: Array = BolumDenetci.statik(veri)   # şema HATA'sı varsa yalnız şema sorunları döner
	var ozet: Dictionary = BolumDenetci.ozet(denetim)
	s["ad"] = str(veri.get("ad", s["ad"]))
	s["kimlik"] = str(veri.get("kimlik", s["kimlik"]))
	s["uyari"] = int(ozet["uyari"])
	s["hata"] = int(ozet["hata"])
	s["durum"] = BolumVerisi.dogrulama_durumu(veri)
	s["cozumsuz"] = s["durum"] != "Doğrulandı"
	for o in denetim:
		if str(o.get("seviye", "")) == "HATA":
			s["hata_metni"] = str(o.get("mesaj", ""))
			break
	s["bozuk"] = false
	s["oynanabilir"] = int(ozet["hata"]) == 0
	return s


# --- Eylemler (düğmeler ve testler aynı yolu kullanır) ------------------------------------------

## Listeyi diskten yeniden okur ve satırları çizer.
func yenile() -> void:
	kayitlar = tara(kok)
	_listeyi_ciz()


## Satırı dosya adından bulur ({} = yok).
func satir(dosya: String) -> Dictionary:
	for k in kayitlar:
		if k["dosya"] == dosya:
			return k
	return {}


## Bölümü editörde açar (şema HATA'lı dosya açılmaz). Dönüş: sahne değişimi başlatıldı mı.
func ac(dosya: String) -> bool:
	var k := satir(dosya)
	if k.is_empty():
		return false
	if bool(k["bozuk"]):
		_mesaj("Açılamadı: %s" % str(k["hata_metni"]))
		return false
	Kayitlar.sifirla()
	EditorOturumu.temizle()
	EditorOturumu.ac_yolu = str(k["yol"])
	EditorOturumu.kok = kok
	get_tree().change_scene_to_file(EDITOR_SAHNESI)
	return true


## Bölümü `oyna/oyna_NNN.tscn` olarak kurup açar. Statik HATA varsa oynanmaz; çözümsüzlük engel değildir
## (S4, HUD uyarı satırı gösterir). Dönüş: sahne değişimi başlatıldı mı.
func oyna(dosya: String) -> bool:
	var k := satir(dosya)
	if k.is_empty():
		return false
	if not bool(k["oynanabilir"]):
		_mesaj("Oynanamaz: %s" % str(k["hata_metni"]))
		return false
	var sonuc := BolumVerisi.oku(str(k["yol"]))
	var veri: Dictionary = sonuc["veri"]
	if veri.is_empty():
		_mesaj("Oynanamaz: dosya okunamadı")
		return false
	var yol := BolumKurucu.yeni_gecici_yol(BolumYollari.oyna_dizini(kok), "oyna")
	var h := BolumKurucu.sahneye_kaydet(veri, yol)
	if h != OK:
		_mesaj("Oynanamadı (hata %d)" % h)
		return false
	Kayitlar.sifirla()
	EditorOturumu.temizle()
	EditorOturumu.kok = kok   # oyundan dönüşte Bölümlerim aynı kökü okusun
	get_tree().change_scene_to_file(yol)
	return true


## Silme için onay ister (diyalog "Evet" → `sil_onayla`).
func sil_iste(dosya: String) -> void:
	if satir(dosya).is_empty():
		return
	if bool(satir(dosya)["canli"]):
		_mesaj("Canlı bölüm silinemez: önce \"Canlıdan kaldır\" ile oyundan çıkarın")
		return
	_onay_ac("sil", dosya, SIL_SORUSU + "\n" + str(satir(dosya)["ad"]))


## Ortak onay diyaloğunu açar (sil / kaldır / güncelle).
func _onay_ac(mod: String, dosya: String, metin: String) -> void:
	_onay_modu = mod
	_silinecek = dosya
	onay_diyalogu.dialog_text = metin
	if onay_diyalogu.is_inside_tree():
		onay_diyalogu.popup_centered()


## Onay düğmesi: amaca göre silme, kaldırma ya da güncelleme.
func _onay_verildi() -> void:
	match _onay_modu:
		"kaldir":
			var dosya := _silinecek
			_silinecek = ""
			onay_diyalogu.hide()
			canli_kaldir(dosya)
		"guncelle":
			var dosya2 := _silinecek
			_silinecek = ""
			onay_diyalogu.hide()
			canli_guncelle(dosya2)
		_:
			sil_onayla()


## Onay verildi: bekleyen dosya silinir. Dönüş: silindi mi.
func sil_onayla() -> bool:
	var dosya := _silinecek
	_silinecek = ""
	if onay_diyalogu != null:
		onay_diyalogu.hide()
	if dosya == "" or satir(dosya).is_empty():
		return false
	var h := DirAccess.remove_absolute(str(satir(dosya)["yol"]))
	if h != OK:
		_mesaj("Silinemedi (hata %d)" % h)
		return false
	_mesaj("Silindi: %s" % dosya)
	yenile()
	return true


func sil_iptal() -> void:
	_silinecek = ""
	if onay_diyalogu != null:
		onay_diyalogu.hide()


# --- Canlıya al / kaldır / güncelle (A12) -----------------------------------------------------------

## Satırın bölüm verisi (okunamazsa {}).
func _veri(dosya: String) -> Dictionary:
	var k := satir(dosya)
	if k.is_empty():
		return {}
	return BolumVerisi.oku(str(k["yol"]))["veri"]


## "Canlıya al" düğmesi: statik HATA engeller; çözüm doğrulanmadıysa önce uyarı onayı, sonra sıra seçimi.
## Dönüş: akış başlatıldı mı.
func canli_iste(dosya: String) -> bool:
	var k := satir(dosya)
	if k.is_empty():
		return false
	if bool(k["bozuk"]) or not bool(k["oynanabilir"]):
		_mesaj("Canlıya alınamaz: %s" % str(k["hata_metni"]))
		return false
	if bool(k["canli"]):
		_mesaj("Bu bölüm zaten canlı (Bölüm %d); güncellemek için \"Canlıyı güncelle\"" % int(k["canli_no"]))
		return false
	_canli_dosya = dosya
	if bool(k["cozumsuz"]):
		uyari_diyalogu.dialog_text = COZUM_UYARISI + "\n" + str(k["ad"])
		if uyari_diyalogu.is_inside_tree():
			uyari_diyalogu.popup_centered()
	else:
		canli_sira_ac()
	return true


## Çözüm uyarısına "Evet": sıra seçimine geçer.
func canli_uyari_onayla() -> void:
	uyari_diyalogu.hide()
	canli_sira_ac()


## Çözüm uyarısına ya da sıra seçimine "İptal": akış biter.
func canli_iptal() -> void:
	_canli_dosya = ""
	if uyari_diyalogu != null:
		uyari_diyalogu.hide()
	if sira_diyalogu != null:
		sira_diyalogu.hide()


## Sıra seçim diyaloğunu doldurur ve açar; varsayılan seçim "en sondaki bölümden sonra".
func canli_sira_ac() -> void:
	_sira_secenekleri = CanliBolumler.sira_secenekleri(kok)
	sira_secici.clear()
	for o in _sira_secenekleri:
		sira_secici.add_item(str(o["etiket"]))
	sira_secici.select(_sira_secenekleri.size() - 1)
	if sira_diyalogu.is_inside_tree():
		sira_diyalogu.popup_centered()


## Sıra seçicide `i`. seçeneği seçer (testler ve düğme aynı yolu kullanır).
func canli_sira_sec(i: int) -> void:
	if i >= 0 and i < _sira_secenekleri.size():
		sira_secici.select(i)


## Sıra diyaloğuna "Canlıya al": seçili yere canlıya alır. Dönüş: başarılı mı.
func canli_onayla() -> bool:
	var dosya := _canli_dosya
	var secim := sira_secici.selected
	_canli_dosya = ""
	sira_diyalogu.hide()
	if dosya == "" or secim < 0 or secim >= _sira_secenekleri.size():
		return false
	return canliya_al(dosya, str(_sira_secenekleri[secim]["sonra"]))


## Bölümü `sonra` konumuna canlıya alır (diyalog gerektirmez). Dönüş: başarılı mı.
func canliya_al(dosya: String, sonra: String) -> bool:
	var veri := _veri(dosya)
	if veri.is_empty():
		_mesaj("Canlıya alınamadı: dosya okunamadı")
		return false
	var sorunlar := CanliBolumler.canliya_al(veri, sonra, kok)
	if not sorunlar.is_empty():
		_mesaj("Canlıya alınamadı: %s" % str(sorunlar[0]["mesaj"]))
		return false
	yenile()
	_mesaj("Canlıya alındı: Bölüm %d · %s" % [int(satir(dosya)["canli_no"]), str(veri.get("ad", ""))])
	return true


## "Canlıdan kaldır" düğmesi: onay ister.
func kaldir_iste(dosya: String) -> void:
	if satir(dosya).is_empty() or not bool(satir(dosya)["canli"]):
		return
	_onay_ac("kaldir", dosya, KALDIR_SORUSU + "\n" + str(satir(dosya)["ad"]))


## Canlıdan kaldırır; numaralar geri kayar. Dönüş: başarılı mı.
func canli_kaldir(dosya: String) -> bool:
	var k := satir(dosya)
	if k.is_empty() or not bool(k["canli"]):
		return false
	var h := CanliBolumler.kaldir(str(k["kimlik"]), kok)
	if h != OK:
		_mesaj("Canlıdan kaldırılamadı (hata %d)" % h)
		return false
	yenile()
	_mesaj("Canlıdan kaldırıldı: %s" % str(k["ad"]))
	return true


## "Canlıyı güncelle" düğmesi: onay ister (çözüm doğrulanmadıysa metin uyarır).
func guncelle_iste(dosya: String) -> void:
	var k := satir(dosya)
	if k.is_empty() or not bool(k["canli"]):
		return
	var metin := GUNCELLE_SORUSU
	if bool(k["cozumsuz"]):
		metin = COZUM_UYARISI + "\n" + metin
	_onay_ac("guncelle", dosya, metin + "\n" + str(k["ad"]))


## Canlı kopyayı günceller (Y1). Dönüş: başarılı mı.
func canli_guncelle(dosya: String) -> bool:
	var k := satir(dosya)
	var veri := _veri(dosya)
	if k.is_empty() or veri.is_empty() or not bool(k["canli"]):
		return false
	var sorunlar := CanliBolumler.guncelle(veri, kok)
	if not sorunlar.is_empty():
		_mesaj("Güncellenemedi: %s" % str(sorunlar[0]["mesaj"]))
		return false
	yenile()
	_mesaj("Canlı kopya güncellendi: Bölüm %d · %s" % [int(satir(dosya)["canli_no"]), str(veri.get("ad", ""))])
	return true


## Boş editör açar.
func yeni_bolum() -> void:
	Kayitlar.sifirla()
	EditorOturumu.temizle()
	EditorOturumu.kok = kok
	get_tree().change_scene_to_file(EDITOR_SAHNESI)


func ana_menuye_don() -> void:
	Kayitlar.sifirla()
	EditorOturumu.temizle()
	get_tree().change_scene_to_file(BolumYollari.MENU_SAHNESI)


# --- Arayüz ---------------------------------------------------------------------------------------

func _mesaj(m: String) -> void:
	durum_mesaji = m
	if durum_etiketi != null:
		durum_etiketi.text = m


## Satırdaki özet metin: "Ad · Doğrulandı · 2 uyarı".
static func satir_metni(k: Dictionary) -> String:
	return "%s · %s" % [k["ad"], durum_metni(k)]


## Satırın ikinci satırı: durum, canlı bilgisi, hata ve uyarı sayısı (kırpılmaz, gerekirse alt satıra sarar).
static func durum_metni(k: Dictionary) -> String:
	if bool(k["bozuk"]):
		return "Bozuk: %s" % k["hata_metni"]
	var m := str(k["durum"])
	if bool(k.get("canli", false)):
		m += " · Canlı: Bölüm %d" % int(k["canli_no"]) if int(k["canli_no"]) > 0 else " · Canlı: listede değil (sahne dosyası eksik)"
		if bool(k.get("canli_degisti", false)):
			m += " (değişti)"
	if int(k["hata"]) > 0:
		m += " · %d hata" % int(k["hata"])
	if int(k["uyari"]) > 0:
		m += " · %d uyarı" % int(k["uyari"])
	return m


func _arayuz_kur() -> void:
	if _kuruldu:
		return
	_kuruldu = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = LabTema.olustur()
	var arka := LabArkaplani.new()
	arka.name = "LabArkaplani"
	add_child(arka)
	var ortala := CenterContainer.new()
	ortala.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ortala)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(PANEL_GENISLIK, 520)
	panel.add_theme_stylebox_override("panel", LabTema.panel_stili())
	ortala.add_child(panel)
	var kutu := VBoxContainer.new()
	kutu.add_theme_constant_override("separation", 10)
	panel.add_child(kutu)
	var baslik := Label.new()
	baslik.text = "Bölümlerim"
	baslik.add_theme_font_size_override("font_size", 32)
	baslik.add_theme_color_override("font_color", LabPaleti.CAMGOBEGI.lightened(0.45))
	kutu.add_child(baslik)
	var kaydirma := ScrollContainer.new()
	kaydirma.name = "Kaydirma"
	kaydirma.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kaydirma.custom_minimum_size = Vector2(0, 360)
	kaydirma.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	kutu.add_child(kaydirma)
	liste_kutusu = VBoxContainer.new()
	liste_kutusu.name = "Liste"
	liste_kutusu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	liste_kutusu.add_theme_constant_override("separation", 6)
	kaydirma.add_child(liste_kutusu)
	durum_etiketi = Label.new()
	durum_etiketi.name = "Durum"
	durum_etiketi.add_theme_color_override("font_color", LabPaleti.AMBER)
	kutu.add_child(durum_etiketi)
	var alt := HBoxContainer.new()
	alt.add_theme_constant_override("separation", 8)
	kutu.add_child(alt)
	var yeni_d := Button.new()
	yeni_d.name = "YeniDugmesi"
	yeni_d.text = "Yeni bölüm"
	yeni_d.pressed.connect(yeni_bolum)
	alt.add_child(yeni_d)
	var menu_d := Button.new()
	menu_d.name = "MenuDugmesi"
	menu_d.text = "Ana menü"
	menu_d.pressed.connect(ana_menuye_don)
	alt.add_child(menu_d)
	onay_diyalogu = ConfirmationDialog.new()
	onay_diyalogu.name = "OnayDiyalogu"
	onay_diyalogu.title = BASLIK_ONAY
	onay_diyalogu.dialog_text = SIL_SORUSU
	onay_diyalogu.ok_button_text = "Evet"
	onay_diyalogu.cancel_button_text = "İptal"
	onay_diyalogu.confirmed.connect(_onay_verildi)
	onay_diyalogu.canceled.connect(sil_iptal)
	add_child(onay_diyalogu)
	uyari_diyalogu = ConfirmationDialog.new()
	uyari_diyalogu.name = "UyariDiyalogu"
	uyari_diyalogu.title = BASLIK_UYARI
	uyari_diyalogu.dialog_text = COZUM_UYARISI
	uyari_diyalogu.ok_button_text = "Evet"
	uyari_diyalogu.cancel_button_text = "İptal"
	uyari_diyalogu.confirmed.connect(canli_uyari_onayla)
	uyari_diyalogu.canceled.connect(canli_iptal)
	add_child(uyari_diyalogu)
	sira_diyalogu = ConfirmationDialog.new()
	sira_diyalogu.name = "SiraDiyalogu"
	sira_diyalogu.title = "Hangi bölümden sonra?"
	sira_diyalogu.ok_button_text = "Canlıya al"
	sira_diyalogu.cancel_button_text = "İptal"
	# İçerik tek bir kapta: açıklama üstte, seçici altında (OptionButton doğrudan çocuk olursa dialog_text'i örter).
	var sira_icerik := VBoxContainer.new()
	sira_icerik.name = "SiraIcerik"
	sira_icerik.add_theme_constant_override("separation", 10)
	sira_aciklama = Label.new()
	sira_aciklama.name = "SiraAciklama"
	sira_aciklama.text = SIRA_ACIKLAMASI
	sira_aciklama.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sira_aciklama.custom_minimum_size = Vector2(460, 0)
	sira_icerik.add_child(sira_aciklama)
	sira_secici = OptionButton.new()
	sira_secici.name = "SiraSecici"
	sira_icerik.add_child(sira_secici)
	sira_diyalogu.add_child(sira_icerik)
	sira_diyalogu.confirmed.connect(canli_onayla)
	sira_diyalogu.canceled.connect(canli_iptal)
	add_child(sira_diyalogu)


func _listeyi_ciz() -> void:
	if liste_kutusu == null:
		return
	for c in liste_kutusu.get_children():
		liste_kutusu.remove_child(c)
		c.queue_free()
	if kayitlar.is_empty():
		var bos := Label.new()
		bos.name = "Bos"
		bos.text = "(kayıtlı bölüm yok; \"Yeni bölüm\" ile başlayın)"
		liste_kutusu.add_child(bos)
		return
	for k in kayitlar:
		var satir_kutusu := HBoxContainer.new()
		satir_kutusu.name = "Satir_" + str(k["dosya"]).get_basename()
		satir_kutusu.add_theme_constant_override("separation", 6)
		var sorunlu: bool = bool(k["bozuk"]) or int(k["hata"]) > 0
		var bilgi := VBoxContainer.new()
		bilgi.name = "Bilgi"
		bilgi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bilgi.add_theme_constant_override("separation", 0)
		var et := Label.new()   # üst satır: ad (uzunsa "…" ile kısalır, tam metin ipucunda)
		et.name = "Metin"
		et.text = str(k["ad"])
		et.tooltip_text = satir_metni(k)
		et.mouse_filter = Control.MOUSE_FILTER_PASS
		et.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if sorunlu:
			et.add_theme_color_override("font_color", LabPaleti.AMBER)
		bilgi.add_child(et)
		var dt := Label.new()   # alt satır: durum, canlı bilgisi, hata/uyarı (kırpılmaz, sarar)
		dt.name = "DurumSatiri"
		dt.text = durum_metni(k)
		dt.tooltip_text = satir_metni(k)
		dt.mouse_filter = Control.MOUSE_FILTER_PASS
		dt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dt.add_theme_font_size_override("font_size", 14)
		dt.add_theme_color_override("font_color", LabPaleti.AMBER if sorunlu else LabPaleti.METAL_ACIK)
		bilgi.add_child(dt)
		satir_kutusu.add_child(bilgi)
		var dosya: String = k["dosya"]
		_satir_dugmesi(satir_kutusu, "AcDugmesi", "Aç", ac.bind(dosya), bool(k["bozuk"]))
		_satir_dugmesi(satir_kutusu, "OynaDugmesi", "Oyna", oyna.bind(dosya), not bool(k["oynanabilir"]))
		if bool(k["canli"]):
			_satir_dugmesi(satir_kutusu, "GuncelleDugmesi", "Canlıyı güncelle", guncelle_iste.bind(dosya), not bool(k["canli_degisti"]))
			_satir_dugmesi(satir_kutusu, "KaldirDugmesi", "Canlıdan kaldır", kaldir_iste.bind(dosya), false)
		else:
			_satir_dugmesi(satir_kutusu, "CanliDugmesi", "Canlıya al", canli_iste.bind(dosya), not bool(k["oynanabilir"]))
		_satir_dugmesi(satir_kutusu, "SilDugmesi", "Sil", sil_iste.bind(dosya), false)
		liste_kutusu.add_child(satir_kutusu)


func _satir_dugmesi(kutu: Control, ad: String, metin: String, islem: Callable, kapali: bool) -> void:
	var d := Button.new()
	d.name = ad
	d.text = metin
	d.disabled = kapali
	d.focus_mode = Control.FOCUS_NONE
	d.pressed.connect(func() -> void: islem.call())
	kutu.add_child(d)
