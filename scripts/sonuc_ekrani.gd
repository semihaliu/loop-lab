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
	panel.custom_minimum_size = Vector2(400, 330)
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


## kare: bölümü bitiren turda geçen fizik karesi sayısı.
func goster(kare: int, tur: int) -> void:
	var saniye := float(kare) / Engine.physics_ticks_per_second
	sure_etiketi.text = "Süre: %.2f sn" % saniye
	tur_etiketi.text = "Tur sayısı: %d" % tur


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
