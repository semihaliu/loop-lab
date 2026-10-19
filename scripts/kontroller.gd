extends Control
## Kontroller ekranı: tuş adları InputMap'ten okunur (sabit metin yok). Yalnızca görünüm.

const MENU_SAHNESI := "res://scenes/ana_menu.tscn"
## [eylem, açıklama]
const SATIRLAR := [
	["sol", "Sola git"],
	["sag", "Sağa git"],
	["zipla", "Zıpla"],
	["asagi", "Aşağı / platformdan düş"],
	["tur_bitir", "Turu bitir"],
	["bastan", "Baştan başla"],
]
## Türkçe tuş adları (listede olmayan tuş OS adıyla gösterilir).
const TUS_ADLARI := {
	KEY_LEFT: "Sol ok",
	KEY_RIGHT: "Sağ ok",
	KEY_UP: "Yukarı ok",
	KEY_DOWN: "Aşağı ok",
	KEY_SPACE: "Boşluk",
}

@onready var geri_dugmesi: Button = %GeriDugmesi


func _ready() -> void:
	theme = LabTema.olustur()
	var arka := LabArkaplani.new()
	arka.name = "LabArkaplani"
	add_child(arka)
	move_child(arka, 0)
	var kutu: VBoxContainer = %Kutu
	var baslik: Label = %Baslik
	baslik.add_theme_color_override("font_color", LabPaleti.CAMGOBEGI.lightened(0.45))
	baslik.add_theme_color_override("font_outline_color", LabPaleti.KENAR)
	baslik.add_theme_constant_override("outline_size", 8)
	for s in SATIRLAR:
		kutu.add_child(_satir(s[1], tus_metni(s[0])))
	kutu.add_child(_satir("Ekran butonları (sağ üst)", "Ana menü, Baştan başla"))
	kutu.move_child(geri_dugmesi, kutu.get_child_count() - 1)
	geri_dugmesi.focus_mode = Control.FOCUS_NONE
	geri_dugmesi.pressed.connect(_on_geri)


## Eyleme bağlı tuşların okunur adı ("Left / A"); bağlı değilse "-".
static func tus_metni(eylem: String) -> String:
	var adlar: Array[String] = []
	if InputMap.has_action(eylem):
		for e in InputMap.action_get_events(eylem):
			if e is InputEventKey:
				var kod: int = e.physical_keycode if e.physical_keycode != 0 else e.keycode
				var ad: String = TUS_ADLARI.get(kod, OS.get_keycode_string(kod))
				if ad != "" and not adlar.has(ad):
					adlar.append(ad)
	return " / ".join(adlar) if not adlar.is_empty() else "-"


func _satir(aciklama: String, tuslar: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	var a := Label.new()
	a.text = aciklama
	a.custom_minimum_size = Vector2(340, 0)
	a.add_theme_font_size_override("font_size", 24)
	var t := Label.new()
	t.text = tuslar
	t.add_theme_font_size_override("font_size", 24)
	t.add_theme_color_override("font_color", LabPaleti.AMBER)
	h.add_child(a)
	h.add_child(t)
	return h


func _on_geri() -> void:
	get_tree().change_scene_to_file(MENU_SAHNESI)
