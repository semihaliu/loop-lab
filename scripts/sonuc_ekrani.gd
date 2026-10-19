extends CanvasLayer
## Bölüm sonu ekranı: süre, tur sayısı, "Sonraki bölüm" (son bölümde gizli), "Tekrar oyna" ve "Menüye dön".
## process_mode = ALWAYS olduğu için simülasyon durmuşken (paused) butonlar çalışır.

const MENU_SAHNESI := "res://scenes/ana_menu.tscn"

var sonraki_yol := ""

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
	if sonraki_dugmesi.visible:
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
	get_tree().change_scene_to_file(MENU_SAHNESI)
