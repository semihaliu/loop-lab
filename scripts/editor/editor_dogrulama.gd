class_name EditorDogrulama
extends CanvasLayer
## Oyun içi "Doğrula" akışı (taslak §6.4). Doğrulama bölüm sahnesini defalarca yeniden yüklediği için
## editör sahnesi ortadan kalkar; bu düğüm `root` altında yaşar, ilerleme şeridini kendi katmanında
## gösterir, işi bitirince sonucu `EditorOturumu.dogrulama`'ya yazar ve editör sahnesine döner
## (editör `_oturumdan_yukle`'de sonucu `veri["dogrulama"]`ya işler).
## İptal (Esc ya da İptal düğmesi): hiçbir şey yazılmaz, `Kayitlar` boşaltılır, editöre dönülür.
## Başka betik/sahne preload edilmez (lazer.tscn önbellek kuralı).

const EDITOR_SAHNESI := "res://scenes/editor.tscn"
## "Tuşlara basmayın" uyarısı: koyu panelde WCAG AA (>= 4,5:1) kontrast için amber (eski METAL ~3,3:1 idi).
const UYARI_RENGI := LabPaleti.AMBER

var veri: Dictionary = {}
var sahne_yolu: String = ""
var dogrulayici: CozumDogrulayici
## Ekrandaki şerit (testler okur).
var serit: ProgressBar
var etiket: Label
var iptal_dugmesi: Button

var _iptal_istendi := false
var _ilk_bitis := -1


func _init() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Her fizik karesinde oyun düğümlerinden ÖNCE çalışır (en düşük öncelik değeri).
	process_physics_priority = -2147483648


## Doğrulama sürerken gerçek T (baştan başla) ve R (turu bitir) basışı oynatmayı bozmasın.
func _physics_process(_delta: float) -> void:
	Input.action_release("bastan")
	Input.action_release("tur_bitir")


## Ağaca eklendikten sonra çağrılır: arayüzü kurar ve doğrulamayı başlatır (await edilmez; sonuçta sahne değişir).
func baslat(v: Dictionary, yol: String) -> void:
	veri = v
	sahne_yolu = yol
	_arayuz_kur()
	_calistir()


func iptal_et() -> void:
	if _iptal_istendi:
		return
	_iptal_istendi = true
	if etiket != null:
		etiket.text = "İptal ediliyor…"
	if dogrulayici != null:
		dogrulayici.iptal()


## Doğrulama sürerken bütün klavye olayları burada tüketilir (Esc iptal eder); sonuç ekranının
## düğmesi (Enter/Boşluk) ya da oyunun kısayolları oynatmaya karışmaz. Not: `Input` eylem durumu olay
## dağıtımından önce güncellendiği için yön/zıplama tuşlarının kendisi engellenemez; panel uyarır.
func _input(e: InputEvent) -> void:
	if not (e is InputEventKey):
		return
	if e.pressed and not e.echo and e.keycode == KEY_ESCAPE:
		iptal_et()
	get_viewport().set_input_as_handled()


func _arayuz_kur() -> void:
	var kok := Control.new()
	kok.name = "Kok"
	kok.mouse_filter = Control.MOUSE_FILTER_STOP   # doğrulama sürerken alttaki oyun tıklanmasın
	kok.theme = LabTema.olustur()
	add_child(kok)
	kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var koyu := ColorRect.new()
	koyu.color = Color(0, 0, 0, 0.6)
	koyu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	koyu.anchor_right = 1.0
	koyu.anchor_bottom = 1.0
	kok.add_child(koyu)
	var orta := CenterContainer.new()
	orta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kok.add_child(orta)
	orta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(420, 0)
	var stil := StyleBoxFlat.new()
	stil.bg_color = Color(LabPaleti.DUVAR, 0.95)
	stil.border_color = LabPaleti.CAMGOBEGI
	stil.set_border_width_all(1)
	stil.set_content_margin_all(14.0)
	panel.add_theme_stylebox_override("panel", stil)
	orta.add_child(panel)
	var kutu := VBoxContainer.new()
	kutu.add_theme_constant_override("separation", 8)
	panel.add_child(kutu)
	etiket = Label.new()
	etiket.name = "Etiket"
	etiket.text = "Doğrulanıyor…"
	kutu.add_child(etiket)
	var uyari := Label.new()
	uyari.name = "Uyari"
	uyari.text = "Doğrulama sürerken tuşlara basmayın."
	uyari.add_theme_color_override("font_color", UYARI_RENGI)
	kutu.add_child(uyari)
	serit = ProgressBar.new()
	serit.name = "Serit"
	serit.min_value = 0.0
	serit.max_value = 1.0
	serit.value = 0.0
	serit.custom_minimum_size = Vector2(0, 18)
	kutu.add_child(serit)
	iptal_dugmesi = Button.new()
	iptal_dugmesi.name = "IptalDugmesi"
	iptal_dugmesi.text = "İptal (Esc)"
	iptal_dugmesi.focus_mode = Control.FOCUS_NONE
	iptal_dugmesi.pressed.connect(iptal_et)
	kutu.add_child(iptal_dugmesi)


func _ilerleme(adim: int, toplam: int, aciklama: String) -> void:
	if serit != null:
		serit.max_value = float(maxi(toplam, 1))
		serit.value = float(adim - 1)
	if etiket != null and not _iptal_istendi:
		etiket.text = "Doğrulanıyor %d/%d: %s" % [adim, toplam, aciklama]


func _oynatma_bitti(sonuc: Dictionary) -> void:
	# İlk çözüm koşusunun bitiş karesi kayda geçer (taslak §1.1 `bitis_kare`).
	if _ilk_bitis < 0 and bool(sonuc.get("bitti", false)):
		_ilk_bitis = int(sonuc.get("bitis_kare", -1))


func _calistir() -> void:
	dogrulayici = CozumDogrulayici.new()
	dogrulayici.name = "CozumDogrulayici"
	add_child(dogrulayici)
	dogrulayici.ilerleme.connect(_ilerleme)
	dogrulayici.bitti.connect(_oynatma_bitti)
	# Doğrulayıcının fizik karesi işlemesi için bir process + bir physics karesi bekle.
	await get_tree().process_frame
	await get_tree().physics_frame
	var statik: Array = BolumDenetci.statik(veri)
	# `toplu_basla` iptal bayrağını sıfırlar: bekleme sırasında gelen iptal burada yakalanır.
	var dinamik: Array = []
	if not _iptal_istendi:
		dinamik = await BolumDenetci.dinamik(veri, dogrulayici, sahne_yolu)
	var kayitlar := get_node_or_null("/root/Kayitlar")
	if kayitlar != null:
		kayitlar.sifirla()
	var sonuc := {"iptal": _iptal_istendi}
	if not _iptal_istendi:
		var tum: Array = statik + dinamik
		var ozet: Dictionary = BolumDenetci.ozet(tum)
		var din_hata := 0
		for s in dinamik:
			if str(s.get("seviye", "")) == "HATA":
				din_hata += 1
		sonuc["hata"] = din_hata
		sonuc["uyari"] = int(ozet["uyari"])
		sonuc["bitis_kare"] = _ilk_bitis
		sonuc["durum"] = "dogrulandi" if din_hata == 0 and _ilk_bitis >= 0 else "taslak"
		sonuc["sorunlar"] = dinamik
	EditorOturumu.dogrulama = sonuc
	EditorOturumu.donus = true
	get_tree().change_scene_to_file(EDITOR_SAHNESI)
	queue_free()
