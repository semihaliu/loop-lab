extends Control
## Ana menü: Oyna (ilerleme haritasını açar), Çık.

const HARITA_SAHNESI := "res://scenes/harita.tscn"

@onready var oyna_dugmesi: Button = %OynaDugmesi
@onready var cik_dugmesi: Button = %CikDugmesi


func _ready() -> void:
	# Görünüm (yalnızca görsel): laboratuvar arka planı ve ortak tema.
	theme = LabTema.olustur()
	var arka := LabArkaplani.new()
	arka.name = "LabArkaplani"
	add_child(arka)
	move_child(arka, 0)
	var baslik: Label = $Ortala/Kutu/Baslik
	baslik.add_theme_color_override("font_color", LabPaleti.CAMGOBEGI.lightened(0.45))
	baslik.add_theme_color_override("font_outline_color", LabPaleti.KENAR)
	baslik.add_theme_constant_override("outline_size", 8)
	oyna_dugmesi.pressed.connect(_on_oyna)
	cik_dugmesi.pressed.connect(get_tree().quit)
	oyna_dugmesi.grab_focus()


func _on_oyna() -> void:
	get_tree().change_scene_to_file(HARITA_SAHNESI)
