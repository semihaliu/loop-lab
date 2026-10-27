extends CanvasLayer
## Bölüm sonu ekranı: süre, tur sayısı, "Sonraki bölüm" (son bölümde gizli), "Tekrar oyna" ve "Menüye dön".
## process_mode = ALWAYS olduğu için simülasyon durmuşken (paused) butonlar çalışır.

const MENU_SAHNESI := "res://scenes/ana_menu.tscn"

const EDITOR_SAHNESI := "res://scenes/editor.tscn"
const EDITOR_OTURUMU_YOLU := "res://scripts/editor/editor_oturumu.gd"

var sonraki_yol := ""
## Editörden "Dene" ile açılan geçici bölüm mü (resmî yolda hep false).
var dene_kipi := false
## Bölümlerim'den "Oyna" ile açılan özel bölüm mü.
var ozel_kipi := false
var cozum_dugmesi: Button

@onready var sure_etiketi: Label = %SureEtiketi
@onready var tur_etiketi: Label = %TurEtiketi
@onready var sonraki_dugmesi: Button = %SonrakiDugmesi
@onready var tekrar_dugmesi: Button = %TekrarDugmesi
@onready var menu_dugmesi: Button = %MenuDugmesi


func _ready() -> void:
	# Görünüm (yalnızca görsel): ortak tema ve kutunun arkasında panel.
	$Ortala.theme = LabTema.olustur()
	var panel := Panel.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(400, 400)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", LabTema.panel_stili())
	$Ortala.add_child(panel)
	$Ortala.move_child(panel, 0)
	$Ortala/Kutu/Baslik.add_theme_color_override("font_color", LabPaleti.YESIL)
	sonraki_dugmesi.pressed.connect(_on_sonraki)
	tekrar_dugmesi.pressed.connect(_on_tekrar)
	menu_dugmesi.pressed.connect(_on_menu)
	# Sonuç ekranı bölüm sahnesinin çocuğudur; sonraki bölüm listeden bulunur.
	sonraki_yol = BolumListesi.sonraki(get_parent().scene_file_path)
	sonraki_dugmesi.visible = sonraki_yol != ""
	dene_kipi = BolumYollari.dene_mi(get_parent().scene_file_path)
	ozel_kipi = BolumYollari.ozel_mi(get_parent().scene_file_path)
	if dene_kipi:
		_dene_dugmelerini_kur()
	elif ozel_kipi:
		# Özel bölümde "Sonraki" yok; "Menü" Bölümlerim'e döner (taslak §5.3).
		sonraki_dugmesi.visible = false
		menu_dugmesi.text = "Bölümlerim'e dön"
		tekrar_dugmesi.grab_focus()
	elif sonraki_dugmesi.visible:
		sonraki_dugmesi.grab_focus()
	else:
		tekrar_dugmesi.grab_focus()


## kare: bölümü bitiren turda geçen fizik karesi. toplam_kare: tüm turların karesi (görsel süre),
## klon: kullanılan klon sayısı, ipucu: bölümün `ipucu_klon` değeri (0 = rozet yok). Kalıcı kayıt yok.
func goster(kare: int, tur: int, toplam_kare: int = -1, klon: int = 0, ipucu: int = 0) -> void:
	if toplam_kare < 0:
		toplam_kare = kare
	var saniye := float(toplam_kare) / Engine.physics_ticks_per_second
	var dk := int(saniye) / 60
	sure_etiketi.text = "Süre: %02d:%04.1f" % [dk, saniye - dk * 60]
	tur_etiketi.text = "Tur sayısı: %d" % tur
	var kutu: Node = tur_etiketi.get_parent()
	var klon_etiketi := Label.new()
	klon_etiketi.name = "KlonEtiketi"
	klon_etiketi.text = "Kullanılan klon: %d" % klon
	klon_etiketi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	klon_etiketi.add_theme_font_size_override("font_size", 20)
	kutu.add_child(klon_etiketi)
	kutu.move_child(klon_etiketi, tur_etiketi.get_index() + 1)
	if ipucu > 0 and klon <= ipucu:
		var rozet := Label.new()
		rozet.name = "AzKlonRozeti"
		rozet.text = "Az klonla çözüldü"
		rozet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rozet.add_theme_color_override("font_color", LabPaleti.AMBER)
		kutu.add_child(rozet)
		kutu.move_child(rozet, klon_etiketi.get_index() + 1)


func _on_sonraki() -> void:
	get_tree().paused = false
	Kayitlar.sifirla()
	get_tree().change_scene_to_file(sonraki_yol)


func _on_tekrar() -> void:
	get_tree().paused = false
	Kayitlar.sifirla()
	get_tree().reload_current_scene()


func _on_menu() -> void:
	get_tree().paused = false
	Kayitlar.sifirla()
	if dene_kipi:
		get_tree().change_scene_to_file(EDITOR_SAHNESI)
	elif ozel_kipi:
		get_tree().change_scene_to_file(BolumYollari.BOLUMLERIM_SAHNESI)
	else:
		get_tree().change_scene_to_file(MENU_SAHNESI)


## Dene kipi: "Sonraki" gizli, yerine "Çözümü kaydet ve editöre dön"; "Menü" = "Editöre dön".
func _dene_dugmelerini_kur() -> void:
	sonraki_dugmesi.visible = false
	menu_dugmesi.text = "Editöre dön"
	cozum_dugmesi = Button.new()
	cozum_dugmesi.name = "CozumKaydetDugmesi"
	cozum_dugmesi.text = "Çözümü kaydet ve editöre dön"
	var kutu: Node = sonraki_dugmesi.get_parent()
	kutu.add_child(cozum_dugmesi)
	kutu.move_child(cozum_dugmesi, sonraki_dugmesi.get_index() + 1)
	cozum_dugmesi.pressed.connect(_on_cozum_kaydet)
	cozum_dugmesi.grab_focus()


## Klon turlarını ve canlı oyuncunun son tur kaydını editör oturumuna yazar (dosyaya yazılmaz).
func _on_cozum_kaydet() -> void:
	var oturum: Script = load(EDITOR_OTURUMU_YOLU)
	var turlar: Array = []
	for t in Kayitlar.turlar:
		turlar.append((t as Array).duplicate(true))
	var oyuncu_kaydi: Array = []
	var oyuncu: Variant = get_parent().get("oyuncu")
	if oyuncu != null:
		oyuncu_kaydi = (oyuncu.kayit_girdileri as Array).duplicate(true)
	oturum.set("cozum", {"turlar": turlar, "oyuncu": oyuncu_kaydi})
	_on_menu()
